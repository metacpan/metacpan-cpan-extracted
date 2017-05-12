#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use Template;

BEGIN {
    use_ok('Template::Plugin::Time::Duration');
};

ok( Template->new->process(
    \qq{[% USE time_dir = Time.Duration; time_dir.ago(0) %]},
    my $vars = {},
    \(my $out),
), "template processing" ) || warn( Template->error );

cmp_ok($out, 'eq', 'right now', 'ago');

done_testing;
