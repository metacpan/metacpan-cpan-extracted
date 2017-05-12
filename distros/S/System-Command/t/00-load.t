use strict;
use warnings;
use Test::More;
use File::Find;

my @modules;
find( sub { push @modules, $File::Find::name if /\.pm$/ }, 'lib' );

plan tests => scalar @modules;

do {
    `$^X -Ilib -M$_ -e1`;
    ok(! ( $? >> 8 ), $_ );
}
    for reverse sort map { s!/!::!g; s/\.pm$//; s/^lib:://; $_ } @modules;
