#!/usr/bin/perl

use strict;
use warnings;

use RT::Extension::TravisCI::Test tests => 3;

use RT::Extension::TravisCI;

use RT;
RT->LoadConfig;

my $ans = RT::Extension::TravisCI::get_status('rt', '4.4-trunk', RT::CurrentUser->new($RT::SystemUser));

ok($ans->{success}, "Successfully queried TravisCI branch");
is($ans->{result}->{name}, '4.4-trunk', "Branch name is correct");
is(ref($ans->{result}->{last_build}), 'HASH', "We have a build");




