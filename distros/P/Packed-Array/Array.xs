#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Packed::Array		PACKAGE = Packed::Array		

SV *
FETCH(this, index)
  SV *this
  SV *index
  PPCODE:
{

  IV index_offset = SvIV(index);
  SV *storage = SvRV(this);
  IV curlen = SvCUR(storage);
  IV byte_size;
  IV *data;
  IV number;

  /* Are we big enough? */
  byte_size = (index_offset + 1) * sizeof(IV);
  if (byte_size > curlen) {
    XPUSHs(sv_2mortal(newSViv(0)));
  } else {
    /* Now snag the pointer to storage out of the SV */
    data = (IV *)SvPVX(storage);
    number = data[index_offset];
    XPUSHs(sv_2mortal(newSViv(data[index_offset])));
  }
}

SV *
STORE(this, index, value)
  SV *this
  SV *index
  SV *value
  PPCODE:
{
  IV index_offset = SvIV(index);
  IV value_value = SvIV(value);
  SV *storage = SvRV(this);
  IV curlen = SvCUR(storage);
  IV byte_size;
  IV *data;

  /* Are we big enough? */
  byte_size = (index_offset + 1) * sizeof(IV);
  if (byte_size > curlen) {
    /* Apparently not. Go extend the buffer */
    char *temp = malloc(byte_size - curlen);
    Zero(temp, byte_size - curlen, char);
    sv_catpvn(storage, temp, byte_size - curlen);
    free(temp);
  }

  /* Now snag the pointer to storage out of the SV */
  data = (IV *)SvPVX(storage);
  data[index_offset] = value_value;
  XPUSHs(value);
}

SV *
TIEARRAY(classname, ...)
  SV *classname
  PPCODE:
{
  SV *rv;
  SV *tiething;
  HV *stash = gv_stashsv(classname, 0);
  tiething = newSVpvn("", 0); /* Begin with a zero-length string */
  rv = newRV_noinc(tiething);
  sv_bless(rv, stash);
  XPUSHs(rv);
}

SV *
FETCHSIZE(this)
  SV *this
  PPCODE:
{
  SV *thing = SvRV(this);
  XPUSHs(sv_2mortal(newSViv(SvCUR(thing) / sizeof(IV))));
}

SV *
STORESIZE(this, size)
  SV *this
  SV *size
  PPCODE:
{
  SV *thing = SvRV(this);
  IV curlen = SvIV(thing);
  IV newsize = SvIV(size) * sizeof(IV);
  IV byte_size;

  /* Are we big enough? */
  if (newsize > curlen) {
    /* Apparently not. Go extend the buffer */
    char *temp = malloc(newsize - curlen);
    Zero(temp, newsize - curlen, char);
    sv_catpvn(thing, temp, newsize - curlen);
    free(temp);
  } else {
    SvCUR(thing) = newsize;
  }

  XPUSHs(sv_2mortal(newSViv(SvCUR(thing) / sizeof(IV))));
}
