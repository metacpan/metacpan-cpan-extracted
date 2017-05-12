package Mojo::SNMP;
use Mojo::Base 'Mojo::EventEmitter';
use Mojo::IOLoop;
use Mojo::SNMP::Dispatcher;
use Net::SNMP    ();
use Scalar::Util ();
use constant DEBUG => $ENV{MOJO_SNMP_DEBUG} ? 1 : 0;
use constant MAXREPETITIONS => 10;

our $VERSION = '0.12';

my $DISPATCHER;
my @EXCLUDE_METHOD_ARGS = qw( maxrepetitions );
my %EXCLUDE             = (
  v1  => [qw( username authkey authpassword authprotocol privkey privpassword privprotocol )],
  v2c => [qw( username authkey authpassword authprotocol privkey privpassword privprotocol )],
  v3  => [qw( community )],
);

my %SNMP_METHOD;
__PACKAGE__->add_custom_request_method(bulk_walk => \&_snmp_method_bulk_walk);
__PACKAGE__->add_custom_request_method(walk      => \&_snmp_method_walk);

$Net::SNMP::DISPATCHER = $Net::SNMP::DISPATCHER;    # avoid warning

has concurrent     => 20;
has defaults       => sub { +{} };
has master_timeout => 0;
has ioloop         => sub { Mojo::IOLoop->singleton };

# these attributes are experimental and therefore not exposed. Let me know if
# you use them...
has _dispatcher => sub { $DISPATCHER ||= Mojo::SNMP::Dispatcher->new(ioloop => shift->ioloop) };

sub add_custom_request_method {
  my ($class, $name, $cb) = @_;
  $SNMP_METHOD{$name} = $cb;
  $class;
}

sub prepare {
  my $cb    = ref $_[-1] eq 'CODE' ? pop : undef;       # internal usage. might change
  my $self  = shift;
  my $hosts = ref $_[0] eq 'ARRAY' ? shift : [shift];
  my $args  = ref $_[0] eq 'HASH' ? shift : {};
  my %args  = %$args;

  $hosts = [keys %{$self->{sessions} || {}}] if $hosts->[0] and $hosts->[0] eq '*';

  defined $args{$_} or $args{$_} = $self->defaults->{$_} for keys %{$self->defaults};
  $args{version} = $self->_normalize_version($args{version} || '');
  delete $args{$_} for @{$EXCLUDE{$args{version}}}, @EXCLUDE_METHOD_ARGS;
  delete $args{stash};

HOST:
  for my $key (@$hosts) {
    my ($host) = $key =~ /^([^|]+)/;
    local $args{hostname} = $host;
    my $key = $key eq $host ? $self->_calculate_pool_key(\%args) : $key;
    $self->{sessions}{$key} ||= $self->_new_session(\%args) or next HOST;

    local @_ = @_;
    while (@_) {
      my $method = shift;
      my $oid = ref $_[0] eq 'ARRAY' ? shift : [shift];
      push @{$self->{queue}{$key}}, [$key, $method, $oid, $args, $cb];
    }
  }

  $self->{n_requests} ||= 0;

  for ($self->{n_requests} .. $self->concurrent - 1) {
    my $queue = $self->_dequeue or last;
    $self->_prepare_request($queue);
  }

  $self->_setup if !$self->{_setup}++ and $self->ioloop->is_running;
  $self;
}

sub wait {
  my $self   = shift;
  my $ioloop = $self->ioloop;
  my $stop;

  $stop = sub {
    $_[0]->unsubscribe(finish  => $stop);
    $_[0]->unsubscribe(timeout => $stop);
    $ioloop->stop;
    undef $stop;
  };

  $self->_setup unless $self->{_setup}++;
  $self->once(finish  => $stop);
  $self->once(timeout => $stop);
  $ioloop->start;
  $self;
}

for my $method (qw( get get_bulk get_next set walk bulk_walk )) {
  eval <<"HERE" or die $@;
    sub $method {
      my(\$self, \$host) = (shift, shift);
      my \$args = ref \$_[0] eq 'HASH' ? shift : {};
      \$self->prepare(\$host, \$args, $method => \@_);
    }
    1;
HERE
}

sub _calculate_pool_key {
  join '|', map { defined $_[1]->{$_} ? $_[1]->{$_} : '' } qw( hostname version community username );
}

sub _dequeue {
  my $self = shift;
  my $key = (keys %{$self->{queue} || {}})[0] or return;
  return delete $self->{queue}{$key};
}

sub _finish {
  warn "[Mojo::SNMP] Finish\n" if DEBUG;
  $_[0]->emit('finish');
  $_[0]->{_setup} = 0;
}

sub _new_session {
  my ($self, $args) = @_;
  my ($session, $error) = Net::SNMP->new(%$args, nonblocking => 1);

  warn "[Mojo::SNMP] New session $args->{hostname}: ", ($error || 'OK'), "\n" if DEBUG;
  Mojo::IOLoop->next_tick(sub { $self->emit(error => "$args->{hostname}: $error") }) if $error;
  $session;
}

sub _normalize_version {
  $_[1] =~ /1/ ? 'v1' : $_[1] =~ /3/ ? 'v3' : 'v2c';
}

sub _prepare_request {
  my ($self, $queue) = @_;
  my $item = shift @$queue;

  unless ($item) {
    $queue = $self->_dequeue or return;
    $item = shift @$queue;
  }

  my ($key, $method, $list, $args, $cb) = @$item;
  my $session = $self->{sessions}{$key};
  my ($error, $success);

  # dispatch to our mojo based dispatcher
  $Net::SNMP::DISPATCHER = $self->_dispatcher;

  unless ($session->transport) {
    warn "[Mojo::SNMP] <<< open connection\n" if DEBUG;
    unless ($session->open) {
      Mojo::IOLoop->next_tick(
        sub {
          return $self->$cb($session->error, undef) if $cb;
          return $self->emit(error => $session->error, $session, $args);
        },
      );
      return $self->{n_requests} || '0e0';
    }
  }

  warn "[Mojo::SNMP] <<< $method $key @$list\n" if DEBUG;
  Scalar::Util::weaken($self);
  $method = $SNMP_METHOD{$method} || "$method\_request";
  $success = $session->$method(
    $method =~ /bulk/ ? (maxrepetitions => $args->{maxrepetitions} || MAXREPETITIONS) : (),
    ref $method ? (%$args) : (),
    varbindlist => $list,
    callback    => sub {
      my $session = shift;

      eval {
        local @$args{qw( method request )} = @$item[1, 2];
        $self->{n_requests}--;
        if ($session->var_bind_list) {
          warn "[Mojo::SNMP] >>> success: $method $key @$list\n" if DEBUG;
          return $self->$cb('', $session) if $cb;
          return $self->emit(response => $session, $args);
        }
        else {
          warn "[Mojo::SNMP] >>> error: $method $key @{[$session->error]}\n" if DEBUG;
          return $self->$cb($session->error, undef) if $cb;
          return $self->emit(error => $session->error, $session, $args);
        }
        1;
      } or do {
        $self->emit(error => $@);
      };
      warn "[Mojo::SNMP] n_requests: $self->{n_requests}\n" if DEBUG;
      $self->_prepare_request($queue);
      warn "[Mojo::SNMP] n_requests: $self->{n_requests}\n" if DEBUG;
      $self->_finish unless $self->{n_requests};
    },
  );

  return ++$self->{n_requests} if $success;
  $self->emit(error => $session->error, $session);
  return $self->{n_requests} || '0e0';
}

sub _setup {
  my $self = shift;
  my $timeout = $self->master_timeout or return;
  my $tid;

  warn "[Mojo::SNMP] Timeout: $timeout\n" if DEBUG;
  Scalar::Util::weaken($self);

  $tid = $self->ioloop->timer(
    $timeout => sub {
      warn "[Mojo::SNMP] Timeout\n" if DEBUG;
      $self->ioloop->remove($tid);
      $self->emit('timeout');
      $self->{_setup} = 0;
    }
  );
}

sub _snmp_method_bulk_walk {
  my ($session, %args) = @_;
  my $base_oid       = $args{varbindlist}[0];
  my $last           = $args{callback};
  my $maxrepetitions = $args{maxrepetitions} || MAXREPETITIONS;
  my ($callback, $end, %tree, %types);

  $end = sub {
    if (scalar keys %tree) {
      $session->pdu->var_bind_list(\%tree, \%types);
    }
    else {
      $session->pdu->var_bind_list({$base_oid => 'noSuchObject'}, {$base_oid => Net::SNMP::NOSUCHOBJECT});
    }
    $session->$last;
    $end = $callback = undef;
  };

  $callback = sub {
    my ($session) = @_;
    my $res     = $session->var_bind_list    or return $end->();
    my @sortres = $session->var_bind_names() or return $end->();
    my $types   = $session->var_bind_types;
    my $next    = $sortres[-1];

    for my $oid (@sortres) {
      return $end->() if $types{$oid} or !Net::SNMP::oid_base_match($base_oid, $oid);
      $types{$oid} = $types->{$oid};
      $tree{$oid}  = $res->{$oid};
    }

    return $end->() unless $next;
    return $session->get_bulk_request(maxrepetitions => $maxrepetitions, varbindlist => [$next], callback => $callback);
  };

  $session->get_bulk_request(maxrepetitions => $maxrepetitions, varbindlist => [$base_oid], callback => $callback);
}

sub _snmp_method_walk {
  my ($session, %args) = @_;
  my $base_oid = $args{varbindlist}[0];
  my $last     = $args{callback};
  my ($callback, $end, %tree, %types);

  $end = sub {
    $session->pdu->var_bind_list(\%tree, \%types) if %tree;
    $session->$last;
    $end = $callback = undef;
  };

  $callback = sub {
    my ($session) = @_;
    my $res = $session->var_bind_list or return $end->();
    my $types = $session->var_bind_types;
    my @next;

    for my $oid (keys %$res) {
      if (!$types{$oid} and Net::SNMP::oid_base_match($base_oid, $oid)) {
        $types{$oid} = $types->{$oid};
        $tree{$oid}  = $res->{$oid};
        push @next, $oid;
      }
    }

    return $end->() unless @next;
    return $session->get_next_request(varbindlist => \@next, callback => $callback);
  };

  $session->get_next_request(varbindlist => [$base_oid], callback => $callback);
}

1;

=encoding utf8

=head1 NAME

Mojo::SNMP - Run SNMP requests with Mojo::IOLoop

=head1 VERSION

0.12

=head1 SYNOPSIS

  use Mojo::SNMP;
  my $snmp = Mojo::SNMP->new;
  my @response;

  $snmp->on(response => sub {
    my($snmp, $session, $args) = @_;
    warn "Got response from $args->{hostname} on $args->{method}(@{$args->{request}})...\n";
    push @response, $session->var_bind_list;
  });

  $snmp->defaults({
    community => 'public', # v1, v2c
    username => 'foo', # v3
    version => 'v2c', # v1, v2c or v3
  });

  $snmp->prepare('127.0.0.1', get_next => ['1.3.6.1.2.1.1.3.0']);
  $snmp->prepare('localhost', { version => 'v3' }, get => ['1.3.6.1.2.1.1.3.0']);

  # start the IOLoop unless it is already running
  $snmp->wait unless $snmp->ioloop->is_running;

=head1 DESCRIPTION

You should use this module if you need to fetch data from many SNMP servers
really fast. The module does its best to not get in your way, but rather
provide a simple API which allow you to extract information from multiple
servers at the same time.

This module use L<Net::SNMP> and L<Mojo::IOLoop> to fetch data from hosts
asynchronous. It does this by using a custom dispatcher,
L<Mojo::SNMP::Dispatcher>, which attach the sockets created by L<Net::SNMP>
directly into the ioloop reactor.

If you want greater speed, you should check out L<Net::SNMP::XS> and make sure
L<Mojo::Reactor::EV> is able to load.

L<Mojo::SNMP> is supposed to be a replacement for a module I wrote earlier,
called L<SNMP::Effective>. Reason for the rewrite is that I'm using the
framework L<Mojolicious> which includes an awesome IO loop which allow me to
do cool stuff inside my web server.

=head1 CUSTOM SNMP REQUEST METHODS

L<Net::SNMP> provide methods to retrieve data from the SNMP agent, such as
L<get_next()|Net::SNMP/get_next>. It is possible to add custom methods if
you find yourself doing the same complicated logic over and over again.
Such methods can be added using L</add_custom_request_method>.

There are two custom methods bundled to this package:

=over 4

=item * bulk_walk

This method will run C<get_bulk_request> until it receives an oid which does
not match the base OID. maxrepetitions is set to 10 by default, but could be
overrided by maxrepetitions inside C<%args>.

Example:

  $self->prepare('192.168.0.1' => { maxrepetitions => 25 }, bulk_walk => [$oid, ...]);

=item * walk

This method will run C<get_next_request> until the next oid retrieved does
not match the base OID or if the tree is exhausted.

=back

=head1 EVENTS

=head2 error

  $self->on(error => sub {
    my($self, $str, $session, $args) = @_;
  });

Emitted on errors which may occur. C<$session> is set if the error is a result
of a L<Net::SNMP> method, such as L<get_request()|Net::SNMP/get_request>.

See L</response> for C<$args> description.

=head2 finish

  $self->on(finish => sub {
    my $self = shift;
  });

Emitted when all hosts have completed.

=head2 response

  $self->on(response => sub {
    my($self, $session, $args) = @_;
  });

Called each time a host responds. The C<$session> is the current L<Net::SNMP>
object. C<$args> is a hash ref with the arguments given to L</prepare>, with
some additional information:

  {
    method => $str, # get, get_next, ...
    request => [$oid, ...],
    # ...
  }

=head2 timeout

  $self->on(timeout => sub {
    my $self = shift;
  })

Emitted if L<wait> has been running for more than L</master_timeout> seconds.

=head1 ATTRIBUTES

=head2 concurrent

How many hosts to fetch data from at once. Default is 20. (The default may
change in later versions)

=head2 defaults

This attribute holds a hash ref with default arguments which will be passed
on to L<Net::SNMP/session>. User-submitted C<%args> will be merged with the
defaults before being submitted to L</prepare>. C<prepare()> will filter out
and ignore arguments that don't work for the SNMP C<version>.

NOTE: SNMP version will default to "v2c".

=head2 master_timeout

How long to run in total before timeout. Note: This is NOT per host but for
the complete run. Default is 0, meaning run for as long as you have to.

=head2 ioloop

Holds an instance of L<Mojo::IOLoop>.

=head1 METHODS

=head2 add_custom_request_method

  $self->add_custom_request_method(name => sub {
    my($session, %args) = @_;
    # do custom stuff..
  });

This method can be used to add custom L<Net::SNMP> request methods. See the
source code for an example on how to do "walk".

NOTE: This method will also replace any method, meaning the code below will
call the custom callback instead of L<Net::SNMP/get_next_request>.

  $self->add_custom_request_method(get_next => $custom_callback);

=head2 get

  $self->get($host, $args, \@oids, sub {
    my($self, $err, $res) = @_;
    # ...
  });

Will call the callback when data is retrieved, instead of emitting the
L</response> event.

=head2 get_bulk

  $self->get_bulk($host, $args, \@oids, sub {
    my($self, $err, $res) = @_;
    # ...
  });

Will call the callback when data is retrieved, instead of emitting the
L</response> event. C<$args> is optional.

=head2 get_next

  $self->get_next($host, $args, \@oids, sub {
    my($self, $err, $res) = @_;
    # ...
  });

Will call the callback when data is retrieved, instead of emitting the
L</response> event. C<$args> is optional.

=head2 prepare

  $self = $self->prepare($host, \%args, ...);
  $self = $self->prepare(\@hosts, \%args, ...);
  $self = $self->prepare(\@hosts, ...);
  $self = $self->prepare('*' => ...);

=over 4

=item * $host

This can either be an array ref or a single host. The "host" can be whatever
L<Net::SNMP/session> can handle; generally a hostname or IP address.

=item * \%args

A hash ref of options which will be passed directly to L<Net::SNMP/session>.
This argument is optional. See also L</defaults>.

=item * dot-dot-dot

A list of key-value pairs of SNMP operations and bindlists which will be given
to L</prepare>. The operations are the same as the method names available in
L<Net::SNMP>, but without "_request" at end:

  get
  get_next
  set
  get_bulk
  inform
  walk
  bulk_walk
  ...

The special hostname "*" will apply the given operation to all previously
defined hosts.

=back

Examples:

  $self->prepare('192.168.0.1' => { version => 'v2c' }, get_next => [$oid, ...]);
  $self->prepare('192.168.0.1' => { version => 'v3' }, get => [$oid, ...]);
  $self->prepare(localhost => set => [ $oid => OCTET_STRING, $value, ... ]);
  $self->prepare('*' => get => [ $oid ... ]);

Note: To get the C<OCTET_STRING> constant and friends you need to do:

  use Net::SNMP ':asn1';

=head2 set

  $self->set($host, $args => [ $oid => OCTET_STRING, $value, ... ], sub {
    my($self, $err, $res) = @_;
    # ...
  });

Will call the callback when data is set, instead of emitting the
L</response> event. C<$args> is optional.

=head2 walk

  $self->walk($host, $args, \@oids, sub {
    my($self, $err, $res) = @_;
    # ...
  });

Will call the callback when data is retrieved, instead of emitting the
L</response> event. C<$args> is optional.

=head2 bulk_walk

  $self->bulk_walk($host, $args, \@oids, sub {
    my($self, $err, $res) = @_;
    # ...
  });

Will call the callback when data is retrieved, instead of emitting the
L</response> event. C<$args> is optional.

=head2 wait

This is useful if you want to block your code: C<wait()> starts the ioloop and
runs until L</timeout> or L</finish> is reached.

  my $snmp = Mojo::SNMP->new;
  $snmp->prepare(...)->wait; # blocks while retrieving data
  # ... your program continues after the SNMP operations have finished.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

=head1 CONTRIBUTORS

Espen Tallaksen - C<espen.tallaksen@telenor.com>

Joshua Keroes - C<joshua.keroes@integratelecom.com>

Oliver Gorwits - C<oliver@cpan.org>

Per Carlson - C<per.carlson@broadnet.no>

=head1 COPYRIGHT & LICENSE

Copyright (C) 2012-2016, L</AUTHOR> and L</CONTRIBUTORS>.

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
