#!/opt/ecelerity/3rdParty/bin/perl -w
use strict;
use Test::More tests => 6;

BEGIN {
    diag "Testing Perl::call";
    use_ok 'PHP::Interpreter' or die;
}

our @var;
our $scalar;

push @var, "hello";
push @var, "goodbye";

ok my $p = PHP::Interpreter->new, "Create new PHP interpreter";
sub hello { my $who = shift; return "hello $who"; }

ok my $rv = $p->eval(q/
  $perl = Perl::getInstance();
  $rv = $perl->call('hello', 'world');
  return $rv;
/), 'Test use of Perl::call';

is $rv, 'hello world', "Check return value of call";

ok $rv = $p->eval(q/
  $perl = Perl::getInstance();
  $rv = $perl->hello('world');
  return $rv;
/), 'Test use of Perl::call via PHP overloading';

is $rv, 'hello world', "Check return value of call";
