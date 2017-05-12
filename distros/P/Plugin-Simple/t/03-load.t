#!/usr/bin/perl
use strict;
use warnings;

use Plugin::Simple;
use Test::More;

my $ps = Plugin::Simple->_new;
my $file = 't/base/Testing.pm';

SKIP: { # module test
    my @ret = $ps->_load('Plugin::Simple');

    is (@ret, 1, "with an example item, things appear ok");
    is ($ret[0], 'Plugin::Simple', 'returned plugin is correct');
    can_ok('Plugin::Simple', '_load');
};
{ # file
    my @ret = $ps->_load($file);
    is (@ret, 1, "using the $file file, _load() loads ok");
    is ($ret[0], 'Testing', "...and the return is ok");
    can_ok($ret[0], 'hello');
    is ($ret[0]->hello(), 'hello, world!', "$ret[0] sub call ok");

}
done_testing();

