#!/usr/bin/perl

=head1 NAME

t/OneTool/Configuration.t

=head1 DESCRIPTION

Tests for OneTool::Configuration module

=cut

use strict;
use warnings;

use FindBin;
use Test::More;

use lib "$FindBin::Bin/../../lib/";

require_ok('OneTool::Configuration');

my $DIR = "$FindBin::Bin/../conf/";

# 2 OneTool::Configuration::Directory() tests
my $dir = OneTool::Configuration::Directory();
like($dir, qr/\/conf$/, "OneTool::Configuration::Directory() => '$dir'");

my $dir2 = OneTool::Configuration::Directory($DIR);
like($dir2, qr/\/conf\/$/, "OneTool::Configuration::Directory('$DIR')");

# 3 OneTool::Configuration::Get() tests
my $conf = OneTool::Configuration::Get();
ok(!defined $conf, 'OneTool::Configuration::Get() => undef');

my $conf2 = OneTool::Configuration::Get({module => 'test'});
ok(
    defined $conf2 && ($conf2->{key} eq 'value'),
    "OneTool::Configuration::Get({ module => 'test' })"
  );

my $conf3 = OneTool::Configuration::Get({file => "${DIR}/test.conf"});
ok(defined $conf3 && ($conf3->{key} eq 'value'),
    "OneTool::Configuration::Get({ file => '${DIR}/test.conf' })");

done_testing(1 + 2 + 3);

=head1 AUTHOR

Sebastien Thebert <contact@onetool.pm>

=cut
