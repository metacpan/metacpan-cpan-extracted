/*
    CF_* CPU Flags
*/
#define CF_MMX             0x00800000
#define CF_MMXPLUS         0x00400000
#define CF_SSE             0x02000000
#define CF_SSE2            0x04000000
#define CF_SSE3            0x00000001
#define CF_SSSE3           0x00000200
#define CF_SSE41           0x00080000
#define CF_SSE42           0x00100000
#define CF_SSE4A           0x00000040
#define CF_SSE5            0x00000800
#define CF_A3DNOW          0x80000000
#define CF_A3DNOWEXT       0x40000000

/*
    KF_* = Kernel Feature Bits (these constants were taken from ketypes.h - ReactOS)
    These are actually CPU Feature Sets
*/

#define KF_V86_VIS         0x00000001
#define KF_RDTSC           0x00000002
#define KF_CR4             0x00000004
#define KF_CMOV            0x00000008
#define KF_GLOBAL_PAGE     0x00000010
#define KF_LARGE_PAGE      0x00000020
#define KF_MTRR            0x00000040
#define KF_CMPXCHG8B       0x00000080
#define KF_MMX             0x00000100
#define KF_WORKING_PTE     0x00000200
#define KF_PAT             0x00000400
#define KF_FXSR            0x00000800
#define KF_FAST_SYSCALL    0x00001000
#define KF_XMMI            0x00002000
#define KF_3DNOW           0x00004000
#define KF_AMDK6MTRR       0x00008000
#define KF_XMMI64          0x00010000
#define KF_DTS             0x00020000
#define KF_NX_BIT          0x20000000
#define KF_NX_DISABLED     0x40000000
#define KF_NX_ENABLED      0x80000000

/* Features */

#define FT_X87_FPU_ON_CHIP                      0x00000001
#define FT_VIRTUAL_8086_MODE_ENHANCEMENT        0x00000002
#define FT_DEBUGGING_EXTENSIONS                 0x00000004
#define FT_PAGE_SIZE_EXTENSIONS                 0x00000008
#define FT_TIME_STAMP_COUNTER                   0x00000010
#define FT_RDMSR_AND_WRMSR_SUPPORT              0x00000020
#define FT_PHYSICAL_ADDRESS_EXTENSIONS          0x00000040
#define FT_MACHINE_CHECK_EXCEPTION              0x00000080
#define FT_CMPXCHG8B_INSTRUCTION                0x00000100
#define FT_APIC_ON_CHIP                         0x00000200
#define FT_UNKNOWN1                             0x00000400
#define FT_SYSENTER_AND_SYSEXIT                 0x00000800
#define FT_MEMORY_TYPE_RANGE_REGISTERS          0x00001000
#define FT_PTE_GLOBAL_BIT                       0x00002000
#define FT_MACHINE_CHECK_ARCHITECTURE           0x00004000
#define FT_CONDITIONAL_MOVE_COMPARE_INSTRUCTION 0x00008000
#define FT_PAGE_ATTRIBUTE_TABLE                 0x00010000
#define FT_PAGE_SIZE_EXTENSION                  0x00020000
#define FT_PROCESSOR_SERIAL_NUMBER              0x00040000
#define FT_CFLUSH_EXTENSION                     0x00080000
#define FT_UNKNOWN2                             0x00100000
#define FT_DEBUG_STORE                          0x00200000
#define FT_THERMAL_MONITOR_AND_CLOCK_CTRL       0x00400000
#define FT_MMX_TECHNOLOGY                       0x00800000
#define FT_FXSAVE_FXRSTOR                       0x01000000
#define FT_SSE_EXTENSIONS                       0x02000000
#define FT_SSE2_EXTENSIONS                      0x04000000
#define FT_SELF_SNOOP                           0x08000000
#define FT_HYPER_THREADING_TECHNOLOGY           0x10000000
#define FT_THERMAL_MONITOR                      0x20000000
#define FT_UNKNOWN4                             0x40000000
#define FT_PEND_BRK_EN                          0x80000000

#define CPUDATA struct CPUData

typedef void (WINAPI *PGNSI)(LPSYSTEM_INFO);
typedef BOOL (WINAPI *PGPI)(DWORD, DWORD, DWORD, DWORD, PDWORD);
typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS) (HANDLE, PBOOL);

/*
    "x87 FPU On Chip",
    "Virtual-8086 Mode Enhancement",
    "Debugging Extensions",
    "Page Size Extensions",
    "Time Stamp Counter",
    "RDMSR and WRMSR Support",
    "Physical Address Extensions",
    "Machine Check Exception",
    "CMPXCHG8B Instruction",
    "APIC On Chip",
    "Unknown1",
    "SYSENTER and SYSEXIT",
    "Memory Type Range Registers",
    "PTE Global Bit",
    "Machine Check Architecture",
    "Conditional Move/Compare Instruction",
    "Page Attribute Table",
    "Page Size Extension",
    "Processor Serial Number",
    "CFLUSH Extension",
    "Unknown2",
    "Debug Store",
    "Thermal Monitor and Clock Ctrl",
    "MMX Technology",
    "FXSAVE/FXRSTOR",
    "SSE Extensions",
    "SSE2 Extensions",
    "Self Snoop",
    "Hyper-threading Technology",
    "Thermal Monitor",
    "Unknown4",
    "Pend. Brk. EN."
*/

const int szFeatures[] = {
FT_X87_FPU_ON_CHIP,
FT_VIRTUAL_8086_MODE_ENHANCEMENT,
FT_DEBUGGING_EXTENSIONS,
FT_PAGE_SIZE_EXTENSIONS,
FT_TIME_STAMP_COUNTER,
FT_RDMSR_AND_WRMSR_SUPPORT,
FT_PHYSICAL_ADDRESS_EXTENSIONS,
FT_MACHINE_CHECK_EXCEPTION,
FT_CMPXCHG8B_INSTRUCTION,
FT_APIC_ON_CHIP,
FT_UNKNOWN1,
FT_SYSENTER_AND_SYSEXIT,
FT_MEMORY_TYPE_RANGE_REGISTERS,
FT_PTE_GLOBAL_BIT,
FT_MACHINE_CHECK_ARCHITECTURE,
FT_CONDITIONAL_MOVE_COMPARE_INSTRUCTION,
FT_PAGE_ATTRIBUTE_TABLE,
FT_PAGE_SIZE_EXTENSION,
FT_PROCESSOR_SERIAL_NUMBER,
FT_CFLUSH_EXTENSION,
FT_UNKNOWN2,
FT_DEBUG_STORE,
FT_THERMAL_MONITOR_AND_CLOCK_CTRL,
FT_MMX_TECHNOLOGY,
FT_FXSAVE_FXRSTOR,
FT_SSE_EXTENSIONS,
FT_SSE2_EXTENSIONS,
FT_SELF_SNOOP,
FT_HYPER_THREADING_TECHNOLOGY,
FT_THERMAL_MONITOR,
FT_UNKNOWN4,
FT_PEND_BRK_EN
};

struct CPUData {
    int  SteppingID;
    int  Model;
    int  Family;
    int  ProcessorType;
    int  Extendedmodel;
    int  Extendedfamily;
    int  BrandIndex;
    int  CLFLUSHcachelinesize;
    int  APICPhysicalID;
    int  FeatureInfo;
    int  L2CacheLineSize;
    int  L2Associativity;
    int  L2CacheSizeK;
    bool SSE3NewInstructions;
    bool MONITOR_MWAIT;
    bool CPLQualifiedDebugStore;
    bool ThermalMonitor2;
    char BrandString[0x40];
    char String[0x20];
    unsigned Ids;
    unsigned ExIds;
    unsigned int Count; /* Number of CPUs */
};
