package Test::Consul;
$Test::Consul::VERSION = '0.015';
# ABSTRACT: Run a consul server for testing

use 5.010;
use namespace::autoclean;

use File::Which qw(which);
use JSON::MaybeXS qw(JSON encode_json);
use Path::Tiny;
use POSIX qw(WNOHANG);
use Carp qw(croak);
use HTTP::Tiny v0.014;
use Net::EmptyPort qw( check_port );
use File::Temp qw( tempfile );
use Scalar::Util qw( blessed );

use Moo;
use Types::Standard qw( Bool Enum Undef );
use Types::Common::Numeric qw( PositiveInt PositiveOrZeroInt );
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
        next if check_port( $current_port, 'tcp' );
        next if $udp_too and check_port( $current_port, 'udp' );
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

has node_name => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_node_name {
    state $node_num = 0;
    $node_num++;
    return "tc_node$node_num";
}

has datacenter => (
    is  => 'lazy',
    isa => NonEmptySimpleStr,
);
sub _build_datacenter {
    state $dc_num = 0;
    $dc_num++;
    return "tc_dc$dc_num";
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

has enable_remote_exec => (
    is      => 'ro',
    isa     => Bool,
);

has bin => (
    is => 'lazy',
    isa => NonEmptySimpleStr | Undef,
);
sub _build_bin {
    my ($self) = @_;
    return $self->found_bin;
}

has datadir => (
    is        => 'ro',
    isa       => NonEmptySimpleStr,
    predicate => 1,
);

has version => (
  is => 'lazy',
  isa => PositiveOrZeroInt,
  default => sub {
    my ($self) = @_;
    return $self->found_version;
  },
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

    # Make sure we have at least Consul 0.6.1 which supports the -dev option.
    unless ($self->version >= 6_001) {
        croak "consul not version 0.6.1 or newer";
    }

    my @opts;

    my %config = (
        node_name  => $self->node_name(),
        datacenter => $self->datacenter(),
        bind_addr  => '127.0.0.1',
        ports => {
            dns      => -1,
            http     => $self->port() + 0,
            https    => -1,
            serf_lan => $self->serf_lan_port() + 0,
            serf_wan => $self->serf_wan_port() + 0,
            server   => $self->server_port() + 0,
        },
    );

    # Version 0.7.0 reduced default performance behaviors in a way
    # that makese these tests slower to startup.  Override this and
    # make leadership election happen ASAP.
    if ($self->version >= 7_000) {
        $config{performance} = { raft_multiplier => 1 };
    }

    # gRPC health checks were added 1.0.5, and in dev mode are enabled and bind
    # to port 8502, which then clashes if you want to run up a second
    # Test::Consul. Just disable it.
    if ($self->version >= 1_000_005) {
      $config{ports}{grpc} = -1;
    }

    if ($self->enable_acls()) {
      if ($self->version >= 1_004_000) {
        croak "ACLs not supported with Consul >= 1.4.0"
      }

        $config{acl_master_token} = $self->acl_master_token();
        $config{acl_default_policy} = $self->acl_default_policy();
        $config{acl_datacenter} = $self->datacenter();
        $config{acl_token} = $self->acl_master_token();
    }

    if (defined $self->enable_remote_exec) {
        $config{disable_remote_exec} = $self->enable_remote_exec ? JSON->false : JSON->true;
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
      $configpath = path( ( tempfile(SUFFIX => '.json') )[1] );
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

sub wan_join {
    my ($self, $other) = @_;

    my $http = HTTP::Tiny->new(timeout => 10);
    my $port = $self->port;
    my $other_wan_port = $other->serf_wan_port;

    my $res = $http->put("http://127.0.0.1:$port/v1/agent/join/127.0.0.1:$other_wan_port?wan=1");
    unless ($res->{success}) {
        croak "WAN join failed: $res->{status} $res->{reason}"
    }
}

sub found_bin {
  state ($bin, $bin_searched_for);
  return $bin if $bin_searched_for;
  my $binpath = $ENV{CONSUL_BIN} || which "consul";
  $bin = $binpath if defined($binpath) && -x $binpath;
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

sub found_version {
  state ($version);
  return $version if defined $version;
  my $bin = found_bin();
  ($version) = qx{$bin version};
  if ($version and $version =~ m{v(\d+)\.(\d+)\.(\d+)}) {
    $version = sprintf('%03d%03d%03d', $1, $2, $3);
  }
  else {
    $version = 0;
  }
}

sub skip_all_unless_version {
    my ($class, $minver, $maxver) = @_;

    croak 'usage: Test::Consul->skip_all_unless_version($minver, [$maxver])'
      unless defined $minver;

    croak 'The skip_all_unless_version method may only be used if the plan ' .
          'function is callable on the main package (which Test::More ' .
          'and Test2::Tools::Basic provide)'
          if !main->can('plan');

    $class->skip_all_if_no_bin;

    my $version = $class->found_version;

    if (defined $maxver) {
      return if $minver <= $version && $maxver > $version;
      main::plan( skip_all => "Consul must be between version $minver and $maxver to run this test." );
    }
    else {
      return if $minver <= $version;
      main::plan( skip_all => "Consul must be version $minver or higher to run this test." );
    }
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

=head2 serf_lan_port

The TCP and UDP port for the Serf LAN.  Consul's default is C<8301>, but
this defaults to a random unused port.

=head2 serf_wan_port

The TCP and UDP port for the Serf WAN.  Consul's default is C<8302>, but
this defaults to a random unused port.

=head2 server_port

The TCP port for the RPC Server address.  Consul's default is C<8300>, but
this defaults to a random unused port.

=head2 node_name

The name of this node. If not provided, one will be generated.

=head2 datacenter

The name of the datacenter. If not provided, one will be generated.

=head2 enable_acls

Set this to true to enable ACLs. Note that Consul ACLs changed substantially in
Consul 1.4, and L<Test::Consul> has not yet been updated to support them. If
you try to enable them with Consul 1.4+, L<Test::Consul> will croak. See
L<https://github.com/robn/Test-Consul/issues/7> for more info.

=head2 acl_default_policy

Set this to either C<allow> or C<deny>. The default is C<allow>.
See L<https://www.consul.io/docs/agent/options.html#acl_default_policy> for more
information.

=head2 acl_master_token

If L</enable_acls> is true then this token will be used as the master
token.  By default this will be C<01234567-89AB-CDEF-GHIJ-KLMNOPQRSTUV>.

=head2 enable_acls

Set this to true to enable remote execution (off by default since Consul 0.8.0)

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

=head2 wan_join

    my $tc1 = Test::Consul->start;
    my $tc2 = Test::Consul->start;
    $tc1->wan_join($tc2);

Perform a WAN join to another L<Test::Consul> instance. Use this to test Consul
applications that operate across datacenters.

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

=head2 found_version

Return the version of the consul binary, by running the binary return by
L</found_bin> with the C<version> argument. Returns 0 if the version can't be
determined.

=head2 skip_all_unless_version

    Test::Consul->skip_all_unless_version($minver, [$maxver]);

This class method issues a C<skip_all> on the main package if the consul binary
is not between C<$minver> and C<$maxvar> (exclusive).

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

Rob N ★ <robn@robn.io>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Aran Deltac <bluefeet@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) (c) 2015 by Rob N ★ and was supported by FastMail
Pty Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
