#!/usr/bin/env perl
use strict;
use Test::Spec;

use rlib;

use SQL::Concat qw(SQL);

use Cpanel::JSON::XS;

describe "TO_JSON", sub {
  describe "SQL(['select ?', 'foo'])", sub {
    it q{should be encoded ["select ?","foo"]}, sub {
      my $cat = SQL(['select ?', 'foo']);
      my $enc = Cpanel::JSON::XS->new->convert_blessed;
      my $jsonStr = $enc->encode($cat);
      is($jsonStr, q{["select ?","foo"]});
    };
  };
};

runtests unless caller;
