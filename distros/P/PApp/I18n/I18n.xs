#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include <string.h>

#include <unistd.h>
#include <sys/mman.h>

/* header */
/* the format could easily be improved by eliminating next
 * if we could sort by hash value before writing the file. well,
 * should have done it in perl in the first place, but this implementation
 * uses very little memory, and our .dpo files might get LARGE. */

/* the next version might instead use the cdb format
 * (http://cr.yp.to/cdb/cdb.txt), but that's not sure (it might
 * be worse.
 */

#define DPO_VERSION 1
#define HASHSIZE 997
#define MAXHASH 40 /* the number of bytes to hash at most */

typedef U32 OFS;
typedef unsigned int HASH;

#define DPO_SIG      0x5000504f
#define DPO_SIG_SWAP 0x4f500050

/* dpo file header */
/* we assume natural alignment is ok */
struct dpo_head {
  U32 sig;
  U32 version;
  U32 hashsize;
  OFS hash[1];
  /* followed by aligned dpo_str's */
};
#define SIZEOF_HDR(hashsize) (sizeof (struct dpo_head) + sizeof (OFS) * ((hashsize)-1))

/* each string has the following format */
struct dpo_str {
  OFS next; /* inefficient, should be optimized by sorting buckets */
  OFS len1;
  OFS len2;
  /* followed by two unterminated, unaligned strings */
};

/* We only hash the first MAXHASH bytes at max. This is a totally made-up,
 * not researched at least one minute, probably very bad hashing function.
 * But it is fast, and wasting diskspace for a too-large hash is ok.
 */
static HASH
hash (const unsigned char *msg, unsigned int len)
{
  HASH hval = len;

  if (len > MAXHASH)
    len = MAXHASH;

  if (len)
    do {
      hval ^= (hval << 4) + (hval >> 25) + (HASH)*msg++;
    } while (--len);

  return hval;
}

typedef struct dpo_writer {
  int fd;
  OFS ofs;
  struct dpo_head *hdr;
} *PApp__I18n__DPO_Writer;

typedef struct dpo_table {
  void *start;
  size_t length;
  SV *lang;
} *PApp__I18n__Table;

/* skip any leading \{} or \{\ tag */
#define SKIP_META(s,l)	\
        if (l >= 3 && s[0] == '\\' && s[1] == '{')		\
          {							\
            /* escape sequence \{ found, skip it */		\
            s += 2;						\
            l -= 2;						\
            /* if the full sequence is "\{\" then modify it */	\
            /* to look like "\". otw. skip to trailing } */	\
            if (*s != '\\')					\
              while (*s++ != '}')				\
                l--;						\
          }

MODULE = PApp::I18n		PACKAGE = PApp::I18n::DPO_Writer

PROTOTYPES: ENABLE

PApp::I18n::DPO_Writer
new(class, path, hashsize = 997)
	SV *	class
	char *	path
        int	hashsize
        CODE:
{
        int fd = creat (path, 0666);
        void *data;

        if (fd <= 0)
          croak ("DPO_Writer: unable to create '%s': %s", path, strerror (errno));

        Newz(0, RETVAL, 1, struct dpo_writer);
        Newz(0, data, SIZEOF_HDR (hashsize), char);
        RETVAL->hdr = (struct dpo_head *) data;
        RETVAL->fd = fd;
        RETVAL->ofs = SIZEOF_HDR (hashsize);
        RETVAL->hdr->sig = DPO_SIG;
        RETVAL->hdr->version = DPO_VERSION;
        RETVAL->hdr->hashsize = hashsize;
}
	OUTPUT:
        RETVAL

void
add(self, msgid, msgstr)
	PApp::I18n::DPO_Writer self
        SV *	msgid
        SV *	msgstr
        CODE:
        sv_utf8_upgrade (msgid);
        sv_utf8_upgrade (msgstr);
{
	STRLEN len1, len2;
        unsigned char *xmsgid  = SvPV (msgid , len1);
        unsigned char *xmsgstr = SvPV (msgstr, len2);
        HASH hval = hash (xmsgid, len1) % self->hdr->hashsize;
        struct dpo_str str;
        OFS ofs;

        SKIP_META (xmsgid, len1);

        ofs = self->ofs;

        /* align to sizeof OFS */
        ofs += sizeof (OFS) - 1;
        ofs -= ofs % sizeof (OFS);
        
        str.len1 = len1;
        str.len2 = len2;

        str.next = self->hdr->hash[hval];
        self->hdr->hash[hval] = ofs;

        lseek (self->fd, ofs, SEEK_SET);
        ofs += write (self->fd, &str, sizeof (struct dpo_str));
        ofs += write (self->fd, xmsgid , len1);
        ofs += write (self->fd, xmsgstr, len2);

        self->ofs = ofs;
}
        
void
DESTROY(self)
	PApp::I18n::DPO_Writer self
        CODE:
        lseek (self->fd, 0, SEEK_SET);
        write (self->fd, self->hdr, SIZEOF_HDR (self->hdr->hashsize));
        close (self->fd);
        Safefree (self->hdr);
        Safefree (self);

MODULE = PApp::I18n		PACKAGE = PApp::I18n::Table

PApp::I18n::Table
new(class, path = 0, lang = &PL_sv_undef)
	SV *	class
	char *	path
        SV *	lang
        CODE:
{
        int fd;
        void *start = 0;
        size_t length;

        if (path && *path)
          {
            struct dpo_head *hdr;

            fd = open (path, O_RDONLY);
            if (fd <= 0)
              croak ("unable to open translation table '%s': %s", path, strerror (errno));

            length = lseek (fd, 0, SEEK_END);

            if (length < sizeof (struct dpo_head))
              croak ("%s: translation table too short to be valid", path);

            start = mmap (0, length, PROT_READ, MAP_SHARED, fd, 0);

            if (start == MAP_FAILED)
              croak ("unable to mmap translation table '%s': %s", path, strerror (errno));

            close (fd);

            hdr = (struct dpo_head *)start;
            if (hdr->sig == DPO_SIG)
              {
                if (hdr->version != DPO_VERSION)
                  croak ("%s: unsupported translation table version (%d)", path, hdr->version);
              }
            else if (hdr->sig == DPO_SIG_SWAP)
              croak ("%s: invalid translation table (probably byteswapped)", path);
            else
              croak ("%s: invalid translation table", path);
          }

        Newz(0, RETVAL, 1, struct dpo_table);
        RETVAL->start = start;
        RETVAL->length = length;
        RETVAL->lang = newSVsv (lang);
}
	OUTPUT:
        RETVAL

SV *
lang(self)
	PApp::I18n::Table self
        CODE:
        RETVAL = SvREFCNT_inc (self->lang);
	OUTPUT:
        RETVAL

void
DESTROY(self)
	PApp::I18n::Table self
        CODE:

        if (self->start)
          munmap (self->start, self->length);

        if (self->lang)
          SvREFCNT_dec (self->lang);

        Safefree (self);

SV *
gettext(self, msgid)
	PApp::I18n::Table self
        SV *	msgid
        CODE:
{
        STRLEN len;
        char *xmsgid;
        
        if (!SvUTF8 (msgid)) /* optimization */
          sv_utf8_upgrade (msgid);

        xmsgid = SvPV (msgid, len);
        SKIP_META (xmsgid, len);

        if (self->start)
          {
            struct dpo_head *hdr = (struct dpo_head *)self->start;
            HASH hval = hash (xmsgid, len) % hdr->hashsize;
            OFS ofs = hdr->hash[hval];

            while (ofs)
              {
                struct dpo_str *str = (struct dpo_str *)(((char *)self->start) + ofs);

                if (str->len1 == len && memcmp (str + 1, xmsgid, len) == 0)
                  {
                    RETVAL = newSVpvn (((char *)(str + 1)) + len, str->len2);
                    goto found;
                  }

                ofs = str->next;
              }
          }

        /* default: return "original" string */
        RETVAL = newSVpvn (xmsgid, len);
found:
        SvUTF8_on (RETVAL);
}        
        OUTPUT:
        RETVAL

