package Net::DAAP::Client::v2;
use strict;
use warnings;
use Digest::MD5;

my @seeds;
sub validate {
    my $self = shift;
    my ($url, $select) = @_;
    unless (@seeds) {
        for my $i (0..255) {
            my $ctx = Digest::MD5->new;
            $ctx->add( $i & 0x80 ? "Accept-Language"     : "user-agent"    );
            $ctx->add( $i & 0x40 ? "max-age"             : "Authorization" );
            $ctx->add( $i & 0x20 ? "Client-DAAP-Version" : "Accept-Encoding" );
            $ctx->add( $i & 0x10 ? "daap.protocolversion": "daap.songartist" );
            $ctx->add( $i & 0x08 ? "daap.songcomposer"   : "daap.songdatemodified" );
            $ctx->add( $i & 0x04 ? "daap.songdiscnumber" : "daap.songdisabled" );
            $ctx->add( $i & 0x02 ? "playlist-item-spec"  : "revision-number" );
            $ctx->add( $i & 0x01 ? "session-id"          : "content-codes" );
            push @seeds, uc $ctx->hexdigest;
        }
    }

    my $ctx = Digest::MD5->new;
    $ctx->add( $url );
    $ctx->add( "Copyright 2003 Apple Computer, Inc." );
    $ctx->add( $seeds[ $select ]);
    return uc $ctx->hexdigest;
}


1;

