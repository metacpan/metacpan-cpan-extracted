package Win32::SimpleProcess;

use Win32;
use Win32::API;
use strict;
use warnings;

sub new
{
	my $self = {};

	$self->{TOKEN_QUERY}			=	0x0008;
	$self->{TOKEN_ADJUST_PRIVILEGES}	=	0x0020;
	$self->{SE_PRIVILEGE_ENABLED}		=	0x02;
	$self->{PROCESS_TERMINATE}		=	0x0001;
	$self->{SE_DEBUG_NAME}			=	"SeDebugPrivilege";

	$self->{GetCurrentProcess} = new Win32::API('Kernel32.dll', 'GetCurrentProcess', [], 'N') || die "Coulnd set up Win32::API for GetCurrentProcess\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{OpenProcessToken} = new Win32::API('AdvApi32.dll', 'OpenProcessToken', ['N','N','P'], 'I') || die "Coulnd set up Win32::API for OpenProcessToken\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{LookupPrivilegeValue} = new Win32::API('AdvApi32.dll', 'LookupPrivilegeValue', ['P','P','P'], 'I') || die "Coulnd set up Win32::API for LookupPrivilegeValue\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{AdjustTokenPrivileges} = new Win32::API('AdvApi32.dll', 'AdjustTokenPrivileges', ['N','I','P','N','P','P'], 'I') || die "Coulnd set up Win32::API for AdjustTokenPrivileges\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{OpenProcess} = new Win32::API('Kernel32.dll', 'OpenProcess', ['N','I','N'], 'I') || die "Coulnd set up Win32::API for OpenProcess\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{TerminateProcess} = new Win32::API('Kernel32.dll', 'TerminateProcess', ['N','I'], 'I') || die "Coulnd set up Win32::API for TerminateProcess\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{CloseHandle} = new Win32::API('Kernel32.dll', 'CloseHandle', ['N'], 'I') || die "Coulnd set up Win32::API for CloseHandle\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{EnumProcesses} = new Win32::API('iprocnt.dll',"EnumProcess",['P','P','P'],'I') || die "Coulnd set up Win32::API for EnumProcesses\nError: ". Win32::FormatMessage(Win32::GetLastError());
	$self->{ReallocMem} = new Win32::API('iprocnt.dll',"ReallocMemory",['P','I'],'I') || die "Coulnd set up Win32::API for ReallocMemory\nError: ". Win32::FormatMessage(Win32::GetLastError());

	bless($self);
	return $self;
}

sub Launch {
	my ($object, $app, $args)=@_;
	my $pid=0;

	if(Win32::Spawn($app,$args,$pid)){
		
	}
	else{
		print "Could not create the process.\n";
		print "Error: ". Win32::FormatMessage(Win32::GetLastError()). "\n";
	}
	return $pid;
}

sub ForceKill{
	my ($object,$Pid)=@_;
	my $iResult = 0;
	my $phToken = pack("L",0);
	
	if($object->{OpenProcessToken}->Call( $object->{GetCurrentProcess}->Call(),$object->{TOKEN_ADJUST_PRIVILEGES} | $object->{TOKEN_QUERY}, $phToken)){
		my $hToken = unpack("L",$phToken);
		if($object->SetPrivilege($hToken,$object->{SE_DEBUG_NAME},1)){
			my $hProcess = $object->{OpenProcess}->Call($object->{PROCESS_TERMINATE},0,$Pid);
			if($hProcess){
				$object->SetPrivilege($hToken,$object->{SE_DEBUG_NAME},0);
				$iResult = $object->{TerminateProcess}->Call($hProcess,0);
				$object->{CloseHandle}->Call($hProcess);
			}
		}
		$object->{CloseHandle}->Call($hToken);
	}
	return ($iResult);
}

sub SetPrivilege {
	my ($object,$hToken,$pszPriv,$bSetFlag) = @_;
	my $pLuid = pack ("Ll",0,0);
	my $iResult=0;

	if($object->{LookupPrivilegeValue}->Call("\x00\x00",$pszPriv,$pLuid)){
		my $pPrivStruct = pack ("LLlL",1,unpack("Ll",$pLuid),(($bSetFlag) ? $object->{SE_PRIVILEGE_ENABLED} : 0));
		$iResult = (0 != $object->{AdjustTokenPrivileges}->Call($hToken,0,$pPrivStruct,length($pPrivStruct),0,0));
	}
	return ($iResult);
}

sub ProcessList {
	my($obj)=shift;
	if(scalar(@_)>2){die "\n[Error] Parameters do not correspond in EnumProcesses()\n";}
	my($Ptr1)=pack("L",0);
	my($Ptr2)=pack("L",0);
	my($Ptr3)=pack("l",0);
	my($i);
	my(@a);
	my(@b);
	my(@Info);
	my($Info)=shift;
	my($Str);
	my($Path)=shift;
	my($Ret)=$obj->{EnumProcesses}->Call($Ptr1,$Ptr2,$Ptr3);
	$obj->{Error}=unpack("l",$Ptr3);
	@$Info=();

	if(Win32::IsWinNT){
		if ($Ret){
			$Ptr2=unpack("L",$Ptr2);
			@a=split(/\//,unpack('P'.$Ptr2,$Ptr1));
 			for ($i=0;$i<scalar(@a);$i++){
				@b=split(/:/,$a[$i]);
				@$Info[$i]={ProcessName => $b[0],
                 		ProcessId   => $b[1]
			}
		}
		return $Ret;
	}else{return undef;}}

	if(Win32::IsWin95){
		if($Ret){
			$Ptr2=unpack("L",$Ptr2);
			@a=split(/\//,unpack('P'.$Ptr2,$Ptr1));
    			for ($i=0;$i<scalar(@a);$i++ ){
				@b=split(/\*/,$a[$i]);
				if (!$Path){
					my(@SplitPath) = split(/\\/,$b[0]);
					$b[0]=$SplitPath[scalar(@SplitPath)-1]
         			}
				$$Info[$i]={ProcessName     => "$b[0]",
                   	ProcessId       => $b[1],
                   	PriClassBase    => $b[2],
                   	CntThreads      => $b[3] ,
                 		ParentProcessId => $b[4]}
  			}
			return $Ret;
		} else {return undef;}
	}
}

return 1;

__END__

=head1 NAME

Win32::SimpleProcess -- An extremely simple object-oriented module launch, kill, and list processes by process ID.

=head1 SYNOPSIS

use Win32::SimpleProcess;

$program = "notepad.exe";
$path = "$ENV{SystemRoot}";
$App = "$path\\$program";
$Args = "$Program $ENV{Temp}\\test.txt";
$Time = 3;

$process = Win32::SimpleProcess->new();
$mypid = $process->Launch($App,$Args);

print "Launched: $mypid\n";

sleep $Time;

$process->ForceKill($mypid);
print "Killed: $mypid\n";


print "\nProcess List:\n\n";
$process->ProcessList(\@proclist) or die "unable to get process list: $!\n";

foreach $proc (@proclist) { 
	my $pid = $proc->{ProcessId}; 
	my $name = $proc-> {ProcessName}; 
	print "$pid\t$name\n";
} 

exit(0);

=head1 DESCRIPTION

After trying to write some process management components in Perl using modules like Win32::Process and Win32::IProcess my code looked awful. It had mixtures of object-oriented perl and non-object-oriented perl. There were a number of compatibility and scalability issues. After struggling with some issues regarding my personal project and the architecture of the existing modules I decided it would be best to write a new module with very simple features and source. Thus Win32::SimpleProcess only Launches, Kills, and Lists processes by ProcessID. Let me just say that I don't believe my module is any better than the other two... Just more accommodating for the project I was trying to accomplish.  If you have had similar issues and would like to try a simpler module then Win32::SimpleProcess might be what you are looking for.

=head1 BUGS

uses Win32::API so Win32:API must be installed and Win32::API issues apply.

=head2 Methods

=over 4

=item $process = Win32::SimpleProcess->new()

Constructor for a new event object. 

=item $pid = $process->Launch($App,$Args)

Launches and application with specified arguments.

=item $process->ForceKill($pid)

Kills the process with process ID $pid.

=item $process->ProcessList(\@proclist)

Fills the given array with hashes of the current list of running processes and process IDs. The hashes keys for each array element are 'ProcessID' and 'ProcessName'.

=back

=head1 AUTHOR

Edward C. Kubaitis <ted@radiumhahn.com>
