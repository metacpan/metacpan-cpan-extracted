#!/usr/bin/perl

use strict;
use Test::More;

if (!eval { require Socket; Socket::inet_aton('api.cron.io') }) {
    plan skip_all => "Cannot connect to the API server";
} 
elsif ( ! $ENV{CRONIO_API_USERNAME} || ! $ENV{CRONIO_API_PASSWORD} ) {
    plan skip_all => "API credentials required for these tests";
}
else {
    plan tests => 8;
}

#untaint environment variables
my @params = map {my ($v) = $ENV{uc "CRONIO_$_"} =~ /\A(.*)\z/; $_ => $v} qw(api_username api_password);

use Net::CronIO;

my $cron = Net::CronIO->new( @params );
isa_ok($cron, 'Net::CronIO', 'object created');

my $job = $cron->create_cron(
    name => "Test",
    url => "http://byte-me.org/cronio/t.php",
    schedule => "55 * * * *",
);

is($job->{'name'}, "Test", "got job name");

$job = $cron->update_cron(
    id => $job->{'id'},
    name => "Foobar",
);

is($job->{'name'}, "Foobar", "changed job name");

my $job2 = $cron->create_cron(
    name => "Hoge",
    url => "http://byte-me.org/cronio/t.php",
    schedule => "57 * * * *",
);

is($job2->{'name'}, "Hoge", "got job2 name");

my $jobs = $cron->get_all_crons();
is(scalar(@{$jobs}), 2, "got 2 jobs");

is $cron->delete_cron( id => $job->{'id'} ), 1, "deleted job";

$jobs = $cron->get_all_crons();
is(scalar(@{$jobs}), 1, "got 1 job");

is $cron->delete_cron( id => $jobs->[0]->{'id'} ), 1, "deleted job2";
