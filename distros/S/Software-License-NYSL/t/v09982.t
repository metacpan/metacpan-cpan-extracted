use strict;
use warnings;
use Test::More tests => 11;

my $nysl;
BEGIN {
    $nysl = 'Software::License::NYSL';
    eval "require $nysl";
}

like($nysl->name, qr/NYSL/);
like($nysl->name, qr/Version 0.9982/);
like($nysl->notice, qr/NYSL/);
like($nysl->notice, qr/Version 0.9982/);
like($nysl->notice, qr/Everyone'sWare/);
like($nysl->license, qr/NYSL/);
like($nysl->license, qr/Version 0.9982/);
like($nysl->license, qr/Everyone'sWare/);
is($nysl->url, 'http://www.kmonos.net/nysl/');
is($nysl->meta_name, 'unrestricted');
is($nysl->meta2_name, 'unrestricted');
