package MyCPAN::App::DPAN;
use strict;
use warnings;

use base qw(MyCPAN::App::BackPAN::Indexer);
use vars qw($VERSION $logger);

use Cwd qw(cwd);
use File::Spec::Functions;
use Log::Log4perl;

$VERSION = '1.281';

=encoding utf8

=head1 NAME

MyCPAN::App::DPAN - Create a CPAN-like structure out of some dists

=head1 SYNOPSIS

	use MyCPAN::App::DPAN;

	my $application = MyCPAN::App::DPAN->activate( @ARGV );

	# do some other stuff, anything that you like

	$application->activate_end;

=head1 DESCRIPTION

This module ties together all the bits to let the C<dpan> do its work. It
overrides the defaults in C<MyCPAN::App::BackPAN::Indexer> to provide the
right components.

The work happens in two steps. When you call C<activate>, the program goes
through all of the steps to examin each of the module distributions. It creates
a report for each distribution, then stops. This pause right after the
examination gives you the chance to do something right before the program
creates the PAUSE index files. The examination might take several minutes
(or even hours depending on how much you want to index), so you have a chance
to check the state of the world before the next step.

When you call C<activate_end>, the program takes the results from the
previous step and creates the PAUSE index files in the F<modules> directory.
This step should be very quick since all of the information is ready-to-go.

=cut

=head1 METHODS

=over 4

=cut

BEGIN {
use vars qw( $Starting_dir );
$Starting_dir = cwd();

$SIG{INT} = sub { print "Caught SIGINT\n"; chdir $Starting_dir; exit() };

my $cwd = cwd();

my $report_dir = catfile( $cwd, 'indexer_reports' );

my %Defaults = (
    author_map                  => undef,
	dpan_dir                    => $cwd,
	collator_class              => 'MyCPAN::App::DPAN::Reporter::Minimal',
	dispatcher_class            => 'MyCPAN::Indexer::Dispatcher::Serial',
	extra_reports_dir           => undef,
	fresh_start                 => defined $ENV{DPAN_FRESH_START} ? $ENV{DPAN_FRESH_START} : 0,
	i_ignore_errors_at_my_peril => 0,
	ignore_missing_dists        => 0,
	ignore_packages             => 'main MY MM DB bytes DynaLoader',
	indexer_class               => 'MyCPAN::App::DPAN::Indexer',
	organize_dists              => 1,
	parallel_jobs               => 1,
	pause_id                    => 'DPAN',
	pause_full_name             => "DPAN user <CENSORED>",
	queue_class                 => 'MyCPAN::App::DPAN::SkipQueue',
	relative_paths_in_report    => 1,
	reporter_class              => 'MyCPAN::App::DPAN::Reporter::Minimal',
	skip_perl                   => 0,
	use_real_whois              => 0,
	);

=item default_keys

Returns the list of default configuration directive.

=cut

sub default_keys
	{
	my %Seen;
	grep { ! $Seen{$_}++ } keys %Defaults, $_[0]->SUPER::default_keys;
	}

=item default( DIRECTIVE )

Returns the configuration value for DIRECTIVE.

=cut

sub default
	{
	exists $Defaults{ $_[1] }
		?
	$Defaults{ $_[1] }
		:
	$_[0]->SUPER::default( $_[1] );
	}

=item adjust_config

Adjusts the configuration to set various internal values. You don't need
to call this yourself.

=cut

sub adjust_config
	{
	my( $application ) = @_;

	my $coordinator = $application->get_coordinator;
	my $config      = $coordinator->get_config;

	# the Indexer stuff expects the directory in backpan_dir
	if( $config->exists( 'dpan_dir') )
		{
		$config->set(
			'backpan_dir',
			$config->get( 'dpan_dir' )
			);
		}

	$application->SUPER::adjust_config;
	}

$logger = Log::Log4perl->get_logger( 'backpan_indexer' );
}

=item activate_steps

Returns the list of methods to invoke from C<activate>. By overriding this
method you can change the DPAN process.

=cut

sub activate_steps
	{
	qw(
	process_options
	setup_coordinator
	setup_environment
	handle_config
	setup_logging
	fresh_start
	setup_dirs
	run_components
	);
	}

=item activate_end

Runs right before C<dpan> is about to exit. It calls the postflight
handler if one if configured. It prints a short summary message to
standard output.

=cut

sub activate_end
	{
	my( $application ) = @_;

	my $coordinator = $application->get_coordinator;
	$application->cleanup;

	$application->_handle_postflight;

	print <<"HERE" unless( $coordinator->get_note( 'epic_fail' ) || $coordinator->get_note( 'postflight_failure' ) );
=================================================
Ensure you reload your indices in your CPAN tool!

For CPAN.pm, use:

	cpan> reload index

For CPANPLUS, use

	CPAN Terminal> x
=================================================
HERE

	print <<"HERE" if $coordinator->get_note( 'epic_fail' );
=================================================
Something really bad happened and I couldn't
finish creating the index files. The DPAN is
incomplete.
=================================================
HERE

	print <<"HERE" if $coordinator->get_note( 'postflight_failure' );
=================================================
I wasn't able to complete the postflight step.
DPAN might be okay, but your post processing
may have failed.
=================================================
HERE

	$application->_exit;
	}

sub _handle_postflight
	{
	my( $application ) = @_;

	$logger->info( "Handling cleanup" );

	my $config = $application->get_coordinator->get_config;

	# if it's not in the config then we're done already.
	return 1 unless $config->exists( 'postflight_class' );

	my $class = $config->get( 'postflight_class' );

	if( $application->_check_postflight_class( $class ) )
		{
		eval { $class->run( $application ) } or do {
			my $at = $@;
			$logger->error( "postflight class [$class] complained: $at" );
			$application->get_coordinator->set_note( 'postflight_failure', $at );
			return;
			};
		}

	return 1;
	}

sub _check_postflight_class
	{
	my( $application, $class ) = @_;

	if( eval( "require $class; 1" ) )
		{
		unless( eval { $class->can('run') } )
			{
			my $error = "Class [$class] does not claim to have a run() method";
			$logger->error( $error );
			$application->get_coordinator->set_note( 'postflight_class_failure', $error );
			return;
			}
		}
	else
		{
		my $at = $@;
		$logger->error( "Could not load postflight class [$class]: $at" );
		$application->get_coordinator->set_note( 'postflight_class_failure', $at );
		return;
		}

	return 1;
	}

=item components

Returns the list of components to load and the implementing classes.

=cut

sub components
	{
	(
	[ qw( queue      MyCPAN::Indexer::Queue                get_queue      ) ],
	[ qw( dispatcher MyCPAN::Indexer::Dispatcher::Serial   get_dispatcher ) ],
	[ qw( reporter   MyCPAN::App::DPAN::Reporter::Minimal  get_reporter   ) ],
	[ qw( worker     MyCPAN::Indexer::Worker               get_task       ) ],
	[ qw( collator   MyCPAN::App::DPAN::Reporter::Minimal  get_collator   ) ],
# this has to be last because it kicks off everything
	[ qw( interface  MyCPAN::Indexer::Interface::Text      do_interface   ) ],
	)
	}

=item fresh_start

If C<fresh_start> is set, this method deletes the reports in the
report directory, leaving the directories in place.

=cut

sub fresh_start
	{
	my( $application ) = @_;

	my $config = $application->get_coordinator->get_config;

	return unless $config->get( 'fresh_start' );

	require File::Path;
	foreach my $dir ( map { my $m = "${_}_report_subdir"; $config->$m() } qw(error success) )
		{
		$logger->info( "Cleaning report directory [$dir]" );
		unlink glob( catfile( $dir, '*' ) );
		}

	return 1;
	}

1;

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-app-dpan.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut
