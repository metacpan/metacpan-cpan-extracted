#!/usr/bin/perl
use strict;
use Test::More;
use Oracle::TNS;

my ( $conn, $str, $err );

my $DESC_STR  = '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=192.168.5.221)(PORT=1521))(CONNECT_DATA=(SID=CARDS)))';
my $DESC_TREE = { DESCRIPTION => {
                                 ADDRESS      => { PROTOCOL => 'TCP', HOST => '192.168.5.221', PORT => 1521 },
                                 CONNECT_DATA => { SID => 'CARDS' },
                                 } };

### parse

for my $ok (
           [ 'ahive/ahive@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST= 192.168.5.221)(PORT=1521))(CONNECT_DATA=(SID=CARDS)))',
             { USER => 'ahive', PASS => 'ahive', TNS => $DESC_TREE },                                'descriptor' ],
           [ "  scott/tiger@ \n (DESCRIPTION = (ADDRESS=(HOST=h)) ) \n",
             { USER => 'scott', PASS => 'tiger', TNS => { DESCRIPTION => { ADDRESS => { HOST => 'h' } } } }, 'descriptor with whitespace' ],
           [ 'scott/tiger@Prod.World',          { USER => 'scott', PASS => 'tiger', ALIAS => 'Prod.World' }, 'alias, case kept' ],
           [ 'scott@PROD',                      { USER => 'scott', ALIAS => 'PROD' },                       'user without password' ],
           [ 'scott/tiger',                     { USER => 'scott', PASS => 'tiger' },                       'no target' ],
           [ 'scott',                           { USER => 'scott' },                                        'user only' ],
           [ '/@PROD',                          { ALIAS => 'PROD' },                                        'external auth with alias' ],
           [ '/',                               {},                                                         'external auth, local' ],
           [ 'a/b/c@PROD',                      { USER => 'a', PASS => 'b/c', ALIAS => 'PROD' },            '/ in password' ],
           [ 'u$1#x/p#2$@PROD',                 { USER => 'u$1#x', PASS => 'p#2$', ALIAS => 'PROD' },       '$ and # in user and password' ],
           [ '"my user"/"p@ss w/"@PROD',        { USER => 'my user', PASS => 'p@ss w/', ALIAS => 'PROD' },  'quoted user and password' ],
           [ 'u/""@PROD',                       { USER => 'u', PASS => '', ALIAS => 'PROD' },               'quoted empty password' ],
           [ 'u/p@db1:1521/ORCL',               { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1', PORT => 1521, SERVICE_NAME => 'ORCL' } }, 'ezconnect' ],
           [ 'u/p@//db1.example.com/ORCL',      { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1.example.com', SERVICE_NAME => 'ORCL' } }, 'ezconnect // no port' ],
           [ 'u/p@db1:1521',                    { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1', PORT => 1521 } }, 'ezconnect host and port' ],
           [ 'u/p@//db1',                       { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1' } }, 'ezconnect // host only' ],
           [ 'u/p@db1:1521/svc.x:DEDICATED/inst1',
             { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1', PORT => 1521, SERVICE_NAME => 'svc.x', SERVER => 'DEDICATED', INSTANCE_NAME => 'inst1' } }, 'ezconnect full' ],
           [ 'u/p@db1/svc/inst1',               { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1', SERVICE_NAME => 'svc', INSTANCE_NAME => 'inst1' } }, 'ezconnect instance without server' ],
           [ 'u/p@[::1]:1521/svc',              { USER => 'u', PASS => 'p', EZCONNECT => { HOST => '::1', PORT => 1521, SERVICE_NAME => 'svc' } }, 'ezconnect ipv6' ],
           [ 'u/p@//[fe80::1]',                 { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'fe80::1' } }, 'ezconnect ipv6 host only' ],
           [ 'u/p@192.168.5.221',               { USER => 'u', PASS => 'p', ALIAS => '192.168.5.221' },      'bare ip is an alias' ],
           )
  {
  my ( $in, $exp, $name ) = @$ok;
  ( $conn, $err ) = tns_parse_connect( $in );
  is( $err, undef, "parse $name: no error" );
  is_deeply( $conn, $exp, "parse $name" );
  }

for my $bad (
            [ undef,                     qr/^empty connect string/,                 'undef' ],
            [ "  \n",                    qr/^empty connect string/,                 'blank' ],
            [ '@PROD',                   qr/^expected user or \/ at offset 0/,      'no user and no /' ],
            [ '/p@PROD',                 qr/^password without user/,                'password without user' ],
            [ 'u/@PROD',                 qr/^missing password after \/ at offset 2/, 'empty password' ],
            [ 'u/p@',                    qr/^missing connect target after \@/,      'empty target' ],
            [ 'u/p@ ',                   qr/^missing connect target after \@/,      'blank target' ],
            [ 'u/p@ss@PROD',             qr/^bad connect target: ss\@PROD/,         'unquoted @ in password' ],
            [ 'u/p@(DESCRIPTION=(HOST=a)', qr/^descriptor: expected \) after DESCRIPTION/, 'broken descriptor' ],
            [ 'u/p@(DESCRIPTION=(HOST=a)) x', qr/^descriptor: trailing data/,         'data after descriptor' ],
            [ 'u/p@db1:port/svc',        qr/^bad connect target/,                   'ezconnect bad port' ],
            [ 'u/p@db1:1521/svc:ded-x',  qr/^bad connect target/,                   'ezconnect bad server' ],
            [ 'u/p@db1:1521/svc@x',      qr/^bad connect target/,                   'ezconnect @ in service' ],
            [ 'u/p@[::1',                qr/^bad connect target/,                   'ezconnect unclosed ipv6' ],
            [ 'u/p@PROD x',              qr/^bad connect target/,                   'space in target' ],
            [ 'u p@PROD',                qr/^trailing data at offset 1/,            'space in user' ],
            [ '"u/p@PROD',               qr/^expected user or \/ at offset 0/,      'unterminated quoted user' ],
            [ 'u/"p@PROD',               qr/^missing password after \/ at offset 2/, 'unterminated quoted password' ],
            )
  {
  my ( $in, $re, $name ) = @$bad;
  ( $conn, $err ) = tns_parse_connect( $in );
  is( $conn, undef, "parse $name: no result" );
  like( $err, $re, "parse $name: error" );
  }

### build

for my $ok (
           [ { USER => 'ahive', PASS => 'ahive', TNS => $DESC_TREE }, "ahive/ahive\@$DESC_STR",         'descriptor' ],
           [ { USER => 'u', PASS => 'p', ALIAS => 'PROD' },          'u/p@PROD',                       'alias' ],
           [ { USER => 'u', ALIAS => 'PROD' },                       'u@PROD',                         'no password' ],
           [ { USER => 'u', PASS => 'p' },                           'u/p',                            'no target' ],
           [ { ALIAS => 'PROD' },                                    '/@PROD',                         'external auth' ],
           [ {},                                                     '/',                              'external auth, local' ],
           [ { USER => 'my user', PASS => 'p@ss w', ALIAS => 'X' },  '"my user"/"p@ss w"@X',           'quoting' ],
           [ { USER => 'a/b', PASS => 'c/d', ALIAS => 'X' },         '"a/b"/c/d@X',                    '/ quoted in user only' ],
           [ { USER => '', PASS => '', ALIAS => 'X' },               '""/""@X',                        'empty user and password' ],
           [ { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1', PORT => 1521, SERVICE_NAME => 'ORCL' } },
             'u/p@db1:1521/ORCL',                                                                      'ezconnect' ],
           [ { USER => 'u', PASS => 'p', EZCONNECT => { HOST => 'db1', PORT => 1521, SERVICE_NAME => 's', SERVER => 'POOLED', INSTANCE_NAME => 'i' } },
             'u/p@db1:1521/s:POOLED/i',                                                                'ezconnect full' ],
           [ { USER => 'u', EZCONNECT => { HOST => 'db1' } },        'u@//db1',                        'ezconnect host only gets //' ],
           [ { USER => 'u', EZCONNECT => { HOST => '10.0.0.1' } },   'u@//10.0.0.1',                   'ezconnect ip only gets //' ],
           [ { USER => 'u', EZCONNECT => { HOST => '::1', PORT => 1 } }, 'u@[::1]:1',                  'ezconnect ipv6' ],
           [ { USER => 'u', EZCONNECT => { HOST => '::1' } },        'u@[::1]',                        'ezconnect ipv6 host only' ],
           )
  {
  my ( $in, $exp, $name ) = @$ok;
  ( $str, $err ) = tns_build_connect( $in );
  is( $err, undef, "build $name: no error" );
  is( $str, $exp, "build $name" );

  ( $conn, $err ) = tns_parse_connect( $str );
  is_deeply( $conn, $in, "build $name: round trip" );
  }

( $str, $err ) = tns_build_connect( { USER => 'u', TNS => { A => { B => 1 } } }, 2 );
is( $str, "u\@(A=\n  (B=1)\n)", 'build descriptor with indent' );

for my $bad (
            [ undef,                                              qr/^hashref expected/,                    'undef' ],
            [ [],                                                 qr/^hashref expected/,                    'arrayref' ],
            [ { USER => 'u', HOST => 'x', PORT => 1 },            qr/^unknown key HOST PORT/,              'unknown keys' ],
            [ { USER => 'u', ALIAS => 'X', TNS => { A => 1 } },   qr/^only one of TNS ALIAS expected/,     'two targets' ],
            [ { PASS => 'p', ALIAS => 'X' },                      qr/^PASS without USER/,                  'pass without user' ],
            [ { USER => undef },                                  qr/^undefined USER/,                     'undef user' ],
            [ { USER => 'u', PASS => undef },                     qr/^undefined PASS/,                     'undef pass' ],
            [ { USER => [] },                                     qr/^unsupported USER type ARRAY/,        'ref user' ],
            [ { USER => 'u"x' },                                  qr/^double quote in USER/,               'quote in user' ],
            [ { USER => 'u', PASS => 'p"x' },                     qr/^double quote in PASS/,               'quote in pass' ],
            [ { USER => 'u', ALIAS => 'a b' },                    qr/^bad ALIAS/,                          'bad alias' ],
            [ { USER => 'u', ALIAS => undef },                    qr/^bad ALIAS/,                          'undef alias' ],
            [ { USER => 'u', TNS => {} },                         qr/^TNS: empty hashtree/,                'empty tns' ],
            [ { USER => 'u', TNS => 'x' },                        qr/^TNS: hashref expected/,              'scalar tns' ],
            [ { USER => 'u', EZCONNECT => 'x' },                  qr/^EZCONNECT: hashref expected/,        'scalar ezconnect' ],
            [ { USER => 'u', EZCONNECT => { PORT => 1 } },        qr/^EZCONNECT: missing HOST/,            'ezconnect no host' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'h', SID => 1 } }, qr/^EZCONNECT: unknown key SID/,   'ezconnect unknown key' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'h', PORT => 'x' } }, qr/^EZCONNECT: bad PORT/,        'ezconnect bad port' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'a/b' } },    qr/^EZCONNECT: bad HOST/,                'ezconnect bad host' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'a@b' } },    qr/^EZCONNECT: bad HOST/,                'ezconnect @ in host' ],
            [ { USER => 'u', EZCONNECT => { HOST => '[::1]' } },  qr/^EZCONNECT: bad HOST/,                'ezconnect brackets in host' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'h', INSTANCE_NAME => 'i@x', SERVICE_NAME => 's' } }, qr/^EZCONNECT: bad INSTANCE_NAME/, 'ezconnect @ in instance' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'h', SERVICE_NAME => 'a:b' } }, qr/^EZCONNECT: bad SERVICE_NAME/, 'ezconnect bad service' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'h', SERVER => 'DEDICATED' } }, qr/^EZCONNECT: SERVER and INSTANCE_NAME need SERVICE_NAME/, 'ezconnect server without service' ],
            [ { USER => 'u', EZCONNECT => { HOST => 'h', INSTANCE_NAME => 'i' } },  qr/^EZCONNECT: SERVER and INSTANCE_NAME need SERVICE_NAME/, 'ezconnect instance without service' ],
            )
  {
  my ( $in, $re, $name ) = @$bad;
  ( $str, $err ) = tns_build_connect( $in );
  is( $str, undef, "build $name: no string" );
  like( $err, $re, "build $name: error" );
  }

### mask

for my $mask (
             [ "scott/tiger\@$DESC_STR",   "***/***\@$DESC_STR",  'descriptor' ],
             [ 'scott/tiger@PROD',         '***/***@PROD',        'alias' ],
             [ 'scott@PROD',               '***@PROD',            'user without password' ],
             [ 'scott',                    '***',                 'user only' ],
             [ 'scott/tiger',              '***/***',             'no target' ],
             [ '/@PROD',                   '/@PROD',              'external auth' ],
             [ '"my user"/"p@ss w"@PROD',  '***/***@PROD',        'quoted user and password' ],
             [ 'u/p@db1:1521/ORCL',        '***/***@db1:1521/ORCL', 'ezconnect' ],
             [ 'u/p@bad target',           '***@bad target',      'unparsable, target kept' ],
             [ 'u/"p@ss',                  '***',                 'unparsable, quote after @' ],
             [ 'u/p@x@y z',                '***@y z',             'unparsable, after last @' ],
             [ '',                         '',                    'empty' ],
             [ undef,                      undef,                 'undef' ],
             )
  {
  my ( $in, $out, $name ) = @$mask;
  is( tns_mask_connect( $in ), $out, "mask $name" );
  }

is( tns_mask_connect( 'scott/tiger@PROD', 'X' ), 'X/X@PROD', 'mask custom' );

done_testing();
