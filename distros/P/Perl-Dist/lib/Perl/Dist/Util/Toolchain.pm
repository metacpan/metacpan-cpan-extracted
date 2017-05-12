package Perl::Dist::Util::Toolchain;

use 5.005;
use strict;
use Carp                 ();
use Params::Util         qw{ _HASH _ARRAY };
use Module::CoreList     ();
use IO::Capture::Stdout  ();
use IO::Capture::Stderr  ();
use Process::Delegatable ();
use Process::Storable    ();
use Process              ();

use vars qw{$VERSION @ISA @DELEGATE};
BEGIN {
	$VERSION  = '1.16';
	@ISA      = qw{
		Process::Delegatable
		Process::Storable
		Process
	};
	@DELEGATE = ();

	# Automatically handle delegation within the test suite
	if ( $ENV{HARNESS_ACTIVE} ) {
		require Probe::Perl;
		@DELEGATE = (
			Probe::Perl->find_perl_interpreter, '-Mblib',
		);
	}
}

my %MODULES = (
	'5.008008' => [ qw{
		ExtUtils::MakeMaker
		File::Path
		ExtUtils::Command
		Win32API::File
		ExtUtils::Install
		ExtUtils::Manifest
		Test::Harness
		Test::Simple
		ExtUtils::CBuilder
		ExtUtils::ParseXS
		version
		Scalar::Util
		Compress::Raw::Zlib
		Compress::Raw::Bzip2
		IO::Compress::Base
		Compress::Bzip2
		IO::Zlib
		File::Spec
		File::Temp
		Win32::WinError
		Win32API::Registry
		Win32::TieRegistry
		File::HomeDir
		File::Which
		Archive::Zip
		Package::Constants
		IO::String
		Archive::Tar
		Compress::unLZMA
		Parse::CPAN::Meta
		YAML
		Net::FTP
		Digest::MD5
		Digest::SHA1
		Digest::SHA
		Module::Build
		Term::Cap
		CPAN
		Term::ReadKey
		Term::ReadLine::Perl
		Text::Glob
		Data::Dumper
		URI
		HTML::Tagset
		HTML::Parser
		LWP::UserAgent
	} ],
);
$MODULES{'5.010000'} = $MODULES{'5.008008'};
$MODULES{'5.008009'} = $MODULES{'5.008008'};

my %CORELIST = (
	'5.008008' => '5.008008',
	'5.008009' => '5.008008',
	'5.010000' => '5.010000',
);





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check the Perl version
	unless ( defined $self->perl_version ) {
		Carp::croak("Did not provide a perl_version param");
	}
	unless ( defined $self->{cpan} ) {
		Carp::croak("Did not provide a cpan param");
	}
	unless ( $MODULES{$self->perl_version} ) {
		Carp::croak("Perl version '" . $self->perl_version . "' is not supported in $class");
	}
	unless ( $CORELIST{$self->perl_version} ) {
		Carp::croak("Perl version '" . $self->perl_version . "' is not supported in $class");
	}

	# Populate the modules array if needed
	unless ( _ARRAY($self->{modules}) ) {
		$self->{modules}  = $MODULES{$self->perl_version};
	}

	# Confirm we can find the corelist for the Perl version
	my $corelist_version = $CORELIST{$self->perl_version};
	$self->{corelist} = $Module::CoreList::version{$corelist_version}
	                 || $Module::CoreList::version{$corelist_version+0};
	unless ( _HASH($self->{corelist}) ) {
		Carp::croak("Failed to find module core versions for Perl " . $self->perl_version);
	}

	# Check forced dists, if applicable
	if ( $self->{force} and ! _HASH($self->{force}) ) {
		Carp::croak("The force param must be a HASH reference");
	}

	# Create the distribution array
	$self->{dists} = [];

	return $self;
}

sub perl_version {
	$_[0]->{perl_version};
}

sub modules {
	@{$_[0]->{modules}};
}

sub dists {
	@{$_[0]->{dists}};
}

sub errstr {
	$_[0]->{errstr};
}

sub prepare {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;
	$stdout->start;
	$stderr->start;

	# Load the CPAN client
	require CPAN;
	CPAN->import();

	# Load the latest index
	eval {
		local $SIG{__WARN__} = sub { 1 };
		CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
		$CPAN::Config->{'urllist'} = [ $self->{cpan} ];
		$CPAN::Config->{'use_sqlite'} = q[0];
		CPAN::Index->reload;
	};

	$stdout->stop;
	$stderr->stop;

	return $@ ? '' : 1;
}

sub run {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new;
	my $stderr = IO::Capture::Stderr->new;
	
	# Find the module
	my $core = delete $self->{corelist};
	
	$stdout->start;		$stderr->start;
	CPAN::HandleConfig->load unless $CPAN::Config_loaded++;
	$CPAN::Config->{'urllist'} = [ $self->{cpan} ];
	$CPAN::Config->{'use_sqlite'} = q[0];
	$stdout->stop;		$stderr->stop;

	foreach my $name ( @{$self->{modules}} ) {
		# Shortcut if forced
		if ( $self->{force}->{$name} ) {
			push @{$self->{dists}}, $self->{force}->{$name};
			next;
		}

		# Get the CPAN object for the module, covering any output.
		$stdout->start;		$stderr->start;
		my $module = CPAN::Shell->expand('Module', $name);
		$stdout->stop;		$stderr->stop;
		unless ( $module ) {
			die "Failed to find '$name'";
		}

		# Ignore modules that don't need to be updated
		my $core_version = $core->{$name};
		if ( defined $core_version and $core_version =~ /_/ ) {
			# Sometimes, the core contains a developer
			# version. For the purposes of this comparison
			# it should be safe to "round down".
			$core_version =~ s/_.+$//;
		}
		my $cpan_version = $module->cpan_version;
		unless ( defined $cpan_version ) {
			next;
		}
		if ( defined $core_version and $core_version >= $cpan_version ) {
			next;
		}

		# Filter out already seen dists
		my $file = $module->cpan_file;
		$file =~ s/^[A-Z]\/[A-Z][A-Z]\///;
		push @{$self->{dists}}, $file;
	}

	# Remove duplicates
	my %seen = ();
	@{$self->{dists}} = grep { ! $seen{$_}++ } @{$self->{dists}};

	return 1;
}

sub delegate {
	my $self = shift;
	unless ( $self->{delegated} ) {
		$self->SUPER::delegate( @DELEGATE );
		$self->{delegated} = 1;
	}
	return 1;
}

sub delegated {
	$_[0]->{delegated};
}

1;

