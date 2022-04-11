use strict;
use warnings;

use Test::More;
use Test::Exception;

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

my @tests = (
    # test short_name retrieved by Software::LicenseUtils
    [ 'GPL-1' ,'Software::License::GPL_1' ],

    # test fall back
    [ 'MIT' =>  'Software::License::MIT' ],
    [ 'Apache-2.0' => 'Software::License::Apache_2_0' ],

    # SPDX identifiers handled by Software::LicenseUtils
    [ 'Zlib' => 'Software::License::Zlib'],
    [ 'PostgreSQL' => 'Software::License::PostgreSQL']
);

foreach my $test (@tests) {
    my ($short_name, $lic_class) = @$test;

    my $lic = $class->new_from_short_name({
        short_name => $short_name,
        holder => 'X. Ample'
    });

    is($lic->license_class, $lic_class,"short name: $short_name");
}

# test also fulltext
my $lgpl_2_lic = $class->new_from_short_name({
    short_name => 'LGPL-2',
    holder => 'X. Ample'
});
is($lgpl_2_lic->license_class,'Software::LicenseMoreUtils::LGPL_2',"license class");
like($lgpl_2_lic->fulltext, qr/we are referring to freedom/,"found full text");

# kaboom test
throws_ok {
    my $kaboom_lic = $class->new_from_short_name({
        short_name => 'kaboom-2.0',
        holder => 'X. Plosive'
    });
} qr/Unknow license with short name kaboom-2.0/, 'test unknow short_name';

done_testing;

