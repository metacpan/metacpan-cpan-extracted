package PBS::Build ;

use PBS::Debug ;
use 5.006 ;

use strict ;
use warnings ;
use Data::Dumper ;
use Data::TreeDumper ;
use PBS::ProgressBar ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.04' ;

use Time::HiRes qw(gettimeofday tv_interval) ;

use PBS::Config ;
use PBS::Depend ;
use PBS::Check ;
use PBS::Output ;
use PBS::Constants ;
use PBS::Digest ;
use PBS::Information ;
use PBS::PBSConfig ;
use PBS::Build::NodeBuilder ;

#-------------------------------------------------------------------------------
$|++ ;
#-------------------------------------------------------------------------------
 
sub BuildSequence
{
# display some information about the build  and choose between sequential and parallel build

my $pbs_config      = shift ;
my $build_sequence  = shift ; # array of node references, including PBS virtual root
my $inserted_nodes  = shift ; # hash of node references

if
	(
		0 == @$build_sequence
	||
		(1 == @$build_sequence && $build_sequence->[0]{__NAME} =~ /^__/) #only root is present
	)
	{
	PrintInfo("Nothing to build.\n") ;
	return(BUILD_SUCCESS, 'Nothing to build') ; ;
	}
else
	{
	my $number_of_nodes_to_build = 0 ;
	my $number_of_virtual_nodes_to_build = 0 ;
	
	my @bi_regex_matched = map {0} @{$pbs_config->{DISPLAY_BUILD_INFO}} ;
	
	my $node_builders_using_perl_subs = 0 ;
	my $node_builders_not_using_perl_subs = 0;
	
	for my $node (@$build_sequence)
		{
		my $node_name = $node->{__NAME} ;
		next if($node_name =~ /^__/) ;
		
		if(PBS::Build::NodeBuilderUsesPerlSubs($node))
			{
			$node_builders_using_perl_subs++ ;
			}
		else
			{
			$node_builders_not_using_perl_subs++ ;
			}
			
		$number_of_nodes_to_build++ ;
		
		if(defined $node->{__VIRTUAL})
			{
			$number_of_virtual_nodes_to_build++  ;
			}
			
		# match all the nodes to the build_info regexes
		my $bi_regex_index = -1 ;
		
		for my $bi_regex (@{$pbs_config->{DISPLAY_BUILD_INFO}})
			{
			$bi_regex_index++ ;
			
			if($node_name =~ /$bi_regex/)
				{
				$bi_regex_matched[$bi_regex_index]++ ;
				}
			}
		}
		
	my $perl_vs_shellcommands = ", $node_builders_using_perl_subs P, $node_builders_not_using_perl_subs S" ;
	my $plural = $number_of_nodes_to_build > 1 ? 's' : '' ;
	PrintInfo("$number_of_nodes_to_build [${number_of_virtual_nodes_to_build}V$perl_vs_shellcommands] node$plural scheduled for build.\n") ;

	if(defined (my $lh = $pbs_config->{CREATE_LOG}))
		{
		print $lh INFO "$number_of_nodes_to_build [${number_of_virtual_nodes_to_build}V$perl_vs_shellcommands] node$plural scheduled for build.\n" ;
		}
		
	# display which --bi don't match
	my $no_bi_regex_matched = 1 ;
	
	for (my $bi_regex_index = 0 ; $bi_regex_index < @bi_regex_matched ; $bi_regex_index++)
		{
		if($bi_regex_matched[$bi_regex_index])
			{
			$no_bi_regex_matched = 0 ;
			}
		else
			{
			PrintWarning("--bi $pbs_config->{DISPLAY_BUILD_INFO}[$bi_regex_index] doesn't match any node in the build sequence.\n") ;
			}
		}
		
	if(@{$pbs_config->{DISPLAY_BUILD_INFO}} && $no_bi_regex_matched)
		{
		PrintWarning("No --bi switch matched.\n") ;
		}
	else
		{
		if(defined $pbs_config->{JOBS})
			{
			#~ PrintWarning("--j switch disable till perl get better threads than the completely useless Ithreads.\n") ;
			#~ use PBS::ThreadedBuild ;
			#~ return
				#~ (
				#~ PBS::ThreadedBuild::ThreadedBuild($package_alias , $pbs_config, $build_sequence, $inserted_nodes) 
				#~ ) ;
				
			if(defined $pbs_config->{LIGHT_WEIGHT_FORK})
				{
				eval "use PBS::Build::LightWeightServer ;" ;
				die $@ if $@ ;
				
				return
					(
					PBS::Build::LightWeightServer::Build($pbs_config, $build_sequence, $inserted_nodes) 
					) ;
				}
			else
				{
				eval "use PBS::Build::Forked ;" ;
				die $@ if $@ ;
				
				return
					(
					PBS::Build::Forked::Build($pbs_config, $build_sequence, $inserted_nodes) 
					) ;
				}
			}
		else
			{
			return
				(
				SequentialBuild($pbs_config, $build_sequence, $inserted_nodes)
				) ;
			}
		}
	}
}

#-----------------------------------------------------------------------------------------

sub SequentialBuild
{
my $pbs_config      = shift ;
my $build_sequence  = shift ;
my $inserted_nodes  = shift ;

my ($build_result, $build_message) = (BUILD_SUCCESS, 'Nothing to build') ;

my $t0 = [gettimeofday];

my $node_build_index = 0 ;

my $number_of_nodes_to_build ;
for (@$build_sequence)
	{
	my $node_name = $_->{__NAME} ;
	next if($node_name =~ /^__/) ;
	$number_of_nodes_to_build++ ;
	}

my $progress_bar ;

if($pbs_config->{DISPLAY_PROGRESS_BAR})
	{
	$progress_bar = PBS::ProgressBar->new
			({
			  count => $number_of_nodes_to_build 
			, ETA   => "linear", 
			#~ , pre_update_user_code => $PBS::Output::global_info_escape_code
			#~ , post_update_user_code => $PBS::Output::global_reset_escape_code
			});
	}
	
my $failed_but_no_stop_set ; # holds error if NO_STOP was set

my $builder_using_perl_time = 0 ;

for my $node (@$build_sequence)
	{
	my $name = $node->{__NAME} ;
	
	next if($name =~ /^__/) ;

	$node_build_index++ ;
	
	my $build_this_node = 0 ;
	
	if(0 == @{$pbs_config->{DISPLAY_BUILD_INFO}})
		{
		$build_this_node++ ,
		}
	else
		{
		for my $bi_regex (@{$pbs_config->{DISPLAY_BUILD_INFO}})
			{
			if($name =~ /$bi_regex/)
				{
				$build_this_node++ ,
				}
			}
		}
	
	next unless $build_this_node ;
	
	my $percent_done = int(($node_build_index * 100) / $number_of_nodes_to_build ) ;
	my $tn0 = [gettimeofday];

	($build_result, $build_message) = PBS::Build::NodeBuilder::BuildNode
						(
						  $node
						, $node->{__PBS_CONFIG}
						, $inserted_nodes
						, "$node_build_index/$number_of_nodes_to_build, $percent_done%"
						) ;
						
	$builder_using_perl_time += tv_interval ($tn0, [gettimeofday]) if NodeBuilderUsesPerlSubs($node) ;
	
	$progress_bar->update($node_build_index) if($pbs_config->{DISPLAY_PROGRESS_BAR} && $build_result != BUILD_FAILED) ;
	
	if($build_result == BUILD_SUCCESS)
		{
		PBS::Depend::SynchronizeAfterBuild($node) ;
		}
	
	if(@{$pbs_config->{DISPLAY_BUILD_INFO}})
		{
		PrintWarning("--bi defined, continuing.\n") ;
		}
	else
		{
		if($build_result == BUILD_FAILED)
			{
			last unless $pbs_config->{NO_STOP} ;
			$failed_but_no_stop_set++ ;
			}
		}
	}
	
if($pbs_config->{DISPLAY_TOTAL_BUILD_TIME})
	{
	PrintInfo(sprintf("Total build time: %0.2f s. Perl subs time: %0.2f s.\n", tv_interval ($t0, [gettimeofday]), $builder_using_perl_time)) ;
	}

if($failed_but_no_stop_set)
	{
	($build_result, $build_message) = (BUILD_FAILED, "Failed but NO_STOP flag was set") ;
	}

return($build_result, $build_message) ;
}

#-----------------------------------------------------------------------------------------

sub NodeBuilderUsesPerlSubs
{
my $file_tree = shift ;

return(! defined $file_tree->{__SHELL_COMMANDS_GENERATOR}) ;
}

#-----------------------------------------------------------------------------------------------------------------------------------

1 ;

__END__

=head1 NAME

PBS::Build  -

=head1 SYNOPSIS

  use PBS::Build ;
  PBS::Build::BuildSequence($package, $config, $build_sequence) ;

=head1 DESCRIPTION

	PBS::Build::BuildSequence: Chooses between a sequential and parallel build
	PBS::Build::SequentialBuild: Builds the sequence sequentialy
	PBS::Build::NodeBuilder::BuildNode: Builds a node

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

PBS reference manual.

=cut
