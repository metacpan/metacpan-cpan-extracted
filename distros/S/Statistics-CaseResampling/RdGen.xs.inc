
MODULE = Statistics::CaseResampling		PACKAGE = Statistics::CaseResampling::RdGen PREFIX=mt_
PROTOTYPES: DISABLE

int
mt_CLONE_SKIP(...)
  CODE:
    RETVAL = 1;
  OUTPUT:
    RETVAL

Statistics::CaseResampling::RdGen
mt_setup(seed)
  U32     seed
  CODE:
    RETVAL = mt_setup(seed);
    if (RETVAL == NULL)
      croak("Out of memory allocating RdGen");
  OUTPUT:
    RETVAL

Statistics::CaseResampling::RdGen
mt_setup_array( array, ... )
  CODE:
    U32 * array = U32ArrayPtr(aTHX_ items);
    U32 ix_array = 0;
    while (items--) {
      array[ix_array] = (U32)SvUV(ST(ix_array));
      ix_array++;
    }
    RETVAL = mt_setup_array( (uint32_t*)array, ix_array );
    if (RETVAL == NULL)
      croak("Out of memory allocating RdGen");
  OUTPUT:
    RETVAL

void
mt__os_entropy(nwords)
    I32 nwords
  PREINIT:
    uint32_t buf[64];
    I32 i;
  PPCODE:
    if (nwords >= 1 && nwords <= 64 && mt_os_entropy(buf, nwords)) {
      EXTEND(SP, nwords);
      for (i = 0; i < nwords; ++i) {
        mPUSHu((UV)buf[i]);
      }
    }

void
mt__mark_auto_seeded(self, pid)
    Statistics::CaseResampling::RdGen self
    IV pid
  CODE:
    if (self == NULL)
      croak("Invalid RdGen object");
    self->auto_seeded = 1;
    self->pid = (long)pid;

void
mt_DESTROY(self)
    Statistics::CaseResampling::RdGen self
  CODE:
    mt_free(self);

double
mt_genrand(self)
    Statistics::CaseResampling::RdGen self
  CODE:
    if (self == NULL)
      croak("Invalid RdGen object");
    RETVAL = mt_genrand(self);
  OUTPUT:
    RETVAL

