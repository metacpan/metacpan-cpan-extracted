#!/usr/bin/perl
use strict;
use Test::More;
use Oracle::TNS;

my ( $str, $err, $tree, $names );

my $DESC = {
           DESCRIPTION => {
                          CONNECT_DATA => { SERVICE_NAME => 'ORCLPDB1', SERVER => 'DEDICATED' },
                          ADDRESS      => [
                                          { PORT => 1521, HOST => 'db1', PROTOCOL => 'TCP' },
                                          { PORT => 1521, HOST => 'db2', PROTOCOL => 'TCP' },
                                          ],
                          LOAD_BALANCE => 'ON',
                          },
           };

### single line, canonical key order

( $str, $err ) = tns_build( $DESC );
is( $err, undef, 'single line builds' );
is( $str, '(DESCRIPTION=(LOAD_BALANCE=ON)'
         .'(ADDRESS=(PROTOCOL=TCP)(HOST=db1)(PORT=1521))'
         .'(ADDRESS=(PROTOCOL=TCP)(HOST=db2)(PORT=1521))'
         .'(CONNECT_DATA=(SERVICE_NAME=ORCLPDB1)(SERVER=DEDICATED)))', 'single line output' );

### pretty

( $str, $err ) = tns_build( { DESCRIPTION => { ADDRESS => { HOST => 'db1', PORT => 1521 }, CONNECT_DATA => { SID => 'X' } } }, 2 );
is( $err, undef, 'pretty builds' );
my $pretty = <<'TNS';
(DESCRIPTION=
  (ADDRESS=
    (HOST=db1)
    (PORT=1521)
  )
  (CONNECT_DATA=
    (SID=X)
  )
)
TNS
chomp( $pretty );
is( $str, $pretty, 'pretty output' );

( $str, $err ) = tns_build( { A => { B => 1 } }, 4 );
is( $str, "(A=\n    (B=1)\n)", 'indent width' );

( $str, $err ) = tns_build( { A => { B => 1 } }, 0 );
is( $str, "(A=\n(B=1)\n)", 'zero indent is multiline, not single line' );

### unknown keys sorted after well-known ones, alphabetically

( $str, $err ) = tns_build( { X => { ZZ => 1, AA => 2, PORT => 3, HOST => 4, MM => 5 } } );
is( $str, '(X=(HOST=4)(PORT=3)(AA=2)(MM=5)(ZZ=1))', 'key order' );

### one-element arrayref same as scalar/hashref

is( ( tns_build( { A => [ { B => [ 1 ] } ] } ) )[0], '(A=(B=1))', 'one-element arrayrefs' );

### quoting

( $str, $err ) = tns_build( { A => { S => 'a b', P => 'x(y)', E => 'k=v', H => 'a#b', N => 'plain.v-1_2', Z => '' } } );
is( $str, '(A=(E="k=v")(H="a#b")(N=plain.v-1_2)(P="x(y)")(S="a b")(Z=))', 'values needing quotes are quoted' );

### caller data untouched

my $q = { A => [ 'a b', 'c' ] };
tns_build( $q );
is_deeply( $q, { A => [ 'a b', 'c' ] }, 'quoting does not modify input' );

### errors

for my $bad (
            [ undef,                     qr/^hashref expected/,                     'undef tree' ],
            [ [],                        qr/^hashref expected/,                     'arrayref tree' ],
            [ { A => undef },            qr/^undefined value for A/,                'undef value' ],
            [ { A => { B => [ 1, undef ] } }, qr/^undefined value for B/,           'undef in array' ],
            [ { A => \'x' },             qr/^unsupported value type SCALAR for A/,  'scalar ref' ],
            [ { A => [ [ 1 ] ] },        qr/^unsupported value type ARRAY for A/,   'nested arrayref' ],
            [ { A => sub {} },           qr/^unsupported value type CODE for A/,    'code ref' ],
            [ {},                        qr/^empty hashtree/,                       'empty tree' ],
            [ { A => {} },               qr/^empty hashref for A/,                  'empty hashref' ],
            [ { A => [ { B => 1 }, {} ] }, qr/^empty hashref for A/,                'empty hashref in array' ],
            [ { A => 'a"b' },            qr/^double quote in value for A/,          'double quote' ],
            [ { A => { B => 'a "b' } },  qr/^double quote in value for B/,          'double quote needing quotes' ],
            )
  {
  my ( $t, $re, $name ) = @$bad;
  my ( $s, $e ) = tns_build( $t );
  is( $s, undef, "$name: no string" );
  like( $e, $re, "$name: error" );
  }

### round trips

for my $indent ( undef, 2 )
  {
  my $label = defined $indent ? 'pretty' : 'single line';
  ( $str, $err ) = tns_build( $DESC, $indent );
  ( $tree, $err ) = tns_parse( $str );
  is( $err, undef, "$label round trip parses" );
  is_deeply( $tree, $DESC, "$label round trip tree" );
  }

( $tree ) = tns_parse( '(A=(Q="a (b) = c")(S="x y"))' );
( $str ) = tns_build( $tree );
is( $str, '(A=(Q="a (b) = c")(S="x y"))', 'quoted values round trip' );

( $str ) = tns_build( { A => { H => 'a#b', P => 'x # y' } }, 2 );
( $tree, $err ) = tns_parse( $str );
is( $err, undef, 'value with # round trip parses' );
is_deeply( $tree, { A => { H => 'a#b', P => 'x # y' } }, 'value with # round trip' );

### key order: parsed order kept, added values and keys placed sensibly

my $ROUTE = '(DESCRIPTION=(SOURCE_ROUTE=yes)(ADDRESS=(HOST=h1))'
           .'(ADDRESS_LIST=(FAILOVER=on)(ADDRESS=(HOST=h2a))(ADDRESS=(HOST=h2b)))'
           .'(ADDRESS=(HOST=h3))(CONNECT_DATA=(SID=X)(SERVER=dedicated)))';

( $tree ) = tns_parse( $ROUTE );
is( ( tns_build( $tree ) )[0], $ROUTE, 'parsed order kept, interleaved ADDRESS and ADDRESS_LIST' );

( $tree ) = tns_parse( '(X=(ZZ=1)(PORT=2)(HOST=3)(AA=4))' );
is( ( tns_build( $tree ) )[0], '(X=(ZZ=1)(PORT=2)(HOST=3)(AA=4))', 'parsed order kept over predefined order' );

( $tree ) = tns_parse( $ROUTE );
my $d = $tree->{ DESCRIPTION };
push @{ $d->{ ADDRESS } }, { HOST => 'h4' };
$d->{ CONNECT_DATA }{ INSTANCE_NAME } = 'i1';
$d->{ CONNECT_DATA }{ AAA } = 'a';
$d->{ LOAD_BALANCE } = 'on';
is( ( tns_build( $tree ) )[0],
    '(DESCRIPTION=(SOURCE_ROUTE=yes)(ADDRESS=(HOST=h1))'
   .'(ADDRESS_LIST=(FAILOVER=on)(ADDRESS=(HOST=h2a))(ADDRESS=(HOST=h2b)))'
   .'(ADDRESS=(HOST=h3))(ADDRESS=(HOST=h4))(CONNECT_DATA=(SID=X)(SERVER=dedicated)(INSTANCE_NAME=i1)(AAA=a))(LOAD_BALANCE=on))',
    'added value after last of its key, added keys in predefined order' );

( $tree ) = tns_parse( $ROUTE );
$d = $tree->{ DESCRIPTION };
shift @{ $d->{ ADDRESS } };
delete $d->{ SOURCE_ROUTE };
is( ( tns_build( $tree ) )[0],
    '(DESCRIPTION=(ADDRESS_LIST=(FAILOVER=on)(ADDRESS=(HOST=h2a))(ADDRESS=(HOST=h2b)))'
   .'(ADDRESS=(HOST=h3))(CONNECT_DATA=(SID=X)(SERVER=dedicated)))',
    'removed values and keys skipped' );

( $tree ) = tns_parse( $ROUTE );
$d = $tree->{ DESCRIPTION };
@{ $d->{ ADDRESS } } = reverse @{ $d->{ ADDRESS } };
is( ( tns_build( $tree ) )[0],
    '(DESCRIPTION=(SOURCE_ROUTE=yes)'
   .'(ADDRESS_LIST=(FAILOVER=on)(ADDRESS=(HOST=h2a))(ADDRESS=(HOST=h2b)))'
   .'(ADDRESS=(HOST=h3))(ADDRESS=(HOST=h1))(CONNECT_DATA=(SID=X)(SERVER=dedicated)))',
    'reordered values keep array order' );

( $tree ) = tns_parse( $ROUTE );
$d = $tree->{ DESCRIPTION };
unshift @{ $d->{ ADDRESS } }, { HOST => 'h0' };
$d->{ SOURCE_ROUTE } = 'no';
is( ( tns_build( $tree ) )[0],
    '(DESCRIPTION=(SOURCE_ROUTE=no)(ADDRESS=(HOST=h0))(ADDRESS=(HOST=h1))'
   .'(ADDRESS_LIST=(FAILOVER=on)(ADDRESS=(HOST=h2a))(ADDRESS=(HOST=h2b)))'
   .'(ADDRESS=(HOST=h3))(CONNECT_DATA=(SID=X)(SERVER=dedicated)))',
    'value added in front and changed scalar keep their key position' );

( $tree ) = tns_parse( $ROUTE );
$tree->{ DESCRIPTION }{ ADDRESS } = { HOST => 'only' };
is( ( tns_build( $tree ) )[0],
    '(DESCRIPTION=(SOURCE_ROUTE=yes)(ADDRESS=(HOST=only))'
   .'(ADDRESS_LIST=(FAILOVER=on)(ADDRESS=(HOST=h2a))(ADDRESS=(HOST=h2b)))'
   .'(CONNECT_DATA=(SID=X)(SERVER=dedicated)))',
    'repeated key replaced by single value takes its first position' );

( $tree ) = tns_parse( $ROUTE );
$tree->{ DESCRIPTION }{ CONNECT_DATA } = { SERVER => 'shared', SERVICE_NAME => 'S' };
like( ( tns_build( $tree ) )[0], qr/\(CONNECT_DATA=\(SERVICE_NAME=S\)\(SERVER=shared\)\)\)$/, 'replaced subtree uses predefined order' );

( $tree ) = tns_parse( $ROUTE );
my $copy = { DESCRIPTION => { %{ $tree->{ DESCRIPTION } } } };
like( ( tns_build( $copy ) )[0], qr/^\(DESCRIPTION=\(SOURCE_ROUTE=yes\)\(ADDRESS_LIST=/, 'copied hash uses predefined order' );

( $names ) = tns_parse_names( "A = $ROUTE\nB, C = (X=(Z=1)(A=2))\n" );
is( ( tns_build( $names->{ A } ) )[0], $ROUTE, 'tnsnames alias keeps parsed order' );
like( ( tns_build_names( $names ) )[0], qr/^C =\n  \(X=\n    \(Z=1\)\n    \(A=2\)\n  \)\n/m, 'tnsnames shared alias tree keeps parsed order' );

my ( $conn ) = tns_parse_connect( "u/p\@$ROUTE" );
is( ( tns_build_connect( $conn ) )[0], "u/p\@$ROUTE", 'connect descriptor keeps parsed order' );

### tnsnames.ora

my $NAMES = {
            ZED  => { DESCRIPTION => { ADDRESS => { HOST => 'z', PORT => 1 } } },
            ALFA => { DESCRIPTION => { ADDRESS => { HOST => 'a', PORT => 2 } } },
            };

( $str, $err ) = tns_build_names( $NAMES );
is( $err, undef, 'tnsnames builds' );
is( $str, <<'ORA', 'tnsnames output, aliases sorted, default indent 2' );
ALFA =
  (DESCRIPTION=
    (ADDRESS=
      (HOST=a)
      (PORT=2)
    )
  )

ZED =
  (DESCRIPTION=
    (ADDRESS=
      (HOST=z)
      (PORT=1)
    )
  )

ORA

( $str, $err ) = tns_build_names( { A => { X => 1 } }, 4 );
is( $str, "A =\n  (X=1)\n\n", 'tnsnames custom indent' );

( $names, $err ) = tns_parse_names( ( tns_build_names( $NAMES ) )[0] );
is_deeply( $names, $NAMES, 'tnsnames round trip' );

is_deeply( [ tns_build_names( {} ) ], [ '', undef ], 'empty tnsnames' );

( $str, $err ) = tns_build_names( [] );
like( $err, qr/^hashref expected/, 'tnsnames arrayref' );

( $str, $err ) = tns_build_names( { A => { X => undef } } );
is( $str, undef, 'tnsnames bad alias: no string' );
like( $err, qr/^alias A: undefined value for X/, 'tnsnames bad alias: error' );

( $str, $err ) = tns_build_names( { A => \'x' } );
like( $err, qr/^alias A: hashref expected/, 'tnsnames scalar ref alias' );

### NAME = value entries

my $IFILES = {
             IFILE => [ '/etc/oracle/a.ora', '/etc/oracle/dir with space/b.ora', 'a#b' ],
             ONE   => ' x',
             EMPTY => '',
             A     => { X => 1 },
             };
my @ifile = @{ $IFILES->{ IFILE } };

( $str, $err ) = tns_build_names( $IFILES );
is( $err, undef, 'NAME = value entries build' );
is( $str, <<'ORA', 'NAME = value entries output' );
A =
  (X=1)

EMPTY = ""

IFILE = /etc/oracle/a.ora

IFILE = /etc/oracle/dir with space/b.ora

IFILE = "a#b"

ONE = " x"

ORA
is_deeply( $IFILES->{ IFILE }, \@ifile, 'quoting does not modify input entries' );

( $names, $err ) = tns_parse_names( $str );
is( $err, undef, 'NAME = value round trip parses' );
is_deeply( $names, $IFILES, 'NAME = value round trip' );

for my $bad (
            [ { A => undef },            qr/^alias A: undefined value$/,                     'undef entry' ],
            [ { A => [ 'x', undef ] },   qr/^alias A: undefined value$/,                     'undef entry in array' ],
            [ { A => [ { X => 1 } ] },   qr/^alias A: hashref or scalar expected/,           'hashref in entry array' ],
            [ { A => 'a"b' },            qr/^alias A: double quote in value/,                'double quote entry' ],
            [ { A => "a\nb" },           qr/^alias A: multiline value/,                      'multiline entry' ],
            )
  {
  my ( $t, $re, $name ) = @$bad;
  my ( $s, $e ) = tns_build_names( $t );
  is( $s, undef, "$name: no string" );
  like( $e, $re, "$name: error" );
  }

done_testing();
