#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

// portable impl
#include "crc32csb8.c"

static uint32_t (*crc32c) (uint32_t crc, const void *data, size_t length) = crc32cSlicingBy8;

// optimized sse4.2 impl
#if __GNUC__ >= 8 && (__i386__ || __x86_64__)

#include <cpuid.h>
#include "crc32intelc.c"

static void
detect (void)
{
  unsigned int eax, ebx = 0, ecx = 0, edx;

  if (__get_cpuid_max (0, 0) >= 1)
    __cpuid (1, eax, ebx, ecx, edx);

  if (ecx & bit_SSE4_2)
    crc32c = crc32cIntelC;
}

#else

static void
detect (void)
{
}

#endif

MODULE = String::CRC32C		PACKAGE = String::CRC32C

BOOT:
	detect ();

PROTOTYPES: ENABLE

U32 crc32c (SV *data, U32 initvalue = 0)
	CODE:
{
	STRLEN len;
	const char *ptr = SvPVbyte (data, len);
	RETVAL = ~crc32c (~initvalue, ptr, len);
}
	OUTPUT: RETVAL


