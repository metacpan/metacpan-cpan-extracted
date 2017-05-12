#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 1;
use Template;

my $t = <<EOT;
[%-
    USE Num2Word;
    foobar.to_word
-%]
EOT

my $template = Template->new;
my $out = "";
$template->process(\$t, { foobar => 1 }, \$out)
    or die $template->error();

is($out, "one")


