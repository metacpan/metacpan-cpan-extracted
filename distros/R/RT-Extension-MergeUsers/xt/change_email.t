#!/usr/bin/perl

use strict;
use warnings;
use RT::Extension::MergeUsers::Test tests => undef;

my ($id, $message);

# create N unique users  ($$ == our pid)
my $primary_user = RT::User->new($RT::SystemUser);
($id, $message) = $primary_user->Create( EmailAddress => "primary-$$\@example.com" );
ok($id, "Created 'primary' user? $message");
my $primary_id = $id;

my $secondary_user = RT::User->new($RT::SystemUser);
($id, $message) = $secondary_user->Create( EmailAddress => "secondary-$$\@example.com" );
ok($id, "Created 'secondary' user? $message");
my $secondary_id = $id;

# successfully merges users
($id, $message) = $secondary_user->MergeInto($primary_user);
ok($id, "Successfully merges users? $message");

{
    my $user = RT::User->new( $RT::SystemUser );
    $user->LoadByEmail( "primary-$$\@example.com" );
    is($user->id, $primary_user->id, "loaded user");

    my ($status, $msg) = $user->SetEmailAddress( "secondary-$$\@example.com" );
    ok $status, "changed primary address to something we already had"
        or diag "error: $msg";

    $user->LoadOriginal( id => $secondary_id );
    is($user->id, $secondary_id, "loaded original record");

    ok(!$user->EmailAddress, "secondary record has no email");
}

done_testing;
