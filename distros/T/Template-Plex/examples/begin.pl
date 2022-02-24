use strict;
use warnings;
use feature ":all";

use Template::Plex;

my $template='This is a template with a BEGIN block to load time. Time before using BEGIN: @{[time]}. @{[ do{BEGIN {use Time::HiRes qw<time>}}]} Time after using BEGIN: @{[time]}';
my $ren=plex [$template],{};
say $ren->render();
