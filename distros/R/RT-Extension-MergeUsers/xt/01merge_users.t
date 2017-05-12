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

# load a nonexistent user
my $nonexistent_user = RT::User->new($RT::SystemUser);
#or, rather, don't load anything at all

# module should error if there isn't a valid user
($id, $message) = $primary_user->MergeInto($nonexistent_user);
ok(!$id, "Doesn't merge into non-existent users? $message");

# a user should not be able to be merged into itself
($id, $message) = $primary_user->MergeInto($primary_user);
ok(!$id, "Doesn't merge a user into itself? $message");

# successfully merges users
($id, $message) = $secondary_user->MergeInto($primary_user);
ok($id, "Successfully merges users? $message");

# Check that the comments are useful
{
    my $from = RT::User->new( $RT::SystemUser );
    $from->LoadOriginal( id => $secondary_user->id );
    is( $from->Comments, "Merged into primary-$$\@example.com (".$primary_user->id.")",
        "Comments contain the right user that was merged into"
    );

    my $into = RT::User->new( $RT::SystemUser );
    $into->LoadOriginal( id => $primary_user->id );
    is( $into->Comments, "secondary-$$\@example.com (".$secondary_user->id.") merged into this user",
        "Comments contain the right user that was merged in"
    );
}

# recognizes already-merged users
($id, $message) = $secondary_user->MergeInto($primary_user);
ok(!$id, "Recognizes secondary as child? $message");
($id, $message) = $primary_user->MergeInto($secondary_user);
ok(!$id, "Recognizes primary as parent? $message");

# DTRT with multiple inheritance
$quaternary_user->MergeInto($tertiary_user);
($id, $message) = $tertiary_user->MergeInto($primary_user);
ok($id, "Merges users with children? $message");

# recognizes siblings
($id, $message) = $tertiary_user->MergeInto($secondary_user);
ok(!$id, "Recognizes siblings? $message");

# recognizes children of children as children of the primary
($id, $message) = $quaternary_user->MergeInto($primary_user);
ok(!$id, "Recognizes children of children? $message");

# Associates tickets from a secondary address with the primary address
my $ticket = RT::Ticket->new($RT::SystemUser);
my $transaction_obj;
($id, $transaction_obj, $message)
    = $ticket->Create(  Requestor    => ["secondary-$$\@example.com"],
                        Queue        => 'general',
                        Subject      => 'MergeUsers test',
                     );
ok($ticket->RequestorAddresses =~ /primary-$$\@example.com/, "Canonicalizes tickets properly: @{[$ticket->RequestorAddresses]}");

# allows unmerging
($id, $message) = $secondary_user->UnMerge;
ok($id, "Unmerges users? $message");

# Associates tickets from unmerged address with the secondary address
my $ticket2 = RT::Ticket->new($RT::SystemUser);
($id, $transaction_obj, $message)
    = $ticket2->Create(  Requestor    => ["secondary-$$\@example.com"],
                        Queue        => 'general',
                        Subject      => 'UnMergeUsers test',
                     );
ok($ticket2->RequestorAddresses =~ /secondary-$$\@example.com/, "Unmerges tickets properly: @{[$ticket2->RequestorAddresses]}");

done_testing;
