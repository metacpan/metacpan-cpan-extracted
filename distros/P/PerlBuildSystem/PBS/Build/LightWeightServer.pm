
package PBS::Build::LightWeightServer ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;

our $VERSION = '0.02' ;

use PBS::Output ;
use PBS::Constants ;
use PBS::Distributor ;
use Data::TreeDumper ;
use Time::HiRes qw(gettimeofday tv_interval) ;
use PBS::Build ;
use PBS::Build::Forked ;

use IO::Socket;
use IO::Select ;
#use PBS::ProgressBar ;

#-------------------------------------------------------------------------------

sub Build
{
my $t0 = [gettimeofday];

# Kids, don't do this at home!
no warnings qw(redefine) ;
local *PBS::Build::Forked::StartBuilderProcess = \&StartBuilderProcess ;
local *PBS::Build::Forked::SendIpcToBuildNode = \&SendIpcToBuildNode ;

my $pbs_config      = shift ;
our $build_sequence = shift ;
my $inserted_nodes  = shift ;

my $build_queue = PBS::Build::Forked::EnqueuTerminalNodes($build_sequence, $pbs_config) ;

my $number_of_nodes_to_build = scalar(@$build_sequence) - 1 ; # -1 as PBS root is never build
my $number_of_terminal_nodes = scalar(keys %$build_queue) ;

my $distributor        = PBS::Distributor::CreateDistributor($pbs_config, $build_sequence) ;
my $number_of_builders = PBS::Build::Forked::GetNumberOfBuilders($number_of_terminal_nodes, $pbs_config, $distributor) ;
my $builders           = PBS::Build::Forked::StartBuilders($number_of_builders, $pbs_config, $distributor, , $build_sequence, $inserted_nodes) ;

my $number_of_already_build_node = 0 ;
my $number_of_failed_builders = 0 ;
my $error_output = '' ;

my %builder_stats ;
my $builder_using_perl_time = 0 ;

my $progress_bar = PBS::Build::Forked::CreateProgressBar($pbs_config, $number_of_nodes_to_build) ;
my $node_build_index = 0 ;

while(%$build_queue)
	{
	# start building a node if a process is free and no error occured
	unless($number_of_failed_builders)
		{
		my $started_builders = PBS::Build::Forked::StartEnqueuedNodesBuild
					(
					  $pbs_config
					, $build_queue
					, $builders
					, $node_build_index
					, $number_of_nodes_to_build
					, \%builder_stats
					) ;
					
		$node_build_index += $started_builders ; 
		}
	
	my @built_nodes = PBS::Build::Forked::WaitForBuilderToFinish($pbs_config, $builders) ;
	
	@built_nodes || last if $number_of_failed_builders ; # stop if nothing is building and an error occured
		
	for my $built_node_name (@built_nodes)
		{
		my ($build_result, $build_time, $node_error_output) = PBS::Build::Forked::CollectNodeBuildResult($pbs_config, $built_node_name, $build_queue) ;
		
		$number_of_already_build_node++ ;
		
		if($build_result == BUILD_SUCCESS)
			{
			# mark the node as BUILD etc...
			# generate md5 etc.. see BuildNode after BUILD_SUCCESS is received
			# post_build
			
			$progress_bar->update($number_of_already_build_node) if $progress_bar ;
			$builder_using_perl_time += $build_time if PBS::Build::NodeBuilderUsesPerlSubs($build_queue->{$built_node_name}) ;
			
			PBS::Build::Forked::EnqueueNodeParents($pbs_config, $build_queue->{$built_node_name}{NODE}, $build_queue) ;
			}
		else
			{
			$error_output .= $node_error_output ;
			$number_of_failed_builders++ ;
			}
		
		delete $build_queue->{$built_node_name} ;
		}
	}

PBS::Build::Forked::TerminateBuilders($builders) ;

if($number_of_failed_builders)
	{
	PrintError "** Failed build@{[$number_of_failed_builders > 1 ? 's' : '']} **\n" ;
	print $error_output ;
	}
	
if(defined $pbs_config->{DISPLAY_SHELL_INFO})
	{
	print WARNING DumpTree(\%builder_stats, '** Builder process statistics: **', DISPLAY_ADDRESS => 0) ;
	}
	
if($pbs_config->{DISPLAY_TOTAL_BUILD_TIME})
	{
	PrintInfo(sprintf("Total build time: %0.2f s. Perl subs time: %0.2f s.\n", tv_interval ($t0, [gettimeofday]), $builder_using_perl_time)) ;
	}

return(!$number_of_failed_builders) ;
}

#----------------------------------------------------------------------------------------------------------------------

sub StartBuilderProcess
{
my ($pbs_config, $build_sequence, $inserted_nodes, $shell, $builder_info) = @_ ;

#connect to server, return socket
my ($server, $port) = split(':', $pbs_config->{LIGHT_WEIGHT_FORK}) ;

my $remote = IO::Socket::INET->new
		(
		Proto    => "tcp",
		PeerAddr => $server,
		PeerPort => $port,
		) or die ERROR "Can't connect to pbs shell command server port @ '$server:$port'.\n";
	    
return($remote) ;
}

#-------------------------------------------------------------------------------------------------------

sub SendIpcToBuildNode
{
my ($pbs_config, $node, $node_index, $number_of_nodes_to_build, $pid) = @_ ;
my $node_name = $node->{__NAME} ; 

my $shell_command_generator = $node->{__SHELL_COMMANDS_GENERATOR} ;

if(defined $pbs_config->{DISPLAY_JOBS_INFO})
	{
	my $percent_done = int(($node_index * 100) / $number_of_nodes_to_build) ;
	my $node_build_sequencer_info = "$node_index/$number_of_nodes_to_build, $percent_done%" ;
	
	if(defined  $shell_command_generator)
		{
		PrintInfo "Starting build of  '$node_name' ($node_build_sequencer_info) using light weight process.\n" ;
		}
	else
		{
		PrintInfo "Starting build of '$node_name' ($node_build_sequencer_info).\n" ;
		}
	}
	
# IPC start the build
if(! defined $node->{__SHELL_OVERRIDE} && defined $shell_command_generator)
	{
	my $history = $node->{__SHELL_COMMANDS_GENERATOR_HISTORY} ;
	
	if(@$history > 1)
		{
		PrintWarning DumpTree($history, "\nMultiple shell commands for '$node_name': Using " . @$history[-1]) ;
		}
	
	my $builder_channel = $pid->{BUILDER_CHANNEL} ;
	my @shell_commands = $shell_command_generator->($node) ;
	
	# create path to node!
	my $build_name = $node->{__BUILD_NAME} ;
	my ($basename, $path, $ext) = File::Basename::fileparse($build_name, ('\..*')) ;
	
	unless(-e $path)
		{
		use File::Path ;
		mkpath($path) ;
		}
	
	print $builder_channel "NODE_NAME" . "__PBS_FORKED_BUILDER__"
				. $node_name . "__PBS_FORKED_BUILDER__\n" ;
				
	print $builder_channel "RUN_COMMANDS" . "__PBS_FORKED_BUILDER__"
				. join('__PBS_FORKED_BUILDER__', @shell_commands) . "__PBS_FORKED_BUILDER__\n" ;
	}
else
	{
	#perl sub,  build ourselves???
	die ERROR "Error: No support yet to build nodes using perl subs in -ubs mode!\n" ;
	}
}

#---------------------------------------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

PBS::Build::LightWeightServer -

=head1 DESCRIPTION

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut


