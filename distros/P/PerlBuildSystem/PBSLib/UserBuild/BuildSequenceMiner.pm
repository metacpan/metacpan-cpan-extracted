use strict ;
use warnings ;
use Data::Dumper ;

use PBS::Output ;
use PBS::Shell ;

die "Old example kept for historical reasons only!\n This can be made to work again :)\n" ;

#-------------------------------------------------------------------------------
sub BuildSequenceMiner
{
my @build_arguments = @{shift @_} ;
my @miners          = @{shift @_} ;

my $Pbsfile            = shift @build_arguments ;
my $package            = shift @build_arguments ;
my $load_package       = shift @build_arguments ;
my $pbs_config         = shift @build_arguments ;
my $rules_namespaces   = shift @build_arguments ;
my $rules              = shift @build_arguments ;
my $config_namespaces  = shift @build_arguments ;
my $config             = shift @build_arguments ;
my $targets            = shift @build_arguments ; # automatically build in rule 'BuiltIn::__ROOT', argument is given as information only
my $inserted_files     = shift @build_arguments ;
my $dependency_tree    = shift @build_arguments ;
my $build_point        = shift @build_arguments ;
my $depend_and_build   = shift @build_arguments ;

die "Unsupported mode\n" unless DEPEND_CHECK_AND_BUILD == $depend_and_build ;
die "Unsupported composite target build\n" if ($build_point ne '') ;

my $build_sequence = PBS::DefaultBuild::DefaultBuild
							(
							  $Pbsfile
							, $package
							, $load_package
							, $pbs_config
							, $rules_namespaces
							, $rules
							, $config_namespaces
							, $config
							, $targets
							, $inserted_files
							, $dependency_tree
							, $build_point
							, DEPEND_AND_CHECK
							) ;
							

PrintInfo("\n** Building **\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;
PrintInfo("\n** Building with Build Sequence Miners **\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;

my @remaining_nodes = @{$build_sequence} ;
for my $miner (@miners)
	{
	my ($build_result, $build_message) ;
	
	($build_result, $build_message, @remaining_nodes) = $miner->($package, $pbs_config, @remaining_nodes) ;
	
	return ($build_result, $build_message) if $build_result == BUILD_FAILED ;
	}

PrintInfo("\n** Building with Build Sequence Miners Done**\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;

return
	(
	PBS::Build::BuildSequence
		(
		  $package
		, $pbs_config
		, \@remaining_nodes
		)
	) ;
}

#-------------------------------------------------------------------------------
1;

