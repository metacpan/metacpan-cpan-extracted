#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "perlmulticore.h"

// portable impl
#include "crc32csb8.c"

static uint32_t (*crc32c) (uint32_t crc, const void *data, size_t length) = crc32cSlicingBy8;

// optimized sse4.2 impl
#if __GNUC__ >= 8 && (__i386__ || __x86_64__) && __SSE4_2__ /* for __builtin__crc32 */

#include <cpuid.h>
#include "crc32intelc.c"

static const char *
detect (void)
{
  unsigned int eax, ebx, ecx = 0, edx;

  __get_cpuid (1, &eax, &ebx, &ecx, &edx);

  if (ecx & bit_SSE4_2)
    {
      crc32c = crc32cIntelC;
      return "IntelCSSE42";
    }

  return "SlicingBy8";
}

#else

static const char *
detect (void)
{
  return "SlicingBy8";
}

#endif

MODULE = String::CRC32C		PACKAGE = String::CRC32C

BOOT:
	perlmulticore_support ();
	sv_setpv (get_sv ("String::CRC32C::IMPL", GV_ADD), detect ());

PROTOTYPES: ENABLE

U32 crc32c (SV *data, U32 initvalue = 0)
	CODE:
{
	STRLEN len;
	const char *ptr = SvPVbyte (data, len);
	if (len > 65536) perlinterp_release ();
	RETVAL = ~crc32c (~initvalue, ptr, len);
	if (len > 65536) perlinterp_acquire ();
}
	OUTPUT: RETVAL


