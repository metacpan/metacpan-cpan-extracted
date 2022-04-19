use strict;
use warnings;

use Test::More;
use Test::Exception;

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

my @tests = (
    'Apache-1.1' => 'Software::License::Apache_1_1',
    'Apache-2.0' => 'Software::License::Apache_2_0',
    'GPL-1'      => 'Software::License::GPL_1',
    'GPL-1+'     => 'Software::License::GPL_1',
    'GPL-2+'     => 'Software::License::GPL_2',
    'GPL-3+'     => 'Software::License::GPL_3',
    'GPL-3.0+'   => 'Software::License::GPL_3',
    # There's no LGPL-1
    'LGPL-2'     => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL-2+'    => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL-2.0'   => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL-2.1'   => 'Software::License::LGPL_2_1',
    'LGPL-2.1+'  => 'Software::License::LGPL_2_1',
    'LGPL-3'     => 'Software::License::LGPL_3_0',
    'LGPL-3+'    => 'Software::License::LGPL_3_0',
    'LGPL-3.0'   => 'Software::License::LGPL_3_0',
    'LGPL-3.0+'  => 'Software::License::LGPL_3_0',
    'LGPL_2'     => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL_2+'    => 'Software::LicenseMoreUtils::LGPL_2',
    'MIT'        => 'Software::License::MIT',
    'PostgreSQL' => 'Software::License::PostgreSQL',
    'Zlib'       => 'Software::License::Zlib',

    # SPDX identifiers handled by Software::LicenseUtils
    'GPL-1.0-or-later'  => 'Software::License::GPL_1',
    'GPL-2.0-or-later'  => 'Software::License::GPL_2',
    'GPL-3.0-or-later'  => 'Software::License::GPL_3',
    'LGPL-2.0-or-later' => 'Software::LicenseMoreUtils::LGPL_2',
    'LGPL-2.1-or-later' => 'Software::License::LGPL_2_1',
    'LGPL-3.0-only'     => 'Software::License::LGPL_3_0',
    'LGPL-3.0-or-later' => 'Software::License::LGPL_3_0',
);

while (@tests) {
    my ($short_name, $lic_class) = splice @tests, 0, 2;

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

