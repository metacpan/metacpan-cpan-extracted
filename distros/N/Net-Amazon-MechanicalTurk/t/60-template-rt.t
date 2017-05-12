#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;
BEGIN { push(@INC, "lib", "t"); }
use Net::Amazon::MechanicalTurk::Template;

sub nlfix {
    my $text = shift;
    $text =~ s/\r//gm;
    return $text;
}

my $file = "t/templates/60-template.rt";
my $template = Net::Amazon::MechanicalTurk::Template->compile($file);

ok($template, "Compiled mtt file.");

my $params = {
    title    => "The Big One",
    subTitle => "hmmm",
    genre    => "Who knows?",
    author   => "Bob",
    family => {
        kid  => ['Toby', 'Charlie'],
        wife => 'Meg'
    }
};

print Net::Amazon::MechanicalTurk::DataStructure->toString($params), "\n";

my $text = $template->execute($params);

my $expected = <<END_TXT;
Title:    The Big Onehmmm-X
Genre:    Who knows?
Author:   Bob
Missing1: 
Escaped:  \${}
Escaped2: \$\\{}
Kid-1:    Toby
Kid-2:    Charlie
Wife:     Meg
END_TXT

print $expected, "\n";

$expected =~ s/\s*$//s;

print Net::Amazon::MechanicalTurk::DataStructure->toString($params), "\n";
my $p = Net::Amazon::MechanicalTurk::DataStructure->toProperties($params);
while (my ($k,$v) = each %$p) {
  printf "  [%s] = [%s]\n", $k, $v;
}

print "----\n", $text, "\n---------\n";

$text = nlfix($text);
$expected = nlfix($expected);

is($text, $expected, "rt template execute");

