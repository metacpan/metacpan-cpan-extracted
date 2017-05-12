#!/usr/bin/env perl
# Create an template
use warnings;
use strict;

use lib 'lib', '../WSSSIG/lib', '../XMLWSS/lib';
use Test::More tests => 7;
use Log::Report;

my $smd_example  = "examples/smd-templ.pl";
my $mark_example = "examples/mark-templ.pl";

use File::Slurp  qw/write_file/;

use Net::Domain::SMD::Schema ':ns10';
like(SMD10_NS, qr/^urn\:/);
like(MARK10_NS, qr/^urn\:/);

my $smd = Net::Domain::SMD::Schema->new(prepare => 'NONE');
ok(defined $smd, 'instantiate smd object');
isa_ok($smd, 'Net::Domain::SMD::Schema');

my $schemas = $smd->schemas;
isa_ok($schemas, 'XML::Compile::Cache');

write_file $smd_example, $schemas->template(PERL => 'smd:signedMark');
ok(-s $smd_example, "example created in $smd_example");

write_file $mark_example, $schemas->template(PERL => 'mark:mark');
ok(-s $mark_example, "example created in $mark_example");
