=head1 PBSFILE USER HELP

=head2 I<user_build.pl>

I<user_build.pl> is to be used with the Perl Build System (B<PBS>).

=head2 Description

This I<Pbsfile> shows you how to Define your own Build()  sub.

=cut 

use strict ;
use warnings ;
use Data::Dumper ;

use PBS::Output ;

#-------------------------------------------------------------------------------

die "Old example kept for historical reasons only!\n" ;

=head2 Used B<PBS> libs

none.

=head2 Top rules

=over 2 

=item * '*.lib'

=back

=head2 Rules

4 rules are defined:

=over 2 

=item * B<lib> defines a dependency on a 'a' type file, 'b' type files and 5 't' type files, builder alwas succed (for the example sake)

=item * B<a> defines no dependencies, builder always succed

=item * B<b> defines no dependencies, builder always succed

=item * B<t> defines no dependencies, builder always succed

=back

=cut

AddRule 'lib',
	[
	'*.lib' =>
		  '*.a'
		, '[path]/a1.t'
		, '[path]/a2.t'
		, '*.b'
		, '[path]/a3.t'
		, '[path]/a4.t'
		, '[path]/a5.t'
	], 
	BuildOk("Library built.\n") ;

AddRule 'a', ['*.a' => undef], BuildOk("'a' type file built.\n") ;
AddRule 'b', ['*.b' => undef], BuildOk("'b' type file built.\n") ;
AddRule 't', ['*.t' => undef], BuildOk("'t' type file built.\n") ;

=head2 User defined B<Build()>

=over 2 

=item * Define your own Build()  sub.

=back

=cut

sub Build
{
my $Pbsfile            = shift ;
my $package_alias      = shift ;
my $load_package       = shift ;
my $pbs_config         = shift ;
my $rules_namespaces   = shift ;
my $rules              = shift ; 
my $config_namespaces  = shift ;
my $config_snapshot    = shift ;
my $build_directory    = $pbs_config->{BUILD_DIRECTORY} ;
my $source_directories = $pbs_config->{SOURCE_DIRECTORIES} ;
my $targets            = shift ; # a rule to build the targets exists in 'Builtin' this  argument is not used
my $inserted_nodes     = shift ;
my $dependency_tree    = shift ;
my $build_point        = shift ;
my $build_type         = shift ;

die "Unsupported mode\n" unless DEPEND_CHECK_AND_BUILD == $build_type ;
die "Unsupported composite target build\n" if ($build_point ne '') ;

=over 2 

=item * Call B<PBS> DefaultBuild to do the depending and checking part

=back

=cut

my $build_sequence = PBS::DefaultBuild::DefaultBuild
							(
							  $Pbsfile
							, $package_alias
							, $load_package
							, $pbs_config
							, $rules_namespaces
							, $rules
							, $config_namespaces
							, $config_snapshot
							, $targets
							, $inserted_nodes
							, $dependency_tree
							, $build_point
							, DEPEND_AND_CHECK
							) ;
							
=over 2 

=item * Manipulate the Build sequence

=back

	Remove all the 't' type files from the build sequence and build them

=cut

PrintInfo("\n** Special Build **\n") ;

if(defined $pbs_config->{USER_OPTIONS}{DBS})
	{
	warn Data::Dumper->Dump([$build_sequence], ['build_sequence']) ;
	}

my (@t_nodes, @other_nodes) ;
for my $node (@$build_sequence)
	{
	if($node->{__NAME} =~ /\.t$/)
		{
		PrintInfo("Removing '$node->{__NAME}' from original build sequence.\n") ;
		push @t_nodes, $node ;
		}
	else
		{
		push @other_nodes, $node ;
		}
	}

# build the node
PBS::Digest::GenerateNodeDigest($_) for (@t_nodes) ;
PrintInfo("All '.t' nodes built\n") ;


# the following  is very important
# if you _don't_ use -j when building, the build sequence is ordered
# and everything works fine. But when using the -j switch, PBS reorders
# the build to a more effective parallel sequence. The parallel sequence 
# used the parent/child relationship.

# Children must be tagged as already build.
for my $node (@t_nodes)
	{
	$node->{__BUILD_DONE} = "'t' node builder @ $Pbsfile" ;
	}

=over 2 

=item * Call B<PBS> do the the rest of the build step

=back

=cut

PBS::Build::BuildSequence
	(
	  $package_alias
	, $pbs_config
	, \@other_nodes
	) ;

PrintInfo("\n**Special Build Done**\n") ;
}

=head2 Running the example I<Pbsfile>

	perl pbs.pl -p user_build.pl -f -dd -be x.lib

=cut

=head1 End  of PBSFILE USER HELP!

=cut

