#!/usr/bin/perl
use strict;

use Net::iContact;

=pod

=head1 NAME

printlists.pl

=head1 DESCRIPTION

Logs into an account and prints the ID, name, and description of every
defined list.

=head1 USAGE

    ./printlists.pl username password apikey secret

=cut

die("Usage: $0 username password apikey secret\n") unless $#ARGV == 3;

my ($user, $pass, $key, $secret) = @ARGV;
my $api = Net::iContact->new($user,$pass,$key,$secret);
$api->login();
for my $id (@{$api->lists}) {
    my $list = $api->list($id);
    print $list->{name} . '(' . $list->{id} . '): ' . $list->{description} . "\n";
}

=head1 SEE ALSO

C<Net::iContact>

=cut
