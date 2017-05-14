#!/usr/bin/perl
#$Id: pssql.pm 4848 2014-08-07 21:22:41Z pro $ $URL: svn://svn.setun.net/search/trunk/lib/pssql.pm $

=copyright
PRO-search sql library
Copyright (C) 2003-2011 Oleg Alexeenkov http://pro.setun.net/search/ proler@gmail.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

=c
todo:

pg
2009/10/06-13:53:11 dev HandleError DBD::Pg::db do failed: no connection to the server
 DBI::db=HASH(0x1229568)  7 no connection to the server



2009/06/02-19:37:35 dev HandleError DBD::Pg::st execute failed: FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
        This probably means the server terminated abnormally
        before or while processing the request.
 DBI::st=HASH(0x271b688)  7 FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
        This probably means the server terminated abnormally
        before or while processing the request.

2009/06/02-19:37:35 dev err_parse st0 ret1  wdi=  di=  fa= 1 er=  300 1000 fatal 57P01
2009/06/02-19:37:36 dev HandleError DBD::Pg::st execute failed: no connection to the server
 DBI::st=HASH(0x271b718)  7 no connection to the server

2009/06/02-19:37:39 dev HandleError DBD::Pg::db do failed: no connection to the server
 DBI::db=HASH(0x1209d38)  7 no connection to the server



$work

=cut

#our ( %config);
package    #no cpan
  pssql;
use strict;
use utf8;
no warnings qw(uninitialized);
no if $] >= 5.017011, warnings => 'experimental::smartmatch';
our $VERSION = ( split( ' ', '$Revision: 4848 $' ) )[1];
#use locale;
use DBI;
use Time::HiRes qw(time);
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = $Data::Dumper::Terse = 1;
our ( %work, );      #%stat %static, $param,
our (%config);
#local *config = *main::config;
#*pssql::config = *main::config;
#*pssql::work = *main::work;
#*pssql::stat = *main::stat;
*config = *main::config;
*work   = *main::work;
*stat   = *main::stat;
use lib::abs './';
use psmisc;
#use psconn;
#our ( %config, %work, %stat, %static, $param, );
use base 'psconn';
our $AUTOLOAD;
#our $VERSION = ( split( ' ', '$Revision: 4848 $' ) )[1];
my ( $tq, $rq, $vq );
my ( $roworder, $tableorder, );
our ( %row, %default );
$config{ 'log_' . $_ } = 0 for grep { !exists $config{ 'log_' . $_ } } qw(trace dmpbef);
#warn "SQL UESEEDDD" ;
sub row {
  my $row = shift @_;
  return {
    %{ ( defined $config{'row'} ? $config{'row'}{$row} : undef ) || $row{$row} || {} }, %{ $config{'row_all'} || {} },
    'order' => --$roworder,
    @_
  };
}

sub table {
  my $table = shift @_;
  return @_;
  #{
  #%{ ( defined $config{'row'} ? $config{'row'}{$row} : undef ) || $row{$row} || {} }, %{ $config{'row_all'} || {} },
  #'order' => --$tableorder,
  #@_
  #};
}
#}
BEGIN {
  %row = (
    'time' => {
      'type'      => 'INT',
      'unsigned'  => 1,
      'default'   => 0,
      'date_time' => 1,       #todo
    },
    'uint'   => { 'type' => 'INTEGER',  'unsigned' => 1,  'default' => 0, },
    'uint16' => { 'type' => 'SMALLINT', 'unsigned' => 1,  'default' => 0, },
    'uint64' => { 'type' => 'BIGINT',   'unsigned' => 1,  'default' => 0, },
    'text'   => { 'type' => 'VARCHAR',  'index'    => 10, 'default' => '', },
    'stem'   => {
      'type' => 'VARCHAR',
      #!      'length'   => 128,
      'fulltext'   => 'stemi',
      'default'    => '',
      'not null'   => 1,
      'stem_index' => 1,
    },
  );
  $row{'id'}      ||= row( 'uint', 'auto_increment' => 1,             'primary'          => 1 ),
    $row{'added'} ||= row( 'time', 'default_insert' => int( time() ), 'no_insert_update' => 1, );
  $row{'year'} ||= row('uint16');
  $row{'size'} ||= row('uint64');
  %default = (
    'null' => { 'do' => sub { }, 'query' => sub { wantarray ? () : [] }, 'line' => sub { {} }, },
    'sqlite' => {
      #'dbi'          => 'SQLite2',
      'dbi'                 => 'SQLite',
      'params'              => [qw(dbname)],
      'dbname'              => $config{'root_path'} . 'sqlite.db',
      'no_update_limit'     => 1,                                    #pg sux
      'table quote'         => '"',
      'row quote'           => '"',
      'value quote'         => "'",
      'IF NOT EXISTS'       => 'IF NOT EXISTS',
      'index_IF NOT EXISTS' => 'IF NOT EXISTS',
      'IF EXISTS'           => 'IF EXISTS',
      'REPLACE'             => 'REPLACE',
      'AUTO_INCREMENT'      => 'AUTOINCREMENT',
      'ANALYZE'             => 'ANALYZE',
      'err_ignore'          => [qw( 1 )],
      'error_type'          => sub {                                 #TODO!!!
        my $self = shift;
        my ( $err, $errstr ) = @_;
        #$self->log('dev',"ERRDETECT($err, $errstr)");
        return 'install' if $errstr =~ /no such table:|unable to open database file/i;
        return 'syntax'  if $errstr =~ /syntax|unrecognized token/i or $errstr =~ /misuse of aggregate/;
        return 'retry'   if $errstr =~ /database is locked/i;
        return 'upgrade' if $errstr =~ /no such column/i;
        #return 'connection' if $errstr =~ /connect/i;
        return undef;
      },
      'pragma' => {
        map {
          $_ => $_
          } 'synchronous = OFF',
        'auto_vacuum = FULL'
      },
      'on_connect' => sub {
        my $self = shift;
        $self->do("PRAGMA $_;") for keys %{ $self->{'pragma'} || {} };
        #$self->log( 'sql', 'on_connect!' );
      },
      'no_dbirows' => 1,
    },
    'pg' => {
      'dbi'  => 'Pg',
      'user' => ( $^O =~ /^(?:(ms)?(dos|win(32|nt)?)|linux)/i ? 'postgres' : 'pgsql' ),
      #'port' => 5432,
      'IF EXISTS'     => 'IF EXISTS',
      'CREATE TABLE'  => 'CREATE TABLE',
      'OFFSET'        => 'OFFSET',
      'IF NOT EXISTS' => 'IF NOT EXISTS',    #9.2 ok
      #'unsigned'     => 0,
      'UNSIGNED'         => '',                         #pg sux
      'no_delete_limit'  => 1,                          #pg sux
      'table quote'      => '"',
      'row quote'        => '"',
      'value quote'      => "'",
      'index_name_table' => 1,
      'REPLACE'          => 'INSERT',
      'EXPLAIN'          => 'EXPLAIN ANALYZE',
      'CASCADE'          => 'CASCADE',
      'SET NAMES'        => 'SET client_encoding = ',
      'fulltext_config'  => 'pg_catalog.simple',
      'params'           => [
        qw(host hostaddr port options dbname database db user username password service sslmode), qw(
          )
      ],
      'err_ignore' => [qw( 1 7)],
      'error_type' => sub {
        my $self = shift, my ( $err, $errstr ) = @_;
        #$self->log('dev',"ERRDETECT($err, [$errstr])");
        return 'connection' if $errstr eq $err; # 7, [7] # wtf
        return 'install_db' if $errstr =~ /FATAL:\s*database ".*?" does not exist/i;
        return 'connection' if $errstr =~ /FATAL:\s*terminating connection/i; #7
        return 'fatal'      if $errstr =~ /fatal/i;
        return 'syntax'     if $errstr =~ /syntax/i;
        return 'connection' if $errstr =~ /ERROR:\s*prepared statement ".*?" does not exist/i;
        return 'connection' if $errstr =~ /connect|Unknown message type: ''/i and $errstr !~ /(?:column|relation) "/; #"mc
        return 'install'    if $errstr =~ /ERROR:\s*(?:relation \S+ does not exist)/i;
        #return 'retry'    if $errstr =~       /ERROR:\s*cannot drop the currently open database/i;
        return 'retry' if $errstr =~ /ERROR:  database ".*?" is being accessed by other users/i;
        return 'ignore'
          if $errstr =~
/(?:duplicate key violates unique constraint)|(?:duplicate key value violates unique constraint)|(?:ERROR:\s*(?:database ".*?" already exists)|(?:relation ".*?" already exists)|(?:invalid byte sequence for encoding)|(?:function .*? does not exist)|(?:null value in column .*? violates not-null constraint)|(?:Can't create database '.*?'; database exists))/i;
        return undef;
      },
      'set'        => { 'lc_messages' => 'C' },
      'on_connect' => sub {
        my $self = shift;
        $self->{dbh}->{pg_utf8_strings} = $self->{dbh}->{pg_enable_utf8} = 1;
        $self->set_names();
        $self->do("select set_curcfg('default');") if $self->{'use_fulltext'} and $self->{'old_fulltext'};
        $self->do("SET $_=$vq$self->{'set'}{$_}$vq;") for grep {!$self->{'no_set_'.$_}} sort keys %{ $self->{'set'} || {} };
      },
      'no_dbirows'         => 1,
      'cp1251'             => 'win1251',
      'fulltext_word_glue' => '&',
    },
    'sphinx' => {
      'dbi'                     => 'mysql',
      'user'                    => 'root',
      'port'                    => 9306,
      'params'                  => [qw(host port )],                                                        # perldoc DBD::mysql
      'sphinx'                  => 1,
      'value quote'             => "'",
      'no_dbirows'              => 1,
      'no_column_prepend_table' => 1,
      'no_join'                 => 1,
      'OPTION'                  => 'OPTION',
      'option'                  => { 'max_query_time' => 20000, 'cutoff' => 1000, 'ranker' => 'sph04', },
    },
    'mysql5' => {
      'dbi'               => 'mysql',
      'user'              => 'root',
      'use_drh'           => 1,
      'mysql_enable_utf8' => 1,
      'varchar_max'       => 65530,
      'unique_max'        => 1000,
      'primary_max'       => 999,
      'fulltext_max'      => 1000,
      'key_length'        => 1000, # maybe 3072 for mariadb
      'err_connection'    => [qw( 1 1040 1053 1129 1213 1226 2002 2003 2006 2013 )],
      'err_fatal'         => [qw( 1016 1046 1251 )],                                   # 1045,
      'err_syntax'  => [qw( 1060 1064 1065 1067 1071 1096 1103 1118 1148 1191 1364 1366 1406 1439)], #1054 #maybe all 1045..1075
      'err_repair'  => [qw( 126 130 144 145 1034 1062 1194 1582 )],
      'err_retry'   => [qw( 1317 )],
      'err_install' => [qw( 1146)], # 1017 repair?
      'err_install_db' => [qw( 1049 )],
      'err_upgrade'    => [qw( 1054 )],
      'err_ignore '    => [qw( 2 1264 1061 )],
      'error_type'     => sub {
        my $self = shift, my ( $err, $errstr ) = @_;
        #$self->log('dev',"MYERRDETECT($err, $errstr)");
        for my $errtype (qw(connection retry syntax fatal repair install install_db upgrade)) {
          #$self->log('dev',"ERRDETECTED($err, $errstr) = $errtype"),
          return $errtype if grep { $err eq $_ } @{ $self->{ 'err_' . $errtype } };
        }
        return undef;
      },
      'table quote' => "`",
      'row quote'   => "`",
      'value quote' => "'",
      #'index quote'		=> "`",
      #'unsigned'                => 1,
      'quote_slash'             => 1,
      'index in create table'   => 1,
      'utf-8'                   => 'utf8',
      'koi8-r'                  => 'koi8r',
      'table options'           => 'ENGINE = MYISAM DELAY_KEY_WRITE=1',
      'IF NOT EXISTS'           => 'IF NOT EXISTS',
      'IF EXISTS'               => 'IF EXISTS',
      'IGNORE'                  => 'IGNORE',
      'REPLACE'                 => 'REPLACE',
      'INSERT'                  => 'INSERT',
      'HIGH_PRIORITY'           => 'HIGH_PRIORITY',
      'SET NAMES'               => 'SET NAMES',
      'DEFAULT CHARACTER SET'   => 'DEFAULT CHARACTER SET',
      'USE_FRM'                 => 'USE_FRM',
      'EXTENDED'                => 'EXTENDED',
      'QUICK'                   => 'QUICK',
      'ON DUPLICATE KEY UPDATE' => 'ON DUPLICATE KEY UPDATE',
      'UNSIGNED'                => 'UNSIGNED',
      'UNLOCK TABLES'           => 'UNLOCK TABLES',
      'LOCK TABLES'             => 'LOCK TABLES',
      'OPTIMIZE'                => 'OPTIMIZE TABLE',
      'ANALYZE'                 => 'ANALYZE TABLE',
      'CHECK'                   => 'CHECK TABLE',
      'FLUSH'                   => 'FLUSH TABLE',
      'LOW_PRIORITY'            => 'LOW_PRIORITY',
      'on_connect'              => sub {
        my $self = shift;
        $self->{'db_id'} = $self->{'dbh'}->{'mysql_thread_id'};
        $self->set_names() if !( $ENV{'MOD_PERL'} || $ENV{'FCGI_ROLE'} );
      },
      'on_user' => sub {
        my $self = shift;
        $self->set_names() if $ENV{'MOD_PERL'} || $ENV{'FCGI_ROLE'};
      },
      'params' => [
        qw(host port database mysql_client_found_rows mysql_compression mysql_connect_timeout mysql_read_default_file mysql_read_default_group mysql_socket
          mysql_ssl mysql_ssl_client_key mysql_ssl_client_cert mysql_ssl_ca_file mysql_ssl_ca_path mysql_ssl_cipher
          mysql_local_infile mysql_embedded_options mysql_embedded_groups mysql_enable_utf8)
      ],    # perldoc DBD::mysql
      'insert_by' => 1000, ( !$ENV{'SERVER_PORT'} ? ( 'auto_check' => 1 ) : () ), 'unique name' => 1,    # test it
      'match' => sub {
        my $self = shift;
        my ( $param, $param_num, $table, $search_str, $search_str_stem ) = @_;
        my ( $ask, $glue );
        local %_;
        map { $_{ $self->{'table'}{$table}{$_}{'fulltext'} } = 1 }
          grep { $self->{'table'}{$table}{$_}{'fulltext'} or ( $self->{'sphinx'} and $self->{'table'}{$table}{$_}{'sphinx'} ) }
          keys %{ $self->{'table'}{$table} };
        for my $index ( keys %_ ) {
          if (
            $_ = join( ' , ',
              map  { "$rq$_$rq" }
              sort { $self->{'table'}{$table}{$b}{'order'} <=> $self->{'table'}{$table}{$a}{'order'} }
              grep { $self->{'table'}{$table}{$_}{'fulltext'} eq $index } keys %{ $self->{'table'}{$table} } )
            )
          {
            my $stem =
              grep { $self->{'table'}{$table}{$_}{'fulltext'} eq $index and $self->{'table'}{$table}{$_}{'stem_index'} }
              keys %{ $self->{'table'}{$table} };
            #TODO: maybe some message for user ?
            $self->{'accurate'} = 1, next,
              if ($stem
              and length $search_str_stem
              and $self->{'auto_accurate_on_slow'}
              and $search_str_stem =~ /\b\w{$self->{'auto_accurate_on_slow'}}\b/ );
            my $double =
              grep { $self->{'table'}{$table}{$_}{'fulltext'} and $self->{'table'}{$table}{$_}{'stem'} }
              keys %{ $self->{'table'}{$table} };
            next if $double and ( $self->{'accurate'} xor !$stem );
            my $match;
            if ( $self->{'sphinx'} ) { $match = ' MATCH (' . $self->squotes( $stem ? $search_str_stem : $search_str ) . ')' }
            else {
              $match = ' MATCH (' . $_ . ')' . ' AGAINST (' . $self->squotes( $stem ? $search_str_stem : $search_str ) . (
                ( !$self->{'no_boolean'} and $param->{ 'adv_query' . $param_num } eq 'on' )
                ? 'IN BOOLEAN MODE'
                  #: ( $self->{'allow_query_expansion'} ? 'WITH QUERY EXPANSION' : '' )
                : $self->{'fulltext_extra'}
              ) . ') ';
            }
            $ask .= " $glue " . $match;
            $work{'what_relevance'}{$table} ||= $match . " AS $rq" . "relev$rq"
              if $self->{'select_relevance'}
                or $self->{'table_param'}{$table}{'select_relevance'};
          }
          $glue = $self->{'fulltext_glue'};
        }
        return $ask;
      },
    },
  );
}

sub new {
  my $self = bless( {}, shift );
  $self->init(@_);
  $self->psconn::init(@_);
  return $self;
}

sub cmd {
  my $self = shift;
  my $cmd  = shift;
  $self->log( 'trace', "pssql::$cmd [$self->{'dbh'}]", @_ ) if $cmd ne 'log';
  $self->{'handler_bef'}{$cmd}->( $self, \@_ ) if $self->{'handler_bef'}{$cmd};
  my @ret =
    ref( $self->{$cmd} ) eq 'CODE'
    ? ( wantarray ? ( $self->{$cmd}->( $self, @_ ) ) : scalar $self->{$cmd}->( $self, @_ ) )
    : (
    exists $self->{$cmd}
    ? ( ( defined( $_[0] ) ? ( $self->{$cmd} = $_[0] ) : ( $self->{$cmd} ) ) )
    : ((!ref $self->{'dbh'}) ? ()
      : $self->{'dbh'}->can($cmd) ? $self->{'dbh'}->$cmd(@_)
      : exists $self->{'dbh'}{$cmd} ? ( ( defined( $_[0] ) ? ( $self->{'dbh'}->{$cmd} = $_[0] ) : ( $self->{'dbh'}->{$cmd} ) ) )
      :                               undef )
    );
  $self->{'handler'}{$cmd}->( $self, \@_, \@ret ) if $self->{'handler'}{$cmd};
  return wantarray ? @ret : $ret[0];
}

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self) or return;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;    # strip fully-qualified portion
  #$self->log('dev', 'autoload', $name, $AUTOLOAD, @_);
  return $self->cmd( $name, @_ );
}

sub _disconnect {
  my $self = shift;
  $self->log( 'trace', 'pssql::_diconnect', "dbh=$self->{'dbh'}" );
  $self->flush_insert() unless $self->{'in_disconnect'};
  $self->{'in_disconnect'} = 1;
  return 0;
}

sub _dropconnect {
  my $self = shift;
  $self->log( 'trace', 'pssql::_dropconnect' );
  $self->{'in_disconnect'} = 1;
  $self->{'sth'}->finish() if $self->{'sth'};
  $self->{'dbh'}->disconnect(), $self->{'dbh'} = undef if $self->{'dbh'} and keys %{ $self->{'dbh'} };
  delete $self->{'in_disconnect'};
  return 0;
}

sub _check {
  my $self = shift;
  return 1 if !$self->{'dbh'} or !$self->{'connected'};    #or !keys %{$self->{'dbh'}};
  return !$self->{'dbh'}->ping();
}

sub init {
  my $self = shift;
  #warn Dumper $self, \@_;
  local %_ = (
    'log' => sub (@) {
      shift;
      psmisc::printlog(@_);
    },
    'trace'=>sub(@) {
      shift;
      psmisc::trace(@_);
    },
    'driver'   => 'mysql5',
    'host'     => ( $^O eq 'cygwin' ? '127.0.0.1' : 'localhost' ),
    'database' => 'pssqldef',
    #'connect_tries'     => 100,
    'error_sleep'       => ( $ENV{'SERVER_PORT'} ? 1 : 3600 ),
    'error_tries'       => ( $ENV{'SERVER_PORT'} ? 1 : 1000 ),
    'error_chain_tries' => ( $ENV{'SERVER_PORT'} ? 1 : 100 ),
    #($ENV{'SERVER_PORT'} ? ('connect_tries'=>1) : ()),
    #'reconnect_tries' => 10,            #look old
    'connect_tries' => ( $ENV{'SERVER_PORT'} ? 1 : 0 ),
    'connect_chain_tries' => 0,
    'connect_auto'        => 0,
    'connect_params'      => {
      'RaiseError'  => 0,
      'AutoCommit'  => 1,
      'PrintError'  => 0,
      'PrintWarn'   => 0,
      'HandleError' => sub {
        $self->trace( 'dev', 'HandleError', @_, $DBI::err, $DBI::errstr );
        $self->err(join ', ', grep {$_} $DBI::err, $DBI::errstr);
        push @{$self->{error_log}||=[]},$self->err() if $self->{'error_collect'};
	#psmisc::caller_trace(15)
      },
    },
    #'connect_check' => 1, #check connection on every keep()
    ( $ENV{'SERVER_PORT'} ? () : ( 'auto_repair' => 10 ) ),    # or number 10-30
    'auto_repair_selected' => 0,                                             # repair all tables
    'auto_install' => 1, 'auto_install_db' => 1, 'err_retry_unknown' => 0,
    #'reconnect_sleep' => 3600,    #maximum sleep on connect error
    'codepage' => 'utf-8',
    #'cp_in'             => 'utf-8',
    'index_postfix' => '_i', 'limit_max' => 1000, 'limit_default' => 100,
    #'limit' => 100,
    'page_min' => 1, 'page_default' => 1,
    #'varchar_max'    => 255,
    'varchar_max'    => 65535,
    'row_max'        => 65535,
    'primary_max'    => 65535,
    'fulltext_max'   => 65535,
    'AUTO_INCREMENT' => 'AUTO_INCREMENT',
    'EXPLAIN'        => 'EXPLAIN',
    'statable'       => { 'queries' => 1, 'connect_tried' => 1, 'connects' => 1, 'inserts' => 1 },
    'statable_time' => { 'queries_time' => 1, 'queries_avg' => 1, },
    'param_trans_int' => { 'on_page' => 'limit', 'show_from' => 'limit_offset', 'page' => 'page', 'accurate' => 'accurate' },
    #'param_trans'    => { 'codepage'=>'cp_out' ,},
    'connect_cached'     => 1,
    'char_type'          => 'VARCHAR',
    'true'               => 1,
    'fulltext_glue'      => 'OR',
    'retry_vars'         => [qw(auto_repair connect_tries connect_chain_tries error_sleep error_tries auto_check)],
    'err'                => 0,
    'insert_cached_time' => 60,
    'stat_every'         => 60,
    'auto_repairs_max'   => 2,
    @_,
  );
  @{$self}{ keys %_ } = values %_;
  #$self->{$_} //= $_{$_} for keys %_;
  #%_ = @_;
  #$self->{$_} = $_{$_} for keys %_;
  #$self->log( 'dev', 'initdb',  "$self->{'database'},$self->{'dbname'};");
  $self->{'database'} = $self->{'dbname'} if $self->{'dbname'};
  $self->{'dbname'} ||= $self->{'database'};
  $self->calc();
  $self->functions();
  ( $tq, $rq, $vq ) = $self->quotes();
  DBI->trace( $self->{'trace_level'}, $self->{'trace'} ) if $self->{'trace_level'} and $self->{'trace'};
  return 0;
}

sub calc {
  my $self = shift;
  $self->{'default'} ||= \%default;
  $self->{'default'}{'pg'}{'match'} = sub {
    my $self = shift;
    return undef unless $self->{'use_fulltext'};
    my ( $param, $param_num, $table, $search_str, $search_str_stem ) = @_;
    my ( $ask, $glue );
    s/(?:^\s+)|(?:\s+$)//, s/\s+/$self->{'fulltext_word_glue'}/g for ( $search_str, $search_str_stem );
    local %_;
    map { $_{ $self->{'table'}{$table}{$_}{'fulltext'} } = 1 }
      grep { $self->{'table'}{$table}{$_}{'fulltext'} } keys %{ $self->{'table'}{$table} };
    for my $index ( keys %_ ) {
      my $stem =
        grep { $self->{'table'}{$table}{$_}{'fulltext'} eq $index and $self->{'table'}{$table}{$_}{'stem_index'} }
        keys %{ $self->{'table'}{$table} };
      my $double =
        grep { $self->{'table'}{$table}{$_}{'fulltext'} and $self->{'table'}{$table}{$_}{'stem'} }
        keys %{ $self->{'table'}{$table} };
      next if $double and ( $self->{'accurate'} xor !$stem );
      $ask .= " $glue $index @@ to_tsquery( ${vq}$self->{'fulltext_config'}${vq}, "
        . $self->squotes( $stem ? $search_str_stem : $search_str ) . ")";
      $glue ||= $self->{'fulltext_glue'};
    }
    return $ask;
    }
    if $self->{'use_fulltext'};
  %{ $self->{'default'}{'mysql6'} } = %{ $self->{'default'}{'mysql5'} };
  %{ $self->{'default'}{'mysql4'} } = %{ $self->{'default'}{'mysql5'} };
  $self->{'default'}{'mysql4'}{'SET NAMES'}                 = $self->{'default'}{'mysql4'}{'DEFAULT CHARACTER SET'} =
    $self->{'default'}{'mysql4'}{'ON DUPLICATE KEY UPDATE'} = '';
  $self->{'default'}{'mysql4'}{'varchar_max'} = 255;
  %{ $self->{'default'}{'mysql3'} } = %{ $self->{'default'}{'mysql4'} };
  $self->{'default'}{'mysql3'}{'table options'} = '';
  $self->{'default'}{'mysql3'}{'USE_FRM'}       = '';
  $self->{'default'}{'mysql3'}{'no_boolean'}    = 1;
  #%{ $self->{'default'}{'sqlite2'} } = %{ $self->{'default'}{'sqlite'} };
  #$self->{'default'}{'sqlite2'}{'IF NOT EXISTS'} = $self->{'default'}{'sqlite2'}{'IF EXISTS'} = '';
  $self->{'default'}{'pg'}{'fulltext_config'} = 'default' if $self->{'old_fulltext'};
  %{ $self->{'default'}{'pgpp'} } = %{ $self->{'default'}{'pg'} };
  $self->{'default'}{'pgpp'}{'dbi'}    = 'PgPP';
  $self->{'default'}{'pgpp'}{'params'} = [qw(dbname host port path debug)];
  %{ $self->{'default'}{'mysqlpp'} } = %{ $self->{'default'}{'mysql5'} };
  $self->{'default'}{'mysqlpp'}{'dbi'}  = 'mysqlPP';
  $self->{'default'}{'sphinx'}{'match'} = $self->{'default'}{'mysql5'}{'match'};
  $self->{'driver'} ||= 'mysql5';
  $self->{'driver'} = 'mysql5' if $self->{'driver'} eq 'mysql';
  #print "U0:", $self->{user};
  #print "D0:", $self->{dbi};
  $self->{$_} //= $self->{'default'}{ $self->{'driver'} }{$_} for keys %{ $self->{'default'}{ $self->{'driver'} } };
  #print "U1:", $self->{user};
  #print "D1:", $self->{dbi};
  #$self->log( 'dev', "calc dbi[$self->{'dbi'} ||= $self->{'driver'}]");
  $self->{'dbi'} ||= $self->{'driver'}, $self->{'dbi'} =~ s/\d+$//i unless $self->{'dbi'};
  $self->{'codepage'} = psmisc::cp_normalize( $self->{'codepage'} );
  local $_ = $self->{ $self->{'codepage'} } || $self->{'codepage'};
  $self->{'cp'} = $_;
  $self->{'cp_set_names'} ||= $_;
  #$self->{'cp_int'} ||= 'cp1251';    # internal
  $self->{'cp_int'} ||= 'utf-8';    # internal
  $self->{'cp_out'} ||= 'utf-8';    # internal
  $self->cp_client( $self->{'codepage'} );
}

sub _connect {
  my $self = shift;

=c
  $self->log(
    'dev', 'conn',
    "dbi:$self->{'dbi'}:"
#"dbi:$self->{'default'}{ $self->{'driver'} }{'dbi'}:database=$self->{'base'};"
      #map {"$_:$self->{$_}"} qw(dbi database)
      . join(
      ';',
      map( { $_ . '=' . $self->{$_} }
        grep { defined( $self->{$_} ) } @{ $self->{'params'} } )
      ),
    $self->{'user'},
    $self->{'pass'},
#\%{ $self->{'connect_params'} }
    $self->{'connect_params'}
  );
=cut

  local @_ = (
    "dbi:$self->{'dbi'}:"
      . join( ';', map( { $_ . '=' . $self->{$_} } grep { defined( $self->{$_} ) } @{ $self->{'params'} } ) ),
    $self->{'user'}, $self->{'pass'}, $self->{'connect_params'}
  );
  #$self->log('dmp', "connect_cached = ",$self->{'connect_cached'}, Dumper(\@_));
  $self->{'dbh'} = ( $self->{'connect_cached'} ? DBI->connect_cached(@_) : DBI->connect(@_) );
  local $_ = $self->err_parse( \'Connection', $DBI::err, $DBI::errstr );
  return $_;
}

sub sleep {
  my $self = shift;
  return psmisc::sleeper(@_);
}

sub functions {
  my $self = shift;
  $self->{'user_params'} ||= sub {
    my $self = shift;
    ( $tq, $rq, $vq ) = $self->quotes();
    my $param = { map { %$_ } @_ };
    for my $from ( keys %{ $self->{'param_trans_int'} } ) {
      my $to = $self->{'param_trans_int'}{$from} || $from;
      $param->{$from} = 1 if $param->{$from} eq 'on';
      $self->{$to} =
        psmisc::check_int( $param->{$from}, ( $self->{ $to . '_min' } ), $self->{ $to . '_max' }, $self->{ $to . '_default' } );
    }
    $self->cp_client( $work{'codepage'} || $param->{'codepage'} || $config{'codepage'} );
  };
  $self->{'dump'} ||= sub {
    my $self = shift;
    $self->log( 'dmp', caller, ':=', join( ':', %$self ) );
    return 0;
  };
  $self->{'quotes'} ||= sub {
    #sub quotes {    # my ($tq, $rq, $vq) = $self->quotes();
    my $self = shift;
    $self->{'tq'} ||= $self->{'table quote'};
    $self->{'rq'} ||= $self->{'row quote'};
    $self->{'vq'} ||= $self->{'value quote'};
    return (
      $self->{'table quote'},    #$tq
      $self->{'row quote'},      #$rq
      $self->{'value quote'},    #$vq
    );
  };
  $self->{'sleep'} ||= sub {
    my $self = shift;
    $self->log( 'dev', 'sql_sleeper', @_ );
    return psmisc::sleeper(@_);
  };
  $self->{'drh_init'} ||= sub {
    my $self = shift;
    $self->{'drh'} ||= DBI->install_driver( $self->{'dbi'} );
    return 0;
  };
  $self->{'repair'} ||= sub {
    my $self = shift;
    my $tim  = psmisc::timer();
    @_ = sort keys %{ $self->{'table'} } unless @_;
    @_ = grep { $_ and $self->{'table'}{$_} } @_;
    $self->log( 'info', 'Repairing table...', @_ );
    $self->flush() unless $self->{'no_repair_flush'};
    local $self->{'error_tries'} = 0;    #!
    $self->query_log( "REPAIR TABLE "
        . join( ',', map( $self->tquote("$self->{'table_prefix'}$_"), @_ ) )
        . ( $self->{'rep_quick'} ? ' ' . $self->{'QUICK'}    : '' )
        . ( $self->{'rep_ext'}   ? ' ' . $self->{'EXTENDED'} : '' )
        . ( $self->{'rep_frm'}   ? ' ' . $self->{'USE_FRM'}  : '' ) );
    $self->flush();
    $self->log( 'time', 'Repair per', psmisc::human( 'time_period', $tim->() ) );
    return 0;
  };
  $self->{'query_time'} ||= sub {
    my $self = shift;
    #$self->log( 'dev', 'query_time ',  $_[0]);
    ++$self->{'queries'};
    $self->{'queries_time'} += $_[0];
    $self->{'queries_avg'} = $self->{'queries_time'} / $self->{'queries'} || 1;
  };
  $self->{'do'} ||= sub {
    my $self = shift;
    #$self->log( 'dev', 'do', @_);
    my $ret;
    return $ret if $self->keep();
    $self->err(0);
    for my $cmd (@_) {
      next unless $cmd;
      do {
        {
          $self->log( 'dmpbef', 'do(' . $self->{database} . '):[', $cmd, '] ' );
          my $tim = psmisc::timer();
          $ret += $self->{'dbh'}->do($cmd) if $self->{'dbh'};
          $self->log(
            'dmp', 'do(' . $self->{database} . '):[',
            $cmd, '] = ', $ret, ' per', psmisc::human( 'time_period', $tim->() ),
            'rps', psmisc::human( 'float', $ret / ( $tim->() || 1 ) )
          );
          $self->query_time( $tim->() );
        }
      } while ( $self->can_query() and $self->err_parse( \$cmd, $DBI::err, $DBI::errstr ) );
    }
    return $ret;
  };
  $self->{'can_query'} ||= sub {
    my $self = shift;
    return
        !( $work{'die'} or $self->{'die'} or $self->{'fatal'} )
      && ( !$self->{'error_chain_tries'} or $self->{'errors_chain'} < $self->{'error_chain_tries'} )
      && ( !$self->{'error_tries'} or $self->{'errors'} < $self->{'error_tries'} );
  };
  $self->{'prepare'} ||= sub {
    my $self = shift;
    my ($query) = @_;
    return 1 if $self->keep();
    $self->log( 'dmpbef', "prepare query {$query}" );
    return 2 unless $query;
    #warn $self->err();
    $self->err(0);
    my $ret;
    my $tim = psmisc::timer();
    #$self->log('dbg', "prepare", __LINE__, );
    do {
      {
        next unless $self->{'dbh'};
        $self->{'sth'}->finish() if $self->{'sth'};
        $self->{'sth'} = $self->{'dbh'}->prepare($query);
        redo if $self->can_query() and $self->err_parse( \$query, $DBI::err, $DBI::errstr, 1 );
        last unless $self->{'sth'};
        $ret = $self->{'sth'}->execute();
      }
    } while ( $self->can_query() and $self->err_parse( \$query, $DBI::err, $DBI::errstr ) );
    $self->query_time( $tim->() );
    #$self->log('dbg', "prepare", __LINE__, );
    return 3 if $DBI::err;
    $self->{'dbirows'} = 0 if ( $self->{'dbirows'} = $DBI::rows ) == 4294967294;
    $self->{'dbirows'} = $self->{'limit'} if $self->{'no_dbirows'};
#$self->log('dbg', "prepare", __LINE__, ':',$ret, $DBI::rows,'=',(($self->{'no_dbirows'} && $ret) ? '0E0' : !int $ret), 'dr=', $self->{'dbirows'});
    return ( ( $self->{'no_dbirows'} && $ret ) ? undef : !int $ret );
  };
  $self->{'line'} ||= sub {
    my $self = shift;
    #$self->log('dev', "line prep");
    return {} if @_ and $self->prepare(@_);
    #$self->log('dev', "line sth");
    return {} if !$self->{'sth'} or $self->{'sth'}->err;
    my $tim = psmisc::timer();
    #$self->log('dev', "line fetch");
    local $_ = $self->{'sth'}->fetchrow_hashref() || {};
    $_ = scalar( psmisc::cp_trans_hash( $self->{'codepage'}, $self->{'cp_out'}, $_ ) ) if $self->{'codepage'} ne $self->{'cp_out'};
    $self->{'queries_time'} += $tim->();
    $self->log(
      'dmp', 'line(' . $self->{database} . '):[', @_, '] = ', scalar keys %$_, ' per', psmisc::human( 'time_period', $tim->() ),
      'err=', $self->err(),
      #( caller(2) )[0]);
    ) if ( caller(2) )[0] ne 'pssql';
    return $_;
  };
  $self->{'query'} ||= sub {
    my $self = shift;
    #$self->log("qrun");
    my $tim = psmisc::timer();
    my @hash;
    for my $query (@_) {
      next unless $query;
      local $self->{'explain'} = 0, $self->query_log( $self->{'EXPLAIN'} . ' ' . $query )
        if $self->{'explain'} and $self->{'EXPLAIN'};
      local $_ = $self->line($query);
      next unless keys %$_;
      push( @hash, $_ );
      next unless $self->{'sth'} and keys %$_;
      my $tim = psmisc::timer();
      #$self->log("Db[",%$_,"]($self->{'codepage'}, $self->{'cp_out'})"),
      while ( $_ = $self->{'sth'}->fetchrow_hashref() ) {
        if ($self->{'codepage'} ne $self->{'cp_out'}) {
          push @hash, scalar psmisc::cp_trans_hash( $self->{'codepage'}, $self->{'cp_out'}, $_ );
        } else {
          push @hash, $_;
        }
      }
        #$self->log("Da[",%$_,"]"),
      $self->{'queries_time'} += $tim->();
    }
    $self->log(
      'dmp', 'query(' . $self->{database} . '):[',
      @_, '] = ', scalar @hash, ' per', psmisc::human( 'time_period', $tim->() ),
      'rps', psmisc::human( 'float', ( scalar @hash ) / ( $tim->() || 1 ) ),
      'err=', $self->err()
    );
    $self->{'dbirows'} = scalar @hash if $self->{'no_dbirows'} or $self->{'dbirows'} <= 0;
    #$self->log('dbirows=', $self->{'dbirows'});
    #$self->query_print($_) for @hash;
    #$self->log('qcp', $self->{'codepage'}, Dumper \@hash);
    if ( $self->{'codepage'} eq 'utf-8' ) {
      for (@hash) { utf8::decode $_ for grep {!ref} %$_; }
    }
    return wantarray ? @hash : \@hash;
  };
  $self->{'query_log'} ||= sub {
    my $self = shift;
    my @ret;
    for (@_) { push( @ret, $self->query_print( $self->query($_) ) ); }
    return wantarray ? @ret : \@ret;
  };
  $self->{'query_print'} ||= sub {
    my $self = shift;
    my @hash = @_;
    return unless @hash and %{ $hash[0] };
    $self->log( 'dbg', 'sql query', $_ );
    $self->log( 'dbg', '|',         join "\t|", keys %{ $hash[0] } ) if keys %{ $hash[0] };
    $self->log( 'dbg', '|',         join( "\t|", values %{$_} ) ) for @hash;
    return wantarray ? @_ : \@_;
  };
  $self->{'quote'} ||= sub {
    my $self = shift;
    my ( $s, $q, $qmask ) = @_;
    return $s if $self->{'no_quote_null'} and $s =~ /^null$/i;
    return $self->{'dbh'}->quote( defined $s ? $s : '' ) if $self->{'dbh'} and !$q;
    $q ||= "'";    # mask "|', q='
    if   ( $self->{'quote_slash'} ) { $s =~ s/($q|\\)/\\$1/g; }
    else                            { $s =~ s/($q)/$1$1/g; }
    return $q . $s . $q;
  };
  $self->{'squotes'} ||= sub {
    my $self = shift;
    return ' ' . $self->quote(@_) . ' ';
  };
  $self->{'tquote'} ||= sub {
    my $self = shift;
    return $self->{'tq'} . $_[0] . $self->{'tq'};
  };
  $self->{'rquote'} ||= sub {
    my $self = shift;
    return $self->{'rq'} . $_[0] . $self->{'rq'};
  };
  $self->{'vquote'} ||= $self->{'quote'};
  $self->{'filter_row'} ||= sub {
    my $self = shift;
    my ( $table, $filter, $values ) = @_;
    local %_;
    map { $_{$_} = $values->{$_} } grep { $self->{'table'}{$table}{$_}{$filter} } keys %{ $self->{'table'}{$table} };
    return wantarray ? %_ : \%_;
  };
  $self->{'err_parse'} ||= sub {
    my $self = shift;
    my ( $cmd, $err, $errstr, $sth ) = @_;
    $err    ||= $DBI::err;
    $errstr ||= $DBI::errstr;
    my $state = $self->{'dbh'}->state if $self->{'dbh'};
    my $errtype = $self->error_type( $err, $errstr );
    $errtype ||= 'connection' unless $self->{'dbh'};
    $self->{'fatal'} = 1 if $errtype eq 'fatal';
#$self->log('dev','error entry', $errtype, $err, $errstr, 'wdi=', $work{'die'}, 'di=', $self->{'die'}, 'fa=', $self->{'fatal'});

=c

ok
no dbi  ret1
install act ret1
repair  act ret1
syntax  ret0
fatal   ret0
ignore  ret0
other   ret1 n times

tries total
tries 

=cut

    $self->log(
      'dev', "err_parse st0 ret1 ",
      'wdi=', $work{'die'}, 'di=', $self->{'die'}, 'fa=', $self->{'fatal'}, 'er=',
      ( $self->{'errors'} >= $self->{'error_tries'} ),
      $self->{'errors'}, $self->{'error_tries'},
      $errtype, $state
      ),
      CORE::sleep(1), return $self->err(1)
      if $work{'die'}
        or $self->{'die'}
        or $self->{'fatal'}
        or ( $self->{'error_tries'} and $self->{'errors'} > $self->{'error_tries'} )
        or ( $self->{'error_chain_tries'} and $self->{'errors_chain'} > $self->{'error_chain_tries'} );
    $self->log( 'err', 'err_parse: IMPOSIBLE! !$err and !$self->{sth}' ), $self->err('sth'), return 0
      if $sth and ( !$err and !$self->{'sth'} );
    $self->{'errors_chain'} = 0, return $self->err(0) if !$err and $self->{'dbh'};
    ++$self->{'errors_chain'};
    ++$self->{'errors'};
    $self->log( 'err',
      "SQL: error[$err,$errstr,$errtype,$state] on executing {$$cmd} [sleep:$self->{'error_sleep'}] dbh=[$self->{'dbh'}]" );
    $self->log( 'dev', "err_parse st3 ret0 fatal=$errtype" ), $self->err($errtype), return (0)
      if $errtype and grep { $errtype eq $_ } qw(fatal syntax ignore);
    $self->log( 'dev', "err_parse sleep($self->{'error_sleep'}), ret1 ", );
    $self->sleep( $self->{'error_sleep'}, 'sql_parse' ) if $self->{'error_sleep'};
    $self->log( 'dev', "err_parse st3 ret1 fatal=$errtype" ), return $self->err($errtype)
      if $errtype and grep { $errtype eq $_ } qw(retry);

    if ( $errtype eq 'install_db' and $self->{'auto_install_db'}-- > 0 ) {
      $self->log( 'info', "SQL: trying automatic install db" );
      $self->create_databases(@_);
      return $self->err($errtype);
    }
    $self->log( 'info', "SQL: trying reconnect[$self->{'connected'}]" ), $self->reconnect(), return $self->err('dbh')
      if !$self->{'dbh'};
    if ( $errtype eq 'install' or $errtype eq 'upgrade' ) {
      if ( $self->{'auto_install'}-- > 0 ) {
        $self->log( 'dev',  "SQL:install err " );
        $self->log( 'info', "SQL: trying automatic install" );
        $self->$errtype();
        return $self->err($errtype);
      } else {
        $self->log( 'dev', "SQL:NOinstall err " );
        $self->err($errtype);
        return (0);
      }
    }
    $self->log( 'err', "SQL: connection error, trying reconnect and retry last query" ), $self->dropconnect(),
      $self->reconnect(), return $self->err($errtype)
      if $errtype eq 'connection';
    if ( $self->{'auto_repair'} and $errtype eq 'repair' ) {
      my ($repair) = $errstr =~ /'(?:.*[\\\/])*(\w+)(?:\.my\w)?'/i;
      $repair = $self->{'current_table'} unless %{ $self->{'table'}{$repair} || {} };
      if ( $self->{'auto_repairs'}{$repair} < $self->{'auto_repairs_max'} ) {
        my $sl = int( rand( $self->{'auto_repair'} + 1 ) );
        $self->log( 'info', 'pre repair sleeping', $sl );
        $self->sleep($sl);
        if ( $sl == 0 or $self->{'force_repair'} ) {
          $self->log( 'info', 'denied repair', $repair ), return $self->err(1)
            if $self->{'auto_repair_selected'}
              and ( !$repair or $self->{'auto_repair_selected'} and $self->{'table_param'}{$repair}{'no_auto_repair'} );
          ++$self->{'auto_repairs'}{$repair};
          $self->log( 'info', "SQL: trying automatic repair", $repair );
          $self->repair($repair);
          $self->{'rep_ext'} = $self->{'rep_frm'} = 1;
          $self->{'rep_quick'} = 0;
          return $self->err($errtype);
        }
      }
    }
    $self->log( 'dev', "err_parse st2 ret1 no dbh", $err, $errstr ), return $self->err('dbh') if !$self->{'dbh'};
    $self->log( 'dev', "err_parse unknown error ret($self->{'err_retry_unknown'}), end: [$err], [$errstr], [$errtype]" );
    return $self->err( $self->{'err_retry_unknown'} );
  };
  $self->{'install'} ||= sub {
    my $self = shift;
    return $self->create_databases(@_) + $self->create_tables();
  };
  $self->{'create_database'} ||= sub {
    my $self = shift;
    my $ret;
    local $_;
    local @_ = ( $self->{'database'} ) unless @_;
    $self->drh_init() if $self->{'use_drh'};
    for my $db (@_) {
      if ( $self->{'use_drh'} ) {
        $ret += $_ = $self->{'drh'}->func( 'createdb', $db, $self->{'host'}, $self->{'user'}, $self->{'pass'}, 'admin' );
      } elsif ( $self->{'driver'} =~ /pg/i ) {
        {
          my $db = $self->{'dbname'};
          local $self->{'dbname'}     = 'postgres';
	  local $self->{'database'}   = undef;
          local $self->{'in_connect'} = undef;
          $self->do("CREATE DATABASE $rq$db$rq WITH ENCODING $vq$self->{'cp'}$vq");
        }
        $self->reconnect();
      }
      $self->log( 'info', 'install database ', $db, '=', $ret );
    }
    return $ret;
  };
  $self->{'create_databases'} ||= sub {    #http://dev.mysql.com/doc/refman/5.1/en/create-table.html
    my $self = shift;
    return $self->create_database( $self->{'database'} );
  };
  $self->{'create_tables'} ||= sub {       #http://dev.mysql.com/doc/refman/5.1/en/create-table.html
    my $self = shift;
    my (%table) = %{ $self->{'table'} or {} };
    my @ret;
    for my $tab ( sort keys %table ) {
      $self->log( 'dev', 'creating table', $tab );
      push( @ret, $self->{'create_table'}->( $self, $tab, $table{$tab} ) );
      push( @ret, $self->{'create_index'}->( $self, $tab, $table{$tab} ) ) unless $self->{'index in create table'};
    }
    return @ret;
  };
  $self->{'create_table'} ||= sub {        #http://dev.mysql.com/doc/refman/5.1/en/create-table.html
    my $self = shift;
    my ( $tab, $table ) = @_;
    my ( @subq, @ret );
    return undef if $tab =~ /^\W/;
    my ( @primary, %unique, %fulltext, @do );
    for my $row ( sort { $table->{$b}{'order'} <=> $table->{$a}{'order'} } keys %$table ) {
      push( @primary, $rq . $row . $rq ) if $table->{$row}{'primary'}
          #!and $self->{'driver'} ne 'sqlite'
      ;
      push( @{ $fulltext{ $table->{$row}{'fulltext'} } }, $rq . $row . $rq ) if $table->{$row}{'fulltext'};
      push( @{ $unique{ $table->{$row}{'unique'} } }, $rq . $row . $rq )
        if $table->{$row}{'unique'} and $table->{$row}{'unique'} =~ /\D/;
    }
    if ( $self->{'driver'} =~ /pg/i and $self->{'use_fulltext'} ) {
      #$self->log('dev', 'ftdev',$tab,Dumper(\%fulltext),
      1 || $self->{'fulltext_trigger'}
        ? push(
        @do,
        "DROP TRIGGER $self->{'IF EXISTS'} ${tab}_update_$_ ON $tab",
        $self->{'old_fulltext'}
        ? ( "CREATE TRIGGER ${tab}_update_$_ BEFORE UPDATE OR INSERT ON $tab FOR EACH ROW EXECUTE PROCEDURE tsearch2($rq$_$rq, "
            . ( join( ', ', @{ $fulltext{$_} || [] } ) )
            . ")" )
        : (
"CREATE TRIGGER ${tab}_update_$_ BEFORE UPDATE OR INSERT ON $tab FOR EACH ROW EXECUTE PROCEDURE tsvector_update_trigger($rq$_$rq, ${vq}$self->{'fulltext_config'}${vq}, "
            . ( join( ', ', @{ $fulltext{$_} || [] } ) )
            . ")" )
        )
        : (),
        #),
        $table->{$_} = { 'order' => -9999, 'type' => 'tsvector', } for keys %fulltext;
      #push(@do,"update pg_ts_cfg set locale = 'en_US.UTF-8' where ts_name = 'default'") ,
      #push(@do,"select set_curcfg('default');") if @do;
    }
    for my $row ( grep { keys %{ $table->{$_} } } keys %$table ) {
      $table->{$row}{'varchar'} = 1 if $table->{$row}{'type'} =~ /^varchar$/i;    #
    }
    #$self->log('dev', Dumper $table);
    for my $row ( sort { $table->{$b}{'order'} <=> $table->{$a}{'order'} } grep { keys %{ $table->{$_} } } keys %$table ) {
      next if $row =~ /^\W/;
      $table->{$row}{'length'} = psmisc::min( $self->{'varchar_max'}, $table->{$row}{'length'} );
      my $length = $table->{$row}{'length'};
      if ( !defined $length ) {
        {
          my ( @types, @maxs, );
          push @types, 'primary' if $table->{$row}{'primary'} and $table->{$row}{'type'} =~ /char/i;
          push @types, 'fulltext' if $table->{$row}{'fulltext'};
          push @types, 'unique'   if $table->{$row}{'unique'};
          push( @types, 'varchar' ) if $table->{$row}{'varchar'};    #= 1 if $table->{$row}{'type'} =~ /^varchar$/i;
          last unless @types;
          #$self->log( 'dev', ' ======= ', $row, ' length detect start', @types );
          for my $type (@types) {
            my $max;
            #$type = $types[0];
            $max = $self->{ $type . '_max' };                        # if $type ne 'varchar';
            #$self->log('dev',"type $type start ", $row, " max=$max");
            $max /= 3 if $self->{'codepage'} eq 'utf-8' and $self->{'driver'} =~ /mysql/;
            #$max-=2;
            #$self->log('dev','lenmax:',$row,  "type=$type; max=$max, ", Dumper($table));
            my $same;
            my $nowtotal;
            for (
              grep {
                $_
                  #$table->{ $_ }{$type} and $_ ne $row
                  #and $table->{ $_ }{$type} eq $table->{ $row }{$type}
              } keys %{$table}
              )
            {
              $nowtotal += 2 if $type eq 'varchar' and $table->{$_}{'type'} =~ /^smallint$/i;
              $nowtotal += 4 if $type eq 'varchar' and $table->{$_}{'type'} =~ /^int$/i;
              $nowtotal += 8 if $type eq 'varchar' and $table->{$_}{'type'} =~ /^bigint$/i;
          #$self->log('dev', $row, 'look', $_, $type, $table->{ $_ }{$type} , $table->{ $_ }{'length'}, $table->{ $_ }{'type'});
              next unless $table->{$_}{$type} eq $table->{$row}{$type};
              next if !( $table->{$_}{$type} and $_ ne $row );
              #$self->log( 'dev', $row, 'minus', $_, $table->{$_}{'length'} ),
              #$max -=  $table->{ $_ }{'length'};
              $nowtotal += $table->{$_}{'length'};
              ++$same,
                #$self->log('dev', $row, 'same', $_, $same),
                if !( $table->{$_}{'length'} );
            }
            $max -= $nowtotal;
            my $want = $max / ( $same + 1 );
    #$self->log('dev', $row, 'same',  $same, 'tot:', $nowtotal,);
    #$self->log('dev','len0:',$row,  "type=$type; max=$max, same=$same totalwo=$nowtotal want=$want  el=", scalar keys %$table);
            $nowtotal = 0;
            for (
              grep {
                      $table->{$_}{$type}
                  and $_ ne $row
                  and $table->{$_}{$type} eq $table->{$row}{$type}
                  and !$table->{$_}{'length'}
              } keys %{$table}
              )
            {
              --$same,
                #$max += $want - $table->{ $_ }{'length_max'} ,
                $max -= $table->{$_}{'length_max'}, $nowtotal += $table->{$_}{'length_max'},
#$self->log('dev','maxlen:',$row,  "look=$_ type=$type; max=$max, same=$same totalwo=$nowtotal want=$want lenmax=$table->{$_}{'length_max'} ret=",$want - $table->{ $_ }{'length_max'}),
                if $table->{$_}{'length_max'} and $table->{$_}{'length_max'} < $want;
            }
           #|| $table->{ $_ }{'length_max'}
           #$self->log( 'dev', $row, 'same', $same, 'tot:', $nowtotal );
           #$self->log('dev','len1:',$row,  "type=$type; max=$max, ");
           #$self->log('dev','lenpresame',$row,  "type=$type; max=$max, same=$same totalwo=$nowtotal el=", scalar keys %$table);
            $max /= $same + 1 if $same;
            $max = int($max);
            #$self->log('dev','tot:',$row, $nowtotal+(($same+1) * $max));
            #$self->log('dev','len:',$row,  "type=$type; max=$max, same=$same totalwo=$nowtotal el=", scalar keys %$table);
            #$max /= ( scalar @primary or 1 ) if $table->{$row}{'primary'} and $table->{$row}{'primary'};
            #$length /= ( scalar keys(%unique) + 1 ) if $table->{$row}{'unique'} and $table->{$row}{'unique'} =~ /\D/;
            push @maxs, $max;
          }
          push @maxs, $table->{$row}{'length_max'} if $table->{$row}{'length_max'};
          push @maxs, $self->{'varchar_max'} if $table->{$row}{'type'} =~ /^varchar$/i;
         #push @maxs, 1000 / 3
         push @maxs, $self->{'key_length'} / 3
            if $table->{$row}{'type'} =~ /^varchar$/i
              and $table->{$row}{'primary'}
              and $self->{'codepage'} eq 'utf-8';
          #$self->log( 'dev', $row, "key=$self->{'key_length'}", 'maxs:', @maxs , Dumper $table->{$row});
          #print "mx:",@maxs;
          $length = psmisc::min( grep { $_ > 0 } @maxs );
          #$table->{$row}{'length'} ||= $length if $table->{$row}{'type'} eq 'varchar';
          $table->{$row}{'length'} ||= $length;

=z
        $length ||= $self->{'primary_max'} if $table->{$row}{'primary'} and $table->{$row}{'type'} =~ /char/i;
        $length ||= $self->{'fulltext_max'} if $table->{$row}{'fulltext'};
        $length ||= $self->{'unique_max'}   if $table->{$row}{'unique'};
        $length ||= $self->{'varchar_max'}  if $table->{$row}{'type'} =~ /^varchar$/i;
        $self->log('dev', 'crelenbef',$row, $length, 'prim=', $table->{$row}{'primary'});
        my $maxl = $self->{'row_max'} / scalar keys %$table;    #todo better counting
#my $maxl = $length / scalar keys %$table;    #todo better counting
        $self->log('dev', 'maxl',$row, $maxl);
        $length = $maxl if $length > $maxl;
        $length /= 3 if $self->{'codepage'} eq 'utf-8' and $self->{'driver'} =~ /mysql/;
        #$self->log('dev', 'crelen',$row, $length, scalar keys(%unique) +1);
#$self->log('dev', 'crelen',$row, $length, scalar @primary );
        $length /= ( scalar @primary or 1 ) if $table->{$row}{'primary'} and $table->{$row}{'primary'};
        $length /= ( scalar keys(%unique) + 1 ) if $table->{$row}{'unique'} and $table->{$row}{'unique'} =~ /\D/;
        #$length=int($length/(4));
        $self->log('dev', 'crelenaft',$row, $length);
=cut

          $length = int($length);
        }
      }
      #$self->log('dev', "$row NN= $table->{$row}{'not null'}");
      push(
        @subq,
        $rq
          . $row
          . $rq
          . " $table->{$row}{'type'} "
          #. ( $table->{$row}{'length'} ? "($table->{$row}{'length'}) " : '' )
          . ( $length ? "($length) " : '' )
          . ( ( $table->{$row}{'unsigned'} and $self->{'UNSIGNED'} ) ? ' ' . $self->{'UNSIGNED'} : '' )
          . ( (
            #!S$self->{'driver'} ne 'sqlite' or
            !$table->{$row}{'auto_increment'}
          )
          #? ( ( $table->{$row}{'null'} ) ? ' NULL ' : ' NOT NULL ' )
          #? ( ( $table->{$row}{'null'} ) ? '' : ' NOT NULL ' )
          ? ( ( $table->{$row}{'not null'} ) ? ' NOT NULL ' : '' )
          : ''
          )
          . (
          ( defined( $table->{$row}{'default'} ) and !$table->{$row}{'auto_increment'} )
          ? " DEFAULT " . ( $table->{$row}{'default'} eq 'NULL' ? 'NULL' : "$vq$table->{$row}{'default'}$vq" ) . " "
          : ''
          )
          . ( ( $table->{$row}{'unique'} and $table->{$row}{'unique'} =~ /^\d+$/ ) ? ' UNIQUE ' : '' )
          #.( ( $self->{'driver'} eq '!Ssqlite' and $table->{$row}{'primary'} ) ? ' PRIMARY KEY ' : '' )
          . ( (
            $table->{$row}{'auto_increment'} and (
              #TEST S! $self->{'driver'} ne '!Ssqlite' or
              #$table->{$row}{'primary'} #?
              1
            )
          )
          ? ' '
            . $self->{'AUTO_INCREMENT'} . ' '
          : ''
          )
          . "$table->{$row}{'param'}"
      );
    }
    #iwh
    push( @subq, "PRIMARY KEY (" . join( ',', @primary ) . ")" ) if @primary;
    for my $row ( sort { $table->{$b}{'order'} <=> $table->{$a}{'order'} } keys %$table ) {
      push(
        @subq,
        "INDEX "
          . $rq
          . $row
          . $self->{'index_postfix'}
          . $rq . " ("
          . $rq
          . $row
          . $rq
          . (
          ( $table->{$row}{'index'} > 1 and $table->{$row}{'index'} < $table->{$row}{'length'} )
          ? '(' . $table->{$row}{'index'} . ')'
          : ''
          )
          . ")"
      ) if $table->{$row}{'index'} and $self->{'index in create table'};

=c
      push(
        @subq,
        "INDEX UNIQUE" 
          . $rq 
          . $row 
          . $self->{'index_postfix'} . 'u'
          . $rq . " (" 
          . $rq 
          . $row 
          . $rq
          . ")"
        )
        if $table->{$row}{'unique'}
        and $self->{'index in create table'};
=cut

      push( @primary, $rq . $row . $rq ) if $table->{$row}{'primary'};
    }
    push( @subq, "UNIQUE " . ( $self->{'unique name'} ? $rq . $_ . $rq : '' ) . "  (" . join( ',', @{ $unique{$_} } ) . ")" )
      for grep @{ $unique{$_} }, keys %unique;
    if ( $self->{'index in create table'} ) {
      push( @subq, "FULLTEXT $rq$_$rq (" . join( ',', @{ $fulltext{$_} } ) . ")" ) for grep @{ $fulltext{$_} }, keys %fulltext;
      #push( @subq, "UNIQUE $rq$_$rq  (" . join( ',',  @{ $unique{$_} } ) . ")" )   for grep @{ $unique{$_} },   keys %unique;
    }
    #push(
    #$self->log('dev', "[cp:$self->{'cp'}; dcs:$self->{'DEFAULT CHARACTER SET'}]");
    #@ret,
    return
      #print
      map  { $self->do($_) }
      grep { $_ }
      ( !@subq
      ? ()
      : 'CREATE TABLE '
        . $self->{'IF NOT EXISTS'}
        . " $tq$self->{'table_prefix'}$tab$tq ("
        . join( ",", @subq )
        . ( join ' ', '', grep { $_ } $self->{'table_constraint'}, $self->{'table_param'}{$tab}{'table_constraint'} ) . ") "
        . $self->{'table options'} . ' '
        . $self->{'table_param'}{$tab}{'table options'}
        . ( $self->{'cp'} && $self->{'DEFAULT CHARACTER SET'} ? " $self->{'DEFAULT CHARACTER SET'} $vq$self->{'cp'}$vq " : '' )
        . ';' ), @do;
    #return undef;
  };
  #$self->{'do'}{'create_index'} = 1;
  $self->{'create_index'} ||= sub {
    #sub create_index {
    my $self = shift;
    my @ret;
    my ( $tab, $table ) = @_;
    #for my $table( @_){
    #for my $tab ( keys %$table ) {
    my (@subq);
    #next if $tab =~ /^\W/;
    for my $row ( sort { $table->{$b}{'order'} <=> $table->{$a}{'order'} } keys %$table ) {
      next if $row =~ /^\W/;
      push( @ret,
            'CREATE INDEX '
          . $self->{'index_IF NOT EXISTS'} . ' '
          . $rq
          . $row
          . ( $self->{'index_name_table'} ? '_' . $tab : '' )
          . $self->{'index_postfix'}
          . $rq . ' ON '
          . " $tq$self->{'table_prefix'}$tab$tq ( $rq$row$rq )" )
        if $table->{$row}{'index'};
    }
    #}
    return $self->do(@ret);
  };
  $self->{'create_indexes'} ||= sub {
    #$self->log values  %{ $self->{'table'}};
    $self->create_index( $_, $self->{'table'}{$_} ) for keys %{ $self->{'table'} };
  };
  #$self->{'do'}{'drop_table'} = 1;
  $self->{'drop_table'} ||= sub {
    #sub drop_table {
    my $self = shift;
    my @ret;
    for my $tab (@_) {
      my ($sql);
      next if $tab =~ /^\W/ or $tab !~ /\w/;
      $sql .= "DROP TABLE " . $self->{'IF EXISTS'} . " $tq$self->{'table_prefix'}$tab$tq $self->{'CASCADE'}";
      push( @ret, $sql );
    }
    return $self->do(@ret);
  };
  $self->{'drop_database'} ||= sub {
    #sub drop_table {
    my $self = shift;
    my @ret;
    @_ = $self->{'database'} if !@_;
    my $rec = 1 if $self->{'driver'} =~ /pg/i and grep { $self->{'database'} eq $_ } @_;
    if ($rec) {
      #$self->log('dev','tryreconnect', $self->{'connected'});
      local $self->{'dbname'}   = undef;
      local $self->{'database'} = undef;
      $self->{'dbname'} = $self->{'database'} = 'postgres' if $self->{'driver'} =~ /pg/i;    #TODO MYSQL
      #$self->dropconnect();
      $self->reconnect();
    }
    for my $tab (@_) {
      my ($sql);
      next if $tab =~ /^\W/ or $tab !~ /\w/;
      $sql .= "DROP DATABASE " . $self->{'IF EXISTS'} . " $tq$self->{'table_prefix'}$tab$tq";
      push( @ret, $sql );
    }
    @ret = $self->do(@ret);
    if ($rec) { $self->reconnect(); }
    return @ret;
  };
  $self->{'drop_tables'} ||= sub {
    my $self = shift;
    @_ = keys %{ $self->{'table'} or {} } if !@_;
    return $self->drop_table(@_);
  };
  #{
  #my (%buffer);
  #$processor{'out'}{'array'} ||= sub {
  $self->{'insert_fields'} ||= sub {
    my $self = shift;
    my $table = shift || $self->{'current_table'};
    return grep {
      $self->{'table'}{$table}{$_}{'array_insert'}
        #or !defined $self->{'table'}{$table}{$_}{'default'}
    } keys %{ $self->{'table'}{$table} };
  };
  $self->{'insert_order'} ||= sub {
    my $self = shift;
    my $table = shift || $self->{'current_table'};
    return sort { $self->{'table'}{$table}{$b}{'order'} <=> $self->{'table'}{$table}{$a}{'order'} } $self->insert_fields($table)
      #grep { $self->{'table'}{$table}{$_}{'array_insert'} or !defined $self->{'table'}{$table}{$_}{'default'}
      #} keys %{ $self->{'table'}{$table} }
  };
  $self->{'insert_cached'} ||= sub {
    my $self         = shift;
    my $table        = shift;
    my $table_insert = $table || $self->{'current_table'};
#$self->log('dev','insert_cached', $table,Dumper(\@_), 'by', ( $self->{'table_param'}{$table}{'insert_by'} or $self->{'insert_by'} ), 'bytime=', $self->{'insert_cached_time'});
    my @dummy;
    #my ( $tq, $rq, $vq ) = sql_quotes();
    ++$self->{'inserts'}, ++$self->{'table_updated'}{$table_insert}, push( @{ $self->{'insert_buffer'}{$table_insert} }, \@_ )
      if $table_insert and @_;
    #$self->log('dev', 'cached', keys %{ $self->{'insert_buffer'} });
    for my $table ( $table ? ($table) : ( keys %{ $self->{'insert_buffer'} } ) ) {
      $self->{'insert_block'}{$table} //= $self->{'table_param'}{$table}{'insert_by'} || $self->{'insert_by'};
      #unless defined $self->{'insert_block'}{$table};
      #$self->log('ict', $table,int(time() - $self->{'insert_buffer_time'}{$table}));
      #$self->{'insert_buffer_time'}{$table}||=time();
      if (
        $self->{'insert_block'}{$table}-- <= 1
        or !scalar(@_)
        #or time() - $self->{'insert_buffer_time'}{$table} > $self->{'insert_cached_time'}
        or time() - ( $self->{'insert_buffer_time'}{$table} ||= time() ) > $self->{'insert_cached_time'}
        )
      {
        $self->{'stat'}{'time'}{'count'} += scalar @{ $self->{'insert_buffer'}{$table_insert} || [] };
        $self->{'insert_buffer_time'}{$table} = time();
        $self->{'current_table'} = $table;
        #$self->log('doing insert', $table, Dumper $self->{'insert_buffer'}{$table});
        $self->do(
          join(
            '',
            ( $self->{'ON DUPLICATE KEY UPDATE'} ? $self->{'INSERT'} : $self->{'REPLACE'} )
              . " $self->{$self->{'insert_options'}} INTO $tq$self->{'table_prefix'}$table$tq (",
            join( ',', map { $rq . $_ . $rq } $self->insert_order($table) ),
            ") VALUES\n",
            join(
              ",\n",
              map {
                join(
                  '', '(',
                  join(
                    ',',
                  #map { $self->quote( scalar cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $$_ ), $self->{'value quote'} ) }
                    map { $self->quote( scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $$_ ) ) }
                      @{$_}[ 0 .. scalar( $self->insert_fields($table) ) - 1 ],
                    @dummy =
                      ( map { \$self->{'table'}{$table}{$_}{'default'} } $self->insert_order($table) )
                      [ scalar( @{$_} ) .. scalar( $self->insert_fields($table) ) - 1 ]
                  ),
                  ')'
                  )
              } @{ $self->{'insert_buffer'}{$table} }
            ), (
              !$self->{'ON DUPLICATE KEY UPDATE'} ? '' : " \n" . $self->{'ON DUPLICATE KEY UPDATE'} . ' ' . join(
                ',',
                map {
                  $rq . $_ . $rq . '=VALUES(' . $rq . $_ . $rq . ')'
                  } sort {
                  $self->{'table'}{$table}{$b}{'order'} <=> $self->{'table'}{$table}{$a}{'order'}
                  } grep {
                  $self->{'table'}{$table}{$_}{'array_insert'}
                    and !$self->{'table'}{$table}{$_}{'no_insert_update'}
                    and !$self->{'table'}{$table}{$_}{'added'}
                  } keys %{ $self->{'table'}{$table} }
              )
            ),
            ';'
          )
          ),
          delete $self->{'insert_buffer'}{$table}
          if scalar @{ $self->{'insert_buffer'}{$table} || [] };
        $self->{'insert_block'}{$table} = $self->{'table_param'}{$table}{'insert_by'} || $self->{'insert_by'};
        $self->{'stat'}{'time'}{'time'} += time - $self->{'insert_buffer_time'}{$table};
        psmisc::schedule(
          [ $self->{'stat_every'}, $self->{'stat_every'} ],
          sub {
            #my $per =  $self->{'stat'}{'time'}{'time'};
            $self->log(
              'time',
              'inserts',
              $self->{'stat'}{'time'}{'count'},
              'per',
              psmisc::human( 'time_period', $self->{'stat'}{'time'}{'time'} ),
              'at',
              psmisc::human( 'float', $self->{'stat'}{'time'}{'count'} / ( $self->{'stat'}{'time'}{'time'} || 1 ) ),
              'rps',
              'full',
              psmisc::human( 'float', $self->{'stat'}{'time'}{'count'} / ( time - $self->{'stat'}{'time'}{'full'} or 1 ) ),
              'rps'
            );
            $self->{'stat'}{'time'} = { 'full' => time };
          }
        ) if $self->{'stat_every'};
      }
    }
    #$self->log('dev', 'insert:',@{ $buffer{$table} });
    return undef;
  };
  #}
  #$self->{'flush'} ||= $self->{'insert'};
  $self->{'flush_insert'} ||= sub {
    my $self = shift;
    $self->insert_cached(@_);
    #pg tsearch
    #push( @{ $fulltext{ $table->{$row}{'fulltext'} } }, $rq . $row . $rq ) if $table->{$row}{'fulltext'};
    if ( 0 and $self->{'driver'} =~ /pg/i and $self->{'use_fulltext'} ) {
      for my $tablen ( grep { $_ and $self->{'table_updated'}{$_} } keys %{ $self->{'table_updated'} || {} } ) {
        my $table = $self->{'table'}{$tablen};
        my (%fulltext);
        for my $row ( sort { $table->{$b}{'order'} <=> $table->{$a}{'order'} } keys %$table ) {
          push( @{ $fulltext{ $table->{$row}{'fulltext'} } }, $rq . $row . $rq ) if $table->{$row}{'fulltext'};
        }
        my @do;
        #local @_ = map {$self->rquote($_)}grep {$table->{$_}{'fulltext'}} keys %{%$table || {}} or next;
        push @do,
            "SELECT tsvector_update_trigger($rq$_$rq, ${vq}$self->{'fulltext_config'}${vq}, "
          . ( join( ', ', @{ $fulltext{$_} || [] } ) )
          . ") FROM $tq$tablen$tq"
          for keys %fulltext;
        #$self->log('dev', 'ftup',$self->{'table_updated'}{$table},$table, $do);
        $self->do(@do);
        $self->{'table_updated'}{$tablen} = 0;
      }
    }
  };
  $self->{'insert'} ||= sub {
    my $self = shift;
    my @ret  = $self->insert_cached(@_);
    $self->flush_insert( $_[0] ) if scalar @_ > 1;
    return @ret;
  };
  $self->{'update'} ||= sub {
    my $self = shift;
    my $table = ( shift or $self->{'current_table'} );
    #sub update {    #v5
    #my $self = shift;
    my ( $by, $values, $where, $set, $setignore, $whereignore ) = @_;
    #$self->log('dev','sql_update:', $self->{database}, join ':',@_, "PREUPVAL=",%{$values} );
    #$self->log('dev','sql_update:', "[$set],[$setignore]" );
    return unless %{ $self->{'table'}{$table} or {} };
    $self->{'current_table'} = $table;
    #my ( $tq, $rq, $vq ) = sql_quotes();
    #$self->log('dev','HIRUN', $table, $self->{'handler_insert'} ,
    #$self->log( 'filter', 'f2', $self->{'table_param'}{$table}{'filter'} );
    next
      if ref $self->{'table_param'}{$table}{'filter'} eq 'CODE'
        and $self->{'table_param'}{$table}{'filter'}->( $self, $values );
    $self->{'handler_insert'}->( $table, $values ) if ref $self->{'handler_insert'} eq 'CODE';
    $self->stem_insert( $table, $values );
    #$self->{'handler_insert'}->( $table, \%{$values} ) if $self->{'handler_insert'};
    local $self->{'handler_insert'} = undef;
    local $self->{'stem_insert'} = sub { };
    local @_;
    $by ||=
      [ grep { $self->{'table'}{$table}{$_}{'primary'} or $self->{'table'}{$table}{$_}{'unique'} }
        keys %{ $self->{'table'}{$table} || {} } ];
    my $bymask = '^(' . join( ')|(', @$by ) . ')$';
    my $bywhere = join(
      ' AND ',
      map ( "$rq$_$rq=" . $self->quote( $values->{$_} ),
        grep {
          %{ $self->{'table'}{$table}{$_} || {} }
            and ( $self->{'table'}{$table}{$_}{'primary'} or $self->{'table'}{$table}{$_}{'unique'} )
            and $self->{'table'}{$table}{$_}{'type'} ne 'serial'
            and !$self->{'table'}{$table}{$_}{'auto_increment'}    #todo mysql
        } @$by )
    );
    $set ||= join(
      ', ', (
        map {
          #$self->log('dev','sql_update:', "[$_:$values->{$_}]" );
          $rq . $_ . $rq . "=" . $self->quote(
            $self->cut( $values->{$_}, $self->{'table'}{$table}{$_}{'length'} )
              #$values->{$_}
            )
          } (
          @_ = grep( ( ( $_ !~ $bymask ) and $_ and %{ $self->{'table'}{$table}{$_} || {} } and defined( $values->{$_} ) ),
            keys %$values ), (
            @_ ? () : grep {
              $_ and %{ $self->{'table'}{$table}{$_} or {} } and defined( $values->{$_} )
            } keys %$values
          )
          )
      )
    );
    $set = 'SET ' . $set if $set;
    my $lwhere = $where;
    $where = '' if $where eq 1;
    $where = ' AND ' . $where if $where and $bywhere;
    $whereignore = ' AND ' . $whereignore if $whereignore and ( $where or $bywhere );
    local $_;
    #$processor{'out'}{'sql'}
    $_ = $self->do(
"UPDATE $self->{$self->{'update_options'}} $self->{'IGNORE'} $tq$self->{'table_prefix'}$table$tq $set $setignore WHERE $bywhere $where $whereignore"
      )
      if ( $set or $lwhere or !$self->{'ON DUPLICATE KEY UPDATE'} )
      and ( $bywhere or $where or $whereignore );
#$self->log( 'dev','by', Dumper $by);
#$self->log( 'dev', "WHERE[" . $where . "] BYwhere[" . $bywhere . "] whereignore[$whereignore] ",      " UPVAL=", %{$values}, "UPSET=", $set, "RES[$_]" , Dumper $self->{'table'}{$table});
#$processor{'out'}{'hash'}->
#$self->hash($table, { '' => $values } ),    #$processor{'out'}{'array'}->($table)
#$self->log( 'dev',"insert_hash run? ", "( !$set or !int($_) ) and !$where");
#$self->log( 'dev',"insert_hash run "),
    $self->insert_data( $table, $values ),    #$processor{'out'}{'array'}->($table)
      $self->flush_insert($table) if ( !$set or !int($_) ) and !$lwhere;
    return undef;
  };
  $self->{'insert_hash'} ||= sub {
    my $self = shift;
    return $self->insert_data(@_) unless $self->{'driver'} =~ /pg/i;
    my $table = shift || $self->{'current_table'};
    my $ret;
    for (@_) {
      #$self->log( 'dev',"insert_hash run "),
      $ret += $self->update( $table, undef, $_ );
    }
    return $ret;
  };
  #=z
  $self->{'cut'} ||= sub {
    my $self = shift;
    return $_[0] unless $_[1];
    #return $_[0] = substr( $_[0], 0, $_[1] - ( ( $self->{'codepage'} eq 'utf-8' and $self->{'driver'} =~ /mysql/ ) ? 2 : 0 ) ),
    #  ( $self->{'codepage'} eq 'utf-8' ? $_[0] =~ s/[\xD0\xD1]+$// : () );
    return $_[0] = substr( $_[0], 0, $_[1] );
  };
  #=cut
  $self->{'insert_data'} ||= sub {
    my $self = shift;
    #$self->log('dmp','insertdata=',Dumper(\@_));
    my $table = ( shift or $self->{'current_table'} );    #or $self->{'tfile'}
    #$self->log('dev','hash!', $table);
    #$processor{'out'}{'hash'} ||= sub {
    #my $self = shift;
    #my $table = ( shift or $self->{'tfile'} );
    for my $hash (@_) {
      #$self->log('dev','hash1=',Dumper($hash));
      #for my $col ( keys %$hash ) {
      #$self->log('dev','hash col',$col );
      #$self->log('dev','hash col2',$col , $hash->{$col}{'path'});
      #$self->log('dev','hash col2',$col , $hash->{$col}{'path'});
      next if !$hash;
      #$self->log('dev',"def for $_", $self->{'table'}{$table}{$_}{'array_insert'}),
      #$self->log('dev',"hash[$hash]",Dumper($hash) ) if ref $hash eq 'REF';
      $hash->{$_} = (
        $self->{'table'}{$table}{$_}{'default_insert'}
          or ( $self->{'table'}{$table}{$_}{'array_insert'} ? $self->{'table'}{$table}{$_}{'default'} : undef )
        ),
        #$self->log('dev','hash def',$_, $hash->{$_}),
        for grep { !defined $hash->{$_} }    #$self->{'table'}{ $table }{$_}{'array_insert'} and
        keys %{ $self->{'table'}{$table} };
#$self->log('dev','hash next insert_min', $hash->{$col}, grep { $self->{'table'}{$table}{$_}{'insert_min'} and $hash->{$_} }          keys %{ $self->{'table'}{$table} }),
#$self->log('dev','hash2=',Dumper($hash),
#grep { $self->{'table'}{$table}{$_}{'insert_min'} and !$hash->{$_} } keys %{ $self->{'table'}{$table} }
#),
#$self->log('dev','SKIP'),
      next if                                #!$hash->{$col}
        #and !(grep { $self->{'table'}{$table}{$_}{'insert_min'} } keys %{ $self->{'table'}{$table} })
        #or
        grep { $self->{'table'}{$table}{$_}{'insert_min'} and !$hash->{$_} } keys %{ $self->{'table'}{$table} };
      #$self->log('dev','hash1');
#########not here
      $self->handler_insert0( $table, $hash );
      #if $self->{'handler_insert0'};
#########not here
      #$self->log('dev','hash3=',Dumper($hash));
      #( $self->{'filter_handler'} ? $self->{'filter_handler'}->($hash) : () ), next
      #if grep { $self->{'table'}{$table}{$_}{'skip_mask'} and $hash->{$_} =~ /$self->{'table'}{ $table }{$_}{'skip_mask'}/i }
      #keys %{ $self->{'table'}{$table} };
      #$self->log('filter', 'f1', $self->{'table_param'}{$table}{'filter'});
      next
        if ref $self->{'table_param'}{$table}{'filter'} eq 'CODE'
          and $self->{'table_param'}{$table}{'filter'}->( $self, $hash );
      #$self->handler_insert( $table, $hash );
      $self->handler_insert( $table, $hash );    # if $self->{'handler_insert'};
      $self->stem_insert( $table, $hash );
      #$self->log('dev',"lenCUT[$hash->{$_}]"),
      $self->cut( $hash->{$_}, $self->{'table'}{$table}{$_}{'length'} )
#$hash->{$_} = substr( $hash->{$_}, 0, $self->{'table'}{$table}{$_}{'length'} - ( $self->{'codepage'} eq 'utf-8' ? 2 : 0 ) ),($self->{'codepage'} eq 'utf-8' ? $hash->{$_} =~ s/[\xD0\xD1]+$// : ()),
#$self->log('dev',"lenCUT[$self->{'codepage'}][$hash->{$_}]"),
        for grep {
        ( $self->{'table'}{$table}{$_}{'type'} eq $self->{'char_type'} )
          and $self->{'table'}{$table}{$_}{'length'}
          and length( $hash->{$_} ) >
          ( $self->{'table'}{$table}{$_}{'length'} )
        } keys %{ $self->{'table'}{$table} };
      #$processor{'out'}{'array'}->
      #$self->log('dev','ic from here=');
      local $self->{'table'}{$table} = $self->{'table'}{$table};
      #$self->log('dev', $self->{'table'}{$table});
      my $chanded;
      #$self->log('dev', 'set array_insert', $table, $_, ),
      (
        ++$chanded == 1
        ? (
          #$self->log('dev', 'flush on change', $table, $_),
          $self->flush_insert($table)
          )
        : ()
        ),
        $self->{'table'}{$table}{$_}{'array_insert'} = 1
        for grep {
        defined $hash->{$_}
          and length $hash->{$_}
          #and ($hash->{$_} ne $self->{'table'}{$table}{$_}{'default'} )
          and keys %{ $self->{'table'}{$table}{$_} } and !$self->{'table'}{$table}{$_}{'array_insert'}
        } keys %{ $self->{'table'}{$table} };
      #$self->log('dmp','insertdata2($table)=',Dumper(\@_));
      $self->insert_cached(
        $table,
        \@{$hash}{
          $self->insert_order($table)
            #sort   { $self->{'table'}{$table}{$b}{'order'} <=> $self->{'table'}{$table}{$a}{'order'} }
            #grep { $self->{'table'}{$table}{$_}{'array_insert'} } keys %{ $self->{'table'}{$table} }
          }
      );
#########not here
      $self->handler_insert2( $table, $hash );
#########not here
    }
    #}
    return undef;
  };
  $self->{'insert_hash_hash'} ||= sub {
    my $self = shift;
    my $table = ( shift or $self->{'current_table'} );    #or $self->{'tfile'}
    for my $hash (@_) { $self->insert_hash( $table, values %$hash ); }
    return undef;
  };
  $self->{'q_file'} ||= sub {
    my $self       = shift;
    my $table      = shift || $self->{'current_table'};
    my $search_str = shift;
    my %tparam;
    #return () if $self->{'sphinx'};
    #if ( $self->{'table'}{$table}{'name'} and $self->{'table'}{$table}{'ext'} and $search_str =~ /^\s*(\S+)\.+(\S+)\s*$/ ) {
    if (  $self->{'table'}{$table}{'name'}
      and $self->{'table'}{$table}{'ext'}
      and $search_str =~ m{^([^/|"]+[^\s/|"])\.([^/\."|]+)$} )    #"
    {
      %tparam = ( 'name' => $1, 'ext' => $2 );
    } elsif ( $self->{'table'}{$table}{'tiger'} and $search_str =~ /^\s*([A-Z0-9]{39})\s*$/i ) {
      %tparam = ( 'tiger' => uc $1 );
    }
    return %tparam;
  };
  $self->{'where_body'} ||= sub {
    my $self = shift;
    my ( $param_orig, $param_num, $table, $after ) = @_;
    my $param = { %{ $param_orig || {} } };
    #my $param = $param_orig;
    $table ||= $self->{'current_table'};
    my ( $search_str_add, $ask, $close );
    #$self->log('dev', 'where_body', 1, $table, %$param, $self->{'current_table'});
    my $questions = 0;
    map ++$questions, grep defined( $param->{ $_ . $param_num } ),
      @{ $config{'user_param_founded'} || [ 'q', keys %{ $self->{'table'}{$table} } ] };
    #$self->log('dev', 'recstop' , $param_num),
    return if ( $param_num and !$questions ) or ++$self->{'rec_stop'} > 20;
    my $first      = 1;
    my $local_cond = 0;
    #my ( $tq, $rq, $vq ) = sql_quotes();
    #$self->log('dev', 'where_body', 1.1, $param->{ 'q' . $param_num });
    while ( defined( $param->{ 'q' . $param_num } ) and $param->{ 'q' . $param_num } =~ s/(\w+\S?[=:](?:".+?"|\S+))// ) {
      #$self->log('dev', 'where_body', 1.2, $param->{ 'q' . $param_num }, $1);
      #$self->log('dev', 'where_body selected', $1);
      #$self->log('dev', 'where_body selected',
      #get_params_one( $param, $1 );
      local $_ = $1;
      s/^(\S+):/$1=/;
      my $lparam = get_params_one( undef, $_ );
      $lparam->{$_} =~ s/^"|"$//g, $param->{$_} = $lparam->{$_} for keys %$lparam;
      #$self->log('dev', 'where_body selected', $1,  %$param); #%$lparam,
    }
    #$self->log('dev', 'where_body', 2);
    for my $preset ( $param->{ 'q' . $param_num } =~ /:(\S+)/g ) {
      for my $sets ( keys %{ $config{'preset'} } ) {
        if ( $config{'preset'}{$sets}{$preset} ) {
          $param->{ 'q' . $param_num } =~ s/:$preset//;
          for ( keys %{ $config{'preset'}{$sets}{$preset}{'set'} } ) {
            $param->{ $_ . $param_num } .=
              ( $param->{ $_ . $param_num } ? ' ' : '' ) . $config{'preset'}{$sets}{$preset}{'set'}{$_};
          }
        }
      }
    }
    my $search_str = $param->{ 'q' . $param_num };
    #$self->log( 'dev', 'where_body', 3, $search_str, $param_num );
    my $glueg = $param->{ 'glueg' . $param_num } eq 'or' ? ' OR ' : ' AND ';
    my $gluel = $param->{ 'gluel' . $param_num } eq 'or' ? ' OR ' : ' AND ';
    $glueg = ' XOR ' if $self->{'enable_xor_query'} and $param->{ 'glueg' . $param_num } eq 'xor';
    $gluel = ' XOR ' if $self->{'enable_xor_query'} and $param->{ 'gluel' . $param_num } eq 'xor';
    if ( my ($days) = $param->{ 'search_days' . $param_num } =~ /(\d+)/ and $1 and %{ $self->{'table'}{$table}{'time'} or {} } )
    {
      $ask .= " " . ( $self->{'no_column_prepend_table'} ? () : "$tq$self->{'table_prefix'}$table$tq." ) . "$rq" . "time$rq ";
      if   ( $param->{ 'search_days_mode' . $param_num } eq 'l' ) { $ask .= '<'; }
      else                                                        { $ask .= '>'; }
      $days = int( time() ) - $days * 24 * 60 * 60;
      $ask .= '= ' . ( $self->{'sphinx'} ? $days : $self->squotes($days) );
    }
    #$self->log('dev', 'online1', Dumper($param));
    if ( !$self->{'no_online'} and defined( $param->{ 'online' . $param_num } ) ) {
      if ( $param->{ 'online' . $param_num } eq 'on' ) { $param->{ 'online' . $param_num } = $config{'online_minutes'}; }
      #$self->log('dev', 'online2', Dumper($param));
      if ( $param->{ 'online' . $param_num } > 0 ) {
        $param->{ 'live' . $param_num } = int( time() ) + $self->{'timediff'} - int( $param->{ 'online' . $param_num } ) * 60;
        $param->{ 'live_mode' . $param_num } = 'g';
        #$self->log('dev', $param->{ 'live' . $param_num });
      }
    }
    if (
          $self->{'path_complete'}
      and $param->{ 'path' . $param_num }
      and !( $param->{ 'path' . $param_num } =~ /^[ !\/\*]/ )
      and ( $param->{ 'path' . $param_num } ne 'EMPTY' )
      and !( (
          !$self->{'no_regex'}
          and
          ( $param->{ 'path' . $param_num } =~ /^\s*reg?e?x?p?:\s*/i or $param->{ 'path' . '_mode' . $param_num } =~ /[r~]/i )
        )
      )
      )
    {    # bad idea ?
      $search_str_add .= ' /' . $param->{ 'path' . $param_num } . '/ ';
      delete $param->{ 'path' . $param_num };
    }
    for my $item ( (
        sort {
          $self->{'table'}{$table}{$b}{'weight'} <=> $self->{'table'}{$table}{$a}{'weight'}
            || $self->{'table'}{$table}{$b}{'order'} <=> $self->{'table'}{$table}{$a}{'order'}
        } grep {
               $self->{'nav_all'}
            or $self->{'table'}{$table}{$_}{'nav_num_field'}
            or $self->{'table'}{$table}{$_}{'nav_field'}
            or $self->{'table'}{$table}{$_}{'nav_hide'}
        } keys %{ $self->{'table'}{$table} }
      ),
      @{ $self->{'table_param'}{$table}{'join_fields'} }
      )
    {
      #$self->log('dev', 'where_body', 4, $item);
      next
        if $self->{'no_index'}
          or $self->{'ignore_index'}
          or $self->{'table_param'}{$table}{'no_index'}
          or $self->{'table_param'}{$table}{'ignore_index'}
          or $param->{ $item . $param_num } !~ /\S/;
      #$self->log('dev', 'where_body', 4, $item);
      my $lask;
      ++$local_cond, $lask .= $gluel if $ask;
      my $pib = $param->{ $item . $param_num };
      $pib =~ s/^\s*|\s*$//g;
      my ( $group_not, $group_not_close );    #,
      #$self->log('dev', 'where_body', 5, $item, $self->{$item}, $_, 'C=', $config{$item});
      $pib =~ s/\:$_(\W|$)/$config{$item}{$_}{'to'}$1/g and ++$group_not
        for grep { defined $config{$item}{$_}{'to'} } keys %{ ref $config{$item} eq 'HASH' ? $config{$item} : {} };
      #for grep {defined $self->{$item}{$_}{'to'}} keys %{ $self->{$item} or {}};
      next if $pib eq '';
      my ( $brstr, $space );
      if ( $self->{'table'}{$table}{$item}{'no_split_space'}
        or ( !$self->{'no_regex'} and ( $pib =~ /\s*reg?e?x?p?:\s*/ or $param->{ $item . '_mode' . $param_num } =~ /[r~]/i ) ) )
      {
        #$self->log('dev', 'SPA')    ;
        $space = '\s+';
      } else {
        $brstr = '|\s+';
      }
      #$brstr = $space . '\&+' . $space . '|' . '\|+' . '|(\s+AND\s+)|\s+OR\s+' . $brstr;
      $brstr = $space . '\&+' . $space . '|' . $space . '\|+' . $space . '|(\s+AND\s+)|\s+OR\s+' . $brstr;
      my $num_cond = 0;
      my $next_cond;
      my $llask;
      do {
        my ( $pi, $cond );
        $cond = $next_cond;
        #$self->log('dev', "split[$pib] with  [($brstr)]");
        if ( $pib =~ /($brstr)/ ) { ( $pib, $pi, $next_cond ) = ( $', $`, $1 ); }
        else                      { $pi = $pib, $pib = ''; }
        if ( $num_cond++ ) {
          #$self->log('dev', "andf1, $llask");
          if ( $cond =~ /(and)|\&+/i ) { $llask .= ' AND '; }
          elsif ( $self->{'enable_xor_query'} and $cond =~ /(xor)/i ) { $llask .= ' XOR '; }    #too slow
          elsif ( $cond =~ /(or)|\|+|\s+|^$/i ) { $llask .= ' OR '; }
          #$self->log('dev', "andf2, $llask");
        }
        #$self->log('dev', "$pib, $pi, $next_cond, $llask");
        my $not = 1 if ( !$self->{'no_slow'} or $self->{'table'}{$table}{$item}{'fast_not'} ) and ( $pi =~ s/^\s*[\!\-]\s*//g );
        $llask .= ' NOT ' . ( $group_not ? ( ++$group_not_close, ' ( ' ) : '' ) if $not;
        #$self->log('dev', "not1 $llask");
        if ( $self->{'table_param'}{$table}{'name_to_base'}{$item} ) {
          #$self->log('dev', "here", $self->{'table_param'}{$table}{'name_to_base'}{$item});
          #$llask .= ' ' . $tq . $self->{'table_prefix'} . $self->{'table_param'}{$table}{'name_to_base'}{$item} . $tq . ' ';
          $llask .= ' ' . $self->{'table_param'}{$table}{'name_to_base'}{$item} . ' ';
        } else {
          $llask .=
            " " . ( $self->{'no_column_prepend_table'} ? () : "$tq$self->{'table_prefix'}$table$tq." ) . "$rq$item" . "$rq ";
        }
        my ($dequote_);    #, $dequotesl
        #$self->log('dev', !$self->{'no_regex'});
        if ( !$self->{'no_regex'}
          and ( $pi =~ s/^\s*reg?e?x?p?:\s*//ig or $param->{ $item . '_mode' . $param_num } =~ /[r~]/i ) )
        {
          $llask .= ' REGEXP ';
          #++$dequotesl;
        } elsif ( !$self->{'no_soundex'}
          and ( $pi =~ s/^\s*sou?n?d?e?x?:\s*//ig or $param->{ $item . '_mode' . $param_num } =~ /[s@]/i ) )
        {
          $llask .= ' SOUNDS LIKE ';
        } elsif ( $pi =~ /[*?]/ ) {
          $pi =~ s/%/\\%/g;
          $pi =~ s/_/\\_/g and ++$dequote_;
          $pi =~ tr/*?/%_/;
          next if $self->{'no_empty'} and ( $pi !~ /\S/ or $pi =~ /^\s*[%_]+\s*$/ );
          #$self->log('dev', 'pi_:', $pi);
          $llask .= ' LIKE ';
        }
        #} else {
        elsif ( $param->{ $item . '_mode' . $param_num } =~ /notnull/i ) { $llask .= 'IS NOT NULL'; next; }
        elsif ( $param->{ $item . '_mode' . $param_num } =~ /null/i )    { $llask .= 'IS NULL';     next; }
        elsif ( $param->{ $item . '_mode' . $param_num } =~ /[g>]/i ) { $llask .= ( $not ? '<' : '>' ) . '= '; }
        elsif ( $param->{ $item . '_mode' . $param_num } =~ /[l<]/i ) { $llask .= ( $not ? '>' : '<' ) . '= '; }
        else                                                          { $llask .= '= '; }
        #}
        $pi =~ s/(^\s*)|(\s*$)//g;
        $pi = psmisc::human( 'number_k', $pi ) if $item eq 'size';
        $work{ 'bold_' . $item } .= ' ' . $pi;
        if ( !( $self->{'sphinx'} and $self->{'table'}{$table}{$item}{'nav_num_field'} and $pi =~ /^\d+$/ ) ) {
          $pi = ( $pi ne 'EMPTY' ? $self->squotes($pi) : $self->squotes('') );
        }
        $pi =~ s|\\_|\_|g if $dequote_;
        #$self->log('dev', '$pi:', $pi, $dequotesl);
        #$pi =~ s|\\{2}|\\|g if $dequotesl;
        #$self->log('dev', '$pi a:', $pi);
        $llask .= $pi;
        #$self->log('dev', '$llask:', $llask);
      } while ( $pib and $num_cond < 50 );
      #$self->log('dev', '1 $llask:', $llask);
      $llask .= " ) " x $group_not_close;
      $group_not_close = 0;
      $lask .= ( $num_cond > 1 ? ' ( ' : '' ) . $llask . ( $num_cond > 1 ? ' ) ' : '' );
      #$self->log('dev', '1 $lask:', $lask);
      $ask .=
        ( ( !$self->{'no_slow'} or $self->{'table'}{$table}{$item}{'fast_not'} )
          and $param->{ $item . '_mode' . $param_num } =~ /[n!]/i ? ' NOT ' : ' ' )
        . $lask;
      #$self->log('dev', '1 $ask:', $ask);
    }
    $work{'search_str'} .= ' ' . $search_str . ' ' . $search_str_add;
    #$self->log('dev', 'Sstr', $work{'search_str'});
    if ( $search_str =~ /\S/ or $search_str_add ) {
      unless ( $param->{'page'} > 1 or $param->{'order'} or $param->{'no_querystat'} ) {
        #$self->log('dev', '2 $ask:', $search_str);
        #$self->dump_cp();
        ++$work{'query'}{$search_str};
        map { ++$work{'word'}{$_} } grep $_, split /[\W_]+/, $search_str;    #if $self->{'codepage'} ne 'utf-8';
      }
      #$self->log('dev', '2 $ask:', $ask, Dumper %work);
      ++$local_cond, $ask .= $gluel if $ask;
      #$self->log('dev', '3 $ask:', $ask, $search_str, $search_str_add);
      $param->{ 'adv_query' . $param_num } = 'on'
        if $search_str =~ /\S+\*+\s*/
          or $search_str =~ /(^|\s+)(([+\-><~]+\()|\")[^"()]*\S+\s+\S+[^"()]*[\"\)]($|\s+)/
          or $search_str =~ /(^|\s+)[\~\+\-\<\>]\S+/;
      $search_str =~ s/(\S+)/\+$1/g
        if $param->{ 'adv_query' . $param_num } eq 'on'
          and !( $search_str =~ /((^|\s)\W+\S)|\S\W+(\s|$)/ )
          and $search_str =~ /\s/;
      $ask .= ( $search_str =~ s/^\s*\!\s*// ? ' NOT ' : '' );
      #!
      if ( !$self->{'use_q_file_fallback'} and my %tparam = $self->q_file( $table, $search_str ) ) {
        #$search_str =~ /^\s*(\S+)\.+(\S+)\s*$/ and $self->{'table'}{$table}{'name'} and $self->{'table'}{$table}{'ext'} ) {
        #my %tparam = ( 'name' => $1, 'ext' => $2 );
        $ask .= ' ( ' . $self->where_body( \%tparam, undef, $table ) . ' ) ';
      } elsif ( !$self->{'sphinx'}
        and !$self->{'no_slow'}
        and $search_str =~ /^\s*\*+\S+/
        and $self->{'table'}{$table}{'path'}
        and $self->{'table'}{$table}{'name'}
        and $self->{'table'}{$table}{'ext'} )
      {
        my %tparam = ( 'path' => '/' . $search_str, 'name' => $search_str, 'ext' => $search_str, 'gluel' => 'or' );
        $ask .= ' ( ' . $self->where_body( \%tparam, undef, $table ) . ' ) ';
        #!
      } else {
        #my $search_str = $search_str . $search_str_add;
        #$self->log('ss', $search_str);
        $search_str .= $search_str_add;
        $self->{'handler_search_str'}->( $table, \$search_str ) if ref $self->{'handler_search_str'} eq 'CODE';
        my $search_str_stem = $self->stem($search_str)
          if grep { $self->{'table'}{$table}{$_}{'stem'} } keys %{ $self->{'table'}{$table} };
        #$self->log('ss1',$param_num, $search_str);
        local $param->{ 'adv_query' . $param_num } = 'on'
          if $self->{'ignore_index'}
            or $self->{'table_param'}{$table}{'ignore_index'};
#$self->log( 'dev', 'where_body', 6, $search_str, $table, $ask, grep { $self->{'table'}{$table}{$_}{'fulltext'} } keys %{ $self->{'table'}{$table} } );
        if ( (    #!$self->{'use_sphinx'} and
            !$param->{ 'adv_query' . $param_num } and (
              $self->{'ignore_index_fulltext'} or !grep {
                $self->{'table'}{$table}{$_}{'fulltext'}
                  or ( $self->{'sphinx'} and $self->{'table'}{$table}{$_}{'sphinx'} )
              } keys %{ $self->{'table'}{$table} }
            )
          )
          or !$self->{'match'}
          )
        {
          #my $sl = $self->squotes( '%' . $search_str . '%' );
          #$self->log( 'dev', 'where_body', 7, $search_str,  $table , $ask);
          $_ = join(
            ' OR ',
           #map{ "$rq$_$rq LIKE $sl"} grep{ defined $self->{'table'}{$table}{$_}{'fulltext'}} keys %{ $self->{'table'}{$table} }
            map {
              "$rq$_$rq LIKE "
                . $self->squotes( ( (
                         !$self->{'no_slow'}
                      and $self->{'table'}{$table}{$_}{'like_bef'}
                      || $self->{'table_param'}{$table}{'like_bef'}
                      || $self->{'like_bef'}
                  ) ? '%' : ''
                )
                . $search_str . '%'
                )
              } grep {
              $self->{'table'}{$table}{$_}{'q'} || $self->{'table'}{$table}{$_}{'nav_field'}
                and !$self->{'table'}{$table}{$_}{'q_skip'}
              } keys %{ $self->{'table'}{$table} }
          );
          #$self->log( 'dev', 'where_body', 8, $_ , $ask);
          $ask .= ' ( ' . $_ . ' ) ' if $_;
          #$self->log( 'dev', 'where_body', 9, $search_str,  $ask );
        } else {
          #$self->log( 'dev', 'where_body', 10, $search_str );
          $ask .= $self->match( $param, $param_num, $table, $search_str, $search_str_stem );
        }
      }
    }
    #$self->log( 'dev', 'ask1:', $ask);
    #$ask = ( $local_cond > 1 ? ' ( ' : '' ) . $ask . ( $local_cond>1 ? ' ) ' : '' );
    if ( !$self->{'sphinx'} and $local_cond > 1 ) { $ask = ' ( ' . $ask . ' ) '; }
    #$self->log( 'dev', 'ask2:', $ask);
    $ask = $glueg . $ask if $after and $ask;
#$self->log( 'dev', 'ask3:', $ask);
#$self->log(      'dbg', $local_cond, ' lret: ', $ask . ( $ask and $close ? ' ) ' x $close : '' ),      'after=', $after, '$glueg', $glueg, $param->{'search_prev'},    );
#"RET=[$ask]"
#
#. ( $ask and $close ? ' ) ' x $close : '' )
#. $self->where_body(
#$param, $param_num + ( defined($param_num) ? 1 : ( $param->{'search_prev'} ? 0 : 1 ) ),
#$table, ( $ask ? 1 : 0 )
#)
#
#);
    return
        $ask
      . ( $ask and $close ? ' ) ' x $close : '' )
      . $self->where_body( $param, $param_num + ( defined($param_num) ? 1 : ( $param->{'search_prev'} ? 0 : 1 ) ),
      $table, ( $ask ? 1 : 0 ) );
  };
  $self->{'where'} ||= sub {
    #sub where {
    my $self = shift;
    my ( $param, undef, $table ) = @_;
    #my $where = sql_where_body(@_);
    $self->{'rec_stop'} = 0;
    my $where = $self->where_body(@_);
#$self->log( 'dbg', "WHERE($table):[$where]", Dumper(\@_) , "$self->{'cp_in'} -> $self->{'codepage'} [extra=$self->{'table_param'}{$table}{'where_extra'}]");
#return ' WHERE ' . scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $where ) if $where;
    if ( $self->{'table_param'}{$table}{'where_extra'} ) {
      #$self->log( 'dbg','where_extra', $self->{'table_param'}{$table}{'where_extra'});
      $where .= (' AND ') if length $where;
      $where .= $self->{'table_param'}{$table}{'where_extra'};
    }
    return ' WHERE ' . $where if $where;
    return undef;
  };
  $self->{'count'} ||= sub {
    #sub query_count {
    my $self = shift;
    my ( $param, $table ) = @_;
    #my ( $tq, $rq, $vq ) = sql_quotes();
    $self->limit_calc( $self, $param, $table );
    return undef
      if $self->{'query_count'}{$table}++
        or $self->{'ignore_index'}
        or $self->{'table_param'}{$table}{'ignore_index'};
    my @ask;
    $param->{'count_f'} = 'on' if $self->{'page'} eq 'rnd';
    push( @ask, ' COUNT(*) ' ) if $param->{'count_f'} eq 'on';
    push( @ask, " SUM($tq$table$tq.$rq$_$rq) " )
      for grep(
      ( ( $self->{'allow_count_all'} or $self->{'table'}{$table}{$_}{'allow_count'} ) and $param->{ 'count_' . $_ } eq 'on' ),
      sort keys %{ $self->{'table'}{$table} } );
    if (@ask) {
      my %tmp_para = %$param;
      local $self->{'dbirows'};
      delete $tmp_para{'online'};
      my $where = $self->where( \%tmp_para, undef, $table );
      return unless $self->{'allow_null_count'} or $where;
      my $from = join ' ', $tq . $self->{'table_prefix'} . $table . $tq, $self->join_what( undef, $param, $table );
      my $req = ' SELECT ' . join( ' , ', @ask ) . " FROM $from $where ";
      psmisc::flush();
#$self->log( 'dmp', 'query:[', @_, '] = ', scalar @hash, ' per', psmisc::human( 'time_period', $tim->() ), 'err=',$self->err() );
      @ask = values %{ $self->query($req)->[0] };
      #@ask = values %{ $self->line($req) };
      $self->{'stat'}{'found'}{'files'} = pop(@ask) if $param->{'count_f'} eq 'on';
      for (
        grep( ( $self->{'table'}{$table}{$_}{'allow_count'} and $param->{ 'count_' . $_ } eq 'on' ),
          sort keys %{ $self->{'table'}{$table} } )
        )
      {
        my $t = pop(@ask);
        $self->{'stat'}{'found'}{$_} = $t if $t;
      }
    }
    $self->{'calc_count'}->( $self, $param, $table );
    return undef;
  };
  $self->{'can_select'} ||= sub {
    my $self = shift;
    my ( $param, $table, ) = @_;
    my $where = $self->where( $param, undef, $table );
    return $where if $where;
    return '0E0' if $self->{'use_sphinx'} and $self->{'sphinx_dbi'} and length $param->{'q'};
  };
  $self->{'select'} ||= sub {
    my $self = shift;
    my ( $table, $param, $opt ) = @_;
    $opt ||= {};
    $self->{'current_table'} = $table;
#$self->log( 'dbg',  "SELECTR[$self->{'sphinx'}]",  ,Dumper($param));
#$self->log( 'dbg',  "$self->{'cp_in'} -> $self->{'codepage'}");
#return ' WHERE ' . scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $where ) if $where;
#$self->log( 'dbg',  'q1', scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $self->select_body( $self->where($param), $param, $table ) ));
#$self->log( 'dbg',  'q2', $self->select_body( $self->where($param, undef, $table), $param, $table ) );
#$self->log( 'dbg',  'q3',  $self->where($param));
    my $select;
    my $ids  = [];
    my $idsh = {};
    my %id;
    my $ret = [];
    $self->{'founded_max'} = $self->{'dbirows'} = 0;
    #my ($fail_q, $fail_n);
    my @fail;
    my @selects;
    my $file_fallback;
    my $n;
    my $post_process = sub ($) {
      my ($ret) = @_;
      for my $r (@$ret) {
        $r->{$_} ||= $idsh->{ $r->{'id'} }{$_} for keys %{ $idsh->{ $r->{'id'} } || {} };
        #$self->log( 'dev123',  Dumper $r,  );
      }
      @$ret = sort { $idsh->{ $a->{'id'} }{'n'} <=> $idsh->{ $b->{'id'} }{'n'} } @$ret;
      #@$ret = sort { $ids{ $a->{'weight'} } <=> $ids{ $b->{'weight'} } } @$ret;
      #$self->log( 'dev124', Dumper $ret );
      #$self->log( 'devFail', Dumper \@fail);
      for (@fail) {
        next if scalar @$ret < $_->{'n'};
        $ret->[ $_->{'n'} ]{'__fulltext_fail'} = $_->{'q'};
        #$self->log( 'setFail', $_->{'n'});
      }
      @fail = ();
    };
    my $do_select = sub {
      #my ($s, $ids) = @_;
      #$self->log('do_select', Dumper \@_);
      #        $self->log('devids', Dumper $ids);
      my $count;
      for my $s (@_) {
        #my ( $select, $ids );
        my ($select);
        #( $select, $ids ) = $s->() if psmisc::is_code $s;
        my ( $count_add, $idst );
        ( $select, $idst, $count_add ) = $s->() if psmisc::is_code $s;
        if ( psmisc::is_array_size $idst) {
          $ids = $idst;
          #$self->log('do_select', $count_add, $self->{'limit_offset'}, $self->{'sphinx_dbi'}{'limit_offset'});
          my $nn = $self->{'sphinx_dbi'}{'limit_offset'} || $self->{'limit_offset'};
          $idsh = { map { $_->{'n'} //= ++$nn; $_->{'id'} => $_ } @$ids };
        }
        $count += $count_add;
        ( $select, ) = $s if psmisc::is_hash $s;
        local $self->{'limit_body'} = sub { }
          if psmisc::is_array_size $ids;
        #$self->log('select extracted:', $s, $select, Dumper $param);
        #my $idsh = {};
        if ( psmisc::is_hash($select) ) {
          for my $s ( sort { $select->{$a} <=> $select->{$b} } keys %$select ) {
            #$self->log('r', $s, ':', Dumper $select->{$s});
            my $r;
            #sleep 2;
            $r =
              $self->{'shard_dbis'}{ $select->{$s} }
              ->query( scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $self->select_body( $s, $param ) ) )
              if $s;
            next unless $r;
            #            map {
            #$self->log('r1', Dumper $idsh->{$_->{id}});
            # $_->{id} //= psmisc::join_url($_) } @$r;    #unless $self->{'use_sphinx'};
            for my $l (@$r) {
              #$self->log('r1',$l, $idsh->{$l->{id}});
              #$l->{$_} ||= $idsh->{$l->{id}}{$_} for keys %{$idsh->{$l->{id}} || {}};
              $l->{id} //= psmisc::join_url($l);
            }
            #$self->log('r1', Dumper $r);
            $r = [ grep { !$id{ $_->{id} }++ } @$r ];
            $post_process->($r);
            #     @$r = sort { $idsh->{ $a->{'id'} }{'n'} <=> $idsh->{ $b->{'id'} }{'n'} } @$r;
            # for (@fail) {next if scalar @$r < $_->{'n'};
            #      $r->[ $_->{'n'} ]{'__fulltext_fail'} = $_->{'q'}
            #}
            $count += scalar @$r;
            $opt->{row}->(@$r), psmisc::code_run( $opt->{flush} ),
              #$self->log('flush!'),
              next if psmisc::is_code $opt->{row};
            push @$ret, @$r;
          }
        } else {
          for my $select ( psmisc::array $select) {    #select from sphinx
            my $r;
            #sleep 2;
            $r = $self->query(
              scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'codepage'}, $self->select_body( $select, $param ) ) )
              if $select;
            next unless $r;
            #$self->log('SSSs', "sp[$self->{'use_sphinx'}]");
            map { $_->{id} //= psmisc::join_url($_) } @$r;    # unless $self->{'use_sphinx'};
            $r = [ grep { !$id{ $_->{id} }++ } @$r ];
            #my %already = map { $_->{'id'} => 1 } @$ret;
            #$self->log('SSSs', Dumper $r);
            #$self->log('SSSsRRb', Dumper $ret);
            #$self->log('SSSsRRbr', Dumper $r);
            #push @fail, { 'n' => scalar @$ids, 'q' => $param->{'q'} } if $n ;
            #$self->log('SSSsid5', Dumper \%id);
            #$ret +=  scalar @$r;
            $count += scalar @$r;
            push @$ret, @$r;
            #$self->log('SSSsRRa', Dumper $ret);
            #$self->log('SSSsid6', Dumper \%id);
            #++$id{$_->{id}} for @$r;
            #push @$ids, grep { !$already{ $_->{id} } } @$r;
            #$self->log('SS', scalar @$ret , 'L', $self->{'limit'}, map { $_->{'id'}  } @$r);
          }
        }
        #$self->log('cnts:', $count, scalar @$ret , $self->{'limit'});
        #last if @$ret >= $self->{'limit'};
        last if $count >= $self->{'limit'};
      } continue {
        ++$n;
        #$self->log('continue', $n);
      }
      return $count;
    };
    push @selects, sub {    # try LIKE by name
      #      $self->log( 'dbg',  'selectrun', __LINE__);
      my $ask;
      my $search_str = $param->{'q'};
      if ( my %tparam = $self->q_file( $table, $search_str ) ) {
        #$self->log( 'qf', %tparam );
        #$search_str =~ /^\s*(\S+)\.+(\S+)\s*$/ and $self->{'table'}{$table}{'name'} and $self->{'table'}{$table}{'ext'} ) {
        #my %tparam = ( 'name' => $1, 'ext' => $2 );
        $ask .= ' ( ' . $self->where_body( \%tparam, undef, $table ) . ' ) ';
      }
      #$self->log('S1', $ask);
      #$file_fallback = 1, return ' WHERE ' . $ask if $ask;
      }
      if $self->{'use_q_file_fallback'} and !$self->{'sphinx'};
    push @selects, sub {
      #      $self->log( 'dbg',  'selectrun', __LINE__);
      #$self->log( 'dbg',  'selectrun2 sph');
      my $ids = [];
      my %id;
      if (  $self->{'use_sphinx'}
        and $self->{'sphinx_dbi'}
        and length $param->{'q'}
        and ( $file_fallback or !$self->q_file( $table, $param->{'q'} ) ) )
      {
        #$self->log( 'dbg',  'selectin', __LINE__);
        ( $tq, $rq, $vq ) = $self->quotes();
        local $self->{'sphinx_dbi'}->{'option'}{'max_query_time'} = 2000 if $config{'client_bot'};
        #     my %already = map { $_->{'id'} => 1 } @$ids, @$ret;
        my $idsl = [];
        #        $self->log('SSSsid1', Dumper \%id);
        push @$idsl, grep { !$id{ $_->{id} }++ } @{ $self->{'sphinx_dbi'}->select( $table, $param ) };
        #        $self->log('SSSsid2', Dumper \%id);
        #my $ids = $self->{'sphinx_dbi'}->select( $table, $param );
        #++$id{$_->{id}} for @$ids;
        $self->{'founded_max'} = $self->{'sphinx_dbi'}{'option'}{'cutoff'};
        #$self->log ('d1', "fmax", $self->{'founded_max'}, Dumper $ids,$idsl);
        #		$self->log ('cnt',scalar @$ids , scalar  @$idsl ,  $self->{'limit'});
        if (
          ( @$ids + @$idsl < $self->{'limit'} )    #and (!$self->{'use_sphinx'} or !$config{'client_bot'})
          )
        {
          #warn "limit[]"
          #          $self->log( 'dbg','q', $param->{'q'});
          #local $self->{'sphinx_dbi'}->{'select_append'} = ' OPTION ranker=wordcount ';
          ++$work{'fulltext_fail'} unless @$ids;
          local $param->{'q'} = $param->{'q'};
          for my $func ( sub { $_[0] =~ s/^\s*"\s*// and $_[0] =~ s/\s*"\s*$// }, sub { $_[0] =~ s/(\w\s+)(\w)/$1 | $2/g }, ) {
            if ( $func->( $param->{'q'} ) ) {
              local $param->{'no_querystat'} = 1;
              #$self->log( 'idn', scalar @$ids, scalar @$idsl );
              #my %already = map { $_->{'id'} => 1 } @$ids, @$ret;
              local $self->{'sphinx_dbi'}{'limit_minus'} = scalar @$idsl;
              local $self->{'sphinx_dbi'}{'limit_offset'};
              local $self->{'sphinx_dbi'}{'page'} = 0 if $self->{'sphinx_dbi'}{'limit_minus'};
              my $ids_add = $self->{'sphinx_dbi'}->select( $table, $param );
              $self->{'founded_max'} = $self->{'sphinx_dbi'}{'option'}{'cutoff'};
              #TODO: info about changed query
              #$self->log('dev', "setfail $#$ids:$ids->[$#$ids]{id};"),
              #$self->log('dev', "setfail ", scalar @$ids, scalar @$idsl , scalar @$ids_add),
              push @fail, { 'n' => scalar @$ids + scalar @$idsl, 'q' => $param->{'q'} } if @$ids_add;
              unless (@$ids_add) { ++$work{'fulltext_fail_or'}; }
              #$self->log('SSSsid3', Dumper \%id, $ids_add);
              push @$idsl, grep { !$id{ $_->{id} }++ } @$ids_add;
              #$self->log('SSSsid4', Dumper \%id, $idsl);
              #++$id{$_->{id}} for @$ids_add;
            }
            last if @$ids + @$idsl >= $self->{'limit'};
          }
        }
        #psmisc::dmp ('dbiSmin', $self->{'sphinx_dbi'}{'limit_minus'});
        #psmisc::dmp ('dbiSoff',    $self->{'sphinx_dbi'}{'limit_offset'});
        #psmisc::dmp ('dbimin',     $self->{'limit_minus'});
        #psmisc::dmp ('dbioff',    $self->{'limit_offset'});
        if (@$idsl) {
          #		$self->log(__LINE__, 'prep idsl');
          my $wheregen = sub {
            @_ = psmisc::array @_;
            #            $self->log('dmp','wheregen', Dumper \@_);
            return " WHERE ${rq}id${rq} IN (" . ( join ',', map { $_->{'id'} } @_ ) . ')' if @_;
            #();
          };
          #$self->log('joining',$select, 'sh=', $self->{'shard'},  Dumper $ids, $idsl);
          if ( !$self->{'sphinx'} and $self->{'shard'} ) {
            # $self->log('shard',keys %{$self->{'shard_dbis'}} );
            my %ids;
            for my $r (@$idsl) {
              for my $from ( reverse sort keys %{ $self->{'shard_dbis'} } ) {
                #$self->log('shardC',$from, $self->{'shard_dbis'}{$from}{database}, $self->{'shard_dbis'}{$from}{dbname});
                #                $self->log('shardC',$from, $r);
                if ( $r->{id} >= $from ) {
                  push @{ $ids{$from} ||= [] }, $r;
                  last;
                }
              }
            }
            #$self->log('sh', Dumper \%ids);
            $select = {};
            for my $from ( keys %{ $self->{'shard_dbis'} } ) {
              my $w = $ids{$from} || next;
              $select->{ $wheregen->($w) } = $from;    #scalar @{$ids{$from}};
              #$self->log('sh22', $from, $ids{$from});
            }
            #$self->log('sh22', Dumper $select,);
          } else {
            #		  $self->log('wgen', Dumper $select,);
            $select = $wheregen->($idsl);
            #			$self->log('simple', Dumper $select,);
          }
          push @$ids, @$idsl;
        }
      }
      local $self->{'limit_body'} = sub { }
        if @$ids;
      ( $tq, $rq, $vq ) = $self->quotes();
      #unless ($select) {
      #local $self->{'table'}{$table}{$table}{'ext'}{'nav_field'} = 0;
      #local $self->{'table'}{$table}{'ext'}{'q_skip'} = 1;
      #      $self->log( 'dev', "!$select and !$config{'client_bot'} and sp!$self->{'use_sphinx'}");
      my $count;
      if ( !$select and ( !$self->{'use_sphinx'} or !$config{'client_bot'} ) ) {
        if ( !$self->{'use_sphinx'} or !$self->{'no_sphinx_like'} ) {
          #$select = $self->where( $param, undef, $table );
          # $self->log( 'dev', "!$select and !$config{'client_bot'}");
          #$self->log( 'dbg',  'selectshrd', __LINE__);
          if ( !$self->{'sphinx'} and $self->{'shard'} ) {
            # $self->log('shard',keys %{$self->{'shard_dbis'}} );
            #$self->log('sh', Dumper \%ids);
            #$select = {};
            for my $from ( sort keys %{ $self->{'shard_dbis'} } ) {
              #my $w = $ids{$from}  || next;
              #$select->{ $wheregen->( $w ) } = $from;    #scalar @{$ids{$from}};
              #local $self->{limit} = $self->{limit} - $count;
              local $self->{'limit_from'} = $self->{'limit_offset'} + $count if $count;
              local $self->{'limit_minus'} = $count;
  # $self->log( 'limi', $from, $count, $self->{limit}, $self->{'limit_offset'}, $self->{'limit_from'}, $self->{'limit_minus'} );
              $select = {};
              $select->{ "/* $from */" . $self->where( $param, undef, $table ) } = $from;
              #$do_select->($select, $ids);
              $count += $do_select->($select);
              #$self->log('shard lst',  $from, $count, $self->{limit});
              $select = undef;
              last if $count >= $self->{limit};
              #$self->log('shard after',  $from, $count);
            }
            #$self->log( 'sh22', Dumper $param, $self->{limit} );
          } else {
            #            $self->log( 'noshard',);
            $select = $self->where( $param, undef, $table );
          }
        }
        $self->{'founded_max'} = 0;
      }
      #$self->log( 'S2', $select, Dumper \%id);
      #$self->log( 'S2', $select, Dumper $ids);
      return $select, $ids, $count;
    };
    #push @selects, $select if $select;
    #}
    #$self->log('devpredoselect',Dumper \@selects);
    my $count = $do_select->(@selects);
    #{'use_q_file_fallback'}
    #if (@$ids) {
    #my %byid = map { $_->{id} => $_ } @$ret;
    #for my $s (@$ids) { $byid{ $s->{id} }{$_} //= $s->{$_} for keys %$s; }
    #$self->log('devret', Dumper $ret);
    #$self->log('dev1', "sph[$self->{'use_sphinx'}]", Dumper $ids);
    if ( $self->{'use_sphinx'} and @$ids ) {
      my $n = 0;
      #my %ids = map { $_->{'id'} => ++$n } @$ids;
      #my %ids = map {$_->{'n'} = ++$n;  $_->{'id'} => $_ } @$ids;
      #$self->log( 'dev123', map { $_->{'id'} } @$ret);
      #$self->log( 'dev123',  Dumper \%ids );
      #$self->log( 'dev123',  Dumper $ids );
      #$self->log( 'dev123r',  Dumper $ret );
      $post_process->($ret);

=no
      for my  $r (@$ret) {
      	$r->{$_} ||= $idsh->{$r->{'id'}}{$_} for keys %{$idsh->{$r->{'id'}}||{}};
      #$self->log( 'dev123',  Dumper $r,  );
        
      }
      @$ret = sort { $ids{ $a->{'id'} }{'n'} <=> $ids{ $b->{'id'} }{'n'} } @$ret;
      #@$ret = sort { $ids{ $a->{'weight'} } <=> $ids{ $b->{'weight'} } } @$ret;
      #$self->log( 'dev124', Dumper $ret );
      #$self->log( 'devFail', Dumper \@fail);
 for (@fail) {
next if scalar @$ret < $_->{'n'};
      $ret->[ $_->{'n'} ]{'__fulltext_fail'} = $_->{'q'}
}
=cut

    }
    #$self->log( 'devFIN', $self->{'dbirows'}, $count, Dumper $ret );
    #}
    #$self->log( 'fnd', "$self->{'founded'}, $self->{'dbirows'},$count;" );
    #$self->log( 'devFIN', $self->{'dbirows'}, $count, Dumper $param );
    $self->{'dbirows'} ||= $count;
    return wantarray ? @$ret : $ret;
  };
  $self->{'select_log'} ||= sub {
    my $self = shift;
    my ( $table, $param, ) = @_;
    return $self->query_log( $self->select_body( $self->where( $param, undef, $table ), $param, $table ) );
  };
  $self->{'join_what'} ||= sub {
    #sub select {
    my $self = shift;
    my ( $where, $param, $table ) = @_;
    $table ||= $self->{'current_table'};
    my @join;
    #=dev
    for my $jt ( keys %{ $self->{'table_join'}{$table} } ) {
      local @_ = (    #(
        #map    { $_ }
        grep { $_ and $self->{'table'}{$jt}{$_} } keys %{ $self->{'table_join'}{$table}{$jt}{'on'} }
          #)
      );
      #$self->log('dev','join', %{$self->{'table_join'}});
      #$self->log('dev', "JOd $table -> $jt,",@_,"::", keys %{ $self->{'table_join'}{$table}{$jt}{'on'} });
      #push @join,  " $tq$self->{'table_prefix'}$table$tq LEFT JOIN " .$tq. $self->{'table_prefix'} . $jt . $tq.
      push @join, "  LEFT JOIN " . $tq . $self->{'table_prefix'} . $jt . $tq . ' ON ' . '(' . join(
        ', ',
        map {
          $tq
            . $self->{'table_prefix'}
            . $table
            . $tq . '.'
            . $rq
            . $self->{'table_join'}{$table}{$jt}{'on'}{$_}
            . $rq . ' = '
            . $tq
            . $self->{'table_prefix'}
            . $jt
            . $tq . '.'
            . $rq
            . $_
            . $rq
        } @_
        )
        . ')'
        if @_;
      unless (@_) {
        @_ = (
          #(
          #map    { $_ }
          grep { $_ and $self->{'table'}{$jt}{$_} } keys %{ $self->{'table_join'}{$table}{$jt}{'using'} }
            #)
            #or (grep { $self->{'table'}{$jt}{$_}{'primary'} }
            #keys %{ $self->{'table'}{$jt} })
        );
#$self->log('dev',"joprim{$jt}{$_}",
#keys (%{ $self->{'table'}{$jt} }),"oooooo",
#grep( { $self->{'table'}{$jt}{$_}{'primary'} }
#keys (%{ $self->{'table'}{$jt} })),
#"j[".join(':',@_)."]", scalar @_),
#$self->log('dev',"joprim{$jt} keys:", map( {'[', keys %{ $self->{'table'}{$jt}{$_}} , ']'} ,keys %{ $self->{'table'}{$jt} }),'prim:',grep { $self->{'table'}{$jt}{$_}{'primary'} }
#keys %{ $self->{'table'}{$jt} }
#);
#$self->log('dev',"joprim{$jt:",%{$self->{'table'}{$jt}{'host'}});
#$self->log('dev','jop1',@_, "::", Dumper($self->{'table'}{$jt} ));
        @_ = ( grep { $self->{'table'}{$jt}{$_}{'primary'} } keys %{ $self->{'table'}{$jt} } ) unless @_;
#$self->log('dev','jop2',@_);
#$self->log('dev','jop', "j[$jt][$_][".join(':',@_)."]", scalar @_);
#$self->log('dev', 'jo:',@_, ',,,:',grep { $self->{'table'}{$jt}{$_} }
#grep { $_ }keys %{ $self->{'table_join'}{$table}{$jt}{'using'} });
#push @join, "$tq$self->{'table_prefix'}$table$tq LEFT JOIN " .$tq. $self->{'table_prefix'} . $jt . $tq.' USING ' . '(' . join( ', ', map { $rq . $_ . $rq } @_ ) . ')'
#$self->log('dev', "JO1 $table -> $jt,@_ [".join(':',@_)."]::", keys %{ $self->{'table_join'}{$table}{$jt}{'on'} });
        push @join,
            " LEFT JOIN "
          . $tq
          . $self->{'table_prefix'}
          . $jt
          . $tq
          . ' USING ' . '('
          . join( ', ', map { $rq . $_ . $rq } @_ ) . ')'
          if @_;
      }
      #=cut
    }
    #=cut
    return join( ' ', @join );
  };
  $self->{'join_where'} ||= sub {
    #sub select {
    my $self = shift;
    my ( $where, $param, $table ) = @_;
    my @what;
    $table ||= $self->{'current_table'};
    for my $jt ( sort keys %{ $self->{'table_join'}{$table} } ) {
      #$self->log('dev', "here $jt");
      local $_ = join ', ', map {
            $tq
          . $self->{'table_prefix'}
          . $jt
          . $tq . '.'
          . $rq
          . $self->{'table_join'}{$table}{$jt}{'fields'}{$_}
          . $rq . ' AS '
          . $rq
          . $_
          . $rq
        } grep {
        $self->{'table'}{$jt}{ $self->{'table_join'}{$table}{$jt}{'fields'}{$_} }
        } sort keys %{ $self->{'table_join'}{$table}{$jt}{'fields'} };
      $_ ||= "$tq$self->{'table_prefix'}$jt" . "$tq.*";
      #$join .= $_
      push( @what, $_ );
    }
  #$join = ', ' . $join if $join;
  #$sql = " $tq$self->{'table_prefix'}$table" . "$tq.* $work{'what_relevance'}{$table}".($join ? ', ' : ''). $join . " " . $sql;
  #$self->log('dev', join(':',@what));
  #@what = ('*');
    return join( ', ', grep { $_ } @what );
  };
  for my $by (qw(order group)) {
    $self->{ $by . 'by' } ||= sub {
      #sub select {
      my $self = shift;
      my ( $param, $table ) = @_;
      $table ||= $self->{'current_table'};
      my $sql;
      my %order;
      for my $ordern ( '', 0 .. 10 ) {
        my $order = ( $param->{ $by . $ordern } or next );
        last if ( $self->{'ignore_index'} or $self->{'table_param'}{$table}{'ignore_index'} );
        #$self->log('dev',1, $ordern, $order);
        my $min_data;
        ++$min_data
          for grep { $self->{'table'}{$table}{$_}{'sort_min'} and defined( $param->{$_} ) } keys %{ $self->{'table'}{$table} };
        last if $self->{'no_slow'} and !$min_data;
        #$self->log('dev',2, $ordern, $order);
        for my $join (
          grep { $order eq $_ } (
            grep { $self->{'table'}{$table}{$_}{'sort'} or !$self->{'table'}{$table}{$_}{'no_order'} }
              keys %{ $self->{'table'}{$table} }
            ),
          @{ $self->{'table_param'}{$table}{'join_fields'} }
          )
        {
          my ($intable) = grep { keys %{ $self->{'table'}{$_}{$join} } } $table, keys %{ $config{'sql'}{'table_join'}{$table} };
          #print "INTABLE[$intable]";
          #$order{ $tq . $table . $tq . '.' . $rq . $_ . $rq
          $order{ ( $self->{'no_column_prepend_table'} ? '' : $tq . $intable . $tq . '.' )
              . $rq
              . $join
              . $rq
              . ( ( $param->{ $by . '_mode' . $ordern } ) ? ' DESC ' : ' ASC' ) }
            =    #$param->{ 'order_rev' . $ordern } eq 'on' or
            $ordern;
        }
      }
      if ( keys %order ) {
        $sql .= ' ' . uc($by) . ' BY ' . join ', ', sort { $order{$a} <=> $order{$b} } keys %order;
      }
      #print 'ORDERBY', Dumper($param,$table,$sql,  $self->{'table_param'}{$table}{'join_fields'} );
      return $sql;
    };
  }
  $self->{'select_body'} ||= sub {
    #sub select {
    my $self = shift;
    my ( $where, $param, $table ) = @_;
    $table ||= $self->{'current_table'};
    ( $tq, $rq, $vq ) = $self->quotes();
    #$self->log( 'dev', 'select_body', $where );
    #my ( $tq,    $rq,    $vq )    = sql_quotes();
    $self->limit_calc( $param, $table );
    #limit(_calc( $param, $table );
    if ( ( $self->{'ignore_index'} or $self->{'table_param'}{$table}{'ignore_index'} )
      and !( $self->{'no_index'} or $self->{'table_param'}{$table}{'no_index'} ) )
    {
      local @_ = ();
      local %_ = ();
      for ( keys %{ $self->{'table'}{$table} } ) {
        ++$_{ $self->{'table'}{$table}{$_}{'fulltext'} } if $self->{'table'}{$table}{$_}{'fulltext'};
        push( @_, $_ ) if $self->{'table'}{$table}{$_}{'index'};
      }
      push( @_, keys %_ ) unless $self->{'ignore_index_fulltext'} and $self->{'table_param'}{$table}{'ignore_index_fulltext'};
      $work{'sql_select_index'} = 'IGNORE INDEX (' . join( ',', @_ ) . ')';
    }
    #my $join = ;
    #!!!
    my $from;
    if ($table) {
      if ( $self->{'sphinx'} and $self->{'table_param'}{$table}{'stemmed_index'} and !$param->{'accurate'} ) {
        $from .= "$tq$self->{'table_param'}{$table}{'stemmed_index'}$tq ";
      } else {
        $from .= "$tq$self->{'table_prefix'}$table$tq ";
      }
    }
    unless ( $self->{'no_join'} ) { $from .= $work{'sql_select_index'} . ' ' . $self->join_what( $where, $param, $table ); }
    $from = "FROM " . $from if $from;
    my $sql  = $from . ' ' . $where;
    my @what = (
      ( ( $table and !$self->{'no_column_prepend_table'} ) ? $tq . $self->{'table_prefix'} . $table . $tq . '.' : '' ) . '*',
      $work{'what_relevance'}{$table},
      #$param->{'what_extra'}
      $self->{'table_param'}{$table}{'what_extra'}
    );
    if ( defined( $self->{'table'}{$table}{ $param->{'distinct'} } ) ) {
      #$sql = " DISTINCT $rq$param->{'distinct'}$rq " . $sql . " ";
      @what = ( "DISTINCT $rq$param->{'distinct'}$rq", $self->{'table_param'}{$table}{'what_extra'} );
    } else {
      #my $join ;
      #@join = ()
      #!!
      unless ( $self->{'no_join'} ) { @what = ( $self->join_where( $where, $param, $table ), @what ); }
    }
    #$self->log('dmp', "SP=", $self->{'sphinx'} );
    $sql = join( ', ', grep { $_ } @what, ) . ' ' . $sql;
    my $priority;
    $priority = $self->{'HIGH_PRIORITY'} if !$config{'client_bot'} and !$config{'client_no_high_priority'};
    $sql = " SELECT $self->{'SELECT_FLAGS'} $priority " . $sql;    #SQL_CALC_FOUND_ROWS
    $sql .= $self->groupby( $param, $table );
    $sql .= $self->orderby( $param, $table );
    #$work{'on_page'} = 10 unless defined $work{'on_page'};
    #my $limit = psmisc::check_int( ( $param->{'limit'} or $work{'on_page'} ), 0, $self->{'limit_max'}, $self->{'on_page'} );
    #$sql .= ' LIMIT ' . ( $param->{'show_from'} ? $param->{'show_from'} . ',' : '' ) . " $limit"
    #if $param->{'show_from'}
    #or $limit;
    #$self->{'limit'} = 10 unless defined $self->{'limit'};
    #my $limit = psmisc::check_int( ( $param->{'limit'} or $self->{'limit'} ), 0, $self->{'results_max'}, $self->{'on_page'} );
    #$sql .= ' LIMIT ' . ( $param->{'show_from'} ? $param->{'show_from'} . ',' : '' ) . " $limit"      if $param->{'show_from'}
    $sql .= $self->limit_body();
    if ( $self->{'OPTION'} and psmisc::is_hash $self->{'option'} ) {    #sphinx
      $sql .= $self->{'OPTION'} . ' ' . join ', ', map { "$_=$self->{'option'}{$_}" } keys %{ $self->{'option'} };
    }
    $sql .= $self->{'select_append'};
    return $sql;
  };
  $self->{'limit_body'} ||= sub {
    #sub calc_count {
    my $self = shift;
    return unless $self->{'limit_offset'} or $self->{'limit'};
    return
        ' LIMIT '
      . ( $self->{'limit_offset'} && !$self->{'OFFSET'} ? $self->{'limit_offset'} . ',' : '' )
      . $self->{'limit'}
      . ( $self->{'OFFSET'} && $self->{'limit_offset'} ? ' ' . $self->{'OFFSET'} . ' ' . $self->{'limit_offset'} : '' ) . ' ';
    return '';
  };
  $self->{'calc_count'} ||= sub {
    #sub calc_count {
    my $self = shift;
    my ( $param, $table, $count ) = @_;
    return if $work{'calc_count'}{$table}++;
#$self->log(      'dev', "calc_count0 : founded=$self->{'founded'}; page=$self->{'page'} page_last=$self->{'page_last'}  dbirows=$self->{'dbirows'}   limit=$self->{'limit'}  ",          );
    $self->{'founded'} = $count
      || ( ( $self->{'dbirows'} > $self->{'stat'}{'found'}{'files'} and $self->{'dbirows'} < $self->{'limit'} )
      ? $self->{'dbirows'} + $self->{'limit_offset'}
      : $self->{'stat'}{'found'}{'files'} );
    $self->{'founded'} = 0 if $self->{'founded'} < 0 or !$self->{'founded'};    #or !$self->{'dbirows'} !!!experemental!
    $self->{'page_last'} =
      $self->{'limit'} > 0
      ? ( int( $self->{'founded'} / ( $self->{'limit'} or 1 ) ) + ( $self->{'founded'} % ( $self->{'limit'} or 1 ) ? 1 : 0 ) )
      : 0;                                                                      #3
    $self->{'page'} = int( rand( $self->{'page_last'} ) ) if $self->{'page'} eq 'rnd' and $param->{'count_f'} eq 'on';    #4
#$self->log(      'dev', "calc_count : founded=$self->{'founded'}; page=$self->{'page'} page_last=$self->{'page_last'}  dbirows=$self->{'dbirows'}   limit=$self->{'limit'}  ",          );
  };
  $self->{'limit_calc'} ||= sub {
    #sub pre_query {
    my $self = shift;
    my ($param) = @_;
    #return if $work{'pre_query'}{$table}++;
    #$self->{'page'} = int( $param->{'page'} > 0 ? $param->{'page'} : 1 );
    #$self->{'page'}  = psmisc::check_int( $param->{'page'}, 1, $self->{'page_max'},    1 );
    #$self->{'limit'} = psmisc::check_int( $param->{'on_page'},   0, $self->{'limit_max'}, $self->{'on_page'} );
    #$self->{'limit'} ||= psmisc::check_int( $param->{'on_page'},   0, $self->{'results_max'}, $self->{'on_page'} );
    $self->{'limit_offset'} =
      int( $self->{'page'} > 0 ? $self->{'limit'} * ( $self->{'page'} - 1 ) : ( ( $param->{'show_from'} ) or 0 ) );
    $self->{'limit_offset'} -= $self->{'limit_from'} - $self->{'limit_minus'} if $self->{'limit_offset'};
    $self->{'limit'} -= $self->{'limit_minus'};
#$self->log( 'dev',"limit_calc : limit_offset=$self->{'limit_offset'}; page=$self->{'page'} limit= $self->{'limit'} from=$self->{'limit_from'}"    );
#;    #caller(), caller(1),  caller(2)
    return undef;
  };
  $self->{'lock_tables'} ||= sub {
    #sub lock_tables {
    my $self = shift;
    #local $_ = $self->do( $self->{'LOCK TABLES'}.' ' . join ' ', @_ );
    #$work{'sql_locked'} = join ' ', @_ if $_;
    return $self->do( $self->{'LOCK TABLES'} . ' ' . join ' ', @_ ) if $self->{'LOCK TABLES'};
  };
  $self->{'unlock_tables'} ||= sub {
    #sub unlock_tables {
    my $self = shift;
    #$work{'sql_locked'} = '';
    #return $self->do( 'UNLOCK TABLES ' . join ' ', @_ );
    return $self->do( $self->{'UNLOCK TABLES'} . ' ' . join ' ', @_ ) if $self->{'UNLOCK TABLES'};
  };
  $self->{'stat_string'} ||= sub {
    my $self = shift;
    #print "\nSTRAAAA\n";
    return 'sqlstat: '
      . join(
      ' ',
      ( map { "$_=$self->{$_};" } grep { $self->{$_} } ( @_ or sort keys %{ $self->{'statable'} } ) ),
      (
        map { "$_=" . psmisc::human( 'time_period', $self->{$_} ) . ';' }
        grep { $self->{$_} } ( @_ or sort keys %{ $self->{'statable_time'} } )
      )
      );
  };
  $self->{'log_stat'} ||= sub {
    my $self = shift;
    $self->log( 'stat', $self->stat_string(@_) );
  };
  $self->{'check_data'} ||= sub {
    my $self = shift;
    local @_ = sort grep { $_ } keys %{ $self->{'table'} };
    return 0 unless @_;
    #$self->log('dev',@_);
    return 0;
    return $self->query( 'SELECT * FROM ' . ( join ',', map { "$tq$_$tq" } @_ ) . ' WHERE 1 LIMIT 1' );
  };
  $self->{'check_data_every_table'} ||= sub {
    my $self = shift;
    local @_ = sort grep { $_ } keys %{ $self->{'table'} };
    return 0 unless @_;
    for my $table (@_) {
      #$self->log('check', $table,
      $self->query_log("SELECT * FROM $tq$table$tq LIMIT 1");    #);
    }
  };
  $self->{'on_connect1'} ||= sub {
    my $self = shift;
    #$self->log( 'dev', 'ONCON1');
    $self->check_data() if $self->{'auto_check'};
    #use Data::Dumper;
    #$self->log( 'dev', Dumper($config{'sql'}));
  };
  $self->{'table_stat'} ||= sub {
    my $self = shift;
    $self->log( 'info', 'totals:', @_,
      map { ( $_, '=', values %{ $self->line("SELECT COUNT(*) FROM $rq$self->{'table_prefix'}$_$rq ") } ) }
      grep { $_ } ( @_ or keys %{ $self->{'table'} } ) );
  };
  $self->{'next_user_prepare'} ||= sub {
    my $self = shift;
    #$self->{'queries'} = $self->{''} = $self->{''} = $self->{''} = $self->{''} = 0;
    #delete $self->{error_log} if $self->{'error_collect'};

    delete $self->{$_} for qw(founded queries queries_time errors_chain errors connect_tried error_log);
    $self->{'stat'}{'found'} = {};
    $self->{ 'on_user' . $_ }->($self) for grep { ref $self->{ 'on_user' . $_ } eq 'CODE' } ( '', 1 .. 5 );
    #$self->{ 'on_user' }->($self) for grep { ref $self->{ 'on_user' } eq 'CODE'}('');
    #$self->log('dev', 'nup');

  };
  $self->{'next_user'} ||= sub {
    my $self = shift;
    $self->user_params(@_);
    $self->next_user_prepare(@_);
    $self->{'sphinx_dbi'}->next_user(@_) if $self->{'sphinx_dbi'};
  };

=stem links
http://en.wikipedia.org/wiki/New_York_State_Identification_and_Intelligence_System
http://translit.ru/
http://koi8.pp.ru/koi8-r_iso9945-2.txt
http://en.wikipedia.org/wiki/Stemming
http://linguist.nm.ru/stemka/stemka.html
=cut

  $self->{'stem'} ||= sub {
    my $self = shift;
    #$self->log('dev', "stem in[$_[0]]( $self->{'codepage'}, $self->{'cp_in'} -> $self->{'cp_int'})");
    #return $_[0];
    local $_ = lc( scalar psmisc::cp_trans( $self->{'cp_in'}, $self->{'cp_int'}, $_[0] ) );
    #local $_ = lc( scalar psmisc::cp_trans( $self->{'codepage'}, $self->{'cp_int'}, $_[0] ) );
    #local $_ = lc($_[0]  );
    #$self->log('dev', "stem bef[$_]");
    $self->{'stem_version'} = 4 if $self->{'stem_version'} <= 1;
    if ( $self->{'stem_version'} == 2 ) {    #first
      s/(\d)(\D)/$1 $2/g;
      s/(\D)(\d)/$1 $2/g;
      tr/А-Я/а-я/;
      s/[ъь]//g;
      s/kn/n/g;
      tr/абвгдеёжзийклмнопрстуфхцчшщыэюя/abvgdeejsiiklmnoprstufhccssieua/;
      tr/ekouw/acaav/;
      s/'//g;
      s/\W/ /g if $_[1];
      s/_/ /g;
      s/(?:rd|nd)\b/d/g;
      s/ay\b/y/g;
      s/\B[aeisuo]\b//g;
      s/av/af/g;
      s/sch/s/g;
      s/ph/f/g;
      s/\s+/ /g;
      s/(\w)\1+/$1/g;
    } elsif ( $self->{'stem_version'} == 3 ) {    #temporary
      s/(\d)(\D)/$1 $2/g;
      s/(\D)(\d)/$1 $2/g;
      tr/А-Я/а-я/;
      s/[ъь]//g;
      s/kn/n/g;
      tr/абвгдеёжзийклмнопрстуфхцчшщыэюя/abvgdeejsiiklmnoprstufhccssieua/;
      s/ks/x/g;                                   #2
      tr/kw/cv/;                                  #3
      s/'//g;
      s/\W/ /g if $_[1];
      s/_/ /g;
      s/(?:rd|nd)\b/d/g;
      s/ay\b/y/g;
      s/\B[aeisuo]\b//g;
      s/av/af/g;
      s/sch/s/g;
      s/ph/f/g;
      s/\s+/ /g;
      s/(?:(?!xxx)|(?=xxxx))(\w)\1+(?:(?<!xxx)|(?<=xxxx))/$1/g;    #3
    } elsif ( $self->{'stem_version'} == 4 ) {                     #release candidate
      s/(\d)(\D)/$1 $2/g;
      s/(\D)(\d)/$1 $2/g;
      tr/А-Я/а-я/;
      s/kn/n/g;
      s/[ъь]//g;
      tr{абвгдеёжзийклмнопрстуфхцчшщыэюя}
        {abvgdeejziiklmnoprstufhccssieua};                         #4 z
      s/ks/x/g;                                                    #2
      tr/kw/cv/;                                                   #3
      s/'//g;
      s/\W/ /g if $_[1];
      s/_/ /g;
      s/(?:rd|nd)\b/d/g;
      s/ay\b/y/g;
      s/\B[aeisuo]\b//g;
      s/av/af/g;
      s/sch/s/g;
      s/ph/f/g;
      s/\s+/ /g;
      s/(?:(?!xxx)|(?=xxxx))(\w)\1+(?:(?<!xxx)|(?<=xxxx))/$1/g;    #3
    }
    #$self->log('dev', "stem aft[$_]");
    #$_ = scalar psmisc::cp_trans( $self->{'cp_int'}, $self->{'cp_in'},$_);
    #$_ = scalar psmisc::cp_trans( $self->{'cp_int'}, $self->{'codepage'}, $_ );
    #$self->log('dev', "stem out[$_]");
    #return scalar psmisc::cp_trans( $self->{'cp_int'}, $self->{'codepage'}, $_ );
    return scalar psmisc::cp_trans( $self->{'cp_int'}, $self->{'cp_in'}, $_ );
  };
  $self->{'stem_insert'} ||= sub {
    my $self = shift;
    #$config{'sql'}{'handler_insert'} = sub {
    my ( $table, $col ) = @_;
    return 1 unless ref $self->{'stem'} eq 'CODE';
    #$config{'stem'} and
    #$config{'stem_func'};
    $col->{'stem'} = join ' ',
      map { $self->stem( $col->{$_}, 1 ) } grep { $self->{'table'}{$table}{$_}{'stem'} and $col->{$_} } keys %$col;
    return undef;
  };
  $self->{'last_insert_id'} ||= sub {
    my $self = shift;
    my $table = shift || $self->{'current_table'};
    if ( $^O eq 'MSWin32' and $self->{'driver'} eq 'pgpp' ) {
      my ($field) =
        grep { $self->{'table'}{$table}{$_}{'type'} eq 'serial' or $self->{'table'}{$table}{$_}{'auto_increment'} }
        keys %{ $self->{'table'}{$table} };
      #$self->log('dev', 'use lid1', "${table}_${field}");
      return $self->line("SELECT currval('${table}_${field}_seq') as lastid")->{'lastid'};
    } else {
      #$self->log('use lid2');
      return $self->{dbh}->last_insert_id( undef, undef, $table, undef );
    }
  };
  $self->{'dump_cp'} ||= sub {
    $self->log( 'dev', map { "$_ = $self->{$_}; " } qw(codepage cp cp_in cp_out cp_int cp_set_names) );
  };
  $self->{'cp_client'} ||= sub {
    my $self = shift;
    $self->{'cp_in'} = $_[0] if $_[0];
    $self->{'cp_out'} = $_[1] || $self->{'cp_in'} if $_[1] or $_[0];
    return ( $self->{'cp_in'}, $self->{'cp_out'} );
  };
  $self->{'index_disable'} ||= sub {
    my $self = shift;
    my $tim  = psmisc::timer();
    $self->log( 'info', 'Disabling indexes on', @_ );
    $self->log( 'err', 'ALTER TABLE ... DISABLE KEYS available in mysql >= 4' ), return
      if $self->{'driver'} eq 'mysql3'
        or $self->{'driver'} !~ /mysql/;
    $self->    #query_log
      do("ALTER TABLE $tq$config{'table_prefix'}$_$tq DISABLE KEYS") for @_;
    $self->log( 'time', "Disable index per", psmisc::human( 'time_period', $tim->() ), "sec" );
  };
  $self->{'index_enable'} ||= sub {
    my $self = shift;
    my $tim  = psmisc::timer();
    $self->log( 'info', 'Enabling indexes on', @_ );
    $self->log( 'err', 'ALTER TABLE ... DISABLE KEYS available in mysql >= 4' ), return
      if $self->{'driver'} eq 'mysql3'
        or $self->{'driver'} !~ /mysql/;
    $self->    #query_log
      do("ALTER TABLE $tq$config{'table_prefix'}$_$tq ENABLE KEYS") for @_;
    $self->log( 'time', 'Enable index per ', psmisc::human( 'time_period', $tim->() ) );
  };
  for my $action (qw(optimize analyze check flush)) {
    $self->{$action} ||= sub {
      my $self = shift;
      @_ = sort keys %{ $self->{'table'} } unless @_;
      @_ = grep { $_ and $self->{'table'}{$_} } @_;
      $self->log( 'err', 'not defined action', $action, ), return unless $self->{ uc $action };
      $self->log( 'info', $action, @_ );
      my $tim = psmisc::timer();
      for ( $self->{'bulk_service'} ? \@_ : @_ ) {
        $self->query_log(
          $self->{ uc $action } . ' ' . join( ',', map( $self->tquote("$self->{'table_prefix'}$_"), psmisc::array $_ ) ) );
      }
      $self->log( 'time', $action, 'per ', psmisc::human( 'time_period', $tim->() ) );
    };
  }

=no
  for my $action (qw(flush)) {
    $self->{$action} ||= sub {
      my $self = shift;
      @_ = sort keys %{ $self->{'table'} } unless @_;
      @_ = grep { $_ and ( m/\./ or $self->{'table'}{$_} ) } @_;
      $self->log( 'err', 'not defined action', $action, ), return unless $self->{ uc $action };
      $self->log( 'info', $action, @_ );
      my $tim = psmisc::timer();
      $self->do( $self->{ uc $action } . ' ' . join( ',', map( $self->tquote( $self->{'table_prefix'} . $_ ), @_ ) ) );
      $self->log( 'time', $action, 'per ', psmisc::human( 'time_period', $tim->() ) );
    };
  }
=cut

  $self->{'retry_off'} ||= sub {
    my $self = shift;
    return if %{ $self->{'retry_save'} || {} };
    $self->{'retry_save'}{$_} = $self->{$_}, $self->{$_} = 0 for @{ $self->{'retry_vars'} };
  };
  $self->{'retry_on'} ||= sub {
    my $self = shift;
    return unless %{ $self->{'retry_save'} || {} };
    $self->{$_} = $self->{'retry_save'}{$_} for @{ $self->{'retry_vars'} };
    $self->{'retry_save'} = {};
  };
  $self->{'set_names'} ||= sub {
    my $self = shift;
    local $_ = $_[0] || $self->{'cp_set_names'};
    $self->do( $self->{'SET NAMES'} . " $vq$_$vq" ) if $_ and $self->{'SET NAMES'};
  };
}
1;
