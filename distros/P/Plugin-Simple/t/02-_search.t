#!/usr/bin/perl
use strict;
use warnings;

use Plugin::Simple;
use Test::More;

my $ps = Plugin::Simple->_new;

{ # empty search
    my @ret = $ps->_search('main');
    is (@ret, 0, "#FIXME: by default, empty search returns nothing");
}
{
    my @ret = $ps->_search('main', 'Plugin::Simple');

    ok (@ret >= 1, "with an example item, things appear ok");
    can_ok('Plugin::Simple', '_search');
}
{ # numerous
    my @ret = $ps->_search('main', 'Module::');
    ok (@ret >= 10, 'proper count of files with multi-search enabled');
}
done_testing();

