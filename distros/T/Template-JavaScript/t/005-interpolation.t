#!/usr/bin/env perl

use strict;
use warnings;

# for the time being
use Test::More qw( no_plan );

use Template::JavaScript;

my $ctx3 = Template::JavaScript->new();
$ctx3->tmpl_string( <<'' );
% var my_value = 'YES';
% var other_value = 'NO';
This is the value: <% my_value %> and I want it <% other_value %>

$ctx3->output( \my $text );
$ctx3->run;

is( $text, <<'', 'can interpolate variables inline' );
This is the value: YES and I want it NO

undef $ctx3;  # safety net

my $ctx4 = Template::JavaScript->new();
$ctx4->tmpl_string( <<'DICKS' );
% var my_value = 'YES';
% var other_value = 'NO';
This is the value: <% my_value %> and I want it <% other_value %>


DICKS

$ctx4->output( \$text );
$ctx4->run;

is( $text, <<'DICKS', 'can interpolate variables inline with correct newline handling' );
This is the value: YES and I want it NO


DICKS

undef $ctx4;  # safety net
