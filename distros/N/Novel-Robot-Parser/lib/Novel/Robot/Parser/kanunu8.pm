# ABSTRACT: http://www.kanunu8.com
package Novel::Robot::Parser::kanunu8;
use strict;
use warnings;
use utf8;

use base 'Novel::Robot::Parser';
use Web::Scraper;

sub parse_board {
  my ( $self, $html_ref ) = @_;

  my $parse_writer = scraper {
    process_first '//h2/b', writer => 'TEXT';
  };

  my $ref = $parse_writer->scrape( $html_ref );

  $ref->{writer} =~ s/作品集//;
  return $ref->{writer};
}

sub parse_board_item {
  my ( $self, $html_ref ) = @_;

  my $parse_writer = scraper {
    process '//tr//td//a',
      'booklist[]' => {
      url  => '@href',
      book => 'TEXT'
      };
  };

  my $ref = $parse_writer->scrape( $html_ref );

  my @books =
    grep { $_->{url} and ( $_->{url} =~ /index.html$/ or $_->{url} =~ m#/\d+/$# ) } @{ $ref->{booklist} };
  return \@books;

} ## end sub parse_board_item

1;
