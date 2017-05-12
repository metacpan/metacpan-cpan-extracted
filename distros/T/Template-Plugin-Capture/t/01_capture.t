use strict;

use Test::More tests => 3;

use Template;

my $tt = Template->new;
my $template = <<'END_TMPL';
[%- USE Capture %]
[%- FILTER capture('block1')%]
foo bar
[%- END %]
[%- block1 %]
END_TMPL

my $output;
$tt->process(\$template, {}, \$output) or die $tt->error;
like($output, qr/foo bar/);

# nothing
$template = <<'END_TMPL';
[%- USE Capture %]
[%- FILTER capture('block1')%]
foo bar
[%- END %]
END_TMPL

undef $output;
$tt->process(\$template, {}, \$output) or die $tt->error;
unlike($output, qr/foo bar/);


# multiple
$template = <<'END_TMPL';
[%- USE Capture %]
[%- FILTER capture('block1')%]
foo bar
[%- END %]
[%- block1 %]
[%- FILTER capture('block2')%]
foo bar baz
[%- END %]
[%- block2 %]
END_TMPL

undef $output;
$tt->process(\$template, {}, \$output) or die $tt->error;
like($output, qr/foo bar\nfoo bar baz/);

