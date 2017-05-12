
use strict;
use IO::Socket;
use POSIX qw(strftime WNOHANG);
use Time::HiRes qw(gettimeofday tv_interval) ;

=head1 NAME

build_server.pl

=head2 DESCRIPTION

Forking PBS is very expensive, for reasons I don't understan copy on write doesn't work properly, this
application runs as a server and waits for PBS to send it build commands. This is the equivalent of a 
forked PBS but only the build code is found here.

=cut


# go over to zeroconf
use constant PORT => 12000;

my $quit = 0;

# signal handler for child die events
$SIG{CHLD} = sub { while ( waitpid(-1,WNOHANG)>0 ) { } };

# signal handler for interrupt key and TERM signal
$SIG{INT} = sub { $quit++ };

my $listen_socket = IO::Socket::INET->new
					(
					LocalPort => PORT,
                                        Listen    => 20,
                                        Proto     => 'tcp',
                                        Reuse     => 1,
                                        Timeout   => 60*60,
                                        );
					 
die "Can't create a listening socket: $@" unless $listen_socket;
warn "PBS shell command server ready.  Waiting for connections...\n\n";   

my $connection_index = 0 ;
while (!$quit) 
	{
	next unless my $connection = $listen_socket->accept;
	$connection_index++ ;
	
	defined (my $child = fork()) or die "Can't fork: $!";
	
	if ($child == 0) 
		{
		# in child process
		
		my $now_string = strftime "%a %b %e %H:%M:%S %Y", gmtime ;
		print "[$$] Connection $connection_index $now_string.\n" ;
		
		$SIG{CHLD} = undef ; # arrrrrrrgggggg! without this line $? was always -1

		$listen_socket->close;
		
		interact($connection);
		
		exit 0;
		}
	
	$connection->close;
	}

#move all this a to a pbs module Builder::ShellCommand::Server or something like it.
# look into refactoring this one and ForkedNodeBuilder.pm

sub interact 
{
my $sock = shift;

my $build_output ;
my $node_name ;
my $build_time ; #last node build time

while(defined (my $command_and_args = <$sock>))
	{
	$command_and_args =~ s/\n|\r//g ;
	
	my ($command, @args) = split /__PBS_FORKED_BUILDER__/, $command_and_args ;
	
	for ($command)
		{
		/^STOP_PROCESS$/ and do
			{
			print("[$$] Stop.\n") ;
			close($sock) ;
			exit ;
			} ;
			
		/^GET_PROCESS_ID$/ and do
			{
			print $sock "$$\n__PBS_FORKED_BUILDER__\n" ;
			last ;
			} ;
			
		/^NODE_NAME$/ and do
			{
			$node_name = $args[0] ;
			last ;
			} ;
			
		/^RUN_COMMANDS$/ and do
			{
			($build_output, $build_time) = Runcommands($sock, $node_name, @args) ;
			last ;
			} ;
			
		/^GET_LOG$/ and do
			{
			print $sock "'$node_name': No log implemented in light weight build!\n" . "__PBS_FORKED_BUILDER___\n" ;
			last ;
			} ;
			
		/^GET_OUTPUT$/ and do
			{
			SendFile($sock, $build_output, @args) ;
			last ;
			} ;
			
		print $sock "0__PBS_FORKED_BUILDER__ [$$] Unrecognized command '$command_and_args'__PBS_FORKED_BUILDER__\n" ;
		}
	}
}

sub Runcommands
{
my ($sock, $node_name, @commands) = @_ ;
my $t0 = [gettimeofday] ;

#~ my $redirection_file =  $shell->GetInfo() . '_node_' . $node_name ;
my $redirection_file =  $node_name ;

$redirection_file =~ s/\s/_/g ;
$redirection_file =~ s/[[\]]/_/g ;
$redirection_file =~ s/\//_/g ;

TODO!
redirection file has changed in PBS to avoid a "file name too long" error
user the same scheme.


#~ my $pbs_build_buffers_directory = $node->{__PBS_CONFIG}{BUILD_DIRECTORY} . "/PBS_BUILD_BUFFERS/";
my $pbs_build_buffers_directory = "./TEST_PBS_BUILD_BUFFERS/";

unless(-e $pbs_build_buffers_directory)
	{
	use File::Path ;
	mkpath($pbs_build_buffers_directory) ;
	}
	
$redirection_file = $pbs_build_buffers_directory . $redirection_file ;

open(OLDOUT, ">&STDOUT") ;
open(OLDERR, ">&STDERR") ;

#all output gore to files that might be kept if KEEP_PBS_BUILD_BUFFERS is set
open STDOUT, '>', $redirection_file or die "Can't redirect STDOUT to '$redirection_file': $!";
STDOUT->autoflush(1) ;

open STDERR, '>&' . fileno(STDOUT) or die "Can't redirect STDERR to '$redirection_file': $!";
STDERR->autoflush(1) ;

my ($build_result, $build_message) = (1, "build OK") ;

my $columns = length("Node '$node_name':") ;
my $separator = '#' . ('-' x ($columns - 1)) . "\n"  ;

print STDOUT $separator . "Node '$node_name':\n" . $separator ;

for my $command (@commands)
	{
	
	print STDOUT "Remote shell command: '$command'\n" ; # if not silent
	
	my $output = `$command` ;

	if($?)
		{
		print OLDOUT "[$$] Error: '$command' => $?\n" ;
		
		print STDOUT "Error: $! $?\n" ;
		print STDOUT $output ;
		
		($build_result, $build_message) = (0, "Error running command '$command' [$! $?]") ;
		last ;
		}
	else
		{
		print OLDOUT "[$$] Done: '$command'\n" ;
		print STDOUT $output ; # if not silent
		}
	
	#~ if(system($command))
		#~ {
		#~ print OLDOUT "[$$] Error: '$command'\n" ;
		#~ print STDOUT "Error: $! $?\n" ;
		
		#~ ($build_result, $build_message) = (0, "Error running command '$command' [$!]") ;
		#~ last ;
		#~ }
	#~ else
		#~ {
		#~ print OLDOUT "[$$] Done: '$command'\n" ;
		#~ }
	}

#stop redirecting to a file
close(STDOUT) ;
close(STDERR) ;
open(STDOUT, ">&OLDOUT") ;
open(STDERR, ">&OLDERR") ;

close(OLDOUT) ;
close(OLDERR) ;

#let other side know if something went wrong
print $sock "${build_result}__PBS_FORKED_BUILDER__${build_message}\n" ;

return($redirection_file, tv_interval ($t0, [gettimeofday])) ;
}

sub SendFile
{
my $channel     = shift ;
my $file        = shift ;
my $remove_file = shift or 'keep' ;

print "[$$] SendFile $file [$remove_file] ***\n" ;

open FILE, '<', $file or die "[$$] Can't open '$file': $!" ;
while(<FILE>)
	{
	print $channel $_ ;
	}
	
close(FILE) ;	

print $channel "__PBS_FORKED_BUILDER___\n" ;

unlink($file) if $remove_file;
}
