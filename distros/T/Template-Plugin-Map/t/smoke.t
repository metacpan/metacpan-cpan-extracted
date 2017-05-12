#!/usr/bin/env perl
#

package Person;

sub new {
    my ($class, $name) = @_;

    bless {name => $name}, $class;
}

sub name {
    shift->{name}
}

package main;

use strict;
use Template::Test;

my @people = map { Person->new($_) } qw(Mike Jim Bill);

my %vars = (
    people => \@people,
    person => $people[0]);

my $tt = Template->new;

test_expect(<<END,$tt, \%vars);
--test--
[% USE Map -%]
[% people.map('name').join(':') %]
--expect--
Mike:Jim:Bill

--test--
[% USE Map -%]
[% person.map('name').join(':') %]
--expect--
Mike

END
