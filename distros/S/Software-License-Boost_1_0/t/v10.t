use strict;
use warnings;
use Test::More tests => 6;

my $l;
BEGIN {
    $l = 'Software::License::Boost_1_0';
    eval "require $l";
}

is($l->name, 'Boost Software License, Version 1.0, August 17th, 2003');
like($l->notice, qr/Boost Software License, Version 1\.0, August 17th, 2003/);
like($l->license, qr/Boost Software License - Version 1\.0 - August 17th, 2003/);
is($l->url, 'http://www.boost.org/LICENSE_1_0.txt');
is($l->meta_name,  'open_source');
is($l->meta2_name, 'open_source');
