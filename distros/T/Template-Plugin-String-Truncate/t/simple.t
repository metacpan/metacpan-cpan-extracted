#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use Template;

BEGIN {
    use_ok('Template::Plugin::String::Truncate');
};

ok( Template->new->process(
    \qq{[% USE st = String.Truncate; st.trunc('12345', 3) %]},
    my $vars = {},
    \(my $out),
), "template processing" ) || warn( Template->error );

cmp_ok($out, 'eq', '123', 'trunc');

ok( Template->new->process(
    \qq{[% USE st = String.Truncate; st.elide('1234567', 6) %]},
    my $vars2 = {},
    \(my $out2),
), "template processing" ) || warn( Template->error );

cmp_ok($out2, 'eq', '123...', 'elide');

ok( Template->new->process(
    \qq{[% USE st = String.Truncate; st.elide('1234567', 6, { truncate => 'left' }) %]},
    my $vars3 = {},
    \(my $out3),
), "template processing" ) || warn( Template->error );

cmp_ok($out3, 'eq', '...567', 'elide left');

done_testing;