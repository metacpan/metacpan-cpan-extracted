use strict;
use warnings;
use t::scan::Util;

test(<<'TEST'); # JEPRICE/Meta-Widget-Gtk-Sprite-0.01/Sprite.pm
sub new
    {
        _debug "New sprite manager created";
        my $self = bless {}, ref($_[0]) || $_[0] || __PACKAGE__;
        $self->{sprite} = {};
        $self->{croot} = $_[1];
        $self->{cgroup} = {};
        return $self;
    }

=item $sprite_number = $sprites->create("/path/to/filename", 10, 20);

Create will load an image file (right now, only xpm format) from disk and make a sprite out of it.  The two numbers are the x and y positi
on on the canvas.

=cut

sub create
    {
        my ($self, $filename, $x, $y) = @_;
        my $img = Gtk::Gdk::ImlibImage->load_image($filename) || die "Could not load requested tile, $filename.  $!";
        my ( $cg, $cg_index ) = $self->_get_new_cgroup();
        $cg->hide;
        my $imgitem = $cg->new($cg, "Gnome::CanvasImage",
            'image' => $img,
            'x' => $x,
            'y' => $y,
            width => $img->rgb_width,
            height => $img->rgb_height,
        );
        $cg->{x} = $x;
        $cg->{y} = $y;
        $cg->{width} = $img->rgb_width;
        $cg->{height} = $img->rgb_height;
        #$cg->{radius} = sqrt($cg->{width}**2 + $cg->{height}**2)/2;
        $cg->{radius} = ($cg->{width} + $cg->{height})/4;
        $cg->{cx} = $cg->{x} + $cg->{width}/2;
        $cg->{cy} = $cg->{y} + $cg->{height}/2;
        my $index = $self->_add_sprite($cg);
        $cg->{index} = $index;
        return $index;
    }

=item $sprites->show( $sprite_number );

Makes the sprite appear on the canvas

=cut

sub show
    {
        my ($self, $item) = @_;
        $self->{sprite}->{$item}->show;
    }

=item $sprites->hide( $sprite_number );

Make the sprite picture disappear from the canvas.  Note that it can still collide with other sprites.  If you don't want it to hit anythi
ng, move it out of the way or ignore it in your own collision handler.


=cut

sub hide
    {
        my ($self, $item) = @_;
        $self->{sprite}->{$item}->hide;
    }


TEST

test(<<'TEST');
b#!/usr/bin/perl
#$Id: pssql.pm 4624 2011-05-26 18:10:55Z pro $ $URL: svn://svn.setun.net/search/trunk/lib/pssql.pm $

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
our $VERSION = ( split( ' ', '$Revision: 4624 $' ) )[1];
#use locale;
use DBI;
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
#our $VERSION = ( split( ' ', '$Revision: 4624 $' ) )[1];
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
    'sqlite' => {
      #'dbi'          => 'SQLite2',
      'dbi'                 => 'SQLite',
      'params'              => [qw(dbname)],
      'dbname'              => $config{'root_path'} . 'sqlite.db',
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
        #return 'connection' if $errstr =~ /connect/i;
        return undef;
      },
      'on_connect' => sub {
        my $self = shift;
        $self->do("PRAGMA synchronous = OFF;");
        #$self->log( 'sql', 'on_connect!' );
      },
      'no_dbirows' => 1,
    },
    'pgpp' => {
      'dbi'  => 'PgPP',
      'user' => ( $^O =~ /^(?:(ms)?(dos|win(32|nt)?))/i ? 'postgres' : 'pgsql' ),
      #'port' => 5432,
      'IF EXISTS' => 'IF EXISTS', 'CREATE TABLE' => 'CREATE TABLE', 'OFFSET' => 'OFFSET',
      #'unsigned'     => 0,
      'UNSIGNED'         => '',
      'table quote'      => '"',
      'row quote'        => '"',
      'value quote'      => "'",
      'index_name_table' => 1,
      'REPLACE'          => 'INSERT',
      'EXPLAIN'          => 'EXPLAIN ANALYZE',
      'CASCADE'          => 'CASCADE',
      'SET NAMES'        => 'SET client_encoding = ',
      'fulltext_config'  => 'pg_catalog.simple',
      'params'           => [qw(dbname host port path debug)],
      'err_ignore'       => [qw( 1 7)],
      'error_type'       => sub {
        my $self = shift, my ( $err, $errstr ) = @_;
        #$self->log('dev',"ERRDETECT($err, [$errstr])");
        return 'install_db' if $errstr =~ /FATAL:\s*database ".*?" does not exist/i;
        return 'fatal'      if $errstr =~ /fatal/i;
        return 'syntax'     if $errstr =~ /syntax/i;
        return 'connection' if $errstr =~ /connect|Unknown message type: ''/i;
        return 'install'    if $errstr =~ /ERROR:\s*(?:relation \S+ does not exist)/i;
        #return 'retry'    if $errstr =~       /ERROR:\s*cannot drop the currently open database/i;
        return 'retry' if $errstr =~ /ERROR:  database ".*?" is being accessed by other users/i;
        return 'ignore'
          if $errstr =~
/(?:duplicate key violates unique constraint)|(?:duplicate key value violates unique constraint)|(?:ERROR:\s*(?:database ".*?" already exists)|(?:relation ".*?" already exists)|(?:invalid byte sequence for encoding)|(?:function .*? does not exist)|(?:null value in column .*? violates not-null constraint))/i;
        return undef;
      },
      'on_connect' => sub {
        my $self = shift;
        $self->set_names();
        $self->do("select set_curcfg('default');") if $self->{'use_fulltext'} and $self->{'old_fulltext'};
      },
      'no_dbirows'         => 1,
      'cp1251'             => 'win1251',
      'fulltext_word_glue' => '&',
    },
    'sphinx' => {
      'dbi'                     => 'mysql',
      'user'                    => 'root',
      'port'                    => 9306,
      'params'                  => [qw(host port )],                                  # perldoc DBD::mysql
      'sphinx'                  => 1,
      'value quote'             => "'",
      'no_dbirows'              => 1,
      'no_column_prepend_table' => 1,
      'no_join'                 => 1,
      'OPTION'                  => 'OPTION',
      'option'                  => { 'max_query_time' => 20000, 'cutoff' => 1000 },
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
      'err_connection'    => [qw( 1 1040 1053 1129 1213 1226 2002 2003 2006 2013 )],
      'err_fatal'         => [qw( 1016 1046 1251 )],                                   # 1045,
      'err_syntax'  => [qw( 1054 1060 1064 1065 1067 1071 1096 1103 1118 1148 1191 1364 1366 1406 1439)],  #maybe all 1045..1075
      'err_repair'  => [qw( 126 130 144 145 1034 1062 1194 1582 )],
      'err_retry'   => [qw( 1317 )],
      'err_install' => [qw( 1146 )],
      'err_install_db' => [qw( 1049 )],
      'err_ignore '    => [qw( 2 1264 )],
      'error_type'     => sub {
        my $self = shift, my ( $err, $errstr ) = @_;
        #$self->log('dev',"MYERRDETECT($err, $errstr)");
        for my $errtype (qw(connection retry syntax fatal repair install install_db)) {
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
    : ( exists $self->{$cmd} ? ( ( defined( $_[0] ) ? ( $self->{$cmd} = $_[0] ) : ( $self->{$cmd} ) ) ) : 
    (!$self->{'dbh'} ? () : $self->{'dbh'}->can($cmd) ? $self->{'dbh'}->$cmd(@_) : exists $self->{'dbh'}{$cmd} ? 
    ( ( defined( $_[0] ) ? ( $self->{'dbh'}->{$cmd} = $_[0] ) : ( $self->{'dbh'}->{$cmd} ) ) ) : undef) );
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
        $self->log( 'dev', 'HandleError', @_, $DBI::err, $DBI::errstr );
        #$self->{'err'} = "$DBI::err, $DBI::errstr";
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
  $self->{'default'}{'pgpp'}{'match'} = sub {
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
  $self->{'default'}{'pgpp'}{'fulltext_config'} = 'default' if $self->{'old_fulltext'};
  %{ $self->{'default'}{'pg'} } = %{ $self->{'default'}{'pgpp'} };
  $self->{'default'}{'pg'}{'dbi'}    = 'Pg';
  $self->{'default'}{'pg'}{'params'} = [qw(host port options tty dbname user password)];
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
TEST

done_testing;
