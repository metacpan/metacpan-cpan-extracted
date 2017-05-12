#!/usr/bin/perl

use strict;
use warnings;
use RT::Extension::MergeUsers::Test tests => undef;

my ($id, $message);

# create N unique users  ($$ == our pid)
my $primary_user = RT::User->new($RT::SystemUser);
($id, $message) = $primary_user->Create( EmailAddress => "primary-$$\@example.com" );
ok($id, "Created 'primary' user? $message");

my $secondary_user = RT::User->new($RT::SystemUser);
($id, $message) = $secondary_user->Create( EmailAddress => "secondary-$$\@example.com" );
ok($id, "Created 'secondary' user? $message");

my $tertiary_user = RT::User->new($RT::SystemUser);
($id, $message) = $tertiary_user->Create( EmailAddress => "tertiary-$$\@example.com" );
ok($id, "Created 'tertiary' user? $message");

my $quaternary_user = RT::User->new($RT::SystemUser);
($id, $message) = $quaternary_user->Create( EmailAddress => "quaternary-$$\@example.com" );
ok($id, "Created 'quaternary' user? $message");

my %seen;
{
    my $users = RT::Users->new(RT->SystemUser);
    $users->LimitToEnabled;
    while (my $user = $users->Next) {
        $seen{$user->id}++;
    }
}

# successfully merges users
($id, $message) = $secondary_user->MergeInto($primary_user);
ok($id, "Successfully merges users? $message");

{
    my $users = RT::Users->new(RT->SystemUser);
    $users->LimitToEnabled;
    while (my $user = $users->Next) {
        $seen{$user->id}--;
    }
    ok( delete $seen{ $secondary_user->id }, "havn't seen merged user" );
    ok( !scalar (grep $_, values %seen), "seen everybody else");
}

done_testing;
