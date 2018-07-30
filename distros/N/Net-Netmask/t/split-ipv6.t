#!/usr/bin/perl -I. -w

use strict;

use Test2::V0;

use Net::Netmask;

#feel free to add a build requires of Test::Exception if that is okay with you.
sub throws_ok(&$$) {
    my ( $code, $regex, $desc ) = @_;
    eval { $code->(); };

    my $err = $@;

    like( $err, $regex );
    return;
}

sub make_nm {
    my ($cidr_str) = @_;
    return Net::Netmask->new($cidr_str);
}

my $cidr128 = make_nm('2001:db8::/128');
my $cidr120 = make_nm('2001:db8::/120');
my $cidr48  = make_nm('2001:db8::/48');

throws_ok { $cidr48->split(3) }
qr/^Parts count must be a number of base 2. Got: 3/, "Non base 2 split count errors.";

throws_ok { $cidr48->split() }
qr/^Parts must be defined and greater than 0./, "undef split throws error";

throws_ok { $cidr48->split(0) }
qr/^Parts must be defined and greater than 0./, "Zero split throws error";

throws_ok { $cidr48->split(-1) }
qr/^Parts must be defined and greater than 0./, "Negative split count errors";

throws_ok { $cidr128->split(2) }
qr/^Netmask only contains 1 IPs. Cannot split into 2./, "32 cannot be split";

is $cidr48->split(2),
  map( { make_nm( "2001:db8:${_}::/49" ) } ( "0", "8000" ) ),
  'Can split /48 into 2 49s';

is $cidr120->split(256),
  map( { make_nm sprintf("2001:db8::%x", $_) } ( 0 .. 255 ) ),
  'Can split into 128s (i.e $parts = $self->size)';

done_testing();
