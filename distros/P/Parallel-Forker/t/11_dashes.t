#!/usr/bin/perl -w
# DESCRIPTION: Perl ExtUtils: Type 'make test' to test this package
#
# Copyright 2003-2019 by Wilson Snyder.  This program is free software;
# you can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
######################################################################

use Test::More;
use strict;

BEGIN { plan tests => 12 }
BEGIN { require "./t/test_utils.pl"; }

BEGIN { $Parallel::Forker::Debug = 1; }

use Parallel::Forker;
ok(1, "use");

######################################################################

a_test(0);
a_test(1);

my %Didit;
sub didit { $Didit{$_[0]->name} = 1 }

sub a_test {
    my $failit = shift;

    my $fork = new Parallel::Forker(use_sig_child=>1);
    $SIG{CHLD} = sub { Parallel::Forker::sig_child($fork); };
    $SIG{TERM} = sub { $fork->kill_tree_all('TERM') if $fork && $fork->in_parent; die "Quitting...\n"; };
    ok(1, "sig");

    # Test use of -'s in run_afters
    %Didit = ();

    $fork->schedule(name => 'a',
		    run_on_start => sub {
			if ($failit) {exit(13);} # Intentional bad status
			exit(0);
		    },
		    run_on_finish => sub {
			my ($procref, $status) = @_;
			#print "Stat = $status\n";
			if ($failit) {
			    if (($status>>8) == 13) { $Didit{a} = 1 }
			} else { $Didit{a} = 1; }
		    },
		    run_after => ['-doesnt_exist'],
		    label => 'a',
		    );
    $fork->schedule(name => 'b',
		    run_on_start => sub { },
		    run_on_finish => \&didit,
		    run_after => ['| a'],
		    label => 'd2',
		    );
    my $na =
    $fork->schedule(name => 'c',
		    run_on_start => sub { },
		    run_on_finish => \&didit,
		    run_after => ['!a'],
		    label => 'd3',
		    );
    $fork->schedule(name => 'd',
		    run_on_start => sub { },
		    run_on_finish => \&didit,
		    run_after => ['^a'],
		    );
    $fork->schedule(name => 'e',
		    run_on_start => sub { },
		    run_on_finish => \&didit,
		    run_after => [$na],
		    );
    $fork->schedule(name => 'e2',
		    run_on_start => sub { },
		    run_on_finish => \&didit,
		    run_after => ['e'],
		    );
    $fork->schedule(name => 'f',
		    run_on_start => sub { },
		    run_on_finish => \&didit,
		    run_after => ["d2 | d3"],
		    );

    # Check implicit and'ing (will never run)
    $fork->schedule(name => 'g',
      run_on_start => sub {},
      run_on_finish => \&didit,
      run_after => ['b', $na],
    );

    # Check implicit and'ing (will run if NOT $failit)
    $fork->schedule(name => 'h',
      run_on_start => sub {},
      run_on_finish => \&didit,
      run_after => ['d', $na],
    );

    # Run them
    $fork->ready_all();
    $fork->wait_all();

    # Check right procs died
    print " Didit: ", (join ' ',(sort (keys %Didit))), "\n";
    if ($failit) {
	ok($Didit{a} && !$Didit{b} && $Didit{c} && $Didit{d} && $Didit{f}
          && !$Didit{g} && $Didit{h});
    } else {
	ok($Didit{a} && $Didit{b} && !$Didit{c} && $Didit{d} && $Didit{f}
          && !$Didit{g} && !$Didit{h});
    }
    ok( (($Didit{e}||-1) == ($Didit{c}||-1))
	&& (($Didit{e}||-1) == ($Didit{e2}||-1)));

    # Check all marked appropriately
    sub names_are {
      my ($fork, $method) = @_;
      return join('', map { $_->name }
        grep { $_->$method } $fork->processes_sorted);
    }

    if ($failit) {
      ok( names_are($fork, 'is_parerr'), 'bg' );
      ok( names_are($fork, 'is_done'), 'acdee2fh' );
    } else {
      ok( names_are($fork, 'is_parerr'), 'cee2gh' );
      ok( names_are($fork, 'is_done'), 'abdf' );
    }
}

# Full ordering test (simple tree with one diamond, so there's just two possibilities)
#         a
#         |
#         b
#        / \
#       c  d
#       \ /
#        e
#        |
#        f
{
  my $fork = new Parallel::Forker(use_sig_child=>1);
  $SIG{CHLD} = sub { Parallel::Forker::sig_child($fork); };
  $SIG{TERM} = sub { $fork->kill_tree_all('TERM') if $fork && $fork->in_parent; die "Quitting...\n"; };

  my @done_order;
  sub done { push @done_order, $_[0]->name }
  my %args = (
    run_on_start => sub {},
    run_on_finish => \&done,
  );

  $fork->schedule(name => 'a', %args);
  $fork->schedule(name => 'b', %args,
    run_after => ['a'],
  );
  $fork->schedule(name => 'c', %args,
    run_after => ['b'],
  );
  $fork->schedule(name => 'd', %args,
    run_after => ['b'],
  );
  $fork->schedule(name => 'e', %args,
    run_after => ['d', 'c'],
  );
  $fork->schedule(name => 'f', %args,
    run_after => ['e'],
  );

  $fork->ready_all;
  $fork->wait_all;

  ok(("@done_order" eq "a b c d e f"
      || "@done_order" eq "a b d c e f"),
     "done_order");
}
