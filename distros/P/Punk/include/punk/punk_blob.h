/* punk_blob.h - content-addressed storage for uploads, on Apophis.
 *
 * Punk::Upload answers what an upload costs and stops there. Where the file
 * then lives is left to the application, so every application invents a
 * directory layout, a naming scheme and a deduplication story - and the
 * naming scheme is usually the user's filename, which is how a path traversal
 * gets written.
 *
 * Apophis does the storage half: deterministic UUID v5 identifiers, a sharded
 * tree, atomic temp-and-rename writes, and dedup that needs no locking
 * because content addressing is idempotent. This is the tier above it - the
 * part that decides what an application may hand it and what it may hand
 * back.
 *
 * WHY THE CONTENT IS COMPARED ON A DEDUP HIT.
 *
 * Apophis identifies content with UUID v5, which is SHA-1, and its store()
 * returns immediately when the id already exists without comparing the bytes.
 * That is the right optimisation under the assumption content addressing
 * usually carries, that one id means one set of bytes.
 *
 * SHA-1 has not supported that assumption since 2017. The attack is three
 * steps: craft two colliding files; upload A, which is stored and gets
 * whatever review or sharing the application does; then anyone who later
 * uploads B is handed a reference that serves A, because nothing was written.
 *
 * So a dedup hit READS THE STORED BLOB AND COMPARES IT. Equal costs one read.
 * Unequal croaks, because it cannot be resolved: the store holds one of the
 * two files and either answer is wrong for somebody.
 *
 * HOW APOPHIS IS REACHED.
 *
 * Through its C ABI (ap_abi.h, via ExtUtils::Depends), not through method
 * calls. Identifying content, sharding it and writing it are all snprintf and
 * memcpy underneath, and paying a Perl method call for each of them is most
 * of what blob_send costs. Apophis 0.05+ is a hard prerequisite, so a missing
 * or too-old table is a BOOT error raised by register, not a per-request
 * fallback - there is no second implementation to fall back to, and quietly
 * having one would be worse than the croak.
 *
 * What stays on the Perl API: remove, verify, meta. None of them is on the
 * request path, and remove has a metadata sidecar to unlink as well as the
 * blob. A second copy of those semantics, exercised once a month by a
 * maintenance job, is how a rewrite quietly stops deleting something.
 *
 * Must be included after punk_context.h (pcx_call_meth), punk_app.h (app_hv)
 * and punk_static.h (punk_closure).
 */

#ifndef PUNK_BLOB_H
#define PUNK_BLOB_H

#include <sys/types.h>
#include <sys/stat.h>
#include <dirent.h>
#include <unistd.h>
#include <fcntl.h>

#include "ap_abi.h"          /* Apophis's public ABI, via ExtUtils::Depends */

#define PB_PATH_MAX 4096

static const ap_abi *PUNK_AP = NULL;
static int PUNK_AP_TRIED = 0;

/* Resolve (once) Apophis's ABI table, or NULL. PUNK_FAKE_AP_BAD simulates a
 * version mismatch for the guard test. */
static const ap_abi *punk_ap_try(pTHX) {
    if (!PUNK_AP_TRIED) {
        dSP; int count; UV p = 0;
        PUNK_AP_TRIED = 1;
        if (pk_require_once(aTHX_ "Apophis", FALSE)) {
            SPAGAIN;   /* the require may have reallocated the value stack */
            ENTER; SAVETMPS; PUSHMARK(SP); PUTBACK;
            count = call_pv("Apophis::_abi_ptr", G_SCALAR | G_EVAL);
            SPAGAIN;
            /* SvUV, not SvIV: the address is unsigned, and a .so mapped with
             * the top bit set reads back negative through PTR2IV/SvIV.
             *
             * And popped ONCE, into an SV*, because SvUV is a macro that
             * mentions its argument more than once: SvUV(POPs) pops twice and
             * reads the address off the wrong slot, so the table came back
             * as zero and every perl older than the one this was written on
             * failed the version guard with "upgrade Apophis to 0.05+"
             * against an Apophis 0.05 that was sitting right there. */
            if (count > 0) {
                SV *sv = POPs;
                if (!SvTRUE(ERRSV)) p = SvUV(sv);
            }
            PUTBACK; FREETMPS; LEAVE;
            if (p) {
                const ap_abi *a = INT2PTR(const ap_abi *, p);
                /* >= and never ==: the table is append-only, so a later one
                 * is a superset whose prefix stays valid. An equality check
                 * would make every Apophis release break this plugin. */
                if (a && !getenv("PUNK_FAKE_AP_BAD")
                    && a->abi_version >= AP_ABI_VERSION)
                    PUNK_AP = a;
            }
        }
    }
    return PUNK_AP;
}

/* The table, croaking if it is missing or too old. Called by register, so
 * this is a boot-environment error rather than a surprise mid-request. */
static const ap_abi *punk_ap(pTHX) {
    const ap_abi *a = punk_ap_try(aTHX);
    if (!a)
        croak("Punk::Plugin::Blob needs Apophis with a compatible C ABI "
              "(AP_ABI_VERSION %d); upgrade Apophis to 0.05+", AP_ABI_VERSION);
    return a;
}

/* Was an option actually given? Defined, and not the empty string.
 *
 * SvCUR is only legal on a PV, and `namespace` is documented to take a
 * CODEREF - a reference is an IV-bodied SV with no PVX at all. Reading one
 * silently returns whatever sits at that offset on an ordinary perl and trips
 * `PL_valid_types_PVX` on a DEBUGGING one, which is an abort rather than a
 * croak. A reference is by definition not empty, so it answers before the
 * length is ever looked at. */
static int pb_given(pTHX_ SV *sv) {
    STRLEN len;
    if (!sv || !SvOK(sv)) return 0;
    if (SvROK(sv)) return 1;
    (void)SvPV_const(sv, len);
    return len != 0;
}

/* The store's namespace bytes and directory, or croak. */
static void pb_unpack(pTHX_ SV *store, const unsigned char **ns,
                      const char **dir, STRLEN *dirlen) {
    const ap_abi *A = punk_ap(aTHX);
    if (!A->store_of(aTHX_ store, ns, dir, dirlen))
        croak("Punk::Plugin::Blob: the store is not a usable Apophis object "
              "- it needs both a namespace and a store_dir");
}

/* The on-disk path for an id, into a caller's buffer. Returns its length.
 *
 * build_path comes from the ABI rather than being two lines of snprintf here,
 * and that is the point: the sharded layout is Apophis's to change, and a
 * second copy of the rule would mean that the day it changes, every blob
 * already on disk becomes unreachable through Punk while staying perfectly
 * findable through Apophis. */
static int pb_path(pTHX_ SV *store, const char *id, STRLEN idlen,
                   char *out, size_t outsz) {
    const ap_abi *A = punk_ap(aTHX);
    const unsigned char *ns; const char *dir; STRLEN dirlen;
    int n;
    pb_unpack(aTHX_ store, &ns, &dir, &dirlen);
    n = A->build_path(out, outsz, dir, dirlen, id, idlen);
    /* snprintf semantics: n is the length it WOULD have needed. Apophis's own
     * callers do not check this, so a store root long enough to overrun
     * truncates silently - and a truncated path is a different file. */
    if (n < 0 || (size_t)n >= outsz)
        croak("Punk::Plugin::Blob: the blob path does not fit in %d bytes "
              "- the store root is too long", (int)outsz);
    return n;
}

/* Do the bytes already at `path` match what is being offered?
 *
 * Compared in chunks rather than by reading the blob into a scalar: the whole
 * point of this read is a memcmp, and a mismatched first block ends it. -1
 * means the file could not be read at all. */
static int pb_same(const char *path, const char *want, STRLEN wantlen) {
    char buf[65536];
    struct stat st;
    STRLEN off = 0;
    int fd = open(path, O_RDONLY);
    if (fd < 0) return -1;
    if (fstat(fd, &st) != 0) { close(fd); return -1; }
    if ((STRLEN)st.st_size != wantlen) { close(fd); return 0; }
    while (off < wantlen) {
        size_t chunk = wantlen - off;
        ssize_t got;
        if (chunk > sizeof buf) chunk = sizeof buf;
        got = read(fd, buf, chunk);
        if (got <= 0) { close(fd); return -1; }
        if (memNE(buf, want + off, (size_t)got)) { close(fd); return 0; }
        off += (STRLEN)got;
    }
    close(fd);
    return 1;
}

/* Is this a UUID, exactly?
 *
 * 8-4-4-4-12 lowercase hex and nothing else. It matters because an id usually
 * came out of a URL and is about to become a filesystem path through
 * Apophis's path_for - and send_file says so plainly: "the path is served as
 * given - if any part of it came from the request, the traversal guard is
 * yours".
 *
 * A whole-shape check rather than a scan for '..' or '/': a rule that
 * enumerates the bad shapes misses one, and there is exactly one good shape. */
static int pb_id_ok(const char *s, STRLEN l) {
    static const int dash[5] = { 8, 13, 18, 23, -1 };
    STRLEN i;
    int d = 0;
    if (!s || l != 36) return 0;
    for (i = 0; i < 36; i++) {
        if (dash[d] >= 0 && i == (STRLEN)dash[d]) {
            if (s[i] != '-') return 0;
            d++;
            continue;
        }
        if (!((s[i] >= '0' && s[i] <= '9') || (s[i] >= 'a' && s[i] <= 'f')))
            return 0;
    }
    return 1;
}

/* The types a blob may be served INLINE as, and nothing else.
 *
 * Raster images. The list is short on purpose: every entry is a format a
 * browser will render in this application's origin, so every entry is a
 * decision about what an uploader may make it render.
 *
 * SVG IS NOT ON IT, which is the whole reason there is a list rather than an
 * /^image\// test. An SVG is a document that can carry script, so serving one
 * inline from your own origin is exactly the cross-site scripting this
 * defends against - and image/svg+xml passes every naive image check ever
 * written. PDF is not on it either: browsers render PDFs inline and a PDF is
 * a far larger attack surface than a raster decoder. */
static const char *pb_inline_ok(const char *s, STRLEN l) {
    static const char *ok[] = { "image/png", "image/jpeg", "image/gif",
                                "image/webp", "image/avif", NULL };
    char buf[64];
    STRLEN i, n = 0;
    int j;
    if (!s || !l) return NULL;
    for (i = 0; i < l && n < sizeof buf - 1; i++) {
        char c = s[i];
        if (c == ';') break;                  /* drop any parameters */
        if (c == ' ' || c == '\t') continue;
        buf[n++] = (c >= 'A' && c <= 'Z') ? (char)(c | 32) : c;
    }
    buf[n] = '\0';
    for (j = 0; ok[j]; j++) if (strEQ(buf, ok[j])) return ok[j];
    return NULL;
}

/* Store bytes, comparing on a dedup hit. Returns the id (+1).
 *
 * The whole of Apophis's store() in C: identify, format, shard, stat, and
 * either compare or write. No Perl frame, and the collision check is now a
 * chunked compare rather than a fetch into a scalar. */
/* Create the directories leading to `path`.
 *
 * Apophis's write_atomic does this itself, but the cross-filesystem copy
 * below cannot use write_atomic - that takes the content as a buffer, which
 * is the one thing this whole path exists to avoid holding. */
static void pb_mkparent(pTHX_ const char *path) {
    char buf[PB_PATH_MAX];
    char *p;
    STRLEN n = strlen(path);
    if (n >= sizeof buf) return;
    Copy(path, buf, n + 1, char);
    p = strrchr(buf, '/');
    if (!p) return;
    *p = '\0';
    for (p = buf + 1; *p; p++) {
        if (*p != '/') continue;
        *p = '\0';
        (void)PerlDir_mkdir(buf, 0700);
        *p = '/';
    }
    (void)PerlDir_mkdir(buf, 0700);
}

/* An upload that is already a file: is there a path, and can it be read? */
static SV *pb_upload_path(pTHX_ SV *what) {
    SV *p;
    if (!(what && SvROK(what) && SvOBJECT(SvRV(what)))) return NULL;
    if (!pcx_can(aTHX_ what, "path")) return NULL;
    p = pcx_call_meth(aTHX_ what, "path", NULL, 0, 1);
    if (p && SvOK(p) && SvCUR(p)) return p;
    if (p) SvREFCNT_dec(p);
    return NULL;
}

/* Do two files hold the same bytes? Used for the deduplication check when
 * neither side is in memory. -1 when one of them cannot be read. */
static int pb_same_file(pTHX_ const char *a, const char *b) {
    PerlIO *fa = PerlIO_open(a, "rb");
    PerlIO *fb;
    int same = 1;
    if (!fa) return -1;
    fb = PerlIO_open(b, "rb");
    if (!fb) { PerlIO_close(fa); return -1; }
    for (;;) {
        char ba[65536], bb[65536];
        SSize_t na = PerlIO_read(fa, ba, sizeof ba);
        SSize_t nb = PerlIO_read(fb, bb, sizeof bb);
        if (na != nb) { same = 0; break; }
        if (na <= 0) break;
        if (memNE(ba, bb, (size_t)na)) { same = 0; break; }
    }
    PerlIO_close(fa);
    PerlIO_close(fb);
    return same;
}

/* Store an upload that is already on disk, without ever holding it.
 *
 * Phases 1 to 3 of the upload work got a large file from the wire to a temp
 * file without it being resident anywhere. Storing it through ->content would
 * have undone all of that at the last step: the whole point of an id derived
 * from the contents is that the contents must be READ, and reading them into
 * a scalar to hash them is the copy that was just removed.
 *
 * Apophis ships `identify_fh` for exactly this - the same id the in-memory
 * path produces, computed in 64KB chunks - and it says why a consumer must
 * not reimplement it: the chunking and the namespace prefix are easy to get
 * subtly wrong, and wrong here means ids that disagree with every other path.
 *
 * Returns NULL when this is not an on-disk upload, so the caller falls back.
 */
static SV *pb_store_file(pTHX_ SV *ca, SV *what) {
    const ap_abi *A = punk_ap(aTHX);
    const unsigned char *ns; const char *dir; STRLEN dirlen;
    unsigned char idb[16];
    char id_str[37], path[PB_PATH_MAX];
    SV *src = pb_upload_path(aTHX_ what);
    PerlIO *fh;
    struct stat st;

    if (!src) return NULL;
    fh = PerlIO_open(SvPVX(src), "rb");
    if (!fh) { SvREFCNT_dec(src); return NULL; }

    pb_unpack(aTHX_ ca, &ns, &dir, &dirlen);
    A->identify_fh(aTHX_ idb, ns, fh);
    PerlIO_close(fh);
    A->format_id(id_str, idb);
    (void)pb_path(aTHX_ ca, id_str, 36, path, sizeof path);

    if (stat(path, &st) == 0) {
        int same = pb_same_file(aTHX_ path, SvPVX(src));
        if (same == 0) {
            SvREFCNT_dec(src);
            croak("Punk::Plugin::Blob: refusing to store - two DIFFERENT "
                  "files share the id %s. Apophis identifies content with "
                  "SHA-1, so this is either a deliberate collision or a "
                  "corrupted store, and either way the bytes already held "
                  "are not the bytes offered", id_str);
        }
        if (same == 1) {
            /* The dedup case, and the one this is most obviously worth
             * having: a file uploaded by a hundred users is stored once, and
             * the ninety-nine after the first move nothing at all. */
            SvREFCNT_dec(src);
            return newSVpvn(id_str, 36);
        }
        /* -1: there but unreadable. Fall through and write. */
    }

    {   /* Same filesystem: a rename, which is free. Otherwise a copy, still
         * without the bytes passing through a scalar. Either way the store
         * only ever sees a COMPLETE file at a content address - a partial
         * object at an address that claims to be its hash is a lie that
         * survives every later integrity check. */
        SV *tmp = newSVpv(path, 0);
        sv_catpvs(tmp, ".part");
        /* BEFORE the rename, not only in the copy branch below: rename fails
         * with ENOENT when the destination's directory does not exist, which
         * is every first store into a shard. Without this the rename always
         * failed and the copy path always ran - so the move was never a move,
         * on the filesystem where it was supposed to be free. */
        (void)pb_mkparent(aTHX_ path);
        if (PerlLIO_rename(SvPVX(src), path) != 0) {
            PerlIO *in = PerlIO_open(SvPVX(src), "rb");
            PerlIO *out;
            if (!in) { SvREFCNT_dec(tmp); SvREFCNT_dec(src); return NULL; }
            out = PerlIO_open(SvPVX(tmp), "wb");
            if (!out) { PerlIO_close(in); SvREFCNT_dec(tmp);
                        SvREFCNT_dec(src); return NULL; }
            for (;;) {
                char buf[65536];
                SSize_t n = PerlIO_read(in, buf, sizeof buf);
                if (n <= 0) break;
                if (PerlIO_write(out, buf, n) != n) {
                    PerlIO_close(in); PerlIO_close(out);
                    (void)PerlLIO_unlink(SvPVX(tmp));
                    SvREFCNT_dec(tmp); SvREFCNT_dec(src);
                    croak("Punk::Plugin::Blob: short write storing %s", id_str);
                }
            }
            PerlIO_close(in);
            PerlIO_close(out);
            if (PerlLIO_rename(SvPVX(tmp), path) != 0) {
                (void)PerlLIO_unlink(SvPVX(tmp));
                SvREFCNT_dec(tmp); SvREFCNT_dec(src);
                croak("Punk::Plugin::Blob: cannot place %s", id_str);
            }
        }
        SvREFCNT_dec(tmp);
    }

    /* It has been moved into the store; the upload's cleanup must not chase
     * it, exactly as Punk::Upload::save does after its own rename. */
    if (pcx_can(aTHX_ what, "_disown"))
        { SV *r = pcx_call_meth(aTHX_ what, "_disown", NULL, 0, 1);
          if (r) SvREFCNT_dec(r); }

    SvREFCNT_dec(src);
    return newSVpvn(id_str, 36);
}

static SV *pb_store(pTHX_ SV *ca, SV *what) {
    const ap_abi *A = punk_ap(aTHX);
    {   /* an upload already on disk never becomes a scalar */
        SV *id = pb_store_file(aTHX_ ca, what);
        if (id) return id;
    }
    {
    const unsigned char *ns; const char *dir; STRLEN dirlen;
    unsigned char idb[16];
    char id_str[37], path[PB_PATH_MAX];
    const char *content;
    STRLEN clen;
    struct stat st;

    pb_unpack(aTHX_ ca, &ns, &dir, &dirlen);
    content = SvPV_const(SvROK(what) ? SvRV(what) : what, clen);

    A->identify(idb, ns, content, clen);
    A->format_id(id_str, idb);
    (void)pb_path(aTHX_ ca, id_str, 36, path, sizeof path);

    if (stat(path, &st) == 0) {
        int same = pb_same(path, content, clen);
        if (same == 0)
            croak("Punk::Plugin::Blob: refusing to store - two DIFFERENT "
                  "files share the id %s. Apophis identifies content with "
                  "SHA-1, so this is either a deliberate collision or a "
                  "corrupted store, and either way the bytes already held "
                  "are not the bytes offered", id_str);
        if (same == 1)
            return newSVpvn(id_str, 36);      /* the ordinary dedup case */
        /* -1: it is there but unreadable, so the store changed underneath
         * us. Fall through and write. */
    }

    A->write_atomic(aTHX_ path, content, clen);
    return newSVpvn(id_str, 36);
    }
}

/* What the caller handed over, as the scalar ref Apophis takes (+1).
 *
 * A Punk::Upload, a scalar ref, or a string of bytes. NOT a filename: a
 * string that happens to name a file is content, and guessing otherwise is
 * how an application stores the path instead of the bytes. */
static SV *pb_content_ref(pTHX_ SV *what) {
    if (!(what && SvOK(what)))
        croak("Punk::Plugin::Blob: blob_put needs content");
    if (SvROK(what) && SvTYPE(SvRV(what)) == SVt_PVMG && SvOBJECT(SvRV(what))) {
        /* something blessed: an upload, if it can hand over its bytes */
        SV *bytes = pcx_call_meth(aTHX_ what, "content", NULL, 0, 1);
        if (bytes) return newRV_noinc(bytes);
        croak("Punk::Plugin::Blob: blob_put takes a Punk::Upload, a scalar "
              "reference, or a string of bytes");
    }
    if (SvROK(what)) {
        if (SvTYPE(SvRV(what)) > SVt_PVMG)
            croak("Punk::Plugin::Blob: blob_put takes a Punk::Upload, a "
                  "scalar reference, or a string of bytes");
        return newRV_inc(SvRV(what));         /* already a scalar ref */
    }
    return newRV_noinc(newSVsv(what));
}

/* ---- the sweep --------------------------------------------------------------
 *
 * Deduplication means a blob may have several references, so deleting one
 * cannot mean unlinking the bytes: two users uploaded the same file, one
 * deletes their copy, and the other must still have theirs. Unlinking on the
 * first delete is data loss that looks like a successful operation.
 *
 * Refcounting would work and puts an atomic read-modify-write on the upload
 * path - a lock, in a component whose whole appeal is that content addressing
 * needs none. So nothing unlinks during a request, and a sweep asks the
 * application which ids are still referenced and removes the rest. Unswept
 * orphans cost disk, and disk is cheaper than a support ticket about a
 * missing file.
 *
 * THE DANGEROUS PART IS THE ANSWER, NOT THE WALK. A `live` callback that dies
 * or returns nothing is indistinguishable from "no blobs are referenced", and
 * acting on that unlinks the whole store.
 */

static void pb_sweep_dir(pTHX_ const char *dir, HV *live, double now,
                         double grace, int dry, UV *removed, UV *kept) {
    DIR *d = opendir(dir);
    struct dirent *e;
    if (!d) return;
    while ((e = readdir(d))) {
        char path[2048];
        struct stat st;
        STRLEN nl = strlen(e->d_name);

        /* Only things shaped like a blob. A temp file from an interrupted
         * write, or anything a human left here, is left alone: a sweep that
         * removes what it does not recognise eventually removes something
         * that mattered. */
        if (!pb_id_ok(e->d_name, nl)) continue;
        if ((size_t)snprintf(path, sizeof path, "%s/%s", dir, e->d_name)
            >= sizeof path) continue;
        if (stat(path, &st) != 0 || !S_ISREG(st.st_mode)) continue;

        if (hv_exists(live, e->d_name, (I32)nl)) { (*kept)++; continue; }

        /* A blob written between the caller's snapshot of live ids and this
         * walk is in neither, and is not an orphan. The grace period is what
         * stops that race collecting a file whose row was committed a moment
         * later. */
        if (grace > 0 && now - (double)st.st_mtime < grace) {
            (*kept)++;
            continue;
        }
        if (!dry && unlink(path) != 0) { (*kept)++; continue; }
        (*removed)++;
    }
    closedir(d);
}

/* The whole store: two shard levels, then the blob. */
static void pb_sweep(pTHX_ const char *root, HV *live, double grace, int dry,
                     UV *removed, UV *kept) {
    DIR *d1 = opendir(root);
    struct dirent *e1;
    double now = (double)time(NULL);
    if (!d1) croak("Punk::Plugin::Blob: cannot read the store at '%s'", root);
    while ((e1 = readdir(d1))) {
        char l1[2048];
        DIR *d2;
        struct dirent *e2;
        if (e1->d_name[0] == '.') continue;
        if ((size_t)snprintf(l1, sizeof l1, "%s/%s", root, e1->d_name)
            >= sizeof l1) continue;
        d2 = opendir(l1);
        if (!d2) continue;
        while ((e2 = readdir(d2))) {
            char l2[2048];
            if (e2->d_name[0] == '.') continue;
            if ((size_t)snprintf(l2, sizeof l2, "%s/%s", l1, e2->d_name)
                >= sizeof l2) continue;
            pb_sweep_dir(aTHX_ l2, live, now, grace, dry, removed, kept);
        }
        closedir(d2);
    }
    closedir(d1);
}

/* Ask the application which ids are still referenced, and refuse to act on an
 * answer that might not be one. Returns a hash of live ids (+1), or croaks. */
static HV *pb_live_set(pTHX_ SV *cb, int allow_empty) {
    dSP;
    HV *live = newHV();
    AV *got = (AV *)sv_2mortal((SV *)newAV());
    AV *items = got;
    int count, i;
    IV n = 0;

    ENTER; SAVETMPS;
    PUSHMARK(SP);
    PUTBACK;
    count = call_sv(cb, G_ARRAY | G_EVAL);
    SPAGAIN;
    for (i = count - 1; i >= 0; i--) av_store(got, (SSize_t)i, newSVsv(POPs));
    PUTBACK;
    if (SvTRUE(ERRSV)) {
        /* croak BEFORE the FREETMPS rather than after it holding a pointer
         * into what it just freed: an SV mortalised inside this scope is gone
         * the moment its temporaries are released, and reading the message
         * out of it afterwards is a use-after-free that usually still says
         * the right thing. perl unwinds the scope. */
        SvREFCNT_dec((SV *)live);
        croak("Punk::Plugin::Blob: the sweep's `live` callback died, so "
              "NOTHING was removed - an answer that failed is not an answer "
              "that there are no live blobs: %s", SvPV_nolen(ERRSV));
    }
    FREETMPS; LEAVE;

    /* One arrayref, or a plain list - a model returns the first and a
     * hand-written callback the second.
     *
     * BORROWED, not copied back into `got`: emptying `got` to refill it would
     * free the arrayref SV, which holds the only reference to the array being
     * read from, and the loop below would then walk freed memory. */
    if (count == 1) {
        SV **only = av_fetch(got, 0, 0);
        if (only && *only && SvROK(*only)
            && SvTYPE(SvRV(*only)) == SVt_PVAV) {
            items = (AV *)SvRV(*only);
            count = (int)(av_len(items) + 1);
        }
    }

    for (i = 0; i < count; i++) {
        SV **x = av_fetch(items, (SSize_t)i, 0);
        STRLEN l;
        const char *s;
        if (!(x && *x && SvOK(*x))) continue;
        s = SvPV_const(*x, l);
        if (!pb_id_ok(s, l)) continue;        /* not an id: cannot be live */
        (void)hv_store(live, s, (I32)l, newSViv(1), 0);
        n++;
    }

    if (n == 0 && !allow_empty) {
        SvREFCNT_dec((SV *)live);
        croak("Punk::Plugin::Blob: the sweep's `live` callback returned no "
              "blob ids, so NOTHING was removed. An empty answer is "
              "indistinguishable from a query that failed, and acting on it "
              "would unlink the whole store. Pass allow_empty => 1 if the "
              "application really does reference no blobs");
    }
    return live;
}

/* Call a plain coderef, returning its scalar result (+1) or NULL. */
static SV *pb_call_cv(pTHX_ SV *cv, SV **argv, int n) {
    dSP;
    SV *r = NULL;
    int count, i;
    ENTER; SAVETMPS;
    PUSHMARK(SP);
    EXTEND(SP, n);
    for (i = 0; i < n; i++) PUSHs(argv[i]);
    PUTBACK;
    count = call_sv(cv, G_SCALAR);
    SPAGAIN;
    if (count > 0) r = SvREFCNT_inc(POPs);
    PUTBACK; FREETMPS; LEAVE;
    return r;
}

/* ---- the helpers, as C closures ---------------------------------------------
 *
 * Each captures the Apophis store built at registration, so a request never
 * constructs one. cap = [store, root].
 */

/* The store this request belongs to, borrowed.
 *
 * cap = [store-or-undef, root, namespace, cache].
 *
 * A STRING namespace is one store, built at registration: every tenant shares
 * ids, and a file held by two of them is stored once.
 *
 * A CODEREF namespace is one store per tenant. It cannot be built at
 * registration because it depends on the request, so it is built on first use
 * and cached per worker - the cost is one Apophis object per tenant this
 * worker has served, which is a handful of scalars.
 *
 * Which of the two an application wants is the trade in "Deduplication
 * crosses tenants", and it is deliberately not defaulted. */
static SV *pb_store_for(pTHX_ CV *cv, SV *c) {
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV **s, **ns, **cache, **root;
    SV *nsv;
    HV *seen;
    HE *have;

    if (!cap) return NULL;
    s = av_fetch(cap, 0, 0);
    if (s && *s && SvROK(*s)) return *s;          /* one store for everyone */

    ns    = av_fetch(cap, 2, 0);
    root  = av_fetch(cap, 1, 0);
    cache = av_fetch(cap, 3, 0);
    if (!(ns && *ns && SvROK(*ns) && SvTYPE(SvRV(*ns)) == SVt_PVCV))
        return NULL;
    if (!(cache && *cache && SvROK(*cache))) return NULL;
    seen = (HV *)SvRV(*cache);

    {   /* $namespace->($c) */
        SV *argv[1];
        argv[0] = c ? c : &PL_sv_undef;
        nsv = pb_call_cv(aTHX_ *ns, argv, c ? 1 : 0);
    }
    if (!(nsv && SvOK(nsv) && SvCUR(nsv))) {
        if (nsv) SvREFCNT_dec(nsv);
        croak("Punk::Plugin::Blob: the `namespace` callback gave back "
              "nothing - it decides which tenant's ids these are, so an "
              "empty answer would silently put this request in somebody "
              "else's namespace");
    }
    sv_2mortal(nsv);

    have = hv_fetch_ent(seen, nsv, 0, 0);
    if (have) return HeVAL(have);

    {
        SV *argv[4], *store;
        argv[0] = sv_2mortal(newSVpvs("namespace"));
        argv[1] = nsv;
        argv[2] = sv_2mortal(newSVpvs("store_dir"));
        argv[3] = (root && *root) ? *root : &PL_sv_undef;
        store = pcx_call_meth(aTHX_ sv_2mortal(newSVpvs("Apophis")), "new",
                              argv, 4, 1);
        if (!(store && SvROK(store)))
            croak("Punk::Plugin::Blob: Apophis->new gave back no store for "
                  "namespace '%" SVf "'", SVfARG(nsv));
        (void)hv_store_ent(seen, nsv, store, 0);
        return store;
    }
}

XS_INTERNAL(pb_put_cb);
XS_INTERNAL(pb_put_cb) {
    dXSARGS;
    SV *store = pb_store_for(aTHX_ cv, items > 0 ? ST(0) : NULL);
    SV *what = items > 1 ? ST(1) : NULL;
    SV *ref;
    if (!store) XSRETURN_EMPTY;
    ref = sv_2mortal(pb_content_ref(aTHX_ what));
    ST(0) = sv_2mortal(pb_store(aTHX_ store, ref));
    XSRETURN(1);
}

XS_INTERNAL(pb_exists_cb);
XS_INTERNAL(pb_exists_cb) {
    dXSARGS;
    SV *store = pb_store_for(aTHX_ cv, items > 0 ? ST(0) : NULL);
    SV *id = items > 1 ? ST(1) : NULL;
    STRLEN l = 0;
    const char *s = (id && SvOK(id)) ? SvPV_const(id, l) : NULL;
    char path[PB_PATH_MAX];
    struct stat st;
    if (!store || !pb_id_ok(s, l)) { ST(0) = sv_2mortal(newSViv(0)); XSRETURN(1); }
    (void)pb_path(aTHX_ store, s, l, path, sizeof path);
    ST(0) = sv_2mortal(newSViv(stat(path, &st) == 0 && S_ISREG(st.st_mode)));
    XSRETURN(1);
}

XS_INTERNAL(pb_path_cb);
XS_INTERNAL(pb_path_cb) {
    dXSARGS;
    SV *store = pb_store_for(aTHX_ cv, items > 0 ? ST(0) : NULL);
    SV *id = items > 1 ? ST(1) : NULL;
    STRLEN l = 0;
    const char *s = (id && SvOK(id)) ? SvPV_const(id, l) : NULL;
    if (!store) XSRETURN_EMPTY;
    /* blob_path croaks where blob_send answers 404: a program calls this one
     * deliberately, so a bad id here is a bug rather than a stray request. */
    if (!pb_id_ok(s, l))
        croak("Punk::Plugin::Blob: '%s' is not a blob id", s ? s : "(undef)");
    {
        char path[PB_PATH_MAX];
        int n = pb_path(aTHX_ store, s, l, path, sizeof path);
        ST(0) = sv_2mortal(newSVpvn(path, n));
    }
    XSRETURN(1);
}

XS_INTERNAL(pb_remove_cb);
XS_INTERNAL(pb_remove_cb) {
    dXSARGS;
    SV *store = pb_store_for(aTHX_ cv, items > 0 ? ST(0) : NULL);
    SV *id = items > 1 ? ST(1) : NULL;
    STRLEN l = 0;
    const char *s = (id && SvOK(id)) ? SvPV_const(id, l) : NULL;
    SV *r;
    if (!store || !pb_id_ok(s, l)) { ST(0) = sv_2mortal(newSViv(0)); XSRETURN(1); }
    r = pcx_call_meth(aTHX_ store, "remove", &id, 1, 1);
    ST(0) = sv_2mortal(newSViv((r && SvTRUE(r)) ? 1 : 0));
    if (r) SvREFCNT_dec(r);
    XSRETURN(1);
}

XS_INTERNAL(pb_store_cb);
XS_INTERNAL(pb_store_cb) {
    dXSARGS;
    SV *store = pb_store_for(aTHX_ cv, items > 0 ? ST(0) : NULL);
    ST(0) = store ? sv_2mortal(newSVsv(store)) : &PL_sv_undef;
    XSRETURN(1);
}

XS_INTERNAL(pb_root_cb);
XS_INTERNAL(pb_root_cb) {
    dXSARGS;
    AV *cap = punk_clos_cap(aTHX_ cv);
    SV **r = cap ? av_fetch(cap, 1, 0) : NULL;
    PERL_UNUSED_VAR(items);
    ST(0) = (r && *r) ? sv_2mortal(newSVsv(*r)) : &PL_sv_undef;
    XSRETURN(1);
}

XS_INTERNAL(pb_safe_type_cb);
XS_INTERNAL(pb_safe_type_cb) {
    dXSARGS;
    SV *claimed = items > 1 ? ST(1) : NULL;
    STRLEN l = 0;
    const char *s = (claimed && SvOK(claimed)) ? SvPV_const(claimed, l) : NULL;
    const char *ok = pb_inline_ok(s, l);
    ST(0) = ok ? sv_2mortal(newSVpv(ok, 0)) : &PL_sv_undef;
    XSRETURN(1);
}

/* blob_send: the unfriendly defaults, and why.
 *
 * An uploader controls the bytes AND claims the type, so serving those bytes
 * back as the claimed type is stored cross-site scripting with this
 * application's origin on it - the commonest way a file-upload feature
 * becomes a vulnerability.
 *
 *   Content-Type: application/octet-stream
 *   Content-Disposition: attachment
 *   X-Content-Type-Options: nosniff
 *
 * nosniff matters as much as the type: without it a browser may sniff HTML
 * out of a response labelled octet-stream and render it, which puts the whole
 * defence back where it started. It is set always and this helper offers no
 * way to turn it off. */
XS_INTERNAL(pb_send_cb);
XS_INTERNAL(pb_send_cb) {
    dXSARGS;
    SV *c  = items > 0 ? ST(0) : NULL;
    SV *store = pb_store_for(aTHX_ cv, c);
    SV *id = items > 1 ? ST(1) : NULL;
    STRLEN l = 0;
    const char *s = (id && SvOK(id)) ? SvPV_const(id, l) : NULL;
    SV *path, *argv[24];
    int n = 0, i, have_type = 0, have_cc = 0, have_fn = 0, inline_ok = 0;
    int public_ = 0;

    if (!(store && c)) XSRETURN_EMPTY;

    /* An id that is not an id is a 404, not an error: it came out of a URL,
     * so something probing /blob/../.. should be told there is nothing there
     * rather than fill the error log with 500s. */
    if (!pb_id_ok(s, l)) {
        ST(0) = sv_2mortal(pcx_call_meth(aTHX_ c, "not_found", NULL, 0, 1));
        XSRETURN(1);
    }

    /* Always, and before send_file, which folds set headers in. */
    {
        SV *hv[2];
        SV *r;
        hv[0] = sv_2mortal(newSVpvs("X-Content-Type-Options"));
        hv[1] = sv_2mortal(newSVpvs("nosniff"));
        r = pcx_call_meth(aTHX_ c, "header", hv, 2, 1);
        if (r) SvREFCNT_dec(r);
    }

    for (i = 2; i + 1 < items; i += 2) {
        const char *k = SvPV_nolen(ST(i));
        if (strEQ(k, "type"))          have_type = 1;
        else if (strEQ(k, "cache_control")) have_cc = 1;
        else if (strEQ(k, "filename")) have_fn = 1;
        else if (strEQ(k, "inline"))   inline_ok = SvTRUE(ST(i + 1)) ? 1 : 0;
        else if (strEQ(k, "public"))   { public_ = SvTRUE(ST(i + 1)) ? 1 : 0; continue; }
        if (n + 2 < (int)(sizeof argv / sizeof argv[0])) {
            argv[n++] = ST(i);
            argv[n++] = ST(i + 1);
        }
    }

    if (!have_type) {
        /* nothing unknown is displayed inline */
        argv[n++] = sv_2mortal(newSVpvs("type"));
        argv[n++] = sv_2mortal(newSVpvs("application/octet-stream"));
        if (inline_ok) {
            argv[n++] = sv_2mortal(newSVpvs("inline"));
            argv[n++] = sv_2mortal(newSViv(0));
        }
        if (!have_fn) {
            argv[n++] = sv_2mortal(newSVpvs("filename"));
            argv[n++] = sv_2mortal(newSVpvs("blob"));
            have_fn = 1;
        }
    }
    if (!have_cc) {
        /* A content-addressed URL cannot come to mean anything else, so a
         * long lifetime is right - but `public` on a blob behind
         * authorisation tells a shared cache it may hand somebody's document
         * to the next person who asks. */
        argv[n++] = sv_2mortal(newSVpvs("cache_control"));
        argv[n++] = sv_2mortal(newSVpvf("%s, max-age=31536000, immutable",
                                        public_ ? "public" : "private"));
    }
    /* A well-formed id naming no blob is a reference the sweep collected. */
    argv[n++] = sv_2mortal(newSVpvs("missing"));
    argv[n++] = sv_2mortal(newSVpvs("not_found"));

    {   /* the request path's one remaining Perl call was this snprintf */
        char buf[PB_PATH_MAX];
        STRLEN il = 0;
        const char *is = SvPV_const(id, il);
        int pn = pb_path(aTHX_ store, is, il, buf, sizeof buf);
        path = sv_2mortal(newSVpvn(buf, pn));
    }
    {
        SV *full[26];
        int j;
        full[0] = path;
        for (j = 0; j < n; j++) full[j + 1] = argv[j];
        ST(0) = sv_2mortal(pcx_call_meth(aTHX_ c, "send_file", full, n + 1, 1));
    }
    XSRETURN(1);
}

#endif /* PUNK_BLOB_H */
