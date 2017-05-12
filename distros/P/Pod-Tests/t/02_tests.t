#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More 'no_plan';
use Pod::Tests;

my $p = Pod::Tests->new;
$p->parse_fh(*DATA);

my @tests       = $p->tests;
my @examples    = $p->examples;

is( @tests,     3,                      'saw tests' );
is( @examples,  7,                      'saw examples' );

is( $tests[0]{code},    <<'POD',        'saw =for testing' );
ok(2+2 == 4);
is( __LINE__, 96 );
POD

is( $tests[1]{code},    <<'POD',        'saw testing block' );

my $foo = 0;  is( __LINE__, 108 );
ok( !$foo,      'foo is false' );
ok( $foo == 0,  'foo is zero'  );

POD

is( $examples[0]{code}, <<'POD',        'saw example block' );

  # This is an example.
  2+2 == 4;
  5+5 == 10;

POD

is( $examples[1]{code}, <<'POD',       'multi-part example glued together' );
  sub mygrep (&@) { }


  mygrep { $_ eq 'bar' } @stuff
POD

is( $examples[2]{code}, <<'POD',        'example with tests' );

  my $result = 2 + 2;




POD
is( $examples[2]{testing}, <<'POD',     q{  and there's the tests});
  ok( $result == 4,         'addition works' );
  is( __LINE__, 142 );
POD


is( $examples[4]{code}, <<'POD',        '=for example begin' );

  1 + 1 == 2;

POD


# Test that double parsing works.

# Seek back to __END__.
use POSIX qw( :fcntl_h );
seek(DATA, 0, SEEK_SET) || die $!;
do { $_ = <DATA> } until /^__END__$/;

$p->parse_fh(*DATA);

is( $p->tests,       6,                      'double parse tests' );
is( $p->examples,   14,                      'double parse examples' );



__END__
code and things

=for something_else
  Make sure Pod::Tests ignores other =for tags.

=head1 NAME

Dummy testing file for Pod::Tests

=for testing
ok(2+2 == 4);
is( __LINE__, 96 );

This is not a test

=cut

code and stuff

=pod

=begin testing

my $foo = 0;  is( __LINE__, 108 );
ok( !$foo,      'foo is false' );
ok( $foo == 0,  'foo is zero'  );

=end testing

Neither is this.

=also begin example

  # This is an example.
  2+2 == 4;
  5+5 == 10;

=also end example

Let's try an example with helper code.

=for example
  sub mygrep (&@) { }

=also for example
  mygrep { $_ eq 'bar' } @stuff

And an example_testing block

=for example begin

  my $result = 2 + 2;

=for example end

=for example_testing
  ok( $result == 4,         'addition works' );
  is( __LINE__, 142 );

And the special $_STDOUT_ and $_STDERR_ variables..

=for example begin

  local $^W = 1;
  print "Hello, world!\n";
  print STDERR  "Beware the Ides of March!\n";
  warn "Really, we mean it\n";

=for example end

=for example_testing
  is( $_STDERR_, <<OUT,       '$_STDERR_' );
Beware the Ides of March!
Really, we mean it
OUT
  is( $_STDOUT_, "Hello, world!\n",                   '$_STDOUT_' );
  is( __LINE__, 161 );

=for example begin

  1 + 1 == 2;

=for example end

foo

=for example begin

  print "Hello again\n";
  print STDERR "Beware!\n";

=for example end

=for example_testing;

  is( $_STDOUT_, "Hello again\n" );
  is( $_STDERR_, "Beware!\n" );  

=for testing
  use File::Spec;
  is( $Original_File, File::Spec->catfile(qw(t 02_tests.t)) );

=for testing
  is( __LINE__, 188, 'line in =for testing' );

=begin testing

  is( __LINE__, 192, 'line in =begin/end testing' );

=end testing

=for example begin

  BEGIN{binmode STDOUT};

=for example end

=cut
