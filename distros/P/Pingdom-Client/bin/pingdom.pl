#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;
use Getopt::Long;
use Pingdom::Client;

my $username = undef;
my $password = undef;
my $apikey = undef;

GetOptions(
        'username=s'    => \$username,
        'password=s'    => \$password,
        'apikey=s'      => \$apikey,
);

my $API = Pingdom::Client::->new({
        'username' => $username,
        'password' => $password,
        'apikey'   => $apikey,
});

print Dumper($API->contacts());

=head1 NAME

pingdom cli

=cut
