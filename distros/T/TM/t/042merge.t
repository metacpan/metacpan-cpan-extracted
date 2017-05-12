use strict;
use warnings;

# change 'tests => 1' to 'tests => last_test_to_print';
use Test::More qw(no_plan);

use Data::Dumper;
$Data::Dumper::Indent = 1;

sub _chomp {
    my $s = shift;
    chomp $s;
    return $s;
}

#ok(1);
#exit;

#== TESTS =====================================================================


#-- check various flavours of merging for the number of resulting topics -----------------

my %Ts = (
   t0815 => '
%s (rumsti ramsti) reifies http://www.0815.com/
bn: something completely different
bn: first version of 0815
oc @ scope1 (type1): http://www.rumsti.com/
oc @ scope2 (type2): http://www.romsti.com/
sin: http://IamIdonquichote.com/
sin: http://IamIdonquichote.com2/
',

   t0815a => '
%s (ramsti remsti)
bn: second version of 0815
oc @ scope2 (type2): http://www.ramsti.com/
',

   t0816 => '
%s reifies http://www.0815.com/
bn: something different
',

   t0816b => '
%s reifies http://www.0816.com/
bn: 0816
oc @ scope2 (type2): http://www.ramsti.com/
sin: http://IamIdonquichote.com/
',

   t0816c => '
%s
bn: something different
',

   t0817 => '
%s
bn : something completely different
bn @ xxxyyy: and yet another one
oc @ scope2 (type2): http://www.romsti.com/
sin: http://IamIdonquichote.com/
',

   t0818 => '
%s (rumsti ramsti)
bn : something completely different
oc @ scope1 (type1): http://www.rumsti.com/
sin: http://IamIdonquichote.com2/
',

   t0819 => '
%s
bn: another name for Don Quichote
sin: http://IamIdonquichote.com/
',

   t0820 => '
%s (ramsti romsti)
bn @ zzz : something completely different
oc @ scope2 (type2): http://www.romsti.com/
sin: http://IamIdonquichote.com2/
',

   t0821 => '
%s
bn @ xxxyyy: and yet another one
bn @ zzz : something completely different
',

   t0822 => '
%s
bn @ xxxzzz : something completely different
',

   t0823 => '
%s reifies http://www.0816.com/
bn: something different
');

sub mk_file {
  my @topics = @_;

  use File::Temp qw/ tempfile /;
  my ($fh, $filename) = tempfile( );
  print $fh join ("", (map { eval "\$$_" } @topics));
  close ($fh);

  return $filename;
}

use TM::AsTMa::Fact;

sub _parse {
    my $c = shift;
    my $text = shift;
    my $ms = new TM (baseuri => 'tm:', consistency => $c);
    my $p  = new TM::AsTMa::Fact (store => $ms);
    my $i  = $p->parse ($text);
    return $ms;
}


# sub _oldparse {
#     my $c = shift;
#     my $s = shift;
#     use TM::Materialized::AsTMa;
#     my $tm = new TM::Materialized::AsTMa (consistency => $c,
# 					  inline      => $s);
#     $tm->sync_in;
#     return $tm;
# }

use TM;
use TM::PSI;

sub _closure { # computes transitive closure
    my %r = @_;
    my %graph;
    foreach (keys %r) {
	$graph{$_}->{$r{$_}} = 1;
	$graph{$r{$_}}->{$_} = 1;
    }
	
    { # Floyd-Warshall
	my @vertices = keys %graph;
	
	foreach my $k (@vertices) {
	    foreach my $i (@vertices) {
		foreach my $j (@vertices) {
		    $graph{$j}->{$i} = $graph{$i}->{$j} = 1 
			if (($graph{$k}->{$j} && $graph{$i}->{$k})
			||
			    ($graph{$j}->{$k} && $graph{$k}->{$i}));
		}
	    }
	}
    }
    return \%graph;
}

{
    my %tests = (
# Address/Indicator Based
		 'address identical' => {
		     merging => [ TM->Subject_based_Merging, TM->Indicator_based_Merging ],
		     topics  => [ qw (t0815 t0816) ],
		     results => { t0815 => 't0816' },
		 },
		 'address identical' => {
		     merging => [ TM->Subject_based_Merging, TM->Indicator_based_Merging ],
		     topics  => [ qw (t0815 t0816 t0819) ],
		     results => { t0815 => 't0816',
				  t0819 => 't0815' },
		 },
 		 'sharing a subjectIndicator' => {
 		     merging => [ TM->Subject_based_Merging, TM->Indicator_based_Merging ],
 		     topics  => [ qw (t0815 t0819) ],
 		     results => { t0815 => 't0819' },
 		 },
 		 'sharing a subjectIndicator (indirect)' => {
 		     merging => [ TM->Subject_based_Merging, TM->Indicator_based_Merging ],
 		     topics  => [ qw (t0815 t0817 t0818 t0820) ],
 		     results => { t0817 => 't0815',
				  t0818 => 't0815',
				  t0820 => 't0815' }
		 },
		 'sharing a subjectIndicator (indirect)' => {
		     merging => [ TM->Subject_based_Merging, TM->Indicator_based_Merging ],
		     topics  => [ qw (t0815 t0817 t0818 t0820) ],
		     results => { t0817 => 't0815',
				  t0818 => 't0815',
				  t0820 => 't0815' }
		 },
 		 'sharing a subjectIndicator (indirect, reorder)' => {
 		     merging => [ TM->Subject_based_Merging, TM->Indicator_based_Merging ],
 		     topics  => [ qw (t0817 t0820 t0818 t0815) ],
 		     results => { t0817 => 't0815',
				  t0818 => 't0815',
				  t0820 => 't0815' }
 		 },
 		 'sharing a subjectAddress (indirect, reorder)' => {
 		     merging => [ TM->Subject_based_Merging ],
 		     topics  => [ qw (t0817 t0816 t0818 t0815) ],
 		     results => { t0816 => 't0815', }
 		 },
# TNC Based merging
 		 'sharing "something completely different" (indirect, reorder)' => {
 		     merging => [ TM->TNC_based_Merging ],
 		     topics  => [ qw (t0817 t0816 t0820 t0815) ],
 		     results => { t0817 => 't0815', }
 		 },
 		 'sharing "zzz @ something completely different" (indirect, reorder)' => {
 		     merging => [ TM->TNC_based_Merging ],
 		     topics  => [ qw (t0816c t0819 t0820 t0821 t0823) ],
 		     results => { t0820  => 't0821',
			          t0816c => 't0823', }
 		 },
# 		 'TNC: all 4 merged' => {
# 		     merging => [ 'Subject_based_Merging', 'Topic_Naming_Constraint' ],
# 		     topics  => [ qw (t0815 t0817 t0820 t0821) ],
# 		     results => { t0815 => 't0816' },
#		 },
# 		 'TNC: only 2 merged' => {
# 		     merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
# 		     topics => [ qw (t0815 t0817 t0820) ],
# 		     result => 2,
# 		 },
# 		 'TNC: none merged 1 (scope mismatch)' => {
# 		     merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
# 		     topics => [ qw (t0815 t0820) ],
# 		     result => 2,
# 		 },
# 		 'TNC: none merged 2 (scope mismatch)' => {
# 		     merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
# 		     topics => [ qw (t0821 t0822) ],
# 		     result => 2,
# 		 },
	    );

    foreach my $t (sort keys %tests) {
#warn "working on test '$t'";
	foreach my $p (permutations (@{$tests{$t}->{topics}})) {
#warn "working on permutation ".join (" ", @$p);

            my $i;
	    my %X = map { $_ => sprintf ("X-%02d", $i++) } @$p;
#warn Dumper \%X;

            my $astma = join ("\n\n", map { sprintf $Ts{$_}, $X{$_} } keys %X);
	    my $tm    = _parse ($tests{$t}->{merging}, $astma);

	    my $ms = $tm;
	    foreach my $a (@{$tests{$t}->{topics}}) {
		foreach my $b (@{$tests{$t}->{topics}}) {
		    next if $a eq $b;
		    my ($ta, $tb) = $ms->midlet ($ms->mids ($X{$a}, $X{$b}));
#warn Dumper $ta, $tb;
		    ok ($ta != $tb, "$t: $a not same as $b");
		}
	    }

	    $tm->consolidate;

	    my $res_closure = _closure (%{$tests{$t}->{results}});
	    foreach my $a (@{$tests{$t}->{topics}}) {
		foreach my $b (@{$tests{$t}->{topics}}) {
		    next if $a eq $b;                                  # well
		    my ($ta, $tb) = $ms->midlet ($ms->mids ($X{$a}, $X{$b}));
		    if ($res_closure->{$a} and $res_closure->{$a}->{$b} or
			$res_closure->{$b} and $res_closure->{$b}->{$a}) {
#warn Dumper $ta, $tb;
			ok ($ta == $tb, "$t: $a same as $b") or 
			    warn "---------
$astma
".Dumper (\%X).
Dumper ($tests{$t}->{merging}).
"
  for permutation ".join (" ", @$p) and exit;

		    } else {
			ok ($ta != $tb, "$t: $a not same as $b") or 
			    warn "---------
$astma
".Dumper (\%X).
Dumper ($tests{$t}->{merging}).
"
  for permutation ".join (" ", @$p) and exit;
		    }
		}
	    }
	}
    }

#	    foreach my $a (keys %{$tests{$t}->{results}}) {
#		my $b = $tests{$t}->{results}->{$a};
#		my ($ta, $tb) = $ms->toplet ($X{$a}, $X{$b});
##warn Dumper $ta, $tb;
#		ok ($ta == $tb, "$t: $a same as $b");
#		if ($ta != $tb) { # this is an error
#		}
#	    }
}

sub permutations {
    my @ps;
    permute ([ @_ ], [], \@ps);
    return @ps;
}
    

sub permute {
    my @items = @{ $_[0] };
    my @perms = @{ $_[1] };
    my $ps    =    $_[2];

    unless (@items) {
	push @$ps, \@perms;
    } else {
        my @newitems;
        my @newperms;
        foreach my $i (0.. $#items) {
            @newitems = @items;
            @newperms = @perms;
            unshift (@newperms, splice (@newitems, $i, 1));
            permute ([@newitems], [@newperms], $ps);
        }
    }
}


__END__

{
    my $tm = _parse ([ 'Id_based_Merging', TM->Subject_based_Merging ], qw(t0815 t0816b));
    eval {
        $tm->consolidate;
	ok (0, 'should fail here');
    }; like ($@, qr/different subject/, _chomp($@));
}


#MIX ADD/IND
# Id Based
# 		 'id: all merged' => {
# 		     merging => [ 'Id_based_Merging' ],
# 		     topics => [ qw (t0815 t0815a) ],
# 		     result => 1,
# 		 },
# 		 'id: none merged' => {
# 		     merging => [ 'Id_based_Merging' ],
# 		     topics => [ qw (t0815 t0817) ],
# 		     result => 2,
# 		 },



#------------------------------------------------------------

{
  my $tm = new TM (consistency => { merge => [ TM->Subject_based_Merging ] },
                   tau         => "file:".mk_file (qw(t0818 t0819 t0820)));
  is (scalar $tm->toplets,                    $npt+10, 'merge all topics');
# chars von 818, no dup
  is ($tm->toplet ('t0820'), $tm->toplet ('t0818'), 'merged topics same reference');
  my $t818 = $tm->toplet ('t0818');
  ok (eq_set ( [ map { $_->[VALUE] } grep ($_->[KIND] == TM::Maplet::KIND_SIN, @{$t818->[CHARS]}) ],
	       [ qw (http://IamIdonquichote.com2/ t0820) ]), 't0818 indicators merged');
  
}

__END__

{
  my $tm = new TM (consistency => { merge => [ TM->Subject_based_Merging ] },
                   tau         => "file:".mk_file (qw(t0815 t0816)));
##  warn Dumper $tm;
  is (scalar $tm->toplets,                    $npt+7, 'merge all topics');
}


__END__

#-- check setting of consistency ---------------------------------------------------------

#-- detect erroneous situations -----------------------------------------------------

eval {
  my $tm = new TM (consistency => { merge => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ] },
		   tau         => "file:".mk_file (qw(t0823 t0816)));
  warn Dumper $tm;
}; like ($@, qr/incompatible/i, 'detected duplicate resourceRef');


__END__

#-- check result details of merging ------------------------------------------------
{
  my @topics = qw (t0820 t0817 t0816 t0818);
  my $astma = join ("", (map { eval "\$$_" } @topics));
  my $tm = new XTM (consistency => { merge => [ 'all' ]},
		    tie => new XTM::AsTMa (auto_complete => 0,
					   text => $astma));
  
  is (@{$tm->topics()},                    1, 'merge all topics');
  foreach (@topics) {
    is (@{$tm->topics("id regexps /$_/")}, 1, "find $_");
  }
  cmp_ok ($tm->topic ($topics[0]), '==', $tm->topic ($topics[-1]), 'same topic references');

  foreach my $t (@topics) {
    my $a = eval "\$$t";
    while ($a =~ s/bn.*?:\s*(.+?)\n//s) {
      my $bn = $1;
      is (scalar @{$tm->topics ("baseName regexps /$bn/")}, 1, "merged baseName '$bn'");
    }
  }


  my $t = $tm->topic ($topics[0]);
#print Dumper $t;
  ok (defined $t, 'topic id is still t0820');

  is (scalar @{$t->occurrences}, 3, 'eliminated occurrences');
  is (scalar @{$t->baseNames},   4, 'eliminated baseNames');
  is (scalar @{$t->instanceOfs}, 4, 'eliminated instanceOfs');
  is (scalar @{$t->subjectIdentity->references}, 2, 'eliminated subjectIndicators');

  is ($t->subjectIdentity->resourceRef->href, 'http://www.0815.com/', 'merged resourceRef');
  is (scalar @{$t->subjectIdentity->references}, 2, 'merged subjectIndicators');

  foreach my $y (qw(rumsti romsti)) {
    ok ($t->has_instanceOf ($y), "merged instanceOfs $y");
  }
  foreach (qw(rumsti romsti)) {
    is (scalar @{$tm->topics ("occurrence regexps /$_/")}, 1, "merged occurrence $_");
  }
}



my %tests = (
# TNC Based merging
	     'TNC: all 4 merged' => {
				merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
		       topics => [ qw (t0815 t0817 t0820 t0821) ],
		       result => 1,
		      },
	     'TNC: only 2 merged' => {
				merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
		       topics => [ qw (t0815 t0817 t0820) ],
		       result => 2,
		      },
	     'TNC: none merged 1 (scope mismatch)' => {
				merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
		       topics => [ qw (t0815 t0820) ],
		       result => 2,
		      },
	     'TNC: none merged 2 (scope mismatch)' => {
				merging => [ 'Id_based_Merging', 'Topic_Naming_Constraint' ],
		       topics => [ qw (t0821 t0822) ],
		       result => 2,
		      },
# Subject Based
	     'Subj: resourceRef identical' => {
				merging => [ 'Id_based_Merging', TM->Subject_based_Merging ],
		       topics => [ qw (t0815 t0816) ],
		       result => 1,
		      },
	     'Subj: sharing a subjectIndicator' => {
				merging => [ 'Id_based_Merging', TM->Subject_based_Merging ],
		       topics => [ qw (t0815 t0819) ],
		       result => 1,
		      },
	     'Subj: backward topicRef' => {
				merging => [ 'Id_based_Merging', TM->Subject_based_Merging ],
		       topics => [ qw (t0816 t0817) ],
		       result => 1,
		      },
	     'Subj: forward topicRef' => {
				merging => [ 'Id_based_Merging', TM->Subject_based_Merging ],
		       topics => [ qw (t0817 t0816) ],
		       result => 1,
		      },
	     'Subj: backward forward topicRef' => {
				merging => [ 'Id_based_Merging', TM->Subject_based_Merging ],
		       topics => [ qw (t0817 t0816 t0818) ],
		       result => 1,
		      },
	     'Subj: forward backward forward topicRef' => {
				merging => [ 'Id_based_Merging', TM->Subject_based_Merging ],
		       topics => [ qw (t0820 t0817 t0816 t0818) ],
		       result => 1,
		      },
# Id Based
	     'id: all merged' => {
				merging => [ 'Id_based_Merging' ],
		       topics => [ qw (t0815 t0815a) ],
		       result => 1,
		      },
	     'id: none merged' => {
				merging => [ 'Id_based_Merging' ],
		       topics => [ qw (t0815 t0817) ],
		       result => 2,
		      },
	    );

foreach my $t (sort keys %tests) {
  my $astma = join ("", (map { eval "\$$_" } @{$tests{$t}->{topics}}));
  my $tm = new XTM (consistency => { merge => $tests{$t}->{merging} },
		    tie => new XTM::AsTMa (auto_complete => 0,
					   text => $astma));
  is (@{$tm->topics()}, $tests{$t}->{result}, $t);
#print Dumper $tm;
}

#__END__



{ # test for Jan
  my $tm = new XTM (consistency => { merge => [ TM->Subject_based_Merging ] });

  use XTM::Path;
  my $xtmp = new XTM::Path;

  my $t1 = $xtmp->create ('topic[baseNameString = "rumsti"]');
  $t1->add_defaults;
  $tm->add ($t1);
  my $t2 = $xtmp->create ('topic[baseNameString = "rumsti"]');
  $t2->add_defaults;
  $tm->add ($t2);
  is (@{$tm->topics}, 2, 'same name, no TNC, no merge');
#  print Dumper $tm;
}

#__END__


__END__


