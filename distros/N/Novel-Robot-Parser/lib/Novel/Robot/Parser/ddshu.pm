# ABSTRACT: 豆豆小说阅读网 http://www.dddshu.net
=pod

=encoding utf8

=head1 FUNCTION

=head2 make_query_request

  支持的查询类型：作品，作者，主角，系列

=cut

package Novel::Robot::Parser::ddshu;
use base 'Novel::Robot::Parser';

use strict;
use warnings;
use utf8;

use Web::Scraper;
use Encode;

sub base_url { 'http://www.ddshu.net' }

sub parse_novel {

    my ( $self, $html_ref ) = @_;

    my $parse_novel =

      $$html_ref =~ /<h2 id="lc">/
      ? scraper {
        process_first '#lc', 'book_info' => sub {
            my ( $writer, $book ) = ( $_[0]->look_down( '_tag', 'a' ) )[ 2, 3 ];
            return [
                $writer->as_trimmed_text, $writer->attr('href'),
                $book->as_trimmed_text,   $book->attr('href')
            ];
        };
        process_first '//table[@width="95%"]//td[2]', 'intro' => 'HTML';

    }
      : scraper {
        process_first '.cntPath', 'book_info' => sub {
            my ( $writer, $book ) = ( $_[0]->look_down( '_tag', 'a' ) )[ 3, 4 ];
            return [
                $writer->as_trimmed_text, $writer->attr('href'),
                $book->as_trimmed_text,   $book->attr('href')
            ];
        };
        process_first '.bookintro', 'intro' => 'HTML';
      };

    my $ref = $parse_novel->scrape($html_ref);

    $ref->{intro} = $self->get_inner_html( $ref->{intro} );
    $ref->{intro} =~ s#<script[^>]*?>.*?</script>##sig;

    @{$ref}{ 'writer', 'writer_url', 'book', 'url' } = @{ $ref->{book_info} };

    $ref->{url} = $self->format_abs_url( $ref->{url} );
    ( $ref->{book_opt_url} = $ref->{url} ) =~ s#index.html$#opf.html#;

    return $ref;
} ## end sub parse_novel

sub parse_novel_list {
    my ( $self, $html_ref, $index_ref ) = @_;

    my $h = $self->{browser}->request_url( $index_ref->{book_opt_url} );

    my $refine_engine = scraper {
        process '//div[@class="opf"]//a',
          'chapter_list[]' => {
            title => 'TEXT',
            url   => '@href'
          };
    };

    my $r = $refine_engine->scrape( \$h );
    return $r->{chapter_list};
} ## end sub parse_novel_list

sub parse_novel_item {

    my ( $self, $html_ref ) = @_;

    $$html_ref =~ s#\<img[^>]+dou\.gif[^>]+\>#，#g;

    my $parse_novel_item = scraper {
        process '//div[@id="toplink"]//a', 'book_info[]' => 'TEXT';
        process_first '.mytitle',          'title'       => 'TEXT';
        process_first '#content',          'content'     => 'HTML';
    };
    my $ref = $parse_novel_item->scrape($html_ref);
    return unless($ref->{content}); 
    #@{$ref}{ 'book', 'writer' } = @{ $ref->{book_info} }[ 3, 4 ];
    for ( $ref->{content} ) {
        s#<script[^>]+></script>##sg;
        s#<div[^>]+></div>##sg;
    }
    $ref->{title} =~ s/^\s*//;

    return $ref;
} ## end sub parse_novel_item

sub parse_board {
    my ( $self, $html_ref ) = @_;

    my $parse_writer = scraper {
        process_first 'title', writer => 'TEXT';
    };
    my $ref = $parse_writer->scrape($html_ref);
    $ref->{writer} =~ s/小说.*//;
    return $ref->{writer};
}

sub parse_board_item {

    my ( $self, $html_ref ) = @_;

    my $parse_writer = scraper {
        process '//div[@id="border_1"]//ul', 'booklist[]' => scraper {
            process_first '//a', url => '@href', book => 'TEXT';
            process_first '//li[2]', series => 'TEXT';
        };
    };

    my $ref = $parse_writer->scrape($html_ref);

    my @book;
    for my $r ( @{ $ref->{booklist} } ) {
        next unless ( $r->{book} );
        $r->{series} =~ s/\s*(\S*)\s*.*$/$1/;
        push @book, $r;
    }
    $ref->{booklist} = \@book;

    return $ref->{booklist};
} ## end sub parse_writer

sub make_query_request {

    my ( $self, $keyword, %opt ) = @_;
    $opt{query_type} ||= '作品';

    my $url = $self->base_url() . '/search.php';

    my %qt = (
        '作品' => 'name',
        '作者' => 'author',
        '主角' => 'main',
        '系列' => 'series',
    );

    return (
        $url,
        {
            'keyword' => encode( $self->charset(), $keyword ),
            'select'  => $qt{ $opt{query_type} },
            'Submit'  => '搜索',
        },
    );

} ## end sub make_query_request

sub parse_query_item {
    my ( $self, $html_ref ) = @_;

    my $parse_query = scraper {
        process '//h3/a', 'books[]' => { url => '@href', book => 'TEXT' };
        process '//ul/li/a[1]',
          'writers[]' => { writer_url => '@href', writer => 'TEXT' };
    };

    my $ref = $parse_query->scrape($html_ref);
    my @res = map {
        {
            %{ $ref->{books}[$_] }, %{ $ref->{writers}[$_] }
        }
    } ( 0 .. $#{ $ref->{books} } );

    return \@res;
} ## end sub parse_query

1;
