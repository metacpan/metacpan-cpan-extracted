#!perl

use strict;
use warnings;

use Test::Perl::Critic %{+{
  "-profile" => ".perlcriticrc",
  "-verbose" => 8,
}};
all_critic_ok();
