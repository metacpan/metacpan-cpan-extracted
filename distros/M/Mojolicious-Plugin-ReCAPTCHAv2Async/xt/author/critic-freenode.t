#!perl

use strict;
use warnings;

use Test::Perl::Critic (-theme => 'freenode', severity => 1);
all_critic_ok();
