#!/usr/bin/perl

use Test::More tests => 1;

BEGIN {
  use_ok(
    'Perl::Critic::Policy::ValuesAndExpressions::ProhibitAccessOfPrivateData'
  );
}

diag(
  "Testing Perl::Critic::Nits $Perl::Critic::Policy::Nits::VERSION, Perl $],$^X"
);
