#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Synth::Config';

my $db_file = 'test.db';

END {
    ok -e $db_file, 'db exists';
    if (-e $db_file) {
        unlink $db_file;
        unlink $db_file . '-shm';
        unlink $db_file . '-wal';
        ok !-e $db_file, "$db_file removed";
    }
    done_testing();
}

my $model = 'Moog Matriarch';
my $first = 'Simple 001';
my $initial;

my $obj = new_ok 'Synth::Config' => [
  model  => $model,
  dbname => $db_file,
#  verbose => 1,
];

subtest defaults => sub {
  is $obj->model, 'moog_matriarch', 'model';
  is $obj->verbose, 0, 'verbose';
};

subtest yaml => sub {
  my $got = $obj->import_yaml(
    file    => 'eg/Modular.yaml',
    patches => [ $first ],
  );
  is @$got, 1, 'import_yaml';
  $initial = $obj->recall_setting_names;
  is @$initial, 1, 'recall_setting_names';
};

subtest settings => sub {
  my $name   = 'Test setting!';
  my $expect = {
    name       => $name,
    group      => 'foo',
    parameter  => 'bar',
    control    => 'knob',
    bottom     => 20,
    top        => 20_000,
    value      => 200,
    unit       => 'Hz',
    is_default => 0,
  };
  # make an initial setting
  my $id1 = $obj->make_setting(%$expect);
  ok $id1, "make_setting (id: $id1)";
  # recall that setting
  my $setting = $obj->recall_setting(id => $id1);
  $expect->{id} = $id1;
  is_deeply $setting, $expect, 'recall_setting';
  # update a single field in the setting
  my $got = $obj->make_setting(id => $id1, is_default => 1);
  is $got, $id1, 'make_setting update';
  # recall that same setting
  $setting = $obj->recall_setting(id => $id1);
  is keys(%$setting), keys(%$expect), 'recall_setting';
  # check the updated field
  ok $setting->{is_default}, 'is_default';
  # undef a single field in the setting
  $got = $obj->make_setting(id => $id1, is_default => undef);
  is $got, $id1, 'make_setting undef update';
  # recall that same setting
  $setting = $obj->recall_setting(id => $id1);
  # check the updated field
  ok !$setting->{is_default}, 'is_default';
  # search the settings for a particular key
  my $settings = $obj->search_settings(group => $expect->{group});
  is_deeply $settings, [ $setting ], 'search_settings';
  # another!
  $expect = {
    name       => $name,
    group      => 'mixer',
    parameter  => 'output',
    control    => 'patch',
    group_to   => 'modulation',
    param_to   => 'rate-in',
    is_default => 0,
  };
  # make a second setting
  my $id2 = $obj->make_setting(%$expect);
  is $id2, $id1 + 1, "make_setting (id: $id2)";
  # recall that setting
  my $setting2 = $obj->recall_setting(id => $id2);
  $expect->{id} = $id2;
  is_deeply $setting2, $expect, 'recall_setting';
  # recall named settings
  $settings = $obj->search_settings(name => $name);
  is_deeply $settings,
    [ $setting, $setting2 ],
    'search_settings';
  # search the settings for two keys
  $settings = $obj->search_settings(group => $expect->{group}, name => $name);
  is_deeply $settings, [ $setting2 ], 'search_settings';
  # recall setting names
  my $setting_names = $obj->recall_setting_names;
  is_deeply $setting_names, [ $first, $name ], 'recall_setting_names';
  # recall all for model
  $settings = $obj->recall_settings;
  isa_ok $settings->[0], 'HASH', 'recall_settings';
  # make a third setting
  $expect = {
    name       => 'Foo',
    group      => 'foo',
    parameter  => 'output',
    control    => 'patch',
    group_to   => 'modulation',
    param_to   => 'bar',
  };
  my $id3 = $obj->make_setting(%$expect);
  is $id3, $id2 + 1, "make_setting (id: $id3)";
  # remove settings
  $obj->remove_setting(id => $id1);
  $settings = $obj->search_settings(name => $name);
  is_deeply $settings, [ $setting2 ], 'remove_setting';
  $obj->remove_settings(name => $name);
  is_deeply $settings, [ $setting2 ], 'already removed';
  $obj->remove_settings;
  $settings = $obj->recall_settings;
  is_deeply $settings, [], 'recall_settings';
};

subtest graphviz => sub {
  my $settings = $obj->search_settings(name => $initial);
  my $got = $obj->graphviz(
    settings   => $settings,
    patch_name => $first,
  );
  isa_ok $got, 'GraphViz2';
};

subtest specs => sub {
  my $expect = {
    order      => [qw(group parameter control group_to param_to bottom top value unit is_default)],
    group      => [],
    parameter  => {},
    control    => [qw(knob switch slider patch)],
    group_to   => [],
    param_to   => [],
    bottom     => [qw(off 0 1 7AM 20)],
    top        => [qw(on 3 4 6 7 5PM 20_000 100%)],
    value      => [],
    unit       => [qw(Hz o'clock)],
    is_default => [0, 1],
  };
  my $id = $obj->make_spec(%$expect);
  ok $id, 'make_spec';
  my $got = $obj->recall_spec(id => $id);
  $expect->{id} = $id;
  is_deeply $got, $expect, 'recall_spec';
  $got = $obj->recall_specs;
  $expect->{model} = $obj->model;
  is_deeply $got, $expect, 'recall_specs';
};

subtest cleanup => sub {
  # remove the model
  $obj->remove_model(model => $model);
  my $settings = eval { $obj->recall_setting_names };
  is $settings, undef, 'remove_model';
};
