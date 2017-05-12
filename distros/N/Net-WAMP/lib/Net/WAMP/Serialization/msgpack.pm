package Net::WAMP::Serialization::msgpack;

use strict;
use warnings;

use Data::MessagePack ();

#Ugh. These are necessary until this PR merges:
#https://github.com/msgpack/msgpack-perl/pull/34
use Clone ();
use Data::MessagePack::Boolean ();
use Data::Rmap ();
use Types::Serialiser ();
use Try::Tiny;

use constant {
    serialization => 'msgpack',
    websocket_data_type => 'binary',
};

sub stringify {
    my $to_pack = Clone::clone($_[0]);

    #Necessary until this merges:
    #https://github.com/bowman/Data-Rmap/pull/7
    #… though Data::Rmap is itself only needed because
    #of the Types::Serialiser problem in Data::MessagePack.
    while (1) {
        my $changed = 0;

        Data::Rmap::rmap_all(
            sub {
                if ( try { $_->isa('Types::Serialiser::Boolean') } ) {
                    $changed = 1;
                    $_ = $_ ? $Data::MessagePack::Boolean::true : $Data::MessagePack::Boolean::false;
                }

                $_;
            },
            $to_pack,
        );

        last if !$changed;
    }

    return Data::MessagePack->pack($to_pack);
}

sub parse {
    my $unpacked = Data::MessagePack->unpack(@_);

    #Ditto - gotta do this until that PR merges.
    while (1) {
        my $changed = 0;

        Data::Rmap::rmap(
            sub {
                if ( try { $_->isa('Data::MessagePack::Boolean') } ) {
                    $changed = 1;
                    $_ = $_ ? $Types::Serialiser::true : $Types::Serialiser::false;
                }
            },
            $unpacked,
        );

        last if !$changed;
    }

    return $unpacked;
}

1;
