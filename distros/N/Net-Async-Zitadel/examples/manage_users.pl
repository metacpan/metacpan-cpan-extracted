#!/usr/bin/env perl

# manage_users.pl — Async CRUD operations on Zitadel users
#
# Usage:
#   ZITADEL_ISSUER=https://zitadel.example.com \
#   ZITADEL_TOKEN=my-pat \
#   ZITADEL_USER_ID=123456789 \
#   perl examples/manage_users.pl

use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::Zitadel;

my $issuer  = $ENV{ZITADEL_ISSUER}  or die "ZITADEL_ISSUER required\n";
my $token   = $ENV{ZITADEL_TOKEN}   or die "ZITADEL_TOKEN required (PAT or service account token)\n";
my $user_id = $ENV{ZITADEL_USER_ID} or die "ZITADEL_USER_ID required\n";

my $loop = IO::Async::Loop->new;

my $z = Net::Async::Zitadel->new(
    issuer   => $issuer,
    token    => $token,
    base_url => $issuer,
);
$loop->add($z);

my $mgmt = $z->management;

# Get user
print "Fetching user $user_id...\n";
my $user = $mgmt->get_user_f($user_id)->get;
printf "User: %s %s <%s>\n",
    $user->{user}{human}{profile}{firstName} // '',
    $user->{user}{human}{profile}{lastName}  // '',
    $user->{user}{human}{email}{email}       // '(no email)';

# List projects
print "\nListing projects...\n";
my $projects = $mgmt->list_projects_f->get;
my @proj = @{ $projects->{result} // [] };
if (@proj) {
    printf "  - %s (%s)\n", $_->{name}, $_->{id} for @proj;
} else {
    print "  (no projects found)\n";
}

# Set metadata on the user
print "\nSetting metadata...\n";
$mgmt->set_user_metadata_f($user_id, 'managed-by', 'manage_users.pl')->get;
print "Metadata set.\n";

# Read it back
my $meta = $mgmt->get_user_metadata_f($user_id, 'managed-by')->get;
printf "Metadata value: %s\n", $meta->{metadata}{value} // '(empty)';
