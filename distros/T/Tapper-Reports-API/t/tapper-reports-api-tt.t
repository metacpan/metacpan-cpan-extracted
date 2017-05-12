#! /usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Test::More;

use Tapper::Reports::API;
use Test::MockModule;

my $result;
use subs qw/print/;
sub print { $result = join " ", @_ ; return}

my $mock_net = Test::MockModule->new('Tapper::Reports::API');
$mock_net->mock('get_payload', sub{return q(
[%- res = reportdata('{ "suite.name" => "perfmon" } :: //tap/tests_planned') -%]
Planned tests:
[%- FOREACH r IN res %]
  [% r -%]
[% END %]
)});

close STDOUT;
my $output;
open STDOUT, ">", \$output or die "Can't dup STDOUT: $!";
my $api = Tapper::Reports::API->new();
isa_ok($api, 'Tapper::Reports::API');
$api->handle_tt();
is($output, "Planned tests:
  4
  3
  4
  3\n", 'TT with reportdata');

done_testing();
