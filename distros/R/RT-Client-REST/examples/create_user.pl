#!/usr/bin/perl
#
# create_user.pl

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::User;

unless (@ARGV >= 3) {
    die "Usage: $0 username password user password\n";
}

my $rt = RT::Client::REST->new(
    server  => ($ENV{RTSERVER} || 'http://rt.cpan.org'),
);
$rt->login(
    username=> shift(@ARGV),
    password=> shift(@ARGV),
);

my $user;
try {
    $user = RT::Client::REST::User->new(
        rt  => $rt,
        name => shift(@ARGV),
        password => shift(@ARGV),
    )->store;
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

print "User created. Id: ", $user->id, "\n";
