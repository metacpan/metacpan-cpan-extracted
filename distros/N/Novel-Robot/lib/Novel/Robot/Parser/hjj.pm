# ABSTRACT: http://bbs.jjwxc.net
package Novel::Robot::Parser::hjj;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';

use Web::Scraper;

sub base_url { 'http://bbs.jjwxc.net' }

sub charset { 'cp936' }

sub class { 'tiezi' }

sub parse_novel {
  my ( $self, $h, $r) = @_;
  my %t;
  for ( $$h ) {
    ( $t{title} )   = m{<td bgcolor="\#E8F3FF"><div [^>]+?style="float: left;">\s*主题：(.+?)\s*<font color="\#999999" size="-1">}s;
    ( $t{content} ) = m{<td class="read"><div id="topic" >(.*?)</div>\s*</td>\s*</tr>\s*</table>}s;
    $t{content} ||= '';
    $t{content} =~ s#</?font[^>]+>##sg;
    ( $t{writer}, $t{time} ) =
      m#№0 </font>.*?☆☆☆</font>(.*?)</b><font color="99CC00">于</font>(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})留言#s;

    $t{writer} ||= 'unknown';
    $t{writer} =~ s/<\/?(font|b).*?>//gsi;
    $t{id} = 0;
  }

  return \%t;
} ## end sub parse_novel

sub parse_novel_item {
  my ( $self, $h ) = @_;

  my @item;
  my @cc = $$h =~ m#(<td[^>]*?class="read"[^>]*?>.*?<td class="authorname">.*?</tr>)#gis;
  #print $#cc;
  exit;
  for my $cell (@cc) {
    next unless ( $cell );

    my %fl;

    ( $fl{writer}, $fl{time} ) =
      $cell =~ m#☆☆☆</font>\s*(.*?)\s*<font color="99CC00">于</font>(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})留言#s;
    $fl{writer} =~ s/<\/?(font|b).*?>//gsi;
    $fl{writer} =~ s/^-*//;
    $fl{writer} ||= 'unknown';

    ($fl{content})=$cell=~m#<td[^>]*?class="read"[^>]*?>(.*?)<td class="authorname">#s;
    for ( $fl{content} ) {
      s#本帖尚未审核,若发布24小时后仍未审核通过会被屏蔽##s;
      s#</?font[^>]*>##isg;
      s#</?(b|u)>##sig;
    }

    $fl{title} = '';
    ( $fl{id} ) = $cell =~ m{№(\d+)</font>}s;

    push @item, \%fl;
  } ## end while ( $$h =~ m#(<tr class="reply_\d+">\s+<td colspan="2">.*?<td><font color=99CC00 size="-1">.*?</tr>)#gis)
  shift @item;

  return \@item;
} ## end sub parse_novel_item

sub parse_item_list {
  my ( $self, $h ) = @_;
  my ( $page_info ) = $$h =~ m[<div id="pager_top" align="center" style="padding:10px;">(.+?)</div>]s;
  return unless ( $page_info );

  my ( $page_num, $page_url ) = $page_info =~ m[共(\d+)页.+?<a href=(.+?page=)\d]s;
  my @urls =
    map { $self->base_url()."/showmsg.php$page_url$_" } ( 1 .. $page_num - 1 );
  return \@urls;
}

sub parse_board {
  my ( $self, $h ) = @_;
  my ( $title ) =
    $$h =~ m[<div style="float:left;position:relative;padding-top:3px;padding-left:4px;"><font color="red">(.+?)</font></div>]s;
  return { title => $title };
}

sub parse_board_item {
  my ( $self, $h ) = @_;

  my @tz_list =
    split( /<tr valign="middle" bgcolor="#FFE7F7">/, $$h );
  shift @tz_list;

  my @res;
  for ( @tz_list ) {
    my %temp = ();
    @temp{qw/url title/} = m{href="(showmsg.php\?board=\d+[^>]*?&id=\d+)[^>]+>(.+?)</a>}s;
    next unless ( $temp{url} );

    @temp{qw/writer/} = m{</td></tr></table></td>\s+<td>&nbsp;(.+?)</td>}s;
    @temp{qw/time/}   = m{<td align="center"><font size="-1">(.+?)</font></td>}s;
    $temp{url}        = $self->base_url()."/$temp{url}";

    $temp{writer} =~ s/<[^>]+>//sg;
    $temp{title} =~ s#</?font[^>]*>##gs;
    $temp{title} =~ s#&nbsp;##gs;
    $temp{title} =~ s/^\s+|\s+$//sg;
    push @res, \%temp;
  }

  return \@res;
} ## end sub parse_board_item

sub parse_board_list {
  my ( $self, $h ) = @_;
  my ( $u ) = $$h =~ m{href=(board.php\?[^>]+?page=)\d+\s+><img src="img/anniu1.gif" alt="下一页"}s;
  my ( $n ) = $$h =~ m{共<font color="\#FF0000">(\d+)</font>页}s;
  my @board_urls =
    map { $self->base_url()."/$u$_" } ( 2 .. $n );
  return \@board_urls;
}

1;
