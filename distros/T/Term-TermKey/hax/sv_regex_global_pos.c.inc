/* vi: set ft=c : */

#ifndef SV_POSBYTES

/* any value will do; it's just for our own purposes */
#define SV_POSBYTES (1<<0)

/* Before perl 5.41.10, the only way to access the regex global `pos` position
 * was direct interaction with the PERL_MAGIC_regex_global magic's mg_len
 * field.
 */

#define sv_regex_global_pos_get(sv, posp, flags)  S_sv_regex_global_pos_get(aTHX_ sv, posp, flags)
static bool S_sv_regex_global_pos_get(pTHX_ SV *sv, STRLEN *posp, U32 flags)
{
  /* TODO: This implementation only supports SV_POSBYTES, not zero flags */
  assert(flags & SV_POSBYTES);

  if(SvTYPE(sv) < SVt_PVMG || !SvMAGIC(sv))
    return FALSE;

  MAGIC *mg = mg_find(sv, PERL_MAGIC_regex_global);
  if(!mg || mg->mg_len == (STRLEN)-1)
    return FALSE;

  *posp = mg->mg_len;
  return TRUE;
}

#define sv_regex_global_pos_set(sv, pos, flags)  S_sv_regex_global_pos_set(aTHX_ sv, pos, flags)
static void S_sv_regex_global_pos_set(pTHX_ SV *sv, STRLEN pos, U32 flags)
{
  assert(flags & SV_POSBYTES);

  MAGIC *mg = SvTYPE(sv) >= SVt_PVMG ? mg_find(sv, PERL_MAGIC_regex_global) : NULL;
  if(!mg)
    mg = sv_magicext(sv, NULL, PERL_MAGIC_regex_global, &PL_vtbl_mglob, NULL, 0);

  mg->mg_len = pos;
}

#endif
