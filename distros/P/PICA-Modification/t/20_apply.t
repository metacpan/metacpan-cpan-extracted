use strict;
use warnings;
use v5.10;
use Test::More;

use PICA::Record;
use PICA::Modification;

my @tests = (
  {
    pica   => '021A $aHello',
    expect => '021A $aWorld',
    id => 'xy:ppn:1', del => '021A', add => '021A $aWorld',
  },
  {
    about  => 'PPN match',
    id     => 'abc:ppn:123', del => '021A', add => '021A $aWorld',
    pica   => "003@ \$0123\n021A \$aHello",
    expect => "003@ \$0123\n021A \$aWorld",
  },{
    about => 'added level 1 field only to one holding',
    id => 'abc:ppn:123', iln => 50, del => '144Z', add => '144Z $all',
    pica  => <<'PICA',
003@ $0123
021A $aHello
101@ $a20$cPICA
101@ $a50$cPICA
PICA
    expect => <<'PICA',
003@ $0123
021A $aHello
101@ $a20$cPICA
101@ $a50$cPICA
144Z $all
PICA
  },{
    about => 'removed level 1 field',
    id => 'abc:ppn:123', iln => 20, del => '144Z', 
    pica  => <<'PICA',
003@ $0123
021A $aHello
101@ $a20$cPICA
144Z $all
101@ $a50$cPICA
144Z $axx
PICA
    expect => <<'PICA',
003@ $0123
021A $aHello
101@ $a20$cPICA
101@ $a50$cPICA
144Z $axx
PICA
    diff => <<'PICA',
 101@ $a20$cPICA
-144Z $all
 101@ $a50$cPICA
PICA
    context => 1,
 },{
    about => 'modified level 0 field',
    id => 'abc:ppn:123', iln => 50, del => '011@', add => '011@ $a2003',
    pica  => <<'PICA',
003@ $0123
021A $aTest
011@ $a1999
101@ $a50
203@/01 $0123
203@/02 $0456
PICA
    expect => <<'PICA',
003@ $0123
011@ $a2003
021A $aTest
101@ $a50
203@/01 $0123
203@/02 $0456
PICA
    diff => "+011@ \$a2003\n-011@ \$a1999\n",
    context => 0,
  }
);

foreach my $test (@tests) {
    my $pica    = PICA::Record->new(delete $test->{pica});
    my $expect  = PICA::Record->new(delete $test->{expect});
    my $about   = delete $test->{about};
    my $diff    = delete $test->{diff};
    my $context = delete $test->{context};

    my $mod = PICA::Modification->new( %$test );
    is $mod->apply($pica)->string, $expect->string, $about;

    if ($diff) {
        is $mod->diff($pica,$context), $diff, 'diff'
    }
}

done_testing;
