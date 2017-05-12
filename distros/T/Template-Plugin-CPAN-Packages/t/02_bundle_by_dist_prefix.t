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
    c.bundle_by_dist_prefix(
        'prefix'   => 'Class-Accessor',
        'unwanted' => [ 'Class::Accessor::Classy' ]
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

Class::Accessor

Class::Accessor::Assert

Class::Accessor::Chained

Class::Accessor::Children

Class::Accessor::Class

Class::Accessor::Complex

Class::Accessor::Constructor

Class::Accessor::FactoryTyped

Class::Accessor::Fast::Contained

Class::Accessor::Grouped

Class::Accessor::Installer

Class::Accessor::Lvalue

Class::Accessor::Named

Class::Accessor::Ref

Class::AccessorMaker

After the template.
EOEXPECT

eq_or_diff $result, $expect, 'bundle_by_dist_prefix';

