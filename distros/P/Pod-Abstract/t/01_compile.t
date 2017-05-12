#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;

my @modules = qw(
Pod::Abstract
Pod::Abstract::Node
Pod::Abstract::Tree
Pod::Abstract::BuildNode
Pod::Abstract::Path
Pod::Abstract::Parser
Pod::Abstract::Filter
Pod::Abstract::Filter::cut
Pod::Abstract::Filter::uncut
Pod::Abstract::Filter::sort
Pod::Abstract::Filter::overlay
Pod::Abstract::Filter::unoverlay
Pod::Abstract::Filter::add_podcmds
Pod::Abstract::Filter::clear_podcmds
Pod::Abstract::Filter::summary
Pod::Abstract::Filter::find
Pod::Abstract::Filter::number_sections
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
