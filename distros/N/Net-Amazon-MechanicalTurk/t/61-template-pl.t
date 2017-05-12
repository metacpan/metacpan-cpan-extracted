#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN { push(@INC, "lib", "t"); }

use Net::Amazon::MechanicalTurk::Template;

my $file = "t/templates/61-template-ok.pl";
my $template = Net::Amazon::MechanicalTurk::Template->compile($file);

ok($template, "Compiled perl file.");

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

my $text = $template->execute($params);
#print $text, "\n";
ok(1, "Executed template");

$template = Net::Amazon::MechanicalTurk::Template->compile($file);
ok($template, "recompile worked");

$text = $template->execute($params);
#print $text, "\n";
ok(1, "Executed template");

eval {
    $template = Net::Amazon::MechanicalTurk::Template->compile("t/templates/61-template-bad.pl");
};
if ($@) {
    
}
