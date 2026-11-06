#!/usr/bin/perl
##############################################################################
##
##  real-world TNS descriptors, tnsnames.ora entries and connect strings,
##  collected from the internet, parsed and built back by Oracle::TNS,
##  checked that no data is lost and the result is valid Oracle Net syntax
##
##  run: prove -l xt/*.pl
##  failures are expected until the issues in KNOWN_ISSUES are fixed,
##  the file maps each failing test to its issue
##
##  sources:
##
##    [NET112]  Oracle Net Services Reference 11g R2, tnsnames.ora chapter
##              https://docs.oracle.com/cd/E18283_01/network.112/e10835/tnsnames.htm
##    [NAME19]  Oracle Net Services Administrator's Guide 19c, Configuring Naming Methods
##              https://docs.oracle.com/en/database/oracle/oracle-database/19/netag/configuring-naming-methods.html
##    [EZC23]   Oracle Net Services Administrator's Guide 23, Support for Easy Connect Plus
##              https://docs.oracle.com/en/database/oracle/oracle-database/23/netag/support-easy-connect-plus.html
##    [SYN92]   Oracle9i Net Services Reference 9.2, Syntax Rules for Configuration Files
##              https://docs.oracle.com/cd/B10500_01/network.920/a96581/syntax.htm
##    [DEVART]  dotConnect for Oracle, Connecting to Oracle Autonomous Database
##              https://docs.devart.com/dotconnect/oracle/OracleAutonomousDatabase.html
##    [DBDORA]  DBD::Oracle POD, connect
##              https://metacpan.org/pod/DBD::Oracle
##
##############################################################################
use strict;
use Test::More;
use Oracle::TNS;

##############################################################################
##
##  REFERENCE PARSER, independent of Oracle::TNS, after [SYN92]:
##  reserved ( ) = \ " ' #, values quoted with ' or ", # comments
##
##############################################################################

# returns ( [ [ KEY, value | [ ... ] ], ... ], undef ) or ( undef, $error )
# $strict: bare values must not contain reserved characters or whitespace
sub ref_tree
{
  my ( $str, $strict ) = @_;

  $str =~ s/("[^"]*"|'[^']*')|#[^\n]*/defined $1 ? $1 : ''/ge;
  pos( $str ) = 0;

  my ( $list, $err ) = ref_groups( \$str, $strict );
  return ( undef, $err ) if $err;
  $str =~ /\G\s*/gc;
  return ( undef, "trailing data at " . pos( $str ) ) if pos( $str ) < length( $str );
  return ( undef, "empty" ) unless @$list;
  return ( undef, "more than one top-level group" ) if @$list > 1;

  return ( $list, undef );
}

sub ref_groups
{
  my ( $sr, $strict ) = @_;

  my @groups;
  while( $$sr =~ /\G\s*\(\s*([A-Za-z0-9_.\-]+)\s*=\s*/gc )
    {
    my $key = uc $1;
    my $val;
    if( $$sr =~ /\G(?=\()/gc )
      {
      my $err;
      ( $val, $err ) = ref_groups( $sr, $strict );
      return ( undef, $err ) if $err;
      }
    elsif( $$sr =~ /\G"([^"]*)"/gc or $$sr =~ /\G'([^']*)'/gc )
      {
      $val = $1;
      }
    elsif( $strict ? $$sr =~ /\G([^()"'=\\#\s]*)(?=\s*\))/gc
                   : $$sr =~ /\G([^()"']*?)\s*(?=\))/gc )
      {
      $val = $1;
      }
    else
      {
      return ( undef, "bad value for $key at " . pos( $$sr ) );
      }
    return ( undef, "no ) after $key at " . pos( $$sr ) ) unless $$sr =~ /\G\s*\)/gc;
    push @groups, [ $key, $val ];
    }
  return ( undef, "bad group at " . pos( $$sr ) ) if $$sr =~ /\G\s*\(/gc;

  return ( \@groups, undef );
}

# canonical text: keys where order matters keep their relative order,
# all others sorted by key (stable)
my %ORDERED = map { $_ => 1 } qw( DESCRIPTION ADDRESS ADDRESS_LIST );

sub canon
{
  my $v = shift;

  return "=" . $v unless ref( $v );

  my $i = 0;
  my @idx  = map { [ $i++, $_ ] } @$v;
  my @ord  = grep {   $ORDERED{ $_->[1][0] } } @idx;
  my @oth  = sort { $a->[1][0] cmp $b->[1][0] or $a->[0] <=> $b->[0] } grep { ! $ORDERED{ $_->[1][0] } } @idx;

  return "=(" . join( '', map { "($_->[1][0]" . canon( $_->[1][1] ) . ")" } @ord, @oth ) . ")";
}

sub canon_str
{
  my ( $str, $strict ) = @_;
  my ( $list, $err ) = ref_tree( $str, $strict );
  return ( undef, $err ) if $err;
  return ( canon( $list ), undef );
}

##############################################################################
##
##  SAMPLES: tnsnames.ora entries, verbatim
##
##############################################################################

my @ENTRIES = (

[ 'NET112 6-4 connection manager', <<'TNS' ],
sample1=
 (DESCRIPTION=
   (SOURCE_ROUTE=yes)
   (ADDRESS=(PROTOCOL=tcp)(HOST=host1)(PORT=1630))    # 1
   (ADDRESS_LIST=
     (FAILOVER=on)
     (LOAD_BALANCE=off)                               #  2
     (ADDRESS=(PROTOCOL=tcp)(HOST=host2a)(PORT=1630))
     (ADDRESS=(PROTOCOL=tcp)(HOST=host2b)(PORT=1630)))
   (ADDRESS=(PROTOCOL=tcp)(HOST=host3)(PORT=1521))    #  3
   (CONNECT_DATA=(SERVICE_NAME=Sales.us.example.com)))
TNS

[ 'NET112 6-5 client load balancing', <<'TNS' ],
sample2=
 (DESCRIPTION=
   (LOAD_BALANCE=on)                                    # 1
   (FAILOVER=on)
   (ADDRESS_LIST=
     (SOURCE_ROUTE=yes)
     (ADDRESS=(PROTOCOL=tcp)(HOST=host1)(PORT=1630))    # 2
     (ADDRESS=(PROTOCOL=tcp)(HOST=host2)(PORT=1521)))
  (ADDRESS_LIST=
     (SOURCE_ROUTE=yes)
     (ADDRESS=(PROTOCOL=tcp)(HOST=host3)(port=1630))
     (ADDRESS=(PROTOCOL=tcp)(HOST=host4)(port=1521)))
   (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com)))  # 3
TNS

[ 'NET112 DESCRIPTION', <<'TNS' ],
net_service_name=
(DESCRIPTION=
  (ADDRESS=...)
  (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NET112 DESCRIPTION_LIST', <<'TNS' ],
net_service_name=
(DESCRIPTION_LIST=
 (DESCRIPTION=
  (ADDRESS=...)
  (CONNECT_DATA=(SERVICE_NAME=sales.example.com)))
 (DESCRIPTION=
  (ADDRESS=...)
  (CONNECT_DATA=(SERVICE_NAME=sales2.us.example.com))))
TNS

[ 'NET112 ADDRESS (unbalanced in docs)', <<'TNS' ],
net_service_name=
(DESCRIPTION=
 (ADDRESS=(PROTOCOL=tcp)(HOST=sales-svr)(PORT=1521))
 (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com))
TNS

[ 'NET112 ADDRESS_LIST', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
  (ADDRESS_LIST=
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-svr)(PORT=1521))
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-svr)(PORT=1521)))
  (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NET112 ENABLE (unbalanced in docs)', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
  (ENABLE=broken)
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-svr)(PORT=1521))
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-svr)(PORT=1521)))
  (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com))
TNS

[ 'NET112 FAILOVER (unbalanced in docs)', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
  (FAILOVER=on)
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-svr)(PORT=1521))
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-svr)(PORT=1521)))
  (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NET112 RECV_BUF_SIZE in ADDRESS (unbalanced in docs)', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
   (ADDRESS_LIST=
     (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-server)(PORT=1521)
        (RECV_BUF_SIZE=11784))
     (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-server)(PORT=1521)
        (RECV_BUF_SIZE=11784))
   (CONNECT_DATA=
     (SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NET112 SDU (unbalanced in docs)', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
  (SDU=8192)
   (ADDRESS_LIST=
     (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-server)(PORT=1521))
     (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-server)(PORT=1521)))
  (CONNECT_DATA=
    (SERVER_NAME=sales.us.example.com))
TNS

[ 'NET112 TYPE_OF_SERVICE', <<'TNS' ],
net_service_name=
 (DESCRIPTION_LIST=
  (DESCRIPTION=
   (ADDRESS=...)
   (CONNECT_DATA=
    (SERVICE_NAME=generic)
    (RDB_DATABASE=[.mf]mf_personal.rdb)
    (GLOBAL_NAME=alpha5))
   (TYPE_OF_SERVICE=rdb_database))
  (DESCRIPTION=
   (ADDRESS=...)
   (CONNECT_DATA=
    (SERVICE_NAME=sales.us.example.com))
   (TYPE_OF_SERVICE=oracle11_database)))
TNS

[ 'NET112 HS', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
   (ADDRESS=...)
   (ADDRESS=...)
   (CONNECT_DATA=
    (SID=sales6)
    (HS=ok)))
TNS

[ 'NET112 RDB_DATABASE with space', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
   (ADDRESS=...)
   (ADDRESS=...)
   (CONNECT_DATA=
    (SERVICE_NAME=sales.us.example.com)
    (RDB_DATABASE= [.mf]mf_personal.rdb)))
TNS

[ 'NET112 SERVER', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
   (ADDRESS=...)
   (ADDRESS=...)
   (CONNECT_DATA=
    (SERVER_NAME=sales.us.example.com)
    (SERVER=dedicated)))
TNS

[ 'NET112 SECURITY', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-svr)(PORT=1521))
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-svr)(PORT=1521))
  (CONNECT_DATA=
   (SERVICE_NAME=sales.us.example.com))
   (SECURITY=
    (SSL_SERVER_CERT_DN="cn=sales,cn=OracleContext,dc=us,dc=acme,dc=com")))
TNS

[ 'NET112 CONNECT_TIMEOUT', <<'TNS' ],
net_service_name=
 (DESCRIPTION=
  (CONNECT_TIMEOUT=10)(RETRY_COUNT=3)
  (ADDRESS_LIST=
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-svr)(PORT=1521))
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-svr)(PORT=1521)))
  (CONNECT_DATA=
   (SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NET112 RETRY_COUNT', <<'TNS' ],
net_service_name=
(DESCRIPTION_LIST=
 (DESCRIPTION=
  (CONNECT_TIMEOUT=10)(RETRY_COUNT=3)
  (ADDRESS_LIST=
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales1a-svr)(PORT=1521))
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales1b-svr)(PORT=1521)))
  (CONNECT_DATA=(SERVICE_NAME=sales1.example.com)))
 (DESCRIPTION=
  (CONNECT_TIMEOUT=60)(RETRY_COUNT=1)
  (ADDRESS_LIST=
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales2a-svr)(PORT=1521))
   (ADDRESS=(PROTOCOL=tcp)(HOST=sales2b-svr)(PORT=1521)))
  (CONNECT_DATA=(SERVICE_NAME=sales2.us.example.com))))
TNS

[ 'NET112 TRANSPORT_CONNECT_TIMEOUT (unbalanced in docs)', <<'TNS' ],
net_service_name =
  (DESCRIPTION=
    (TRANSPORT_CONNECT_TIMEOUT=10)
    (ADDRESS_LIST=
      (ADDRESS=(PROTOCOL=tcp)(HOST=sales1-svr)(PORT=1521))
      (ADDRESS=(PROTOCOL=tcp)(HOST=sales2-svr)(PORT=1521))
    (CONNECT_DATA=
      (SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NAME19 8-1 host name', <<'TNS' ],
sales=
(DESCRIPTION=
  (ADDRESS=(PROTOCOL=tcp)(HOST=sales-server)(PORT=1521))
  (CONNECT_DATA=
     (SERVICE_NAME=sales.us.example.com)))
TNS

[ 'NAME19 8-2 IPv6 address', <<'TNS' ],
salesdb =
  ( DESCRIPTION =
    ( ADDRESS=(PROTOCOL=tcp)(HOST=2001:0db8:1:1::200C:417A)(PORT=1522) )
    ( CONNECT_DATA =
        (SERVICE_NAME=sales.example.com) )
  )
TNS

[ 'NAME19 easy connect equivalent, empty SERVICE_NAME', <<'TNS' ],
ez1 = (DESCRIPTION= (CONNECT_DATA= (SERVICE_NAME=)) (ADDRESS= (PROTOCOL=TCP) (HOST=sales-server) (PORT=1521)))
TNS

[ 'NAME19 easy connect equivalent, server and instance', <<'TNS' ],
ez2 = (DESCRIPTION= (CONNECT_DATA= (SERVICE_NAME=sales) (INSTANCE_NAME=inst1) (SERVER=dedicated)) (ADDRESS= (PROTOCOL=TCP) (HOST=sales-server) (PORT=1521)))
TNS

[ 'NAME19 easy connect plus equivalent, lowercase keys', <<'TNS' ],
ez3 = (DESCRIPTION= (SDU=8128)(retry_count=3)(connect_timeout=10) (ADDRESS=(PROTOCOL=tcp)(HOST=saleserver1)(PORT=1521)) (CONNECT_DATA=(SERVICE_NAME=sales)))
TNS

[ 'NAME19 tcps equivalent, unquoted DN with =', <<'TNS' ],
ez4 = (DESCRIPTION= (ADDRESS=(PROTOCOL=tcps)(HOST=salesserver)(PORT=1521)) (CONNECT_DATA=(SERVICE_NAME=sales))(SECURITY=(TLS_SERVER_DN_MATCH=TRUE)(TLS_SERVER_CERT_DN=cn=sales,cn=OracleContext,dc=us,dc=example,dc=com)(WALLET_LOCATION=/tmp/oracle)))
TNS

[ 'NAME19 directory export (unbalanced in docs)', <<'TNS' ],
99 (description=(address=(protocol=tcp) (host=sales)(port=1999)))
   (connect_data=(service_name=dirprod)))
TNS

[ 'EZC23 example 2 equivalent', <<'TNS' ],
ezp2 = (DESCRIPTION=
   (retry_count=3)(retry_delay=2)
   (connect_timeout=1min)(transport_connect_timeout=30sec)
   (ADDRESS=(PROTOCOL=tcp)(HOST=salesserver1)(PORT=1521))
   (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com))
)
TNS

[ 'EZC23 example 3 equivalent, address lists', <<'TNS' ],
ezp3 = (DESCRIPTION=
  (SDU=16384)
  (ADDRESS_LIST=
    (ADDRESS=(PROTOCOL=tcp)(HOST=saleserver1)(PORT=1521))
  )
  (ADDRESS_LIST=
    (ADDRESS=(PROTOCOL=tcp)(HOST=saleserver2)(PORT=1522))
  )
  (CONNECT_DATA=(SERVICE_NAME=sales.us.example.com))
)
TNS

[ 'DEVART autonomous database', <<'TNS' ],
db000000000000_high = (description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-frankfurt-1.oraclecloud.com))(connect_data=(service_name=gcf000000000000_db000000000000_high.adb.oraclecloud.com))(security=(ssl_server_cert_dn="CN=adwc.eucom-central-1.oraclecloud.com,OU=Oracle BMCS FRANKFURT,O=Oracle Corporation,L=Redwood City,ST=California,C=US")))
TNS

[ 'DEVART sqlnet.ora wallet, quoted backslash path', <<'TNS' ],
WALLET_LOCATION = (SOURCE = (METHOD = file) (METHOD_DATA = (DIRECTORY="C:\Oracle\Wallet")))
TNS

[ 'DBDORA TCPS descriptor', <<'TNS' ],
mydb_ssl = (DESCRIPTION=
  (ADDRESS=(PROTOCOL=TCPS)(HOST=dbhost.example.com)(PORT=2484))
  (CONNECT_DATA=(SERVICE_NAME=ORCL)))
TNS

[ 'DBDORA DRCP descriptor, space in HOST', <<'TNS' ],
pooled = (DESCRIPTION=
(ADDRESS=(PROTOCOL=TCP)(HOST= foobar)(PORT=1521))
(CONNECT_DATA=(SID=ORCL)(SERVER=POOLED)))
TNS

[ 'SYN92 single-quoted value', <<'TNS' ],
q1 = (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=h)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME='sales db')))
TNS

[ 'SYN92 double quote inside single quotes', <<'TNS' ],
q2 = (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=h)(PORT=1521))(SECURITY=(SSL_SERVER_CERT_DN='CN="x, y",O=z')))
TNS

[ 'SYN92 single quote inside double quotes', <<'TNS' ],
q3 = (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=h)(PORT=1521))(SECURITY=(SSL_SERVER_CERT_DN="CN=O'Brien,O=z")))
TNS

[ 'SYN92 quoted backslash', <<'TNS' ],
q4 = (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=h)(PORT=1521))(SECURITY=(MY_WALLET_DIRECTORY="C:\app\wallet")))
TNS

);

##############################################################################
##
##  SAMPLES: connect strings, verbatim
##
##############################################################################

my @CONNECTS = (
  [ 'user/pass from your example',   'ahive/ahive@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST= 192.168.5.221)(PORT=1521))(CONNECT_DATA=(SID=CARDS)))' ],
  [ 'DBDORA username/password',      'username/password' ],
  [ 'DBDORA username@DB',            'username@DB' ],
  [ 'DBDORA scott/tiger',            'scott/tiger' ],
  [ 'DBDORA OS authentication',      '/' ],
  [ 'DBDORA TCPS descriptor',        "scott/tiger\@(DESCRIPTION=\n  (ADDRESS=(PROTOCOL=TCPS)(HOST=dbhost.example.com)(PORT=2484))\n  (CONNECT_DATA=(SERVICE_NAME=ORCL)))" ],
  [ 'DBDORA DRCP descriptor',        "scott/tiger\@(DESCRIPTION=\n(ADDRESS=(PROTOCOL=TCP)(HOST= foobar)(PORT=1521))\n(CONNECT_DATA=(SID=ORCL)(SERVER=POOLED)))" ],
  [ 'DBDORA DRCP alias:POOLED',      'username@DB:POOLED' ],
  [ 'NAME19 ezconnect host:port/svc','scott@sales-server:1521/sales.us.example.com' ],
  [ 'NAME19 ezconnect //host/svc',   'scott@//sales-server/sales.us.example.com' ],
  [ 'NAME19 ezconnect //fqdn/svc',   'scott@//sales-server.us.example.com/sales.us.example.com' ],
  [ 'NAME19 ezconnect host/db_name', 'username@host/db_name' ],
  [ 'NAME19 ezconnect //host',       'scott@//sales-server' ],
  [ 'NAME19 alias or host',          'scott@sales-server' ],
  [ 'NAME19 ezconnect host:port',    'u@sales-server:3456' ],
  [ 'NAME19 ezconnect host/svc',     'u@sales-server/sales' ],
  [ 'NAME19 ezconnect ipv6',         'u@[2001:0db8:0:0::200C:417A]:80/sales' ],
  [ 'NAME19 ezconnect server/inst',  'u@sales-server/sales:dedicated/inst1' ],
  [ 'NAME19 ezconnect empty service','u@sales-server//inst1' ],
  [ 'NAME19 ezconnect plus params',  'u@salesserver1:1521/sales?SDU=8128&retry_count=3&connect_timeout=10' ],
  [ 'NAME19 ezconnect plus hosts',   'u@salesserver1:1521,salesserver2,salesserver3:1522/sales' ],
  [ 'NAME19 ezconnect plus tcps',    'u@tcps://salesserver1:1521/sales' ],
  [ 'NAME19 ezconnect plus tcps dn', 'u@tcps://sales-server:1521/sales?tls_server_cert_dn="cn=sales,cn=OracleContext,dc=us,dc=example,dc=com"&wallet_location="/tmp/oracle"' ],
  [ 'EZC23 example 1',               'u@salesserver1:1521/sales.us.example.com?sdu=16384' ],
  [ 'EZC23 example 2',               'u@salesserver1:1521/sales.us.example.com?connect_timeout=1min&transport_connect_timeout=30sec&retry_count=3&retry_delay=2' ],
  [ 'EZC23 example 3 address lists', 'u@salesserver1:1521;saleserver2:1522/sales.us.example.com?sdu=16384' ],
  [ 'DEVART adb tcps url',           'ADMIN/secret@tcps://adb.eu-frankfurt-1.oraclecloud.com:1522/gcf000000000000_db000000000000_high.adb.oraclecloud.com' ],
  [ 'DEVART adb alias',              'ADMIN/secret@db000000000000_high' ],
);

##############################################################################
##
##  TESTS: descriptors
##
##############################################################################

my %names_expected;
my $names_file = '';

for my $s ( @ENTRIES )
  {
  my ( $name, $entry ) = @$s;
  my ( $alias, $desc ) = $entry =~ /^\s*(\S+?)\s*=\s*(.*)$/s;
  $desc = $entry unless defined $desc;

  my ( $ref,  $ref_err  ) = canon_str( $desc );
  my ( $tree, $tree_err ) = tns_parse( $desc );

  if( $ref_err )
    {
    ok( $tree_err, "$name: invalid syntax rejected" ) or diag( "reference: $ref_err" );
    next;
    }

  ok( ! $tree_err, "$name: valid syntax accepted" ) or do { diag( "tns_parse: $tree_err" ); next };

  for my $indent ( undef, 2 )
    {
    my $mode = defined $indent ? 'pretty' : 'single line';
    my ( $built, $build_err ) = tns_build( $tree, $indent );
    ok( ! $build_err, "$name: $mode builds" ) or do { diag( $build_err ); next };

    my ( $out, $out_err ) = canon_str( $built, 1 );
    ok( ! $out_err, "$name: $mode output is valid strict syntax" ) or diag( "$out_err\n$built" );
    ( $out ) = canon_str( $built ) if $out_err;
    is( $out, $ref, "$name: $mode output keeps all data and address order" ) or diag( $built );

    my ( $again ) = tns_parse( $built );
    is_deeply( $again, $tree, "$name: $mode output parses back to the same tree" );
    }

  $names_expected{ uc $alias } = $ref;
  $names_file .= "# $name\n$entry\n";
  }

##############################################################################
##
##  TESTS: all valid entries as one tnsnames.ora file
##
##############################################################################

$names_file .= "IFILE = /etc/oracle/other.ora\n";

my ( $names, $names_err ) = tns_parse_names( $names_file );
ok( ! $names_err, "tnsnames.ora: parses" ) or diag( $names_err );
if( $names )
  {
  is_deeply( [ sort keys %$names ], [ sort 'IFILE', keys %names_expected ], "tnsnames.ora: all aliases" );
  my ( $text, $text_err ) = tns_build_names( $names );
  ok( ! $text_err, "tnsnames.ora: builds" ) or diag( $text_err );
  my ( $again ) = tns_parse_names( $text );
  is_deeply( $again, $names, "tnsnames.ora: output parses back to the same names" );
  for my $alias ( sort keys %names_expected )
    {
    my ( $built ) = tns_build( $names->{ $alias } );
    my ( $out )   = canon_str( $built );
    is( $out, $names_expected{ $alias }, "tnsnames.ora: $alias keeps all data and address order" );
    }
  }

##############################################################################
##
##  TESTS: connect strings
##
##############################################################################

# reference split of user/pass@target, quotes removed
sub ref_connect
{
  my $str = shift;
  my ( $user, $pass, $target ) = $str =~ /^\s*(?:"([^"]*)"|([^\/\@"\s]*))(?:\/(?:"([^"]*)"|([^\@"\s]*)))?(?:\@\s*(.*?))?\s*$/s
      ? ( defined $1 ? $1 : $2, defined $3 ? $3 : $4, $5 ) : ();
  if( defined $target and $target =~ /^\(/ )
    {
    my ( $c, $e ) = canon_str( $target );
    $target = defined $c ? "TNS$c" : "BAD:$e";
    }
  elsif( defined $target )
    {
    $target =~ s/^\/\///;
    }
  return join "\0", map { defined $_ ? $_ : '<undef>' } $user, $pass, $target;
}

for my $s ( @CONNECTS )
  {
  my ( $name, $str ) = @$s;

  my ( $conn, $err ) = tns_parse_connect( $str );
  ok( ! $err, "connect $name: supported" ) or do { diag( "$str\n$err" ); next };

  if( my $ez = $conn->{ EZCONNECT } )
    {
    my @folded = grep { $ez->{ $_ } =~ /[?&,;="]/ } sort keys %$ez;
    ok( ! @folded, "connect $name: no EZConnect Plus syntax folded into @folded" )
        or diag( join "\n", map { "$_ => $ez->{ $_ }" } @folded );
    }
  if( exists $conn->{ ALIAS } )
    {
    unlike( $conn->{ ALIAS }, qr/[:\/]/, "connect $name: alias is a plain name" );
    }

  my ( $built, $build_err ) = tns_build_connect( $conn );
  ok( ! $build_err, "connect $name: builds" ) or do { diag( $build_err ); next };

  is( ref_connect( $built ), ref_connect( $str ), "connect $name: keeps user, password and target" )
      or diag( "in:  $str\nout: $built" );

  my ( $again ) = tns_parse_connect( $built );
  is_deeply( $again, $conn, "connect $name: output parses back to the same" );
  }

done_testing();
