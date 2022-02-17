use strict;
use warnings;
use feature ":all";

use Template::Plex;

my $template='This is a template with a BEGIN block to load time: @{[time]}.  a= $a @{[ do{BEGIN {use Time::HiRes qw<time>}print "a is: ",$a}]}  Time is: @{[time]}, package is: @{[__PACKAGE__]}';
my $ren=plex [$template],{};
say $ren->render();
