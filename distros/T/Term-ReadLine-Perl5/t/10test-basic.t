#!/usr/bin/env perl
use strict; use warnings;
use lib '../lib' ;

use Test::More;

BEGIN {
  # stop reading ~/.inputrc
  $ENV{'INPUTRC'} = '/dev/null';
  $ENV{'COLUMNS'} = '80';
  $ENV{'LINES'}    = '25';
  use_ok( 'Term::ReadLine::Perl5' );
}

require 'Term/ReadLine/Perl5/readline.pm';
ok(defined($Term::ReadLine::Perl5::VERSION),
   "\$Term::ReadLine::Perl5::Version number is set");

note('ctrl()');
is(Term::ReadLine::Perl5::readline::ctrl(ord('A')), 1);
is(Term::ReadLine::Perl5::readline::ctrl(ord('a')), 1);

done_testing();
