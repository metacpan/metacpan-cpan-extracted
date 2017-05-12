#!/usr/bin/perl
#Editor vim:syn=perl

use strict;
use warnings;
use Test::More 'no_plan';
use lib 'lib';

use Panotools::Makefile::Rule;
use Panotools::Makefile::Utils qw/platform/;
ok (1);

my $rule = new Panotools::Makefile::Rule;

$rule->Targets ('%.1');
$rule->Prerequisites ('%.pod');
$rule->Command ('pod2man', '--center', '$(PACKAGE)', '--release', '$(PACKAGE_VERSION)', '$<', '$@');
$rule->Command ('echo', '`uname -a`', '>', '$(TMPDIR)/foo');
$rule->Command ('uname', '-a', '>', '${TMPDIR}/bar', '&&', 'echo', '" ### (woo!) ### "');

platform ('linux');

print $rule->Assemble;

ok ($rule->Assemble =~ /%.1 : %.pod/);
ok ($rule->Assemble =~ /\tpod2man --center \$\(PACKAGE\) --release \$\(PACKAGE_VERSION\) \$< \$@/);
ok ($rule->Assemble =~ /\techo `uname -a` > \$\(TMPDIR\)\/foo/);
ok ($rule->Assemble =~ /\tuname -a > \${TMPDIR}\/bar && echo \\"\\ \\#\\#\\#\\ \\\(woo\\!\\\)\\ \\#\\#\\#\\ \\"/);
