/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2009 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef HAVE_UNIBILIUM
# include <unibilium.h>
#else
# include <term.h>
#endif

static void load_terminfo(const char *termtype,
  HV *flags_by_capname, HV *nums_by_capname, HV *strs_by_capname,
  HV *flags_by_varname, HV *nums_by_varname, HV *strs_by_varname
)
{
  int i;
  SV *sv;

#ifdef HAVE_UNIBILIUM
  unibi_term *unibi = unibi_from_term(termtype);
  if(!unibi) {
    croak("unibi_from_term(\"%s\"): %s", termtype, strerror(errno));
  }
#else
  TERMINAL *oldterm = cur_term;
  setupterm(termtype, 0, NULL);
#endif

#ifdef HAVE_UNIBILIUM
  for(i = unibi_boolean_begin_+1; i < unibi_boolean_end_; i++)
#else
  for(i = 0; boolnames[i]; i++)
#endif
  {
#ifdef HAVE_UNIBILIUM
    const char *capname = unibi_short_name_bool(i);
    const char *varname = unibi_name_bool(i);
    int value = unibi_get_bool(unibi, i);
#else
    const char *capname = boolnames[i];
    const char *varname = boolfnames[i];
    int value = tigetflag(capname);
#endif

    if(!value)
      continue;

    sv = newSViv(1);
    SvREADONLY_on(sv);

    hv_store(flags_by_capname, capname, strlen(capname), sv, 0);
    hv_store(flags_by_varname, varname, strlen(varname), SvREFCNT_inc(sv), 0);
  }

#ifdef HAVE_UNIBILIUM
  for(i = unibi_numeric_begin_+1; i < unibi_numeric_end_; i++)
#else
  for(i = 0; numnames[i]; i++)
#endif
  {
#ifdef HAVE_UNIBILIUM
    const char *capname = unibi_short_name_num(i);
    const char *varname = unibi_name_num(i);
    int value = unibi_get_num(unibi, i);
#else
    const char *capname = numnames[i];
    const char *varname = numfnames[i];
    int value = tigetnum(capname);
#endif

    if(value == -1)
      continue;

    sv = newSViv(value);
    SvREADONLY_on(sv);

    hv_store(nums_by_capname, capname, strlen(capname), sv, 0);
    hv_store(nums_by_varname, varname, strlen(varname), SvREFCNT_inc(sv), 0);
  }

#ifdef HAVE_UNIBILIUM
  for(i = unibi_string_begin_+1; i < unibi_string_end_; i++)
#else
  for(i = 0; strnames[i]; i++)
#endif
  {
#ifdef HAVE_UNIBILIUM
    const char *capname = unibi_short_name_str(i);
    const char *varname = unibi_name_str(i);
    const char *value = unibi_get_str(unibi, i);
#else
    const char *capname = strnames[i];
    const char *varname = strfnames[i];
    const char *value = tigetstr(capname);
#endif

    if(!value)
      continue;

    sv = newSVpv(value, 0);
    SvREADONLY_on(sv);

    hv_store(strs_by_capname, capname, strlen(capname), sv, 0);
    hv_store(strs_by_varname, varname, strlen(varname), SvREFCNT_inc(sv), 0);
  }

#ifdef HAVE_UNIBILIUM
  unibi_destroy(unibi);
#else
  oldterm = set_curterm(oldterm);
  del_curterm(oldterm);
#endif
}

MODULE = Term::Terminfo    PACKAGE = Term::Terminfo

void
_init(self)
    HV *self

  PREINIT:
    char *termtype;
    HV *flags_by_capname, *nums_by_capname, *strs_by_capname;
    HV *flags_by_varname, *nums_by_varname, *strs_by_varname;

  CODE:
    termtype = SvPV_nolen(*hv_fetch(self, "term", 4, 0));

    flags_by_capname = newHV();
    nums_by_capname  = newHV();
    strs_by_capname  = newHV();

    flags_by_varname = newHV();
    nums_by_varname  = newHV();
    strs_by_varname  = newHV();

    load_terminfo(termtype,
      flags_by_capname, nums_by_capname, strs_by_capname,
      flags_by_varname, nums_by_varname, strs_by_varname
    );

    hv_store(self, "flags_by_capname", 16, newRV_noinc((SV*)flags_by_capname), 0);
    hv_store(self, "nums_by_capname",  15, newRV_noinc((SV*)nums_by_capname),  0);
    hv_store(self, "strs_by_capname",  15, newRV_noinc((SV*)strs_by_capname),  0);

    hv_store(self, "flags_by_varname", 16, newRV_noinc((SV*)flags_by_varname), 0);
    hv_store(self, "nums_by_varname",  15, newRV_noinc((SV*)nums_by_varname),  0);
    hv_store(self, "strs_by_varname",  15, newRV_noinc((SV*)strs_by_varname),  0);

    XSRETURN_UNDEF;
