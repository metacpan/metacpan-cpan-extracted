use 5.036;
use warnings;
use Test2::V0;

#plan tests => 102;

use Switch::Right;
use experimental 'builtin';
use builtin qw< true false >;

note 'RHS is a canonical boolean';
ok     smartmatch('whatever', -r __FILE__)  => "line ".__LINE__;
ok     smartmatch('whatever', defined 1)    => "line ".__LINE__;
ok  !  smartmatch('whatever', defined undef)    => "line ".__LINE__;
ok     smartmatch(false,      true) => "line ".__LINE__;
ok  !  smartmatch(true,      false) => "line ".__LINE__;
ok  !  smartmatch(false,     false) => "line ".__LINE__;

note 'RHS is undef';
ok     smartmatch(undef,      undef)   => "line ".__LINE__;
ok  !  smartmatch(true,       undef)   => "line ".__LINE__;
ok  !  smartmatch(false,      undef)   => "line ".__LINE__;
ok  !  smartmatch(42,         undef)   => "line ".__LINE__;
ok  !  smartmatch('undef',    undef)   => "line ".__LINE__;
ok  !  smartmatch([undef],    undef)   => "line ".__LINE__;
ok  !  smartmatch(undef,      [undef]) => "line ".__LINE__;
ok  !  smartmatch({a=>undef}, undef)   => "line ".__LINE__;
ok  !  smartmatch(sub{1},     undef)   => "line ".__LINE__;
ok  !  smartmatch(qr//,       undef)   => "line ".__LINE__;

note "RHS is a number";
my @array99 = (99);
my %hash99  = (99 => 99);
ok     smartmatch(99,        99)    => "line ".__LINE__;
ok     smartmatch('99.0',    99)    => "line ".__LINE__;
ok     smartmatch(true,      1)    => "line ".__LINE__;
ok  !  smartmatch(false,     0)    => "line ".__LINE__;
ok  !  smartmatch('a',       99)    => "line ".__LINE__;
ok  !  smartmatch(2,         99)    => "line ".__LINE__;
ok  !  smartmatch(sub{1},    99)    => "line ".__LINE__;
ok  !  smartmatch(qr/99/,    99)    => "line ".__LINE__;
ok  !  smartmatch(\@array99, 99)    => "line ".__LINE__;
ok  !  smartmatch(\%hash99,  99)    => "line ".__LINE__;
ok  !  smartmatch(\@array99, 0+\@array99)    => "line ".__LINE__;
ok  !  smartmatch(\%hash99,  0+\%hash99)    => "line ".__LINE__;
ok  !  smartmatch(undef,     86)    => "line ".__LINE__;
ok  !  smartmatch(undef,     0)    => "line ".__LINE__;

note "RHS is a string";
ok     smartmatch('a',               'a')    => "line ".__LINE__;
ok     smartmatch('99.0',            '99.0')    => "line ".__LINE__;
ok     smartmatch(*STDOUT,           '*main::STDOUT')    => "line ".__LINE__;
ok     smartmatch(true,              '1')    => "line ".__LINE__;
ok     smartmatch(false,             '')    => "line ".__LINE__;
ok  !  smartmatch(99,                '99.0')    => "line ".__LINE__;
ok  !  smartmatch('b',               'a')    => "line ".__LINE__;
ok  !  smartmatch(qr/a/,             'a')    => "line ".__LINE__;
ok  !  smartmatch(sub{'a' eq shift}, 'a')    => "line ".__LINE__;
ok  !  smartmatch(\@array99,         'a')    => "line ".__LINE__;
ok  !  smartmatch(\%hash99,          'a')    => "line ".__LINE__;
ok  !  smartmatch(*STDOUT,           '*STDOUT')    => "line ".__LINE__;

note "RHS is array (LHS must be identical array)";
ok     smartmatch([],     [])    => "line ".__LINE__;
ok     smartmatch([7],    [7])    => "line ".__LINE__;
ok     smartmatch([1..9], [1..9])    => "line ".__LINE__;
ok  !  smartmatch([],     [undef])    => "line ".__LINE__;
ok  !  smartmatch([7],    [])    => "line ".__LINE__;
ok  !  smartmatch([7],    [8])    => "line ".__LINE__;
ok  !  smartmatch([1..9], [reverse 1..9])    => "line ".__LINE__;

note "RHS is array (LHS cannot be anything except and array)";
ok  !  smartmatch(1,        [1..9])    => "line ".__LINE__;
ok  !  smartmatch('one',    ['one','two','three'])    => "line ".__LINE__;
ok  !  smartmatch(qr/1/,    [1..9])    => "line ".__LINE__;
ok  !  smartmatch({one=>1}, ['one','two','three'])    => "line ".__LINE__;
ok  !  smartmatch(sub{1},   ['one','two','three'])    => "line ".__LINE__;

note "RHS includes self-referential array";
my $array_self_ref = [1,2,3];
$array_self_ref->[3][2][1] = $array_self_ref;
ok     smartmatch($array_self_ref, $array_self_ref)    => "line ".__LINE__;
ok     smartmatch([$array_self_ref], [$array_self_ref])    => "line ".__LINE__;
ok  !  smartmatch($array_self_ref, [$array_self_ref])    => "line ".__LINE__;
ok  !  smartmatch([$array_self_ref], $array_self_ref)    => "line ".__LINE__;
ok  !  smartmatch($array_self_ref, 1)    => "line ".__LINE__;
ok  !  smartmatch(1, $array_self_ref)    => "line ".__LINE__;

note "RHS is hash (LHS must be a hash with the same keys and smartmatched values)";
ok     smartmatch({},            {})    => "line ".__LINE__;
ok     smartmatch({a=>7},        {a=>7})    => "line ".__LINE__;
ok     smartmatch({1..10},       {1..10})    => "line ".__LINE__;
ok     smartmatch({a=>1, b=>2},  {a=>qr/1/, b=>sub{2 == shift}})    => "line ".__LINE__;
ok     smartmatch({a=>1, b=>2},  {a=>true, b=>true})    => "line ".__LINE__;
ok  !  smartmatch({a=>1, b=>2},  {a=>true, b=>false})    => "line ".__LINE__;
ok  !  smartmatch({},            {u=>undef})    => "line ".__LINE__;
ok  !  smartmatch({x=>'y'},      {})    => "line ".__LINE__;
ok  !  smartmatch({x=>7},        {x=>8})    => "line ".__LINE__;
ok  !  smartmatch({x=>8},        {y=>8})    => "line ".__LINE__;

note "RHS is hash (LHS cannot be anything else but a hash)";
ok  !  smartmatch(1,        {a=>1, one=>'a', 1=>'one'})    => "line ".__LINE__;
ok  !  smartmatch('one',    {a=>1, one=>'a', 1=>'one'})    => "line ".__LINE__;
ok  !  smartmatch(qr/1/,    {a=>1, one=>'a', 1=>'one'})    => "line ".__LINE__;
ok  !  smartmatch([1..9],   {a=>1, one=>'a', 1=>'one'})    => "line ".__LINE__;
ok  !  smartmatch(sub{1},   {a=>1, one=>'a', 1=>'one'})    => "line ".__LINE__;

note "RHS includes self-referential hash";
my $hash_self_ref = {a=>1, b=>2, c=>3};
$hash_self_ref->{d}{e}{f} = $hash_self_ref;
ok     smartmatch($hash_self_ref, $hash_self_ref)    => "line ".__LINE__;
ok     smartmatch({h=>$hash_self_ref}, {h=>$hash_self_ref})    => "line ".__LINE__;
ok  !  smartmatch($hash_self_ref, [$hash_self_ref])    => "line ".__LINE__;
ok  !  smartmatch([$hash_self_ref], $hash_self_ref)    => "line ".__LINE__;
ok  !  smartmatch($hash_self_ref, {h=>$hash_self_ref})    => "line ".__LINE__;
ok  !  smartmatch({h=>$hash_self_ref}, $hash_self_ref)    => "line ".__LINE__;
ok  !  smartmatch($hash_self_ref, 1)    => "line ".__LINE__;
ok  !  smartmatch(1, $hash_self_ref)    => "line ".__LINE__;

note "RHS is a subref";
ok     smartmatch(1,      sub { 1 == shift })    => "line ".__LINE__;
ok     smartmatch('a',    sub { 'a' eq shift })    => "line ".__LINE__;
ok     smartmatch(qr/x/,  sub { 'xyz' =~ shift })    => "line ".__LINE__;
ok     smartmatch([1..9], sub { @{shift()} == 9 })    => "line ".__LINE__;
ok     smartmatch({a=>1}, sub { shift()->{a} })    => "line ".__LINE__;
ok  !  smartmatch(1,      sub { 2 == shift })    => "line ".__LINE__;
ok  !  smartmatch('a',    sub { 'b' eq shift })    => "line ".__LINE__;
ok  !  smartmatch(qr/x/,  sub { 'wyz' =~ shift })    => "line ".__LINE__;
ok  !  smartmatch([1..9], sub { @{shift()} == 0 })    => "line ".__LINE__;
ok  !  smartmatch({a=>1}, sub { shift()->{b} })    => "line ".__LINE__;

note "RHS is a regexp";
ok     smartmatch(7,        qr/x|7/)    => "line ".__LINE__;
ok     smartmatch('x',      qr/x|7/)    => "line ".__LINE__;
ok     smartmatch(qr/x|7/,  qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch([7],      qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch(['x'],    qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch({7=>1},   qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch({'x'=>1}, qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch(1,        qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch('a',      qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch(qr/x/,    qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch([1..9],   qr/x|7/)    => "line ".__LINE__;
ok  !  smartmatch({a=>1},   qr/x|7/)    => "line ".__LINE__;

note 'Disjunctive RHS';
ok   smartmatch( 11, any => [1..20] )  => "Line " . __LINE__;
ok   smartmatch( 22, any => [1,22,3] )  => "Line " . __LINE__;
ok ! smartmatch( 99, any => [1,22,3] )  => "Line " . __LINE__;
ok ! smartmatch( 99, any => [] )  => "Line " . __LINE__;

note 'Conjunctive RHS';
ok   smartmatch( 11, all => [11, qr/1/, sub ($x) { $x > 10 }] )  => "Line " . __LINE__;
ok   smartmatch( 11, all => [] )                                 => "Line " . __LINE__;
ok   smartmatch( 11, all => [11] )                               => "Line " . __LINE__;
ok   smartmatch( 11, all => [11,11,11] )                         => "Line " . __LINE__;
ok ! smartmatch( 11, all => [10,11,12] )                         => "Line " . __LINE__;
ok ! smartmatch( 11, all => [11, qr/1/, sub ($x) { $x < 10 }] )  => "Line " . __LINE__;

note 'Injunctive RHS';
ok ! smartmatch( 11, none => [1..20] )   => "Line " . __LINE__;
ok ! smartmatch( 22, none => [1,22,3] )  => "Line " . __LINE__;
ok   smartmatch( 99, none => [1,22,3] )  => "Line " . __LINE__;
ok   smartmatch( 99, none => [] )        => "Line " . __LINE__;


note 'Disjunctive LHS';
ok   smartmatch( any => [1..20] ,  11 )  => "Line " . __LINE__;
ok   smartmatch( any => [1,22,3],  22 )  => "Line " . __LINE__;
ok ! smartmatch( any => [1,22,3],  99 )  => "Line " . __LINE__;
ok ! smartmatch( any => []      ,  99 )  => "Line " . __LINE__;

note 'Conjunctive LHS';
ok ! eval { smartmatch( all => [11, qr/1/, sub ($x) { $x > 10 }], 11 ) } => "Line " . __LINE__;
ok          smartmatch( all => []                               , 11 )  => "Line " . __LINE__;
ok          smartmatch( all => [11]                             , 11 )  => "Line " . __LINE__;
ok          smartmatch( all => [11,11,11]                       , 11 )  => "Line " . __LINE__;
ok !        smartmatch( all => [10,11,12]                       , 11 )  => "Line " . __LINE__;
ok ! eval { smartmatch( all => [11, qr/1/, sub ($x) { $x < 10 }], 11 ) }  => "Line " . __LINE__;

note 'Injunctive LHS';
ok ! smartmatch( none => [1..20] ,  11 )  => "Line " . __LINE__;
ok ! smartmatch( none => [1,22,3],  22 )  => "Line " . __LINE__;
ok   smartmatch( none => [1,22,3],  99 )  => "Line " . __LINE__;
ok   smartmatch( none => []      ,  99 )  => "Line " . __LINE__;


note 'Disjunctive LHS and RHS';
ok   smartmatch( any => [1..9], any => [2..10]  ) => "Line " . __LINE__;
ok ! smartmatch( any => [1..9], any => [10..19] ) => "Line " . __LINE__;

note 'Conjunctive LHS and RHS';
ok   smartmatch( all => [1,1,1], all => [1,1,1] ) => "Line " . __LINE__;
ok   smartmatch( all => [1,2,3], all => [qr/[1-3]/, sub ($x) { $x <= 3 }] ) => "Line " . __LINE__;
ok ! smartmatch( all => [1,1,1], all => [1,1,2] ) => "Line " . __LINE__;
ok ! smartmatch( all => [1,1,2], all => [1,1,1] ) => "Line " . __LINE__;

note 'Compound junctive LHS and RHS';
ok   smartmatch( any => [3,2,1],    all => [1,1,1] )                           => "Line " . __LINE__;
ok   smartmatch( any => [9,99,999], all => [qr/9/, sub ($x) { $x % 2 }, 999] ) => "Line " . __LINE__;
ok ! smartmatch( any => [3,2,1],    all => [1,2,1] )                           => "Line " . __LINE__;
ok ! smartmatch( any => [3,2,1],    all => [4] )                               => "Line " . __LINE__;

ok   smartmatch( all => [3,2,1],    any => [1,2,3] )                           => "Line " . __LINE__;
ok   smartmatch( all => [9,99,999], any => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                               => "Line " . __LINE__;
ok ! smartmatch( all => [9,89,999], any => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                               => "Line " . __LINE__;
ok ! smartmatch( none => [3,2,1],    all => [1,1,1] )                           => "Line " . __LINE__;
ok ! smartmatch( none => [9,99,999], all => [qr/9/, sub ($x) { $x % 2 }, 999] ) => "Line " . __LINE__;
ok   smartmatch( none => [3,2,1],    all => [1,2,1] )                           => "Line " . __LINE__;
ok   smartmatch( none => [3,2,1],    all => [4] )                               => "Line " . __LINE__;

ok ! smartmatch( none => [3,2,1],    any => [1,2,3] )                           => "Line " . __LINE__;
ok ! smartmatch( none => [9,99,999], any => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                               => "Line " . __LINE__;
ok ! smartmatch( none => [9,89,999], any => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                               => "Line " . __LINE__;
ok   smartmatch( none => [1,2,3],    any => [4,5,6] )                          => "Line " . __LINE__;

ok ! smartmatch( all => [3,2,1],    none => [1,1,1] )                           => "Line " . __LINE__;
ok ! smartmatch( all => [9,99,999], none => [qr/9/, sub ($x) { $x % 2 }, 999] ) => "Line " . __LINE__;
ok   smartmatch( all => [3,2,1],    none => [4,5,6] )                           => "Line " . __LINE__;
ok   smartmatch( all => [3,2,1],    none => [4] )                               => "Line " . __LINE__;

ok ! smartmatch( any => [3,2,1],    none => [1,2,3] )                           => "Line " . __LINE__;
ok ! smartmatch( any => [9,99,999], none => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                              => "Line " . __LINE__;
ok   smartmatch( any => [9,89,999], none => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                              => "Line " . __LINE__;
ok   smartmatch( any => [1,2,3],    none => [4,5,6] )                         => "Line " . __LINE__;

ok   smartmatch( none => [3,2,1],    none => [1,2,3] )                           => "Line " . __LINE__;
ok   smartmatch( none => [9,99,999], none => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                               => "Line " . __LINE__;
ok ! smartmatch( none => [9,89,999], none => [qr/.../, sub($x){ $x < 10 }, sub($x){ $x % 11 == 0 }] )
                                                                               => "Line " . __LINE__;
done_testing();



