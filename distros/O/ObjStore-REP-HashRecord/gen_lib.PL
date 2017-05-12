BEGIN { $^W=1; }

use strict;
use Fatal qw(open);
use lib './';
BEGIN {
    require "./HashRecord.pm";
    'ObjStore::REP::HashRecord'->import(qw(c_types $VERSION $Fspec));
}
use vars qw(%T @T $Indent $Base);
$Base = "OSPV_HashRecord";

@T = c_types;
for (my $x=0; $x < @T; $x++) { $T{ $T[$x] } = $x }

$Indent = 0;
sub indent {
    my ($x) = @_;
    $Indent += 2;
    $x->();
    $Indent -= 2;
}
sub out(@) { print(' 'x$Indent.join('', @_)."\n") }

sub preamble {
    out "// Yucky -*-C++-*- generated at ".localtime()." by HashRecord $VERSION";
    out;
}

sub print_defines {
    for (sort keys %T) {
	print "#define FT_$_".' 'x(25 - length)."$T{$_}\n";
    }
}

sub print_fetch {
    out "void $Base\::FETCH(SV *key)";
    out "{";
    indent sub {
	out "STRLEN klen;";
	out "char *kstr = SvPV(key, klen);";
	out "int fi = HR_key_2field(kstr, klen);";
	out "if (fi < 0) {";
	indent sub {
	    out "OSPV_Generic *fb = (OSPV_Generic *) HR_get_fallback();";
	    out "if (!fb) return;";
	    out "fb->FETCH(key);";
	    out "return;";
	};
	out "}";
	out "$Fspec *spec = HR_get_field_spec(fi);";
	out "switch (spec->type) {";
	for my $t (@T) {
	    out "case FT_$t:{";
	    indent sub {
		out "$t *fp = ($t *) (((char*)this)+spec->offset);";
		if ($t eq 'OSPVptr') {
		    out "SV *ret = osp_thr::ospv_2sv(*fp);";
		    out "dSP;";
		    out "XPUSHs(ret);";
		} elsif ($t =~ m/^os_reference/) {
		    out "SV *ret = osp_thr::ospv_2sv((OSSVPV*) fp->resolve());";
		    out "dSP;";
		    out "XPUSHs(ret);";
		} elsif ($t eq 'OSSV') {
		    out "SV *ret = osp_thr::ossv_2sv(fp);";
		    out "dSP;";
		    out "XPUSHs(ret);";
		} elsif ($t =~ m/^ os_int(\d+) $/x) {
		    out "dSP;";
		    out "XPUSHs(sv_2mortal(newSViv(*fp)));";
		} elsif ($t =~ m/^osp_str(\d+)$/) {
		    out "dSP;";
		    out "if (fp->is_undef())";
		    indent sub { out "XPUSHs(&PL_sv_undef);" };
		    out "else {";
		    indent sub {
			out "STRLEN len; char *str = fp->get(&len);";
			out "XPUSHs(len? sv_2mortal(newSVpvn(str,len)) : &PL_sv_no);";
		    };
		    out "}";
		} elsif ($t =~ m/^double|float$/) {
		    out "dSP;";
		    out "XPUSHs(sv_2mortal(newSVnv(*fp)));";
		} elsif ($t =~ m/^char$/) {
		    out "dSP;";
		    out "XPUSHs(sv_2mortal(newSVpvn(fp, 1)));";
		} else {
		    warn "*** unknown type '$t'";
		}
		out "PUTBACK;";
		out "break;}"
	    };
	}
	out "default:";
	indent sub {
	    out qq[croak("%s(0x%p)->FETCH: $Fspec type %d unknown", os_class(&PL_na), this, spec->type);];
	};
	out "}";
    };
    out "}";
}

sub print_store {
    out "void $Base\::STORE(SV *key, SV *nval)";
    out "{";
    indent sub {
	out "STRLEN klen;";
	out "char *kstr = SvPV(key, klen);";
	out "int fi = HR_key_2field(kstr, klen);";
	out "if (fi < 0) {";
	indent sub {
	    out "OSPV_Generic *fb = (OSPV_Generic *) HR_get_fallback();";
	    out q[if (!fb) croak("Cannot create key '%s' in %s(0x%p)", kstr, os_class(&PL_na), this);];
	    out "fb->STORE(key,nval);";
	    out "return;";
	};
	out "}";
	out "$Fspec *spec = HR_get_field_spec(fi);";
	out qq[if (!HR_mod_field(fi)) croak("%s(0x%x): attempt to modify READONLY %s", os_class(&PL_na), this, spec->key);];
	out "switch (spec->type) {";
	for my $t (@T) {
	    out "case FT_$t:{";
	    indent sub {
		out "$t *fp = ($t *) (((char*)this)+spec->offset);";
		if ($t eq 'OSPVptr' or $t =~ m/^os_reference/) {
		    out "ospv_bridge *br = osp_thr::sv_2bridge(nval, 0, os_segment::of(this));";
		    out "*fp = br? br->ospv() : 0;";
		} elsif ($t eq 'OSSV') {
		    out "*fp = nval;";
		} elsif ($t =~ m/^ os_int(\d+) $/x) {
		    out "*fp = SvIV(nval);";
		} elsif ($t =~ m/^osp_str(\d+)$/) {
		    out "if (!SvOK(nval))";
		    indent sub { out "fp->set_undef();" };
		    out "else {";
		    indent sub {
			out "STRLEN len; char *pv = SvPV(nval, len);";
			out qq[if (len > $1) warn("Truncating string from length %d to %d", len, $1);];
			out "fp->set(pv,len);";
		    };
		    out "}";
		} elsif ($t =~ m/^double|float$/) {
		    out "*fp = SvNV(nval);";
		} elsif ($t =~ m/^char$/) {
		    out "*fp = *SvPV(nval, PL_na);";
		} else {
		    warn "*** unknown type '$t'";
		}
		out "break;}"
	    }
	}
	out "default:";
	indent sub {
	    out qq[croak("%s(0x%p)->STORE: $Fspec type %d unknown", os_class(&PL_na), this, spec->type);];
	};
	out "}";
    };
    out "}";
}

sub print_traverse1 {
    out "OSSVPV *$Base\::traverse1(osp_pathexam &exam)";
    out "{";
    indent sub {
        out "int fi = HR_key_2field(exam.get_thru(), exam.get_thru_len());";
        out "if (fi < 0) {";
	indent sub {
	    out "OSPV_Generic *fb = (OSPV_Generic *) HR_get_fallback();";
	    out "if (!fb) return 0;";
	    out "return fb->traverse1(exam);";
	};
	out "}";
        out "$Fspec *spec = HR_get_field_spec(fi);";
	out "switch (spec->type) {";
	for my $t (@T) {
            next unless $t eq 'OSPVptr' || $t =~ m/^os_reference/;
	    out "case FT_$t:{";
	    indent sub {
		out "$t *fp = ($t *) (((char*)this)+spec->offset);";
                if ($t eq 'OSPVptr') {
		    out "OSSVPV *pv = *fp;";
		} elsif ($t =~ m/^os_reference/) {
		    out "OSSVPV *pv = (OSSVPV*) fp->resolve();";
		} else {
		    warn "*** unknown type '$t'";
		}
		out "if (!pv) return 0;";
		out "HR_mod_field(exam, fi);";
                out "return pv;}";
            };
        }
	out "default: return 0;";
        out "}";
    };
    out "}";
}

sub print_traverse2 {
    out "OSSV *$Base\::traverse2(osp_pathexam &exam)";
    out "{";
    indent sub {
	out "int fi = HR_key_2field(exam.get_thru(), exam.get_thru_len());";
	out "if (fi < 0) {";
	indent sub {
	    out "OSPV_Generic *fb = (OSPV_Generic *) HR_get_fallback();";
	    out "if (!fb) return 0;";
	    out "return traverse2(exam);";
	};
	out "}";
	out "osp_hashrec_field_spec *spec = HR_get_field_spec(fi);";
	out "OSSV *ret = exam.get_tmpkey();";
	out "switch (spec->type) {";
	for my $t (@T) {
	    out "case FT_$t:{";
	    indent sub {
		out "$t *fp = ($t *) (((char*)this)+spec->offset);";
		if ($t eq 'OSPVptr' or $t =~ m/^os_reference/) {
		    out q[croak("path resolves to a ref (at %s)", exam.get_thru());];
		} elsif ($t eq 'OSSV') {
		    out "if (fp->is_set()) HR_mod_field(exam, fi);";
		    out "return fp;";
		} elsif ($t =~ m/^os_int(\d+)$/) {
		    out "HR_mod_field(exam, fi);";
		    out "ret->s((os_int32) *fp);";
		} elsif ($t =~ m/^osp_str(\d+)$/) {
		    out "if (fp->is_undef())";
		    indent sub { out "ret->set_undef();"; };
		    out "else {";
		    indent sub {
			out "HR_mod_field(exam, fi);";
			out "STRLEN len; char *str = fp->get(&len);";
			out "ret->s(str, len);";
		    };
		    out "}";
		} elsif ($t =~ m/^double|float$/) {
		    out "HR_mod_field(exam, fi);";
		    out "ret->s((double) *fp);";
		} elsif ($t =~ m/^char$/) {
		    out "HR_mod_field(exam, fi);";
		    out "ret->s(fp, 1);";
		} else {
		    warn "*** unknown type '$t'";
		}
		out "break;}"
	    };
	}
	out "default:";
	indent sub {
	    out qq[croak("%s(0x%p)->traverse2: $Fspec type %d unknown", os_class(&PL_na), this, spec->type);];
	};
	out "}";
	out "return ret;";
    };
    out "}";
}

open OUT, ">osp_hashrecord.h";
select OUT;

&preamble;
out "#ifndef _osp_hashrecord_h_";
out "#define _osp_hashrecord_h_";
out;
out q[#include <osperl.h>];
&print_defines;
out <<END;

#define HASHRECORD_API_VERSION 3

#define OSPV_phrREADONLY	0x0100  /* readonly flag */

struct $Fspec {
  int id;
  char *key;
  STRLEN keylen;
  int offset;
  int type;
  char *alias_to;
};

struct $Base : OSPV_Generic {
  static void use(const char *YourName, int ver);

  virtual char *rep_class(STRLEN *len);
  virtual int get_perl_type();
  virtual void FETCH(SV *key);
  virtual void STORE(SV *key, SV *value);
  virtual int EXISTS(SV *key);
  virtual void DELETE(SV *key);
  virtual void FIRST(osp_smart_object **);
  virtual void NEXT(osp_smart_object **);
  virtual OSSVPV *traverse1(osp_pathexam &exam);
  virtual OSSV *traverse2(osp_pathexam &exam);

  // YOU MUST IMPLEMENT:
  virtual char *os_class(STRLEN *len)=0;
  // & your XS 'new' method

  // TO BE GENERATED PER-SUBCLASS...
  virtual void make_constant()=0;
  virtual int HR_get_num_fields()=0;
  virtual int HR_key_2field(char *key, int klen)=0;
  virtual OSSVPV *HR_get_fallback();
  virtual $Fspec *HR_get_field_spec(int xx)=0;
  virtual int HR_mod_field(int xx)=0;
  virtual void HR_mod_field(osp_pathexam &exam, int xx)=0;
};

#endif
END

close OUT;

open OUT, ">librecord.c";
select OUT;

&preamble;
out q[extern "C" {];
out q[#include "EXTERN.h"];
out q[#include "perl.h"];
out q[#include "XSUB.h"];
out "}";
out q[#include "osp_hashrecord.h"];
out <<END;

void $Base\::use(const char *YourName, int ver)
{
  osp_thr::use("ObjStore::REP::HashRecord", OSPERL_API_VERSION);
  if (ver != HASHRECORD_API_VERSION)
    croak("ObjStore::HashRecord API mismatch (%d != %d); please recompile '%s'",
          HASHRECORD_API_VERSION, ver, YourName);
}

char *$Base\::rep_class(STRLEN *len)
{ *len = 20; return "ObjStore::REP::HashRecord"; }

int $Base\::get_perl_type()
{ return SVt_PVHV; }

OSSVPV *$Base\::HR_get_fallback() { return 0; }

int $Base\::EXISTS(SV *key)
{
  STRLEN klen;
  char *kstr = SvPV(key, klen);
  if (HR_key_2field(kstr, klen) >= 0) return 1;
  OSPV_Generic *fb = (OSPV_Generic *) HR_get_fallback();
  if (!fb) return 0;
  return fb->EXISTS(key);
}

void $Base\::DELETE(SV *key)
{
  STRLEN klen;
  char *kstr = SvPV(key, klen);
  if (HR_key_2field(kstr, klen) >= 0) {
    warn("Attempt to delete key '%s' from %s(0x%p) ignored",
         kstr, os_class(&PL_na), this);
    return;
  }
  OSPV_Generic *fb = (OSPV_Generic *) HR_get_fallback();
  if (!fb) return;
  fb->DELETE(key);
}

struct HR_bridge : osp_smart_object {
  int cursor;
  osp_smart_object *fb_cursor; //for fallback!
  HR_bridge() : cursor(0), fb_cursor(0) {}
  void reset() {
    cursor = 1;
    if (fb_cursor) { fb_cursor->freelist(); fb_cursor = 0; }
  }
  virtual ~HR_bridge() { reset(); }
};

void $Base\::FIRST(osp_smart_object **info)
{
  assert(info);
  if (! *info) *info = new HR_bridge;
  HR_bridge *br = (HR_bridge*) *info;
  br->reset();
  $Fspec *spec = HR_get_field_spec(0);
  dSP;
  XPUSHs(sv_2mortal(newSVpvn(spec->key, spec->keylen)));
  PUTBACK;
}

void $Base\::NEXT(osp_smart_object **info)
{
  assert(info);
  assert(*info);
  HR_bridge *br = (HR_bridge*) *info;
  if (br->cursor < HR_get_num_fields()) {
    $Fspec *spec = HR_get_field_spec(br->cursor++);
    dSP;
    XPUSHs(sv_2mortal(newSVpvn(spec->key, spec->keylen)));
    PUTBACK;
  } else {
    OSPV_Generic *fb = (OSPV_Generic*) HR_get_fallback();
    if (!fb) return;
    if (!br->fb_cursor) fb->FIRST(&br->fb_cursor);
    else fb->NEXT(&br->fb_cursor);
  }
}
END

&print_traverse1;
out;
&print_traverse2;
out;
&print_fetch;
out;
&print_store;

close OUT;

