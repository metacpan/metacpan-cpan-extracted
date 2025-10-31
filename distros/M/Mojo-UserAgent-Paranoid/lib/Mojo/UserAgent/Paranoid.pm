package Mojo::UserAgent::Paranoid 0.01;
use 5.020;
use Mojo::Base 'Mojo::UserAgent';
use Mojo::IOLoop::Client::Paranoid;

=head1 NAME

Mojo::UserAgent::Paranoid - paranoid user agent for fetching unknown URLs

=head1 SYNOPSIS

  my $io = Mojo::IOLoop->singleton;
  my $ua = Mojo::UserAgent::Paranoid->new(
      paranoid_dns => Net::DNS::Paranoid->new(
          blocked_hosts => [qr{\.dev.example\.com$}]
      ),
      ioloop       => $io,
  );

=cut

has 'paranoid_dns' => sub { Net::DNS::Paranoid->new() };

# Copied from Mojo::IOLoop::client() , and adapted to create a paranoid
# client instead
sub paranoid_client {
    my $self = shift;
    my $ioloop = shift;
    my $cb = pop;

  my $id     = $ioloop->_id;
  my $client = $ioloop->{out}{$id}{client} = Mojo::IOLoop::Client::Paranoid->new(
      paranoid_dns => $self->paranoid_dns,
  );
  weaken $ioloop;
  $client->on(
    connect => sub {
      delete $ioloop->{out}{$id}{client};
      my $stream = Mojo::IOLoop::Stream->new(pop);
      $ioloop->_stream($stream => $id);
      $ioloop->$cb(undef, $stream);
    }
  );
  $client->on(error => sub { $ioloop->_remove($id); $ioloop->$cb(pop, undef) });
  $client->connect(@_);
  return $id;
}

# Copied from Mojo::UserAgent, with the line ->client(...) changed to ->paranoid_client(...)
sub _connect {
  my ($self, $loop, $tx, $handle) = @_;
  my $t = $self->transactor;
  my ($proto, $host, $port) = $handle ? $t->endpoint($tx) : $t->peer($tx);
  my %options = (timeout => $self->connect_timeout);
  if   ($proto eq 'http+unix') { $options{path}             = $host }
  else                         { @options{qw(address port)} = ($host, $port) }
  $options{socket_options} = $self->socket_options;
  $options{handle}         = $handle if $handle;
  # SOCKS
  if ($proto eq 'socks') {
    @options{qw(socks_address socks_port)} = @options{qw(address port)};
    ($proto, @options{qw(address port)}) = $t->endpoint($tx);
    my $userinfo = $tx->req->via_proxy(0)->proxy->userinfo;
    @options{qw(socks_user socks_pass)} = split /:/, $userinfo if $userinfo;
  }
  # TLS
  if ($options{tls} = $proto eq 'https') {
    map { $options{"tls_$_"} = $self->$_ } qw(ca cert key);
    $options{tls_options} = $self->tls_options;
    $options{tls_options}{SSL_verify_mode} = 0x00 if $self->insecure;
  }
  weaken $self;
  my $id;
  return $id = $self->paranoid_client($loop,
    %options => sub {
      my ($loop, $err, $stream) = @_;
      # Connection error
      return unless $self;
      return $self->_error($id, $err) if $err;
      # Connection established
      $stream->on(timeout => sub { $self->_error($id, 'Inactivity timeout') });
      $stream->on(close   => sub { $self && $self->_finish($id, 1) });
      $stream->on(error   => sub { $self && $self->_error($id, pop) });
      $stream->on(read    => sub { $self->_read($id, pop) });
      $self->_process($id);
    }
  );
}

1;

=head1 SEE ALSO

L<Mojo::UserAgent>

L<Net::DNS::Paranoid>

=cut
