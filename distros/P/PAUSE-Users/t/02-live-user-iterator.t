#!perl

use strict;
use warnings;
use PAUSE::Users;
use Test::More 0.88 tests => 3;

my $iterator;
my %got;
my %expected =
    (
        CRI     => 'Sun Apr 30 20:15:55 2006',
        HAVOC   => 'Wed Feb 27 04:52:57 2008',
        LETO    => 'Tue Jul 17 21:53:22 2001',
        DOGGY   => 'Fri Jul 30 01:30:57 2010',
        JWAR    => 'Sun Aug 29 12:32:22 2010',
    );

eval { $iterator = PAUSE::Users->new()->user_iterator() };

SKIP: {
    skip("looks like you're offline", 3) if $@;

    ok(defined($iterator), "create PAUSE user iterator");

    while (my $user = $iterator->next_user) {
        next unless exists($expected{ $user->id });
        $got{ $user->id } = gmtime($user->introduced);
    }

    ok(keys(%expected) == keys(%got), "Did we see everyone?");

    my $expected_as_string = hash_as_string(\%expected);
    my $got_as_string      = hash_as_string(\%got);

    is($got_as_string, $expected_as_string,
       "did we get the expected timestamp for everyone?");
}

sub hash_as_string
{
    my $hashref = shift;

    return join '',
           map { "$_\t$expected{$_}" }
           sort
           keys %$hashref;
}

