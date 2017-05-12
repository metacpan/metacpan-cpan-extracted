# -*- perl -*-

use strict;

BEGIN { my $w = $SIG{__WARN__}; $SIG{__WARN__} = sub { $w } };
use Test::More tests => 3;

use_ok( 'SMS::Send' );
use_ok( 'SMS::Send::NL::MyVodafone' );

my @drivers = SMS::Send->installed_drivers;
is( scalar(grep { $_ eq 'NL::MyVodafone' } @drivers), 1, 'Found installed driver NL:
:MyVodafone' );

exit(0);
