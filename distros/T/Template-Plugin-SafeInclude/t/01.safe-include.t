use strict;
use warnings;

use Test::More tests => 4;
use Template;
use FindBin qw/$Bin/;

{
my $template = <<__TEMPLATE__;
[% USE SafeInclude() %]
[% SafeInclude.inc("template/test.inc") %]
__TEMPLATE__

my $tt = Template->new(INCLUDE_PATH => $Bin);
$tt->process(\$template, {}, \my $out) or die $tt->error;

like($out, qr/Template-Plugin-SafeInclude Test/, "exists file included.");
}

{
my $template = <<__TEMPLATE__;
[% USE SafeInclude(verbose => 1) %]
[% SafeInclude.inc("template/test.inc") %]
__TEMPLATE__

my $tt = Template->new(INCLUDE_PATH => $Bin);
$tt->process(\$template, {}, \my $out) or die $tt->error;

like($out, qr/Template-Plugin-SafeInclude Test/, "exists file included. verbose on.");
}

{
my $template = <<__TEMPLATE__;
[% USE SafeInclude() %]
[% SafeInclude.inc("template/test_not_exists.inc") %]
__TEMPLATE__

my $tt = Template->new(INCLUDE_PATH => $Bin);
$tt->process(\$template, {}, \my $out) or die $tt->error;

like($out, qr/^\s*$/, "not exists file.");
}

{
my $template = <<__TEMPLATE__;
[% USE SafeInclude(verbose => 1) %]
[% SafeInclude.inc("template/test_not_exists.inc") %]
__TEMPLATE__

my $tt = Template->new(INCLUDE_PATH => $Bin);
$tt->process(\$template, {}, \my $out) or die $tt->error;
my $reg = quotemeta "<!-- file error - template/test_not_exists.inc: not found -->";
like($out, qr/$reg/, "not exists file. verbose on.");
}

