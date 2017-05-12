use Test::More;

use Nagios::Passive;
use Gearman::Client;
use POSIX qw/mkfifo/;

plan skip_all => "MSWin32 not supported" if $^O eq 'MSWin32';

*CORE::GLOBAL::time = sub { 0 };

my $nw = Nagios::Passive->create(
    gearman => Gearman::Client->new,
    key => 'X',
    check_name => 'x',
    host_name => 'localhost',
);

my $ns = Nagios::Passive->create(
    gearman => Gearman::Client->new,
    service_description=>'x',
    key => 'X' x 32,
    check_name => 'x',
    host_name => 'localhost',
);

ok eval { $ns->encrypted_string; 1 }, "encryption doesn't die";

is($nw->to_string, << 'EOE', 'to_string ok');
type=passive
host_name=localhost
start_time=0.0
finish_time=0.0
latency=0.0
return_code=0
output=x OK - 
EOE

is($ns->to_string, << 'EOE', 'to_string ok');
type=passive
host_name=localhost
service_description=x
start_time=0.0
finish_time=0.0
latency=0.0
return_code=0
output=x OK - 
EOE

is($nw->encrypted_string, << 'EOE', 'crypt ok');
RE2rSDNVWsQGPId1ViNgtRxbzpnUYFm7ELIzYfT6zasUdfOqNlPXTaMWDqjQuEBlzNUjQ/UgXmzE
acZ5UdNCIidKAw/Y+l4DTrUenLg9pK8rowlnZT2Q6IedOt88KtomusHTYvbEFDumcHwS4l/PMlCn
Me4JkF0KdY7RG0z3Lc0=
EOE

done_testing;
