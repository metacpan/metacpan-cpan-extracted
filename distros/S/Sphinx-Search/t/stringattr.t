#! /usr/bin/perl

use Test::More tests => 1;

use Sphinx::Search; 

my $sphinx = Sphinx::Search->new(); 
eval {
  my $r = $sphinx->SetFilter('mystring', ['4bb4afe18d9c4e550798b543']);
};
ok(! $@, "string attribute filtering");

