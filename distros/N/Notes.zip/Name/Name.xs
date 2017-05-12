#define BLOCK Perl_BLOCK

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "notesname.h"

MODULE = Notes::Name   PACKAGE = Notes::Session

PROTOTYPES: DISABLE


void
create_name( s, ln_in_name )
      LN_Session *   s;
      char       *   ln_in_name;
   PREINIT:
      d_LN_XSVARS;
      STATUS         ln_rc = NOERROR;
	  DN_COMPONENTS  DNComp;
	  HV * 			 ln_hash = (HV *) NULL;
	  AV *			 ln_OU_array = (AV *) NULL;
	  AV *			 ln_CMT_array = (AV *) NULL;
	  SV *			 sv = (SV *) NULL;
	  short          i;
	  char           tmp[MAXUSERNAME];
	  char           ln_abbrev_name[MAXUSERNAME];
	  char           ln_canonical_name[MAXUSERNAME];
   ALIAS:
      createname = 0
   PPCODE:
   	  if(ln_rc = DNParse(0L, NULL, ln_in_name, &DNComp, sizeof(DNComp)))
   	  {
		  LN_SET_IVX(s, ln_rc);
		  XSRETURN_NOT_OK;
      }
      if(ln_rc = DNCanonicalize(0L, NULL, ln_in_name, (char FAR *)ln_canonical_name,
     	    						MAXUSERNAME, NULL))
	  {
 		  LN_SET_IVX(s, ln_rc);
  		  XSRETURN_NOT_OK;
      }
      if(ln_rc = DNAbbreviate(0L, NULL, ln_in_name, (char FAR *)ln_abbrev_name,
     	    						MAXUSERNAME, NULL))
	  {
 		  LN_SET_IVX(s, ln_rc);
  		  XSRETURN_NOT_OK;
      }

	  ln_hash      = (HV *)sv_2mortal((SV *)newHV());
	  ln_OU_array  = (AV *)sv_2mortal((SV *)newAV());
	  ln_CMT_array = (AV *)sv_2mortal((SV *)newAV());

      //printf ("Flags:  %lu\n", DNComp.Flags);

	  sv = newSVpv(ln_abbrev_name, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Abbreviated", 11, sv, 0);

	  sv = newSVpv(ln_canonical_name, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Canonical", 9, sv, 0);

      strncpy(tmp, DNComp.C, DNComp.CLength);
      tmp[DNComp.CLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Country", 7, sv, 0);

      strncpy(tmp, DNComp.O, DNComp.OLength);
      tmp[DNComp.OLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Organization", 12, sv, 0);

      //for ( i = 0; i < DN_OUNITS, DNComp.OULength[i]; i++)
      //{
      //   strncpy (tmp, DNComp.OU[i], DNComp.OULength[i]);
      //   tmp[DNComp.OULength[i]] = '\0';
      //   sv = newSVpv(tmp, 0);
      //   SvREADONLY_on(sv);
      //   av_store(ln_OU_array, i, sv);
      //}
      //SvREADONLY_on((SV *)ln_OU_array);
      //hv_store(ln_hash, "OrgUnits", 8, ln_OU_array, 0);

      strncpy(tmp, DNComp.CN, DNComp.CNLength);
      tmp[DNComp.CNLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Common", 6, sv, 0);

      strncpy(tmp, DNComp.Domain, DNComp.DomainLength);
      tmp[DNComp.DomainLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Domain", 6, sv, 0);

      strncpy(tmp, DNComp.PRMD, DNComp.PRMDLength);
      tmp[DNComp.PRMDLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "PRMD", 4, sv, 0);

      strncpy(tmp, DNComp.ADMD, DNComp.ADMDLength);
      tmp[DNComp.ADMDLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "ADMD", 4, sv, 0);

      strncpy(tmp, DNComp.G, DNComp.GLength);
      tmp[DNComp.GLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Given", 5, sv, 0);

      strncpy(tmp, DNComp.S, DNComp.SLength);
      tmp[DNComp.SLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Surname", 7, sv, 0);

      strncpy(tmp, DNComp.I, DNComp.ILength);
      tmp[DNComp.ILength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Initials", 8, sv, 0);

      strncpy(tmp, DNComp.Q, DNComp.QLength);
      tmp[DNComp.QLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
	  hv_store(ln_hash, "Generation", 10, sv, 0);

      strncpy(tmp, DNComp.Phrase, DNComp.PhraseLength);
      tmp[DNComp.PhraseLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Addr822Phrase", 13, sv, 0);

      strncpy(tmp, DNComp.LP, DNComp.LPLength);
      tmp[DNComp.LPLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Addr822LocalPart", 16, sv, 0);

      strncpy(tmp, DNComp.R, DNComp.RLength);
      tmp[DNComp.RLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Addr822Route", 12, sv, 0);

      //for ( i = 0; i < DN_MAX_COMMENTS, DNComp.CMTLength[i]; i++)
      //{
      //   strncpy (tmp, DNComp.CMT[i], DNComp.CMTLength[i]);
      //   tmp[DNComp.CMTLength[i]] = '\0';
      //   printf ("Internet Address Comment:  %s\n", tmp);
      //}

      strncpy(tmp, DNComp.Address821, DNComp.Address821Length);
      tmp[DNComp.Address821Length] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Addr821", 7, sv, 0);

      strncpy(tmp, DNComp.HierarchyOnly, DNComp.HierarchyOnlyLength);
      tmp[DNComp.HierarchyOnlyLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "HierarchyOnly", 13, newSVpv(tmp, 0), 0);

      strncpy(tmp, DNComp.UID, DNComp.UIDLength);
      tmp[DNComp.UIDLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "LDAPUid", 7, sv, 0);

      strncpy(tmp, DNComp.L, DNComp.LLength);
      tmp[DNComp.LLength] = '\0';
      sv = newSVpv(tmp, 0);
      SvREADONLY_on(sv);
      hv_store(ln_hash, "Locality", 8, sv, 0);

	  LN_PUSH_NEW_HASH_OBJ( "Notes::Name", s );
	  LN_SET_OK( s );
	  XSRETURN ( 1 );


MODULE = Notes::Name	 PACKAGE = Notes::Name

void
DESTROY( name )
      LN_Name *   name;
   PPCODE:
      XSRETURN( 0 );