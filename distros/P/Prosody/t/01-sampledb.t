#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
# use Data::Printer;
# use Data::Dumper;

use Prosody::Storage::SQL;

my $storage = Prosody::Storage::SQL->new(
	driver => 'SQLite3',
	database => $Bin.'/data/prosody.sqlite',
);

isa_ok($storage,'Prosody::Storage::SQL');
is_deeply [ $storage->host_list ], [ qw( test.domain ) ], 'Fetching hostlist';
is_deeply [ sort $storage->user_list('test.domain') ], [ qw( testone testthree testtwo ) ], 'Fetching userlist of test.domain';
is_deeply [ sort $storage->user_list ], [ qw( testone testthree testtwo ) ], 'Fetching userlist of all hosts';

#my @users = $storage->all_user('test.domain');
#my @all_users = $storage->all_user;

my $one = $storage->user('testone@test.domain');

# print("user('testone\@test.domain')");
# print Dumper $one;

is_deeply( $one, { accounts => { password => 'testpass' } }, 'Checking values of testone@test.domain');

# my $two = $storage->user('testtwo@test.domain');

# print("user('testtwo\@test.domain')");
# print Dumper $two;

# my $three = $storage->user('testthree@test.domain');

# print("user('testthree\@test.domain')");
# print Dumper $three;

done_testing;
