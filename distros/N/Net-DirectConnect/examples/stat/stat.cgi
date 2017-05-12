#!/usr/bin/perl
#$Id: stat.cgi 792 2011-06-09 21:44:44Z pro $ $URL: svn://svn.setun.net/dcppp/trunk/examples/stat/stat.cgi $
package statcgi;
use strict;
use utf8;
use MIME::Base64;
eval { use Time::HiRes qw(time sleep); };
use Data::Dumper;    #dev only
$Data::Dumper::Sortkeys = $Data::Dumper::Useqq = $Data::Dumper::Indent = 1;
our ( %config, $param, $db, );
use lib::abs qw(../../lib ./);
use statlib;
binmode( STDOUT, ":utf8" );
#our $root_path;
#BEGIN {
#  ( $ENV{'SCRIPT_FILENAME'} || $0 ) =~ m|^(.+)[/\\].+?$|;                                                             #v0w
#  $root_path = $1 . '/' if $1;
#  $root_path =~ s|\\|/|g;
#  eval "use lib '$root_path'" if $root_path;
#  eval "use lib '$root_path./pslib'; use psmisc; use pssql;";    # use psweb;
#  print( "Content-type: text/html\n\n", " lib load error rp=$root_path o=$0 sf=$ENV{'SCRIPT_FILENAME'}; ", $@ ), exit if $@;
#}
#use lib::abs ;
use Net::DirectConnect::pslib::psmisc
  #qw(%config)
  ;    # qw(:config :log printlog);
psmisc->import qw(:log);

sub part ($;@) {
  my $name = shift;
  psmisc::code_run( $config{'out'}{ $config{'view'} }{$name} || $config{'out'}{''}{$name}, @_ );
}
#first is default
our @colors = qw(black aqua gray navy silver green olive teal blue lime purple magenta maroon red yellow);
#$param = psmisc::get_params();
$param = psmisc::get_params_utf8();
delete $param->{'period'} unless exists $config{'periods'}{ $param->{'period'} };
$config{'view'} = $param->{'view'} || 'html';
#$config{'view'} = 'rss';
#warn Dumper $config{'human'};
$config{'out'}{'html'}{'http-header'} = sub {
  print "Content-type: text/xml; charset=utf-8\n\n";
};
$config{'out'}{'rss'}{'http-header'} = sub {
  print "Content-type: application/rss+xml; charset=utf-8\n\n";
};
part 'http-header' if $ENV{'SERVER_PORT'};
$config{'out'}{'rss'}{'footer'} = sub { print '</channel></rss>'; };
$config{'log_all'}     = '0' unless $param->{'debug'};
$config{'log_default'} = '#';
$config{'log_dmp'}     = $config{'log_dbg'} = 1,
  #$db->{'explain'} = 1,
  if $param->{'debug'};
#$config{'view'} = 'html';
$config{'lang'} = 'ru';
$db->retry_off();
$db->set_names();
my ( $tq, $rq, $vq ) = $db->quotes();
$config{'query_default'}{'LIMIT'} = psmisc::check_int( $param->{'on_page'}, 10, 100, 10 );
$param->{'period'} ||= $config{'default_period'};
$config{'human'}{'magnet-dl'} = sub {
  my ($row) = @_;
  $row = { 'tth' => $row } unless ref $row eq 'HASH';
  my $tth = ( $row->{'tth_orig'} || $row->{'tth'} );
  my $string = $row->{'string_orig'} || $row->{'string'};
  $string ||= $tth, $tth = undef, unless $tth =~ /^[0-9A-Z]{39}$/;
  local $_ = join '&amp;', grep { $_ } ( $tth ? 'xt=urn:tree:tiger:' . $tth : '' ),
    ( $row->{'size'}     ? 'xl=' . $row->{'size'}                           : '' ),
    ( $row->{'filename'} ? 'dn=' . psmisc::encode_url( $row->{'filename'} ) : '' ),
    ( $string            ? 'kt=' . psmisc::encode_url($string)              : '' ),
    ( ( $row->{'hub'} and $row->{'hub'} ne 'localhost' ) ? 'xs=dchub://' . $row->{'hub'} : '' );
  return
      '&nbsp;<a class="magnet-darr" href="magnet:?' 
    . $_
    . '">[&dArr;]</a> <a href="http://dc.proisk.ru/?'
    . ( $row->{'string'} ? "q=" . $row->{'string'} : "tiger=$row->{'tth'}" )
    . '">P</a>'
    if $_;
  return '';
};
$config{'human'}{'dchub-dl'} = sub {
  my ($row) = @_;
  $row = { 'hub' => $row } unless ref $row eq 'HASH';
  #print "[$row->{'hub'}; $row->{'nick'}]";
  return
      '&nbsp;<a class="magnet-darr" href="dchub://'
    . ( join '/', grep { $_ } map { $row->{$_} } qw(hub nick) )
    . '">[&dArr;]</a>'
    if length $row->{'hub'};
};
#print '<a>', psmisc::html_chars( $param->{'tth'} ), '</a>', psmisc::human( 'magnet-dl', $param->{'tth'} ), '<br/>'  if $param->{'tth'};
my @ask;
$config{'queries'}{'string'}{'desc'} = psmisc::html_chars( $param->{'string'} ), @ask = ('string') if $param->{'string'};
@ask = ('tth')      if $param->{'tth'};
@ask = ('filename') if $param->{'filename'};
@ask = ( $param->{'query'} ) if $param->{'query'} and $config{'queries'}{ $param->{'query'} };
$config{'query_default'}{'LIMIT'} = 100 if scalar @ask == 1;
my %makegraph;
my %graphcolors;
my $rss_link = ( @ask ? '?' . $ENV{'QUERY_STRING'} : '?query=queries+top+tth' );
$config{'out'}{'html'}{'head'} = sub {
  #print "Content-type: text/xml; charset=utf-8\n\n" if $ENV{'SERVER_PORT'};
  #print qq{<!DOCTYPE html>
  print qq{<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:svg="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<head><title>RU DC stat</title>
<link href="style.css" rel="stylesheet" type="text/css"/>
<link rel="alternate" type="application/rss+xml" title="RSS version" href="}, psmisc::html_chars( $rss_link . '&view=rss' ),
    qq{"/>

<style></style></head><body><script type="text/javascript" src="pslib/lib.js"></script>};
#print '    <svg:svg version="1.1" baseProfile="full" width="300px" height="200px">      <svg:circle cx="150px" cy="100px" r="50px" fill="#ff0000" stroke="#000000" stroke-width="5px"/>    </svg:svg>';
};
part 'head';
$config{'out'}{'html'}{'header'} = sub {
  print '<a href="?">home</a>';
  print ' days ', (
    map {
          '<a '
        . ( $param->{'period'} eq $_ ? '' : qq{href="?period=$_"} )
        . qq{ onclick="createCookie('period', '$_');window.location.reload(false);">}
        . psmisc::human( 'time_period', $config{'periods'}{$_} ) . '</a> '
      } sort {
      $config{'periods'}{$a} <=> $config{'periods'}{$b}
      } keys %{ $config{'periods'} }
    )
    unless (
    grep {
      $param->{$_}
    } qw(string tth)
    ) or ( $param->{'query'} and !$config{'queries'}{ $param->{'query'} }{'periods'} );
  print '<br/>';
  print
qq{<div class="main-top-info">Для скачивания файлов по ссылке <a class="magnet-darr">[&dArr;]</a> необходим <a href="http://en.wikipedia.org/wiki/DC%2B%2B#Client_software_comparison">dc клиент</a></div>};
};
part 'header';
my @queries = @ask ? @ask : sort { $config{'queries'}{$a}{'order'} <=> $config{'queries'}{$b}{'order'} }
  grep { $config{'queries'}{$_}{'main'} } keys %{ $config{'queries'} };
for my $query (@queries) {
  my $q = { %{ $config{'queries'}{$query} || next } };
  next if $q->{'disabled'};
  $q->{'desc'} = $q->{'desc'}{ $config{'lang'} } if ref $q->{'desc'} eq 'HASH';
  $config{'out'}{'rss'}{'table-head'} = sub {
    #my ( $param, $table ) = @_;
    #$work{'param_str'} = get_param_url_str( $param, $config{'skip_from_link'} );
    #$work{'rssn'} = $work{'n'} = $static{'db'}->{'limit_offset'};
    print '<?xml version="1.0" encoding="utf-8"?>';
    #print '<?xml-stylesheet type="text/css" href="', $config{'root_url'}, $config{'css'}, '" ?>' if $config{'css'};
    print '<rss version="2.0" xmlns:dc="http://purl.org/dc/elements/1.1/">', '<channel>';
    print '<title>', $config{'title'}, ' :: ', $query, '</title>' if $config{'title'};
    print '<link>',        $config{'root_url'},         '</link>'        if $config{'root_url'};
    print '<description>', $config{'rss2_description'}, '</description>' if $config{'rss2_description'};
    #print '<language>', lang('language-code'), '</language>';
    print "\n\n";
  };
  $config{'out'}{'html'}{'table-head'} = sub {
    print '<div class="onetable ' . $q->{'class'} . '">', (
        $q->{'no_query_link'}
      ? $query
        . join( '',
         !( $query eq 'tth' and $param->{'tth'} )
        ? ( !( $param->{$query} ) ? () : "= " . psmisc::html_chars( $param->{$query} ) )
        : ( '= <a>', psmisc::html_chars( $param->{'tth'} ), '</a>', psmisc::human( 'magnet-dl', $param->{'tth'} ), '<br/>' ) )
      : '<a href="?query=' . psmisc::encode_url($query) . '">' . ( $q->{'desc'} || $query ) . '</a>'
      )
      . ' <a class="rss" href="'
      . psmisc::html_chars( ( @queries > 1 ? '?query=' . psmisc::encode_url($query) : $rss_link ) . '&view=rss' )
      . '">RSS</a>';
    #print Dumper \%ENV;
    #print Dumper @ask;
    #print " ($q->{'desc'}):" if $q->{'desc'};
    print "<br\n/>";
    print psmisc::human( 'time_period', time - $param->{'time'} ) 
      . "<table"
      . ( !$config{'use_graph'} ? () : ' class="graph"' ) . ">";
    my %sort = map { $_ => 1 } @{ $q->{'sort'} };
    print '<th>',
      $sort{$_} ? qq{<a href="} . psmisc::html_chars( qq{?sort=$_&query=} . psmisc::encode_url($query) ) . qq{">$_</a>} : $_,
      '</th>'
      for @{ $q->{'show'} };
  };
  part 'table-head';
  my $res = statlib::make_query( $q, $query, $param->{'period'} );
  #warn Dumper $res;
  $res =
    [ sort { $b->{ $param->{'sort'} } <=> $a->{ $param->{'sort'} } || $b->{ $param->{'sort'} } cmp $a->{ $param->{'sort'} } }
      @$res ]
    if $param->{'sort'};
  push @{ $q->{'show'} }, $param->{'sort'} if $param->{'sort'} and !grep { $_ eq $param->{'sort'} } @{ $q->{'show'} };
  my $n;
  for my $row (@$res) {
    ++$n;
    #utf8::encode $_ for %$row;
    $row->{$_} = psmisc::html_chars( $row->{$_} ) for @{ $q->{'show'} };
    $row->{'n'} ||= $n;
    $row->{'orig'} = {%$row};
    #warn $row->{nick};
    #$row->{'tth_orig'}    = $row->{'tth'};
    #$row->{'string_orig'} = $row->{'string'};
    my $graphcolor;
    if ( $q->{'graph'} ) {
      my $by = $q->{'GROUP BY'};
      #print "m=$main ";
      $by =~ s/.*\.//;
      #print "M==$main ";
      my ($v) = map { $row->{'orig'}{$_} } grep { $by eq $_ } @{ $q->{'show'} };
      $makegraph{$query}{$v} = $by;
      $graphcolor = $graphcolors{$v} = $colors[$n];    #if length $query;
                                                       #my $id = $query;
                                                       #$id =~ tr/ /_/;
    }
    $row->{'tth_show'} = 'tth' if $config{'view'} eq 'rss';
    $row->{ $_ . '_html' } = (
      $param->{$_}
      ? ''
      : qq{<a class="$_" title="}
        . psmisc::html_chars( $row->{$_} )
        . qq{" href="?$_=}
        . psmisc::encode_url( $row->{$_} ) . qq{">}
        . ( $row->{ $_ . '_show' } || $row->{$_} )
        . qq{</a>}
      )
      . psmisc::human( 'magnet-dl', $row->{'orig'} )
      for grep { length $row->{$_} and !$q->{ 'no_' . $_ . '_link' } }
      grep { $config{'queries'}{$_} } @{ $q->{'show'} };    #qw(string tth);
    $row->{ $_ . '_html' } = psmisc::human( 'time_period', time - $row->{$_} ) for grep { int $row->{$_} } qw(time online);
    $row->{ $_ . '_rss' } = psmisc::human( 'date_time', $row->{$_}, ' ', '-' ) for grep { int $row->{$_} } qw(time online);
    $row->{'hub'} .= psmisc::human( 'dchub-dl', { 'hub' => $row->{'orig'}->{'hub'} } ) if $row->{'hub'};
    #$row->{'nick'} .= psmisc::human( 'dchub-dl', $row->{'orig'} ) if $row->{'nick'};
    $row->{$_} = psmisc::human( 'size', $row->{$_} ) for grep { int $row->{$_} } qw(size share);
    $config{'out'}{'html'}{'table-row'} = sub {
      print '<tr>';
      #'<td>', $n, '</td>';
      print '<td>', $row->{ $_ . '_html' } // $row->{$_}, '</td>' for @{ $q->{'show'} };
      if ( $q->{'graph'} ) {
        print qq{<td style="background-color:$graphcolor;">&nbsp;</td>} if $config{'use_graph'};
        print qq{<td class='graph' id='$query' rowspan='100' style='min-width:100px;'> </td>} if $n == 1;
#print qq{<td class='graph' rowspan='100' width='100%'><img id='$query' src='' NOtype='image/svg+xml' width='100%' height='100%'/></td>}    if $n == 1;
#print qq{<td class='graph' rowspan='100' width='100%'><img id='$query' src='' width='100%' /></td>}    if $n == 1;
        print qq{<td style="background-color:$graphcolor;">&nbsp;</td>} if $config{'use_graph'};
      }
      print '</tr>';
    };
    $config{'out'}{'rss'}{'table-row'} = sub {
      #my ( $param, $table, $row ) = @_;
      my ($row) = @_;
      #printlog('dev', Dumper $row);
      print '<item>';
      #"\n<link>", get_param_url_str( $param, ['view'] ), '#n', ( ++$work{'rssn'} ), '</link>';
      #'<description>';
      #my $buffer;
      #$buffer .= '<table>';
      #print 'ITEMS:[' ,join',',%$row;
      #$buffer .= '</table>';
      #html_chars( \$buffer );
      #print $buffer;
      #print '</description>';
      #$row->{'link'} ||=  'link';
      my $key;
      my $title;
      $row->{'title'} ||= $row->{filename} || $row->{string} || $row->{tth} || $row->{line} || $row->{nick} || $row->{hub};
      for (qw(filename string tth line nick  hub time)) {
        $title ||= $_ if $row->{$_};
        $row->{'title'} ||= $row->{$title};
      }
      my $unique;
      for (qw(tth filename string nick  hub time)) {
        $key ||= $_ if $row->{$_};
        $unique ||= $row->{$key};
      }
      #print "UNIQ1[$unique:$config{'rss2_guid'}]";#, join',',%$row;
      psmisc::html_chars( \$unique );
      $row->{'guid'} ||= $unique;
      #print "UNIQ[$unique]";#, join',',%$row;
      $row->{'description'} ||= '<![CDATA['
        . (
        join ' ', map { $row->{ $_ . '_rss' } || $row->{ $_ . '_html' } || $row->{$_} } grep { $_ ne $title } @{ $q->{'show'} }
        ) . ']]>';
      #$row->{'description'} ||= 'desc';
      #warn "time[$row->{'time'}]";
      $row->{'pubDate'} ||= psmisc::human( 'rfc822_date_time', $row->{'time'} );
      #$row->{'link'} ||= get_param_url_str( $param, ['view'] ), '#n', ( ++$work{'rssn'} );
      $row->{'link'} ||= "?$key=" . psmisc::encode_url($unique);
      $row->{'author'} ||= $row->{'nick'} || 'dcstat';
      print '<', $_, '>', $row->{$_}, '</', $_, ">\n"
        for grep { $row->{$_} } qw(title description author category comments guid pubDate link);
      #'<pubDate>', , '</pubDate>',
      #"<guid></guid>"
      print "</item>\n";
    };
    part 'table-row', $row;
  }
  $config{'out'}{'html'}{'table-foot'} = sub {
    print '</table></div>';
    print '<br/>' if $q->{'group_end'};
  };
  part 'table-foot';
  psmisc::flush();
}
my $graphtime = time;
$config{'out'}{'html'}{'graph'} = sub {
  #print Dumper \%makegraph;
  for my $query ( sort keys %makegraph ) {
    #last;
    my $q = { %{ $config{'queries'}{$query} || next } };
    my $table = $query;
    my %graph;
    my %dates;
    $table =~ s/\s/_/g;
    $table .= '_' . $param->{'period'};
    my ($by) = values %{ $makegraph{$query} };
    my ( $maxy, %date_max, %date_min, %date_step, );

    for my $row (
      $db->query(
            "SELECT * FROM $table WHERE ("
          . ( join ' OR ', map { "${rq}$by${rq}=" . $db->quote($_) } keys %{ $makegraph{$query} } )
          . ") AND ${rq}time${rq} >= "
          . $db->quote( int time - ( $config{'periods'}{ $param->{'period'} } * 30 ) )
          . " ORDER BY ${tq}time${tq} DESC "
      )
      )
    {
      #for my $row ( $db->query("SELECT * FROM $table  " ) ) {
      psmisc::printlog 'dev', Dumper $row;
      next if $row->{tth} eq 'LWPNACQDBZRYXW3VHJVCJ64QBZNGHOHHHZWCLNQ';
      my $by = $makegraph{$query}{ $row->{tth} } || $makegraph{$query}{ $row->{string} };
#print " $row->{date}, $row->{n}, $row->{cnt} <br/>" if $makegraph{$query}{$row->{tth}} eq 'tth' or $makegraph{$query}{$row->{string}} eq 'string';
#$row->{date} .= '-'. (localtime $row->{time})[2];
      ++$dates{ $row->{date} };
      #{$query}
      my $graphby = $row->{cnt};
      #my $graphby = $row->{n};
      $graph{ $row->{$by} }{ $row->{date} } = $graphby if length $row->{$by};
      #{ $graph$row->{$by} }{ $row->{date} } = $row->{cnt} if length $row->{$by};
      #$maxy = $row->{cnt} if $row->{cnt} > $maxy;
      $maxy = $graphby if $graphby > $maxy;
      $date_max{ $row->{date} } = $graphby if $graphby > $date_max{ $row->{date} };
      $date_min{ $row->{date} } = $graphby if $graphby < $date_min{ $row->{date} } or !$date_min{ $row->{date} };
    }
    #next;
    #my $id  = $query;
    #$id =~ tr/ /_/;
    my $xl = 1000;
    my $yl = 700;
    my $xs = int( $xl / ( scalar keys(%dates) - 1 or 1 ) );
    #my $yn = 10;
    my $yn = $maxy || 1;
    my $ys = $yl / $yn;
    for my $date (%date_max) {
      $date_step{$date} = $date_max{$date} ? $yl / $date_max{$date} : 1;
      #$date_step{$date} = $date_max{$date} ?  $date_max{$date} / $yl : 1;
      #psmisc::printlog 'dev', "$date: [$date_step{$date}] yn=$yn; ys=$ys $yl<br\n/>";
    }
    #my $ys = int $yl / $maxy;
    #$ys = 1;
    #psmisc::printlog 'dev', "yn=$yn; ys=$ys<br\n/>";
    my $svgns = $config{'graph_inner'} ? 'svg:' : '';
    my $img =    #join '',
      (
      $config{'graph_inner'}
      ? ()
      : qq{<?xml version="1.0" standalone="no"?>}
        .
        #qq{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.0//EN" "http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd">}.
        qq{<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">}
      )
      . qq{<${svgns}svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100%" height="100%" viewBox="0 0 $xl $yl">}
#qq{<${svgns}circle cx="150px" cy="100px" r="50px" fill="#ff0000" stroke="#000000" stroke-width="5px"/>},
#qq{<g fill="none" stroke="red" stroke-width="3">},
#qq{<path d="M100,100 Q200,400,300,100"/>},
#qq{ <rect x="1" y="1" width="1198" height="398"         fill="none" stroke="blue" stroke-width="2" />},
#qq{ <polyline fill="none" stroke="blue" stroke-width="10"              points="50,375                     150,375 150,325 250,325 250,375                     350,375 350,250 450,250 450,375                     550,375 550,175 650,175 650,375                     750,375 750,100 850,100 850,375                     950,375 950,25 1050,25 1050,375                     1150,375" />},
      ;
    #my $color = 0;
    psmisc::printlog 'dev', $yl, Dumper \%date_max, \%date_min, \%date_step;
    for my $line ( sort keys %graph ) {
      my $n;
      #$colors[$color] <!-- $line : -->
      $img .=
          qq{ <polyline fill="none" stroke="}
        . ( $graphcolors{$line} || $colors[0] )
        . qq{" stroke-width="3" points="};    #. #( #"mc
                                              # join ' ',
      for ( sort keys %dates ) {
	if (  $graph{$line}{$_}   ) {
        #      map {
        #$graph{$line}{$_} = $yl - $graph{$line}{$_};
        if ( my $v = $graph{$line}{$_} ) {    # ? () : (
          $v = $yl if $v > $yn;
          $v = $v - $date_min{$_};
          $img .= int( $n * $xs ) . ',' . int(
            $yl -
              #( $graph{$line}{$_} > $yn ? $yl : ( $graph{$line}{$_} || $yn ) * $ys )
              #( $graph{$line}{$_} > $yn ? $yl : ( $graph{$line}{$_} || $yn ) * $date_step{$_} )
              $v * $date_step{$_}
          ) . ' ';
        }
	}
        ++$n;
        #)
        #       }
        #      ).
      }
      $img .= qq{" />};
      #++$color;
    }
    my $n;
    for ( sort keys %dates ) {
      my $tx = ( $n++ * $xs );
      my $ty = ( $yl - 10 );
      $img .= qq{<text x="$tx" y="$ty" font-size="20" transform="rotate(270 $tx $ty)">$_</text>};
    }
    $img .=
      #qq{</g>},
      qq{</${svgns}svg>},;
#print qq{<script type="text/javascript" language="JavaScript"><![CDATA[},qq{gid('$query').src='data:image/svg+xml;base64,}, encode_base64($img, ''),
#print qq{<script type="text/javascript" language="JavaScript"><![CDATA[},qq{gid('$query').src='data:image/svg+xml;}, psmisc::encode_url($img, ''),
#print qq{<script type="text/javascript" language="JavaScript"><![CDATA[},qq{gid('$query').},qq{src='data:image/svg+xml;base64,}, encode_base64($img, ''),
    print qq{<script type="text/javascript" language="JavaScript"><![CDATA[}, qq{gid('$query').innerHTML='}, (
      $config{'graph_inner'} ? qq{$img} : (
        qq{<img width="100%" src="data:image/svg+xml;base64,}, encode_base64( $img, '' ),
#print  qq{<script type="text/javascript" language="JavaScript"><![CDATA[},qq{gid('$query').src='data:image/svg+xml;}, psmisc::encode_url($img),
#print  qq{<script type="text/javascript" language="JavaScript"><![CDATA[},qq{gid('$query').src='data:image/svg;}, psmisc::encode_url($img),
#print qq{<script type="text/javascript" language="JavaScript"><![CDATA[},qq{gid('$query').innerHTML='}, $img,
        qq{"/>},
      )
      ),
      qq{';}, qq{]]></script>};
    #printlog 'dev', Dumper \%graph, \%dates;
  }
};
part 'graph';
$config{'out'}{'html'}{'footer'} = sub {
  print
    #log'dev',
    '<div>graph per ', psmisc::human( 'time_period', time - $graphtime ), '</div>' if $config{'use_graph'} and %makegraph;
  print
qq{<div class="version"><a href="http://svn.setun.net/dcppp/trac.cgi/browser/trunk/examples/stat">dcstat</a> from <a href="http://search.cpan.org/dist/Net-DirectConnect/">Net::DirectConnect</a> vr}
    . ( split( ' ', '$Revision: 792 $' ) )[1]
    . qq{</div>};
  print '<script type="text/javascript" src="http://iekill.proisk.ru/iekill.js"></script>';
  part 'footer_aft';
  print '</body></html>';
};
part 'footer_bef';
part 'footer';
#print "<pre>";
#print Dumper $param;
#print Dumper \%ENV;
