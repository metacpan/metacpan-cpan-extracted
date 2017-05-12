#!/usr/bin/perl

use strict;
use warnings;

use RTF::Parser;
use Test::More tests => 2;

# First we check that destinations are skipped

my $parser = RTF::Parser->new();

{
    no warnings 'redefine';
    *RTF::Parser::text = sub { my $self = shift; $self->{_TEST_BUFF} = shift; };
}

$parser->parse_string('{\rtf{\*\asdf Quick Brown}}');

ok( !$parser->{_TEST_BUFF}, "No text recorded" );

# And then that they are

$parser = RTF::Parser->new();
$parser->dont_skip_destinations(1);
$parser->parse_string('{\rtf{\*\asdf Quick Brown}}');

is( $parser->{_TEST_BUFF}, "Quick Brown", "Text recorded" );
