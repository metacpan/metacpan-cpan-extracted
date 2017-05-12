#!/usr/bin/env perl
use Test::More;
use lib 'lib';
use Net::Jenkins::Utils qw(build_job_object build_api_object build_build_object);

my $api = build_api_object 'http://ci.jruby.org/job/jruby-git';
ok $api;

my $job = build_job_object 'http://ci.jruby.org/job/jruby-git';
ok $job;
ok $job->name;
ok $job->url;
ok $job->api;
ok $job->to_hashref;

my $build = build_build_object  'http://ci.jruby.org/job/jruby-git/4259';
ok $build;
ok $build->name;

my $hashref = $build->to_hashref;
ok $hashref;

done_testing;
