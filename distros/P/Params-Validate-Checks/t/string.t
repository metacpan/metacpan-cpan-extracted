#! /usr/bin/perl
# 
# tests Params::Validate::Checks string check does what's required

use warnings;
use strict;

use Test::More tests => 8;
use Test::Exception;


BEGIN
{
  use_ok 'Params::Validate::Checks', qw<validate as>
      or die "Loading Params::Validate::Checks failed";
};

sub reflect
{
  my %arg = validate @_, {text => {as 'string'}};

  $arg{text} . reverse $arg{text};
}

lives_and { is reflect(text => 'Finsbury Park'), 'Finsbury ParkkraP yrubsniF' }
    'allows multiple words';

throws_ok { reflect(text => '') }
    qr/did not pass the 'not empty' callback/,
    'complains at empty string';

throws_ok { reflect(text => ' ') }
    qr/did not pass the 'not empty' callback/,
    'complains at just a space';

throws_ok { reflect(text => "\t") }
    qr/did not pass the 'not empty' callback/,
    'complains at just a tab character';

throws_ok { reflect(text => "  \t \t\t ") }
    qr/did not pass the 'not empty' callback/,
    'complains at just space and tab characters';

throws_ok { reflect(text => "hi\nthere") }
    qr/did not pass the 'one line' callback/,
    'complains at multi-line strings';

throws_ok { reflect(text => "greetings!\n") }
    qr/did not pass the 'one line' callback/,
    'complains at trailing line-break characters';
