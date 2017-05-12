
MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling::RdGen PREFIX=mt_
PROTOTYPES: DISABLE

Statistics::CaseResampling::RdGen
mt_setup(seed)
  U32     seed
  CODE:
    RETVAL = mt_setup(seed);
  OUTPUT:
    RETVAL

Statistics::CaseResampling::RdGen
mt_setup_array( array, ... )
  CODE:
    U32 * array = U32ArrayPtr(aTHX_ items);
    U32 ix_array = 0;
    while (items--) {
      array[ix_array] = (U32)SvIV(ST(ix_array));
      ix_array++;
    }
    RETVAL = mt_setup_array( (uint32_t*)array, ix_array );
  OUTPUT:
    RETVAL

void
mt_DESTROY(self)
    Statistics::CaseResampling::RdGen self
  CODE:
    mt_free(self);

double
mt_genrand(self)
    Statistics::CaseResampling::RdGen self
  CODE:
    RETVAL = mt_genrand(self);
  OUTPUT:
    RETVAL

