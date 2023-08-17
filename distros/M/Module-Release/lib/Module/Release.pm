use v5.16;

package Module::Release;

=encoding utf8

=head1 NAME

Module::Release - Automate software releases

=head1 SYNOPSIS

	use Module::Release;

	my $release = Module::Release->new( %params );

	# call methods to automate your release process
	$release->check_vcs;
	...

=cut

use strict;

use warnings;
no warnings;

our $VERSION = '2.133';

use Carp qw(carp croak);
use File::Basename qw(dirname);
use File::Spec;
use Scalar::Util qw(blessed);

my %Loaded_mixins = ( );

=head1 DESCRIPTION

C<Module::Release> automates your software release process. It started as
a script that automated my release process, so it has bits to
talk to PAUSE (CPAN) and SourceForge, and to use C<Makefile.PL> and
C<CVS>. Other people have extended this in other modules under the same
namespace so you can use C<Module::Build>, C<svn>, and many other things.

The methods represent a step in the release process. Some of them check a
condition (e.g. all tests pass) and die if that doesn't work.
C<Module::Release> doesn't let you continue if something is wrong. Once
you have checked everything, use the upload features to send your files
to the right places.

The included C<release> script is a good starting place. Don't be afraid to
edit it for your own purposes.

=head2 Configuration

C<Module::Release> looks at several sources for configuration information.

=head3 Perl setup

C<Module::Release> looks at C<Config> to get the values it needs for
certain operations.

=over 4

=item make

The name of the program to run for the C<make> steps

=back

=head3 Environment variables

=over 4

=item PERL

Use this value as the perl interpreter, otherwise use the value in C<$^X>.

=item RELEASE_DEBUG

Do you want debugging output? Set this to a true value

=item CPAN_PASS

Your CPAN password. If you don't set this and you want to upload to
PAUSE, you should be prompted for it.

=back

=head3 C<.releaserc>

C<Module::Release> looks for either C<.releaserc> or C<releaserc> in
the current working directory. It reads that with
C<ConfigReader::Simple> to get these values:

=over 4

=item cpan_user

Your PAUSE user id.

=item cpan_pass

Your PAUSE password, but don't use this. Put it in the environment
variable.

=item http_proxy

=item https_proxy

=item ignore_prereqs

A whitespace separated list of modules for C<Test::Prereq> to ignore.
But, don't use C<Test::Prereq>. It was not a good idea.

=item makefile_PL

The name of the file to run as F<Makefile.PL>.  The default is
C<"Makefile.PL">, but you can set it to C<"Build.PL"> to use a
C<Module::Build>-based system.

If this is set to C<"Build.PL">, this his will also cause
C<Module::Build::Prereqs> to use C<Test::Prereqs::Build> instead of
C<Test::Prereqs>.

=item makefile

The name of the file created by C<makefile_PL> above.  The default is
C<"Makefile">, but you can set it to C<"Build"> for
C<Module::Build>-based systems.

=item module_name

C<release> tries to guess the module name from the distro name, but if
you don't like that, set the module name in the config file.

=back

=head2 Methods

If you don't like what any of these methods do, override them in a subclass.

=over 4

=item new()

Create the C<Module::Release> object. It reads the configuration
and initializes everything.

=cut

sub new {
	my( $class, %params ) = @_;

	my $self = bless {}, $class;

	my $config = $self->_read_configuration;

	$self->init( $config, %params );

	return $self;
	}


=item init()

Set up the C<Module::Release> object. By default, it expects something
using MakeMaker, but if it sees a F<Build.PL> it configures itself for
C<Module::Build>.

The values in the configuration file override any settings here, so if you
have both a F<Makefile.PL> and a F<Build.PL> then you can override the
C<Module::Build> preference by setting the C<makefile_PL> and C<make>
configuration values.

=cut

sub init {
	my( $self, $config, %params ) = @_;

	$self->_set_defaults( %params );

	# $config comes in as a parameter
	$self->_process_configuration( $config );

	# defer $self->_set_up_web_client;

	1;
	}

sub _select_config_file_name { -e ".releaserc" ? ".releaserc" : "releaserc" }

sub _set_defaults {
	require Config;
	require IO::Null;

	my( $self, %params ) = @_;

	my $defaults = {
		'Makefile.PL'  => 'Makefile.PL',
		'Makefile'     => 'Makefile',
		make           => $Config::Config{make},
		manifest       => 'MANIFEST',
		debug          => $ENV{RELEASE_DEBUG} || 0,
		local_file     => undef,
		remote_file    => undef,
		input_fh       => *STDIN{IO},
		output_fh      => *STDOUT{IO},
		debug_fh       => *STDERR{IO},
		null_fh        => IO::Null->new(),
		quiet          => 0,
		devnull        => File::Spec->devnull,
		ignore_prereqs => '',
		module_name    => undef,
		%params,
		};

	foreach my $key ( keys %$defaults ) {
		$self->{$key} = $defaults->{$key};
		}

	$self->set_perl( $^X );
	$self->add_a_perl( $^X );

	# setup for Module::Build. This is a kludge. There isn't a
	# programmatic interface to Makemaker, and I don't want to
	# treat Makemaker and Module::Build differently. I'm stuck
	# with a fancy shell script.
	if( -e 'Build.PL' ) {
		$self->{'make'}        = File::Spec->catfile(qw{. Build});
		$self->{'Makefile.PL'} = 'Build.PL';
		$self->{'Makefile'}    = '_build';
		}
	1;
	}

sub _read_configuration {
	require ConfigReader::Simple;

	# NOTE: I have to read the configuration to see if I should
	# call the subclass, but I haven't called init yet.
	# Don't set up anything in _read_configuration!
	my $self = shift;

	my $conf_file = $self->_select_config_file_name;

	# Read the configuration
	$self->_die( "Could not find conf file $conf_file\n" )
		unless -e $conf_file;
	my $config = $self->{config} = ConfigReader::Simple->new( $conf_file );
	$self->_die( "Could not get configuration data\n" ) unless ref $config;

	$config;
	}

sub _process_configuration {
	my $self = shift;

	# Figure out options
	$self->{cpan} = $self->config->cpan_user eq '<none>' ? 0 : 1;

	{
	my @pairs = (
		[ qw(Makefile.PL makefile_PL) ],
		[ qw(Makefile    makefile)    ],
		[ qw(make        make)        ],
		[ qw(module_name module_name) ],
		);

	foreach my $pair ( @pairs ) {
		my( $key, $config ) = @$pair;

		$self->{$key} = $self->config->get($config)
			if $self->config->exists($config);
		}
	}

	my @required = qw(  );

	my $ok = 1;
	for( @required ) {
		unless( length $self->config->$_() ) {
			$ok = 0;
			$self->_warn( "Missing configuration data: $_; Aborting!\n" );
			}
		}
	$self->_die( "Missing configuration data" ) unless $ok;

	if( $self->config->perls ) {
		my @paths = split /:/, $self->config->perls;

		foreach my $path ( @paths ) {
			$self->add_a_perl( $path );
			}
		}
	}

sub _handle_subclass {
	my( $self, $subclass, %params ) = @_;


	# This is a bit tricky. We have to be able to use the subclass, but
	# we don't know if it is defined or not. It might be in a .pm file
	# we haven't loaded, it might be in another file the user already
	# loaded, or the user might have defined it inline inside
	# the script. We'll try loading it if it fails can()
	unless( eval { $subclass->can( 'new' ) } ) {
		# I don't care if this fails because loading the file
		# might not be the problem
		eval { require File::Spec->catfile( split '::', $subclass ) . '.pm' };
		}

	# If it's not defined by now, we're screwed and we give up
	$self->_die( "$subclass does not have a new()!" )
		unless eval { $subclass->can( 'new' ) };

	my $new_self = eval { $subclass->new( %params ) };
	my $at = $@;

	return $new_self if blessed $new_self;

	$self->_die( "Could not create object with $subclass: $at!" );
	}


=item load_mixin( MODULE )

EXPERIMENTAL!!

Load MODULE through require (so no importing), without caring what it does.
My intent is that MODULE adds methods to the C<Module::Release> namespace
so a release object can see it. This should probably be some sort of
delegation.

Added in 1.21

=cut

sub load_mixin {
	my( $self, $module ) = @_;

	return 1 if $self->mixin_loaded( $module );

	{ local $^W = 0; eval "use $module" };

	$self->_die( "Could not load [$module]! $@" ) if $@;

	++$Loaded_mixins{ $module };
	}

=item loaded_mixins

Returns a list of the loaded mixins

Added in 1.21

=cut

sub loaded_mixins { keys %Loaded_mixins }

=item mixin_loaded( MODULE )

Returns true if the mixin class is loaded

=cut

sub mixin_loaded { exists $Loaded_mixins{ $_[1] } }

=back

=head2 Methods for configuration and settings

=over 4

=item config

Get the configuration object. By default this is a C<ConfigReader::Simple>
object;

=cut

sub config { $_[0]->{config} }

=item local_file( FILENAME )

Returns or sets the name of the local distribution file. You can use
the literal argument C<undef> to clear the value.

=cut

sub local_file {
	$_[0]->{local_file} = $_[1] if @_ > 1;

	$_[0]->{local_file};
	}

=item remote_file

Returns the name of the file on the remote side. You can use the
literal argument C<undef> to clear the value.

=cut

sub remote_file {
	$_[0]->{remote_file} = $_[1] if @_ > 1;

	$_[0]->{remote_file};
	}

=back

=head2 Methods for multiple perl testing

=over 4

=item set_perl

Set the current path for the perl binary that C<Module::Release> should
use for general tasks. This is not related to the list of perls used to
test multiple binaries unless you use one of those binaries to set a new
value.

If PATH looks like a perl binary, C<set_perl> uses it as the new setting
for perl and returns the previous value.

Added in 1.21.

=cut

sub set_perl {
	my( $self, $path ) = @_;

	# resolve a path, especially on Windows, like
	# C:\STRAWB~1\perl\bin\perl.exe
	unless( my $version = $self->_looks_like_perl( $path ) ) {
		$self->_die( "Does not look like a perl [$path]" );
		}

	my $old_perl = $self->get_perl;

	$self->{perl} = $path;

	$old_perl;
	}

sub _looks_like_perl {
	my( $self, $path ) = @_;

	# resolve a path, especially on Windows, like
	# C:\STRAWB~1\perl\bin\perl.exe
	return 1 if $path =~ /\bperl.exe\z/;

	my $version = `$path -e "print \$\]" 2>&1`;

	$version =~ m/^\d+\.[\d_]+$/ ? $version : ();
	}

=item get_perl

Returns the current path for the perl binary that C<Module::Release> should
use for general tasks. This is not related to the list of perls used to
test multiple binaries.

Added in 1.21.

=cut

sub get_perl { $_[0]->{perl} }

=item perls()

Return the list of perl binaries Module::Release will use to test the
distribution.

Added in 1.21.

=cut

sub perls {
	my $self = shift;

	my @perls = keys %{$self->{perls}};
	$self->_debug( "perls at the start [@perls]" );

	# Sort them
	@perls =
		map  { $_->[0] }
		sort { $a->[2] <=> $b->[2] || $a->[3] <=> $b->[3] || $a->[0] cmp $b->[0] }
		map  { [ $_->[0], ( $_->[1] =~ m/(perl5\.(?|([0-9]{3})_?([0-9]{2})|([0-9]{1,2})\.([0-9]+)))/) ] }
		map  { [ $_, (m{.*/(.*)}) ] }
		grep { -x $_ }
		@perls;

	$self->_debug( "perls after filtering [@perls]" );
	$self->_debug( "Testing with " . @perls . " perls" );

	return @perls;
	}

=item add_a_perl( PATH )

Add a perl binary to the list of perls to use for testing. If PATH
is not executable or cannot run C<print $]>, this method returns
nothing and does not add PATH. Otherwise, it returns true. If the
same path was already in the list, it returns true but does not
create a duplicate.

Added in 1.21.

=cut

sub add_a_perl {
	my( $self, $path ) = @_;

	return 1 if exists $self->{perls}{$path};

	unless( -x $path ) {
		if( $path =~ m/[*?[]/ && $self->config->allow_glob_in_perls ) {
			$self->add_a_perl( $_ ) for glob $path;
			}
		else {
			$self->_warn( "$path is not executable" );
			}
		return;
		}

	my $version = $self->_looks_like_perl( $path );

	unless( $version ) {
		$self->_warn( "$path does not appear to be perl!" );
		return;
		}

	return $self->{perls}{$path} = $version;
	}

=item remove_a_perl( PATH )

Delete PATH from the list of perls used for testing

Added in 1.21.

=cut

sub remove_a_perl {
	my( $self, $path ) = @_;

	return delete $self->{perls}{$path}
	}

=item reset_perls

Reset the list of perl interpreters to just the one running C<release>.

Added in 1.21.

=cut

sub reset_perls {
	my $self = shift;

	$self->{perls} = {};

	return $self->{perls}{$^X} = $];
	}


=item input_fh

Return the value of input_fh.

=cut

sub input_fh {
	return $_[0]->{input_fh};
}

=item output_fh

If quiet is off, return the value of output_fh. If output_fh is not
set, return STDOUT. If quiet is on, return the value of null_fh.

=cut

sub output_fh  {
	$_[0]->quiet
		?
	$_[0]->null_fh
		:
	( $_[0]->{output_fh} || *STDOUT{IO} )
	}

=item null_fh

Return the null filehandle. So far that's something set up in C<new> and I
haven't provided a way to set it. Any subclass can make their C<null_fh>
return whatever they like.

=cut

sub null_fh  {
	require IO::Null;
	$_[0]->{null_fh} //= IO::Null->new;
	}

=item quiet

Get the value of quiet mode (true or false).

=item turn_quiet_on

Turn on quiet mode

=item turn_quiet_off

Turn off quiet mode

=cut

sub turn_quiet_on  { $_[0]->{quiet} = 1 }
sub turn_quiet_off { $_[0]->{quiet} = 0 }

sub quiet          { $_[0]->{quiet} }

=item debug

Get the value of the debugging flag (true or false).

=item turn_debug_on

Turn on debugging

=item turn_debug_off

Turn off debugging

=item debug_fh

If debugging is on, return the value of debug_fh. If debug_fh is not
set, return STDERR. If debugging is off, return the value of null_fh.

=cut

sub turn_debug_on  { $_[0]->{debug} = 1 }
sub turn_debug_off { $_[0]->{debug} = 0 }

sub debug          { $_[0]->{debug} }

sub debug_fh  {
		if( $_[0]->debug ) {
			$_[0]->{debug_fh} || *STDERR{IO}
			}
		else {
			$_[0]->null_fh
			}
	}

=back

=head2 Methods for building

=over 4

=item clean

Run `make realclean`

=cut

sub clean {
	my $self = shift;
	$self->_print( "Cleaning directory... " );

	unless( -e $self->{Makefile} ) {
		$self->_print( " no $self->{Makefile}---skipping\n" );
		return;
		}

	$self->run( "$self->{make} realclean 2>&1" );

	$self->_print( "done\n" );
	}

=item distclean

Run `make distclean`

=cut

sub distclean {
	my $self = shift;
	$self->_print( "Cleaning directory... " );

	unless( -e $self->{Makefile} ) {
		$self->_print( " no $self->{Makefile}---skipping\n" );
		return;
		}

	$self->run( "$self->{make} distclean 2>&1" );

	$self->_print( "done\n" );
	}


=item build_makefile()

Runs `perl Makefile.PL 2>&1`.

This step ensures that we start off fresh and pick up any changes in
C<Makefile.PL>.

=cut

sub build_makefile {
	my $self = shift;
	$self->_print( "Recreating make file... " );

	unless( -e $self->{'Makefile.PL'} ) {
		$self->_print( " no $self->{'Makefile.PL'}---skipping\n" );
		return;
		}

	$self->run( "$self->{perl} $self->{'Makefile.PL'} 2>&1 0<&-" );

	$self->_print( "done\n" );
	}

=item make()

Run a plain old `make`.

=cut

sub make {
	my $self = shift;
	$self->_print( "Running make... " );

	unless( -e $self->{'Makefile'} )
		{
		$self->_print( " no $self->{'Makefile'}---skipping\n" );
		return;
		}

	my $tests = $self->run( "$self->{make} 2>&1" );

	$self->_print( "done\n" );
	}

=item test()

Run `make test`. If any tests fail, it dies.

=cut

sub test {
	my $self = shift;
	$self->_print( "Checking make test... " );

	unless( -e $self->{'Makefile'} ) {
		$self->_print( " no $self->{'Makefile'}---skipping\n" );
		return;
		}

	my $tests = $self->run( "$self->{make} test 2>&1" );

	unless ($tests =~ m/All tests successful/) {
		if( $self->debug ) { # from H.Merijn Brand
			my $prove = File::Spec->catfile(
				dirname( $self->get_perl ),
				'prove'
				);

			if( -x $prove ) {
				my $prove_out =
					join "\n\n",
					map { scalar qx"$prove -wvb $_" }
                    ($tests =~ m{^(t/\w+\.t)\s+[0-9]+}gm);
				$prove_out =~ s/^.*\r//gm;
				$self->_warn( $prove_out );
				}
			elsif( $self->debug ) {
				$self->_print( "prove [$prove] was not executable!" );
				}
			}

			$self->_die( "\nERROR: Tests failed!\n$tests\n\nAborting release\n" )
		}

	$self->_print( "all tests pass\n" );
	}

=item dist()

Run `make dist`. As a side effect determines the distribution
name if not set on the command line.

=cut

sub dist {
	my $self = shift;
	$self->_print( "Making dist...\n" );

	$self->build_makefile;

	my $messages = $self->run( "$self->{make} dist 2>&1 < $self->{devnull}" );
	$self->_debug( "messages are [$messages]\n" );

	# If the distro isn't already set, try to guess it
	unless( $self->local_file ) {
		$self->_debug( ", guessing local distribution name\n" );
		my( $guess ) = $messages =~ /(?:\s|')(\S+\.tar)/;
		$self->_debug( "guessed [$guess]\n" );
		$self->local_file( $guess );

		$self->_die( "Couldn't guess distname from dist output\n" )
			unless $self->local_file;

		$self->local_file( $self->local_file() . '.gz' );
		$self->remote_file( $self->local_file );
		}

	# local_file should exist now
	$self->_die( "Local file '$self->{local_file}' does not exist\n" )
		unless -f $self->local_file;

	$self->_print( "Done making dist\n" );
	}

=item disttest

Run `make disttest`. If the tests fail, it dies.

=cut

sub disttest {
	my $self = shift;

	$self->_print( "Checking make disttest... " );

	unless( -e $self->{'Makefile'} ) {
		$self->_print( " no $self->{'Makefile'}---skipping\n" );
		return;
		}

	my $tests = $self->run( "$self->{make} disttest 2>&1" );

	$self->_die( "\nERROR: Tests failed!\n$tests\n\nAborting release\n" )
		unless $tests =~ /All tests successful/;

	$self->_print( "all tests pass\n" );
	}

=item dist_test

This was the old name for the method, but was inconsistent with
other method names. It still works, but is deprecated and will
give a warning.

=cut

sub dist_test {
	$_[0]->_warn( "dist_test is deprecated. Use disttest instead." );

	goto &disttest;
	}

=item dist_version

Return the distribution version ( set in dist() )

=cut

sub _parse_version {
	my( $self ) = @_;
	no warnings 'uninitialized';

	$self->_die( "Can't get dist_version! It's not set (did you run dist first?)" )
		unless defined $self->remote_file;

	my( $version_str, $vee, $version, $dev ) = $self->remote_file
		=~ / ( (v?) ([\d.]+) (?: _ (\d+) )? ) (?:\. (?: tar \. gz | zip ) )? $/xi
			or return { components => [], string => '', multipart => 0 };

	my @components = split /[.]/, $version;
	my $count      = @components;

	my $multipart  = length($vee) || ($count > 2);

	my $hash = {
		components => \@components,
		count      => $count,
		string     => $version_str,
		vee        => lc $vee,
		version    => $version,
		v_version  => lc($vee) . $version,
		dev        => $dev,
		multipart  => $multipart,
		};

	$self->_debug( Dumper( $self->remote_file, $hash ) ); use Data::Dumper;

	return $hash;
	}

sub dist_version {
	my( $self ) = @_;

	my $v = $self->_parse_version;

	if( $v->{multipart} ) {
		$self->_debug( "Choosing multipart version" );
		# This is a multi-part version
		# We assume that version.pm is available if multi-part
		# versions are in use.
		eval {
			require version;
			}
		or do { # Fall back to using $version_str verbatim
			warn $@;
			return $v->{version_str};
			};

		# There are pre- and post-0.77 versions of version.pm.
		# The former are deprecated, but I assume we must
		# gracefully use what we have available.
		eval {
			my $string = $v->{v_version};
			$v->{version} = version->VERSION >= 0.77 ?
				version->parse ($string)->normal : # latest and best
				''.version->new($string)         ; # legacy
			1;
			}
		or
			$self->_die( "Couldn't parse version '$v->{string}' from '".
				$self->remote_file. "': $@");

		return $v->{version};
		}
	elsif( $v->{count} == 1 ) {
		$self->_debug( "Choosing single component version" );
		# some versions might be a single number, such as those
		# that use dates as integers with no dot.
		return $v->{components}[0];
		}
	elsif( $v->{string} =~ /(\d+) \. (\d+)(_\d+)? $/x ) {
		$self->_debug( "Choosing major.minor_dev? version" );
		# Else, use the older implementation for backward-compatibility
		# Note the lack of an initial ^ matcher is deliberate.
		my( $major, $minor, $dev ) = ( $1, $2, $3 );
		return $self->dist_version_format( $major, $minor, $dev );
		}
	else {
		$self->_debug( "Unhandled version" );
		return '';
		}
	}

=item dist_version_format

Return the distribution version ( set in dist() )

# XXX make this configurable

=cut

sub dist_version_format {
	no warnings 'uninitialized';
	my $self = shift;
	my( $major, $minor, $dev ) = @_;

	sprintf "%s.%s%s", $major, $minor, $dev;
	}

=item module_name

Returns the module name. This either takes it from the config file
or tries to guess it from the distro name.

=cut

sub module_name {
	my $self = shift;
	return $self->{module_name} if $self->{module_name};

	my $name = $self->local_file;
	$self->_debug( "Guessing name. Local file is  <$name>\n" );

	$name =~ s/-\d.*//g;
	$name =~ s/-/::/g;
	$self->_debug( "Guessing name. Module name is  <$name>\n" );

	$self->{module_name} = $name;
	}

=item check_manifest

Run `make manifest` and report anything it finds. If it gives output,
die. You should check C<MANIFEST> to ensure it has the things it needs.
If files that shouldn't show up do, put them in MANIFEST.SKIP.

Since `make manifest` takes care of things for you, you might just have
to re-run your release script.

=cut

# _check_output_lines - for command output with one message per line.
# The message hash identifies the first part of the line and serves
# as a category for the message. If a line doesn't matter, don't put
# it's pattern in the message hash.
#
# Prints a summary of what it found. The message is the hash value
# for that output type.
#
# returns the number of interesting things it found, but that's it.
sub _check_output_lines {
	my $self = shift;
	my( $message_hash, $message ) = @_;

	my %state;
	foreach my $state ( keys %$message_hash ) {
		$state{$state} = [ $message =~ /^\Q$state\E\s+(.+)/gm ];
		}

	my $rule = "-" x 50;
	my $count = 0;

	foreach my $key ( sort keys %state ) {
		my $list = $state{$key};
		next unless @$list;

		$count += @$list;

		local $" = "\n\t";
		$self->_print( "\n\t$message_hash->{$key}\n\t$rule\n\t@$list\n" );
		}

	return $count;
	}

sub check_manifest {
	my $self = shift;

	$self->_print( "Checking state of MANIFEST... " );

	my $manifest = $self->run( "$self->{make} manifest 2>&1" );

	my %message    = (
		"Removed from MANIFEST:"  => 'These files were removed from MANIFEST',
		"Added to MANIFEST:"      => 'These files were added to MANIFEST',
		);

	my $count = $self->_check_output_lines( \%message, $manifest );

	$self->_die( "\nERROR: Manifest was not up-to-date ($count files).\n" )
		if $count;

	$self->_print( "MANIFEST up-to-date\n" );
	}

=item manifest_name

Return the name of the manifest file, probably F<MANIFEST>.

=item manifest

This is the old name for manifest_name. It still works but is
deprecated.

=cut

sub manifest_name { 'MANIFEST' }

sub manifest {
	$_[0]->_warn( "manifest is deprecated. Use manifest_name" );
	&manifest_name
	}

=item files_in_manifest

Return the filenames in the manifest file as a list.

=cut

sub files_in_manifest {
	my $self = shift;

	require ExtUtils::Manifest;

	# I want to use ExtUtils::Manifest so it automatically
	# follows the right MANIFEST rules, but I have to adapt
	# it's output to my output. Annoying, for sure.
	my $hash = do {
		local $SIG{'__WARN__'} = sub {
			my $message = shift;
			if( $message =~ m/Debug: (.*)/ ) {
				$self->_debug( $1 );
				}
			else {
				$self->_die( "files_in_manifest: could not open file\n" );
				}
			};

		ExtUtils::Manifest::maniread( $self->manifest_name );
		};

	sort keys %$hash;
	}

=item check_vcs

=item vcs_tag

=item make_vcs_tag

Note: these methods were formerly "cvs", but are now "vcs" for
Version Control System.

This is a placeholder method which should be implemented in a mixin
module. Try installing Module::Release::CVS, Module::Release::SVN,
or Module::Release::Git and then loading them in your script. The
default C<release> script does this for you by checking for the
special directories for those source systems.

Previous to version 1.24, these methods were implemented in this
module to support CVS. They are now in Module::Release::CVS as a
separate module.

=cut

sub check_vcs {
	$_[0]->_die( "check_vcs must be implemented in a mixin class" );
	}


sub vcs_tag {
	$_[0]->_die( "vcs_tag must be implemented in a mixin class" );
	}

sub make_vcs_tag {
	$_[0]->_die( "make_vcs_tag must be implemented in a mixin class" );
	}

=item touch( FILES )

Set the modification times of each file in FILES to the current time. It
tries to open the file for writing and immediately closing it, as well as
using utime. It checks that the access and modification times were
updated.

Returns the number of files which it successfully touched.

=cut

sub touch {
	my( $self, @files ) = @_;

	my $time = time;

	my $count = 0;
	foreach my $file ( @files ) {
		unless( -f $file ) {
			$self->_warn( "$file is not a plain file" );
			next;
			}

		open my( $fh ), ">>", $file
			or $self->_warn( "Could not open file [$file] for writing: $!" );
		close $file;

		utime( $time, $time, $file );

		# check that it actually worked
		unless( 2 == grep { $_ == $time } (stat $file)[8,9] ) {
			$self->_warn( "$file did not set utimes." );
			next;
			}

		$count++;
		}

	$count;
	}

=item touch_all_in_manifest

Runs touch on all of the files in MANIFEST.

=cut

sub touch_all_in_manifest { $_[0]->touch( $_[0]->files_in_manifest ) }

=back

=head2 Methods for uploading

=over 4

=item should_upload_to_pause

Should I upload to PAUSE? If C<cpan_user> and C<cpan_pass> are set,
go for it.

=cut

sub should_upload_to_pause {
	$_[0]->_debug( "Checking if I should upload\n" );
	my $answer = !!( $_[0]->config->cpan_user && $_[0]->config->cpan_pass );
	$_[0]->_debug( "The answer is [$answer]\n" );
	$answer;
	}

=item check_for_passwords

Get passwords for CPAN.

=cut

sub check_for_passwords {
	if( my $pass = $_[0]->config->cpan_user && $_[0]->get_env_var( "CPAN_PASS" )  ) {
		$_[0]->config->set( 'cpan_pass', $pass );
		}

	$_[0]->_debug( "CPAN pass is " . $_[0]->config->cpan_pass . "\n" );
	}

=item get_changes()

Read and parse the F<Changes> file.  This is pretty specific, so
you may well want to overload it.

=cut

sub get_changes {
	open my $fh, '<:encoding(UTF-8)', 'Changes' or return '';

	my $data = <$fh>;  # get first line

	while( <$fh> ) {
		last if /^\S/;
		$data .= $_;
		}

	return $data;
	}

=item show_recent_contributors()

Show recent contributors before creating/extending Changes.

This output relies upon the method C<get_recent_contributors()> having been
implemented in the relevant mixin for your version control system.

=cut

sub show_recent_contributors {
	my $self = shift;
	return unless $self->can( 'get_recent_contributors' );
	my @contributors = $self->get_recent_contributors;
	$self->_print("Contributors since last release:\n") if @contributors;
	$self->_print( "\t", $_, "\n" ) for @contributors;
	}

=item get_release_date()

Return a string representing the current date and time (in UTC) in the
L<CPAN::Changes::Spec> format so that it can be added directly to the
Changes file.

=cut

sub get_release_date {
	state $rc = require Time::Piece;
	return Time::Piece->gmtime->datetime . 'Z';
	}

=item run

Run a command in the shell.

=item run_error

Returns true if the command ran successfully, and false otherwise. Use
this function in any other method that calls run to figure out what to
do when a command doesn't work. You may want to handle that yourself.

=cut

sub _run_error_reset { $_[0]->{_run_error} = 0 }
sub _run_error_set   { $_[0]->{_run_error} = 1 }
sub run_error        { $_[0]->{_run_error}     }

sub run {
	my( $self, $command ) = @_;

	$self->_run_error_reset;

	$self->_debug( "$command\n" );
	$self->_die( "Didn't get a command!" ) unless defined $command;

	open my($fh), "-|", "$command" or $self->_die( "Could not open command [$command]: $!" );
	$fh->autoflush;

	my $output = '';
	my $buffer = '';
	local $| = 1;

	my $readlen = $self->debug ? 1 : 256;

	while( read $fh, $buffer, $readlen ) {
		$output .= $_;
		$self->_debug( $_, $buffer );
		$output .= $buffer;
		}

	$self->_debug( $self->_dashes, "\n" );

	unless( close $fh ) {
		$self->_run_error_set;
		$self->_warn(  "Command [$command] didn't close cleanly: $?" );
		}

	return $output;
	}

=item get_env_var

Get an environment variable or prompt for it

=cut

sub get_env_var {
	my ($self, $field) = @_;

	# Check for an explicit argument passed
	return $self->{lc $field} if defined $self->{lc $field};

	my $pass = $ENV{$field};

	return $pass if defined( $pass ) && length( $pass );

	$self->_print( "$field is not set.  Enter it now: " );
	if ($field eq 'CPAN_PASS') {
		# don't echo passwords to the screen
		require Term::ReadKey;
		local $| = 1;
		Term::ReadKey::ReadMode('noecho');
		$pass = $self->_slurp;
		Term::ReadKey::ReadMode('restore');
	}
	else {
		$pass = $self->_slurp;
	}
	chomp $pass;

	return $pass if defined( $pass ) && length( $pass );

	$self->_debug( "$field not supplied.  Aborting...\n" );
	}

=back

=head2 Methods for developers

=over

=item _print( LIST )

Send the LIST to whatever is in output_fh, or to STDOUT. If you set
output_fh to a null filehandle, output goes nowhere.

=cut

sub _print { print { $_[0]->output_fh } @_[1..$#_] }

=item _slurp

Read a line from whatever is in input_fh and return it.

=cut

sub _slurp {
	my $fh = $_[0]->input_fh;
	return <$fh>;
}

=item _dashes()

Use this for a string representing a line in the output. Since it's a
method you can override it if you like.

=cut

sub _dashes { "-" x 73 }

=item _debug( LIST )

Send the LIST to whatever is in debug_fh, or to STDERR. If you aren't
debugging, debug_fh should return a null filehandle.

=cut
use Carp qw(carp);
sub _debug {
	my $self = shift;

	my $debug_fh = $self->debug_fh;

	print { $debug_fh } @_;
	}


#eval { print { shift->debug_fh } @_; 1 } or carp "Failure in _debug: [@_] [$@]" }

=item _die( LIST )

=cut

sub _die { croak @_[1..$#_] }

=item _warn( LIST )

=cut

sub _warn { carp @_[1..$#_] unless $_[0]->quiet }

=back

=head1 TO DO

* What happened to my Changes munging?

=head1 CREDITS

Ken Williams turned my initial release(1) script into the present
module form.

Andy Lester handled the maintenance while I was on my Big Camping
Trip. He applied patches from many authors.

Andreas König suggested changes to make it work better with PAUSE.

Chris Nandor helped with figuring out the broken SourceForge stuff.

H.Merijn Brand has contributed many patches and features.

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/briandfoy/module-release

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright © 2007-2023, brian d foy C<< <bdfoy@cpan.org> >>. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the Artistic License 2.0.

=cut

1;
