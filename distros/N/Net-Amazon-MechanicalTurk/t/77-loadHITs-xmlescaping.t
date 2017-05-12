#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 6;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::Command::LoadHITs;
use Net::Amazon::MechanicalTurk::XMLParser;

sub testEscape {
    my ($text, $expected) = @_;
    my $actual = Net::Amazon::MechanicalTurk::Command::LoadHITs::xmlEntityEscape($text);
    is($actual, $expected);
    my $parser = Net::Amazon::MechanicalTurk::XMLParser->new;
    my $xml = $parser->parse("<data>$actual</data>");
    is($text, $xml->{_value});
    return $actual;
}


testEscape("Is 5 < 6?", "Is 5 &lt; 6?");
testEscape("A&B\nIs 5 < 6?", "A&amp;B\nIs 5 &lt; 6?");
testEscape("&'quo\"ted&'", "&amp;&apos;quo&quot;ted&amp;&apos;");
