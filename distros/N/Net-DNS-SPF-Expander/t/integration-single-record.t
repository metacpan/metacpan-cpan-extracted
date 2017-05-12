use strict;
use warnings;
use lib 'lib';

use Net::DNS::SPF::Expander;
use IO::All -utf8;

use Test::More tests => 7;
use Test::Exception;
use Test::Differences;

my $backup_file  = 't/etc/test_zonefile_single.bak';
my $new_file     = 't/etc/test_zonefile_single.new';
my @output_files = ( $backup_file, $new_file );
for my $deletion (@output_files) {
    if ( -e $deletion ) {
        lives_ok { unlink $deletion } "I am deleting $deletion";
    } else {
        ok( 1 == 1, "$deletion was already deleted" );
    }
}

my $file_to_expand = 't/etc/test_zonefile_single';

my $expander;
lives_ok {
    $expander = Net::DNS::SPF::Expander->new(
        input_file => $file_to_expand,
    );
}
"I can make a new expander";

my $string;
lives_ok { $string = $expander->write } "I can call write on my expander";

my $expected_file_content = <<EOM;
\$ORIGIN test_zone.com.

yo      CNAME   111.222.333.4.
mama    CNAME   222.333.444.5.

;@               SPF     "v=spf1 include:_spf.google.com ~all"
;*               TXT     "v=spf1 include:_spf.google.com ~all"
*    600    IN    TXT    "v=spf1 include:_spf1.test_zone.com include:_spf2.test_zone.com include:_spf3.test_zone.com ~all"
@    600    IN    TXT    "v=spf1 include:_spf1.test_zone.com include:_spf2.test_zone.com include:_spf3.test_zone.com ~all"
_spf1.test_zone.com.    600    IN    TXT    "v=spf1 ip4:108.177.8.0/21 ip4:172.217.0.0/19 ip4:173.194.0.0/16 ip4:207.126.144.0/20 ip4:209.85.128.0/17 ip4:216.239.32.0/19 ip4:216.58.192.0/19 ip4:64.18.0.0/20 ip4:64.233.160.0/19 ip4:66.102.0.0/20 ip4:66.249.80.0/20 ip4:72.14.192.0/18"
_spf2.test_zone.com.    600    IN    TXT    "v=spf1 ip4:74.125.0.0/16 ip6:2001:4860:4000::/36 ip6:2404:6800:4000::/36 ip6:2607:f8b0:4000::/36 ip6:2800:3f0:4000::/36 ip6:2a00:1450:4000::/36"
_spf3.test_zone.com.    600    IN    TXT    "v=spf1 ip6:2c0f:fb50:4000::/36"

greasy  CNAME   333.444.555.6.
granny  CNAME   666.777.888.9.
EOM

ok( -e $_, "File $_ was created" ) for @output_files;

eq_or_diff( $string, $expected_file_content,
"The text of the new file is what I expected" );
