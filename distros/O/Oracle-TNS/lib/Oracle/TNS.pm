##############################################################################
##
##  Oracle::TNS -- parse Oracle TNS descriptors / tnsnames.ora into a hashtree
##                 and build descriptor strings back from a hashtree
##  Copyright (c) 2026 Vladi Belperchinov-Shabanski "Cade"
##                           <cade@noxrun.com>
##                     http://cade.noxrun.com
##
##  LICENSE: GPLv2
##
##############################################################################
##
##  Hashtree layout:
##
##    (DESCRIPTION=(ADDRESS=(HOST=a)(PORT=1521))(ADDRESS=(HOST=b)(PORT=1521))
##                 (CONNECT_DATA=(SERVICE_NAME=X)))
##
##  becomes
##
##    {
##      DESCRIPTION => {
##        ADDRESS => [ { HOST => 'a', PORT => 1521 },
##                     { HOST => 'b', PORT => 1521 } ],
##        CONNECT_DATA => { SERVICE_NAME => 'X' },
##      }
##    }
##
##  Repeated keys at the same level are collected into an array reference.
##  Keys are uppercased on parse. A single-element value may be given either
##  as a scalar/hashref or as a one-element arrayref when building.
##
##############################################################################
package Oracle::TNS;
use strict;
use Exporter;
use Hash::Util::FieldHash qw( fieldhash );
use Scalar::Util qw( weaken );

our $VERSION = '1.04';

our @ISA    = qw( Exporter );
our @EXPORT = qw(
                  tns_parse
                  tns_parse_names

                  tns_build
                  tns_build_names

                  tns_parse_connect
                  tns_build_connect
                  tns_mask_connect

                );

# preferred output order for well-known keys, everything else sorted after
our @KEY_ORDER = qw(
                     DESCRIPTION_LIST DESCRIPTION
                     LOAD_BALANCE FAILOVER SOURCE_ROUTE ENABLE
                     ADDRESS_LIST ADDRESS PROTOCOL HOST PORT
                     CONNECT_DATA SERVICE_NAME SID SERVER INSTANCE_NAME
                     SECURITY
                   );
my %KEY_RANK;
@KEY_RANK{ @KEY_ORDER } = ( 1 .. @KEY_ORDER );

# parsed hashref => [ [ KEY, value ], ... ] in parsed order, nested hashrefs
# weakened, used by tns_build() to keep the original order of values,
# entries vanish with their hashes
fieldhash my %KEY_SEEN_ORDER;

##############################################################################
##
##  PARSING
##
##############################################################################

# parses a single descriptor string, e.g. "(DESCRIPTION=...)"
# returns ( $hashtree, undef ) on success, ( undef, $error_message ) on error
sub tns_parse
{
  my $str = __strip_comments( shift );

  my $tree = {};
  my $err  = __parse_items( \$str, $tree );
  return ( undef, $err ) if $err;

  $str =~ /\G\s*/gc;
  return ( undef, "trailing data at offset " . pos( $str ) ) if pos( $str ) < length( $str );
  return ( undef, "empty descriptor" ) unless %$tree;

  return ( $tree, undef );
}

# parses tnsnames.ora content: "ALIAS[, ALIAS2] = (DESCRIPTION=...)" entries
# and "NAME = value" entries (e.g. IFILE), one top-level group per alias
# returns ( { ALIAS => $hashtree, NAME => $value, ... }, undef ) or ( undef, $error_message )
sub tns_parse_names
{
  my $str = __strip_comments( shift );

  my $names = {};
  while( $str =~ /\G\s*([A-Za-z0-9_.\-]+(?:\s*,\s*[A-Za-z0-9_.\-]+)*)\s*=/gc )
    {
    my @aliases = map { uc } split /\s*,\s*/, $1;

    if( $str =~ /\G[^\S\n]*(?:"([^"\n]*)"|([^\s()"=](?:[^\n()"=]*[^\s()"=])?))[^\S\n]*(?=\n|\z)/gc )
      {
      # "NAME = value" entry, repeated names collected into arrayref
      my $val = defined $1 ? $1 : $2;
      for my $alias ( @aliases )
        {
        # same alias given as descriptor before, last one wins as for descriptors
        delete $names->{ $alias } if ref( $names->{ $alias } ) eq 'HASH';
        __add_item( $names, $alias, $val );
        }
      next;
      }

    my $tree = {};
    my $err  = __parse_items( \$str, $tree, 1 );
    return ( undef, "alias $aliases[0]: $err" ) if $err;
    return ( undef, "alias $aliases[0]: empty descriptor" ) unless %$tree;
    $names->{ $_ } = $tree for @aliases;
    }

  $str =~ /\G\s*/gc;
  return ( undef, "unparsed data at offset " . pos( $str ) ) if pos( $str ) < length( $str );

  return ( $names, undef );
}

# removes "# ..." comments up to the end of line, outside of quoted values
sub __strip_comments
{
  my $str = shift;

  $str =~ s/("[^"]*")|#[^\n]*/defined $1 ? $1 : ''/ge;
  pos( $str ) = 0;

  return $str;
}

# parses "(KEY=VALUE)" / "(KEY=(...)(...))" groups into $hr, at most $max if given
# returns undef on success, error message on failure
sub __parse_items
{
  my ( $sr, $hr, $max ) = @_;

  my $order = $KEY_SEEN_ORDER{ $hr } ||= [];
  my $count = 0;
  while( ( ! $max or $count++ < $max ) and $$sr =~ /\G\s*\(/gc )
    {
    return "expected KEY= at offset " . pos( $$sr )
        unless $$sr =~ /\G\s*([A-Za-z0-9_.\-]+)\s*=/gc;
    my $key = uc $1;
    my $val;

    if( $$sr =~ /\G(?=\s*\()/gc )
      {
      # nested groups
      $val = {};
      my $err = __parse_items( $sr, $val );
      return $err if $err;
      }
    elsif( $$sr =~ /\G\s*"([^"]*)"\s*/gc )
      {
      # quoted scalar value
      $val = $1;
      }
    elsif( $$sr =~ /\G\s*([^()"]*?)\s*(?=\))/gc )
      {
      # bare scalar value
      $val = $1;
      }
    else
      {
      return "bad value for $key at offset " . pos( $$sr );
      }

    return "expected ) after $key at offset " . pos( $$sr )
        unless $$sr =~ /\G\s*\)/gc;

    __add_item( $hr, $key, $val );
    push @$order, [ $key, $val ];
    weaken( $order->[ -1 ][ 1 ] ) if ref( $val );
    }

  return undef;
}

# adds a value under key, promoting to arrayref on repeated keys
sub __add_item
{
  my ( $hr, $key, $val ) = @_;

  if( ! exists $hr->{ $key } )
    {
    $hr->{ $key } = $val;
    }
  elsif( ref( $hr->{ $key } ) eq 'ARRAY' )
    {
    push @{ $hr->{ $key } }, $val;
    }
  else
    {
    $hr->{ $key } = [ $hr->{ $key }, $val ];
    }
}

##############################################################################
##
##  BUILDING
##
##############################################################################

# builds descriptor string from hashtree
# $indent: undef -> single line, otherwise number of spaces per nesting level
# returns ( $string, undef ) or ( undef, $error_message )
sub tns_build
{
  my ( $tree, $indent ) = @_;

  return ( undef, "hashref expected" ) unless ref( $tree ) eq 'HASH';
  return ( undef, "empty hashtree" ) unless %$tree;

  my $out = '';
  my $err = __build_items( $tree, \$out, $indent, 0 );
  return ( undef, $err ) if $err;

  $out =~ s/^\n//;
  return ( $out, undef );
}

# builds tnsnames.ora content from { ALIAS => $hashtree, NAME => $value, ... }
# returns ( $string, undef ) or ( undef, $error_message )
sub tns_build_names
{
  my ( $names, $indent ) = @_;

  return ( undef, "hashref expected" ) unless ref( $names ) eq 'HASH';
  $indent = 2 unless defined $indent;

  my $out = '';
  for my $alias ( sort keys %$names )
    {
    my $v = $names->{ $alias };
    if( ! ref( $v ) or ref( $v ) eq 'ARRAY' )
      {
      # "NAME = value" entries
      for my $item ( ref( $v ) ? @$v : ( $v ) )
        {
        my $val = $item;
        return ( undef, "alias $alias: undefined value" ) unless defined $val;
        return ( undef, "alias $alias: hashref or scalar expected" ) if ref( $val );
        return ( undef, "alias $alias: double quote in value is not supported" ) if $val =~ /"/;
        return ( undef, "alias $alias: multiline value is not supported" ) if $val =~ /\n/;
        $val = qq["$val"] if $val eq '' or $val =~ /[()=#]|^\s|\s$/;
        $out .= "$alias = $val\n\n";
        }
      next;
      }
    my ( $str, $err ) = tns_build( $v, $indent );
    return ( undef, "alias $alias: $err" ) if $err;
    $str =~ s/^/  /mg;
    $out .= "$alias =\n$str\n\n";
    }

  return ( $out, undef );
}

# emits all "(KEY=...)" groups of $hr into $$out
sub __build_items
{
  my ( $hr, $out, $indent, $level ) = @_;

  my $pad = defined $indent ? "\n" . ( ' ' x ( $indent * $level ) ) : '';

  for my $item ( __ordered_items( $hr ) )
    {
    my ( $key, $val ) = @$item;
    $$out .= "$pad($key=";
    if( ref( $val ) eq 'HASH' )
      {
      return "empty hashref for $key" unless %$val;
      my $err = __build_items( $val, $out, $indent, $level + 1 );
      return $err if $err;
      $$out .= $pad if defined $indent;
      }
    elsif( ! ref( $val ) )
      {
      return "undefined value for $key" unless defined $val;
      return "double quote in value for $key is not supported" if $val =~ /"/;
      $val = qq["$val"] if $val =~ /[()\s=#]/;
      $$out .= $val;
      }
    else
      {
      return "unsupported value type " . ref( $val ) . " for $key";
      }
    $$out .= ")";
    }

  return undef;
}

# returns ( [ KEY, value ], ... ) in output order: values found at parse
# time go to their parsed position, other values of a parsed key follow the
# previous value of that key (or take its first position), keys not seen at
# parse time (or all, if not parsed) follow in predefined order
sub __ordered_items
{
  my $hr = shift;

  my $slots = $KEY_SEEN_ORDER{ $hr } || [];

  my %first;    # key => first slot of that key
  for my $i ( reverse 0 .. $#$slots )
    {
    $first{ $slots->[ $i ][ 0 ] } = $i;
    }

  my @at;       # slot => [ items placed there ]
  my @rest;     # items of keys not seen at parse time
  for my $key ( __sorted_keys( $hr ) )
    {
    my $v    = $hr->{ $key };
    my @vals = ref( $v ) eq 'ARRAY' ? @$v : ( $v );

    if( ! exists $first{ $key } )
      {
      push @rest, map { [ $key, $_ ] } @vals;
      next;
      }

    my $prev = $first{ $key };
    my %taken;
    for my $val ( @vals )
      {
      for my $i ( $prev .. $#$slots )
        {
        my ( $skey, $sval ) = @{ $slots->[ $i ] };
        next if $skey ne $key or $taken{ $i } or ! defined $sval or ! defined $val;
        next unless ref( $val ) ? ref( $sval ) && $sval == $val : ! ref( $sval ) && $sval eq $val;
        $taken{ $i } = 1;
        $prev = $i;
        last;
        }
      push @{ $at[ $prev ] }, [ $key, $val ];
      }
    }

  return ( map( { @{ $_ || [] } } @at ), @rest );
}

# well-known keys first in canonical order, rest alphabetically
sub __sorted_keys
{
  my $hr = shift;

  return sort { ( $KEY_RANK{ $a } || 999 ) <=> ( $KEY_RANK{ $b } || 999 ) or $a cmp $b } keys %$hr;
}

##############################################################################
##
##  CONNECT STRINGS
##
##############################################################################

my $ALIAS_RE     = qr/[A-Za-z0-9_.\-]+/;
my $EZCONNECT_RE = qr{
                     ^(?://)?
                     (?: \[ ( [^\]\s/\@]+ ) \] | ( [^:/\[\]\s\@]+ ) )  # host or [ipv6]
                     (?: : ( \d+ ) )?                                  # port
                     (?: / ( [^:/\s\@]+ )                              # service name
                         (?: : ( [A-Za-z]+ ) )?                        # server
                         (?: / ( [^/\s\@]+ ) )?                        # instance name
                     )?$
                     }x;

# parses DBI/sqlplus style connect string: user/pass@target, user@target,
# user/pass, /@target, target is a descriptor, an alias or EZConnect
# returns ( { USER, PASS, TNS | ALIAS | EZCONNECT }, undef ) or ( undef, $error_message )
sub tns_parse_connect
{
  my $str = shift;

  return ( undef, "empty connect string" ) unless defined $str and $str =~ /\S/;
  $str =~ s/\s+$//;
  pos( $str ) = 0;
  $str =~ /\G\s*/gc;

  my $conn = {};

  $conn->{ USER } = defined $1 ? $1 : $2 if $str =~ /\G(?:"([^"]*)"|([^\/\@"\s]+))/gc;

  if( $str =~ /\G\//gc )
    {
    if( $str =~ /\G(?:"([^"]*)"|([^\@"\s]+))/gc )
      {
      return ( undef, "password without user" ) unless exists $conn->{ USER };
      $conn->{ PASS } = defined $1 ? $1 : $2;
      }
    elsif( exists $conn->{ USER } )
      {
      return ( undef, "missing password after / at offset " . pos( $str ) );
      }
    }
  elsif( ! exists $conn->{ USER } )
    {
    return ( undef, "expected user or / at offset " . pos( $str ) );
    }

  if( $str =~ /\G\@\s*/gc )
    {
    my $target = substr( $str, pos( $str ) );
    return ( undef, "missing connect target after \@" ) if $target eq '';

    if( $target =~ /^\(/ )
      {
      my ( $tree, $err ) = tns_parse( $target );
      return ( undef, "descriptor: $err" ) if $err;
      $conn->{ TNS } = $tree;
      }
    elsif( $target =~ /^$ALIAS_RE$/ )
      {
      $conn->{ ALIAS } = $target;
      }
    elsif( my ( $host6, $host, $port, $service, $server, $instance ) = $target =~ $EZCONNECT_RE )
      {
      my %ez = ( HOST => defined $host6 ? $host6 : $host );
      $ez{ PORT          } = $port     if defined $port;
      $ez{ SERVICE_NAME  } = $service  if defined $service;
      $ez{ SERVER        } = $server   if defined $server;
      $ez{ INSTANCE_NAME } = $instance if defined $instance;
      $conn->{ EZCONNECT } = \%ez;
      }
    else
      {
      return ( undef, "bad connect target: $target" );
      }
    }
  elsif( pos( $str ) < length( $str ) )
    {
    return ( undef, "trailing data at offset " . pos( $str ) );
    }

  return ( $conn, undef );
}

# builds connect string from { USER, PASS, TNS | ALIAS | EZCONNECT }
# $indent is passed to tns_build() for TNS, default single line
# returns ( $string, undef ) or ( undef, $error_message )
sub tns_build_connect
{
  my ( $conn, $indent ) = @_;

  return ( undef, "hashref expected" ) unless ref( $conn ) eq 'HASH';

  my %known = map { $_ => 1 } qw( USER PASS TNS ALIAS EZCONNECT );
  my @bad   = sort grep { ! $known{ $_ } } keys %$conn;
  return ( undef, "unknown key @bad" ) if @bad;

  my @targets = grep { exists $conn->{ $_ } } qw( TNS ALIAS EZCONNECT );
  return ( undef, "only one of @targets expected" ) if @targets > 1;

  my $out;
  if( exists $conn->{ USER } )
    {
    my ( $user, $err ) = __connect_quote( USER => $conn->{ USER }, qr/[\/\@\s]/ );
    return ( undef, $err ) if $err;
    $out = $user;
    if( exists $conn->{ PASS } )
      {
      my ( $pass, $err ) = __connect_quote( PASS => $conn->{ PASS }, qr/[\@\s]/ );
      return ( undef, $err ) if $err;
      $out .= "/$pass";
      }
    }
  else
    {
    return ( undef, "PASS without USER" ) if exists $conn->{ PASS };
    $out = '/';
    }

  return ( $out, undef ) unless @targets;

  my $target;
  if( exists $conn->{ TNS } )
    {
    my $err;
    ( $target, $err ) = tns_build( $conn->{ TNS }, $indent );
    return ( undef, "TNS: $err" ) if $err;
    }
  elsif( exists $conn->{ ALIAS } )
    {
    $target = $conn->{ ALIAS };
    return ( undef, "bad ALIAS" ) unless defined $target and ! ref( $target ) and $target =~ /^$ALIAS_RE$/;
    }
  else
    {
    my $err;
    ( $target, $err ) = __build_ezconnect( $conn->{ EZCONNECT } );
    return ( undef, "EZCONNECT: $err" ) if $err;
    }

  return ( "$out\@$target", undef );
}

# replaces USER and PASS in connect string with $mask (default "***"), e.g. for logging
# returns masked string, never fails: unparsable strings without quotes keep only the part after the last @
sub tns_mask_connect
{
  my $str  = shift;
  my $mask = @_ ? shift : '***';

  return $str unless defined $str and $str =~ /\S/;

  my ( $conn, $err ) = tns_parse_connect( $str );
  if( ! $err )
    {
    $conn->{ USER } = $mask if exists $conn->{ USER };
    $conn->{ PASS } = $mask if exists $conn->{ PASS };
    my $out;
    ( $out, $err ) = tns_build_connect( $conn );
    return $out unless $err;
    }

  # quoted user/pass may contain @, so nothing can be kept safely
  return $str !~ /"/ && $str =~ /\@([^\@]*)$/ ? "$mask\@$1" : $mask;
}

# quotes user or password if empty or matching $re
sub __connect_quote
{
  my ( $name, $val, $re ) = @_;

  return ( undef, "undefined $name" ) unless defined $val;
  return ( undef, "unsupported $name type " . ref( $val ) ) if ref( $val );
  return ( undef, "double quote in $name is not supported" ) if $val =~ /"/;
  $val = qq["$val"] if $val eq '' or $val =~ $re;

  return ( $val, undef );
}

# builds [//]host[:port][/service[:server][/instance]]
sub __build_ezconnect
{
  my $ez = shift;

  return ( undef, "hashref expected" ) unless ref( $ez ) eq 'HASH';

  my %check = (
              HOST          => qr/^(?:[^:\/\[\]\s\@]+|[^\[\]\s\/\@]*:[^\[\]\s\/\@]*)$/,
              PORT          => qr/^\d+$/,
              SERVICE_NAME  => qr/^[^:\/\s\@]+$/,
              SERVER        => qr/^[A-Za-z]+$/,
              INSTANCE_NAME => qr/^[^\/\s\@]+$/,
              );
  for my $key ( sort keys %$ez )
    {
    return ( undef, "unknown key $key" ) unless $check{ $key };
    my $val = $ez->{ $key };
    return ( undef, "bad $key" ) unless defined $val and ! ref( $val ) and $val =~ $check{ $key };
    }
  return ( undef, "missing HOST" ) unless exists $ez->{ HOST };
  return ( undef, "SERVER and INSTANCE_NAME need SERVICE_NAME" )
      if ! exists $ez->{ SERVICE_NAME } and ( exists $ez->{ SERVER } or exists $ez->{ INSTANCE_NAME } );

  my $out = $ez->{ HOST } =~ /:/ ? "[$ez->{ HOST }]" : $ez->{ HOST };
  $out .= ":$ez->{ PORT }" if exists $ez->{ PORT };
  if( exists $ez->{ SERVICE_NAME } )
    {
    $out .= "/$ez->{ SERVICE_NAME }";
    $out .= ":$ez->{ SERVER }"        if exists $ez->{ SERVER };
    $out .= "/$ez->{ INSTANCE_NAME }" if exists $ez->{ INSTANCE_NAME };
    }
  # a lone host would be read back as alias
  $out = "//$out" if $out =~ /^$ALIAS_RE$/;

  return ( $out, undef );
}

1;

__END__

=head1 NAME

Oracle::TNS - parse and build Oracle TNS descriptors and tnsnames.ora strings

=head1 SYNOPSIS

  use Oracle::TNS;

  my ( $tree, $err ) = tns_parse( '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=db1)(PORT=1521))'
                                 .'(ADDRESS=(PROTOCOL=TCP)(HOST=db2)(PORT=1521))'
                                 .'(CONNECT_DATA=(SERVICE_NAME=ORCLPDB1)))' );
  die $err if $err;

  $tree->{ DESCRIPTION }{ CONNECT_DATA }{ SERVER } = 'DEDICATED';
  push @{ $tree->{ DESCRIPTION }{ ADDRESS } }, { PROTOCOL => 'TCP', HOST => 'db3', PORT => 1521 };

  my ( $str, $err2 ) = tns_build( $tree, 2 );   # pretty, 2-space indent
  my ( $one, $err3 ) = tns_build( $tree );      # single line

  # tnsnames.ora round trip
  my ( $names, $e ) = tns_parse_names( $tnsnames_file_content );
  my ( $text,  $f ) = tns_build_names( $names );

  # DBI-style connect strings
  my ( $conn, $g ) = tns_parse_connect( 'scott/tiger@(DESCRIPTION=(ADDRESS=(HOST=db1)(PORT=1521))'
                                       .'(CONNECT_DATA=(SID=ORCL)))' );
  # { USER => 'scott', PASS => 'tiger', TNS => { DESCRIPTION => { ... } } }
  my ( $cstr, $h ) = tns_build_connect( { USER => 'scott', PASS => 'tiger',
                                          EZCONNECT => { HOST => 'db1', PORT => 1521, SERVICE_NAME => 'ORCL' } } );
  # scott/tiger@db1:1521/ORCL

=head1 DESCRIPTION

Oracle::TNS parses Oracle TNS connect descriptors and tnsnames.ora content
into a hashtree and builds descriptor strings back from a hashtree.

  (DESCRIPTION=(ADDRESS=(HOST=a)(PORT=1521))(ADDRESS=(HOST=b)(PORT=1521))
               (CONNECT_DATA=(SERVICE_NAME=X)))

becomes

  {
    DESCRIPTION => {
      ADDRESS => [ { HOST => 'a', PORT => 1521 },
                   { HOST => 'b', PORT => 1521 } ],
      CONNECT_DATA => { SERVICE_NAME => 'X' },
    }
  }

Repeated keys at the same level are collected into an array reference.
Keys are uppercased on parse. A single-element value may be given either
as a scalar/hashref or as a one-element arrayref when building.
Comments (from # to the end of the line, outside of quoted values) are
ignored on parse. Values cannot contain double quotes; there is no escaping.

=head1 FUNCTIONS

All functions are exported by default and return a two-element list: the
result and undef on success, or undef and an error message on failure.

=head2 tns_parse( $string )

Parses a single descriptor string, e.g. "(DESCRIPTION=...)", and returns
its hashtree. An empty descriptor is an error.

=head2 tns_parse_names( $string )

Parses tnsnames.ora content, "ALIAS[, ALIAS2] = (DESCRIPTION=...)" entries,
and returns { ALIAS => $hashtree, ... }. Aliases are uppercased. Each alias
takes exactly one top-level group; groups following it without a new alias
are an error. A repeated alias replaces the earlier one.

Entries with a single-line value instead of a group, e.g.
"IFILE = /etc/oracle/more.ora", are returned as plain scalars,
{ IFILE => '/etc/oracle/more.ora' }, repeated ones as an array reference.

=head2 tns_build( $hashtree, $indent )

Builds a descriptor string from a hashtree. If $indent is undef the
result is a single line, otherwise it is the number of spaces per nesting
level.

Trees returned by the parse functions keep the parsed order, so a parsed
descriptor is built back in its original order, e.g. ADDRESS and
ADDRESS_LIST in a SOURCE_ROUTE. Values added later are placed after the
previous value of the same key (or at the first position of that key), and
the order inside an array reference is kept. Keys added later, and all keys
of hashes not created by parsing (including copies of parsed ones), are
emitted in predefined order: well-known keys first in canonical order, the
rest alphabetically. Values containing parentheses, whitespace, "=" or "#" are
double-quoted. An empty hashtree or an empty hashref value is an error, so
is a value containing a double quote.

=head2 tns_build_names( $names, $indent )

Builds tnsnames.ora content from { ALIAS => $hashtree, ... }, aliases
sorted. $indent defaults to 2. Scalar values (or array references of
scalars) are written as "NAME = value" entries, as returned by
tns_parse_names(). Such values are double-quoted if empty, if they contain
parentheses, "=" or "#", or if they start or end with whitespace. Multiline
values are an error.

=head2 tns_parse_connect( $string )

Parses a DBI or sqlplus style connect string and returns a hashref with
USER and PASS (when given) and at most one connect target:

  user/pass@(DESCRIPTION=...)     { USER, PASS, TNS => $hashtree }
  user/pass@ALIAS                 { USER, PASS, ALIAS => 'ALIAS' }
  user/pass@host:1521/service     { USER, PASS, EZCONNECT => { HOST, PORT, SERVICE_NAME } }
  user@ALIAS                      { USER, ALIAS }
  user/pass                       { USER, PASS }
  /@ALIAS                         { ALIAS }, external authentication

USER and PASS may be double-quoted, e.g. user/"p@ss w"@ALIAS, the quotes are
removed. An unquoted password cannot contain "@" or whitespace.

A target starting with "(" is parsed with tns_parse(). A target made only of
letters, digits, "_", "." and "-" is an alias (case kept, note that
tns_parse_names() uppercases aliases). Anything else is EZConnect:

  [//]host[:port][/service_name[:server][/instance_name]]

returned as EZCONNECT hashref with keys HOST, PORT, SERVICE_NAME, SERVER and
INSTANCE_NAME, only the ones given. IPv6 hosts are written in brackets,
"[::1]:1521/svc", and returned without them. A host alone is read as an
alias, use "//host" for EZConnect.

=head2 tns_build_connect( $conn, $indent )

Builds a connect string from a hashref as returned by tns_parse_connect().
USER and PASS are double-quoted if empty or containing whitespace or "@"
(USER also "/"), double quotes in them are an error. Without USER the
string starts with "/". $indent is passed to tns_build() for TNS, by
default the descriptor is a single line. EZConnect with HOST only is
written as "//host". Unknown keys, more than one target, PASS without
USER and SERVER or INSTANCE_NAME without SERVICE_NAME are errors.

=head2 tns_mask_connect( $string, $mask )

Returns the connect string with USER and PASS replaced by $mask (default
"***"), for logging. The target is rebuilt with tns_build_connect(), so a
descriptor comes back on a single line:

  scott/tiger@(DESCRIPTION=...)   ***/***@(DESCRIPTION=...)
  scott@PROD                      ***@PROD
  scott                           ***
  /@PROD                          /@PROD

It never fails and returns a plain string, not a ( $string, $error ) pair.
If $string cannot be parsed, only the part after the last "@" is kept, and
only if $string has no double quote, otherwise just $mask is returned.
Undefined or blank $string is returned as is.

=head1 KNOWN ISSUES

Single-quoted values, values containing a backslash or a single quote and
Easy Connect Plus syntax (parameters after "?", several hosts, "tcps://")
are not fully supported, some of them are changed without an error. See
the KNOWN_ISSUES file for the full list, and for the author tests in xt/
which check real-world samples and show these issues.

=head1 LICENSE

Distributed under the GNU General Public License, version 2, see COPYING
file for details.

=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"
        <cade@noxrun.com>
  http://cade.noxrun.com
  https://github.com/cade-vs

=cut
