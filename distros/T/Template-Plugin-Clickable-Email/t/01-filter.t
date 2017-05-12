#!/usr/bin/perl

use warnings;
use strict;

use Template;
use Test::More;

plan tests => 3;

my $tt = Template->new();

# Make sure that normal TT processing works ...

my $template;

$template = <<'EOTEMPLATE';
hello, world
EOTEMPLATE

my $output;

$tt->process(\$template, undef, \$output);

is($template, $output, 'Basic template processing');

# Now use a [% FILTER ... %] block to run the filter ...

$template = <<'EOTEMPLATE';
[%- USE e = Clickable::Email -%]
[%- FILTER $e -%]
text nik@FreeBSD.org text
[% END -%]
EOTEMPLATE

my $expected_output = <<'EOT';
text <a href="mailto:nik@FreeBSD.org">nik@FreeBSD.org</a> text
EOT

$output = '';

$tt->process(\$template, undef, \$output);

is($output, $expected_output, 'Works in [% FILTER ... %] block');

# Now try and use the filter 'inline' ...

$template = <<'EOTEMPLATE';
[%- USE e = Clickable::Email -%]
[% text | $e %]
EOTEMPLATE

$output = '';

$tt->process(\$template, { text => 'text nik@FreeBSD.org text' }, \$output);

is($output, $expected_output, 'Works inline');
