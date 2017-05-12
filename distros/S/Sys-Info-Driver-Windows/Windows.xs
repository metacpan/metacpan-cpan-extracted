#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <windows.h>
#include <commctrl.h>
#include <stdio.h>
#include <tchar.h>
#include <string.h>

#include "detect.h"

#include "include/cpu.h"

MODULE = Sys::Info::Driver::Windows  PACKAGE = Sys::Info::Driver::Windows

int
GetSystemMetrics(index)
    int index
CODE:
    RETVAL = GetSystemMetrics(index);
OUTPUT:
    RETVAL

void
GetSystemInfo()
PREINIT:
    OSVERSIONINFOEX osvi;
    SYSTEM_INFO     si;
    SYSTEM_INFO     si2;
    PGNSI           pGNSI;
    LPFN_ISWOW64PROCESS fnIsWow64Process;
    //PGPI            pGPI;
    BOOL            bOsVersionInfoEx;
    BOOL            bIsWow;
    //DWORD           dwType;
    TCHAR           wProcessorModel         [10];
    TCHAR           wProcessorStepping      [10];
    TCHAR           wProcessorArchitecture2 [64];
    unsigned int    wProcessBitness;
    unsigned int    wProcessorBitness;
PPCODE:
    /*
        See:
        - http://msdn.microsoft.com/en-us/library/ms724429(VS.85).aspx
        - http://blogs.msdn.com/junfeng/archive/2005/07/01/434574.aspx
    */

    ZeroMemory(&si,   sizeof(SYSTEM_INFO));
    ZeroMemory(&si2,  sizeof(SYSTEM_INFO));
    ZeroMemory(&osvi, sizeof(OSVERSIONINFOEX));

    osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFOEX);

    if( !(bOsVersionInfoEx = GetVersionEx ((OSVERSIONINFO *) &osvi)) )
        XSRETURN(1);
 
    // Copy the hardware information to the SYSTEM_INFO structure.
    pGNSI = (PGNSI) GetProcAddress(
                        GetModuleHandle( TEXT("kernel32.dll") ), 
                        "GetNativeSystemInfo"
                    );

    wProcessBitness   = 0;
    wProcessorBitness = 0;
    bIsWow = FALSE;

    (NULL != pGNSI) ? pGNSI(&si) : GetSystemInfo(&si);

    if ( VER_PLATFORM_WIN32_NT == osvi.dwPlatformId && osvi.dwMajorVersion > 4 ) {
        // We have Win2k or later
        EXTEND(SP, 26);

        switch (si.wProcessorArchitecture) {
            case PROCESSOR_ARCHITECTURE_ALPHA: 
                lstrcpy(  wProcessorArchitecture2, TEXT("Alpha"));
                wsprintf( wProcessorModel        , TEXT("%d"), HIBYTE(si.wProcessorRevision) );
                wsprintf( wProcessorStepping     , TEXT("%d"), LOBYTE(si.wProcessorRevision) );
                wProcessBitness   = 64;
                wProcessorBitness = 64;
                break;

            case PROCESSOR_ARCHITECTURE_IA64:
                lstrcpy(  wProcessorArchitecture2, TEXT("IA-64"));
                wsprintf( wProcessorModel        , TEXT("%d"), HIBYTE(si.wProcessorRevision) );
                wsprintf( wProcessorStepping     , TEXT("%d"), LOBYTE(si.wProcessorRevision) );
                wProcessBitness   = 64;
                wProcessorBitness = 64;
                break;

            case PROCESSOR_ARCHITECTURE_ALPHA64:
                lstrcpy(wProcessorArchitecture2  , TEXT("Alpha64"));
                wsprintf( wProcessorModel        , TEXT("%d"), HIBYTE(si.wProcessorRevision) );
                wsprintf( wProcessorStepping     , TEXT("%d"), LOBYTE(si.wProcessorRevision) );
                wProcessBitness   = 64;
                wProcessorBitness = 64;
                break;

            case PROCESSOR_ARCHITECTURE_INTEL:
                lstrcpy(  wProcessorArchitecture2, TEXT("x86") );
                wsprintf( wProcessorModel        , TEXT("%d"), HIBYTE(si.wProcessorRevision) );
                wsprintf( wProcessorStepping     , TEXT("%d"), LOBYTE(si.wProcessorRevision) );

                fnIsWow64Process = (LPFN_ISWOW64PROCESS) GetProcAddress(
                    GetModuleHandle( TEXT("kernel32.dll") ), 
                    "IsWow64Process"
                );

                if ( NULL != fnIsWow64Process ) {
                    if ( ! fnIsWow64Process(GetCurrentProcess(), &bIsWow) ){
                        croak("IsWow64Process failed with last error %d.", GetLastError());
                    } else {
                        if (bIsWow) {
                            pGNSI(&si2);
                            if (si2.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_IA64) {
                                wProcessBitness   = 32;
                                wProcessorBitness = 64;
                                lstrcpy( wProcessorArchitecture2, TEXT("IA-64") );
                            } else if (si2.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64) {
                                wProcessBitness   = 32;
                                wProcessorBitness = 64;
                                lstrcpy( wProcessorArchitecture2, TEXT("x64") );
                            } else {
                                croak("I am running in the future!");
                            }
                        } else {
                            /* wProcessorBitness = (si.wProcessorLevel == 6 && si.wProcessorRevision >= 14)
                                              ? 64 // Core2
                                              : 32; */
                            /*
                            This is tricky. Only way to get a correct value seems to be
                               (1) either using "intrin.h" -> No good with MinGW
                               (2) or using a WMI call -> too complex under XS
                            So, I set this to -1 instead and then try to correct
                            it in the Perl layer with a WMI call.
                            Any patches regarding this are welcome.
                            */
                            lstrcpy( wProcessorArchitecture2, TEXT("x86 or x86-64") );
                            wProcessorBitness = -1;
                            wProcessBitness   = 32;
                        }
                    }
                }

                break;

            case PROCESSOR_ARCHITECTURE_UNKNOWN:
            default:
                lstrcpy(  wProcessorArchitecture2, TEXT("") );
                lstrcpy(  wProcessorModel        , TEXT("") );
                lstrcpy(  wProcessorStepping     , TEXT("") );
                break;
        }

        // build the info hash
        // Processor
        // TODO: dwAllocationGranularity
        PUSHs( sv_2mortal( newSVpv( "dwNumberOfProcessors"         , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.dwNumberOfProcessors            ) ) );

        PUSHs( sv_2mortal( newSVpv( "dwProcessorType"              , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.dwProcessorType                 ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorArchitecture"       , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.wProcessorArchitecture          ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorLevel"              , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.wProcessorLevel                 ) ) );

        PUSHs( sv_2mortal( newSVpv( "dwActiveProcessorMask"        , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.dwActiveProcessorMask           ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorRevision"           , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.wProcessorRevision              ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorModel"              , 0 ) ) );
        PUSHs( sv_2mortal( newSVpv( wProcessorModel                , 0 ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorStepping"           , 0 ) ) );
        PUSHs( sv_2mortal( newSVpv( wProcessorStepping             , 0 ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorArchitecture2"      , 0 ) ) );
        PUSHs( sv_2mortal( newSVpv( wProcessorArchitecture2        , 0 ) ) );

        // other
        PUSHs( sv_2mortal( newSVpv( "dwOemId"                      , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.dwOemId                         ) ) );

        PUSHs( sv_2mortal( newSVpv( "dwPageSize"                   , 0 ) ) );
        PUSHs( sv_2mortal( newSViv( si.dwPageSize                      ) ) );

        PUSHs( sv_2mortal( newSVpv( "lpMinimumApplicationAddress"  , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.lpMinimumApplicationAddress     ) ) );

        PUSHs( sv_2mortal( newSVpv( "lpMaximumApplicationAddress"  , 0 ) ) );
        PUSHs( sv_2mortal( newSVuv( si.lpMaximumApplicationAddress     ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessBitness"              , 0 ) ) );
        PUSHs( sv_2mortal( newSViv(  wProcessBitness                   ) ) );

        PUSHs( sv_2mortal( newSVpv( "wProcessorBitness"            , 0 ) ) );
        PUSHs( sv_2mortal( newSViv(  wProcessorBitness                 ) ) );

    }
    else {
        croak( "GetSystemInfo() can not be run on this version of Windows.");
    }

void
CPUFeatures()
PREINIT:
    int      CPUInfo[4] = {-1};
    unsigned infoext[4];
    CPUDATA  cpu;
    ULONG    FeatureBits;
    unsigned i;
    unsigned ebx = 0;
    unsigned ecx = 0;
    unsigned CpuFeatures = 0;
    unsigned Flags;
    unsigned KFBits;
    unsigned FeatureFlags;
PPCODE:
    /*
        Resources:
        - http://msdn.microsoft.com/en-us/library/hskdteyh(VS.80).aspx
        - http://stackoverflow.com/questions/794632/programmatically-get-the-cache-line-size
        - http://en.wikipedia.org/wiki/CPUID

        __cpuid with an InfoType argument of 0 returns the number of
        valid Ids in CPUInfo[0] and the CPU identification string in
        the other three array elements. The CPU identification string is
        not in linear order. The code below arranges the information 
        in a human readable form.
    */
    __cpuid(CPUInfo, 0);
    cpu.Ids = CPUInfo[0];
    memset(cpu.String, 0, sizeof(cpu.String));
    *((int*)cpu.String)     = CPUInfo[1];
    *((int*)(cpu.String+4)) = CPUInfo[3];
    *((int*)(cpu.String+8)) = CPUInfo[2];

    // Get the information associated with each valid Id
    for ( i = 0; i <= cpu.Ids; ++i ) {
        __cpuid(CPUInfo, i);
        /*
        warn("\nFor InfoType %d\n", i);
        warn("CPUInfo[0] = 0x%x\n", CPUInfo[0]);
        warn("CPUInfo[1] = 0x%x\n", CPUInfo[1]);
        warn("CPUInfo[2] = 0x%x\n", CPUInfo[2]);
        warn("CPUInfo[3] = 0x%x\n", CPUInfo[3]);
        */
        // Interpret CPU feature information.
        if  ( i == 1 ) {
            ebx                        = CPUInfo[1];
            ecx                        = CPUInfo[2];
            CpuFeatures                = CPUInfo[3];
            cpu.SteppingID             =   CPUInfo[0]        & 0xf;
            cpu.Model                  =  (CPUInfo[0] >>  4) & 0xf;
            cpu.Family                 =  (CPUInfo[0] >>  8) & 0xf;
            cpu.ProcessorType          =  (CPUInfo[0] >> 12) & 0x3;
            cpu.Extendedmodel          =  (CPUInfo[0] >> 16) & 0xf;
            cpu.Extendedfamily         =  (CPUInfo[0] >> 20) & 0xff;
            cpu.BrandIndex             =   CPUInfo[1]        & 0xff;
            cpu.CLFLUSHcachelinesize   = ((CPUInfo[1] >>  8) & 0xff) * 8;
            cpu.APICPhysicalID         =  (CPUInfo[1] >> 24) & 0xff;
            cpu.SSE3NewInstructions    =  (CPUInfo[2] & 0x1  ) || 0;
            cpu.MONITOR_MWAIT          =  (CPUInfo[2] & 0x8  ) || 0;
            cpu.CPLQualifiedDebugStore =  (CPUInfo[2] & 0x10 ) || 0;
            cpu.ThermalMonitor2        =  (CPUInfo[2] & 0x100) || 0;
            cpu.FeatureInfo            =   CPUInfo[3];
        }
    }

    // Calling __cpuid with 0x80000000 as the InfoType argument
    // gets the number of valid extended IDs.
    __cpuid( CPUInfo, 0x80000000 );
    cpu.ExIds = CPUInfo[0];
    memset(cpu.BrandString, 0, sizeof(cpu.BrandString));

    if( cpu.ExIds >= 0x80000001 ) {
        __cpuid(infoext, 0x80000001);
        if( CF_MMX       & CpuFeatures ) Flags |= CF_MMX;
        if( CF_SSE       & CpuFeatures ) Flags |= CF_SSE;
        if( CF_SSE2      & CpuFeatures ) Flags |= CF_SSE2;
        if( CF_SSE3      & ecx         ) Flags |= CF_SSE3;
        if( CF_SSSE3     & ecx         ) Flags |= CF_SSSE3;
        if( CF_SSE41     & ecx         ) Flags |= CF_SSE41;
        if( CF_SSE42     & ecx         ) Flags |= CF_SSE42;
        if( CF_SSE5      & infoext[2]  ) Flags |= CF_SSE5;
        if( CF_SSE4A     & infoext[2]  ) Flags |= CF_SSE4A;
        if( CF_A3DNOW    & infoext[3]  ) Flags |= CF_A3DNOW;
        if( CF_MMXPLUS   & infoext[3]  ) Flags |= CF_MMXPLUS;
        if( CF_A3DNOWEXT & infoext[3]  ) Flags |= CF_A3DNOWEXT;
    }

    // Get the information associated with each extended ID.
    for ( i = 0x80000000; i <= cpu.ExIds; ++i ) {
        __cpuid(CPUInfo, i);
        /*
        warn("\nFor InfoType %x\n", i);
        warn("CPUInfo[0] = 0x%x\n", CPUInfo[0]);
        warn("CPUInfo[1] = 0x%x\n", CPUInfo[1]);
        warn("CPUInfo[2] = 0x%x\n", CPUInfo[2]);
        warn("CPUInfo[3] = 0x%x\n", CPUInfo[3]);
        */
        // Interpret CPU brand string and cache information.
        if  (i == 0x80000002)
            memcpy(cpu.BrandString, CPUInfo, sizeof(CPUInfo));
        else if  (i == 0x80000003)
            memcpy(cpu.BrandString + 16, CPUInfo, sizeof(CPUInfo));
        else if  (i == 0x80000004)
            memcpy(cpu.BrandString + 32, CPUInfo, sizeof(CPUInfo));
        else if  (i == 0x80000006) {
            cpu.L2CacheLineSize =  CPUInfo[2] & 0xff;
            cpu.L2Associativity = (CPUInfo[2] >> 12) & 0xf;
            cpu.L2CacheSizeK    = (CPUInfo[2] >> 16) & 0xffff;
        }
    }

    //warn("\n\nCPU String: %s\n", cpu.String);

    if  (cpu.Ids >= 1) {
        /*
        if (cpu.SteppingID)           warn("Stepping ID             = %d\n", cpu.SteppingID);
        if (cpu.Model)                warn("Model                   = %d\n", cpu.Model);
        if (cpu.Family)               warn("Family                  = %d\n", cpu.Family);
        if (cpu.ProcessorType)        warn("Processor Type          = %d\n", cpu.ProcessorType);
        if (cpu.Extendedmodel)        warn("Extended model          = %d\n", cpu.Extendedmodel);
        if (cpu.Extendedfamily)       warn("Extended family         = %d\n", cpu.Extendedfamily);
        if (cpu.BrandIndex)           warn("Brand Index             = %d\n", cpu.BrandIndex);
        if (cpu.CLFLUSHcachelinesize) warn("CLFLUSH cache line size = %d\n", cpu.CLFLUSHcachelinesize);
        if (cpu.APICPhysicalID)       warn("APIC Physical ID        = %d\n", cpu.APICPhysicalID);
        */

        if  (
            cpu.FeatureInfo            ||
            cpu.SSE3NewInstructions    ||
            cpu.MONITOR_MWAIT          ||
            cpu.CPLQualifiedDebugStore ||
            cpu.ThermalMonitor2
        ) {
            /*
            warn("\nThe following features are supported:\n");

            if (cpu.SSE3NewInstructions)    warn("      SSE3 New Instructions\n");
            if (cpu.MONITOR_MWAIT)          warn("      MONITOR/MWAIT\n");
            if (cpu.CPLQualifiedDebugStore) warn("      CPL Qualified Debug Store\n");
            if (cpu.ThermalMonitor2)        warn("      Thermal Monitor 2\n");
            */

            i       = 0;
            cpu.Ids = 1;
            while (i < (sizeof(szFeatures)/sizeof(const int*))) {
                if  (cpu.FeatureInfo & cpu.Ids) {
                    FeatureFlags |= szFeatures[i];
                }
                cpu.Ids <<= 1;
                ++i;
            }
        }
    }

    /*
    if  (cpu.ExIds >= 0x80000004)
        warn("\nCPU Brand String = %s\n", cpu.BrandString);

    if  (cpu.ExIds >= 0x80000006) {
        warn("L2 Cache Line Size = %d\n",  cpu.L2CacheLineSize);
        warn("L2 Associativity   = %d\n",  cpu.L2Associativity);
        warn("L2 Cache Size      = %dK\n", cpu.L2CacheSizeK);
    }
    */

    /*
    HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\System\CentralProcessor
    */
    if (CpuFeatures & 0x00000002) KFBits |= KF_V86_VIS | KF_CR4;
    if (CpuFeatures & 0x00000008) KFBits |= KF_LARGE_PAGE | KF_CR4;
    if (CpuFeatures & 0x00000010) KFBits |= KF_RDTSC;
    if (CpuFeatures & 0x00000100) KFBits |= KF_CMPXCHG8B;
    if (CpuFeatures & 0x00000800) KFBits |= KF_FAST_SYSCALL;
    if (CpuFeatures & 0x00001000) KFBits |= KF_MTRR;
    if (CpuFeatures & 0x00002000) KFBits |= KF_GLOBAL_PAGE | KF_CR4;
    if (CpuFeatures & 0x00008000) KFBits |= KF_CMOV;
    if (CpuFeatures & 0x00010000) KFBits |= KF_PAT;
    if (CpuFeatures & 0x00200000) KFBits |= KF_DTS;
    if (CpuFeatures & 0x00800000) KFBits |= KF_MMX;
    if (CpuFeatures & 0x01000000) KFBits |= KF_FXSR;
    if (CpuFeatures & 0x02000000) KFBits |= KF_XMMI;
    if (CpuFeatures & 0x04000000) KFBits |= KF_XMMI64;

    if (CpuFeatures & 0x10000000) {
        cpu.Count = (UCHAR)(ebx >> 16);
        //warn("System has %d CPUs\n", cpu.Count);
    }

    PUSHs( sv_2mortal( newSVpv( "____ebx"               , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( ebx                         ) ) );

    PUSHs( sv_2mortal( newSVpv( "____ecx"               , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( ecx                         ) ) );

    PUSHs( sv_2mortal( newSVpv( "CpuFeatures"           , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( CpuFeatures                 ) ) );

    PUSHs( sv_2mortal( newSVpv( "SteppingID"            , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.SteppingID              ) ) );

    PUSHs( sv_2mortal( newSVpv( "Model"                 , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.Model                   ) ) );

    PUSHs( sv_2mortal( newSVpv( "Family"                , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.Family                  ) ) );

    PUSHs( sv_2mortal( newSVpv( "ProcessorType"         , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.ProcessorType           ) ) );

    PUSHs( sv_2mortal( newSVpv( "Extendedmodel"         , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.Extendedmodel           ) ) );

    PUSHs( sv_2mortal( newSVpv( "Extendedfamily"        , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.Extendedfamily          ) ) );

    PUSHs( sv_2mortal( newSVpv( "BrandIndex"            , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.BrandIndex              ) ) );

    PUSHs( sv_2mortal( newSVpv( "CLFLUSHcachelinesize"  , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.CLFLUSHcachelinesize    ) ) );

    PUSHs( sv_2mortal( newSVpv( "APICPhysicalID"        , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.APICPhysicalID          ) ) );

    PUSHs( sv_2mortal( newSVpv( "SSE3NewInstructions"   , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.SSE3NewInstructions     ) ) );

    PUSHs( sv_2mortal( newSVpv( "MONITOR_MWAIT"         , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.MONITOR_MWAIT           ) ) );

    PUSHs( sv_2mortal( newSVpv( "CPLQualifiedDebugStore", 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.CPLQualifiedDebugStore  ) ) );

    PUSHs( sv_2mortal( newSVpv( "ThermalMonitor2"       , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.ThermalMonitor2         ) ) );

    PUSHs( sv_2mortal( newSVpv( "FeatureInfo"           , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.FeatureInfo             ) ) );

    PUSHs( sv_2mortal( newSVpv( "ExIds"                 , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.ExIds                   ) ) );

    PUSHs( sv_2mortal( newSVpv( "Ids"                   , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.Ids                     ) ) );

    PUSHs( sv_2mortal( newSVpv( "Count"                 , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.Count                   ) ) );

    PUSHs( sv_2mortal( newSVpv( "BrandString"           , 0 ) ) );
    PUSHs( sv_2mortal( newSVpv( cpu.BrandString         , 0 ) ) );

    PUSHs( sv_2mortal( newSVpv( "String"                , 0 ) ) );
    PUSHs( sv_2mortal( newSVpv( cpu.String              , 0 ) ) );

    PUSHs( sv_2mortal( newSVpv( "L2CacheLineSize"       , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.L2CacheLineSize         ) ) );

    PUSHs( sv_2mortal( newSVpv( "L2Associativity"       , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.L2Associativity         ) ) );

    PUSHs( sv_2mortal( newSVpv( "L2CacheSizeK"          , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv( cpu.L2CacheSizeK            ) ) );

    PUSHs( sv_2mortal( newSVpv( "Flags"                 , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv(  Flags                      ) ) );

    PUSHs( sv_2mortal( newSVpv( "KFBits"                , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv(  KFBits                     ) ) );

    PUSHs( sv_2mortal( newSVpv( "FeatureFlags"           , 0 ) ) );
    PUSHs( sv_2mortal( newSVuv(  FeatureFlags                ) ) );
