package Test::Consul;
$Test::Consul::VERSION = '0.008';
# ABSTRACT: Run a consul server for testing

use namespace::autoclean;

use File::Which qw(which);
use JSON::MaybeXS qw(JSON encode_json);
use Path::Tiny;
use POSIX qw(WNOHANG);
use Carp qw(croak);
use HTTP::Tiny;
use Net::EmptyPort qw( check_port );
use File::Temp qw( tempfile );
use Scalar::Util qw( blessed );

use Moo;
use Types::Standard qw( Bool Enum Undef );
use Types::Common::Numeric qw( PositiveInt );
use Types::Common::String qw( NonEmptySimpleStr );

my $start_port = 49152;
my $current_port = $start_port;
my $end_port  = 65535;

sub _unique_empty_port {
    my ($udp_too) = @_;

    my $port = 0;
    while ($port == 0) {
        $current_port ++;
        $current_port = $start_port if $current_port > $end_port;
        next if check_port( undef, $current_port, 'tcp' );
        next if $udp_too and check_port( undef, $current_port, 'udp' );
        $port = $current_port;
    }

    # Make sure we return a scalar with just numeric data so it gets
    # JSON encoded without quotes.
    return $port;
}

has _pid => (
    is        => 'rw',
    predicate => '_has_pid',
    clearer   => '_clear_pid',
);

has port => (
    is  => 'lazy',
    isa => PositiveInt,
);
sub _build_port {
    return _unique_empty_port();
}

has rpc_port => (
    is  => 'lazy',
    isa => PositiveInt,
);
sub _build_rpc_port {
    return _unique_empty_port();
}

has serf_lan_port => ( 
    is  => 'lazy',
    isa => PositiveInt,
);
sub _build_serf_lan_port {
    return _unique_empty_port( 1 );
}

has serf_wan_port => (
    is  => 'lazy',
    isa => PositiveInt,
);
sub _build_serf_wan_port {
    return _unique_empty_port( 1 );
}

has server_port => (
    is  => 'lazy',
    isa => PositiveInt,
);
sub _build_server_port {
    return _unique_empty_port();
}

has enable_acls => (
    is  => 'ro',
    isa => Bool,
);

has acl_default_policy => (
    is      => 'ro',
    isa     => Enum[qw( allow deny )],
    default => 'allow',
);

has acl_master_token => (
    is      => 'ro',
    isa     => NonEmptySimpleStr,
    default => '01234567-89AB-CDEF-GHIJ-KLMNOPQRSTUV',
);

has bin => (
    is => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);
sub _build_bin {
    my ($self) = @_;
    return $self->found_bin();
}

has datadir => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => 1,
);

sub running {
    my ($self) = @_;
    return !!$self->_has_pid();
}

sub start {
    my $self = shift;
    my $is_class_method = 0;

    if (!blessed $self) {
      $self = $self->new( @_ );
      $is_class_method = 1;
    }

    my $bin = $self->bin();
    unless (defined($bin) && -x $bin) {
        croak "can't find consul binary";
    }

    # Make sure we have at least Consul 0.6.1 which supports the -dev option.
    my ($version) = qx{$bin version};
    if ($version and $version =~ m{v(\d+)\.(\d+)\.(\d+)}) {
        $version = sprintf('%03d%03d%03d', $1, $2, $3);
    }
    else {
        $version = 0;
    }
    unless ($version >= 6_001) {
        croak "consul not version 0.6.1 or newer";
    }

    my @opts;

    my %config = (
        node_name  => 'perl-test-consul',
        datacenter => 'perl-test-consul',
        bind_addr  => '127.0.0.1',
        ports => {
            dns      => -1,
            http     => $self->port() + 0,
            https    => -1,
            rpc      => $self->rpc_port() + 0,
            serf_lan => $self->serf_lan_port() + 0,
            serf_wan => $self->serf_wan_port() + 0,
            server   => $self->server_port() + 0,
        },
    );

    # Version 0.7.0 reduced default performance behaviors in a way
    # that makese these tests slower to startup.  Override this and
    # make leadership election happen ASAP.
    if ($version >= 7_000) {
        $config{performance} = { raft_multiplier => 1 };
    }

    if ($self->enable_acls()) {
        $config{acl_master_token} = $self->acl_master_token();
        $config{acl_default_policy} = $self->acl_default_policy();
        $config{acl_datacenter} = 'perl-test-consul';
        $config{acl_token} = $self->acl_master_token();
    }

    my $configpath;
    if ($self->has_datadir()) {
        $config{data_dir}  = $self->datadir();
        $config{bootstrap} = \1;
        $config{server}    = \1;

        my $datapath = path($self->datadir());
        $datapath->remove_tree;
        $datapath->mkpath;

        $configpath = $datapath->child("consul.json");
    }
    else {
      push @opts, '-dev';
      $configpath = path( ( tempfile() )[1] );
    }

    $configpath->spew( encode_json(\%config) );
    push @opts, '-config-file', "$configpath";

    my $pid = fork();
    unless (defined $pid) {
        croak "fork failed: $!";
    }
    unless ($pid) {
        exec $bin, "agent", @opts;
    }

    my $http = HTTP::Tiny->new(timeout => 10);
    my $now = time;
    my $res;
    my $port = $self->port();
    while (time < $now+30) {
        $res = $http->get("http://127.0.0.1:$port/v1/status/leader");
        last if $res->{success} && $res->{content} =~ m/^"[0-9\.]+:[0-9]+"$/;
        sleep 1;
    }
    unless ($res->{success}) {
        kill 'KILL', $pid;
        croak "consul API test failed: $res->{status} $res->{reason}";
    }

    unlink $configpath if !$self->has_datadir();

    $self->_pid( $pid );

    return $self if $is_class_method;
    return;
}

sub stop {
    my ($self) = @_;
    return unless $self->_has_pid();
    my $pid = $self->_pid();
    $self->_clear_pid();
    kill 'TERM', $pid;
    my $now = time;
    while (time < $now+2) {
        return if waitpid($pid, WNOHANG) > 0;
    }
    kill 'KILL', $pid;
    return;
}

sub end {
    goto \&stop;
}

sub DESTROY {
    goto \&stop;
}

my ($bin, $bin_searched_for);
sub found_bin {
    return $bin if $bin_searched_for;
    $bin = $ENV{CONSUL_BIN} || which "consul";
    $bin_searched_for = 1;
    return $bin;
}

sub skip_all_if_no_bin {
    my ($class) = @_;

    croak 'The skip_all_if_no_bin method may only be used if the plan ' .
          'function is callable on the main package (which Test::More ' .
          'and Test2::Tools::Basic provide)'
          if !main->can('plan');

    return if defined $class->found_bin();

    main::plan( skip_all => 'The Consul binary must be available to run this test.' );
}

1;

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Test-Consul.png)](http://travis-ci.org/robn/Test-Consul)

=head1 NAME

Test::Consul - Run a Consul server for testing

=head1 SYNOPSIS

    use Test::Consul;
    
    # succeeds or dies
    my $tc = Test::Consul->start;
    
    my $consul_baseurl = "http://127.0.0.1:".$tc->port;
    
    # do things with Consul here
    
    # kill test server (or let $tc fall out of scope, destructor will clean up)
    $tc->end;

=head1 DESCRIPTION

This module starts and stops a standalone Consul instance. It's designed to be
used to help test Consul-aware Perl programs.

It's assumed that you have Consul 0.6.4 installed somewhere.

=head1 ARGUMENTS

=head2 port

The TCP port for HTTP API endpoint.  Consul's default is C<8500>, but
this defaults to a random unused port.

=head2 rpc_port

The TCP port for the RPC CLI endpoint.  Consul's default is C<8400>, but
this defaults to a random unused port.

=head2 serf_lan_port

The TCP and UDP port for the Serf LAN.  Consul's default is C<8301>, but
this defaults to a random unused port.

=head2 serf_wan_port

The TCP and UDP port for the Serf WAN.  Consul's default is C<8302>, but
this defaults to a random unused port.

=head2 server_port

The TCP port for the RPC Server address.  Consul's default is C<8300>, but
this defaults to a random unused port.

=head2 enable_acls

Set this to true to enable ACLs.

=head2 acl_default_policy

Set this to either C<allow> or C<deny>. The default is C<allow>.
See L<https://www.consul.io/docs/agent/options.html#acl_default_policy> for more
information.

=head2 acl_master_token

If L</enable_acls> is true then this token will be used as the master
token.  By default this will be C<01234567-89AB-CDEF-GHIJ-KLMNOPQRSTUV>.

=head2 bin

Location of the C<consul> binary.  If not provided then the binary will
be retrieved from L</found_bin>.

=head2 datadir

Directory for Consul's data store. If not provided, the C<-dev> option is used
and no datadir is used.

=head1 ATTRIBUTES

=head2 running

Returns C<true> if L</start> has been called and L</stop> has not been called.

=head1 METHODS

=head2 start

    # As an object method:
    my $tc = Test::Consul->new( %args );
    $tc->start();
    
    # As a class method:
    my $tc = Test::Consul->start( %args );

Starts a Consul instance. This method can take a moment to run, because it
waits until Consul's HTTP endpoint is available before returning. If it fails
for any reason an exception is thrown. In this way you can be sure that Consul
is ready for service if this method returns successfully.

=head2 stop

    $tc->stop();

Kill the Consul instance. Graceful shutdown is attempted first, and if it
doesn't die within a couple of seconds, the process is killed.

This method is also called if the instance of this class falls out of scope.

=head1 CLASS METHODS

See also L</start> which acts as both a class and instance method.

=head2 found_bin

Return the value of the C<CONSUL_BIN> env var, if set, or uses L<File::Which>
to search the system for an installed binary.  Returns C<undef> if no consul
binary could be found.

=head2 skip_all_if_no_bin

    Test::Consul->skip_all_if_no_bin;

This class method issues a C<skip_all> on the main package if the
consul binary could not be found (L</found_bin> returns false).

=head1 SEE ALSO

=over 4

=item *

L<Consul> - Consul client library. Uses L<Test::Consul> in its test suite.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Consul-Test/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Consul-Test>

  git clone https://github.com/robn/Consul-Test.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Aran Deltac <bluefeet@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
