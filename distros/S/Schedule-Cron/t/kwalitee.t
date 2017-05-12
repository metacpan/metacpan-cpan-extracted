#!/usr/bin/perl
use Test::More;

eval { 
  require Test::Kwalitee; 
};

if ($@) {
    plan( skip_all => 'Test::Kwalitee not installed; skipping' ); 
} else {
    Test::Kwalitee->import();
}
