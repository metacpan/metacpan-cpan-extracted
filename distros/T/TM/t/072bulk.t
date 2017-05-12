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

my $warn = shift @ARGV;
unless ($warn) {
    close STDERR;
    open (STDERR, ">/dev/null");
    select (STDERR); $| = 1;
}

#== TESTS =====================================================================

{ # simple vortex
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '

aaa (bbb)
sin: http://aaa/
bn: AAA
oc (rumsti): http://aaa/

(ccc)
xxx: aaa
yyy: bbb ddd

(cccc)
xxxx: aaa
yyyy: bbbb dddd

uuu (aaa)

vvv (aaa bbb)

bbb subclasses fff

bbb subclasses ggg

aaa subclasses mmm

aaa subclasses nnn

mmm subclasses ooo

www subclasses aaa

vvv subclasses www

xxx subclasses vvv

(eee)
aaa: fff
bbb: ggg
ccc: hhh

');
    $tm->sync_in;

#warn Dumper $tm;

  use TM::Bulk;
  use Class::Trait;
  'TM::Bulk'->apply ($tm);

  eval {
    $tm->vortex ('whatever', {}, [ 'rumsti' ]);
  }; like ($@, qr//, 'vortex: scoping not implemented');
  $@ = undef;

#warn Dumper $tm;

  my $vortex =  $tm->vortex ('aaa',
                            {
                             'ttt'  => [ 'topic' ],
                             'yyy'  => [ 'types' ],
                             'iii'  => [ 'instances' ],
                             'yyy*' => [ 'types*' ],
                             'iii*' => [ 'instances*' ],
                             'ppp'  => [ 'superclasses' ],
                             'ppp*' => [ 'superclasses*' ],
                             'bbb'  => [ 'subclasses' ],
                             'bbb*' => [ 'subclasses*' ],
                             'rrr'  => [ 'roles' ],
                             'eee'   => [ 'peers' ],
                             'eee*'  => [ 'peers*' ],
                             'eee**' => [ 'peers**' ],
##                             'lll'  => [ 'players' ],
                             }
                             );

#warn Dumper $vortex;

  ok (ref ($vortex->{ttt}) eq 'ARRAY' &&
      ! defined $vortex->{ttt}->[TM->ADDRESS] &&
      eq_array ($vortex->{ttt}->[TM->INDICATORS], [ 'http://aaa/' ]), 'vortex: midlet complete');

  ok (eq_set ($vortex->{'eee'},
              [
               'tm:vvv'
               ]), 'vortex: peers');

  ok (eq_set ($vortex->{'eee*'},
              [
               'tm:vvv'
               ]), 'vortex: peers*');

  ok (eq_set ($vortex->{'eee**'},
              [
               'tm:vvv',
               ]), 'vortex: peers**');

  ok (eq_set ($vortex->{'iii'},
              [
               'tm:uuu', 'tm:vvv'
               ]), 'vortex: instances');

  ok (eq_set ($vortex->{'iii*'},
              [
               'tm:uuu', 'tm:vvv'
               ]), 'vortex: instances*');
  ok (eq_set ($vortex->{'yyy'},
              [
               'tm:bbb'
               ]), 'vortex: types');
  ok (eq_set ($vortex->{'yyy*'},
              [
               'tm:bbb', 'tm:fff', 'tm:ggg'
               ]), 'vortex: types*');
  ok (eq_set ($vortex->{'ppp'},
              [
               'tm:mmm', 'tm:nnn'
               ]), 'vortex: superclass');
  ok (eq_set ($vortex->{'ppp*'},
              [
               'tm:mmm', 'tm:nnn', 'tm:aaa', 'tm:ooo'
               ]), 'vortex: superclass*');
  ok (eq_set ($vortex->{'bbb'},
              [
               'tm:www'
               ]), 'vortex: subclass');
  ok (eq_set ($vortex->{'bbb*'},
              [
               'tm:aaa', 'tm:www', 'tm:vvv', 'tm:xxx'
               ]), 'vortex: subclass*');

  is (scalar @{$vortex->{'rrr'}}, 2,  'roles'); # look closer xxx subclasses vvv subclasses ...aaa !
}

{ # basenames
    use TM::Materialized::AsTMa;
    my $tm = new TM::Materialized::AsTMa (baseuri => 'tm:',
					  inline => '

aaa (bbb)
bn: AAA
bn @ s1: AAAS
bn @ s2: AAAS2
oc @ s1: http://xxx/

bbb
bn: BBB
bn @ s2: BBBS

ccc
bn @ s2: CCCS

');
    $tm->sync_in;

    use TM::Bulk;
    use Class::Trait;
    'TM::Bulk'->apply ($tm);
    {
	my $names = $tm->names ([ 'ccc', 'ggg', 'aaa' ]);
#warn Dumper $names;
	ok ($names->{'tm:aaa@tm:s1'} && $names->{'tm:aaa@tm:s1'} eq 'AAAS'  || 
	    $names->{'tm:aaa@tm:s2'} && $names->{'tm:aaa@tm:s2'} eq 'AAAS2' || 
	    $names->{'tm:aaa@us'}    && $names->{'tm:aaa@us'}    eq 'AAA',  'basenames: empty scope (any)');
	ok ($names->{'tm:ccc@tm:s2'} eq 'CCCS', 'basenames: empty scope (any)');
	is (scalar keys %$names, 2,    'basenames: empty scope (any)');
    }
    {
	my $names = $tm->names ([ 'ccc', 'ggg', 'aaa' ], [ '*' ]);
#warn Dumper $names;
	ok ($names->{'tm:aaa@tm:s1'} && $names->{'tm:aaa@tm:s1'} eq 'AAAS'  || 
	    $names->{'tm:aaa@tm:s2'} && $names->{'tm:aaa@tm:s2'} eq 'AAAS2' || 
	    $names->{'tm:aaa@us'}    && $names->{'tm:aaa@us'}    eq 'AAA',  'basenames: any scope');
	ok ($names->{'tm:ccc@tm:s2'} eq 'CCCS', 'basenames: any scope');
	is (scalar keys %$names, 2,    'basenames: any scope');
    }
    {
	my $names = $tm->names ([ 'ccc', 'ggg', 'aaa' ], [ 's1' ]);
#warn Dumper $names;
	ok ($names->{'tm:aaa@tm:s1'} eq 'AAAS', 'basenames: one scope');
	ok (! defined $names->{'tm:ccc@tm:s1'}, 'basenames: one scope');
	ok (! defined $names->{'tm:ccc@tm:s2'}, 'basenames: one scope');
	ok (! defined $names->{'tm:ccc@us'},    'basenames: one scope');
	is (scalar keys %$names, 2,    'basenames: one scope');
    }
    {
	my $names = $tm->names ([ 'ccc', 'ggg', 'aaa' ], [ 's1', 's2' ]);
#warn Dumper $names;
	ok ($names->{'tm:aaa@tm:s1'} eq 'AAAS', 'basenames: several scope');
	ok ($names->{'tm:ccc@tm:s2'} eq 'CCCS', 'basenames: several scope');
	is (scalar keys %$names, 2,    'basenames: several scope');
    }
    {
	my $names = $tm->names ([ 'ccc', 'bbb', 'aaa' ], [ 's1', 's3', '*' ]);
#warn Dumper $names;
	ok ($names->{'tm:aaa@tm:s1'} eq 'AAAS', 'basenames: several scope plus *');
	ok ($names->{'tm:bbb@tm:s2'} && $names->{'tm:bbb@tm:s2'} eq 'BBBS' ||
	    $names->{'tm:bbb@us'}    && $names->{'tm:bbb@us'}    eq 'BBB',  'basenames: several scope plus *');
	ok ($names->{'tm:ccc@tm:s2'} eq 'CCCS', 'basenames: several scope plus *');
	is (scalar keys %$names, 3,    'basenames: several scope plus *');
    }
}

__END__



{ # tree
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
parent irad
child: mehajael

#--

(begets)
parent: seth
child: enosh

(begets)
parent: seth
child: noam

');
    $tm->sync_in;

#warn Dumper $tm;

  my $vortex =  $tm->vortex ('adam',
                            {
                             'ttt'  => [ 'tree', 'begets', 'parent', 'child', 3 ],
                             }
                             );

warn Dumper $vortex;

    
}

