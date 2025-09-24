/* vi: set ft=c : */

/* TODO: This only adds cop_disable_warning. Still need to add
 *   cop_has_warning
 *   cop_enable_warning
 */

#ifndef Perl_Warn_Off_
#  define Perl_Warn_Off_(x)           ((x) / 8)
#  define Perl_Warn_Bit_(x)           (1 << ((x) % 8))
#endif

#ifndef cop_disable_warning
#  define cop_disable_warning(cop, warn_bit)  S_cop_disable_warning(aTHX_ cop, warn_bit)
void S_cop_disable_warning(pTHX_ COP *cop, int warn_bit)
{
#if HAVE_PERL_VERSION(5,37,6)
  /* cop_warnings no longer has the weird STRLEN prefix on it
   *   https://github.com/Perl/perl5/pull/20469
   */
  char *warnings = cop->cop_warnings;
#  define WARNING_BITS  warnings
#else
  STRLEN *warnings = cop->cop_warnings;
#  define WARNING_BITS  (char *)(warnings + 1)
#endif
  char *warning_bits;

  if(warnings == pWARN_NONE)
    return;

  if(warnings == pWARN_STD)
    /* TODO: understand what STD vs ALL means */
    warning_bits = WARN_ALLstring;
  else if(warnings == pWARN_ALL)
    warning_bits = WARN_ALLstring;
  else
    warning_bits = WARNING_BITS;

  warnings = Perl_new_warnings_bitfield(aTHX_ warnings, warning_bits, WARNsize);
  cop->cop_warnings = warnings;

  warning_bits = WARNING_BITS;
  warning_bits[Perl_Warn_Off_(2*warn_bit)] &= ~Perl_Warn_Bit_(2*warn_bit);

#undef WARNING_BITS
}
#endif
