package MyCPAN::App::DPAN::Indexer;
use strict;
use warnings;

use subs qw(get_caller_info);
use vars qw($VERSION $logger);

# don't change the inheritance order
# this should be done with roles, but we don't quite have that yet
# it's a problem with who's cleanup() get called
use base qw(MyCPAN::App::BackPAN::Indexer MyCPAN::Indexer);

use Cwd qw(cwd);
use File::Basename qw(dirname);
use File::Path qw(mkpath);
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile rel2abs);

$VERSION = '1.28';

=head1 NAME

MyCPAN::App::DPAN::Indexer - Create a D(ark)PAN out of the indexed distributions

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

This module implements the indexer_class and reporter_class components
to allow C<backpan_indexer.pl> to create a CPAN-like directory structure
with its associated index files. This application of MyCPAN::Indexer is
specifically aimed at creating a 02packages.details file, so it
strives to collect a minimum of information.

It runs through the indexing and prints a report at the end of the run.

=cut

use Carp qw(croak);
use Cwd  qw(cwd);

use Log::Log4perl;

BEGIN {
	$logger  = Log::Log4perl->get_logger( 'Indexer' );
	}

# Override the exit from the parent class so we can embed a run
# inside a bigger application. Applications should override this
# on their own to do any final processing they want.
sub _exit { 1 }

__PACKAGE__->activate( @ARGV ) unless caller;

=head2 Indexer class

=over 4

=item examine_dist_steps

Returns the list of techniques that C<examine_dist> should use
to index distributions. See the documentation in
C<MyCPAN::Indexer::examine_dist_steps>.

For DPAN, unpack the dist, ensure you are in the dist directory,
the find the modules.

=cut

sub examine_dist_steps
	{
	(
	#    method                error message                  fatal
	[ 'unpack_dist',        "Could not unpack distribution!",    1 ],
	[ 'find_dist_dir',      "Did not find distro directory!",    1 ],
	[ 'find_modules',       "Could not find modules!",           1 ],
	[ 'examine_modules',    "Could not process modules!",        0 ],
	);
	}

=item find_modules_techniques

Returns the list of techniques that C<find_modules> should use
to look for Perl module files. See the documentation in
C<MyCPAN::Indexer::find_modules>.

=cut

sub find_module_techniques
	{
	my( $self ) = @_;

=pod

Save this feature for another time

	my $config = $self->get_coordinator->get_config;
	
	if( my @techniques = $config->get( 'find_module_techniques' ) )
		{
		$logger->debug( "Using techniques [@techniques] to find modules" );
		
		@techniques = map {
			my $can =  $self->can( $_ );
			$logger->warn( "The technique [$_] is unknown" )
				unless $can;
			$can ? [ $_, 'Technique $_ specified by config' ] : ();
			} @techniques;
			
		return \@techniques;
		}

=cut

	
	(
	[ 'look_in_lib',               "Guessed from looking in lib/"      ],
	[ 'look_in_cwd',               "Guessed from looking in cwd"       ],
	[ 'look_in_meta_yml_provides', "Guessed from looking in META.yml"  ],
	[ 'look_for_pm',               "Guessed from looking in cwd"       ],
	);
	}

=item get_module_info_tasks

Returns the list of techniques that C<get_module_info> should use
to extract data from Perl module files. See the documentation in
C<MyCPAN::Indexer::get_module_info>.

=cut

sub get_module_info_tasks
	{
	(
	[ 'extract_module_namespaces',   'Extract the namespaces a file declares' ],
	[ 'extract_module_version',      'Extract the version of the module'      ],
	)
	}

=item setup_run_info

Like C<setup_run_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The DarkPAN census really just cares about finding packages,
so the details about the run aren't as interesting.

=cut

sub setup_run_info
	{
#	TRACE( sub { get_caller_info } );

	$_[0]->set_run_info( 'root_working_dir', cwd()   );
	$_[0]->set_run_info( 'run_start_time',   time    );
	$_[0]->set_run_info( 'completed',        0       );
	$_[0]->set_run_info( 'pid',              $$      );
	$_[0]->set_run_info( 'ppid',             $_[0]->getppid );

	$_[0]->set_run_info( 'indexer',          ref $_[0] );
	$_[0]->set_run_info( 'indexer_versions', $_[0]->VERSION );

	return 1;
	}


=item setup_dist_info

Like C<setup_dist_info> in C<MyCPAN::Indexer>, but it remembers fewer
things. The test census really just cares about statements in the test
files, so the details about the distribution aren't as interesting.

=cut

sub setup_dist_info
	{
#	TRACE( sub { get_caller_info } );

	my( $self, $dist ) = @_;

	$logger->debug( "Setting dist [$dist]\n" );
	$self->set_dist_info( 'dist_file', $dist );

	return 1;
	}

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

      git://github.com/briandfoy/mycpan-indexer.git
      git://github.com/briandfoy/mycpan--app--dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2009, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut
