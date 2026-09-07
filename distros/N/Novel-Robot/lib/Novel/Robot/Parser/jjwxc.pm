# ABSTRACT: https://www.jjwxc.net

=pod

=encoding utf8

=head1 FUNCTION

=cut

package Novel::Robot::Parser::jjwxc;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

use Web::Scraper;

sub base_url { 'https://www.jjwxc.net' }

sub domain { 'jjwxc.net' }

sub generate_novel_url {
  my ( $self, $index_url, @args ) = @_;
  my ( $novelid ) = $index_url =~ m#novelid=(\d+)#;
  my $u = $novelid ? "https://m.jjwxc.net/book2/$novelid?more=0&whole=1" : $index_url;
  return $u;
}

sub parse_novel {
  my ( $self, $h, $r) = @_;
  $$h =~ s#本书霸王票读者排行.*##s;

  my ($title)= $$h=~m#<title>(.+?)<\/title>#s;
  ( $r->{book}, $r->{writer} ) = $title =~ m#\s*《(.+?)》(.+?)_晋江文学城#s;

  my ( $cc )          = $$h =~ m#章节列表：<br/>.+?(<a.+?)<\/div>#s;
  my @f               = $cc =~ m#<a.+?href="(.+?/\d+/\d+.*?)".+?>(.+?)</a>#sg;
  my $max_chapter_num = ( $#f + 1 ) / 2;
  for my $i ( 1 .. $max_chapter_num ) {
    my $j = 2 * $i - 1;
    my $t = $f[$j];
    $t =~ s/^\d+\.(&nbsp;)*//;
    $t =~ s/&nbsp/ /g;
    $t =~ s/^.+>//;
    $t =~ s/\s+/ /g;

    my $ui = 2 * $i - 2;
    my $u  = "https://m.jjwxc.net$f[$ui]";
    push @{ $r->{item_list} }, { id => $i, title => $t, url => $u };
  }

  return $r;
} ## end sub parse_novel

sub parse_novel_item {
  my ( $self, $h ) = @_;

  my ( $c ) = $$h =~ m#<h2[^>]+>.+?<li[^>]*>(.+?)</li>#s;

  return { content => $c || '' };
}

sub parse_board {
  my ( $self, $h ) = @_;

  my $parse_writer = scraper {
    process_first '//*[@itemprop="name"]', writer => 'TEXT';
  };
  my $ref = $parse_writer->scrape( $h );

  if ( !$ref->{writer} ) {
    ( $ref->{writer} ) = $$h =~ m#<meta\s+name="Description"\s+content="([^,]+),#i;
  }

  $self->tidy_string( $ref, 'writer' );
  return { writer => $ref->{writer} };
}

sub parse_board_item {
  my ( $self, $h ) = @_;
  my @book_list;
  my $series = '未分类';

  my $parse_writer = scraper {
    process '//tr[@bgcolor="#eefaee"]', 'book_list[]' => sub {
      my $tr = $_[0];
      $series = $self->parse_writer_series_name( $tr, $series );

      my $book = $self->parse_writer_book_info( $tr, $series );
      push @book_list, $book if ( $book and $book->{url} =~ /onebook/ );
    };
  };

  my $ref = $parse_writer->scrape( $h );

  $self->tidy_string( $ref, 'writer' );
  $_->{writer} = $ref->{writer} for @book_list;

  return \@book_list;
} ## end sub parse_board_item

sub parse_writer_series_name {
  my ( $self, $tr, $series ) = @_;

  return $series unless ( $tr->look_down( 'colspan', '7' ) );

  if ( $tr->as_trimmed_text =~ /【(.*)】/ ) {
    $series = $1;
  }

  return $series;
}

sub parse_writer_book_info {
  my ( $self, $tr, $series ) = @_;

  my $book = $tr->look_down(
    '_tag', 'a',
    sub { ( $_[0]->attr( 'href' ) || '' ) =~ m#(?:^|/)onebook\.php\?novelid=\d+# }
  );
  return unless ( $book );

  my $book_url = $book->attr( 'href' );

  my $bookname = $book->as_trimmed_text;
  return unless ( $bookname );

  my @cells = $tr->look_down( '_tag', 'td' );
  return unless ( @cells >= 3 );
  my $status = $cells[2]->as_trimmed_text;
  return {
    series => $series,
    book   => "$bookname($status)",
    url    => $book_url,
  };

} ## end sub parse_writer_book_info

1;
