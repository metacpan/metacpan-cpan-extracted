use strict;
use warnings;
use OPCUA::Open62541;
use Errno;

package OPCUA::Open62541;

use Test::More tests => 15;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my $xs_name = "XS_OPCUA__Open62541_test_croak";

throws_ok { test_croak(undef) } (qr/^$xs_name at /, "croak undef");
no_leaks_ok { eval { test_croak(undef) } } "croak undef leak";
throws_ok { test_croak("foo") } (qr/$xs_name: foo at /, "croak foo");
no_leaks_ok { eval { test_croak("foo") } } "croak foo leak";

$xs_name = "XS_OPCUA__Open62541_test_croake";
$! = Errno::ENOENT;

throws_ok { test_croake(undef, $!) } (qr/^$xs_name: $! at /, "croake undef");
no_leaks_ok { eval { test_croake(undef) } } "croake undef leak";
throws_ok { test_croake("foo", $!) } (qr/$xs_name: foo: $! at /, "croake foo");
no_leaks_ok { eval { test_croake("foo") } } "croake foo leak";

$xs_name = "XS_OPCUA__Open62541_test_croaks";
my $s = STATUSCODE_GOOD;
my $c = 'Good';

throws_ok { test_croaks(undef, $s) } (qr/^$xs_name: $c at /, "croaks undef");
no_leaks_ok { eval { test_croaks(undef, $s) } } "croaks undef leak";
throws_ok { test_croaks("foo", $s) } (qr/$xs_name: foo: $c at /, "croaks foo");
no_leaks_ok { eval { test_croaks("foo", $s) } } "croaks foo leak";

$s = -1;
$c = 'Unknown StatusCode';

throws_ok { test_croaks(undef, $s) } (qr/^$xs_name: $c at /, "croaks unknown");
no_leaks_ok { eval { test_croaks(undef, $s) } } "croaks unknown leak";
