#!perl
use strict;
use warnings;
use Test::More tests => 1;
use Template;

my $tt = Template->new;

$tt->process(\<<EOF, {}, \my $out) or die $tt->error;
[% USE DisableForm %]
[% FILTER disable_form %]
<form method="get">
<input type="text" name="foo" />
<input type="submit" name="bar" />
</form>
[%- END %]
EOF
    ;

like $out, qr/<form method="get">\n<input.*?disabled="disabled".*?>\n<input.*?disabled="disabled".*?>.*/;
