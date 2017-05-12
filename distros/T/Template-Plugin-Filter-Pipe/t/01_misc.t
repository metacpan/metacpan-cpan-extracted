#!/usr/bin/env perl
use warnings;
use strict;
use Template;
use Test::More tests => 3;
use Test::Differences;

sub template_ok ($$$) {
    my ($source, $expect, $name) = @_;
    my $template = Template->new || die Template->error;
    my $result;
    $template->process(\$source, {}, \$result) || die $template->error;
    eq_or_diff $result, $expect, $name;
}
my $template = <<'EOTMPL';
[%- USE Filter.Pipe -%]
[%- FILTER $Filter.Pipe 'Uppercase' -%]
this is some text
[%- END -%]
EOTMPL
template_ok $template, 'THIS IS SOME TEXT', 'Uppercase pipe';
$template = <<EOTMPL;
[%- USE Filter.Pipe -%]
[%- 'this is some more text' | pipe("Uppercase") -%]
EOTMPL
template_ok $template, 'THIS IS SOME MORE TEXT', 'Uppercase pipe';
$template = <<EOTMPL;
[%- USE Filter.Pipe -%]
[%- 'a test' | pipe("Uppercase") | pipe("Repeat", times => 2, join => " = ") |
    pipe("Reverse") -%]
EOTMPL
template_ok $template, 'TSET A = TSET A', 'Uppercase pipe';
