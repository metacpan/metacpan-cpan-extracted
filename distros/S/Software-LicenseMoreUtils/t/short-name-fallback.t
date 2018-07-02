use strict;
use warnings;

use Test::More;
use Test::Exception;

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

# test short_name retrieved by Software::LicenseUtils
my $gpl_lic = $class->new_from_short_name({
    short_name => 'GPL-1',
    holder => 'X. Ample'
});

is($gpl_lic->license_class,'Software::License::GPL_1',"license class");

# test fall back
my $mit_lic = $class->new_from_short_name({
    short_name => 'MIT',
    holder => 'X. Ample'
});
is($mit_lic->license_class,'Software::License::MIT',"license class");

my $apache_lic = $class->new_from_short_name({
    short_name => 'Apache-2.0',
    holder => 'X. Ample'
});
is($apache_lic->license_class,'Software::License::Apache_2_0',"license class");

# kaboom test
throws_ok {
    my $kaboom_lic = $class->new_from_short_name({
        short_name => 'kaboom-2.0',
        holder => 'X. Plosive'
    });
} qr/Unknow license with short name kaboom-2.0/, 'test unknow short_name';

done_testing;

