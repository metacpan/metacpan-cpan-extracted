use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Path qw(remove_tree);
use File::Spec;
use FindBin;

use lib "$FindBin::Bin/../lib";

use PAX::CodeUnitCompiler;
use PAX::StandaloneImage;

my $compiler = PAX::CodeUnitCompiler->new;
my $unit = $compiler->compile(
    path => "$FindBin::Bin/fixtures/app_lib/ProtoOps.pm",
    kind => 'lib',
    logical_path => 'lib/app_lib/ProtoOps.pm',
);
is($unit->{packaging}, 'compiled_pcu_v1', 'prototype fixture compiles to PCU');

require JSON::PP;
my $record = JSON::PP->new->decode($unit->{bytes});
my ($sub) = grep { ($_->{name} // '') eq 'constant_one' } @{ $record->{subs} // [] };
ok($sub, 'prototype fixture records compiled sub');
is($sub->{prototype}, '($$)', 'prototype is recorded for compiled sub');

my $root = File::Spec->catdir(File::Spec->tmpdir, "pax-proto-test-$$");
remove_tree($root) if -d $root;
local $ENV{PAX_STANDALONE_ROOT} = $root;
my $builder = PAX::StandaloneImage->new(root => $root);
my $built = $builder->build(
    name => 'proto-app',
    entrypoint => "$FindBin::Bin/fixtures/proto_app.pl",
    lib_dirs => ["$FindBin::Bin/fixtures/app_lib"],
    runtime_mode => 'bundled_perl',
);
is($built->{status}, 'built', 'prototype standalone image built');

my $binary = abs_path($built->{standalone}{output_path});
my $output = `env -i PATH=/nonexistent TMPDIR=/tmp $binary`;
is($? >> 8, 0, 'prototype standalone runs');
is($output, "1\n", 'prototype compiled sub preserves call behavior');

done_testing;

=pod

=head1 NAME

t/prototype_compiled_sub.t - regression coverage for prototype-aware compiled subroutine handling

=head1 DESCRIPTION

This test exercises prototype-aware compiled subroutine handling. It exists so PAX changes can be checked against a
repeatable behavioral contract instead of informal manual runs.

=head1 TEST PLAN

The assertions in this file cover the specific success, failure, and edge-case
paths needed for prototype-aware compiled subroutine handling. Extend this file when behavior changes in that area.

=head1 HOW TO RUN

  prove -lv t/prototype_compiled_sub.t

=head1 WHY IT EXISTS

PAX uses this test to keep prototype-aware compiled subroutine handling from regressing while the compiler,
standalone runtime, and packaging logic continue to evolve.

=cut
