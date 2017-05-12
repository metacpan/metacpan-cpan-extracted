#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "RPM.h"

static int scalar_tag(int);

/* This unpacks a header data-field obtainted with headerGetEntry()
   into the perl SV*, which is either scalar value or array reference */
static SV* rpmhdr_unpack(pTHX_ int tag, int type, const void *data, int size)
{
    AV* new_list;
    SV* new_item;
    int idx;

    /*
      Bad enough to have to duplicate the loop for all the case branches, I
      can at least bitch out on two of them:
    */
    if (type == RPM_NULL_TYPE)
        return &PL_sv_undef;

    new_list = newAV();

    if (type == RPM_BIN_TYPE)
    {
        /* This differs from other types in that here size is the length of
           the binary chunk itself */
        av_store(new_list, 0, newSVpv(data, size));
    }
    else
    {
        /* There will be at least this many items: */
        av_extend(new_list, size);

        switch (type)
        {
          case RPM_CHAR_TYPE:
            {
                const char* loop;

                for (loop = data, idx = 0; idx < size; idx++, loop++)
                    sv_setpvn(*av_fetch(new_list, idx, TRUE), loop, 1);
                break;
            }
          case RPM_INT8_TYPE:
            {
                const I8* loop;

                for (loop = data, idx = 0; idx < size; idx++, loop++)
                    /* Note that the rpm lib also uses masks for INT8 */
                    sv_setiv(*av_fetch(new_list, idx, TRUE),
                             (I32)(*loop & 0xff));
                break;
            }
          case RPM_INT16_TYPE:
            {
                const I16* loop;

                for (loop = data, idx = 0; idx < size; idx++, loop++)
                    /* Note that the rpm lib also uses masks for INT16 */
                    sv_setiv(*av_fetch(new_list, idx, TRUE),
                             (I32)(*loop & 0xffff));
                break;
            }
          case RPM_INT32_TYPE:
            {
                const I32* loop;

                for (loop = data, idx = 0; idx < size; idx++, loop++)
                    sv_setiv(*av_fetch(new_list, idx, TRUE), *loop);
                break;
            }
          case RPM_STRING_TYPE:
          case RPM_I18NSTRING_TYPE:
          case RPM_STRING_ARRAY_TYPE:
            {
                const char* const* loop;

                /* Special case for exactly one RPM_STRING_TYPE */
                if (type == RPM_STRING_TYPE && size == 1)
                    sv_setpv(*av_fetch(new_list, 0, TRUE), data);
                else
                {
                    for (loop = data, idx = 0; idx < size; idx++, loop++)
                        sv_setpv(*av_fetch(new_list, idx, TRUE), *loop);

                    /* Only for STRING_ARRAY_TYPE do we have to call free() */
                    if (type == RPM_STRING_ARRAY_TYPE) Safefree(data);
                }
                break;
            }
          default:
            rpmError(RPMERR_BADARG, "Unimplemented type %d for rpm tag %s",
                     type, rpmtag_iv2pv(aTHX_ tag));
            Perl_warn(aTHX_ "%s: %s", "RPM::Header", SvPV_nolen(rpm_errSV));
            break;
        }
    }

    if (scalar_tag(tag))
    {
        SV **svp = av_fetch(new_list, 0, FALSE);
        new_item = &PL_sv_undef;
        if (svp && SvOK(*svp)) {
            new_item = *svp;
            SvREFCNT_inc(new_item);
        }
        av_undef(new_list);
        sv_free((SV *) new_list);
    }
    else
        new_item = newRV_noinc((SV *)new_list);

    return new_item;
}

RPM__Header rpmhdr_TIEHASH_header(pTHX_ const Header h)
{
    RPM_Header *hdr;
    Newz(0, hdr, 1, RPM_Header);
    hdr->hdr = h;
    headerNVR(hdr->hdr, &hdr->name, &hdr->version, &hdr->release);
    return hdr;
}

RPM__Header rpmhdr_TIEHASH_new(pTHX)
{
    Header h = headerNew();
    return rpmhdr_TIEHASH_header(aTHX_ h);
}

RPM__Header rpmhdr_TIEHASH_FD(pTHX_ const FD_t Fd)
{
    Header h;
    int isSource = 0;
    RPM_Header *hdr = Null(RPM_Header *);
    sv_setiv(rpm_errSV, 0);
#if RPM_VERSION >= 0x040100
    if (rpmReadHeader(NULL, Fd, &h, NULL))
#else
    if (rpmReadPackageHeader(Fd, &h, &isSource, Null(int *), Null(int *)))
#endif
    {
        /* Some cases of this failing, rpmError was already called. But not
           all cases, unfortunately. So check the IV part of rpm_errSV */
        if (SvIV(rpm_errSV) == 0)
            rpmError(RPMERR_READ, "Error reading package header");
        return hdr;
    }
    hdr = rpmhdr_TIEHASH_header(aTHX_ h);
    if (hdr)
        hdr->isSource = isSource;
    return hdr;
}

RPM__Header rpmhdr_TIEHASH_fd(pTHX_ const int fd)
{
    RPM_Header *hdr = Null(RPM_Header *);
    FD_t Fd = fdDup(fd);
    if (!Fd) {
        rpmError(RPMERR_BADARG, "Bad file descriptor %d", fd);
        return hdr;
    }
    hdr = rpmhdr_TIEHASH_FD(aTHX_ Fd);
    Fclose(Fd);
    return hdr;
}

RPM__Header rpmhdr_TIEHASH_file(pTHX_ const char *path)
{
    RPM_Header *hdr = Null(RPM_Header *);
    FD_t Fd = Fopen(path, "r");
    if (!Fd) {
        rpmError(RPMERR_BADFILENAME, "Unable to open file `%s'", path);
        return hdr;
    }
    hdr = rpmhdr_TIEHASH_FD(aTHX_ Fd);
    if (hdr)
        hdr->source_name = savepv(path);
    Fclose(Fd);
    return hdr;
}

SV* rpmhdr_FETCH(pTHX_ RPM__Header hdr, RPM_Tag tag)
{
    void *data;
    int type;
    int size;

    /* Check the three keys that are cached directly on the struct itself: */
    if (tag == RPMTAG_NAME && hdr->name)
        return newSVpv((char *)hdr->name, 0);
    else if (tag == RPMTAG_VERSION && hdr->version)
        return newSVpv((char *)hdr->version, 0);
    else if (tag == RPMTAG_RELEASE && hdr->release)
        return newSVpv((char *)hdr->release, 0);

    if (headerGetEntry(hdr->hdr, tag, &type, &data, &size))
        return rpmhdr_unpack(aTHX_ tag, type, data, size);

    rpmError(RPMERR_BADARG, "%s: no tag `%s' in header",
            "RPM::Header::FETCH", rpmtag_iv2pv(aTHX_ tag));
    return &PL_sv_undef;
}

/*
  Store the data in "value" both in the header and in the hash associated
  with "self".
*/
int rpmhdr_STORE(pTHX_ RPM__Header hdr, RPM_Tag tag, SV* value)
{
    SV** svp;
    int size, i;
    I32 data_type = -1;
    void* data = NULL;
    AV* a_value = Nullav;

    if (SvROK(value))
    {
        /*
          This is complicated. We have to allow for straight-in AV*, or a
          single-pair HV* that provides the type indexing the data. Then
          we get to decide if the data part needs to be promoted to an AV*.
        */
        if (SvTYPE(SvRV(value)) == SVt_PVHV)
        {
            HE* iter;
            SV* key;
            SV* new_value;
            HV* hv_value = (HV *)SvRV(value);

            /* There should be exactly one key */
            if (hv_iterinit(hv_value) != 1)
            {
                rpmError(RPMERR_BADARG,
                        "%s: Hash reference passed in for tag `%s' has invalid content",
                        "RPM::Header::STORE", rpmtag_iv2pv(aTHX_ tag));
                return 0;
            }
            iter = hv_iternext(hv_value);
            key = HeSVKEY(iter);
            new_value = HeVAL(iter);
            if (! (SvIOK(key) && (data_type = SvIV(key))))
            {
                rpmError(RPMERR_BADARG,
                        "%s: Hash reference key passed in for tag `%s' is invalid",
                        "RPM::Header::STORE", rpmtag_iv2pv(aTHX_ tag));
                return 0;
            }
            /* Clear this for later sanity-check */
            value = Nullsv;
            /* Now let's look at new_value */
            if (SvROK(new_value))
            {
                if (SvTYPE(SvRV(new_value)) == SVt_PVAV)
                    a_value = (AV *)SvRV(new_value);
                else
                    /* Hope for the best... */
                    value = SvRV(new_value);
            }
            else
                value = new_value;
        }
        else if (SvTYPE(SvRV(value)) == SVt_PVAV)
        {
            /*
              If they passed a straight-through AV*, de-ref it and mark type
              to be filled in later
            */
            a_value = (AV *)SvRV(value);
            /* A size of 0 means this is an attempt at autovivification... */
            if (av_len(a_value) == -1)
                /* ...which isn't allowed here. Nip it before it starts. */
                return 0;
            data_type = -1;
            value = Nullsv;
        }
        else
        {
            /* De-reference it and hope it passes muster as a scalar */
            value = SvRV(value);
        }
    }

    /* The only way value will still be set is if nothing else matched */
    if (value != Nullsv)
    {
        /*
          The case-block below is already set up to handle data in a manner
          transparent to the quantity or type. We can fake this with a_value
          and not worry again until actually storing on the hash table for
          self.
        */
        a_value = (AV*)sv_2mortal((SV*)newAV());
        SvREFCNT_inc(value);
        av_store(a_value, 0, value);
        /* Mark type for later setting */
        data_type = -1;
    }
    size = av_len(a_value) + 1;

    /*
      Setting/STORE-ing means do the following:

      1. Confirm that data adheres to type (mostly check against int types)
      2. Create the blob in **data (based on is_scalar)
      3. Store to the header struct
      4. Store the SV* on the hash
    */

    if (data_type == -1)
    {
        data_type = rpmhdr_tagtype(aTHX_ hdr, tag);
        if (data_type == RPM_NULL_TYPE)
        {
            /*
              If header does not exist, then this has not been fetched
              previously, and worse, we don't really know what the type is
              supposed to be. So we state in the docs that the default is
              RPM_STRING_TYPE.
            */
            data_type = RPM_STRING_TYPE;
        }
    }

    if (data_type == RPM_INT8_TYPE ||
        data_type == RPM_INT16_TYPE ||
        data_type == RPM_INT32_TYPE)
    {
        /* Cycle over the array and verify that all elements are valid IVs */
        for (i = 0; i < size; i++)
        {
            svp = av_fetch(a_value, i, FALSE);
            if (! (SvOK(*svp) && SvIOK(*svp)))
            {
                rpmError(RPMERR_BADARG,
                          "RPM::Header::STORE: Non-integer value passed for "
                          "integer-type tag");
                return 0;
            }
        }
    }

    /*
      This is more like the rpmhdr_unpack case block, where we have to
      discern based on data-type, so that the pointers are properly
      allocated and assigned.
    */
    switch (data_type)
    {
      case RPM_NULL_TYPE:
        size = 1;
        data = NULL;
        break;
      case RPM_BIN_TYPE:
        {
            char* data_p;

            svp = av_fetch(a_value, 0, FALSE);
            if (svp && SvPOK(*svp))
                data_p = SvPV(*svp, size);
            else
            {
                size = 0;
                data_p = Nullch;
            }

            data = (void *)data_p;
            break;
        }
      case RPM_CHAR_TYPE:
        {
            char* data_p;
            char* str_sv;
            STRLEN len;

            Newz(TRUE, data_p, size, char);
            for (i = 0; i < size; i++)
            {
                /* Having stored the chars in separate SVs wasn't the most
                   efficient way, but it made the rest of things a lot
                   cleaner. To be safe, only take the initial character from
                   each SV. */
                svp = av_fetch(a_value, i, FALSE);
                if (svp && SvPOK(*svp))
                {
                    str_sv = SvPV(*svp, len);
                    data_p[i] = str_sv[0];
                }
                else
                    data_p[i] = '\0';
            }

            data = (void *)data_p;
            break;
        }
      case RPM_INT8_TYPE:
        {
            I8* data_p;

            Newz(TRUE, data_p, size, I8);

            for (i = 0; i < size; i++)
            {
                svp = av_fetch(a_value, i, FALSE);
                if (svp && SvIOK(*svp))
                    data_p[i] = (I8)SvIV(*svp);
                else
                    data_p[i] = (I8)0;
            }

            data = (void *)data_p;
            break;
        }
      case RPM_INT16_TYPE:
        {
            I16* data_p;

            Newz(TRUE, data_p, size, I16);

            for (i = 0; i < size; i++)
            {
                svp = av_fetch(a_value, i, FALSE);
                if (svp && SvIOK(*svp))
                    data_p[i] = (I16)SvIV(*svp);
                else
                    data_p[i] = (I16)0;
            }

            data = (void *)data_p;
            break;
        }
      case RPM_INT32_TYPE:
        {
            I32* data_p;

            Newz(TRUE, data_p, size, I32);

            for (i = 0; i < size; i++)
            {
                svp = av_fetch(a_value, i, FALSE);
                if (svp && SvIOK(*svp))
                    data_p[i] = SvIV(*svp);
                else
                    data_p[i] = 0;
            }

            data = (void *)data_p;
            break;
        }
      case RPM_STRING_TYPE:
      case RPM_I18NSTRING_TYPE:
      case RPM_STRING_ARRAY_TYPE:
        {
            char** data_p;
            char* str_sv;
            char* str_new;
            SV* cloned;
            STRLEN len;

            if (data_type == RPM_STRING_TYPE && size == 1)
            {
                /* Special case for exactly one RPM_STRING_TYPE */
                svp = av_fetch(a_value, 0, FALSE);
                if (svp)
                {
                    if (SvPOK(*svp))
                        cloned = *svp;
                    else
                        cloned = sv_mortalcopy(*svp);
                    str_sv = SvPV(cloned, len);
                    New(0, str_new, len+1, char);
                    strncpy(str_new, str_sv, len + 1);
                }
                else
                    str_new = Nullch;

                data = (void **)str_new;
            }
            else
            {
                Newz(TRUE, data_p, size, char*);

                for (i = 0; i < size; i++)
                {
                    svp = av_fetch(a_value, i, FALSE);
                    if (svp)
                    {
                        if (SvPOK(*svp))
                            cloned = *svp;
                        else
                            cloned = sv_mortalcopy(*svp);
                        str_sv = SvPV(*svp, len);
                        New(0, str_new, len+1, char);
                        strncpy(str_new, str_sv, len + 1);
                        data_p[i] = str_new;
                    }
                    else
                        data_p[i] = Nullch;
                }

                data = (void *)data_p;
            }
            break;
        }
      default:
        rpmError(RPMERR_BADARG, "Unimplemented tag type");
        break;
    }
    /* That was fun. I always enjoy delving into the black magic of void *. */

    /* Remove any pre-existing tag */
    headerRemoveEntry(hdr->hdr, tag); /* Don't care if it fails? */
    /* Store the new data */
    headerAddEntry(hdr->hdr, tag, data_type, data, size);
    /* Store on the hash */

    if (tag == RPMTAG_NAME || tag == RPMTAG_VERSION || tag == RPMTAG_RELEASE)
        headerNVR(hdr->hdr, &hdr->name, &hdr->version, &hdr->release);
    return 1;
}

int rpmhdr_DELETE(pTHX_ RPM__Header hdr, RPM_Tag tag)
{
    headerRemoveEntry(hdr->hdr, tag);   /* XXX */
    if (tag == RPMTAG_NAME || tag == RPMTAG_VERSION || tag == RPMTAG_RELEASE)
        headerNVR(hdr->hdr, &hdr->name, &hdr->version, &hdr->release);
    return 1;
}

bool rpmhdr_EXISTS(pTHX_ RPM__Header hdr, RPM_Tag tag)
{
    return headerIsEntry(hdr->hdr, tag);
}

int rpmhdr_FIRSTKEY(pTHX_ RPM__Header hdr, RPM_Tag *tagp, SV **valuep)
{
    /* If there is an existing iterator attached to the struct, free it */
    if (hdr->iterator)
        headerFreeIterator(hdr->iterator);

    /* The init function returns the iterator that is used in later calls */
    hdr->iterator = headerInitIterator(hdr->hdr);

    return rpmhdr_NEXTKEY(aTHX_ hdr, 0, tagp, valuep);
}

int rpmhdr_NEXTKEY(pTHX_ RPM__Header hdr, RPM_Tag prev_tag,
                   RPM_Tag *tagp, SV **valuep)
{
    int type, size;
    const void *data;

    (void) prev_tag;

    /* If there is not an existing iterator, we can't continue */
    if (! hdr->iterator) {
        warn("%s called before FIRSTKEY", "RPM::Header::NEXTKEY");
        return 0;
    }

    /* Iterate here, since there are internal tags that may be present for
       which we don't want to expose to the user. */
    while (1)
    {
        /* Run it once, to get the next header entry */
        if (! headerNextIterator(hdr->iterator, tagp, &type, &data, &size)) {
            /* Last tag. Inform perl that iteration is over. */
            headerFreeIterator(hdr->iterator);
            hdr->iterator = Null(HeaderIterator);
            return 0;
        }

        /* This means that any time num2tag couldn't map it, we iterate */
        if (rpmtag_iv2pv(aTHX_ *tagp))
            break;
    }

    *valuep = rpmhdr_unpack(aTHX_ *tagp, type, data, size);
    return 1;
}

void rpmhdr_DESTROY(pTHX_ RPM__Header hdr)
{

    if (! hdr) return;

    if (hdr->iterator)
        headerFreeIterator(hdr->iterator);
    if (hdr->hdr)
        headerFree(hdr->hdr);

    Safefree(hdr->source_name);
    Safefree(hdr);
}

void rpmhdr_CLEAR(pTHX_ RPM__Header hdr)
{
    if (hdr->iterator)
        headerFreeIterator(hdr->iterator);
    if (hdr->hdr)
        headerFree(hdr->hdr);
    Safefree(hdr->source_name);
    Zero(hdr, 1, RPM_Header);
    hdr->hdr = headerNew();
}

unsigned int rpmhdr_size(pTHX_ RPM__Header hdr)
{
    if (! hdr->hdr)
        return 0;
    else
        return(headerSizeof(hdr->hdr, HEADER_MAGIC_YES));
}

int rpmhdr_tagtype(pTHX_ RPM__Header hdr, RPM_Tag tag)
{
    int type;

    if (headerGetEntry(hdr->hdr, tag, &type, NULL, NULL))
        return type;

    switch (tag) {
    case RPMTAG_NAME:
    case RPMTAG_VERSION:
    case RPMTAG_RELEASE:
        return RPM_STRING_TYPE;
    case RPMTAG_EPOCH:
        return RPM_INT32_TYPE;
    default:
        return RPM_NULL_TYPE;
    }
}

int rpmhdr_write(pTHX_ RPM__Header hdr, SV* gv_in, int magicp)
{
    IO* io;
    PerlIO* fp;
    FD_t fd;
    GV* gv;
    int written = 0;

    gv = (SvPOK(gv_in) && (SvTYPE(gv_in) == SVt_PVGV)) ?
        (GV *)SvRV(gv_in) : (GV *)gv_in;

    if (!gv || !(io = GvIO(gv)) || !(fp = IoIFP(io)))
        return written;

    fd = fdDup(PerlIO_fileno(fp));
    headerWrite(fd, hdr->hdr, magicp);
    Fclose(fd);
    written = headerSizeof(hdr->hdr, magicp);

    return written;
}

/*
  A classic-style comparison function for two headers, returns -1 if a < b,
  1 if a > b, and 0 if a == b. In terms of version/release, that is.
*/
int rpmhdr_cmpver(pTHX_ RPM__Header one, RPM__Header two)
{
    return rpmVersionCompare(one->hdr, two->hdr);
}

/*
  A matter-of-convenience function that tells whether the passed-in tag is
  one that returns a scalar (yields a true return value) or one that returns
  an array reference (yields a false value).
*/
static int scalar_tag(int tag_value)
{
    /* self is passed in as SV*, and unused, because this is a class method */
    switch (tag_value)
    {
      case RPMTAG_ARCH:
      case RPMTAG_ARCHIVESIZE:
      case RPMTAG_BUILDHOST:
      case RPMTAG_BUILDROOT:
      case RPMTAG_BUILDTIME:
      case RPMTAG_COOKIE:
      case RPMTAG_DESCRIPTION:
      case RPMTAG_DISTRIBUTION:
      case RPMTAG_EPOCH:
      case RPMTAG_EXCLUDEARCH:
      case RPMTAG_EXCLUDEOS:
      case RPMTAG_EXCLUSIVEARCH:
      case RPMTAG_EXCLUSIVEOS:
      case RPMTAG_GIF:
      case RPMTAG_GROUP:
      case RPMTAG_ICON:
      case RPMTAG_INSTALLTIME:
      case RPMTAG_LICENSE:
      case RPMTAG_NAME:
      case RPMTAG_OS:
      case RPMTAG_PACKAGER:
      case RPMTAG_RELEASE:
      case RPMTAG_RPMVERSION:
      case RPMTAG_SIZE:
      case RPMTAG_SOURCERPM:
      case RPMTAG_SUMMARY:
      case RPMTAG_URL:
      case RPMTAG_VENDOR:
      case RPMTAG_VERSION:
      case RPMTAG_XPM:
        return 1;
        /* not reached */
        break;
      default:
        return 0;
        /* not reached */
        break;
    }
    /* not reached */
}

#ifndef HEADER_DUMP_INLINE
/* from header_internal.h */
void headerDump(Header h, FILE *f, int flags,
		const struct headerTagTableEntry_s * tags)
	/*@modifies f, fileSystem @*/;
#define HEADER_DUMP_INLINE   1
#endif

MODULE = RPM::Header    PACKAGE = RPM::Header           PREFIX = rpmhdr_


RPM::Header
rpmhdr_TIEHASH(class, source=NULL)
    const char *class;
    SV *source;
    PROTOTYPE: $;$
    CODE:
    (void) class;
    if (source == NULL)
        RETVAL = rpmhdr_TIEHASH_new(aTHX);
    else if (SvPOK(source))
        RETVAL = rpmhdr_TIEHASH_file(aTHX_ SvPV_nolen(source));
    else
        RETVAL = rpmhdr_TIEHASH_fd(aTHX_ PerlIO_fileno(IoIFP(sv_2io(source))));
    OUTPUT:
    RETVAL

SV*
rpmhdr_FETCH(self, tag)
    RPM::Header self;
    RPM_Tag tag;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmhdr_FETCH(aTHX_ self, tag);
    OUTPUT:
    RETVAL

int
rpmhdr_STORE(self, tag, value)
    RPM::Header self;
    RPM_Tag tag;
    SV* value;
    PROTOTYPE: $$$
    CODE:
    RETVAL = rpmhdr_STORE(aTHX_ self, tag, value);
    OUTPUT:
    RETVAL

int
rpmhdr_DELETE(self, tag)
    RPM::Header self;
    RPM_Tag tag;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmhdr_DELETE(aTHX_ self, tag);
    OUTPUT:
    RETVAL

void
rpmhdr_CLEAR(self)
    RPM::Header self;
    PROTOTYPE: $
    CODE:
    rpmhdr_CLEAR(aTHX_ self);

bool
rpmhdr_EXISTS(self, tag)
    RPM::Header self;
    RPM_Tag tag;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmhdr_EXISTS(aTHX_ self, tag);
    OUTPUT:
    RETVAL

void
rpmhdr_FIRSTKEY(self)
    RPM::Header self;
    PROTOTYPE: $
    PPCODE:
    {
        RPM_Tag tag;
        SV* value;

        if (rpmhdr_FIRSTKEY(aTHX_ self, &tag, &value))
        {
            XPUSHs(sv_2mortal(value));
            XPUSHs(sv_2mortal(rpmtag_iv2sv(aTHX_ tag)));
        }

    }

void
rpmhdr_NEXTKEY(self, prev_tag=0)
    RPM::Header self;
    RPM_Tag prev_tag;
    PROTOTYPE: $;$
    PPCODE:
    {
        RPM_Tag tag;
        SV* value;

        if (rpmhdr_NEXTKEY(aTHX_ self, prev_tag, &tag, &value))
        {
            XPUSHs(sv_2mortal(value));
            XPUSHs(sv_2mortal(rpmtag_iv2sv(aTHX_ tag)));
        }
    }

void
rpmhdr_DESTROY(self)
    RPM::Header self;
    PROTOTYPE: $
    CODE:
    rpmhdr_DESTROY(aTHX_ self);

unsigned int
rpmhdr_size(self)
    RPM::Header self;
    PROTOTYPE: $
    CODE:
    RETVAL = rpmhdr_size(aTHX_ self);
    OUTPUT:
    RETVAL

int
rpmhdr_tagtype(self, tag)
    RPM::Header self;
    RPM_Tag tag;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmhdr_tagtype(aTHX_ self, tag);
    OUTPUT:
    RETVAL

int
rpmhdr_write(self, gv, magicp=0)
    RPM::Header self;
    SV* gv;
    SV* magicp;
    PROTOTYPE: $$;$
    CODE:
    {
        int flag;

        if (magicp && SvIOK(magicp))
            flag = SvIV(magicp);
        else
            flag = HEADER_MAGIC_YES;

        RETVAL = rpmhdr_write(aTHX_ self, gv, flag);
    }
    OUTPUT:
    RETVAL

bool
rpmhdr_is_source(self)
    RPM::Header self;
    PROTOTYPE: $
    CODE:
    RETVAL = self->isSource;
    OUTPUT:
    RETVAL

int
rpmhdr_cmpver(self, other)
    RPM::Header self;
    RPM::Header other;
    PROTOTYPE: $$
    CODE:
    RETVAL = rpmhdr_cmpver(aTHX_ self, other);
    OUTPUT:
    RETVAL

void
rpmhdr_NVR(self)
    RPM::Header self;
    PROTOTYPE: $
    PPCODE:
    {
        RPM_Header* hdr = self;

        if (hdr->name)
        {
            XPUSHs(sv_2mortal(newSVpv((char *)hdr->name, 0)));
            XPUSHs(sv_2mortal(newSVpv((char *)hdr->version, 0)));
            XPUSHs(sv_2mortal(newSVpv((char *)hdr->release, 0)));
        }
    }

bool
rpmhdr_scalar_tag(self, tag)
    SV* self;
    RPM_Tag tag;
    PROTOTYPE: $$
    CODE:
    (void) self;
    RETVAL = scalar_tag(tag);
    OUTPUT:
    RETVAL

const char *
rpmhdr_source_name(self)
    RPM::Header self;
    PROTOTYPE: $
    CODE:
    RETVAL = self->source_name;
    OUTPUT:
    RETVAL

void
rpmhdr_dump(self, fh=stdout)
    RPM::Header self;
    FILE * fh;
    PROTOTYPE: $;$
    CODE:
    headerDump(self->hdr, fh, HEADER_DUMP_INLINE, rpmTagTable);
