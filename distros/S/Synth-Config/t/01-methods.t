#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

use_ok 'Synth::Config';

my $model = 'Moog Matriarch';

my $obj = new_ok 'Synth::Config' => [
  model   => $model,
  dbname  => 'test.db',
  verbose => 1,
];

subtest defaults => sub {
  is $obj->model, 'moog_matriarch', 'model';
  is $obj->verbose, 1, 'verbose';
};

subtest settings => sub {
  my $name   = 'Test setting!';
  my $expect = {
    name       => $name,
    group      => 'filter',
    parameter  => 'cutoff',
    control    => 'knob',
    bottom     => 20,
    top        => 20_000,
    value      => 200,
    unit       => 'Hz',
    is_default => 0,
  };
  # make an initial setting
  my $id = $obj->make_setting(%$expect);
  ok $id, "make_setting (id: $id)";
  # recall that setting
  my $setting = $obj->recall_setting(id => $id);
  is_deeply $setting, $expect, 'recall_setting';
  # update a single field in the setting
  my $got = $obj->make_setting(id => $id, is_default => 1);
  is $got, $id, 'make_setting update';
  # recall that same setting
  $setting = $obj->recall_setting(id => $id);
  is keys(%$setting), keys(%$expect), 'recall_setting';
  # check the updated field
  ok $setting->{is_default}, 'is_default';
  # search the settings for a particular key
  my $settings = $obj->search_settings(group => $expect->{group});
  is_deeply $settings, [ { $id => $setting } ], 'search_settings';
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
  is $id2, $id + 1, "make_setting (id: $id2)";
  # recall that setting
  my $setting2 = $obj->recall_setting(id => $id2);
  is_deeply $setting2, $expect, 'recall_setting';
  # recall named settings
  $settings = $obj->search_settings(name => $name);
  is_deeply $settings,
    [ { $id => $setting }, { $id2 => $setting2 } ],
    'search_settings';
  # search the settings for two keys
  $settings = $obj->search_settings(group => $expect->{group}, name => $name);
  is_deeply $settings, [ { $id2 => $setting2 } ], 'search_settings';
  # recall names
  my $names = $obj->recall_names;
  is_deeply $names, [ $name ], 'recall_names';
  # recall all for model
  $settings = $obj->recall_all;
  is_deeply $settings, [
    { $id => $setting },
    { $id2 => $setting2 }
  ], 'recall_all';
  # remove a setting
  $obj->remove_setting(id => $id);
  $settings = $obj->search_settings(name => $name);
  is_deeply $settings, [ { $id2 => $setting2 } ], 'remove_setting';
  $obj->remove_settings(name => $name);
  $settings = $obj->search_settings(name => $name);
  is_deeply $settings, [], 'remove_settings';
};

subtest cleanup => sub {
  # remove the model
  $obj->remove_model(model => $model);
  my $settings = eval { $obj->recall_all };
  is $settings, undef, 'remove_model';
  # remove the database
#  ok -e 'test.db', 'db exists';
#  unlink 'test.db';
#  unlink 'test.db-shm';
#  unlink 'test.db-wal';
#  ok !-e 'test.db', 'db unlinked';
};

done_testing();
