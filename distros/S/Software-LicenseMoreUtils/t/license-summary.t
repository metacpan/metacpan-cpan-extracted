use strict;
use warnings;
use 5.10.1;

use Test::More 1.001005; # subtest with args
use Test::Exception;
use Path::Tiny;

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

my %expected = (
    'GPL-1' => qr!can be found in '/usr/share/common-licenses/GPL-1'!,
    'GPL-2' => qr!can be found in '/usr/share/common-licenses/GPL-2'!,
    'LGPL-2.1' => qr!can be found in '/usr/share/common-licenses/LGPL-2\.1'.$!,
    'LGPL-2.1-or-later' => qr!can be found in '/usr/share/common-licenses/LGPL-2\.1'.$!,
    'MIT'   => qr/^$/,
    'GPL-1+' =>  qr!any later version!,
    'GPL-2.0-or-later' =>  qr!any later version!
);

sub my_summary_test {
    my $short_name = shift;

    # test short_name retrieved by Software::LicenseUtils
    my $lic = $class->new_from_short_name({
        short_name => $short_name,
        holder => 'X. Ample'
    });
    isa_ok($lic,'Software::LicenseMoreUtils::LicenseWithSummary',"license class");

    if (path('/etc/debian_version')->is_file) {
        is($lic->distribution, 'debian', "Debian distro was identified");
    }

    my $expected_regexp = $lic->distribution eq 'debian' ? $expected{$short_name} : qr/^$/ ;
    my $summary = $lic->summary;
    like($summary, $expected_regexp, "$short_name summary");
}

foreach my $short_name (sort keys %expected) {
    subtest "testing $short_name summary", \&my_summary_test, $short_name;
}


done_testing;
