#!/usr/bin/perl
use strict;

use Net::iContact;

=pod

=head1 NAME

createmessage.pl

=head1 DESCRIPTION

Creates a message

=head1 USAGE

    ./createmessage.pl username password apikey secret subject campaign

=cut

die("Usage: $0 username password apikey secret subject campaign\n") unless $#ARGV == 5;

my ($user, $pass, $key, $secret, $subject, $campaign) = @ARGV;
my $api = Net::iContact->new($user,$pass,$key,$secret);
$api->login();

my $msgid = $api->putmessage($subject, $campaign, do {local $/;<STDIN>}, '');
if ($msgid) {
    print "Created message: $msgid\n";
} else {
    print 'Got error: ' . $api->error->{code} . ': ' . $api->error->{message} . "\n";
}
=head1 SEE ALSO

C<Net::iContact>

=cut
