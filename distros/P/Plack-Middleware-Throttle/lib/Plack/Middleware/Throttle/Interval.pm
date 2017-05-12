package Plack::Middleware::Throttle::Interval;

use Moose;
extends 'Plack::Middleware::Throttle';

has min => (is => 'rw', isa => 'Int', default => 0, lazy => 1);

sub allowed {
    my ($self, $key) = @_;

    my $t1 = time();
    my $t0 = $self->backend->get($key);
    $self->backend->set($key, $t1);

    if (!$t0 || ($t1 - $t0) > $self->min) {
        return 1;
    }else{
        return 0;
    }
}

sub cache_key {
    my ( $self, $env ) = @_;
    $self->client_identifier($env);
}

sub reset_time {
    time + 1;
}

1;
__END__

=head1 NAME

Plack::Middleware::Throttle::Interval - A Plack Middleware for rate-limiting incoming HTTP requests.

=head1 SYNOPSIS

  my $handler = builder {
    enable "Throttle::Interval",
        min     => 2,
        backend => Plack::Middleware::Throttle::Backend::Hash->new();
    sub { [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] };
  };

=head1 DESCRIPTION

How many request an host can do between an interval of time (in seconds).

=head1 OPTIONS

=over 4

=item B<min>

How many requets can be done in an interval of time.

=back

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

