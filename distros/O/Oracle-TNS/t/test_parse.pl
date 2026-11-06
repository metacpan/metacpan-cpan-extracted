#!/usr/bin/perl
use strict;
use Test::More;
use Oracle::TNS;

my ( $tree, $err, $names );

### single descriptor, repeated keys become arrayref

( $tree, $err ) = tns_parse( '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=db1)(PORT=1521))'
                            .'(ADDRESS=(PROTOCOL=TCP)(HOST=db2)(PORT=1521))'
                            .'(CONNECT_DATA=(SERVICE_NAME=ORCLPDB1)))' );
is( $err, undef, 'descriptor parses' );
is_deeply( $tree, {
                  DESCRIPTION => {
                                 ADDRESS      => [
                                                 { PROTOCOL => 'TCP', HOST => 'db1', PORT => 1521 },
                                                 { PROTOCOL => 'TCP', HOST => 'db2', PORT => 1521 },
                                                 ],
                                 CONNECT_DATA => { SERVICE_NAME => 'ORCLPDB1' },
                                 },
                  }, 'descriptor tree' );

### single address stays hashref, three repeats stay one flat arrayref

( $tree, $err ) = tns_parse( '(DESCRIPTION=(ADDRESS=(HOST=a)))' );
is_deeply( $tree, { DESCRIPTION => { ADDRESS => { HOST => 'a' } } }, 'single key is not an arrayref' );

( $tree, $err ) = tns_parse( '(A=(B=1)(B=2)(B=3))' );
is_deeply( $tree, { A => { B => [ 1, 2, 3 ] } }, 'three repeated keys' );

### keys uppercased, values kept, whitespace and comments ignored

( $tree, $err ) = tns_parse( <<'TNS' );
  # leading comment
  ( description =
    ( address = ( protocol = tcp ) ( host = Db1.Example.Com ) ( port = 1521 ) ) # trailing comment
    ( connect_data = ( service_name = MixedCase ) )
  )
TNS
is( $err, undef, 'multiline descriptor with comments parses' );
is_deeply( $tree, {
                  DESCRIPTION => {
                                 ADDRESS      => { PROTOCOL => 'tcp', HOST => 'Db1.Example.Com', PORT => 1521 },
                                 CONNECT_DATA => { SERVICE_NAME => 'MixedCase' },
                                 },
                  }, 'keys uppercased, values untouched' );

### quoted, empty and odd bare values

( $tree, $err ) = tns_parse( '(X=(Q="a (b) = c")(E=)(S=a b)(M=k=v)(D=a-b.c_d))' );
is( $err, undef, 'odd values parse' );
is_deeply( $tree, { X => { Q => 'a (b) = c', E => '', S => 'a b', M => 'k=v', D => 'a-b.c_d' } }, 'odd values' );

### several top-level groups

( $tree, $err ) = tns_parse( '(A=1)(B=2)(A=3)' );
is_deeply( $tree, { A => [ 1, 3 ], B => 2 }, 'top-level groups' );

### errors

for my $bad (
            [ '(DESCRIPTION=(ADDRESS=(HOST=a))',  qr/expected \) after DESCRIPTION/, 'unclosed group' ],
            [ '(DESCRIPTION=(HOST=a)))',          qr/trailing data at offset 22/,     'extra close paren' ],
            [ '(=a)',                             qr/expected KEY= at offset 1/,      'missing key' ],
            [ '(HOST)',                           qr/expected KEY= at offset 1/,      'missing =' ],
            [ '(HOST="a"b)',                      qr/expected \) after HOST/,         'garbage after quoted value' ],
            [ 'HOST=a',                           qr/trailing data at offset 0/,      'no parens' ],
            )
  {
  my ( $str, $re, $name ) = @$bad;
  my ( $t, $e ) = tns_parse( $str );
  is( $t, undef, "$name: no tree" );
  like( $e, $re, "$name: error" );
  }

( $tree, $err ) = tns_parse( '(HOST="a)' );
is( $tree, undef, 'unterminated quote: no tree' );
like( $err, qr/^bad value for HOST/, 'unterminated quote: error' );

( $tree, $err ) = tns_parse( '(HOST=a"b)' );
like( $err, qr/^bad value for HOST/, 'double quote in bare value' );

for my $empty ( '', "  \n", "# only a comment\n" )
  {
  ( $tree, $err ) = tns_parse( $empty );
  is( $tree, undef, 'empty descriptor: no tree' );
  is( $err, 'empty descriptor', 'empty descriptor: error' );
  }

### comments outside quotes only

( $tree, $err ) = tns_parse( qq[(A=(H="a#b")(P="x # y") # comment ("quoted")\n(N=1))] );
is( $err, undef, '# inside quotes parses' );
is_deeply( $tree, { A => { H => 'a#b', P => 'x # y', N => 1 } }, '# inside quotes is kept' );

### tnsnames.ora

( $names, $err ) = tns_parse_names( <<'ORA' );
# tnsnames.ora

prod, prod.world =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = db1)(PORT = 1521))
    (CONNECT_DATA = (SERVICE_NAME = PROD))
  )

Test-1.db = (DESCRIPTION=(ADDRESS=(HOST=db2)(PORT=1522))(CONNECT_DATA=(SID=T1)))
ORA
is( $err, undef, 'tnsnames parses' );
is_deeply( [ sort keys %$names ], [ 'PROD', 'PROD.WORLD', 'TEST-1.DB' ], 'aliases uppercased, alias lists split' );
is( $names->{ 'PROD' }, $names->{ 'PROD.WORLD' }, 'alias list shares one tree' );
is_deeply( $names->{ 'PROD' }, { DESCRIPTION => { ADDRESS => { PROTOCOL => 'TCP', HOST => 'db1', PORT => 1521 },
                                                  CONNECT_DATA => { SERVICE_NAME => 'PROD' } } }, 'prod tree' );
is_deeply( $names->{ 'TEST-1.DB' }, { DESCRIPTION => { ADDRESS => { HOST => 'db2', PORT => 1522 },
                                                       CONNECT_DATA => { SID => 'T1' } } }, 'test tree' );

( $names, $err ) = tns_parse_names( '' );
is_deeply( $names, {}, 'empty tnsnames' );

( $names, $err ) = tns_parse_names( "A = \nB = (X=1)" );
is( $names, undef, 'empty descriptor: no names' );
like( $err, qr/^alias A: empty descriptor/, 'empty descriptor: error' );

( $names, $err ) = tns_parse_names( "A = (X=(Y=1)" );
like( $err, qr/^alias A: expected \) after X/, 'broken descriptor: error names alias' );

( $names, $err ) = tns_parse_names( "A = (X=1)\n(Y=2)" );
is( $names, undef, 'group without alias: no names' );
like( $err, qr/^unparsed data at offset 10/, 'group without alias: error' );

( $names, $err ) = tns_parse_names( "A = (X=1)(Y=2)\nB = (Z=3)" );
like( $err, qr/^unparsed data at offset 9/, 'two groups for one alias' );

### NAME = value entries

( $names, $err ) = tns_parse_names( "IFILE = /x.ora\r\nA = (X=1)\r\n" );
is( $err, undef, 'CRLF line endings parse' );
is_deeply( $names, { IFILE => '/x.ora', A => { X => 1 } }, 'CRLF line endings' );

( $names, $err ) = tns_parse_names( "A = (X=1)\nA = /x.ora\nB = /y.ora\nB = (Y=2)\n" );
is_deeply( $names, { A => '/x.ora', B => { Y => 2 } }, 'same alias as descriptor and value: last wins' );

( $tree, $err ) = tns_parse( qq[(A=(B="a\nb#c")(C=1)) # comment] );
is_deeply( $tree, { A => { B => "a\nb#c", C => 1 } }, 'multiline quoted value with #' );

( $names, $err ) = tns_parse_names( <<'ORA' );
IFILE = /etc/oracle/a.ora   # first
ifile = "/etc/oracle/dir with space/b.ora"
A = (X="v#1") # comment
ORA
is( $err, undef, 'NAME = value entries parse' );
is_deeply( $names, {
                   IFILE => [ '/etc/oracle/a.ora', '/etc/oracle/dir with space/b.ora' ],
                   A     => { X => 'v#1' },
                   }, 'NAME = value entries' );

done_testing();
