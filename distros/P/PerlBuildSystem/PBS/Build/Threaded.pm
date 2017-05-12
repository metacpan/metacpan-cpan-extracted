package PBS::Build::Threaded ;
use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::Dumper ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.01' ;

use PBS::Output ;
use PBS::Constants ;

die <<EOD ;
#-------------------------------------------------------------------------------
# Attempt to use the completely useless Ithreads to implement threaded build.
# This works  but the overhead is one to TEN! orders of magnitude greater than the 
# saved time in most cases.
#-------------------------------------------------------------------------------
EOD

my $result_queue ;
my $command_queue ;

use Config ;

if($Config{useithreads})
	{
	require threads         ; import threads @threads::EXPORT ;
	require threads::shared ; import threads::shared @threads::shared::EXPORT ;
	require Thread::Queue   ; import Thread::Queue @Thread::Queue::EXPORT  ;

	$command_queue = new Thread::Queue;
	share($command_queue) ;
	
	$result_queue = new Thread::Queue;
	share($result_queue) ;
	} ;

#-------------------------------------------------------------------------------
use constant NODE_NAME               => 0 ;
use constant CHILDRENT_LEFT_TO_BUILD => 1 ;
use constant PARENTS_LIST            => 2 ;

#-------------------------------------------------------------------------------

sub ThreadedBuild
{
unless($Config{useithreads})
	{
	PrintWarning("No Ithread support available in this perl, continuing without Ithreads.\n") ;
	return(PBS::Build::SequentialBuild(@_)) ;
	}

my $package_alias  = shift ;
my $pbs_config     = shift ;
my $build_sequence = shift ;
my $inserted_nodes = shift ;

# build a parallel sequence from the sequencial build sequence
my @parallel_build_sequence_data = () ;
my %parent_reference_to_index ;

for(my $node_index = 0 ; $node_index < @$build_sequence ; $node_index++)
	{
	$parent_reference_to_index{$build_sequence->[$node_index]} = $node_index ;
	}

for(my $node_index = 0 ; $node_index < @$build_sequence ; $node_index++)
	{
	my $file_tree = $build_sequence->[$node_index] ;
	
	my @parent_indexes ;
	for my $parent (@{$file_tree->{__PARENTS}})
		{
		unless(defined $parent_reference_to_index{$parent})
			{
			PrintError("Not good at all!, child to be rebuild but not parent!\n") ;
			die ;
			}
			
		push @parent_indexes, $parent_reference_to_index{$parent} ;
		}
		
	# handle the case where a user Build() builds some of the node in a sequqence
	for my $child (keys %$file_tree)
		{
		next if $child =~ /^__/ ;
		
		if(defined $file_tree->{$child}{__BUILD_DONE})
			{
			if(defined $pbs_config->{DISPLAY_JOBS_INFO})
				{
				PrintInfo("Removing '$file_tree->{$child}{__NAME}' from parallel sequence dependency.\n") ;
				}
				
			$file_tree->{__CHILDREN_TO_BUILD}-- ;
			}
		}
		
	push @parallel_build_sequence_data, 
		[
		  $file_tree->{__NAME}
		, $file_tree->{__CHILDREN_TO_BUILD} || 0
		, [@parent_indexes]
		]
	}

my $number_of_nodes_to_build = @parallel_build_sequence_data ;
$number_of_nodes_to_build-- ; # root node is virtual and is never build.

my $number_of_terminal_nodes = 0 ;

for(my $node_index = 0 ; $node_index < @parallel_build_sequence_data ; $node_index++)
	{
	if($parallel_build_sequence_data[$node_index][CHILDRENT_LEFT_TO_BUILD] == 0)
		{
		$number_of_terminal_nodes++ ;
		if(defined $pbs_config->{DISPLAY_JOBS_INFO})
			{
			PrintInfo("Enqueuing terminal node: '$parallel_build_sequence_data[$node_index][NODE_NAME]'. Node index: [$node_index] \n") ;
			}
			
		$command_queue->enqueue($node_index);
		}
	}

my $terminal_plural = '' ; $terminal_plural = 's' if ($number_of_terminal_nodes > 1) ;
my $node_plural     = '' ; $node_plural = 's' if ($number_of_nodes_to_build > 1) ;
PrintInfo("Parallel build: $number_of_nodes_to_build node$node_plural to build/$number_of_terminal_nodes terminal node$terminal_plural") ;

my $number_of_threads = $pbs_config->{JOBS} ;
	
if($number_of_threads > $number_of_terminal_nodes)
	{
	$number_of_threads = $number_of_terminal_nodes ;
	}

my $thread_plural = '' ; $thread_plural = 's' if($number_of_threads > 1) ;
PrintInfo(", using $number_of_threads thread$thread_plural out of a maximum $pbs_config->{JOBS}.\n") ;

my @threads ;
for(1 .. $number_of_threads)
	{
	push @threads, threads->create(\&BuildThread, $_, $build_sequence) ;
	}

my $root_done = 0 ; # root is virtual and inserted by PBS

my $final_build_result ;

while(! $root_done)
	{
	my $result = $result_queue->dequeue ;
	my ($finished_node_index, $build_result, $build_message, $thread_id) = split / ItS /, $result ;
	
	$final_build_result = $build_result ;
	
	if(@{$pbs_config->{DISPLAY_BUILD_INFO}})
		{
		PrintWarning("node $parallel_build_sequence_data[$finished_node_index][NODE_NAME] [$finished_node_index] is built by thread $thread_id.\n--bi defined, continuing.\n") ;
		}
	else
		{
		if($build_result == BUILD_FAILED)
			{
			if($pbs_config->{NO_STOP})
				{
				PrintWarning("--no_stop defined, ignoring error\n ") ;
				}
			else
				{
				PrintInfo("Attempting to remove commands after error. ") ;
				
				my $number_of_dequeued_command = 0 ;
				my $dequeued_command ;
				do
					{
					$dequeued_command = $command_queue->dequeue_nb() ;
					$number_of_dequeued_command++ if defined $dequeued_command ;
					}
				while(defined $dequeued_command) ;
				
				my $command_plural = '' ;
				$command_plural = 's' if $number_of_dequeued_command > 1 ;
				PrintInfo("$number_of_dequeued_command command$command_plural removed.\n") ;
				
				last ;
				}
			}
		}
	
	$number_of_nodes_to_build-- ;
	#~ print "node $parallel_build_sequence_data[$finished_node_index][NODE_NAME] [$finished_node_index] is built.($number_of_nodes_to_build left)\n" ;
	
	my $node_data = $parallel_build_sequence_data[$finished_node_index] ;
	
	my @parents = @{$parallel_build_sequence_data[$finished_node_index][PARENTS_LIST]} ;

	for my $parent_index (@parents)
		{
		$parallel_build_sequence_data[$parent_index][CHILDRENT_LEFT_TO_BUILD]-- ; #one less child to wait for
		#~ print "parent has $parallel_build_sequence_data[$parent_index][CHILDRENT_LEFT_TO_BUILD] children left to build\n" ;
		
		if(0 == $parallel_build_sequence_data[$parent_index][CHILDRENT_LEFT_TO_BUILD])
			{
			#~ print "Enqueuing $parallel_build_sequence_data[$parent_index][NODE_NAME] [$parent_index]\n" ;
			
			if(0 == @{$parallel_build_sequence_data[$parent_index][PARENTS_LIST]})
				{
				$root_done = 1 ;
				}
			else
				{
				$command_queue->enqueue($parent_index) ;
				}

			}
		}
	}

$command_queue->enqueue('stop') for(1 .. $number_of_threads) ;

for my $thread (@threads)
	{
	$thread->join() ;
	}

return($final_build_result) ;
}

sub BuildThread
{
# a thread using the default PBS::Build::BuildNode

my $thread_id = shift ;
my $build_sequence = shift ;

#~ PrintInfo "BuildThread $thread_id has started\n" ;

while(1)
	{
	my $node_index = $command_queue->dequeue ;
	
	if($node_index =~ /stop/)
		{
		#~ $result_queue->enqueue("$thread_id stopped") ;
		last ;
		}
	
	#~ PrintInfo "Thread $thread_id building '$build_sequence->[$node_index]{__NAME}'.\n" ;
	
	#!! builders expect more args in newer versions!!
	my ($build_result, $build_message)  = PBS::Build::BuildNode($build_sequence->[$node_index]) ;
	
	$result_queue->enqueue("$node_index ItS $build_result ItS $build_message ItS $thread_id") ;
	}
}

#-------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

PBS::Build::Threaded -

=head1 DESCRIPTION

Attempt to use ithreads, unfortunately the overhead is HUGE.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut

