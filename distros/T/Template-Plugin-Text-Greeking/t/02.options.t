#!/usr/bin/perl

use strict;
use warnings;
use Template;
use Test::More tests => 1;

my $t = <<EOT;
[%- USE Text.Greeking -%]
[%- Text.Greeking(lang => "zh_TW", paragraphs => [1,1]) -%]
EOT

my $tt = Template->new;
my $out = "";
$tt->process(\$t, {}, \$out)
    or die $tt->error();

ok(length $out > 0);

print $out;
