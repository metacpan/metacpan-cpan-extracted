package MyCPAN::App::BackPAN::Indexer;

use strict;
no warnings qw(uninitialized redefine);

use vars qw($VERSION $Starting_dir $logger);

use Carp;
use Cwd qw(cwd);
use File::Basename;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile file_name_is_absolute rel2abs);
use File::Temp qw(tempdir);
use Getopt::Std;
use List::Util qw(max);
use Log::Log4perl;

$VERSION = '1.282';

=encoding utf8

=head1 NAME

MyCPAN::App::BackPAN::Indexer - The BackPAN indexer application

=head1 SYNOPSIS

	use MyCPAN::Indexer;

=head1 DESCRIPTION

=cut

$|++;

__PACKAGE__->activate( @ARGV ) unless caller;

BEGIN {
my $cwd = cwd();

my $report_dir = catfile( $cwd, 'indexer_reports' );

my %Defaults = (
	alarm                 => 15,
#	backpan_dir           => cwd(),
	copy_bad_dists        => 0,
	collator_class        => 'MyCPAN::Indexer::Collator::Null',
	dispatcher_class      => 'MyCPAN::Indexer::Dispatcher::Parallel',
	error_report_subdir   => catfile( $report_dir, 'errors'  ),
	indexer_class         => 'MyCPAN::Indexer',
	indexer_id            => 'Joe Example <joe@example.com>',
	interface_class       => 'MyCPAN::Indexer::Interface::Text',
	log_file_watch_time   => 30,
#	merge_dirs            => undef,
	organize_dists        => 0,
	parallel_jobs         => 1,
	pause_id              => 'MYCPAN',
	pause_full_name       => "MyCPAN user <CENSORED>",
	prefer_bin            => 0,
	queue_class           => 'MyCPAN::Indexer::Queue',
	report_dir            => $report_dir,
	reporter_class        => 'MyCPAN::Indexer::Reporter::AsYAML',
	retry_errors          => 1,
	success_report_subdir => catfile( $report_dir, 'success' ),
	system_id             => 'an unnamed system',
	worker_class          => 'MyCPAN::Indexer::Worker',
	perl                  => remember_perl( $^X ),
	);

=over 4

=item remember_perl

We need to remember the C<perl> that started our program. We want to use the
same binary to fire off other processes. WE have to do this very early because
we are going to discard most of the environment. After we do that, we can't
search the PATH to find the C<perl> binary.

=cut

sub remember_perl {
	require File::Which;

	my $perl = do {
		   if( file_name_is_absolute( $^X )      )  { $^X }
		elsif( my $f = File::Which::which( $^X ) )  { $f  }
		elsif( my $g = rel2abs( $^X )            )  { $g  }
		else                                        { undef }
		};

=pod

# All of this takes place before we have an object. :(

	my $sub = sub {
		my $perl = $self->get_config->perl;

		   if( not defined $perl ) {
			$logger->warn( "I couldn't find a perl! This may cause problems later." );
			}
		elsif( -x $perl ) {
			$logger->debug( "$perl is executable" );
			}
		else {
			$logger->warn( "$perl is not executable. This may cause problems later." );
			}
		};

	$self->push_onto_note( 'pre_logging_items', $sub );

=cut

	return $perl;
	}

=item default_keys

Return a list of the default keys.

=cut

sub default_keys { keys %Defaults }

=item default( KEY )

Return the default value for KEY.

=cut

sub default { $Defaults{$_[1]} }


=item config_class

Return the name of the configuration class to use. The default is
C<ConfigReader::Simple>. Any configuration class should respond to
the same interface.

=cut

sub config_class { 'ConfigReader::Simple' }

=item init_config

Load the configuration class, create the new object, and set the defaults.

=cut

sub init_config {
	my( $self, $file ) = @_;

	eval "require " . $self->config_class . "; 1";

	my $config = $self->config_class->new( defined $file ? $file : () );

	foreach my $key ( $self->default_keys ) {
		next if $config->exists( $key );
		$config->set( $key, $self->default( $key ) );
		}

	$config;
	}
}

=item adjust_config

After we setup everything, adjust the config for things that we discovered.
Set some defaults.

=cut

sub adjust_config {
	my( $application ) = @_;

	my $coordinator = $application->get_coordinator;
	my $config      = $coordinator->get_config;

	my( $backpan_dir, @merge_dirs ) = @{ $application->{args} };

	$config->set( 'backpan_dir', $backpan_dir ) if defined $backpan_dir;
	$config->set( 'merge_dirs', join "\x00", @merge_dirs ) if @merge_dirs;

	# set the directories to index, either set in:
		# first argument on the command line
		# config file
		# current working directory
	unless( $config->get( 'backpan_dir' ) ) {
		$config->set( 'backpan_dir', cwd() );
		}

	# in the config file, it's all a single line
	if( $config->get( 'merge_dirs' ) ) {
		my @dirs =
			grep { length }
			split /(?<!\\) /,
				$config->get( 'merge_dirs' ) || '';

		$config->set( 'merge_dirs', join "\x00", @dirs );
		}

	if( $config->exists( 'report_dir' ) ) {
		foreach my $subdir ( qw(success error) ) {
			$config->set(
				"${subdir}_report_subdir",
				catfile( $config->get( 'report_dir' ), $subdir ),
				);
			}
		}

	# Adjust for some environment variables
	my $log4perl_file =
		$ENV{'MYCPAN_LOG4PERL_FILE'}
			||
		$coordinator->get_note( 'log4perl_file' )
			;

	# Adjust for some environment variables
	$ENV{'PREFER_BIN'} = 1 if $config->get( 'prefer_bin' );

	$config->set( 'log4perl_file', $log4perl_file ) if $log4perl_file;

	return 1;
	}

=item new

=cut

sub new {
	my( $class, @args ) = @_;

	bless { args => [ @args ] }, $class;
	}

=item get_coordinator

=item set_coordinator

Convenience methods to deal with the coordinator

=cut

sub get_coordinator { $_[0]->{coordinator}         }
sub set_coordinator { $_[0]->{coordinator} = $_[1] }

=item process_options

Handle the configuration directives from the command line and set default
values:

	-f  config_file     Default is $script.conf
	-l  log4perl_file   Default is $script.log4perl
	-c                  Print the config and exit

=cut

sub process_options {
	my( $application ) = @_;

	my $run_dir = dirname( $0 );
	( my $script  = basename( $0 ) ) =~ s/\.\w+$//;

	local @ARGV = @{ $application->{args} };
	getopts( 'cl:f:', \ my %Options );

	# other things might want to use things from @ARGV, and
	# we just removed the bits that we wanted.
	$application->{args} = [ @ARGV ]; # XXX: yuck

	$Options{f} ||= catfile( $run_dir, "$script.conf" );

	#$Options{l} ||= catfile( $run_dir, "$script.log4perl" );

	$application->{options} = \%Options;
	}

sub get_option { $_[0]->{options}{$_[1]} }

=item setup_coordinator

Set up the coordinator object and set its initial values.

=cut

sub setup_coordinator {
	my( $application ) = @_;

	require MyCPAN::Indexer::Coordinator;
	my $coordinator = MyCPAN::Indexer::Coordinator->new;

	$coordinator->set_application( $application );
	$application->set_coordinator( $coordinator );

	$coordinator->set_note( 'UUID',          $application->get_uuid() );
	$coordinator->set_note( 'tempdirs',      [] );
	$coordinator->set_note( 'log4perl_file', $application->get_option( 'l' ) );

	$coordinator;
	}

=item handle_config

Load and set the configuration file.

You can set the configuration filename with the C<-f> option on the command
line.

You can print the configuration and exit with the C<-c> option.

=cut

sub handle_config {
	my( $application ) = @_;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Adjust config based on run parameters
	my $config = $application->init_config( $application->get_option('f') );
	$application->get_coordinator->set_config( $config );

	$application->adjust_config;

	# If this is a dry run, just print the directives and exit
	if( $application->get_option( 'c' ) ) {
		my @directives = $config->directives;
		my $longest = max( map { length } @directives );
		foreach my $directive ( sort @directives ) {
			printf "%${longest}s   %-10s\n",
				$directive,
				$config->get( $directive );
			}

		exit;
		}
	}

=item activate_steps

Returns a list of the steps to run in C<activate>.

=cut

sub activate_steps {
	qw(
	process_options
	setup_coordinator
	setup_environment
	handle_config
	setup_logging
	post_setup_logging_tasks
	adjust_config
	disable_the_missiles
	setup_dirs
	run_components
	activate_end
	);
	}

=item activate

Start the process.

=cut

sub activate {
	my( $class, @argv ) = @_;
	use vars qw( %Options $Starting_dir);
	$Starting_dir = cwd(); # remember this so we can change out of temp dirs in abnormal cleanup
	local %ENV = %ENV;

	my $application = $class->new( @argv );

	foreach my $step ( $application->activate_steps ) {
		$application->$step();
		}

	$application;
	}

=item run_components

Do the work.

=cut

sub run_components {
	my( $application ) = @_;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Load classes and check that they do the right thing
	my @components = $application->components;

	my $coordinator = $application->get_coordinator;

	my $config     = $coordinator->get_config;

	foreach my $tuple ( @components ) {
		my( $component_type, $default_class, $method ) = @$tuple;

		my $class = $config->get( "${component_type}_class" ) || $default_class;

		eval "require $class; 1" or die "$@\n";
		die "$component_type [$class] does not implement $method()"
			unless $class->can( $method );

		$logger->debug( "Calling $class->$method()" );

		my $component = $class->new;
		$component->set_coordinator( $coordinator );
		$component->$method();

		my $set_method = "set_${component_type}";
		$coordinator->$set_method( $component );
		}
	}

=item activate_end

Do stuff before we quit.

=cut

sub activate_end {
	my( $application ) = @_;

	$application->cleanup;

	$application->_exit;
	}

=item setup_environment

Delete what we don't want and set what we need.

We don't want most of the environment, just the minimal to make things not
break. We especially want to cleanse PATH. We keep these:

	DISPLAY
	USER
	HOME
	PWD
	TERM

Some of the things we need are:

	AUTOMATED_TESTING
	PERL_MM_USE_DEFAULT
	PERL_EXTUTILS_AUTOINSTALL

=cut

sub setup_environment {
	my %pass_through = map { $_, 1 } qw(
		DISPLAY USER HOME PWD TERM
		), grep { /\A(?:D|MYC)PAN_/ } keys %ENV;

	foreach my $key ( keys %ENV ) {
		delete $ENV{$key} unless exists $pass_through{$key}
		}

	# Testers conventions
	$ENV{AUTOMATED_TESTING}++;

	# Makemaker
	$ENV{PERL_MM_USE_DEFAULT}++;

	# Module::Install
	$ENV{PERL_EXTUTILS_AUTOINSTALL} = '--skipdeps';
	}

=item setup_logging

Initialize C<Log4perl>.

In the configuration, you can set

	log4perl_file
	log_file_watch_time

You can also use the environment to set the values:

	MYCPAN_LOG4PERL_FILE
	MYCPAN_LOGLEVEL (defaults to ERROR)

The environment takes precedence.

=cut

sub setup_logging {
	my( $self ) = @_;

	my $config   = $self->get_coordinator->get_config;

	my $log_config = do {
		no warnings 'uninitialized';
		if( -e $ENV{MYCPAN_LOG4PERL_FILE} ) {
			$ENV{MYCPAN_LOG4PERL_FILE};
			}
		elsif( -e $config->get( 'log4perl_file' ) ) {
			$config->get( 'log4perl_file' );
			}
		};

	if( defined $log_config ) {
		Log::Log4perl->init_and_watch(
			$log_config,
			$self->get_coordinator->get_config->get( 'log_file_watch_time' )
			);
		}
	else {
		my %hash = (
			DEBUG => $Log::Log4perl::DEBUG,
			ERROR => $Log::Log4perl::ERROR,
			WARN  => $Log::Log4perl::WARN,
			FATAL => $Log::Log4perl::FATAL,
			);

		my $level = defined $ENV{MYCPAN_LOGLEVEL} ?
			$ENV{MYCPAN_LOGLEVEL} : 'ERROR';

		Log::Log4perl->easy_init( $hash{$level} );
		}

	$logger = Log::Log4perl->get_logger( 'backpan_indexer' );
	}

=item post_setup_logging_tasks

Logging has to happen after we read the config, but there are some
things I'd like to check and log, so I must wait to log. Anyone who
wants to log something before logging has been set up should push a
sub reference onto the C<pre_logging_items> note.

=cut

sub post_setup_logging_tasks {
	my $application = shift;

	# this stuff happened too early to set a pre_logging_items
	$application->_log_perl;

	my $coordinator = $application->get_coordinator;

	my @items = $coordinator->get_note( 'pre_logging_items' );

	foreach my $item ( @items ) {
		next unless ref $item eq ref sub {};
		$item->();
		}

	1;
	}

sub _log_perl {
	my( $application ) = @_;

	my $coordinator = $application->get_coordinator;
	my $config      = $coordinator->get_config;

	my $perl = $config->perl;

	   if( not defined $perl ) {
		$logger->warn( "I couldn't find a perl! This may cause problems later." );
		}
	elsif( -x $perl ) {
		$logger->debug( "$perl is executable" );
		}
	else {
		$logger->warn( "$perl is not executable. This may cause problems later." );
		}
	}

=item disable_the_missiles

Catch INT signals and set up error handlers to direct things toward Log4perl.
Some of this stuff is a bit dangerous, maybe.

=cut

sub disable_the_missiles {
	my( $self ) = @_;

	$self->install_int_handler;
	$self->install_warn_handler;
	}

=item install_int_handler

Catch INT signals so we can log it, clean up, and exit nicely.

=cut

sub install_int_handler {
	#$SIG{__DIE__} = \&Carp::confess;

	# If we catch an INT we're probably in one of the temporary directories
	# and have some files open. To clean up the temp dirs, we have to move
	# above them, so change back to the original directory.
	$SIG{INT} = sub {
		$logger->error("Caught SIGINT in $$" );
		chdir $Starting_dir;
		exit()
		};
	}

=item install_warn_handler

Make C<warn> go to C<Log4perl>.

=cut

sub install_warn_handler {
	$SIG{__WARN__} = sub {
		$logger->warn( @_ );
		};
	}

=item components

An array of arrays that list the components to load and the method each
component needs to implement. You can override the implementing class through
the configuration.

=cut

sub components {
	(
	[ qw( reporter   MyCPAN::Indexer::Reporter::AsYAML     get_reporter   ) ],
	[ qw( queue      MyCPAN::Indexer::Queue                get_queue      ) ],
	[ qw( dispatcher MyCPAN::Indexer::Dispatcher::Parallel get_dispatcher ) ],
	[ qw( indexer    MyCPAN::Indexer                       get_indexer    ) ],
	[ qw( worker     MyCPAN::Indexer::Worker               get_task       ) ],
	[ qw( collator   MyCPAN::Indexer::Collator::Null       get_collator   ) ],
	[ qw( interface  MyCPAN::Indexer::Interface::Curses    do_interface   ) ],
	)
	}

=item cleanup

Clean up on the way out. We're already done with the run.

=cut

sub cleanup {
	my( $self ) = @_;

	require File::Path;

	my @dirs =
		@{ $self->get_coordinator->get_note('tempdirs') },
		$self->get_coordinator->get_config->temp_dir;
	$logger->debug( "Dirs to remove are @dirs" );

	eval {
		no warnings;
		File::Path::rmtree [@dirs];
		};

	$logger->error( "Couldn't cleanup: $@" ) if $@;
	}

# I don't remember why I made an explicit exit. Was it to get
# out of a Tk app or something?
sub _exit {
	my( $self ) = @_;

	$logger->info( "Exiting from ", __PACKAGE__ );

	exit 0;
	}

=item setup_dirs

Setup the temporary directories, report directories, and so on, etc.

=cut

sub setup_dirs { # XXX big ugly mess to clean up
	my( $self ) = @_;

	my $config = $self->get_coordinator->get_config;

# Okay, I've gone back and forth on this a couple of times. There is
# no default for temp_dir. I create it here so it's only set when I
# need it. It either comes from the user or on-demand creation. I then
# set it's value in the configuration.

	my $temp_dir = $config->temp_dir || tempdir( DIR => cwd(), CLEANUP => 1 );
	$logger->debug( "temp_dir is [$temp_dir] [" . $config->temp_dir . "]" );
	$config->set( 'temp_dir', $temp_dir );


	my $tempdirs = $self->get_coordinator->get_note( 'tempdirs' );
	push @$tempdirs, $temp_dir;
	$self->get_coordinator->set_note( 'tempdirs', $tempdirs );

	mkpath( $temp_dir ) unless -d $temp_dir;
	$logger->logdie( "temp_dir [$temp_dir] does not exist!" ) unless -d $temp_dir;

	foreach my $key ( qw(report_dir success_report_subdir error_report_subdir) ) {
		my $dir = $config->get( $key );

		mkpath( $dir ) unless -d $dir;
		$logger->logdie( "$key [$dir] does not exist!" ) unless -d $dir;
		}

	if( $config->retry_errors ) {
		$logger->warn( 'retry_errors no longer deletes error reports, but the worker should skip them if the setting is false' );
		}
	}

=item get_uuid

Generate a unique identifier for this indexer run.

=cut

sub get_uuid {
	require Data::UUID;
	my $ug = Data::UUID->new;
	my $uuid = $ug->create;
	$ug->to_string( $uuid );
	}

=back

=head1 TO DO

=over 4

=item Count the lines in the files

=item Code stats? Lines of code, lines of pod, lines of comments

=back

=head1 SOURCE AVAILABILITY

This code is in Github:

	git://github.com/briandfoy/mycpan-indexer.git

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2008-2018, brian d foy <bdfoy@cpan.org>. All rights reserved.

You may redistribute this under the terms of the Artistic License 2.0.

=cut

1;
