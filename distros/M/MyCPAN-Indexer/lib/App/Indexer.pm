package MyCPAN::App::BackPAN::Indexer;

use strict;
use warnings;
no warnings 'uninitialized';

use vars qw($VERSION);

use Carp;
use Cwd qw(cwd);
use File::Basename;
use File::Path qw(mkpath);
use File::Spec::Functions qw(catfile);
use File::Temp qw(tempdir);
use Getopt::Std;
use Log::Log4perl;

$VERSION = '1.28';

$|++;

my $logger = Log::Log4perl->get_logger( 'backpan_indexer' );

#$SIG{__DIE__} = \&Carp::confess;

$SIG{INT} = sub { exit() };

__PACKAGE__->activate( @ARGV ) unless caller;

BEGIN {
my $cwd = cwd();

my $report_dir = catfile( $cwd, 'indexer_reports' );

my %Defaults = (
	alarm                 => 15,
	copy_bad_dists        => 0,
	dispatcher_class      => 'MyCPAN::Indexer::Dispatcher::Parallel',
	error_report_subdir   => catfile( $report_dir, 'errors'  ),
	indexer_class         => 'MyCPAN::Indexer',
	indexer_id            => 'Joe Example <joe@example.com>',
	interface_class       => 'MyCPAN::Indexer::Interface::Text',
	log_file_watch_time   => 30,
	organize_dists        => 0,
	parallel_jobs         => 1,
	pause_id              => 'MYCPAN',
	queue_class           => 'MyCPAN::Indexer::Queue',
	report_dir            => $report_dir,
	reporter_class        => 'MyCPAN::Indexer::Reporter::AsYAML',
	retry_errors          => 1,
	success_report_subdir => catfile( $report_dir, 'success' ),
	system_id             => 'an unnamed system',
	worker_class          => 'MyCPAN::Indexer::Worker',
	);

sub default_keys { keys %Defaults }

sub default { $Defaults{$_[1]} }

sub config_class { 'ConfigReader::Simple' }

sub init_config
	{
	my( $self, $file ) = @_;

	eval "require " . $self->config_class . "; 1";

	my $config = $self->config_class->new( defined $file ? $file : () );

	foreach my $key ( $self->default_keys )
		{
		next if $config->exists( $key );
		$config->set( $key, $self->default( $key ) );
		}

	$config;
	}
}

sub adjust_config
	{
	my( $application ) = @_;

	my $coordinator = $application->get_coordinator;
	my $config      = $coordinator->get_config;
	
	my @argv = $application->{args};
	
	# set the directories to index
	unless( $config->exists( 'backpan_dir') )
		{
		# At the moment, you can only set string values, so we have to
		# cheat a bit. This should really come in as a ConfigReader
		# subclass
		$config->set( 'backpan_dir', @argv ? join( ' ', @argv ) : cwd() );
		}

	if( $config->exists( 'report_dir' ) )
		{
		foreach my $subdir ( qw(success error) )
			{
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
	
	$config->set( 'log4perl_file', $log4perl_file ) if $log4perl_file;
	}

sub new 
	{ 
	my( $class, @args ) = @_;
	
	bless { args => [ @args ] }, $class;
	}

sub get_coordinator { $_[0]->{coordinator}         }
sub set_coordinator { $_[0]->{coordinator} = $_[1] }

sub process_options
	{
	my( $application ) = @_;
		
	my $run_dir = dirname( $0 );
	( my $script  = basename( $0 ) ) =~ s/\.\w+$//;

	local @ARGV = @{ $application->{args} };
	getopts( 'cl:f:', \ my %Options );
	
	# other things might want to use things from @ARGV, and
	# we just removed the bits that we wanted.
	$application->{args} = [ @ARGV ]; # XXX: yuck

	$Options{f} ||= catfile( $run_dir, "$script.conf" );
	$Options{l} ||= catfile( $run_dir, "$script.log4perl" );
	
	$application->{options} = \%Options;
	}
	
sub get_option { $_[0]->{options}{$_[1]} }

sub setup_coordinator
	{
	my( $application ) = @_;
	
	require MyCPAN::Indexer::Coordinator;
	my $coordinator = MyCPAN::Indexer::Coordinator->new;
	
	$coordinator->set_application( $application );
	$application->set_coordinator( $coordinator );
	
	$coordinator->set_note( 'UUID',     $application->get_uuid() );
	$coordinator->set_note( 'tempdirs', [] );
	$coordinator->set_note( 'log4perl_file', $application->get_option( 'l' ) );
	
	$coordinator;
	}
	
sub handle_config
	{
	my( $application ) = @_;

	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Adjust config based on run parameters
	my $config = $application->init_config( $application->get_option('f') );
	$application->get_coordinator->set_config( $config );
	
	$application->adjust_config;

	if( $application->get_option('c') )
		{
		use Data::Dumper;
		print STDERR Dumper( $config );
		exit;
		}
	}

sub activate_steps
	{
	qw(
	process_options 
	setup_coordinator 
	setup_environment 
	handle_config
	setup_logging 
	setup_dirs 
	run_components 
	activate_end
	);
	}
	
sub activate
	{
	my( $class, @argv ) = @_;
	use vars qw( %Options );
	local %ENV = %ENV;

	my $application = $class->new( @argv );
	
	foreach my $step ( $application->activate_steps )
		{
		$application->$step();
		}
		
	$application;
	}

sub run_components
	{
	my( $application ) = @_;
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
	# Load classes and check that they do the right thing
	my @components = $application->components;

	my $coordinator = $application->get_coordinator;

	my $config     = $coordinator->get_config;
		
	foreach my $tuple ( @components )
		{
		my( $directive, $default_class, $method ) = @$tuple;

		my $class = $config->get( "${directive}_class" ) || $default_class;

		eval "require $class; 1" or die "$@\n";
		die "$directive [$class] does not implement $method()"
			unless $class->can( $method );

		$logger->debug( "Calling $class->$method()" );
		
		my $component = $class->new;
		$component->set_coordinator( $coordinator );
		$component->$method();
		
		my $set_method = "set_$directive";
		$coordinator->$set_method( $component );
		}
	}

sub activate_end
	{
	my( $application ) = @_;
	
	$application->cleanup;

	$application->_exit;
	}
	
sub setup_environment
	{
	my %pass_through = map { $_, 1 } qw( 
		DISPLAY USER HOME PWD TERM 
		), grep { /^(?:D|MY)CPAN_/ } keys %ENV;

	foreach my $key ( keys %ENV )
		{
		delete $ENV{$key} unless exists $pass_through{$key}
		}

	$ENV{AUTOMATED_TESTING}++;
	}

sub setup_logging
	{
	my( $self ) = @_;

	my $config   = $self->get_coordinator->get_config;
	my $log_file = $config->get( 'log4perl_file' );
	
	if( defined $log_file and -e $log_file )
		{
		Log::Log4perl->init_and_watch(
			$log_file,
			$self->get_coordinator->get_config->get( 'log_file_watch_time' )
			);
		}
	else
		{
		Log::Log4perl->easy_init( $Log::Log4perl::ERROR );
		}
	}

sub components
	{
	(
	[ qw( queue      MyCPAN::Indexer::Queue                get_queue      ) ],
	[ qw( dispatcher MyCPAN::Indexer::Dispatcher::Parallel get_dispatcher ) ],
	[ qw( reporter   MyCPAN::Indexer::Reporter::AsYAML     get_reporter   ) ],
	[ qw( worker     MyCPAN::Indexer::Worker               get_task       ) ],
	[ qw( interface  MyCPAN::Indexer::Interface::Curses    do_interface   ) ],
	[ qw( reporter   MyCPAN::Indexer::Reporter::AsYAML     final_words    ) ],
	)
	}

sub cleanup
	{
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
	print STDERR "$@\n" if $@;

	$logger->error( "Couldn't cleanup: $@" ) if $@;
	}

# I don't remember why I made an explicit exit. Was it to get
# out of a Tk app or something?
sub _exit
	{
	my( $self ) = @_;
	
	$logger->info( "Exiting from ", __PACKAGE__ );
		
	exit 0;
	}

sub setup_dirs # XXX big ugly mess to clean up
	{
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

	foreach my $key ( qw(report_dir success_report_subdir error_report_subdir) )
		{
		my $dir = $config->get( $key );

		mkpath( $dir ) unless -d $dir;
		$logger->logdie( "$key [$dir] does not exist!" ) unless -d $dir;
		}

	if( $config->retry_errors )
		{
		my $glob = catfile( $config->get( 'error_report_subdir' ), "*.yml" );
		$glob =~ s/( +)/(\\$1)/g;

		unlink glob( $glob );
		}
	}

sub get_uuid
	{
	require Data::UUID;
	my $ug = Data::UUID->new;
	my $uuid = $ug->create;
	$ug->to_string( $uuid );
	}

1;
