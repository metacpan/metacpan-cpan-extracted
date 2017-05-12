package Plack::Middleware::Throttle::Daily;

use Moose;
extends 'Plack::Middleware::Throttle::Limiter';

sub cache_key {
    my ( $self, $env ) = @_;
    $self->client_identifier($env) . "_"
        . DateTime->now->strftime("%Y-%m-%d");
}

sub reset_time {
    my $dt = DateTime->now;
    (24 * 3600) - (( 60 * $dt->minute ) + $dt->second);
}

1;
__END__

=head1 NAME

Plack::Middleware::Throttle::Daily - A Plack Middleware for rate-limiting incoming HTTP requests.

=head1 SYNOPSIS

  my $handler = builder {
    enable "Throttle::Daily",
        max     => 2,
        backend => Plack::Middleware::Throttle::Backend::Hash->new();
    sub { [ '200', [ 'Content-Type' => 'text/html' ], ['hello world'] ] };
  };

=head1 DESCRIPTION

How many request an host can do in one day.

=head1 OPTIONS

=over 4

=item B<max>

How many requets can be done in one day.

=back

=head1 AUTHOR

franck cuny E<lt>franck@lumberjaph.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

