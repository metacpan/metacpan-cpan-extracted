#!/usr/bin/perl -w

BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for release candidate testing');
  }
}


use strict;
use warnings;
use Test::More;
 
if (eval {require Test::Perl::Critic}) {
    Test::Perl::Critic->import(
        -severity => 1,
        -exclude => ['RequireRcsKeywords', 'RequireExplicitPackage'],
    );
    Test::Perl::Critic::all_critic_ok();
} else {
    plan skip_all => "couldn't load Test::Perl::Critic";
}