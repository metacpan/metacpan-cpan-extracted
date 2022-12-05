#!/usr/bin/perl
#
# create_user.pl

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
use RT::Client::REST::User;

unless ( @ARGV >= 3 ) {
    die "Usage: $0 username password user password\n";
}

my $rt =
  RT::Client::REST->new( server => ( $ENV{RTSERVER} || 'http://rt.cpan.org' ),
  );
$rt->login(
    username => shift(@ARGV),
    password => shift(@ARGV),
);

my $user;
try {
    $user = RT::Client::REST::User->new(
        rt       => $rt,
        name     => shift(@ARGV),
        password => shift(@ARGV),
    )->store;
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

print "User created. Id: ", $user->id, "\n";
