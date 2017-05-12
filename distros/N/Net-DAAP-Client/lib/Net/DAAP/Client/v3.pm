package Net::DAAP::Client::v3;
use strict;
use warnings;
use Digest::MD5::M4p;

# this is a translation of the GenerateHash function in hasher.c of
# libopendaap http://crazney.net/programs/itunes/authentication.html

my @seeds;
sub validate {
    my $self = shift;
    my ($url, $select, $sequence) = @_;
    unless (@seeds) {
        for my $i (0..255) {
            my $ctx = Digest::MD5::M4p->new;

            $ctx->add( $i & 0x40 ? "eqwsdxcqwesdc"      : "op[;lm,piojkmn" );
            $ctx->add( $i & 0x20 ? "876trfvb 34rtgbvc"  :  "=-0ol.,m3ewrdfv" );
            $ctx->add( $i & 0x10 ? "87654323e4rgbv "
                                 : "1535753690868867974342659792" );
            $ctx->add( $i & 0x08 ? "Song Name"          : "DAAP-CLIENT-ID:" );
            $ctx->add( $i & 0x04 ? "111222333444555"    : "4089961010" );
            $ctx->add( $i & 0x02 ? "playlist-item-spec" : "revision-number" );
            $ctx->add( $i & 0x01 ? "session-id"         : "content-codes" );
            $ctx->add( $i & 0x80 ? "IUYHGFDCXWEDFGHN"   : "iuytgfdxwerfghjm" );
            push @seeds, uc $ctx->hexdigest;
        }
    }

    my $ctx = Digest::MD5::M4p->new;
    $ctx->add( $url );
    $ctx->add( "Copyright 2003 Apple Computer, Inc." );
    $ctx->add( $seeds[ $select ]);
    $ctx->add( $sequence ) if $sequence;
    return uc $ctx->hexdigest;
}

1;
__END__
