#!/usr/bin/env perl

use Test::Chimps::Server;

my $server = Test::Chimps::Server->new(
  base_dir                  => '/some/dir',
  list_template             => 'list.tmpl',
  variables_validation_spec => {
    project   => 1,
    revision  => 1,
    committer => 1,
    duration  => 1,
    osname    => 1,
    osvers    => 1,
    archname  => 1
  }
);

$server->handle_request;
