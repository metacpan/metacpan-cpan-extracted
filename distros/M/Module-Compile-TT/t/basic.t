#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use tt foo => "bar";

sub [% foo %] { "foobar" }

[% i = 0 %]
[% subs = ["la", "da"] %]
[% FOR subname IN subs %]
sub [% subname %] { [% i %] }
[% i = i+1 %]
[% END %]

no tt;


is( bar(), "foobar", "compiled sub" );

is( la(), 0, "TT loop seems to work" );
is( da(), 1, "TT loop seems to work" );


