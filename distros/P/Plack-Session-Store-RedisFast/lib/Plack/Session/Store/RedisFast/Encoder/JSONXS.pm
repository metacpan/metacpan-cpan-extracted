package Plack::Session::Store::RedisFast::Encoder::JSONXS;

use strict;
use warnings;

use 5.008_005;

use JSON::XS ();

sub new {
    return JSON::XS->new->utf8->allow_nonref;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Session::Store::RedisFast::JSONXS - L<JSON::XS> adapter for Redis session store.

=head1 DESCRIPTION

L<JSON::XS>-based implementation of L<Plack::Session::Store::RedisFast/inflate>
and L<Plack::Session::Store::RedisFast/deflate>.

=head1 SYNOPSIS

    use Plack::Session::Store::RedisFast::JSONXS;

    my $encoder = Plack::Session::Store::RedisFast::JSONXS->new;

    my $bytes = $encoder->encode( $hashref );

    my $hashref2 = $encoder->decode( $bytes );

=head1 DESCRIPTION

Used by default.

=head1 METHODS

=head2 new

    Plack::Session::Store::RedisFast::JSONXS->new;

=cut
