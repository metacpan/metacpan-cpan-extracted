#-- test suite

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

use Class::Trait;

use constant DONE => 1;

#== TESTS =====================================================================

require_ok ('TM::Tree');
require_ok ('TM::Graph');
require_ok ('TM::Analysis');

if (DONE) { # tree
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '
(begets)
parent: adam eve
child: cain

(begets)
parent: adam eve
child: abel

(begets)
parent: adam eve
child: seth

(begets)
parent: adam eve
child: azura

#--

(begets)
parent: cain
child: enoch

#--

(begets)
parent: enoch
child: irad

#--

(begets)
parent: irad
child: mehajael

#--

(begets)
parent: seth
child: enosh

(begets)
parent: seth
child: noam

   ');

    can_ok 'TM::Tree',     'apply';
    can_ok 'TM::Graph',    'apply';
    can_ok 'TM::Analysis', 'apply';

    ok 'TM::Tree'->apply ($tm), '....applying to an instance';

#    Class::Trait->apply ($tm => 'TM::Tree'); # this makes perl 5.10 choke
    $tm->sync_in;

#warn Dumper $tm;

  my $pedigree =  $tm->tree ($tm->mids ('adam',
                                       'begets',
                                       'parent',
                                       'child')
                                        );

#warn Dumper $pedigree;

  ok ($pedigree->{lid} eq 'tm:adam', 'tree');
  ok (eq_set([ map { $_->{lid} } @{$pedigree->{children}} ],
             [ 'tm:cain', 'tm:abel', 'tm:azura', 'tm:seth' ]), 'tree');
  my ($seth) = grep ($_->{lid} eq 'tm:seth', @{$pedigree->{children}});
  ok (eq_set([ map { $_->{lid} } @{$seth->{children}} ],
             [ 'tm:noam', 'tm:enosh' ]), 'tree');

  my $pedigree2 =  $tm->tree_x ($tm->mids ('adam',
                                           'begets',
                                           'parent',
                                           'child')
                                           );

#warn Dumper $pedigree2;

    use Test::Deep::NoTest;
    eq_deeply( $pedigree2, $pedigree, "tree = tree_x" );
}

if (DONE) { # taxonomy
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '
aaa subclasses thing

bbb subclasses thing

ccc subclasses aaa

ddd subclasses aaa

');
    'TM::Tree'->apply ($tm);
    $tm->sync_in;

#warn Dumper $tm;

    my $taxo =  $tm->taxonomy ($tm->mids ('aaa'));

#warn Dumper $taxo;

    ok ($taxo->{lid} eq 'tm:aaa',                'taxo 1');
    ok (eq_set([ map { $_->{lid} } @{$taxo->{children}} ],
	       [ 'tm:ccc', 'tm:ddd' ]),          'taxo 2');

    $taxo =  $tm->taxonomy;
#warn Dumper $taxo;
    ok ($taxo->{lid} eq 'thing',                 'taxo 3');
    ok (eq_set([ map { $_->{lid} } @{$taxo->{children}} ],
	       [ 'tm:aaa', 'tm:bbb' ]),          'taxo 4');
    my ($aaa) = grep ($_->{lid} eq 'tm:aaa', @{$taxo->{children}});
    ok (eq_set([ map { $_->{lid} } @{$aaa->{children}} ],
	       [ 'tm:ccc', 'tm:ddd' ]),          'taxo 5');

}

if (DONE) { # clustering
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '
# cluster 1
aaa subclasses bbb

bbb is-a ccc

(ddd)
eee: fff
ggg: hhh
iii: ccc

#------------------------------------
# cluster 2
zzz subclasses yyy

zzz subclasses xxx

www is-a zzz

(vvv)
uuu: rrr
sss: ttt
qqq: www
    ');
    $tm->sync_in;

#warn Dumper $tm; exit;

    'TM::Graph'->apply ($tm);

    my $clusters = $tm->clusters (use_lid => 0);
#    foreach (@$clusters) {
#	print "we are connnected: ", join (",", @$_), "\n\n";
#    }

    my ($c1) = grep (grep ($_ eq 'tm:aaa', @$_), @$clusters);
    ok (eq_set ($c1,  [
    'tm:fff',
    'tm:aaa',
    'tm:bbb',
    'tm:hhh',
    'tm:ccc'
    ]), 'cluster 1');
    my ($c2) = grep (grep ($_ eq 'tm:www', @$_), @$clusters);
    ok (eq_set ($c2,  [
    'tm:www',
    'tm:yyy',
    'tm:xxx',
    'tm:ttt',
    'tm:rrr',
    'tm:zzz'
    ]), 'cluster 2');
    my ($c3) = grep (grep ($_ eq 'tm:sss', @$_), @$clusters);
    ok (eq_set ($c3, [    'tm:sss',  ]), 'cluster 3');

    $clusters = $tm->clusters (use_roles => 1, use_type => 1, use_lid => 0);
#warn Dumper $clusters;
    my ($c4) = grep (grep ($_ eq 'tm:aaa', @$_), @$clusters);

    is (scalar @$c4, 33, 'cluster 4');
}

if (DONE) { # graph
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '

# this test data has NOTHING todo with Bond University
# any similarity with morons anywhere is completely coinci-whatever

adam (human)

(is-subclass-of)
subclass: halb-lustiger
superclass: bio-unit

(is-subclass-of)
subclass: human
superclass: halb-lustiger

(begets)
parent: adam eve
child: cain

(bigots)
parent: adam
child: candrews

candrews (halb-lustiger)

(forgets)
forgetter: candrews
fact: everything

(forgets)
forgetter: everything
fact: nothing

(begets)
parent: adam eve
child: abel

(bigots)
parent: abel
child: imorriso

imorriso (halb-lustiger)

(begets)
parent: adam eve
child: seth

(begets)
parent: adam eve
child: azura

#--

(begets)
parent: cain
child: enoch

#--

(begets)
parent: enoch
child: irad

#--

(begets)
parent: irad
child: mehajael

#--

(begets)
parent: seth
child: enosh

(begets)
parent: seth
child: noam

   ');

    'TM::Graph'->apply ($tm);
    $tm->sync_in;

    ok ($tm->is_path ([ 'adam' ],  [ [ 'isa' ] ], 'human'), 'adam is human');
    ok ($tm->is_path ([ 'adam' ],  [ [ 'isa' ] ], 'halb-lustiger'), 'adam is halb-lustiger');
    ok ($tm->is_path ([ 'human' ], [ [ 'iko' ] ], 'bio-unit'), 'humans are bio units');

    my %paths = (
                  'cain'  => [ [ 'begets' ] ],
                  'enoch' => [ [ 'begets' ], [ 'begets' ] ],
                  'irad'  => [ [ 'begets' ], [ 'begets' ], [ 'begets' ] ],
# test begets*
                  'irad'  => (bless [ [ 'begets' ] ], '*'),
                  'noam'  => (bless [ [ 'begets' ] ], '*'),
# test begets | bigots
                  'candrews' => [ [ 'begets', 'bigots' ] ],
                  'imorriso' => (bless [ [ 'begets', 'bigots' ] ], '*'),

                  'everything' => [ [ 'bigots' ], [ 'forgets' ] ],
                  'nothing'    => [ [ 'bigots' ], [ 'forgets' ], [ 'forgets' ] ],
                  'nothing'    => [ [ 'bigots' ], [ bless [ [ 'forgets' ] ],'*' ] ],
                );


   foreach my $p (keys %paths) {
      next if $p =~ /\*/;
      ok ($tm->is_path ([ 'adam' ], $paths{$p}, $p),  'stories which start bad, end bad '. Dumper $paths{$p});
   }

#warn Dumper $tm;

   my @ns = $tm->neighborhood (0, [ 'adam' ]);
   ok (eq_set ([ 'tm:adam' ], [ map { $_->{end} } @ns ]), '0-length neighborhood');
   is (scalar @{ $ns[0]->{path} }, 0, '0-length neighborhood path');

      @ns = $tm->neighborhood (1, [ 'adam' ]);
      my %expect1 = (
              'tm:human'   => 'isa',
	      'tm:eve'     => 'tm:begets',
	      'tm:cain'    => 'tm:begets',
	      'tm:candrews'=> 'tm:bigots',
	      'tm:abel'    => 'tm:begets',
	      'tm:seth'    => 'tm:begets',
	      'tm:azura'   => 'tm:begets',
      );

      is (scalar @ns, 8, "1-length neighborhood");
      foreach my $t (keys %expect1) {
         my ($n) = grep { $_->{end} eq $t } @ns;
         ok (defined $n, "1-length neighborhood $t detected ");
         ok (eq_array ($n->{path}, [ $expect1{$t} ]), "1-length neighborhood path");
      }


#      ok (eq_set (
##warn Dumper
#             [ { path => [],
#                 end  => 'tm:adam' },
#               map { { path => [ $expect1{$_} ], 
##                       end  => $_ } } keys %expect1 ],
#             [@ns]),'1-length neighborhood')
#;

#warn Dumper \@ns;

}

if (DONE) { # statistics
    use TM;
    my $tm1 = new TM;
    'TM::Analysis'->apply ($tm1);
    'TM::Graph'->apply ($tm1);

    my $stats1 = $tm1->statistics;
#warn Dumper $stats1;

    is ($stats1->{'nr_asserts'},  8, 'nr_asserts');
    is ($stats1->{'nr_toplets'},  scalar $tm1->toplets, 'nr_toplets');
    is ($stats1->{'nr_clusters'}, 15, 'nr_clusters');

    use TM::Materialized::AsTMa;
    my $tm2 = new TM::Materialized::AsTMa (baseuri => 'tm:',
					   inline => '
aaa subclasses bbb

bbb is-a ccc
    ');
    $tm2->sync_in;
#warn Dumper $tm2;

    'TM::Analysis'->apply ($tm2);
    my $stats2 = $tm2->statistics;
#warn Dumper $stats;

    is ($stats2->{'nr_asserts'},  $stats1->{'nr_asserts'} + 2,     'nr_asserts');
    is ($stats2->{'nr_toplets'},  $stats1->{'nr_toplets'} + 3,     'nr_toplets');
    is ($stats2->{'nr_clusters'}, 15,                              'nr_clusters');


}

if (DONE) { # orphanage
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '
aaa subclasses bbb

bbb is-a ccc
    ');
    $tm->sync_in;
    'TM::Analysis'->apply ($tm);

    my $o = $tm->orphanage;
#warn Dumper $o;

    ok (!grep ($_ eq 'tm:bbb', @{$o->{untyped}}),        'bbb is not untyped');
    ok ( grep ($_ eq 'tm:ccc', @{$o->{untyped}}),        'ccc is     untyped');

    ok (!grep ($_ eq 'tm:ccc', @{$o->{empty}}),          'ccc is not untyped');
    ok ( grep ($_ eq 'tm:aaa', @{$o->{empty}}),          'aaa is     untyped');

    ok (!grep ($_ eq 'tm:aaa', @{$o->{unclassified}}),   'aaa is not unclassified');
    ok ( grep ($_ eq 'tm:ccc', @{$o->{unclassified}}),   'ccc is     unclassified');

    ok (!grep ($_ eq 'tm:bbb', @{$o->{unspecified}}),    'bbb is not unspecified');
    ok ( grep ($_ eq 'tm:aaa', @{$o->{unspecified}}),    'aaa is     unspecified');

    $o = TM::Analysis::orphanage ($tm, 'untyped');
    ok ($o->{untyped}, 'only untyped');
}

if (DONE) {
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
                                          inline => '
aaa subclasses bbb

bbb is-a ccc

    ')->sync_in;

    $tm->assert (Assertion->new (type => 'seldom',   roles => [ 'xxx' ], players => [ 'ramsti'.$_ ]))
       for (0..0);
    $tm->assert (Assertion->new (type => 'frequent', roles => [ 'xxx' ], players => [ 'ramsti'.$_ ]))
       for (0..10);
    $tm->assert (Assertion->new (type => 'inflated', roles => [ 'xxx' ], players => [ 'ramsti'.$_ ]))
       for (0..100);

    'TM::Analysis'->apply ($tm);
    my $E = $tm->entropy;

    ok (! (grep { ! $E->{$_} } map { $_->[TM->TYPE] } $tm->asserts), 'any assoc type missing');

    ok (! (grep { $_ < 0 }    values %$E), 'all > 0');
    ok (! (grep { $_ > 0.37 } values %$E), 'all < 0.37');

    ok ($E->{'tm:seldom'}   < $E->{'tm:frequent'}, 'seldom   < frequent');
    ok ($E->{'tm:inflated'} < $E->{'tm:frequent'}, 'inflated < frequent');
#warn Dumper $E;
}


__END__

