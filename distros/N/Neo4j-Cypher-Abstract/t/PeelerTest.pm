use lib '..';
use lib '../lib';
use v5.10;
use Test::More;
use t::SimpleTree;
use Neo4j::Cypher::Abstract::Peeler;
use base Exporter;
use strict;
our @EXPORT = qw/test_peeler $peeler/;
our $peeler = Neo4j::Cypher::Abstract::Peeler->new();
my $p = t::SimpleTree->new;
my $q = t::SimpleTree->new;

=head1 NAME

PeelerTest - test Neo4j::Cypher::Abstract::Peeler

=head1 SYNOPSIS

 use Test::More;
 use t::PeelerTest;
 our $peeler; # access to the peeler object
 $t = { todo => 'manage literal + binds',
        where => {
            foo => \["IN (?, ?)", 22, 33],
            bar => [-and =>  \["> ?", 44], \["< ?", 55] ],
        },
        stmt => "( (bar > ? AND bar < ?) AND foo IN (?, ?) )",
        bind => [44, 55, 22, 33] };
 test_peeler($t, $u, $v);
 done_testing;

=head2 DESCRIPTION

Test::Peeler sets up individual tests of
Neo4j::Cypher::Abstract::Peeler by accepting an array of hashes
containing the following keys:

C<where> : a Perl object that can be parsed as a Cypher expression by
Peeler

C<stmt> : the expected Cypher expression as a string

C<bind> : a list of parameter bindings, if C<stmt> contains them

The following optional keys are available:

C<skip> : if exists, then test is skipped with the value as the
message

C<todo> : if exists, then test is treated as a TODO with value as
message

c<no_tree> : if exists, then stmt is compared as string to peel 
production; t::SimpleTree is not used

C<stmt2> : if exists, then peeler output is compared exactly with the
string value, and exactly with C<stmt> string value, to determine
equivalence.

C<t/SimpleTree.pm> is used to compare the C<stmt> with the Peeler
production, which should make it a little easier to write statments
without concern for ordering, extra parens, and the like.

Test::Peeler exports:

 test_peeler(@tests)
 $peeler

=cut

sub test_peeler {
  for my $t (@_) {
    my ($got_can, $got_peel);
    my $stmt = $t->{stmt};
    if ($t->{skip}) {
      diag "skipping ($$t{stmt}) : $$t{skip}";
      next;
    }
    $stmt =~ s{\?}{/[0-9]+/ ? "$_" : "'$_'"}e for @{$t->{bind}};
    if (!$t->{todo}) {
      try {
	ok $got_can = $peeler->canonize($t->{where}), 'canonize passed';
	ok $got_peel = $peeler->peel($got_can), 'peeled';
	1;
      } catch {
	say "bad peel: $_";
	fail;
	1;
      };
    }
    else {
    TODO: {
	local $TODO = $t->{todo};
	try {
	  ok $got_can = $peeler->canonize($t->{where}), 'canonize passed';
	  ok $got_peel = $peeler->peel($got_can), 'peeled';
	  1;
	} catch {
	  say "bad peel: $_";
	  fail;
	  1;
	};
      }
    }
    if ($got_peel) {
      if ($t->{no_tree}) {
	if ($t->{stmt2}) {
	  if ($got_peel eq $stmt or $got_peel eq $t->{stmt2}) {
	    pass "equivalent";
	  }
	  else {
	    fail "not equivalent";
	  }
	}
	else {
	  is $got_peel, $stmt, "equivalent";
	}
      }
      else {
	try {
	  $p->parse($stmt);
	  $q->parse($got_peel);
	  if ($p == $q) {
	    pass "equivalent";
	  }
	  else {
	    fail "not equivalent";
	    diag $stmt;
	    diag $got_peel;
	  }
	} catch {
	  fail "Error in t::SimpleTree";
	  diag "on $stmt";
	  diag "could not completely reduce expression" if /Could not completely reduce/;
	};
      }
    }
    say;
  }
}

1;
