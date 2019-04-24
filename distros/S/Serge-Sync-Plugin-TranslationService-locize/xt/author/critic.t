#!perl

use strict;
use warnings;

use Test::Perl::Critic (-profile => ".perlcriticrc") x!! -e ".perlcriticrc";
all_critic_ok();
