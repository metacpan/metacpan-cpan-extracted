use strict;
use warnings;

use Test::More;
use Test::Exception;

my $class = 'Software::LicenseMoreUtils';
require_ok($class);

my %expected = (
    'GPL-1' => qr!can be found in '/usr/share/common-licenses/GPL-1'!,
    'GPL-2' => qr!can be found in '/usr/share/common-licenses/GPL-2'!,
    'MIT'   => qr/^$/,
    'GPL-1+' =>  qr!any later version!
);

sub my_summary_test {
    my $short_name = shift;

    # test short_name retrieved by Software::LicenseUtils
    my $lic = $class->new_license_with_summary({
        short_name => $short_name,
        holder => 'X. Ample'
    });
    isa_ok($lic,'Software::LicenseMoreUtils::LicenseWithSummary',"license class");

    my $expected_regexp = $lic->distribution eq 'debian' ? $expected{$short_name} : qr/^$/ ;

    like($lic->summary, $expected_regexp, "$short_name summary");
}

foreach my $short_name (sort keys %expected) {
    subtest "testing $short_name summary", \&my_summary_test, $short_name;
}


done_testing;
