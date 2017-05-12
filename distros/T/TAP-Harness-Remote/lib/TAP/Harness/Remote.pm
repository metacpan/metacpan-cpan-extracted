package TAP::Harness::Remote;

our $VERSION = '1.10';

use warnings;
use strict;
use Carp;

use base 'TAP::Harness';
use constant config_path => "$ENV{HOME}/.remote_test";
use File::Spec;
use Cwd;
use YAML;

=head1 NAME

TAP::Harness::Remote - Run tests on a remote server farm

=head1 SYNOPSIS

    prove -l --state=save,slow --harness TAP::Harness::Remote t/*.t

=head1 DESCRIPTION

Sometimes you want to run tests on a remote testing machine, rather
than your local development box.  C<TAP::Harness::Remote> allows you
so reproduce entire directory trees on a remote server via C<rsync>,
and spawn the tests remotely.  It also supports round-robin
distribution of tests across multiple remote testing machines.

=head1 USAGE

C<TAP::Harness::Remote> synchronizes local directories to the remote
testing server.  All tests that you wish to run remotely must be
somewhere within these "local testing directories."  You should
configure this set by creating or editing your F<~/.remote_test> file:

    ---
    ssh: /usr/bin/ssh
    local:
      - /path/to/local/testing/root/
      - /path/to/another/testing/root/
    user: username
    host: remote.testing.host.example.com
    root: /where/to/place/local/root/on/remote/
    perl: /usr/bin/perl
    master: 1
    ssh_args:
      - -x
      - -S
      - '~/.ssh/master-%r@%h:%p'
    rsync_args:
      - -C
      - --exclude
      - blib
    env:
      FOO: bar

See L</CONFIGURATION AND ENVIRONMENT> for more details on the
individual configuration options.

Once your F<~/.remote_test> is configured, you can run your tests
remotely, using:

    prove -l --harness TAP::Harness::Remote t/*.t

Any paths in C<@INC> which point inside your local testing roots are
rewritten to point to the equivilent path on the remote host.  This is
especially useful if you are testing a number of inter-related
modules; by placing all of them all as local testing roots, and adding
all of their C<lib/> paths to your C<PERL5LIB>, you can ensure that
the remote machine always tests your combination of the modules, not
whichever versions are installed on the remote host.

If you have a farm of remote hosts, you may change the C<host>
configuration variable to be an array reference of hostnames.  Tests
will be distributed in a round-robin manner across the hosts.  Each
host will run as many tests in parallel as you specified with C<-j>.

Especially when running tests in parallel, it is highly suggested that
you use the standard L<TAP::Harness> C<--state=save,slow> option, as
this ensures that the slowest tests will run first, reducing your
overall test run time.

=head1 METHODS

=head2 new

Overrides L<TAP::Harness/new> to load the local configuration, and add
the necessary hooks for when tests are actually run.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    $self->load_remote_config;
    for ( @{$self->remote_config("local")} ) {
        die
            "Local testing root ($_) doesn't exist\n"
            unless -d $_;
    }

    # Find which testing root we're under

    die
        "Current path isn't inside of local testing roots (@{$self->remote_config('local')})\n"
        unless defined $self->rewrite_path( Cwd::cwd );

    die "Testing host not defined\n"
        unless grep { defined and not /\.example\.com$/ }
        @{ $self->remote_config("host") };

    die
        "Can't find or execute ssh command: @{[$self->remote_config('ssh')]}\n"
        unless -e $self->remote_config("ssh")
        and -x $self->remote_config("ssh");

    $ENV{HARNESS_PERL} = $self->remote_config("ssh");

    $self->jobs( $self->jobs * @{ $self->remote_config("host") } );

    $self->callback( before_runtests => sub { $self->setup(@_) } );
    $self->callback( parser_args     => sub { $self->change_switches(@_) } );
    return $self;
}

=head2 config_path

Returns the path to the configuration file; this is usually
C<$ENV{HOME}/.remote_test>.

=head2 default_config

Returns, as a hashref, the default configuration.  See
L</CONFIGURATION>.

=cut

sub default_config {
    return {
        user       => "smoker",
        host       => "smoke-server.example.com",
        root       => "/home/smoker/remote-test/$ENV{USER}/",
        perl       => "/home/smoker/bin/perl",
        local      => [ "$ENV{HOME}/remote-test/" ],
        ssh        => "/usr/bin/ssh",
        ssh_args   => [ "-x", "-S", "~/.ssh/master-%r@%h:%p" ],
        rsync_args => [ "-C" ],
        master     => 1,
        env        => {},
    };
}

=head2 load_remote_config

Loads and canonicalizes the configuration.  Writes and uses the
default configuration (L</default_config>) if the file does not exist.

=cut

sub load_remote_config {
    my $self = shift;
    unless ( -e $self->config_path and -r $self->config_path ) {
        YAML::DumpFile( $self->config_path, $self->default_config );
    }
    $self->{remote_config} = YAML::LoadFile( $self->config_path );

    # Make local path into an arrayref
    $self->{remote_config}{local} = [ $self->{remote_config}{local} ]
      unless ref $self->{remote_config}{local};

    # Strip trailing slashes in local dirs, for rsync
    $self->{remote_config}{local} = [map {s|/$||; $_} @{$self->{remote_config}{local}}];

    # Host should be an arrayref
    $self->{remote_config}{host} = [ $self->{remote_config}{host} ]
        unless ref $self->{remote_config}{host};

    # Ditto ssh_args
    $self->{remote_config}{ssh_args}
        = [ split ' ', ( $self->{remote_config}{ssh_args} || "") ]
        unless ref $self->{remote_config}{ssh_args};

    # Also, rsync_args
    $self->{remote_config}{rsync_args}
        = [ split ' ', ($self->{remote_config}{rsync_args} || "") ]
        unless ref $self->{remote_config}{rsync_args};

    # Defaults for env
    $self->{env} ||= {};
}

=head2 remote_config KEY

Returns the configuration value set fo the given C<KEY>.

=cut

sub remote_config {
    my $self = shift;
    $self->load_remote_config unless $self->{remote_config};
    return $self->{remote_config}->{ shift @_ };
}

=head2 userhost [HOST]

Returns a valid C<user@host> string; host is taken to be the first
known host, unless provided.

=cut

sub userhost {
    my $self = shift;
    my $userhost = @_ ? shift : $self->remote_config("host")->[0];
    $userhost = $self->remote_config("user") . "\@" . $userhost
        if $self->remote_config("user");
    return $userhost;
}

=head2 start_masters

Starts the ssh master connections, if support for them is enabled.
Otherwise, does nothing.  See the man page for C<ssh -M> for more
information about master connections.

=cut

sub start_masters {
    my $self = shift;
    return unless $self->remote_config("master");

    local $SIG{USR1} = sub {
        die "Failed to set up SSH master connections\n";
    };

    my $parent = $$;
    for my $host ( @{ $self->remote_config("host") } ) {
        my $userhost = $self->userhost($host);
        my $pid      = fork;
        die "Fork failed: $!" unless $pid >= 0;
        if ( not $pid ) {
            # Make sure we clean out this list, so we don't run
            # anything on _our_ DESTROY
            $self->{ssh_master} = {};

            # Start the master
            system($self->remote_config("ssh"),
                @{ $self->remote_config("ssh_args") }, "-M", "-N", $userhost);

            # Signal the parent when we're done; we're still within 2
            # seconds of starting, we'll catch this and abort.
            kill 'USR1', $parent;
            exit;
        }
        $self->{ssh_master}{$userhost} = $pid;
    }

    # During this sleep, we're waiting for our kids to tell us that
    # they died.
    sleep 5;
}

=head2 setup

Starts the openssh master connections if need be (see
L</start_masters>), then L</rsync>'s over the local roots.
Additionally, stores a rewritten PERL5LIB path such that any
directories which point into the local root are included in the remote
PERL5LIB as well.

=cut

sub setup {
    my $self = shift;
    $SIG{USR1} = sub {};
    $self->start_masters;
    $self->rsync;

    # Set up our perl5lib
    $self->{perl5lib} = join( ":", grep {defined} map {$self->rewrite_path($_)} split( /:/, $ENV{PERL5LIB} || "" ) );
    $self->{perl5lib} =~ s/^(lib:){1,}/lib:/;

    # Also, any other env vars
    $self->{env} = [];
    for my $k (keys %{$self->remote_config("env")}) {
        my $val = $self->remote_config("env")->{$k};
        $val =~ s/'/'"'"'/g;
        push @{$self->{env}}, "$k='$val'";
    }
}

=head2 rsync

Sends all local roots to the remote hosts, one at a time, using C<rsync>.

=cut

sub rsync {
    my $self = shift;

    for my $host ( @{ $self->remote_config("host") } ) {
        my $userhost = $self->userhost($host);
        my $return   = system(
            qw!rsync -avz --delete!,
            @{$self->remote_config('rsync_args')},
            qq!--rsh!,
            $self->remote_config("ssh")
                . " @{$self->remote_config('ssh_args')}",
            @{$self->remote_config("local")},
            "$userhost:" . $self->remote_config("root")
        );
        die "rsync to $userhost failed" if $return;
    }
}

=head2 rewrite_path PATH

Rewrites the given local C<PATH> into the remote path on the testing
server.  Returns undef if the C<PATH> isn't inside any of the
configured local paths.

=cut

sub rewrite_path {
    my $self = shift;
    my $path = shift;
    my $remote = $self->remote_config("root");
    for my $local ( @{$self->remote_config("local")} ) {
        if ($path =~ /^$local/) {
            $path =~ s{^$local}{$remote . "/" . (File::Spec->splitpath($local))[-1]}e;
            return $path;
        }
    }
    return undef;
}

=head2 DESTROY

Tears down the ssh master connections, if they were started.

=cut

sub DESTROY {
    my $self = shift;
    return unless $self->remote_config("master");
    for my $userhost ( keys %{ $self->{ssh_master} || {} } ) {
        next unless kill 0, $self->{ssh_master}{$userhost};
        system $self->remote_config("ssh"), @{ $self->remote_config("ssh_args") }, "-O",
            "exit", $userhost;
    }
}

=head2 change_switches

Changes the switches around, such that the remote perl is called, via
ssh.  This code is called once per test file.

=cut

sub change_switches {
    my ( $self, $args, $test ) = @_;

    my $remote = $self->remote_config("root");

    my @other = grep { not /^-I/ } @{ $args->{switches} };
    my @inc = map {"-I$_"} grep {defined $_} map { s/^-I//; $self->rewrite_path($_) }
        grep {/^-I/} @{ $args->{switches} };

    my $host = $self->remote_config("host")
        ->[ $self->{hostno}++ % @{ $self->remote_config("host") } ];
    my $userhost = $self->userhost($host);
    $args->{switches} = [
        @{ $self->remote_config("ssh_args") }, $userhost,
        "cd",                                  $self->rewrite_path( Cwd::cwd ),
        "&&",                                  "PERL5LIB='@{[$self->{perl5lib}]}'",
        @{$self->{env}},
        $self->remote_config("perl"),          @other,
        @inc
    ];
}

=head1 CONFIGURATION AND ENVIRONMENT

Configuration is done via the file C<~/.remote_test>, which is a YAML
file.  Valid keys are:

=over

=item user

The username to use on the remote connection.

=item host

The host to connect to.  If this is an array reference, tests will be
distributed, round-robin fashion, across all of the hosts.  This does
also incur the overhead of rsync'ing to each host.

=item root

The remote testing root.  This is the place where the local roots will
be C<rsync>'d to.

=item local

The local testing roots.  This can be either an array reference of
multiple roots, or a single string.  Files under each of these
directories will be C<rsync>'d to the remote server.  All tests to be
run remotely must be within these roots.

=item perl

The path to the C<perl> binary on the remote host.

=item ssh

The path to the local C<ssh> binary.

=item ssh_args

Either a string or an array reference of arguments to pass to ssh.
Suggested defaults include C<-x> and C<-S ~/.ssh/master-%r@%h:%p>

=item master

If a true value is given for this, will attempt to use OpenSSH master
connections to reduce the overhead of making repeated connections to
the remote host.

=item rsync_args

Either a string or an array reference of arguments to pass to rsync.
You can use this, for say C<--exclude blib>.  The arguments C<-avz
--delete> are fixed, and then any C<rsync_args> are appended.  C<-C>
is generally a useful and correct option, and is the default when
creating new F<.remote_test> files.  See L<rsync(1)> for more details.

=item env

A hash reference of environment variable names and values, to be
used on the remote host.

=back

=head1 DEPENDENCIES

A recent enough TAP::Harness build; 3.03 or later should suffice.
Working copies of OpenSSH and rsync.

=head1 BUGS AND LIMITATIONS

Aborting tests using C<^C> may leave dangling processes on the remote
host.

Please report any bugs or feature requests to
C<bug-tap-harness-remote@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Alex Vandiver  C<< <alexmv@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007-2008, Best Practical Solutions, LLC.  All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

1;
