package Plack::Session::Store::RedisFast::Encoder::MojoJSON;

use strict;
use warnings;

use 5.008_005;

use Mojo::JSON qw( decode_json encode_json );

sub new {
    my ($class) = @_;

    bless {}, $class;
}

sub encode {
    my ( $self, $thing ) = @_;

    encode_json($thing);
}

sub decode {
    my ( $self, $bytes ) = @_;

    decode_json($bytes);
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Plack::Session::Store::RedisFast::MojoJSON - L<Mojo::JSON> adapter for Redis session store.

=head1 DESCRIPTION

L<Mojo::JSON>-based implementation of L<Plack::Session::Store::RedisFast/inflate>
and L<Plack::Session::Store::RedisFast/deflate>.

=head1 SYNOPSIS

    use Plack::Session::Store::RedisFast::MojoJSON;

    my $encoder = Plack::Session::Store::RedisFast::MojoJSON->new;

    my $bytes = $encoder->encode( $hashref );

    my $hashref2 = $encoder->decode( $bytes );

=head1 DESCRIPTION

Used by default when L<JSON::XS> is not available.

=head1 METHODS

=head2 new

    Plack::Session::Store::RedisFast::MojoJSON->new;

=cut
