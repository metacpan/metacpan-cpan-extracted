#!/usr/bin/perl
#
# This scripts reports a new RT::Client::REST bug to CPAN.

use strict;
use warnings;

use Error qw(:try);
use RT::Client::REST;
use RT::Client::REST::Ticket;
use Term::ReadKey;

my $rt = RT::Client::REST->new(server => 'http://rt.cpan.org');

my $dist = 'RT-Client-REST';    # This is the name of the queue.

my ($username, $password);

print "RT Username: ";
chomp($username = <>);

print "RT Password: ";
ReadMode 2;
chomp($password = <>);
ReadMode 0;

$| = 1;

print "\nAuthenticating...";

try {
    $rt->login(username => $username, password => $password);
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

print "\nShort description of the problem (one line):\n";
chomp(my $subject = <>);

print "Long description (lone period or Ctrl-D to end):\n";
my $description = '';
while (<>) {
    chomp;
    last if '.' eq $_;
    $description = $description . "\n" . $_;
}

my $ticket;
try {
    $ticket = RT::Client::REST::Ticket->new(
        rt => $rt,
        subject => $subject,
        queue => $dist,
    )->store;
    $ticket->correspond(message => $description);
} catch Exception::Class::Base with {
    my $e = shift;
    die ref($e), ": ", $e->message || $e->description, "\n";
};

print "Created ticket ", $ticket->id, " in queue ", $ticket->queue, "\n";
