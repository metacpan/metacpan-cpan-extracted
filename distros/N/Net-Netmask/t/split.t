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

my $cidr32 = make_nm('10.0.0.0/32');
my $cidr30 = make_nm('10.0.0.0/30');
my $cidr24 = make_nm('10.0.0.0/24');

throws_ok { $cidr30->split(3) }
qr/^Parts count must be a number of base 2. Got: 3/, "Non base 2 split count errors.";

throws_ok { $cidr30->split() }
qr/^Parts must be defined and greater than 0./, "undef split throws error";

throws_ok { $cidr30->split(0) }
qr/^Parts must be defined and greater than 0./, "Zero split throws error";

throws_ok { $cidr30->split(-1) }
qr/^Parts must be defined and greater than 0./, "Negative split count errors";

throws_ok { $cidr32->split(2) }
qr/^Netmask only contains 1 IPs. Cannot split into 2./, "32 cannot be split";

is $cidr24->split(2),
  map( { make_nm( "10.0.0.$_" . "/25" ) } ( 0, 128 ) ),
  'Can split /24 into 2 25s';

is $cidr24->split(256),
  map( { make_nm "10.0.0.$_" } ( 0 .. 255 ) ),
  'Can split into 32s (i.e $parts = $self->size)';

done_testing();
