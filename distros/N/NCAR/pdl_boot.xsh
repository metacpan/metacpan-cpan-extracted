BOOT:

   perl_require_pv ("PDL::Core"); /* make sure PDL::Core is loaded */
   CoreSV = perl_get_sv("PDL::SHARE",FALSE);  /* SV* value */
#ifndef aTHX_
#define aTHX_
#endif
   if (CoreSV==NULL)
     Perl_croak(aTHX_ "We require the PDL::Core module, which was not found");
   PDL = INT2PTR(Core*,SvIV( CoreSV ));  /* Core* value */
   if (PDL->Version != PDL_CORE_VERSION)
     Perl_croak(aTHX_ "The code needs to be recompiled against the newly installed PDL");

