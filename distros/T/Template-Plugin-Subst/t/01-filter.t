#!/usr/bin/perl

use warnings;
use strict;

use Template;
use Test::More tests => 13;

use lib '/home/nik/svk/local/jc/CPAN/Template-Plugin-Subst/trunk/lib';
my $tt = Template->new();

my $template;
my $output;
my $expected_output;

$template = <<'EOTEMPLATE';
hello, world
EOTEMPLATE

$expected_output = "hello, world\n";

$tt->process(\$template, undef, \$output);

is($output, $expected_output, 'Basic template processing');

$template = <<'EOTEMPLATE';
[%- USE Subst -%]
[%- FILTER $Subst pattern = 'foo' replacement = 'bar' -%]
foo
[% END -%]
EOTEMPLATE

$expected_output = "bar\n";

undef $output;
$tt->process(\$template, undef, \$output);

is($output, $expected_output, 'Simple replacement');

$template = <<'EOTEMPLATE';
[%- USE Subst -%]
[%- FILTER $Subst pattern = 'foo' replacement = 'bar' -%]
This is a 'foo' test
[% END -%]
EOTEMPLATE

$expected_output = "This is a 'bar' test\n";

undef $output;
$tt->process(\$template, undef, \$output);

is($output, $expected_output, 'Simple replacement (2)');

$template = <<'EOTEMPLATE';
[%- USE Subst -%]
[%- FILTER $Subst pattern = 'foo' replacement = 'bar' -%]
This is a 'foo' test.

Another line of foo.

Here's (foo) another one.
[% END -%]
EOTEMPLATE

$expected_output = <<'EOT';
This is a 'bar' test.

Another line of bar.

Here's (bar) another one.
EOT

undef $output;
$tt->process(\$template, undef, \$output);

is($output, $expected_output, 'Search/replace across multiple lines');

$template = <<'EOTEMPLATE';
[%- USE Subst -%]
[%- FILTER $Subst pattern = '(foo)(bar)' replacement = '$2$1' -%]
foobar
[% END -%]
EOTEMPLATE

$expected_output = "barfoo\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, 'Backrefs work');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = '(foo)(bar)' replacement = '$2$1' -%]
[%- str = 'foobar' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "barfoo\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, 'Works with | notation');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = '(foo)(bar)' replacement = '[$2][$1]' -%]
[%- str = 'foobar' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "[bar][foo]\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, 'Adding extra content works');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = 'foo' replacement = 'bar' -%]
[%- str = 'A foo, and another foo, and yet another foo' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "A bar, and another bar, and yet another bar\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, 'Default behaviour is global');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = 'foo' replacement = 'bar' global = 0 -%]
[%- str = 'A foo, and another foo, and yet another foo' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "A bar, and another foo, and yet another foo\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, '\'global = 0\' works');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = '(foo)' replacement = '[$1]' global = 0 -%]
[%- str = 'A foo, and another foo, and yet another foo' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "A [foo], and another foo, and yet another foo\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, '\'global = 0\' works with backrefs');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = 'foo' replacement = 'bar' -%]
[%- str = 'A foo, and a FOO' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "A bar, and a FOO\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, 'Matches are case sensitive by default');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = '(?i)foo' replacement = 'bar' -%]
[%- str = 'A foo, and a FOO' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "A bar, and a bar\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, '  but (?i) works in the pattern');

$template = <<'EOTEMPLATE';
[%- USE f = Subst pattern = '\$(\d)' replacement = 'USD$1' -%]
[%- str = 'How much money do you want:  $1 or $2 ?' -%]
[% str | $f %]
EOTEMPLATE

$expected_output = "How much money do you want:  USD1 or USD2 ?\n";
undef $output;
$tt->process(\$template, undef, \$output);
is($output, $expected_output, '$ in pattern seems to work');

