package Plack::Session::Store::RedisFast::Encoder::JSON;

use strict;
use warnings;

use 5.008_005;

use JSON ();

sub new {
    return JSON->new->utf8->allow_nonref;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Session::Store::RedisFast::JSON - L<JSON> adapter for Redis session store.

=head1 DESCRIPTION

L<JSON>-based implementation of L<Plack::Session::Store::RedisFast/inflate>
and L<Plack::Session::Store::RedisFast/deflate>.

=head1 SYNOPSIS

    use Plack::Session::Store::RedisFast::JSON;

    my $encoder = Plack::Session::Store::RedisFast::JSON->new;

    my $bytes = $encoder->encode( $hashref );

    my $hashref2 = $encoder->decode( $bytes );

=head1 DESCRIPTION

Used by default when L<JSON::XS> and L<Mojo::JSON> are not available.

=head1 METHODS

=head2 new

    Plack::Session::Store::RedisFast::JSON->new;

=cut
