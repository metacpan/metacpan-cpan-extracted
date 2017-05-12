package Perl::Dist::WiX::Toolchain;

=pod

=head1 NAME

Perl::Dist::WiX::Toolchain - Compiles the initial toolchain for a Win32 perl distribution.

=head1 VERSION

This document describes Perl::Dist::WiX::Toolchain version 1.500001.

=head1 SYNOPSIS

  my $toolchain = Perl::Dist::WiX::Toolchain->new(
    perl_version => '5.012000',       # This is as could be returned from $].
	cpan         => URI::file('C:\\minicpan\'),
	bits         => 32,
  );
  
  $toolchain->delegate() or die $toolchain->get_error();
  
  my @dists;
  if (0 < $toolchain->dist_count()) {
	@dists = $toolchain->get_dists();
  }
  
  ...
  

=head1 DESCRIPTION

This module starts up a copy of the running perl (NOT the perl being built)
in order to determine what modules are in the "initial toolchain" and need
to be upgraded or installed immediately.

The "initial toolchain" is the modules that are required for L<CPAN|CPAN>, 
L<Module::Build|Module::Build>, L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>,
and L<CPANPLUS|CPANPLUS> (for 5.10.x+ versions of Perl) to be able to
install additional modules.

It does not include L<DBD::SQLite|DBD::SQLite> or the modules that are 
required in order for C<CPAN> or C<CPANPLUS> to use it.

It is a subclass of L<Process::Delegatable|Process::Delegatable> and of
L<Process|Process>.

=cut



use 5.010;
use Moose 0.90;
use MooseX::NonMoose;
use MooseX::Types::Moose qw( Str Int Bool HashRef ArrayRef Maybe );
use MooseX::Types::URI qw( Uri );
use Moose::Util::TypeConstraints;
use English qw( -no_match_vars );
use Carp qw();
use Params::Util qw( _HASH );
use Module::CoreList 2.49 qw();
use IO::Capture::Stdout qw();
use IO::Capture::Stderr qw();
use vars qw(@DELEGATE);
use namespace::clean -except => 'meta';

our $VERSION = '1.500001';
$VERSION =~ s/_//ms;

extends qw(
  Process::Delegatable
  Process
);



=head1 METHODS

=head2 new

This method creates a Perl::Dist::WiX::Toolchain object.

See L<Process/new|Process-E<gt>new> for more information.

The possible parameters that this class defines are as follows:

=cut



# This is called by Moose::Object->new(), and just checks that we passed
# in a version of Perl that we know how to handle.
sub BUILD {
	my $self  = shift;
	my $class = ref $self;

	if ( not $self->_modules_exists( $self->_get_perl_version() ) ) {
		Carp::croak( q{Perl version '}
			  . $self->_get_perl_version()
			  . "' is not supported in $class" );
	}
	if ( not $self->_corelist_version_exists( $self->_get_perl_version() ) )
	{
		Carp::croak( q{Perl version '}
			  . $self->_get_perl_version()
			  . "' is not supported in $class" );
	}

} ## end sub BUILD





=head3 perl_version

This required parameter defines the version of Perl that we are generating 
the toolchain for.

This is a string containing a number that is a version of perl in the format
of $] ('5.010001' or '5.012000', for example).

=cut



has perl_version => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_perl_version',
	required => 1,
);




has force => (
	traits  => ['Hash'],
	is      => 'ro',
	isa     => HashRef,
	default => sub { return {} },
	handles => {
		'_force_exists'    => 'exists',
		'_get_forced_dist' => 'get',
	},
);



=head3 cpan

This required parameter defines the CPAN mirror that we are querying. 

It has to be a URL in the form of a string.

=cut

has cpan => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_cpan',
	required => 1,
);



=head3 bits

This required parameter defines the 'bitness' of the Perl that we are 
generating the toolchain for. 

Valid values are 32 or 64.

=cut

has bits => (
	is  => 'ro',                       # Integer 32/64
	isa => subtype(
		'Int' => where {
			$_ == 32 or $_ == 64;
		},
		message {
			'Must be a 32 or 64-bit perl';
		},
	),
	required => 1,
);


# These attributes are undocumented, and are private to the class.
# They may contain public accessors, and those will be documented.
has _modules => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => HashRef [ ArrayRef [Str] ],
	builder  => '_build_modules',
	lazy     => 1,
	init_arg => undef,
	handles  => {
		'_modules_exists' => 'exists',
		'_get_modules'    => 'get',
	},
);

sub _build_modules {
	my $self = shift;

	my @modules_list = ( qw {
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
		  IPC::Run3
		  Probe::Perl
		  Test::Script
		  File::Which
		  File::HomeDir
		  Archive::Zip
		  Package::Constants
		  IO::String
		  Archive::Tar}
	);

	if ( 32 == $self->bits() ) {
		push @modules_list, 'Compress::unLZMA';
	}

	push @modules_list, qw{
	  Win32::UTCFileTime
	  CPAN::Meta::YAML
	  JSON::PP
	  Parse::CPAN::Meta
	  YAML
	  Net::FTP
	  Digest::MD5
	  Digest::SHA1
	  Digest::SHA
	  Module::Metadata
	  Perl::OSType
	  Version::Requirements
	  CPAN::Meta
	  Module::Build
	  Term::Cap
	  CPAN
	  Term::ReadKey
	  Term::ReadLine::Perl
	  Text::Glob
	  Data::Dumper
	  Pod::Text
	  URI
	  HTML::Tagset
	  HTML::Parser
	  LWP
	};

=for cmt
list LWP dependencies for a new version
Old version should be used because support of https in new version depeds on Net::SSLeay
which does not work on 64-bit Perl (https://rt.cpan.org/Public/Bug/Display.html?id=53585)
	 qw{
	  Encode::Locale
	  File::Listing
	  HTTP::Date
	  URI
	  HTML::Tagset
	  HTML::Parser
	  LWP::MediaTypes
	  HTTP::Message
	  HTTP::Cookies
	  HTTP::Negotiate
	  Net::HTTP
	  WWW::RobotRules
	  LWP::UserAgent
	};
=cut

	my %modules = ( '5.010000' => \@modules_list, );
	$modules{'5.010001'} = $modules{'5.010000'};
	$modules{'5.012000'} = $modules{'5.010000'};
	$modules{'5.012001'} = $modules{'5.010000'};
	$modules{'5.012002'} = $modules{'5.010000'};
	$modules{'5.012003'} = $modules{'5.010000'};
	$modules{'5.014000'} = $modules{'5.010000'};

	return \%modules;
} ## end sub _build_modules



has _corelist_version => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => HashRef [Str],
	builder  => '_build_corelist_version',
	init_arg => undef,
	lazy     => 1,
	handles  => {
		'_corelist_version_exists' => 'exists',
		'_get_corelist_version'    => 'get',
	},
);



sub _build_corelist_version {

	my %corelist = (
		'5.010000' => '5.010000',
		'5.010001' => '5.010001',
		'5.012000' => '5.012000',
		'5.012001' => '5.012001',
		'5.012002' => '5.012002',
		'5.012003' => '5.012003',
		'5.014000' => '5.014000',
	);

	return \%corelist;
} ## end sub _build_corelist_version



has _corelist => (
	traits   => ['Hash'],
	is       => 'bare',
	isa      => HashRef,
	builder  => '_build_corelist',
	init_arg => undef,
	lazy     => 1,
	handles  => {
		'_corelist_exists' => 'exists',
		'_get_corelist'    => 'get',
	},
);



sub _build_corelist {
	my $self = shift;

	# Confirm we can find the corelist for the Perl version
	my $corelist_version =
	  $self->_get_corelist_version( $self->_get_perl_version() );
	my $corelist = $Module::CoreList::version{$corelist_version}
	  || $Module::CoreList::version{ $corelist_version + 0 };

	if ( not _HASH($corelist) ) {
		Carp::croak( 'Failed to find module core versions for Perl '
			  . $self->_get_perl_version() );
	}

	return $corelist;
} ## end sub _build_corelist



=head2 get_dists

  my @distribution_tarballs = $toolchain->get_dists();

Gets the distributions that need updated, as a list of 
C<'PAUSEID/Foo-1.23.tar.gz'> strings.

This routine will only return valid values once C<delegate> has returned.

=head2 dist_count

  my $distribution_count = $toolchain->dist_count();

Gets a count of the number of distributions that need updated.

This routine will only return valid values once C<delegate> has returned.

=cut



has _dists => (
	traits   => ['Array'],
	is       => 'bare',
	isa      => ArrayRef [Str],
	default  => sub { return [] },
	init_arg => undef,
	handles  => {
		'_push_dists'  => 'push',
		'get_dists'    => 'elements',
		'_grep_dists'  => 'grep',
		'_empty_dists' => 'clear',
		'dist_count'   => 'count',
	},
);



has _delegated => (
	traits   => ['Bool'],
	is       => 'ro',
	isa      => Bool,
	init_arg => undef,
	default  => 0,
	handles  => { '_delegate' => 'set', },
);



=head2 get_error

  $toolchain->get_error();

Retrieves any errors that are returned by 
L<Process::Delegatable|Process::Delegatable>.

=cut

# Process::Delegatable sets this, this attribute just
# defines how to get at it.
has errstr => (
	is       => 'bare',
	isa      => Maybe [Str],
	init_arg => undef,
	default  => undef,
	reader   => 'get_error',
);


BEGIN {
	@DELEGATE = ();

	# Automatically handle delegation within the test suite
	if ( $ENV{HARNESS_ACTIVE} ) {
		require Probe::Perl;
		@DELEGATE = ( Probe::Perl->find_perl_interpreter(), '-Mblib', );
	}
}



=head2 delegate

  $toolchain->delegate() or die $toolchain->get_error();

Passes the responsibility for the generation of the initial toolchain to 
another perl process.

See L<Process::Delegatable/delegate|Process::Delegatable-E<gt>delegate>
for more information. 

=cut



sub delegate {
	my $self = shift;
	if ( not $self->_delegated() ) {
		$self->SUPER::delegate(@DELEGATE);
		$self->_delegate();
	}
	return 1;
}



=head2 prepare

Loads the latest CPAN index, in preparation for the C<run> method.

This is not meant to be called by the user, but is called by the C<delegate> method.

=cut



sub prepare {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new();
	my $stderr = IO::Capture::Stderr->new();
	$stdout->start();
	$stderr->start();

	# Load the CPAN client
	require CPAN;
	CPAN->import();

	# Load the latest index
	if (
		eval {
			local $SIG{__WARN__} = sub {1};
			if ( not $CPAN::Config_loaded++ ) {
				CPAN::HandleConfig->load();
			}
			$CPAN::Config->{'urllist'}    = [ $self->_get_cpan() ];
			$CPAN::Config->{'use_sqlite'} = q[0];
			CPAN::Index->reload();
			1;
		} )
	{
		$stdout->stop();
		$stderr->stop();
		return 1;
	} else {
		$stdout->stop();
		$stderr->stop();
		return 0;
	}
} ## end sub prepare



=head2 run

Queries the CPAN index for what versions of the initial toolchain modules are 
available,

This is not meant to be called by the user, but is called by the C<delegate> method.

=cut



sub run {
	my $self = shift;

	# Squash all output that CPAN might spew during this process
	my $stdout = IO::Capture::Stdout->new();
	my $stderr = IO::Capture::Stderr->new();
	$stdout->start();
	$stderr->start();

	if ( not $CPAN::Config_loaded++ ) {
		CPAN::HandleConfig->load();
	}
	$CPAN::Config->{'urllist'}    = [ $self->_get_cpan() ];
	$CPAN::Config->{'use_sqlite'} = q[0];
	$stdout->stop();
	$stderr->stop();

	foreach
	  my $name ( @{ $self->_get_modules( $self->_get_perl_version() ) } )
	{

		# Shortcut if forced
		if ( $self->_force_exists($name) ) {
			$self->_push_dists( $self->_get_forced_dist($name) );
			next;
		}

		# Get the CPAN object for the module, covering any output.
		$stdout->start();
		$stderr->start();
		my $module = CPAN::Shell->expand( 'Module', $name );
		$stdout->stop();
		$stderr->stop();

		if ( not $module ) {
			## no critic (RequireCarping RequireUseOfExceptions)
			die "Failed to find '$name'";
		}

		# Ignore modules that don't need to be updated
		my $core_version = $self->_get_corelist($name);
		if ( defined $core_version and $core_version =~ /_/ms ) {

			# Sometimes, the core contains a developer
			# version. For the purposes of this comparison
			# it should be safe to "round down".
			$core_version =~ s{_.+}{}ms;
		}
		my $cpan_version = $module->cpan_version;
		if ( not defined $cpan_version ) {
			next;
		}
		if ( defined $core_version and $core_version >= $cpan_version ) {
			next;
		}

		# Filter out already seen dists
		my $file = $module->cpan_file;
		$file =~ s{\A [[:upper:]] / [[:upper:]][[:upper:]] /}{}msx;
		$self->_push_dists($file);
	} ## end foreach my $name ( @{ $self...})

	# Remove duplicates
	my %seen = ();
	my @dists = $self->_grep_dists( sub { !$seen{$_}++ } );

	$self->_empty_dists();
	$self->_push_dists(@dists);

	return 1;
} ## end sub run

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>

For other issues, contact the author.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, L<Module::CoreList|Module::CoreList>, 
L<Process|Process>, L<Process::Delegatable|Process::Delegatable>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
