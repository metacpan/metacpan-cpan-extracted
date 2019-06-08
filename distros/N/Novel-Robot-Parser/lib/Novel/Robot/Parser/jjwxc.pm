# ABSTRACT: https://www.jjwxc.net

=pod

=encoding utf8

=head1 FUNCTION

=head2 make_query_request

  #$type：作品，作者，主角，配角，其他

  $parser->make_query_request( $type, $keyword );

=cut

package Novel::Robot::Parser::jjwxc;
use strict;
use warnings;
use utf8;
use base 'Novel::Robot::Parser';

use Web::Scraper;
use Encode;

sub base_url { 'https://www.jjwxc.net' }

sub domain { 'jjwxc.net' }

sub generate_novel_url {
  my ( $self, $index_url ) = @_;
  my ( $novelid ) = $index_url =~ m#novelid=(\d+)#;
  my $u = $novelid ? "https://m.jjwxc.net/book2/$novelid?more=0&whole=1" : $index_url;
  return $u;
}

sub parse_novel {
  my ( $self, $h ) = @_;
  $$h =~ s#本书霸王票读者排行.*##s;

  my %r;
  ( $r{book}, $r{writer} ) = $$h =~ m#<title>\s*《(.+?)》\s*(.+?)_#s;

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
    push @{ $r{floor_list} }, { id => $i, title => $t, url => $u };
  }

  return \%r;
} ## end sub parse_novel

sub parse_novel_item {
  my ( $self, $h ) = @_;

  my ( $c ) = $$h =~ m#<h2[^>]+>.+?<li[^>]*>(.+?)</li>#s;

  return { content => $c || '' };
}

sub parse_board {
  my ( $self, $h ) = @_;

  my $parse_writer = scraper {
    process_first '//tr[@valign="bottom"]//b', writer => 'TEXT';
  };
  my $ref = $parse_writer->scrape( $h );

  $self->tidy_string( $ref, 'writer' );
  return $ref->{writer};
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

  my $book = $tr->look_down( '_tag', 'a' );
  return unless ( $book );

  my $book_url = $book->attr( 'href' );

  my $bookname = $book->as_trimmed_text;
  substr( $bookname, 0, 1 ) = '';
  $bookname .= '[锁]' if ( $tr->look_down( 'color', 'gray' ) );

  my $progress = ( $tr->look_down( '_tag', 'td' ) )[4]->as_trimmed_text;
  return {
    series => $series,
    book   => "$bookname($progress)",
    url    => $self->base_url() . "/$book_url",
  };

} ## end sub parse_writer_book_info

sub make_query_request {

  my ( $self, $keyword, %opt ) = @_;
  $opt{query_type} ||= '作品';

  my %qt = (
    '作品' => '1',
    '作者' => '2',
    '主角' => '4',
    '配角' => '5',
    '其他' => '6',
  );

  my $url = $self->base_url() . qq[/search.php?kw=$keyword&t=$qt{$opt{query_type}}];
  $url = encode( $self->charset(), $url );

  return $url;
} ## end sub make_query_request

sub parse_query_list {
  my ( $self, $h ) = @_;
  my $parse_query = scraper {
    process '//div[@class="page"]/a', 'urls[]' => sub {
      return unless ( $_[0]->as_text =~ /^\[\d*\]$/ );
      my $url = $self->base_url() . ( $_[0]->attr( 'href' ) );
      $url = encode( $self->charset(), $url );
      return $url;
    };
  };
  my $r = $parse_query->scrape( $h );
  return $r->{urls} || [];
} ##

sub parse_query_item {
  my ( $self, $h ) = @_;

  my $parse_query = scraper {
    process '//h3[@class="title"]/a',
      'books[]' => {
      'book' => 'TEXT',
      'url'  => '@href',
      };

    process '//div[@class="info"]', 'writers[]' => sub {
      my ( $writer, $progress ) = $_[0]->as_text =~ /作者：(.+?) \┃ 进度：(\S+)/s;
      return { writer => $writer, progress => $progress };
    };
  };
  my $ref = $parse_query->scrape( $h );

  my @result;
  foreach my $i ( 0 .. $#{ $ref->{books} } ) {
    my $r = $ref->{books}[$i];
    next unless ( $r->{url} );

    my $w = $ref->{writers}[$i];
    $r->{title} .= "($w->{progress})";
    push @result, { %$w, %$r };
  }

  return \@result;
} ## end sub parse_query_item

1;
