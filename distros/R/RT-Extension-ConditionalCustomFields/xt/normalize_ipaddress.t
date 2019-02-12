use strict;
use warnings;

use RT::Extension::ConditionalCustomFields::Test tests => 9;

use WWW::Mechanize::PhantomJS;

my @ips = (
    '192.168.1.6',
    '2001:db8::200:0:0:0:7',
    '2001:db8:3:4::192.0.2.33',
);

my ($base, $m) = RT::Extension::ConditionalCustomFields::Test->started_ok;
my $mjs = WWW::Mechanize::PhantomJS->new();
$mjs->get($m->rt_base_url . '?user=root;pass=password');

foreach my $ip (@ips) {
    my ($js_ip, $type) = $mjs->eval("parseIP('$ip')");
    is($js_ip, RT::ObjectCustomFieldValue->ParseIP($ip));
}
