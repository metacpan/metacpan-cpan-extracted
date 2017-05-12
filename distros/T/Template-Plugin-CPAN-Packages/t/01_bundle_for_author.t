#!/usr/bin/env perl

use warnings;
use strict;
use FindBin '$Bin';
use Template;
use Template::Plugin::CPAN::Packages;
use Test::Differences;
use Test::More tests => 1;

my $template = <<'EOTEMPLATE';
Before the template.

[%
    USE c = CPAN.Packages "${Bin}/02packages.details.txt.gz";
    c.bundle_for_author(
        'cpanid'   => 'MARCEL',
        'unwanted' => [ 'Class::Factory::Patched' ]
    );
%]

After the template.
EOTEMPLATE

my $tt = Template->new || die Template->error(), "\n";

my $vars = {
    Bin => $Bin,
};

my $result;

$tt->process(\$template, $vars, \$result) || die $tt->error();

my $expect = <<EOEXPECT;
Before the template.

Class::Accessor::Complex

Class::Accessor::Constructor

Class::Accessor::FactoryTyped

Class::Accessor::Installer

Class::Factory::Enhanced

Class::Null

Class::Scaffold

Class::Value

Class::Value::Contact

Class::Value::Net

After the template.
EOEXPECT

eq_or_diff $result, $expect, 'bundle_for_author';

