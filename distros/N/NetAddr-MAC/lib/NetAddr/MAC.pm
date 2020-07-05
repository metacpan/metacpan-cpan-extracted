#!/bin/false
# ABSTRACT: MAC hardware address functions and object (EUI48 and EUI64)

use strict;
use warnings;
use v5.10;
package NetAddr::MAC;
$NetAddr::MAC::VERSION = '0.97';

use Carp qw( croak );
use List::Util qw( first );

use constant EUI48LENGTHHEX => 12;
use constant EUI48LENGTHDEC => 6;
use constant EUI64LENGTHHEX => 16;
use constant EUI64LENGTHDEC => 8;

use constant ETHER2TOKEN => (
## see also http://www-01.ibm.com/support/docview.wss?uid=nas114157020a771b25d862567250003b62c
## note this table is rotated compared to the above link,
## so that the hex values line up as a linear array :)
## 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
    qw(00 80 40 c0 20 a0 60 e0 10 90 50 d0 30 b0 70 f0),    # 0
    qw(08 88 48 c8 28 a8 68 e8 18 98 58 d8 38 b8 78 f8),    # 1
    qw(04 84 44 c4 24 a4 64 e4 14 94 54 d4 34 b4 74 f4),    # 2
    qw(0c 8c 4c cc 2c ac 6c ec 1c 9c 5c dc 3c bc 7c fc),    # 3
    qw(02 82 42 c2 22 a2 62 e2 12 92 52 d2 32 b2 72 f2),    # 4
    qw(0a 8a 4a ca 2a aa 6a ea 1a 9a 5a da 3a ba 7a fa),    # 5
    qw(06 86 46 c6 26 a6 66 e6 16 96 56 d6 36 b6 76 f6),    # 6
    qw(0e 8e 4e ce 2e ae 6e ee 1e 9e 5e de 3e be 7e fe),    # 7
    qw(01 81 41 c1 21 a1 61 e1 11 91 51 d1 31 b1 71 f1),    # 8
    qw(09 89 49 c9 29 a9 69 e9 19 99 59 d9 39 b9 79 f9),    # 9
    qw(05 85 45 c5 25 a5 65 e5 15 95 55 d5 35 b5 75 f5),    # a
    qw(0d 8d 4d cd 2d ad 6d ed 1d 9d 5d dd 3d bd 7d fd),    # b
    qw(03 83 43 c3 23 a3 63 e3 13 93 53 d3 33 b3 73 f3),    # c
    qw(0b 8b 4b cb 2b ab 6b eb 1b 9b 5b db 3b bb 7b fb),    # d
    qw(07 87 47 c7 27 a7 67 e7 17 97 57 d7 37 b7 77 f7),    # e
    qw(0f 8f 4f cf 2f af 6f ef 1f 9f 5f df 3f bf 7f ff),    # f
);

use base qw( Exporter );
use vars qw( %EXPORT_TAGS );

%EXPORT_TAGS = (
    all => [
        qw(
          mac_is_eui48     mac_is_eui64
          mac_is_unicast   mac_is_multicast
          mac_is_broadcast mac_is_vrrp
          mac_is_hsrp      mac_is_hsrp2
          mac_is_msnlb
          mac_is_local     mac_is_universal
          mac_as_basic     mac_as_sun
          mac_as_microsoft mac_as_cisco
          mac_as_bpr       mac_as_ieee
          mac_as_ipv6_suffix
          mac_as_tokenring mac_as_singledash
          mac_as_pgsql
          )
    ],
    properties => [
        qw(
          mac_is_eui48     mac_is_eui64
          mac_is_unicast   mac_is_multicast
          mac_is_broadcast mac_is_vrrp
          mac_is_hsrp      mac_is_hsrp2
          mac_is_msnlb
          mac_is_local     mac_is_universal
          )
    ],
    normals => [
        qw(
          mac_as_basic     mac_as_sun
          mac_as_microsoft mac_as_cisco
          mac_as_bpr       mac_as_ieee
          mac_as_ipv6_suffix
          mac_as_tokenring mac_as_singledash
          mac_as_pgsql
          )
    ],
);

Exporter::export_ok_tags( keys %EXPORT_TAGS );


sub new {

    my ( $p, @q ) = @_;
    my $c = ref($p) || $p;
    my $self = bless {}, $c;

    # clear the errstr, see also RT96045
    $NetAddr::MAC::errstr = undef;

    unless (@q) {
        my $e = q|Please provide a mac address|;
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    # massage a single argument into a mac argument if needed
    $self->_init( @q % 2 ? ( mac => shift @q, @q ) : @q )
      or return;

    return $self

}

{

    my $_die;

    sub _init {

        my ( $self, %args ) = @_;

        if ( defined $args{die_on_error} ) {
            $self->{_die}++ if $args{die_on_error};
        }
        else {
            $self->{_die}++ if $NetAddr::MAC::die_on_error;
        }

        $_die++ if $self->{_die};

        $self->{original} = $args{mac};

        if ($args{mac} =~ m/^(\d+)\#(.+)$/ ) {
            $self->{priority} = $1;
            $args{mac} = $2;
        }

        $self->{mac} = _mac_to_integers( $args{mac} );

        unless ( $self->{mac} ) {
            croak $NetAddr::MAC::errstr . "\n" if $self->{_die};
            return
        }

        if (defined $self->{priority}) {
            if ($args{priority} and $args{priority} != $self->{priority}) {
                my $e = "Conflicting priority in '$self->{original}' and priority argument $args{priority}";
                croak "$e\n" if $self->{_die};
                $NetAddr::MAC::errstr = $e;
                return
            }
        }
        else {
            $self->{priority} = $args{priority} || 0;
        }

        # check none of the list elements are empty
        if (first { not defined $_ or 0 == length $_} @{$self->{mac}}) {
            my $e = "Invalid MAC format '$self->{original}'";
            croak "$e\n" if $self->{_die};
            $NetAddr::MAC::errstr = $e;
            return
        }

        return 1

    }

    sub _mac_to_integers {

        my $mac = shift;
        my $e;

        for (1) {

            unless ($mac) {
                $e = 'Please provide a mac address';
                last;
            }

            # be nice, strip leading and trailing whitespace
            $mac =~ s/^\s+//;
            $mac =~ s/\s+$//;

            $mac =~ s{^1,\d,}{}
              ; # blindly remove the prefix from bpr, we could check that \d is the actual length, but oh well

            # avoid matching ipv6
            last if $mac =~ m/[a-f0-9]{1,4}:[a-f0-9]{1,4}::([a-f0-9]{1,4})?/i;
            last if $mac =~ m/[a-f0-9]{1,4}::[a-f0-9]{1,4}:[a-f0-9]{1,4}/i;

            my @parts = grep { length } split( /[^a-z0-9]+/ix, $mac );

            # anything other than hex...
            last if ( first { m{[^a-f0-9]}i } @parts );

            # resolve wierd things like aabb.cc.00.11.22 or 11.22.33.aabbcc

            @parts = map {
                my $o = $_;
                (length($o) % 2) == 0 ? $o =~ m/(..)/g
                                      : $o
                } @parts;

            # 12 characters for EUI48, 16 for EUI64
            if (
                @parts == 1
                && (   length $parts[0] == EUI48LENGTHHEX
                    || length $parts[0] == EUI64LENGTHHEX )
              )
            {    # 0019e3010e72
                local $_ = shift(@parts);
                while (m{([a-f0-9]{2})}igx) { push( @parts, $1 ) }
                return [ map { hex($_) } @parts ]
            }

            # 00:19:e3:01:0e:72
            if ( @parts == EUI48LENGTHDEC || @parts == EUI64LENGTHDEC ) {
                return [ map { hex($_) } @parts ]
            }

            # 0019:e301:0e72
            if ( @parts == EUI48LENGTHDEC / 2 || @parts == EUI64LENGTHDEC / 2 )
            {
                # it would be nice to accept no leading 0's but this gives
                # problems detecting broken formatted macs.
                # cisco doesnt drop leading zeros so lets go for the least
                # edgey of the edge cases.
                last if (first {length $_ < 4} @parts);

                return [
                    map {
                        m{^ ([a-f0-9]{2}) ([a-f0-9]{2}) $}ix
                          && ( hex($1), hex($2) )
                    } @parts
                ];
            }

            last

        } # just so we can jump out

        $e ||= "Invalid MAC format '$mac'";

        if ( defined $_die ) {
            croak "$e\n" if $_die;
        }
        elsif ($NetAddr::MAC::die_on_error) {
            croak "$e\n";
        }

        $NetAddr::MAC::errstr = $e;

        return
    }

}


sub random {

    my ( $p, @q ) = @_;
    my $c = ref($p) || $p;
    my $self = bless {}, $c;

    # clear the errstr, see also RT96045
    $NetAddr::MAC::errstr = undef;

    unless (@q) {
        my $e = q|Please provide an oui prefix|;
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    die 'TODO';

    # massage a single argument into a mac argument if needed
    $self->_init( @q % 2 ? ( oui => shift @q, @q ) : @q )
      or return;

    return $self

}


sub original {

    my $self = shift;
    return $self->{original}

}


sub oui {

    my $self = shift;
    return uc join(
        q{-},
            map { sprintf( '%02x', $_ ) }
            @{ $self->{mac} }[0 .. 2]
        );

}


sub errstr {

    my $self = shift;
    return $NetAddr::MAC::errstr unless ref $self;
    return $self->{_errstr}

}


sub is_eui48 {
    my $self = shift;
    return scalar @{ $self->{mac} } == EUI48LENGTHDEC
}


sub is_eui64 {
    my $self = shift;
    return scalar @{ $self->{mac} } == EUI64LENGTHDEC
}


sub is_multicast {
    my $self = shift;

    return ($self->{mac}->[0] & 1) && ! is_broadcast($self);
}



sub is_broadcast {
    my $self = shift;

    for (@{$self->{mac}}) {
        return 0 if $_ != 255
    }
    return 1
}


sub is_vrrp {
    my $self = shift;

    return
        is_eui48($self) &&
        $self->{mac}->[0] == 0 &&
        $self->{mac}->[1] == 0 &&
        $self->{mac}->[2] == hex('0x5e') &&
        $self->{mac}->[3] == 0 &&
        $self->{mac}->[4] == 1;

}


sub is_hsrp {
    my $self = shift;

    return
        is_eui48($self) &&
        $self->{mac}->[0] == 0 &&
        $self->{mac}->[1] == 0 &&
        $self->{mac}->[2] == hex('0xc') &&
        $self->{mac}->[3] == 7 &&
        $self->{mac}->[4] == hex('0xac');

}


sub is_hsrp2 {
    my $self = shift;

    return
        is_eui48($self) &&
        $self->{mac}->[0] == 0 &&
        $self->{mac}->[1] == 0 &&
        $self->{mac}->[2] == hex('0xc') &&
        $self->{mac}->[3] == hex('0x9f');
        $self->{mac}->[4] >= 240; # 0xFX

}



sub is_msnlb {
    my $self = shift;

    return
        is_eui48($self) &&
        ($self->{mac}->[0] == 2
            || $self->{mac}->[0] == 3) &&
        $self->{mac}->[1] == hex('0xbf')

}


sub is_unicast {
    my $self = shift;
    return ! ($self->{mac}->[0] & 1);
}


sub is_local {
    my $self = shift;
    return $self->{mac}->[0] & 2
}


sub is_universal {
    my $self = shift;
    return !is_local($self)
}


sub as_basic {
    my $self = shift;
    return join( q{}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } )
}


sub as_bridge_id {
    my $self = shift;
    return $self->{priority}
        . '#'
        . $self->as_cisco;
}


sub as_bpr {
    my $self = shift;
    return
        q{1,}
      . scalar @{ $self->{mac} } . q{,}
      . join( q{:}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } );
}


sub as_cisco {
    my $self = shift;
    return join( q{.},
        map { m{([a-f0-9]{4})}gxi }
          join( q{}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } ) )
}


sub as_ieee {
    my $self = shift;
    return join( q{:}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } )
}


sub as_ipv6_suffix {

    my $self = shift;
    my @tmpmac;

    # be slightly evil here, so that hashrefs and objects work
    if ( is_eui48($self) ) {

        # save this for later
        @tmpmac = @{ $self->{mac} };

        to_eui64($self);

    }

    my @suffix = ( @{ $self->{mac} }[0] ^ 0x02, @{ $self->{mac} }[ 1 .. 7 ] );

    # restore the eui48 if needed
    $self->{mac} = \@tmpmac if @tmpmac;

    return join(
        q{:},
        map {
            my $i = $_;
            $i *= 2;
            sprintf( '%02x%02x', $suffix[$i], $suffix[ $i + 1 ] )
        } 0 .. 3
    );
}


sub as_microsoft {
    my $self = shift;
    return join( q{-}, map { sprintf( '%02x', $_ ) } @{ $self->{mac} } )
}


sub as_pgsql {
    my $self = shift;

    # there may be a better way to do this
    my $len = scalar @{ $self->{mac} };
    return join(
        q{:},
        join( '',
            map { sprintf( '%02x', $_ ) }
              @{ $self->{mac} }[ 0 .. ( $len / 2 - 1 ) ] ),
        join( '',
            map { sprintf( '%02x', $_ ) }
              @{ $self->{mac} }[ ( $len / 2 ) .. ( $len - 1 ) ] ),
    );
}


sub as_singledash {
    my $self = shift;

    # there may be a better way to do this
    my $len = scalar @{ $self->{mac} };
    return join(
        q{-},
        join( '',
            map { sprintf( '%02x', $_ ) }
              @{ $self->{mac} }[ 0 .. ( $len / 2 - 1 ) ] ),
        join( '',
            map { sprintf( '%02x', $_ ) }
              @{ $self->{mac} }[ ( $len / 2 ) .. ( $len - 1 ) ] ),
    );
}


sub as_sun {
    my $self = shift;
    return join( q{-}, map { sprintf( '%01x', $_ ) } @{ $self->{mac} } )
}


sub as_tokenring {

    my $self = shift;
    return join( q{-}, map { (ETHER2TOKEN)[$_] } @{ $self->{mac} } )
}


sub to_eui48 {

    my $self = shift;

    # be slightly evil here, so that hashrefs and objects work
    if ( is_eui64($self) ) {
        if ( @{ $self->{mac} }[3] == 0xff
            and
            ( @{ $self->{mac} }[4] == 0xff or @{ $self->{mac} }[4] == 0xfe ) )
        {

            # convert to eui-48
            $self->{mac} = [ @{ $self->{mac} }[ 0 .. 2, 5 .. 7 ] ];
        }
        else {
            my $e = 'eui-64 address is not derived from an eui-48 address';
            croak "$e\n" if $self->{_die};
            $self->{_errstr} = $e;
            return
        }
    }

    return 1
}


sub to_eui64 {

    my $self = shift;

    # be slightly evil here so that hashrefs and objects work
    if ( is_eui48($self) ) {

        # convert to EUI64
        $self->{mac} = [
            @{ $self->{mac} }[ 0 .. 2 ],
            0xff,
            0xfe,
            @{ $self->{mac} }[ 3 .. 5 ]
        ];

    }
    else { return }

    return 1
}


sub mac_is_eui48 {

    my $mac = shift;
    croak 'please use is_eui48'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_eui48( { mac => $mac } )

}


sub mac_is_eui64 {

    my $mac = shift;
    croak 'please use is_eui64'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_eui64( { mac => $mac } )

}


sub mac_is_multicast {

    my $mac = shift;
    croak 'please use is_multicast'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_multicast( { mac => $mac } )

}



sub mac_is_broadcast {

    my $mac = shift;
    croak 'please use is_broadcast'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_broadcast( { mac => $mac } )

}


sub mac_is_unicast {

    my $mac = shift;
    croak 'please use is_unicast'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_unicast( { mac => $mac } )

}


sub mac_is_vrrp {

    my $mac = shift;
    croak 'please use is_vrrp'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;

        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_vrrp( { mac => $mac } )

}



sub mac_is_hsrp {

    my $mac = shift;
    croak 'please use is_hsrp'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;

        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_hsrp( { mac => $mac } )

}


sub mac_is_hsrp2 {

    my $mac = shift;
    croak 'please use is_hsrp2'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;

        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_hsrp2( { mac => $mac } )

}


sub mac_is_msnlb {

    my $mac = shift;
    croak 'please use is_msnlb'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;

        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_msnlb( { mac => $mac } )

}


sub mac_is_local {

    my $mac = shift;
    croak 'please use is_local'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_local( { mac => $mac } )

}


sub mac_is_universal {

    my $mac = shift;
    croak 'please use is_universal'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return is_universal( { mac => $mac } )

}


sub mac_as_basic {

    my $mac = shift;
    croak 'please use as_basic'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_basic( { mac => $mac } )

}


sub mac_as_bpr {

    my $mac = shift;
    croak 'please use as_basic'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_bpr( { mac => $mac } )

}


sub mac_as_cisco {

    my $mac = shift;
    croak 'please use as_cisco'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_cisco( { mac => $mac } )

}


sub mac_as_ieee {

    my $mac = shift;
    croak 'please use as_ieee'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_ieee( { mac => $mac } )

}


sub mac_as_ipv6_suffix {

    my $mac = shift;
    croak 'please use as_ipv6_suffix'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_ipv6_suffix( { mac => $mac } )

}


sub mac_as_microsoft {

    my $mac = shift;

    croak 'please use as_microsoft'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_microsoft( { mac => $mac } )

}


sub mac_as_pgsql {

    my $mac = shift;

    croak 'please use as_pgsql'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_pgsql( { mac => $mac } )

}


sub mac_as_singledash {

    my $mac = shift;

    croak 'please use as_singledash'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_singledash( { mac => $mac } )

}


sub mac_as_sun {

    my $mac = shift;

    croak 'please use as_sun'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_sun( { mac => $mac } )

}


sub mac_as_tokenring {

    my $mac = shift;

    croak 'please use as_tokenring'
      if ref $mac eq __PACKAGE__;
    if ( ref $mac ) {
        my $e = 'argument must be a string';
        croak "$e\n" if $NetAddr::MAC::die_on_error;
        $NetAddr::MAC::errstr = $e;
        return
    }

    $mac = _mac_to_integers($mac) or return;
    return as_tokenring( { mac => $mac } )

}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

NetAddr::MAC - MAC hardware address functions and object (EUI48 and EUI64)

=head1 VERSION

version 0.97

=head1 SYNOPSIS

 use NetAddr::MAC;

 my $mac = NetAddr::MAC->new( '00:11:22:aa:bb:cc' );
 my $mac = NetAddr::MAC->new( mac => '0011.22AA.BBCC' );

 print "MAC provided at object creation was: ", $mac->original;

 print "EUI48\n" if $mac->is_eui48;
 print "EUI64\n" if $mac->is_eui64;

 print "Unicast\n" if $mac->is_unicast;
 print "Multicast\n" if $mac->is_multicast;
 print "Broadcast\n" if $mac->is_broadcast;

 print "Locally Administered\n" if $mac->is_local;
 print "Universally Administered\n" if $mac->is_universal;

 print 'Basic Format: ',$mac->as_basic,"\n";
 print 'Bpr Format: ',  $mac->as_bpr,"\n";
 print 'Cisco Format: ',$mac->as_cisco,"\n";
 print 'IEEE Format: ', $mac->as_ieee,"\n";
 print 'IPv6 Address: ',$mac->as_ipv6_suffix,"\n";
 print 'Microsoft Format: ',$mac->as_microsoft,"\n";
 print 'Single Dash Format: ',$mac->as_singledash,"\n";
 print 'Sun Format: ',  $mac->as_sun,"\n";
 print 'Token Ring Format: ', $mac->as_tokenring,"\n";


 use NetAddr::MAC qw( :all );

 my $mac = q/00.11.22.33.44.55/;

 print "EUI48\n" if mac_is_eui48($mac);
 print "EUI64\n" if mac_is_eui64($mac);

 print "Unicast\n" if mac_is_unicast($mac);
 print "Multicast\n" if mac_is_multicast($mac);
 print "Broadcast\n" if mac_is_broadcast($mac);

 print "Locally Administerd\n" if mac_is_local($mac);
 print "Universally Administered\n" if mac_is_universal($mac);

 print 'Basic Format: ',mac_as_basic($mac),"\n";
 print 'Bpr Format: ',  mac_as_bpr($mac),"\n";
 print 'Cisco Format: ',mac_as_cisco($mac),"\n";
 print 'IEEE Format: ', mac_as_ieee($mac),"\n";
 print 'IPv6 Address: ',mac_as_ipv6_suffix($mac),"\n";
 print 'Microsoft Format: ',mac_as_microsoft($mac),"\n";
 print 'Single Dash Format: ', mac_as_singledash($mac),"\n";
 print 'Sun Format: ',  mac_as_sun($mac),"\n";
 print 'Token Ring Format: ',mac_as_tokenring($mac),"\n";

=head1 DESCRIPTION

This module provides an OO and functional interface to deal with Media Access
Control (or MAC) addresses. These are the addresses that uniquely identify a
device on various layer 2 networks. Although the most common case is hardware
addresses on Ethernet network cards, there are a variety of devices that use
this system of addressing.

Both Extended Unique Identifier 48 and 64 addresses are supported.

Some networks that use Extended Unique Identifier 48 (or MAC48) addresses include:

 Ethernet
 802.11 wireless networks
 Bluetooth
 IEEE 802.5 token ring
 FDDI
 ATM

Some networks that use Extended Unique Identifier 64 addresses include:

 Firewire
 IPv6 (sort of)
 ZigBee / 802.15.4 wireless personal-area networks

=for stopwords soe todo
cisco errstr oui
fx hsrp HSRPv2 vrrp autoconf
pgsql unicast
eui48 eui64
4th vmware xen

=head1 OO METHODS

=head2 new

The B<new> method creates instances of this object. It can be called
in any of the following ways.

=head3 NetAddr::MAC->new( mac => $mac )

Creates and returns a new NetAddr::MAC object.  The MAC value is required.

=head3 NetAddr::MAC->new( mac => $mac, %options )

As above, but %options may include any or none of the following

=over 4

=item * die_on_error

If set to true, errors will result in a die (croak) rather than populating I<$errstr>

B<Take care when using the mac_is_* functions!> they will return false in both
the case of an error and according to the properties of the MAC address. You will
therefore need to enable die_on_error or check I<$errstr> when false is returned.

=item * priority

This is the bridge priority as an integer, which can also be set by providing a mac
address in the following format, where 60 is the priority.

 60#0011.22aa.bbcc

This is a cisco thing, so typically the above is the format you would see. But we
are flexible enough to handle formats like...

 60#00:11:22:aa:bb:cc
 60#001122aabbcc
 60#00-11-22-aa-bb-cc
 etc.

If priority is provided as an option and as part of the mac address string, an
error will occur only if they differ.

Priority defaults to 0 if not provided.

=back

=head3 NetAddr::MAC->new( $mac )

Simplified creation method

=head3 NetAddr::MAC->new( $mac, %options )

As above but with %options

=head2 random

As an alternative to L</new>, a "random" mac access based upon the provided
B<oui> argument.

Please consider the following information when selecting an OUI.

If the first octal/digit/number is odd, then the MAC address L</is_multicast>

OUI's used by virtualization software:

Xen's prefix 00:16:3e
VMware's prefix 00:50:56

There are 4 sets of 'Locally Administered Address Ranges' that can be used
without fear of conflict (from actual hardware):

 x2-xx-xx-xx-xx-xx
 x6-xx-xx-xx-xx-xx
 xA-xx-xx-xx-xx-xx
 xE-xx-xx-xx-xx-xx

=head2 original

Returns the original B<mac> string as used when creating the MAC object

=head2 oui

Returns the mac address's Organizationally Unique Identifier (OUI) with dashes
in Hexadecimal / Canonical format:

 AC-DE-48

=head2 errstr

Returns the error (if one occurred).

This is intended for use with the object. Its not exported at all.

Note: this method is used once the NetAddr::MAC object is successfully
created. For now the to_eui48 method is the only method that will
return an error once the object is created.

When creating objects, you will need to catch errors with either the
I<or> function, or the I<eval> way.

=head1 OO PROPERTY METHODS

=head2 is_eui48

Returns true if mac address is determined to be of the EUI48 standard

=head2 is_eui64

Returns true if mac address is determined to be of the EUI64 standard

=head2 is_multicast

Returns true if mac address is determined to be a multicast address

=head2 is_broadcast

Returns true if mac address is determined to be a broadcast address

=head2 is_vrrp

Returns true if mac address is determined to be a Virtual Router Redundancy (VRRP) address

i.e. 00-00-5E-00-01-XX

always returns false for eui64.

I'm not quite sure what to do with 01-00-5E-00-00-12, suggestions welcomed.

=head2 is_hsrp

Returns true if mac address is determined to be a Hot Standby Router (HSRP) address

i.e. 00-00-0C-07-AC-XX

always returns false for eui64.

=head2 is_hsrp2

Returns true if mac address is determined to be a Hot Standby Router Version 2 (HSRPv2) address

i.e. 00-00-0C-9F-FX-XX

always returns false for eui64.

=head2 is_msnlb

Returns true if mac address is determined to be a MS Network Load Balancing MAC address

i.e. 02-BF-1-2-3-4 for unicast or 03-BF-1-2-3-4 for multicast

where 1-2-3-4 is the clusters primary IP address

for outbound packets, clusters members will send from 02-n-1-2-3-4 where n is the node priority. this function does NOT return true for those addresses.

always returns false for eui64.

=head2 is_unicast

Returns true if mac address is determined to be a unicast address

=head2 is_local

Returns true if mac address is determined to be locally administered

=head2 is_universal

Returns true if mac address is determined to be universally administered

=head1 OO NORMALIZATION METHODS

=head2 as_basic

Returns the mac address normalized as a hexadecimal string that is 0 padded and without delimiters

 001122aabbcc

=head2 as_bridge_id

Returns mac address with the priority, a hash, then the mac address normalized with I<as_cisco>

 45#0011.22aa.bbcc

=head2 as_bpr

Returns the mac address normalized as a hexadecimal string that is 0 padded with B<:> delimiters and with
B<1,length> leading where I<length> is the number of hex pairs (i.e. 6 for EUI48)

 1,6,00:11:22:aa:bb:cc

=head2 as_cisco

Returns the mac address normalized as a hexadecimal string that is 0 padded and with B<.> delimiting every 2nd octet
(i.e. after every 4th character)

 0011.22aa.bbcc

=head2 as_ieee

Returns the mac address normalized as a hexadecimal string that is 0 padded and with B<:> delimiting every octet
(i.e. after every 2nd character)

 00:34:56:78:9a:bc

=head2 as_ipv6_suffix

Returns the EUI64 address in the format used for an IPv6 autoconf address suffix

=head2 as_microsoft

Returns the mac address normalized as a hexadecimal string that is 0 padded and with B<-> delimiting every octet
(i.e. after every 2nd character)

 00-34-56-78-9a-bc

=head2 as_pgsql

Returns the mac address normalized as a hexadecimal string that is 0 padded and has a I<:> in the middle of the hex string.
this appears in the pgsql documentation along with the single dash version

 001122:334455

=head2 as_singledash

Returns the mac address normalized as a hexadecimal string that is 0 padded and has a dash in the middle of the hex string.
this appears in the pgsql documentation.

 001122-334455

=head2 as_sun

Returns the mac address normalized as a hexadecimal string that is B<not> padded and with B<-> delimiting every octet
(i.e. after every 2nd character)

 0-34-56-78-9a-bc

=head2 as_tokenring

Returns the mac address normalized as a hexadecimal string that is 0 padded and with B<-> delimiting every octet
(i.e. after every 2nd character) and each octet is bit-reversed order. So 10 00 5A 4D BC 96 becomes 08 00 5A B2 3D 69.

 00-2d-6a-1e-59-3d

=head2 to_eui48

Converts to EUI48 (if the EUI64 was derived from EUI48)

This function will fail if the mac was not derived from EUI48.
you will need to catch it and inspect the error message.

=head2 to_eui64

Converts to EUI64, or in other words encapsulates EUI48 to become EUI64
if needed

=head1 PROCEDURAL PROPERTY FUNCTIONS

=head2 mac_is_eui48($mac)

Returns true if mac address in $mac is determined to be of the EUI48 standard

=head2 mac_is_eui64($mac)

Returns true if mac address in $mac is determined to be of the EUI64 standard

=head2 mac_is_multicast($mac)

Returns true if mac address in $mac is determined to be a multicast address

=head2 mac_is_broadcast($mac)

Returns true if mac address in $mac is determined to be a broadcast address

=head2 mac_is_unicast($mac)

Returns true if mac address in $mac is determined to be a unicast address

=head2 mac_is_vrrp($mac)

Returns true if mac address is $mac is determined to be a Virtual Router Redundancy (VRRP) address

i.e. 00-00-5E-00-01-XX

=head2 mac_is_hsrp($mac)

Returns true if mac address is $mac is determined to be a Hot Standby Router (HSRP) address

i.e. 00-00-0C-07-AC-XX

=head2 mac_is_hsrp2($mac)

Returns true if mac address is $mac is determined to be a Hot Standby Router Version 2 (HSRPv2) address

i.e. 00-00-0C-9F-FX-XX

=head2 mac_is_msnlb($mac)

Returns true if mac address is $mac is determined to be a MS Network Load Balancing address

i.e. 02-BF-XX-XX-XX-XX or 03-BF-XX-XX-XX-XX

=head2 mac_is_local($mac)

Returns true if mac address in $mac is determined to be locally administered

=head2 mac_is_universal($mac)

Returns true if mac address in $mac is determined to be universally administered

=head1 PROCEDURAL NORMALIZATION METHODS

=head2 mac_as_basic($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and without delimiters

 001122aabbcc

=head2 mac_as_bpr($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded, with B<:> delimiting and
B<1,length> leading. I<length> is the number of hex pairs (6 for EUI48)

 1,6,00:11:22:aa:bb:cc

=head2 mac_as_cisco($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and with B<.> delimiting every 2nd octet
(i.e. after every 4th character)

 0011.22aa.bbcc

=head2 mac_as_ieee($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and with B<:> delimiting every octet
(i.e. after every 2nd character)

 00:34:56:78:9a:bc

=head2 mac_as_ipv6_suffix($mac)

Returns the mac address in $mac in the format used for an IPv6 autoconf address suffix

It will convert from eui48 or eui64 if needed

=head2 mac_as_microsoft($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and with B<-> delimiting every octet
(i.e. after every 2nd character)

 00-34-56-78-9a-bc

=head2 mac_as_pgsql($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and a single B<:> delimiter
in the middle. this format appears in their documentation, along with single dash version

 003456:789abc

=head2 mac_as_singledash($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and has a dash in the middle of the hex string.
this appears in the pgsql documentation

 001122-334455

=head2 mac_as_sun($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is B<not> padded and with B<-> delimiting every octet
(i.e. after every 2nd character)

 0-34-56-78-9a-bc

=head2 mac_as_tokenring($mac)

Returns the mac address in $mac normalized as a hexadecimal string that is 0 padded and with B<-> delimiting every octet
(i.e. after every 2nd character) and each octet is bit-reversed order. So 10 00 5A 4D BC 96 becomes 08 00 5A B2 3D 69.

 00-2d-6a-1e-59-3d

=head1 ERROR HANDLING

Prior to 0.8 every error resulted in a die (croak) which needed to be caught.
As I have used this module more, having to catch them all the time is tiresome.
So from 0.8 onward, errors result in an I<undef> and something being set.

For objects, this something is accessible via B<$self-E<gt>errstr> otherwise
the error is in B<$NetAddr::MAC::errstr>;

If you would like to have die (croak) instead, you can either set the global
B<$NetAddr::MAC::die_on_error> or set the B<die_on_error> option when creating
an object. When creating objects, the provided option takes priority over the
global. So if you set the global, then all objects will die - unless you
specify otherwise.

=head2 Global examples

Normal behaviour...

  use NetAddr::MAC qw/mac_as_basic/;
  $mac = mac_as_basic('aaaa.bbbb.cccc')
      or die $NetAddr::MAC::errstr;

If you want to catch exceptions (die/croak's)...

  use NetAddr::MAC qw/mac_as_basic/;
  $NetAddr::MAC::die_on_error = 1; # (or ++ if you like)

  eval { # or use Try::Tiny etc.
      $mac = mac_as_basic('aaaa.bbbb.cccc');
  };
  if ($@) {
      # something bad happened, so handle it
  }
  # all good, so do something

=head2 Object examples

Normal behaviour...

  use NetAddr::MAC;
  my $obj = NetAddr::MAC->new( mac => 'aabbcc112233')
      or die $NetAddr::MAC::errstr;

  $mac = $obj->to_eui48
      or die $obj->errstr;

If you want to catch exceptions (die/croak's)...

  use NetAddr::MAC;
  my $obj = NetAddr::MAC->new( mac => 'aabbcc112233', die_on_error => 1 );

  eval { # or use Try::Tiny etc.
      $mac = $obj->to_eui48
  };
  if ($@) {
      # something bad happened, so handle it
  }
  # all good, so do something

Or do it globally

  use NetAddr::MAC;
  $NetAddr::MAC::die_on_error = 1; # (or ++ if you like)
  my $obj = NetAddr::MAC->new( mac => 'aabbcc112233');

  eval { # or use Try::Tiny etc.
      $mac = $obj->to_eui48
  };
  if ($@) {
      # something bad happened, so handle it

  }

=head1 CREDITS

Stolen lots of ideas and some pod content from L<Device::MAC> and L<Net::MAC>

=head1 SEE ALSO

In some circumstances, the L<Regexp::Common::net> might be a slimmer solution.

L<Net::MAC::Vendor> is useful for doing vendor look up.

If you find L<Device::MAC> or L<Net::MAC> to be more suitable, please send
feedback so I can improve!

=head1 TODO

 - moare tests!
 - find bugs, squash them
 - merge in your changes!

=head1 SUPPORT

Please use the RT system on CPAN to lodge bugs.

Many young people like to use Github, so by all means send me pull requests at

  https://github.com/djzort/NetAddr-MAC

=head1 MOTIVATION

There are lots of systems at my (then) place of work which handle MAC
addresses. There was lots of code validating and normalizing them all over
the place - most of it was quirky and sloppy. So I set about creating a
reusable module to add to our SOE install so that MAC address handling
would become consistent, reliable, powerful and trivial.

Generally speaking this module fulfills that goal. It's very convenient
to be able to use MAC addresses in any format throughout those systems.

There are several other MAC address modules on CPAN. I didn't like the
interface on one, the other dragged in Moose. So I created this module,
taking the ideas I liked from the other two modules and adding in extra bits
that I needed (and a few features just for completeness) whilst avoiding
dependencies and avoiding anything that doesn't work on perl 5.6

I hope that the result is useful to others, the concept is to be able to create
an object representing a MAC address based on a string that only very vaguely
resembles a MAC address. From there, to be able to output normalized string
representations of the mac address in a variety of common formats.

A templating function is deliberately omitted, as very niche outputs can easily
be derived from the 'basic' format.

Feel free to send patches for features you add, I appreciate those who
have done so far and endeavour to incorporate new patches ASAP.

=head1 AUTHOR

Dean Hamstead <dean@bytefoundry.com.au>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dean Hamstad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
