#!/usr/bin/perl
use strict;

use Net::iContact;

=pod

=head1 NAME

contactlookup.pl

=head1 DESCRIPTION

Looks up contacts by domain name.

=head1 USAGE

    ./contactlookup.pl username password apikey secret domain

=head1 EXAMPLES

    $ ./contactlookup.pl username password apikey sharedsecret example.com
    Test Contact <test@example.com>
    $ ./contactlookup.pl username password apikey sharedsecret '*'
    Test Contact <test@example.com>
    Jimbo Smith <jimbo@example.net>
    $ 

=cut

die("Usage: $0 username password apikey secret domain\n") unless $#ARGV == 4;

my ($user, $pass, $key, $secret, $domain) = @ARGV;
my $api = Net::iContact->new($user,$pass,$key,$secret,1);
$api->login();

my $contacts = $api->contacts('email' => '*@' . $domain);
for my $id (@$contacts) {
    my $contact = $api->contact($id);
    print $contact->{fname} .' '. $contact->{lname} .' <'. $contact->{email} . ">\n";
}

=head1 SEE ALSO

C<Net::iContact>

=cut
