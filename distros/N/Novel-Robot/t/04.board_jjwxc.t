#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib 'lib';

use Novel::Robot;
use Test::More;

{
    package Local::BoardBrowser;

    sub new {
        my ( $class, $html ) = @_;
        return bless { html => $html }, $class;
    }

    sub request_url {
        my ( $self ) = @_;
        return $self->{html};
    }
}

my $html = <<'HTML';
<html><body>
<span itemprop="name">牵机</span>
<table>
  <tr bgcolor="#eefaee"><td colspan="7"><b>【旧事系列】</b></td></tr>
  <tr bgcolor="#eefaee">
    <td><a href="onebook.php?novelid=14838">断情逐妖记</a></td>
    <td>原创-言情</td><td>连载</td><td>48518</td>
  </tr>
  <tr bgcolor="#eefaee">
    <td><a href="//www.jjwxc.net/onebook.php?novelid=14446">沉默的征服</a></td>
    <td>原创-言情</td><td>完结</td><td>216305</td>
  </tr>
</table>
</body></html>
HTML

my $robot = Novel::Robot->new( site => 'jjwxc' );
$robot->{browser} = Local::BoardBrowser->new( $html );

my $board = $robot->get_board_ref(
    'https://www.jjwxc.net/oneauthor.php?authorid=14644',
    min_item_num => 2,
    max_item_num => 2,
);

is( $board->{writer}, '牵机', 'extract board writer' );
is( scalar @{ $board->{item_list} }, 1, 'apply board item range' );
is( $board->{item_list}[0]{book}, '沉默的征服(完结)', 'extract book and status' );
is(
    $board->{item_list}[0]{url},
    'https://www.jjwxc.net/onebook.php?novelid=14446',
    'normalize protocol-relative book URL',
);
is( $board->{item_list}[0]{series}, '旧事系列', 'extract series' );

done_testing;
