#include <osp-preamble.h>
#include <osperl.h>
#include "osp_hkey.h"


SV *hkey::to_sv()
{
  // ignore zero termination for easy coersion to numbers
  if (!this || !this->pv || this->len < 2) return &PL_sv_undef;
  return sv_2mortal(newSVpv(this->pv, this->len-1));
}

hkey::hkey() : pv(0)
{ }
hkey::hkey(const hkey &k1) : pv(0)
{ this->operator=(k1); }
hkey::hkey(const char *s1) : pv(0)
{ this->s(s1, strlen(s1)+1); }
hkey::~hkey()
{ set_undef(); }

int hkey::valid()
{ return pv != 0; }

void hkey::set_undef()
{
  len=0;
  if (pv) delete [] pv;
  pv=0;
}

hkey *hkey::operator=(const hkey &k1)
{
  set_undef();
  len = k1.len;
  if (len) {
    NEW_OS_ARRAY(pv, os_segment::of(this), os_typespec::get_char(), char, len);
//    pv = new(os_segment::of(this), os_typespec::get_char(), len) char[len];
//    warn("fill '%s'\n", k1.pv);
    memcpy(pv, k1.pv, len);
  }
  DEBUG_hash(warn("hkey(0x%x)->operator=(%s=0x%x,%d)",
		  this, pv?pv:"(null)", pv, len));
  return this;
}

hkey *hkey::operator=(const char *k1)
{
  this->s(k1, strlen(k1)+1);
  return this;
}

void hkey::s(const char *k1, os_unsigned_int32 nlen)
{
  set_undef();
  len = nlen;
  if (len) {
    NEW_OS_ARRAY(pv, os_segment::of(this), os_typespec::get_char(), char, len);
//    pv = new(os_segment::of(this), os_typespec::get_char(), len) char[len];
//    warn("fill '%s'\n", k1);
    memcpy(pv, k1, len);
  }
  DEBUG_hash(warn("hkey(0x%x)->s(%s=0x%x,%d)",
		  this, pv?pv:"(null)", pv, len));
}

os_unsigned_int32 hkey::hash(os_void_const_p v1)
{
  const hkey *s1 = (hkey*)v1;
  if (s1->len > 8) {
    return ((os_int32*) s1->pv)[0] ^ ((os_int32*) s1->pv)[1] ^ s1->len;
  } else if (!s1->pv || s1->len == 0) {
    return 0;
  } else {
    os_int32 ret=s1->len;
    for (int xx=0; xx < s1->len; xx++) {
      ret = ret ^ (s1->pv[xx] << (8*xx));
      if (xx == 3) break;
    }
    return ret;
  }
}

int hkey::rank(os_void_const_p v1, os_void_const_p v2)
{
  const hkey *s1 = (hkey*)v1;
  const hkey *s2 = (hkey*)v2;
  if (s1->pv == 0 || s2->pv == 0) {
    if (s1->pv) return os_collection::GT;
    if (s2->pv) return os_collection::LT;
    return os_collection::EQ;
  } else {
    return strcmp(s1->pv, s2->pv);
  }
}

