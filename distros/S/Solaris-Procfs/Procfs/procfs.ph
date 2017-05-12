#---------------------------------------------------------------------------

# This file is explicitly require'd by Solaris::Procfs.pm.
#
# The purpose of this file is just to define certain constants
# used in Solaris::Procfs, and possibly exported.
#
# It probably should have been inserted directly into 
# Solaris::Procfs.pm, but it was put into a separate file
# for neatness' sake.  
#

use vars qw( 
	@control_codes
	@pcrun_operand_flags
	@pr_flags
	@pcset_flags
	@pr_why_flags 
	@protection_flags
	@pr_wflags
	@pr_npage_bytes 
);
	
	
@control_codes = qw(
	PCNULL PCSTOP PCDSTOP PCWSTOP PCTWSTOP PCRUN PCCSIG PCCFAULT 
	PCSSIG PCKILL PCUNKILL PCSHOLD PCSTRACE PCSFAULT PCSENTRY 
	PCSEXIT PCSET PCUNSET PCSREG PCSFPREG PCSXREG PCNICE 
	PCSVADDR PCWATCH PCAGENT PCREAD PCWRITE PCSCRED PCSASRS 
);

@pcrun_operand_flags = qw( PRCSIG PRCFAULT PRSTEP PRSABORT PRSTOP );

@pr_flags = qw( 
	PR_STOPPED PR_ISTOP PR_DSTOP PR_STEP PR_ASLEEP 
	PR_PCINVAL PR_ASLWP PR_AGENT PR_ISSYS PR_VFORKP PR_ORPHAN 
);

@pcset_flags = qw( 
	PR_FORK PR_RLC PR_KLC PR_ASYNC PR_MSACCT 
	PR_BPTADJ PR_PTRACE PR_MSFORK 
);

@pr_why_flags = qw(
	PR_REQUESTED PR_SIGNALLED PR_SYSENTRY PR_SYSEXIT PR_JOBCONTROL 
	PR_FAULTED PR_SUSPENDED PR_CHECKPOINT 
);

@protection_flags = qw(
	MA_READ MA_WRITE MA_EXEC MA_SHARED MA_ANON MA_BREAK MA_STACK 
);

@pr_wflags = qw( WA_READ WA_WRITE WA_EXEC WA_TRAPAFTER );
@pr_npage_bytes  = qw( PG_REFERENCED PG_MODIFIED PG_HWMAPPED );

@all_flags = (
	@control_codes,
	@pcrun_operand_flags,
	@pr_flags,
	@pcset_flags,
	@pr_why_flags,
	@protection_flags,
	@pr_wflags,
	@pr_npage_bytes,
);

push @EXPORT_OK, @all_flags;

%EXPORT_TAGS = (

	%EXPORT_TAGS,

	control_codes          => [ @control_codes        ],
	pcrun_operand_flags    => [ @pcrun_operand_flags  ],
	pr_flags               => [ @pr_flags             ],
	pcset_flags            => [ @pcset_flags          ],
	pr_why_flags           => [ @pr_why_flags         ],
	protection_flags       => [ @protection_flags     ],
	pr_wflags              => [ @pr_wflags            ],
	pr_npage_bytes         => [ @pr_npage_bytes       ],

	procfs_h               => [ @all_flags            ],
);

#-------------------------------------------------------------
#
# Control codes (long values) for messages written to ctl and lwpctl files.
#
sub PCNULL 	() { 0;}	# null request, advance to next message 
sub PCSTOP 	() { 1;}	# direct process or lwp to stop and wait for stop 
sub PCDSTOP 	() { 2;}	# direct process or lwp to stop 
sub PCWSTOP 	() { 3;}	# wait for process or lwp to stop, no timeout 
sub PCTWSTOP 	() { 4;}	# wait for stop, with long millisecond timeout arg 
sub PCRUN 	() { 5;}	# make process/lwp runnable, w/ long flags argument 
sub PCCSIG 	() { 6;}	# clear current signal from lwp 
sub PCCFAULT 	() { 7;}	# clear current fault from lwp 
sub PCSSIG 	() { 8;}	# set current signal from siginfo_t argument 
sub PCKILL 	() { 9;}	# post a signal to process/lwp, long argument 
sub PCUNKILL 	() {10;}	# delete a pending signal from process/lwp, long arg
sub PCSHOLD 	() {11;}	# set lwp signal mask from sigset_t argument 
sub PCSTRACE 	() {12;}	# set traced signal set from sigset_t argument 
sub PCSFAULT 	() {13;}	# set traced fault set from fltset_t argument 
sub PCSENTRY 	() {14;}	# set traced syscall entry set from sysset_t arg 
sub PCSEXIT 	() {15;}	# set traced syscall exit set from sysset_t arg 
sub PCSET 	() {16;}	# set modes from long argument 
sub PCUNSET 	() {17;}	# unset modes from long argument 
sub PCSREG 	() {18;}	# set lwp general registers from prgregset_t arg 
sub PCSFPREG 	() {19;}	# set lwp floating-point registers from prfpregset_t
sub PCSXREG 	() {20;}	# set lwp extra registers from prxregset_t arg 
sub PCNICE 	() {21;}	# set nice priority from long argument 
sub PCSVADDR 	() {22;}	# set %pc virtual address from long argument 
sub PCWATCH 	() {23;}	# set/unset watched memory area from prwatch_t arg 
sub PCAGENT 	() {24;}	# create agent lwp with regs from prgregset_t arg 
sub PCREAD 	() {25;}	# read from the address space via priovec_t arg 
sub PCWRITE 	() {26;}	# write to the address space via priovec_t arg 
sub PCSCRED 	() {27;}	# set process credentials from prcred_t argument 
sub PCSASRS 	() {28;}	# set ancillary state registers from asrset_t arg 

#
# PCRUN long operand flags.
#
sub PRCSIG 	() {0x01;}	# clear current signal, if any 
sub PRCFAULT 	() {0x02;}	# clear current fault, if any 
sub PRSTEP 	() {0x04;}	# direct the lwp to single-step 
sub PRSABORT 	() {0x08;}	# abort syscall, if in syscall 
sub PRSTOP 	() {0x10;}	# set directed stop request 


#
# pr_flags (same values appear in both pstatus_t and lwpstatus_t pr_flags).
#
sub PR_STOPPED 	() {0x00000001;}	# lwp is stopped 
sub PR_ISTOP 	() {0x00000002;}	# lwp is stopped on an event of interest 
sub PR_DSTOP 	() {0x00000004;}	# lwp has a stop directive in effect 
sub PR_STEP 	() {0x00000008;}	# lwp has a single-step directive in effect 
sub PR_ASLEEP 	() {0x00000010;}	# lwp is sleeping in a system call 
sub PR_PCINVAL 	() {0x00000020;}	# contents of pr_instr undefined 
sub PR_ASLWP 	() {0x00000040;}	# this lwp is the aslwp 
sub PR_AGENT 	() {0x00000080;}	# this lwp is the /proc agent lwp 
#
# The following flags apply to the process, not to an individual lwp 
#
sub PR_ISSYS 	() {0x00001000;}	# this is a system process 
sub PR_VFORKP 	() {0x00002000;}	# process is the parent of a vfork()d child 
sub PR_ORPHAN 	() {0x00004000;}	# process's process group is orphaned 
#
# The following process flags are modes settable by PCSET/PCUNSET
#
sub PR_FORK 	() {0x00100000;}	# inherit-on-fork is in effect 
sub PR_RLC 	() {0x00200000;}	# run-on-last-close is in effect 
sub PR_KLC 	() {0x00400000;}	# kill-on-last-close is in effect 
sub PR_ASYNC 	() {0x00800000;}	# asynchronous-stop is in effect 
sub PR_MSACCT 	() {0x01000000;}	# micro-state usage accounting is in effect 
sub PR_BPTADJ 	() {0x02000000;}	# breakpoint trap pc adjustment is in effect 
sub PR_PTRACE 	() {0x04000000;}	# ptrace-compatibility mode is in effect 
sub PR_MSFORK 	() {0x08000000;}	# micro-state accounting inherited on fork 


#
#  Reasons for stopping (pr_why).
#
sub PR_REQUESTED 	() {1;}
sub PR_SIGNALLED 	() {2;}
sub PR_SYSENTRY 	() {3;}
sub PR_SYSEXIT 		() {4;}
sub PR_JOBCONTROL 	() {5;}
sub PR_FAULTED 		() {6;}
sub PR_SUSPENDED 	() {7;}
sub PR_CHECKPOINT 	() {8;}


#
# Protection and attribute flags 
#
sub MA_READ 	() {0x04;}	# readable by the traced process 
sub MA_WRITE 	() {0x02;}	# writable by the traced process 
sub MA_EXEC 	() {0x01;}	# executable by the traced process 
sub MA_SHARED 	() {0x08;}	# changes are shared by mapped object 
sub MA_ANON 	() {0x40;}	# anonymous memory (e.g. /dev/zero) 
sub MA_BREAK 	() {0x10;}	# grown by brk(2) 
sub MA_STACK 	() {0x20;}	# grown automatically on stack faults 

#
# pr_wflags
#
sub WA_READ 		() {0x04;}	# trap on read access 
sub WA_WRITE 		() {0x02;}	# trap on write access 
sub WA_EXEC 		() {0x01;}	# trap on execute access 
sub WA_TRAPAFTER 	() {0x08;}	# trap after instruction completes 


#
# pr_npage bytes (plus 0-7 null bytes to round up to an 8-byte boundary)
#  follow each mapping header, each containing zero or more of these flags.
#
sub PG_REFERENCED 	() {0x02;}	# page referenced since last read 
sub PG_MODIFIED 	() {0x01;}	# page modified since last read 
sub PG_HWMAPPED 	() {0x04;}	# page is present and mapped 



1;

