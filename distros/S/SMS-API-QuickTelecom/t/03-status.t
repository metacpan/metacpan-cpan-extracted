#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

use SMS::API::QuickTelecom;

can_ok ( 'SMS::API::QuickTelecom', qw(status) );

my $i = SMS::API::QuickTelecom->new( user => 'usertest', pass => 'userpass', test => 1 ) or die "Failed to create new object"; # unless defined $i;

my $b;
eval {
    $b = $i->status();
};

is ($b, undef, 'sms_id or sms_group_id field mandatory');


$b = $i->status( sms_id => 1 );

like ($b, '/xml version="1.0" encoding="UTF-8".+><output>/', 'sms_id passed');

$b = $i->status( sms_group_id => 1 );
like ($b, '/xml version="1.0" encoding="UTF-8".+><output>/', 'sms_group_id passed');

$b = undef;
eval {
    $b = $i->status( date_from => '00.00.0000 00:00:00' );
};
is ($b, undef, 'date_from must be with date_to');

$b = $i->status( date_from => '00.00.0000 00:00:00', date_to => '00.00.0000 00:00:00' );
like ($b, '/xml version="1.0" encoding="UTF-8".+><output>/', 'date_from and date_to passed');

$b = undef;
eval {
    $b = $i->status( sms_id => 1, date_from => '00.00.0000 00:00:00', date_to => '00.00.0000 00:00:00' );
};
is ($b, undef, 'date_from and date_to passed but no sms_id');

$b = undef;
eval {
    $b = $i->status( date_from => '0.0.0000 00:00:00', date_to => '00.00.0000 00:00:00' );
};
is ($b, undef, 'date_from and date_to format passed');

