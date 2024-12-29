package Mojo::UserAgent::Role::Retry 0.002;

# ABSTRACT: Retry requests on failure

use Mojo::Base -role;

use HTTP::Date qw(str2time);


use constant DEBUG => $ENV{MOJO_CLIENT_DEBUG} || 0;

my $_TX_ROLE_RETRY = "Mojo::Transaction::HTTP::Role::Retry";


has retries        => 5;
has retry_wait_min => 1;
has retry_wait_max => 20;
has retry_policy   => sub {
  return sub {
    my $tx = shift;
    if ( $tx->error
      || ( $tx->res->code && ( $tx->res->code == 429 || $tx->res->code == 503 ) ) )
    {
      return 0;
    }
    return 1;
  };
};

around build_tx => sub {
  my ( $orig, $self, @args ) = @_;
  return $self->$orig(@args)->with_roles($_TX_ROLE_RETRY)->retries(0);
};

around start => sub {
  my ( $orig, $self, $tx, $cb ) = @_;

  if ( !eval { $tx->does($_TX_ROLE_RETRY) } ) {
    return $self->$orig( $tx, $cb );
  }

  if ( $tx->retries > 0 ) {
    my $remaining = $self->retries - $tx->retries;
    warn "-- Remaining retries: $remaining" if DEBUG;
  }

  if ( !$cb ) {
    $self->$orig($tx);
    if ( $self->retry_policy->($tx) )     { return $tx; }
    if ( $tx->retries >= $self->retries ) { return $tx; }
    sleep $self->_retry_wait_time($tx);
    my $new_tx = Mojo::Transaction::HTTP->with_roles($_TX_ROLE_RETRY)
      ->new->req( $tx->req->clone )->retries( $tx->retries + 1 );
    return $self->start( $new_tx, $cb );
  }

  return $self->$orig(
    $tx => sub {
      my ( $ua, $tx ) = @_;
      if ( $self->retry_policy->($tx) )     { return $cb->( $ua, $tx ); }
      if ( $tx->retries >= $self->retries ) { return $cb->( $ua, $tx ); }
      Mojo::IOLoop->timer(
        $self->_retry_wait_time($tx) => sub {
          my $new_tx = Mojo::Transaction::HTTP->with_roles($_TX_ROLE_RETRY)
            ->new->req( $tx->req->clone )->retries( $tx->retries + 1 );
          return $self->start( $new_tx, $cb );
        }
      );
    }
  );
};

sub _retry_wait_time {
  my ( $self, $tx ) = @_;
  my $wait = $self->retry_wait_min;
  if ( my $retry_after = $tx->res->headers->header('Retry-After') ) {
    $wait = _parse_retry_after($retry_after);
    if    ( $wait == 0 )                    { $wait = $self->retry_wait_min; }
    elsif ( $wait > $self->retry_wait_max ) { $wait = $self->retry_wait_max; }
  }
  return $wait;
}

sub _parse_retry_after {
  my $v = shift;
  if ( !defined $v )             { return 0; }
  if ( $v =~ /^\d+$/ && $v > 0 ) { return $v; }
  my $date = str2time($v);
  if ( !$date )       { return 0; }
  if ( $date < time ) { return 0; }
  return $date - time;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojo::UserAgent::Role::Retry - Retry requests on failure

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Mojo::UserAgent;
  use v5.10;

  my $ua = Mojo::UserAgent->with_roles('+Retry')->new;
  say $ua->get('https://www.perl.org/')->result->dom->at('title')->text;

=head1 DESCRIPTION

This role adds retry capabilities to L<Mojo::UserAgent> HTTP requests. By
default (see C<L</retry_policy>>), if a connection error is returned, or if a
C<429> or C<503> response code is received, then a retry is invoked after a
wait period.

=head1 ATTRIBUTES

L<Mojo::UserAgent::Role::Retry> adds the following attributes:

=head2 retries

Defaults to C<5>. The maximum number of retries. If after all retries, the
request still fails, then the last response is returned back to the caller to
interpret.

  my $ua = Mojo::UserAgent->with_roles('+Retry')->new(retries => 5);

=head2 retry_wait_min

Defaults to C<1>. The minimum wait time between retries in seconds. The
L<Retry-After|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>
header value from the response is used if it is greater than this value but
lower than C<retry_wait_max>.

  my $ua = Mojo::UserAgent->with_roles('+Retry')->new(retry_wait_min => 1);

=head2 retry_wait_max

Defaults to C<20>. The maximum wait time between retries in seconds. It's used
if the
L<Retry-After|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Retry-After>
header value from the response is greater than this value.

  my $ua = Mojo::UserAgent->with_roles('+Retry')->new(retry_wait_max => 20);

=head2 retry_policy

The policy to determine if a request should be retried. It must return a
subroutine that returns false if the request should be retried, or true
otherwise. On each invocation, the subroutine receives a new
L<Mojo::Transaction::HTTP> to evaluate.

By default, it retries on connection errors, C<429> and C<503> HTTP response
codes.

  my $ua = Mojo::UserAgent->with_roles('+Retry')->new(retry_policy => sub {
    # Retry on 418 HTTP response codes
    return sub {
      if (shift->res->code == 418) { return 0; }
      return 1;
    }
  });

=head1 SEE ALSO

L<Mojolicious::UserAgent>, L<Mojolicious>, L<Mojolicious::Guides>,
L<https://mojolicious.org>.

=head1 AUTHOR

Christian Segundo <ssmn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Christian Segundo <ssmn@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
