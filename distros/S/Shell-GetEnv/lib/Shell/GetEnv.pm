# --8<--8<--8<--8<--
#
# Copyright (C) 2007 Smithsonian Astrophysical Observatory
#
# This file is part of Shell::GetEnv
#
# Shell::GetEnv is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# -->8-->8-->8-->8--

package Shell::GetEnv;

require 5.008000;
use strict;
use warnings;

use Carp;

use File::Temp;
use Shell::GetEnv::Dumper;

our $VERSION = '0.10';

my $status_var = 'p5_SHELL_GETENV_STATUS';

# a compendium of shells
my %shells = (
    bash => {
        interactive => 'i',
        nostartup   => '--noprofile',
        verbose     => 'v',
        echo        => 'x',
        login       => 'l',
        save_status => qq[export $status_var=\$?],
    },

    zsh => {
        interactive => 'i',
        nostartup   => 'p',
        verbose     => 'v',
        echo        => 'x',
        login       => 'l',
        save_status => qq[export $status_var=\$?],
    },

    dash => {
        interactive => 'i',
        verbose     => 'v',
        echo        => 'x',
        login       => 'l',
        save_status => qq[export $status_var=\$?],
    },

    sh => {
        interactive => 'i',
        verbose     => 'v',
        echo        => 'x',
        login       => 'l',
        save_status => qq[$status_var=\$?; export $status_var],
    },

    ksh => {
        interactive => 'i',
        nostartup   => 'p',
        verbose     => 'v',
        echo        => 'x',
        login       => 'l',
        save_status => qq[export $status_var=\$?],
    },

    csh => {
        interactive => 'i',
        nostartup   => 'f',
        echo        => 'x',
        verbose     => 'v',
        login       => 'l',
        save_status => qq[setenv $status_var \$status],
    },

    tcsh => {
        interactive => 'i',
        nostartup   => 'f',
        echo        => 'x',
        verbose     => 'v',
        login       => 'l',
        save_status => qq[setenv $status_var \$status],
    },
);


my %Opts = (
    startup     => 1,
    login       => 0,
    debug       => 0,
    echo        => 0,
    login       => 0,
    verbose     => 0,
    interactive => 0,
    redirect    => 1,
    stderr      => undef,
    stdout      => undef,
    expect      => 0,
    timeout     => 10,
    shellopts   => undef,
);


sub new
{
    my $class = shift;
    my $shell = shift;

    croak( __PACKAGE__, "->new: unsupported shell: $shell\n" )
      unless defined $shells{$shell};

    my %opt = %{ 'HASH' eq ref( $_[-1] ) ? pop : {} };

    # now want lc, but keep backwards compat
    $opt{lc $_} = delete $opt{$_} for keys %opt;

    my @notvalid = grep { ! exists $Opts{$_} } keys %opt;
    croak( __PACKAGE__, "->new: illegal option(s): @notvalid\n" )
      if @notvalid;

    my $self = bless { %Opts, %opt,
		       cmds => [@_],
		       shell => $shell
		     } , $class;

    # needed to get correct hash key for %shells
    $self->{nostartup} = ! $self->{startup};

    $self->_getenv;

    return $self;
}

# use temporary script files and output files to get the environment
# requires that a shell have a '-i' flag to act as an interactive shell
sub _getenv
{
    my $self = shift;

    # file to hold the environment
    my $fh_e = File::Temp->new( )
      or croak( __PACKAGE__, ": unable to create temporary environment file" );

    # create script to dump environmental variables to the above file
    push @{$self->{cmds}},
      $shells{$self->{shell}}{save_status},
      $self->_dumper_script( $fh_e->filename ),
      'exit' ;

    # construct list of command line options for the shell
    $self->_shell_options;

    # redirect i/o streams
    $self->_stream_redir if $self->{redirect};


    if ( $self->{debug} )
    {
	warn( "Shell: $self->{shell}\n",
	      "Options: ", join( ' ', @{$self->{shelloptions}} ), "\n",
	      "Cmds: \n", join( "\n", @{$self->{cmds}}), "\n" );
    }


    eval {
	if ( $self->{expect} )
	{
	    $self->_getenv_expect( $fh_e->filename);
	}
	else
	{
	    $self->_getenv_pipe( $fh_e->filename);
	}
    };
    my $error = $@;

    # reset i/o streams
    $self->_stream_reset if $self->{redirect};

    if ( $error )
    {
	local $Carp::CarpLevel = 1;
	croak $error;
    }


    # retrieve environment
    $self->_retrieve_env( $fh_e->filename );
}


sub _dumper_script
{
    my ( $self, $filename ) = @_;

    # this invokes the module directly, using the Perl which was
    # used to invoke the parent process.  It uses the fact that we
    # use()'d Shell::GetEnv::Dumper and Perl stored the absolute path
    # to it in %INC;
    return qq{$^X '$INC{'Shell/GetEnv/Dumper.pm'}' $filename};
}



# redirect STDOUT and STDERR
sub _stream_redir
{
    my ( $self ) = @_;

    # redirect STDERR & STDOUT to either /dev/null or somewhere the user points
    # us to.

    my $stdout = $self->{stdout} || File::Spec->devnull();
    my $stderr = $self->{stderr} || File::Spec->devnull();

    open( $self->{oSTDOUT}, ">&STDOUT" )
      or croak( __PACKAGE__,  ': error duping STDOUT' );
    open( $self->{oSTDERR}, ">&STDERR" )
      or croak( __PACKAGE__,  ': error duping STDERR' );

    open( STDERR, '>', $stderr ) or
      croak( __PACKAGE__, ": unable to redirect STDERR to $stderr" );
    open( STDOUT, '>', $stdout ) or
      croak( __PACKAGE__, ": unable to redirect STDOUT to $stdout" );

    select STDERR; $| = 1;
    select STDOUT; $| = 1;
}

# reset STDOUT and STDERR
sub _stream_reset
{
    my ( $self ) = @_;

    close STDOUT;
    close STDERR;

    open STDOUT, '>&', $self->{oSTDOUT};
    open STDERR, '>&', $self->{oSTDERR};

    close delete $self->{oSTDOUT};
    close delete $self->{oSTDERR};
}

# create shell options
sub _shell_options
{
    my ( $self, $scriptfile ) = @_;

    my $shell = $shells{$self->{shell}};

    ## no critic (ProhibitAccessOfPrivateData)

    my @options =
      map { $shell->{$_} }
	grep { exists $shell->{$_} && $self->{$_} }
	  qw( nostartup echo verbose interactive login )
	    ;

    my @shellopts
      = defined $self->{shellopts}
      ? 'ARRAY' eq ref( $self->{shellopts} )
          ? @{ $self->{shellopts} }
          : $self->{shellopts}
      : ();

    ## use critic

    croak( "cannot combine 'login' with any other options for $self->{shell}\n" )
	  if ( $self->{shell} eq 'csh' or $self->{shell} eq 'tcsh' )
	      && $self->{login}
	      && @options + @shellopts > 1;

    # bundled options are those without a leading hyphen or plus
    my %options = map { ( $_ => 1 ) } @options;
    my @bundled = grep{ ! /^[-+]/ } keys %options;
    delete @options{@bundled};

    my $bundled = @bundled ? '-' . join( '', @bundled ) : undef;

    # long options; bash treats these differently
    my @longopts = grep{ /^--/ } keys %options;
    delete @options{@longopts};

    # everything else
    my @otheropts = keys %options;

    $self->{shelloptions} =
			[ 
			 # long options go first (bash complains)
			 @longopts,
			 ( $bundled ? $bundled : () ),
			 @otheropts,
			 @shellopts,
			];
}

# communicate with the shell using a pipe
sub _getenv_pipe
{
    my ( $self ) = @_;

    local $" = ' ';
    open( my $pipe, '|-' , $self->{shell}, @{$self->{shelloptions}} )
      or die( __PACKAGE__, ": error opening pipe to $self->{shell}: $!\n" );

    print $pipe ( join( "\n", @{$self->{cmds}}), "\n");
    close $pipe
      or die( __PACKAGE__, ": error closing pipe to $self->{shell}: $!\n" );
}

# communicate with the shell using Expect
sub _getenv_expect
{
    my ( $self, $filename ) = @_;

    require Expect;
    my $exp = Expect->new;
    $exp->raw_pty(1);
    $exp->spawn( $self->{shell}, @{$self->{shelloptions}} )
      or die( __PACKAGE__, ": error spawning $self->{shell}\n" );
    $exp->send( map { $_ . "\n" } @{$self->{cmds}} );
    $exp->expect( $self->{timeout} );
}

# extract environmental variables from a dumped file
sub _retrieve_env
{
    my ( $self, $filename ) = @_;

    $self->{envs} = Shell::GetEnv::Dumper::read_envs( $filename );
    $self->{status} = delete $self->{envs}{$status_var};
}

# return variables
sub envs
{
    my ( $self, %iopt ) = @_;

    my %opt = ( diffsonly  => 0,
		exclude    => [],
		envstr     => 0,
		zapdeleted => 0,
	      );

    # now want lc, but keep backwards compat
    $iopt{lc $_} = delete $iopt{$_} for keys %iopt;

    my @unknown = grep { !exists $opt{$_} } keys %iopt;
    croak( __PACKAGE__, "->envs: unknown options: @unknown\n" )
      if @unknown;

    %opt = ( %opt, %iopt );

    my %env = %{$self->{envs}};


    ###
    # filter out excluded variables

    # ensure that scalars are handled correctly
    $opt{exclude} = [ $opt{exclude} ]
      unless 'ARRAY' eq ref $opt{exclude};

    foreach my $exclude ( @{$opt{exclude}} )
    {
	my @delkeys;

	if ( 'Regexp' eq ref $exclude )
	{
	    @delkeys = grep { /$exclude/ } keys %env;
	}
	elsif ( 'CODE' eq ref $exclude )
	{
	    @delkeys = grep { $exclude->($_, $env{$_}) } keys %env;
	}
	else
	{
	    @delkeys = grep { $_ eq $exclude } keys %env;
	}

	delete @env{@delkeys};
    }


    # return only variables which are new or differ from the current
    # environment
    if ( $opt{diffsonly} )
    {
	my @delkeys =
	  grep { exists $ENV{$_} && $env{$_} eq $ENV{$_} } keys %env;

	delete @env{@delkeys};
    }



    if ( $opt{envstr} )
    {
	my @set = map { _shell_escape("$_=" . $env{$_}) } keys %env;
	my @unset;

	if ( $opt{zapdeleted} )
	{
	    my @deleted;
	    @deleted = grep { exists $ENV{$_} && ! exists $self->{envs}{$_} }
	      keys %ENV;

	    @unset = map { "-u $_" } @deleted;
	}

	return join( ' ', @unset, @set );
    }

    return \%env;
}

sub status { $_[0]->{status} }

sub _shell_escape
{
  my $str = shift;

  # empty string
  if ( $str eq '' )
  {
    $str = "''";
  }

  # if there's white space, single quote the entire word.  however,
  # since single quotes can't be escaped inside single quotes,
  # isolate them from the single quoted part and escape them.
  # i.e., the string a 'b turns into 'a '\''b' 
  elsif ( $str =~ /\s/ )
  {
    # isolate the lone single quotes
    $str =~ s/'/'\\''/g;

    # quote the whole string
    $str = "'$str'";

    # remove obvious duplicate quotes.
    $str =~ s/(^|[^\\])''/$1/g;
  }

  # otherwise, quote all of the non-word characters
  else
  {
    $str =~  s/(\W)/\\$1/go;
  }

  $str;
}


sub import_envs
{
    my ( $self, %iopt ) = @_;

    my %opt = ( Exclude    => [],
		ZapDeleted => 1,
	      );

    my @unknown = grep { !exists $opt{$_} } keys %iopt;
    croak( __PACKAGE__, "->import_envs: unknown options: @unknown\n" )
      if @unknown;

    %opt = ( %opt, %iopt );
    my $env = $self->envs( %opt );

    # store new values
    while( my ( $key, $val ) = each %$env )
    {
	$ENV{$key} = $val;
    }


    # remove deleted ones, if requested
    if ( $opt{ZapDeleted} )
    {
	delete @ENV{grep { exists $ENV{$_} && ! exists $self->{envs}{$_} }
		      keys %ENV };
    }
}


1;
__END__


=head1 NAME

Shell::GetEnv - extract the environment from a shell after executing commands

=head1 SYNOPSIS

  use Shell::GetEnv;

  $env = Shell::GetEnv->new( $shell, $command );
  $status = $env->status;
  $envs = $env->envs( %opts )
  $env->import_envs( %opts );

=head1 DESCRIPTION

B<Shell::GetEnv> provides a facility for obtaining changes made to
environmental variables as the result of running shell scripts.  It
does this by causing a shell to invoke a series of user provided shell
commands (some of which might source scripts) and having the shell
process store its environment (using a short Perl script) into a
temporary file, which is parsed by B<Shell::Getenv>.

Communications with the shell subprocess may be done via standard IPC
(via a pipe), or may be done via the Perl B<Expect> module (necessary
if proper execution of the shell script requires the shell to be
attached to a "real" terminal).

The new environment may be imported into the current one, or may be
returned either as a hash or as a string suitable for use with the
*NIX B<env> command.


=head1 METHODS

=over

=item new

  $env = Shell::GetEnv->new( $shell, @cmds, \%attrs );

Start the shell specified by I<$shell>, run the passed commands, and
retrieve the environment.  Note that only shell built-in
commands can actually change the shell's environment, so typically
the commands source a startup file.  For example:

  $env = Shell::GetEnv->new( 'tcsh', 'source foo.csh' );

The supported shells are:

  csh tcsh bash sh ksh zsh dash

Attributes:

=over

=item C<startup> I<boolean>

If true, the user's shell startup files are invoked.  This flag is
supported for C<csh>, C<tcsh>, and C<bash>.  This is emulated under
B<ksh> using its B<-p> flag, which isn't quite the same thing.

There seems to be no clean means of turning off startup file
processing under the other shells.

This defaults to I<true>.

=item C<echo> I<boolean>

If true, put shell is put in echo mode.  This is only of use when the
C<stdout> attribute is used.  It defaults to I<false>.

=item C<interactive> I<boolean>

If true, put the shell in interactive mode. Some shells do not react
well when put in interactive mode but not connected to terminals.
Try using the C<expect> option instead. This defaults to I<false>.

=item C<login> I<boolean>

If true, invoke the shell as a login shell.  Defaults to
I<false>.

B<tcsh> and B<csh> will only honor this option if no other command
line options are passed.  For these shells B<Shell::GetEnv> will
throw an exception if this option conflicts with another.

=item C<redirect> I<boolean>

If true, redirect the output and error streams (see also the C<STDERR>
and C<stdout> options).  Defaults to true.

=item C<verbose> I<boolean>

If true, put the shell in verbose mode.  This is only of use when the
C<stdout> attribute is used.  It defaults to I<false>.

=item C<stderr> I<filename>

Normally output from the shells' standard error stream is discarded.
This may be set to a file name to which the stream
should be written.  See also the C<redirect> option.

=item C<stdout> I<filename>

Normally output from the shells' standard output stream is discarded.
This may be set to a file name to which the stream
should be written.  See also the C<Redirect> option.

=item C<expect> I<boolean>

If true, the Perl B<Expect> module is used to communicate with the
subshell.  This is useful if it is necessary to simulate connection
with a terminal, which may be important when setting up some
enviroments.

=item C<timeout> I<integer>

The number of seconds to wait for a response from the shell when using
B<Expect>.  It defaults to 10 seconds.

=item C<shellopts> I<scalar> or I<arrayref>

Arbitrary options to be passed to the shell.

=back

=item envs

  $env = $env->envs( [%opt] );


Return the environment.  Typically the environment is returned as a
hashref, but if the C<envstr> option is true it will be returned as a
string suitable for use with the *NIX B<env> command.  If no options
are specified, the entire environment is returned.

The following options are recognized:

=over

=item C<diffsonly> I<boolean>

If true, the returned environment contains only those variables which
are new or which have changed from the current environment.  There is no way of
indicating Variables which have been I<deleted>.

=item C<exclude> I<array> or I<scalar>

This specifies variables to exclude from the returned environment.  It
may be either a single value or an array of values.

A value may be a string (for an exact match of a variable name), a regular
expression created with the B<qr> operator, or a subroutine
reference.  The subroutine will be passed two arguments, the variable
name and its value, and should return true if the variable should be
excluded, false otherwise.

=item C<envstr> I<boolean>

If true, a string representation of the environment is returned,
suitable for use with the *NIX B<env> command.  Appropriate quoting is
done so that it is correclty parsed by shells.

If the C<zapdeleted> option is also specified (and is true) variables
which are present in the current environment but I<not> in the new one
are explicitly deleted by inserting C<-u variablename> in the output
string.  B<Note>, however, that not all versions of B<env> recognize the
B<-u> option (e.g. those in Solaris or OS X).  In those cases, to ensure the
correct environment, use C<diffsonly => 0, zapdeleted => 0> and
invoke B<env> with the C<-i> option.

=back

=item status

  $status = $env->status;

Returns the invoked shell's status after executing the commands
provided to the constructor.  See L<perlfunc/system> for instructions
on how to interpret the status.

=item import_envs

  $env->import_envs( %opt )

Import the new environment into the current one.  The available
options are:

=over

=item C<exclude> I<array> or I<scalar>

This specifies variables to exclude from the returned environment.  It
may be either a single value or an array of values.

A value may be a string (for an exact match of a variable name), a regular
expression created with the B<qr> operator, or a subroutine
reference.  The subroutine will be passed two arguments, the variable
name and its value, and should return true if the variable should be
excluded, false otherwise.

=item C<zapdeleted> I<boolean>

If true, variables which are present in the current environment but
I<not> in the new one are deleted from the current environment.

=back

=back

=head2 EXPORT

None by default.



=head1 SEE ALSO

There are other similar modules on CPAN. L<Shell::Source> is simpler,
L<Shell::EnvImporter> is a little more heavyweight (requires Class::MethodMaker).

This module's unique features:

=over

=item can use Expect for the times you really need a terminal

=item uses a tiny Perl program to get the environmental variables rather than parsing shell output

=item allows the capturing of shell output

=item more flexible means of submitting commands to the shell

=back

=head1 DEPENDENCIES

The B<YAML::Tiny> module is preferred for saving the environment
(because of its smaller footprint); the B<Data::Dumper> module
will be used if it is not available.

The B<Expect> module is required only if the C<expect> option is
specified.


=head1 AUTHOR

Diab Jerius, E<lt>djerius@cpan.orgE<gt>

=head1 CONTRIBUTORS

=over

=item Marty O'Brien <mob@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2007 Smithsonian Astrophysical Observatory

This software is released under the GNU General Public License.  You
may find a copy at

          http://www.gnu.org/licenses



=cut
