#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/types.h>

/**************************************************************************************
* some of the code for the CPU information was copied and modilefied from             *
*  the source for Unix::Processors. All code contained herein in free to use and edit *
*  under the same licence as Perl itself.                                             *
*                                                                                     *
**************************************************************************************/

#define MAX_IDENT_SIZE 256
#if defined(_WIN32) || defined(WIN32)
  #define _have_cpu_type
  #define _have_cpu_clock
  #define WINDOWS
#endif

#ifdef WINDOWS /* WINDOWS */
 #include <stdlib.h>
 #include <windows.h>
 #include <winbase.h>
 #include <winreg.h>
#else                /* other (try unix) */
 #include <unistd.h>
 #include <sys/unistd.h>
#endif
#if defined(__sun) || defined(__sun__)
 #include <sys/processor.h>
#endif
#ifdef _HPUX_SOURCE
 #include <pthread.h>
 #include <sys/pstat.h>
 #define _have_cpu_clock
 #define _have_cpu_type
#endif
#ifdef __APPLE__
 #include <sys/sysctl.h>
 #define _have_cpu_clock
 #define _have_cpu_type
#endif
#ifdef __FreeBSD__
 #include <sys/sysctl.h>
 #define _have_cpu_type
 #define _have_cpu_clock
#endif
#ifdef WINDOWS
/* Registry Functions */

int GetSysInfoKey(char *key_name,char *output) {
  // Get values from registry, use REGEDIT to see how data is stored while sample is running
  int ret;
  HKEY hTestKey, hSubKey;
  DWORD dwRegType, dwBuffSize;

  // Access using preferred 'Ex' functions
  if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, "Hardware\\Description\\System\\CentralProcessor", 0, KEY_READ,  &hTestKey) == ERROR_SUCCESS) {
    if (RegOpenKey(hTestKey, "0",  &hSubKey) == ERROR_SUCCESS) {
      dwBuffSize = MAX_IDENT_SIZE;
      ret = RegQueryValueEx(hSubKey, key_name, NULL,  &dwRegType,  output,  &dwBuffSize);
      if (ret != ERROR_SUCCESS) {
        sprintf(output,"Failed to get Value for key : %d\n",GetLastError());
        return(1);
      }
      RegCloseKey(hSubKey);
    } else {
      sprintf(output,"Failed to open sub-key : %d\n",GetLastError());
      return(1);
    }
    RegCloseKey(hTestKey);
  }
  else
  {
    sprintf(output,"Failed to open test key : %d\n",GetLastError());
    return(1);
  }
  return(0);
}

#endif /* WINDOWS */

#ifdef _HPUX_SOURCE

/*
 * HP specific function to return the clock-speed of a specified CPU in MHz.
 */
int proc_get_mhz(int id) {
    struct pst_processor st;
    int result = 0;
    if( !(result = pstat_getprocessor(&st, sizeof(st), (size_t)1, id)) ) {

        /* Maybe the CPU id too high, so try for CPU 0, instead. */
        result = pstat_getprocessor(&st, sizeof(st), (size_t)1, 0);
    }

    if( result ) {
        return st.psp_iticksperclktick * sysconf(_SC_CLK_TCK) / 1000000;
    }

    /* Call failed - return 0 for unknown clock speed. */
    return 0;
}

/*
 * Depending on your version of HP-UX, you may or may not already have these
 * but we need them, so make sure that they are defined.
 */
#ifndef CPU_PA_RISC1_0
#define CPU_PA_RISC1_0      0x20B    /* HP PA-RISC1.0 */
#endif

#ifndef CPU_PA_RISC1_1
#define CPU_PA_RISC1_1      0x210    /* HP PA-RISC1.1 */
#endif

#ifndef CPU_PA_RISC1_2
#define CPU_PA_RISC1_2      0x211    /* HP PA-RISC1.2 */
#endif

#ifndef CPU_PA_RISC2_0
#define CPU_PA_RISC2_0      0x214    /* HP PA-RISC2.0 */
#endif

#ifndef CPU_PA_RISC_MAX
#define CPU_PA_RISC_MAX     0x2FF    /* Maximum for HP PA-RISC systems. */
#endif

#ifndef CPU_IA64_ARCHREV_0
#define CPU_IA64_ARCHREV_0  0x300    /* IA-64 archrev 0 */
#endif

const char *proc_get_type_name () {
    long cpuvers = sysconf(_SC_CPU_VERSION);

    switch(cpuvers) {
        case CPU_PA_RISC1_0:
            return "HP PA-RISC1.0";
        case CPU_PA_RISC1_1:
            return "HP PA-RISC1.1";
        case CPU_PA_RISC1_2:
            return "HP PA-RISC1.2";
        case CPU_PA_RISC2_0:
            return "HP PA-RISC2.0";
        case CPU_IA64_ARCHREV_0:
            return "IA-64 archrev 0";
        default:
            if( CPU_IS_PA_RISC(cpuvers) ) {
          return "HP PA-RISC";
      }
    }

    return "UNKNOWN HP-UX";
}

#endif /* _HPUX_SOURCE */

#ifdef __APPLE__

#ifndef POWERPC_G3
#define POWERPC_G3 0xcee41549
#endif

#ifndef POWERPC_G4
#define POWERPC_G4 0x77c184ae
#endif

#ifndef POWERPC_G5
#define POWERPC_G5 0xed76d8aa
#endif

#ifndef INTEL_6_13
#define INTEL_6_13 0xaa33392b
#endif
#ifndef ARM_9
#define ARM_9 0xe73283ae
#endif

#ifndef ARM_11
#define ARM_11 0x8ff620d8
#endif

#ifndef INTEL_PENRYN
#define INTEL_PENRYN 0x78ea4fbc
#endif

#ifndef INTEL_NEHALEM
#define INTEL_NEHALEM 0x6b5a4cd2
#endif

#ifndef INTEL_CORE
#define INTEL_CORE 0x73d67300
#endif

#ifndef INTEL_CORE2
#define INTEL_CORE2 0x426f69ef
#endif

#ifndef INTEL_COREI7
#define INTEL_COREI7 0x5490B78C
#endif

char *apple_get_type_name() {
  int mib[2];
  size_t len=2;
  int kp;

  sysctlnametomib ("hw.cpufamily", mib, &len);
  sysctl(mib, 2, NULL, &len, NULL, 0);
  sysctl(mib, 2, &kp, &len, NULL, 0);
    switch (kp) {
                case POWERPC_G3:
                   return "POWERPC_G3";
                case POWERPC_G4:
                   return "POWERPC_G4";
                case POWERPC_G5:
                   return "POWERPC_G5";
                case INTEL_6_13:
                   return "INTEL_6_13";
                case ARM_9:
                   return "ARM_9";
                case ARM_11:
                   return "ARM_11";
                case INTEL_PENRYN:
                   return "INTEL_PENRYN";
                case INTEL_NEHALEM:
                   return "INTEL_NEHALEM";
                case INTEL_CORE:
                   return "INTEL_CORE";
                case INTEL_CORE2:
                   return "INTEL_CORE2";
                case INTEL_COREI7:
                   return "INTEL_COREI7";
    default:
       return "UNKNOWN";
        }
}
#endif /* __APPLE__ */
/* the following few functions were shamlessly taken from UNIX::Processors *
 * to make this linux compatable. No linux machine to test on, so had to   *
 * use existing code                                                       */

#ifdef __linux__

#define _have_cpu_type
#define _have_cpu_clock

/* Return string from a field of /proc/cpuinfo, NULL if not found */
/* Comparison is case insensitive */
char *proc_cpuinfo_field (const char *field) {
    FILE *fp;
    static char line[1000];
    int len = strlen(field);
    char *result = NULL;
    if (NULL!=(fp = fopen ("/proc/cpuinfo", "r"))) {
      while (!feof(fp) && result==NULL) {
        if (NULL == fgets (line, 990, fp) && !feof(fp)) break;
        if (0==strncasecmp (field, line, len)) {
          char *loc = strchr (line, ':');
          if (loc) {
            result = loc+2;
            loc = strchr (result, '\n');
            if (loc) *loc = '\0';
          }
        }
      }
      fclose(fp);
    }
    return (result);
}

/* Return clock frequency */
int proc_cpuinfo_clock (void) {
    char *value;
    value = proc_cpuinfo_field ("cpu MHz");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("clock");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("bogomips");
    if (value) return (atoi(value));
    return (0);
}

#if defined __s390__ || defined __s390x__

/* Return machine value from s390 processor line, NULL if not found */
char *processor_machine_field (char *processor) {
    char *machine = NULL;
    if (NULL == processor) {
      return NULL;
    }
    if (NULL != (machine = strstr(processor, "machine = "))) {
      machine += 10;
    }
    return machine;
}
#endif

#endif

int get_cpu_count() {
    int ret;

#ifdef WINDOWS /* WINDOWS */
   SYSTEM_INFO info;

   GetSystemInfo(&info);
   ret = info.dwNumberOfProcessors;
#else               /*other (try *nix)*/
#ifdef _HPUX_SOURCE /* HP-UX */
    ret = pthread_num_processors_np();
#else               /*other unix - try sysconf*/
    ret = (int )sysconf(_SC_NPROCESSORS_ONLN);
#endif  /* HP-UX */
#endif  /* WINDOWS */
    return ret;
}
MODULE = Sys::CPU   PACKAGE = Sys::CPU

int
cpu_count()
CODE:
{
    int i = 0;
    i = get_cpu_count();
    if (i) {
      ST(0) = sv_newmortal();
      sv_setiv (ST(0), i);
    } else {
      ST(0) = &PL_sv_undef;
    }
}


int
cpu_clock()
CODE:
{
    int clock = 0;
#ifdef __linux__
    int value = proc_cpuinfo_clock();
    if (value) clock = value;
#endif
#ifdef __FreeBSD__
    size_t len = sizeof(clock);
    sysctlbyname("hw.clockrate", &clock, &len, NULL, 0);
#endif
#ifdef WINDOWS
    char *clock_str = malloc(MAX_IDENT_SIZE);
    /*!! untested !!*/
    if (GetSysInfoKey("~MHz",clock_str)) {
        clock = 0;
    } else {
        clock = atoi(clock_str);
    }
#endif /* not linux, not windows, not hpux */
#ifdef _HPUX_SOURCE
    /* Try to get the clock speed for processor 0 - assume all the same. */
    clock = proc_get_mhz(0);
#endif
#ifdef __APPLE__
    int mib[2];
    unsigned int freq;
    size_t len;

    mib[0] = CTL_HW;
    mib[1] = HW_CPU_FREQ;
    len = sizeof(freq);
    sysctl(mib, 2, &freq, &len, NULL, 0);
    clock = freq/1000000;
#endif
#ifndef _have_cpu_clock
    processor_info_t info, *infop=&info;
    if ( processor_info(0, infop) == 0 && infop->pi_state == P_ONLINE) {
        if (clock < infop->pi_clock) {
            clock = infop->pi_clock;
        }
    }
#endif
    if (clock) {
      ST(0) = sv_newmortal();
      sv_setiv (ST(0), clock);
    } else {
      ST(0) = &PL_sv_undef;
    }
}

SV *
cpu_type()
CODE:
{
    char *value = NULL;
#ifdef __FreeBSD__
    size_t len = MAX_IDENT_SIZE;
    sysctlbyname("hw.model", value, &len, NULL, 0);
#endif
#ifdef __linux__
#if defined __s390__ || defined __s390x__
    value = processor_machine_field (proc_cpuinfo_field ("processor") );
#endif
    if (!value) value = proc_cpuinfo_field ("model name");
    if (!value) value = proc_cpuinfo_field ("machine");
    if (!value) value = proc_cpuinfo_field ("vendor_id");
#endif
#ifdef WINDOWS
    if (GetSysInfoKey("Identifier", value)) {
        value = NULL;
    }
#endif
#ifdef _HPUX_SOURCE
    value = proc_get_type_name();
#endif
#ifdef __APPLE__
    value = apple_get_type_name();
#endif
#ifndef _have_cpu_type  /* not linux, not windows */
    processor_info_t info, *infop=&info;
    if (processor_info (0, infop)==0) {
  value = infop->pi_processor_type;
    }
#endif
    if (value) {
      ST(0) = sv_newmortal();
      sv_setpv (ST(0), value);
    } else {
      ST(0) = &PL_sv_undef;
    }
}


