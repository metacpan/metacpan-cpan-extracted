#!/usr/bin/perl
#$Id: statlib.pm 790 2011-05-27 10:20:14Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/stat/statlib.pm $
package statlib;
use strict;
use Time::HiRes qw(time sleep);
use utf8;
our $root_path;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
#use lib $root_path. './pslib';
#use Net::DirectConnect::pslib::psmisc;
#use Net::DirectConnect;
#warn Dumper \%INC;
#BEGIN {
#$INC{'Net/DirectConnect.pm'} =~ m{(.*/)};
#warn $1 . 'DirectConnect/pslib';
#use lib $1 . 'DirectConnect/pslib/';
use Net::DirectConnect::pslib::pssql;
#psmisc->import qw(:log);
#use Net::DirectConnect::pslib::pssql;
#eval q{
#Net::DirectConnect::use_try 'pssql';
#Net::DirectConnect::use_try 'psmisc';
#use pssql;
#use psmisc;
#};
#}
#warn $@;
use Exporter 'import';
our @EXPORT = qw(%config  $param   $db );
our ( %config, $param, $db, );
*statlib::config = *main::config;
our ( $tq, $rq, $vq );
$config{'log_trace'}  ||= 0;
$config{'log_dmpbef'} ||= 0;
$config{'log_dmp'}    ||= 0;
$config{'log_dcdmp'}  ||= 0;
$config{'hit_to_ask'} ||= 2;
$config{'ask_retry'}  ||= 3600;
$config{'limit_max'}  ||= 100;
$config{'use_slow'}   ||= 1;
$config{'row_all'}    ||= { 'not null' => 1, };
$config{'periods'}    ||= {
  'h' => 3600,
  'd' => 86400,
  'w' => 7 * 86400,    #'m'=>31*86400, 'y'=>366*86400
};
$config{'purge'}          ||= 31 * 86400;                          #366*86400;
$config{'default_period'} ||= 'd';
$config{'browsers'}       ||= [qw(opera firefox chrome safari)];
my $browsers = join '|', @{ $config{'browsers'} };
#$config{'client'} = 'ie',
$config{'browser_ie'} = 1 if $ENV{'HTTP_USER_AGENT'} =~ /MSIE/ and $ENV{'HTTP_USER_AGENT'} !~ /$browsers/i;
#$config{'client'} = $_,
$config{ 'browser_' . $_ } = 1 for grep { $ENV{'HTTP_USER_AGENT'} =~ /$_/i } @{ $config{'browsers'} };
$config{'use_graph'} ||= 1;    #  if grep {$config{'browser_'. $_}} qw(firefox safari chrome opera);
$config{'graph_inner'} ||= 1 if grep { $config{ 'browser_' . $_ } } qw(firefox safari chrome);
$config{'title'}       ||= 'dcstat';
$config{'sql'}         ||= {
  #'driver'              => 'mysql',
  'driver' => 'sqlite', 'dbname' => 'dcstat', 'auto_connect' => 1, 'log' => sub { shift; psmisc::printlog(@_) },
  #'cp_in'               => 'cp1251',
  'connect_tries'       => 0,
  'connect_chain_tries' => 0,
  'error_tries'         => 0,
  'error_chain_tries'   => 0,
  'table'               => {
    'queries' => {
      'time' => pssql::row( 'time', 'index' => 1,         'purge'  => 1, ),
      'hub'  => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 64, 'index' => 1, 'default' => '', ),
      'nick' => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 32, 'index' => 1, 'default' => '', ),
      'ip'   => pssql::row( undef, 'type' => 'VARCHAR',  'length'  => 15, 'default' => '', ),
      'port' => pssql::row( undef, 'type' => 'SMALLINT', 'default' => 0, ),
      'tth'    => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 40,  'default' => '', 'index' => 1 ),
      'string' => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 255, 'default' => '', 'index' => 1 ),
    },
    'results' => {
      'time'   => pssql::row( 'time', 'index' => 1,         'purge'  => 300, ),
      'string' => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 255, 'index' => 1, 'default' => '', ),
      'hub'    => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 64, 'index' => 1, 'default' => '', ),
      'nick'   => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 32, 'index' => 1, 'default' => '', ),
      'ip'   => pssql::row( undef, 'type' => 'VARCHAR',  'length'  => 15, 'default' => '', ),
      'port' => pssql::row( undef, 'type' => 'SMALLINT', 'default' => 0, ),
      'tth'      => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 40,  'index'   => 1, 'default' => '', ),
      'file'     => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 255, 'default' => '', ),
      'filename' => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 255, 'index'   => 1, 'default' => '', ),
      'ext'      => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 32,  'index'   => 1, 'default' => '', ),
      'size'     => pssql::row( undef, 'type' => 'BIGINT',  'index'  => 1 ),
    },
    'chat' => {
      'time' => pssql::row( 'time', 'index' => 1,         'purge'  => 366 * 86400, ),
      'hub'  => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 64, 'index' => 1, 'default' => '', ),
      'nick' => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 32, 'index' => 1, 'default' => '', ),
      'string' => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 3090, 'default' => '', ),
    },
    'slow' => {
      'name'   => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 32, 'index' => 1, 'primary' => 1 ),
      'period' => pssql::row( undef, 'type' => 'VARCHAR', 'length' => 8,  'index' => 1, 'primary' => 1, 'default' => '' ),
      'n'      => pssql::row( undef, 'type' => 'INT', 'index' => 1, 'primary' => 1, ),
      'result' => pssql::row( undef, 'type' => 'VARCHAR', ),
      'time' => pssql::row( 'time', 'index' => 1, 'purge' => 1, ),
    },
    'hubs' => {
      'time'  => pssql::row( 'time', 'index' => 1,         'purge'  => 1, ),
      'hub'   => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 64, 'index' => 1, 'default' => '', ),
      'size'  => pssql::row( undef,  'type'  => 'BIGINT',  'index'  => 1, ),
      'users' => pssql::row( undef,  'type'  => 'INT',     'index'  => 1, ),
    },
    'users' => {
      'time' => pssql::row( 'time', 'index' => 1,         'purge'  => 1, ),
      'hub'  => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 64, 'index' => 1, 'default' => '', 'primary' => 1 ),
      'nick' => pssql::row( undef,  'type'  => 'VARCHAR', 'length' => 32, 'index' => 1, 'default' => '', 'primary' => 1 ),
      'ip'   => pssql::row( undef, 'type' => 'VARCHAR',  'length'  => 15, 'Zindex' => 1, 'default' => '', ),
      'port' => pssql::row( undef, 'type' => 'SMALLINT', 'default' => 0, ),
      'size'   => pssql::row( undef,  'type'  => 'BIGINT', 'index'        => 1, 'default' => 0, ),
      'online' => pssql::row( 'time', 'index' => 1,        'default'      => 0, ),
      'info'   => pssql::row( undef,  'type'  => 'VARCHAR', ), #'dumper' => 1,
    },
  },
  'table_param' => {
    'queries' => { 'big'       => 1, },
    'results' => { 'big'       => 1, },
    'slow'    => { 'no_counts' => 1, },
    'hubs'    => { 'no_counts' => 1, },
  },
};
$config{'sql'}{'table'}{ 'queries_top_string_' . $_ } = {
  'date' => pssql::row( undef,  'type'  => 'VARCHAR', 'length'      => 15, 'default' => '', 'index' => 1, primary => 1 ),
  'time' => pssql::row( 'time', 'index' => 1, ),      #'purge' => 1,
  n      => pssql::row( undef, 'type' => 'SMALLINT', 'default' => 0,    primary => 1 ),
  cnt    => pssql::row( undef, 'type' => 'INT',      'default' => 0, ),
  string => pssql::row( undef, 'type' => 'VARCHAR',  'length'  => 1000, 'index' => 1, ),
  },
  $config{'sql'}{'table'}{ 'queries_top_tth_' . $_ } = {
  #queries_top_tth_daily
  'date' => pssql::row( undef,  'type'  => 'VARCHAR', 'length'      => 15, 'default' => '', primary => 1, 'index' => 1, ),
  'time' => pssql::row( 'time', 'index' => 1, ),      #'purge' => 1,
  n   => pssql::row( undef, 'type' => 'SMALLINT', 'default' => 0,  primary => 1 ),
  cnt => pssql::row( undef, 'type' => 'INT',      'default' => 0, ),
  tth => pssql::row( undef, 'type' => 'VARCHAR',  'length'  => 40, 'index' => 1, ),
  },
  $config{'sql'}{'table'}{ 'results_top_' . $_ } = {
  'date' => pssql::row( undef,  'type'  => 'VARCHAR', 'length'      => 15, 'default' => '', primary => 1, 'index' => 1, ),
  'time' => pssql::row( 'time', 'index' => 1, ),      #'purge' => 1,
  n   => pssql::row( undef, 'type' => 'SMALLINT', 'default' => 0,  primary => 1 ),
  cnt => pssql::row( undef, 'type' => 'INT',      'default' => 0, ),
  tth => pssql::row( undef, 'type' => 'VARCHAR',  'length'  => 40, 'index' => 1, ),
  },
  for sort keys %{ $config{'periods'} };
unless ( $ENV{'SERVER_PORT'} ) {
  $config{'sql'}{'auto_repair'}  = 1;
  $config{'sql'}{'force_repair'} = 1;
}
$config{'query_default'}{'LIMIT'} ||= 100;
my $order;
$config{'queries'}{'queries top tth'} ||= {
  'main'    => 1,
  'periods' => 1,
  ( !$config{'use_graph'} ? ( 'class' => 'half' ) : ( 'graph' => 1 ) ),
  'desc'      => { 'ru' => 'Чаще всего скачивают', 'en' => 'Most downloaded' },
  'show'      => [qw(n cnt string filename size tth time )],
  'SELECT'    => '*, COUNT(*) as cnt',
  #'SELECT'    => 'queries.*,results.*, COUNT(*) as cnt',
  'FROM'      => 'queries',
  'LEFT JOIN' => 'results USING (tth)',
  'WHERE'     => ['queries.tth != ""'],
  'GROUP BY'  => 'queries.tth',
  'ORDER BY'  => 'cnt DESC',
  'order'     => ++$order,
  'sort'      => [qw(time cnt size)],
};

=cu
$config{'queries'}{'queries top tth new'} ||= {%{$config{'queries'}{'queries top tth'}}};
local %_ = 
(
'ORDER BY'=> 'time DESC',
  'desc'      => { 'ru' => 'Популярные новинки', 'en' => 'Pop new' },
  'graph' => 0,
  'show'      => [qw(n time cnt string filename size tth )],

  'order'     => ++$order,
)          ;
$config{'queries'}{'queries top tth new'}{$_}=$_{$_} for keys %_;
=cut

$config{'queries'}{'queries top string'} ||= {
  'main'    => 1,
  'periods' => 1,
  ( !$config{'use_graph'} ? ( 'class' => 'half' ) : ( 'graph' => 1 ) ),
  'group_end' => 1,
  'show'      => [qw(n cnt string)],
  'desc'      => { 'ru' => 'Чаще всего ищут', 'en' => 'Most searched' },
  'SELECT'    => 'string, COUNT(*) as cnt',
  'FROM'      => 'queries',
  'WHERE'     => ['string != ""'],
  #todo: show time last
  'GROUP BY' => 'string',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'queries string last'} ||= {
  'main'     => 1,
  'class'    => 'half',
  'desc'     => { 'ru' => 'Сейчас ищут', 'en' => 'last searches' },
  'FROM'     => 'queries',
  'show'     => [qw(n time hub nick ip string )],
  'SELECT'   => '*',
  'WHERE'    => ['queries.string != ""'],
  'ORDER BY' => 'queries.time DESC',
  'order'    => ++$order,
};
$config{'queries'}{'queries tth last'} ||= {
  %{ $config{'queries'}{'queries string last'} },
  'desc'      => { 'ru' => 'Сейчас скачивают', 'en' => 'last downloads' },
  'class'     => 'half',
  'group_end' => 1,
  'show'      => [qw(n time hub nick ip filename size tth)],
  'SELECT' =>
'*, (SELECT string FROM results WHERE queries.tth=results.tth LIMIT 1) AS string, (SELECT filename FROM results WHERE queries.tth=results.tth LIMIT 1) AS filename, (SELECT size FROM results WHERE queries.tth=results.tth LIMIT 1) AS size',
  'WHERE'    => ['tth != ""'],
  'ORDER BY' => 'queries.time DESC',
  'order'    => ++$order,
};
$config{'queries'}{'results top'} ||= {
  'main'    => 1,
  'periods' => 1,
  #( !$config{'use_graph'} ? () : ( 'graph' => 1 ) ),
  'show'     => [qw(n cnt string filename size tth)],                                               #time
  'desc'     => { 'ru' => 'Распространенные файлы', 'en' => 'Most stored' },
  'SELECT'   => '*, COUNT(*) as cnt',
  'FROM'     => 'results',
  'WHERE'    => ['tth != ""'],
  'GROUP BY' => 'tth',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'users top'} ||= {
  'main'     => 1,
  'class'    => 'half',
  'show'     => [qw(n time hub nick size online )],
  'SELECT'   => '*',
  'FROM'     => 'users',
  'ORDER BY' => 'size DESC',
  'order'    => ++$order,
};
$config{'queries'}{'users online'} ||= {
  'main'      => 1,
  'class'     => 'half',
  'group_end' => 1,
  'show'      => [qw(n time hub nick size online )],
  'SELECT'    => '*',
  'FROM'      => 'users',
  'WHERE'     => ['online > 0'],
  'ORDER BY'  => 'size DESC',
  'order'     => ++$order,
};
$config{'queries'}{'results top users'} ||= {
  'main'      => 1,
  'periods'   => 1,
  'class'     => 'half',
  'show'      => [qw(n cnt hub nick share)],                                                              #time
  'desc'      => { 'ru' => 'Чаще всего скачивают с', 'en' => 'they have anything' },
  'SELECT'    => '*, users.size as share, COUNT(*) as cnt',
  'FROM'      => 'results',
  'LEFT JOIN' => 'users USING (hub, nick )',
  'WHERE'    => [ 'string != ""', 'nick != ""' ],
  'GROUP BY' => 'nick',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'results top users tth'} ||= {
  'main'      => 1,
  'periods'   => 1,
  'class'     => 'half',
  'show'      => [qw(n cnt hub nick  share)],                                               #time
  'desc'      => { 'ru' => 'У них найдется все', 'en' => 'they know 42' },
  'SELECT'    => '*, users.size as share, COUNT(*) as cnt',
  'FROM'      => 'results',
  'LEFT JOIN' => 'users USING (hub, nick )',
  'WHERE'    => [ 'tth != ""', 'results.nick != ""' ],
  'GROUP BY' => 'nick',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'queries top users'} ||= {
  'main'      => 1,
  'periods'   => 1,
  'class'     => 'half',
  'show'      => [qw(n cnt hub nick share)],                                                 #time
  'desc'      => { 'ru' => 'Больше всех ищут', 'en' => 'they search "42"' },
  'SELECT'    => '*, users.size as share, COUNT(*) as cnt',
  'FROM'      => 'queries',
  'LEFT JOIN' => 'users USING (hub, nick )',
  'WHERE'    => [ 'string != ""', 'nick != ""' ],
  'GROUP BY' => 'nick',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'queries top users tth'} ||= {
  'main'      => 1,
  'periods'   => 1,
  'class'     => 'half',
  'group_end' => 1,
  'show'      => [qw(n cnt hub nick share)],                                                                   #time
  'desc'      => { 'ru' => 'Больше всех скачивают', 'en' => 'they have unlimited hdds' },
  'SELECT'    => '*, users.size as share, COUNT(*) as cnt',
  'FROM'      => 'queries',
  'LEFT JOIN' => 'users USING (hub, nick )',
  'WHERE'    => [ 'tth != ""', 'nick != ""' ],
  'GROUP BY' => 'nick',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'hubs top'} ||= {
  'main'  => 1,
  'class' => 'half',
  'show'  => [qw(n time hub users size )],    #time
                                              #'SELECT'         => 'DISTINCT hub , MAX(size), h2.*', # DISTINCT hub,size,time
                                              #!'SELECT' => '*, hub as h1'
  , #DISTINCT DISTINCT hub,size,time                                                    'FROM'     => 'hubs',  'LEFT JOIN' => 'hubs as h2 USING (hub,size)','GROUP BY' => 'hubs.hub',  'ORDER BY' => 'h2.size DESC',
    #'WHERE'    => ['time = (SELECT time FROM hubs WHERE hub=h ORDER BY size DESC LIMIT 1)'],
    #!'WHERE' => ['time = (SELECT time FROM hubs WHERE hub=h1 ORDER BY size DESC LIMIT 1)'],
  'SELECT' => '*', 'WHERE' => ['time = (SELECT time FROM hubs /*WHERE hub=h1*/ ORDER BY size DESC LIMIT 1)'],
  #'GROUP BY' => 'hubs.hub',
  #'ORDER BY' => 'size DESC',
  #'SELECT' => '*',
  'FROM' => 'hubs',
  #'GROUP BY' => 'hub',
  'ORDER BY' => 'size DESC',
#'SELECT'         => 'h2.time,h2.users, hub, max(size) as size',
#'SELECT'         => 'hubs.time, hubs.users, hub, max(size) as size',
#'SELECT'         => 'hubs.time, hubs.users, hub, size',
#'SELECT'         => 'h2.time, h2.users, hub, size',  'FROM'     => 'hubs',  'LEFT JOIN' => 'hubs AS h2' ,'USING' => '(hub, size)','GROUP BY' => 'hubs.hub',  'ORDER BY' => 'size DESC',
#'SELECT'         => 'h2.time, h2.users, DISTINCT (hub), size',  'FROM'     => 'hubs',  'LEFT JOIN' => 'hubs AS h2' ,'USING' => '(hub, size)',
#'ORDER BY' => 'size DESC',
#select    from hubs left join hubs as h2 using (hub, size) group by hubs.hub order by size desc limit 10
#'time'        'hub'         'size'        'users'
  'order' => ++$order,
};
$config{'queries'}{'hubs now'} ||= {
  'main' => 1,
  #'group_end' => 1,
  'group_end' => 1,
  'class'     => 'half',
  'show'      => [qw(n time hub users size)],
  'FROM'      => 'hubs',
  'SELECT'    => '*',
  'WHERE'     => ['time = (SELECT time FROM hubs ORDER BY time DESC LIMIT 1)'],
  'ORDER BY'  => 'size DESC',
  'order'     => ++$order,
};
$config{'queries'}{'results ext'} ||= {
  'main'     => 1,
  'class'    => 'half',
  'show'     => [qw(n cnt ext size)],
  'desc'     => { 'ru' => 'Расширения', 'en' => 'by extention' },
  'SELECT'   => '*, SUM(size) as size , COUNT(*) as cnt',
  'FROM'     => 'results',
  'WHERE'    => ['ext != ""'],
  'GROUP BY' => 'ext',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
};
$config{'queries'}{'counts'} ||= {
  'main'      => 1,
  'show'      => [qw(n tbl cnt)],
  'class'     => 'half',
  'group_end' => 1,
  'sql'       => (
    join ' UNION ',
    map         { qq{SELECT '$_' as tbl, COUNT(*) as cnt FROM $_ } }
      sort grep { !$config{'sql'}{'table_param'}{$_}{'no_counts'} } keys %{ $config{'sql'}{'table'} }
  ),
  'order' => ++$order,
};
$config{'queries'}{'chat top'} ||= {
  'main'     => 1,
  'periods'  => 1,
  'class'    => 'half',
  'show'     => [qw(n cnt hub nick)],
  'desc'     => { 'ru' => 'Находки для шпиона', 'en' => 'top flooders' },
  'SELECT'   => '*, COUNT(*) as cnt',
  'FROM'     => 'chat',
  'GROUP BY' => 'nick',
  'ORDER BY' => 'cnt DESC',
  'order'    => ++$order,
  'slow'     => 1,
};
$config{'queries'}{'chat last'} ||= {
  'main'           => 1,
  'class'          => 'half',
  'desc'           => { 'ru' => 'Сейчас в чате', 'en' => 'online' },
  'group_end'      => 1,
  'no_string_link' => 1,
  'show'           => [qw(n time hub nick string)],
  'SELECT'         => '*',
  'FROM'           => 'chat',
  'ORDER BY'       => 'time DESC',
  'order'          => ++$order,
};
$config{'queries'}{'string'} ||= {
  'show'          => [qw(n cnt string  filename size tth)],
  'no_query_link' => 1,
  'SELECT'        => '*, COUNT(*) as cnt',
  'WHERE'         => ['tth != ""'],
  'GROUP BY'      => 'tth',
  'ORDER BY'      => 'cnt DESC',
  'FROM'          => 'results',
};
$config{'queries'}{'tth'} ||= {
  %{ $config{'queries'}{'string'} },
  'desc'     => { 'ru' => 'Имена файла', 'en' => 'various filenames' },
  'show'     => [qw(n cnt string filename size tth)],
  'GROUP BY' => 'filename',
};
$config{'queries'}{'filename'} ||= {
  %{ $config{'queries'}{'string'} },
  'desc'     => { 'ru' => 'Разное содержимое', 'en' => 'various tth' },
  'show'     => [qw(n cnt string filename size tth)],
  'GROUP BY' => 'tth',
};
psmisc::configure( 0, 0, 0, 1 );

sub is_slow {
  my ($query) = @_;
  return ( (
            $config{'sql'}{'table_param'}{ $config{'queries'}{$query}{'FROM'} }{'big'}
        and $config{'queries'}{$query}{'GROUP BY'}
        and $config{'queries'}{$query}{'main'}
    )
      or $config{'queries'}{$query}{'slow'}
  );
}

sub make_query {
  my ( $q, $query, $period ) = @_;
  my $sql;
  #warn Dumper caller(0);
  #(caller(0))[1] eq 'statcgi'
  #return ;
  if ( is_slow($query) and ( caller(0) )[0] eq 'statcgi' and $config{'use_slow'} ) {
    #warn "SLOWweb";
    $sql =
        "SELECT * FROM ${tq}slow${tq} WHERE name = "
      . $db->quote($query)
      . ( ( $config{'queries'}{$query}{'periods'} ? ' AND period=' . $db->quote($period) : '' )
      . " ORDER BY n"
        . " LIMIT $config{'query_default'}{'LIMIT'}" );
    my $res = $db->query($sql);
    #print Dumper $res if $param->{'debug'};
    my @ret;
    for my $row (@$res) { push @ret, eval $row->{'result'}; }
    #print Dumper @ret if $param->{'debug'};
    return \@ret;
  }
  #warn "SLOWcalc";
  #return;
  $q->{'WHERE'} = join ' AND ', grep { $_ } @{ $q->{'WHERE'}, } if ref $q->{'WHERE'} eq 'ARRAY';
  $q->{'WHERE'} = join ' AND ', grep { $_ } $q->{'WHERE'},
    map { $_ . '=' . $db->quote( $param->{$_} ) } grep { length $param->{$_} } keys %{ $config{'queries'} };    #qw(string tth);
  $sql = join ' ', $q->{'sql'},
    map { my $key = ( $q->{$_} || $config{query_default}{$_} ); length $key ? ( $_ . ' ' . $key ) : '' } 'SELECT', 'FROM',
    'LEFT JOIN', 'USING', 'WHERE', 'GROUP BY', 'HAVING', 'ORDER BY', 'LIMIT', 'UNION';
  return $db->query($sql);
}
$db ||= pssql->new( %{ $config{'sql'} || {} }, );
( $tq, $rq, $vq ) = $db->quotes();

#=todo
{
 my $self = $db;


  $self->{'array_hash_repl'} = sub {
    my $self = shift;
    my $r = shift;
    return {} if  !$self->{'sth'} or !$r;
      my $i = -1;
      my %uniq;
      $r = { map {++$i; $_=>($r->[$i] ? $uniq{$_} = $r->[$i] : $uniq{$_})  } @{$self->{'sth'}{'NAME'}} };
    return $r;
  };
  $self->{'array_hash_add'} = sub {
    my $self = shift;
    my $r = shift;
    return {} if  !$self->{'sth'} or !$r;
      my $i = -1;
      my %uniq;
      $r = { map {++$i; $_=>($uniq{$_} ||= $r->[$i])  } @{$self->{'sth'}{'NAME'}} };
    return $r;
  };
  $self->{'fetch_hash'} = sub {
    my $self = shift;
    #return $self->{'sth'}->fetchrow_hashref();
    local $_ = $self->{'sth'}->fetchrow_arrayref() || return;
#print 'A:',Dumper $self->{'sth'}{'NAME'},$_;
    #return $self->array_hash_add( $_ );
    return $self->array_hash_repl( $_ );
  };

  $self->{'array_to_hash'} = sub {
    my $self = shift;
  };

  $self->{'line'} = sub {
    my $self = shift;
    return {} if @_ and $self->prepare(@_);
    return {} if !$self->{'sth'} or $self->{'sth'}->err;
    my $tim = psmisc::timer();
    local $_ =
      scalar( psmisc::cp_trans_hash( $self->{'codepage'}, $self->{'cp_out'}, ( 
      #$self->array_to_hash( $self->{'sth'}->fetchrow_arrayref() )
      $self->fetch_hash()
      #$self->{'sth'}->fetchrow_hashref() || {} 
      ) ) );
    $self->{'queries_time'} += $tim->();
    $self->log(
      'dmp', 'line:[', @_, '] = ', scalar keys %$_,
      ' per', psmisc::human( 'time_period', $tim->() ),
      'err=', $self->err(),
    ) if ( caller(2) )[0] ne 'pssql';
    return $_;
  }if $self->{'driver'} =~ /mysql/;


  $db->{'query'} = sub {
    my $self = shift;
    my $tim  = psmisc::timer();
    my @hash;
    for my $query (@_) {
      next unless $query;
      local $self->{'explain'} = 0, $self->query_log( $self->{'EXPLAIN'} . ' ' . $query )
        if $self->{'explain'} and $self->{'EXPLAIN'};
      local $_ = $self->line($query);
      next unless keys %{$_};
      push( @hash, $_ );
      next unless $self->{'sth'} and keys %{$_};
      my $tim = psmisc::timer();
      #$self->log("Db[",%$_,"]($self->{'codepage'}, $self->{'cp_out'})"),
      #print 'name', Dumper $self->{sth}{'NAME'};
      #while ( my $r = $self->{'sth'}->fetchrow_arrayref()  ) {
      while ( my $r = $self->fetch_hash() ) {
#print 'H:',Dumper $r;
            

      #$r = $self->array_to_hash($r);
#print "r[$r]", Dumper $r;
      push( @hash, scalar psmisc::cp_trans_hash( $self->{'codepage'}, $self->{'cp_out'}, $r ) );
      #print Dumper \%uniq;
      }
        #$self->log("Da[",%$_,"]"),
        #while ( $_ = $self->{'sth'}->fetchrow_hashref() );
#print 'name', Dumper $self->{sth}{'NAME'}, $self->{sth}{'NAME_hash'} ,Dumper @hash;
      $self->{'queries_time'} += $tim->();
    }
    $self->log(
      'dmp', 'query:[', @_, '] = ', scalar @hash, ' per', psmisc::human( 'time_period', $tim->() ),
      'rps', psmisc::human( 'float', ( scalar @hash ) / ( $tim->() || 1 ) ),
      'err=', $self->err()
    );
    $self->{'dbirows'} = scalar @hash if $self->{'no_dbirows'} or $self->{'dbirows'} <= 0;
    #$self->query_print($_) for @hash;
    #$self->log('qcp', $self->{'codepage'});
    if ( $self->{'codepage'} eq 'utf-8' ) {
      for (@hash) { utf8::decode $_ for %$_; }
    }
    return wantarray ? @hash : \@hash;
  } if $self->{'driver'} =~ /mysql/;
}
#=cut


1;
