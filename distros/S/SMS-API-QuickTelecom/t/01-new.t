#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
    $| = 1 ;
}

use_ok ( 'SMS::API::QuickTelecom' ) or die($@);
can_ok ( 'SMS::API::QuickTelecom', qw(new send_sms) );

my $i;

$i = SMS::API::QuickTelecom->new( user => 'usertest', pass => 'userpass', host => 'hosttest', test => 1 ) or die "Failed to create new object"; # unless defined $i;

is (ref($i), 'SMS::API::QuickTelecom', 'got object');

undef $i;

eval {
    $i = SMS::API::QuickTelecom->new( user => 'usertest' );
};
is ( $i, undef, 'pass is mandatory');

eval {
    $i = SMS::API::QuickTelecom->new( pass => 'userpass' );
};
is ( $i, undef, 'user is mandatory');

