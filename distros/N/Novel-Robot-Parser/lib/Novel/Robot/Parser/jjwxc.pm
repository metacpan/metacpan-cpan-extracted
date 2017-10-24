# ABSTRACT: http://www.jjwxc.net

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

sub base_url { 'http://www.jjwxc.net' }

sub parse_novel_item {
    my ( $self, $h ) = @_;

    my $pr = scraper {
        process_first 'h2', title => 'TEXT';
        #process_first '//div[@class="b module"]//li[1]', content => 'HTML';
        #process_first '//div/ul/li[2]', writer_say => 'HTML';
    };

    my $r = $pr->scrape($h);
    $r->{title}  =~s#(^\d+、)|(\s*[\.]+\s*$)##sg;
    ($r->{content})= $$h=~m#<li>(.+?)</li>#s;
    $r->{content} ||= '';

    return $r;
}

sub parse_novel {

    my ( $self, $h ) = @_;
    return if ( $$h =~ /自动进入被锁文章的作者专栏/ );

    my $parse_novel = scraper {
        process_first '//h1[@itemprop="name"]',     'book'       => 'TEXT';
        process_first '//h2/a',                     'writer_url' => '@href';
        process_first '//span[@itemprop="author"]', 'writer'     => 'TEXT';
        process_first '.readtd>.smallreadbody',
          'intro' => sub { $self->parse_intro(@_); };
    };

    my $r = $parse_novel->scrape($h);
    return $self->parse_novel_single($h) unless ( $r->{book} );

    for ($$h) {
        ( $r->{series} )   = m{<span>所属系列：</span>(.*?)</li>}s;
        ( $r->{progress} ) = m{<span>文章进度：</span>(.*?)</li>}s;
        ( $r->{word_num} ) = m{<span>全文字数：</span>(\d+)字</li>}s;
    }
    $r->{$_} =~ s/^\s+|<[^>]+>|\s+$//gs for qw/series progress/;

    return $r;
} ## end sub parse_novel

sub parse_intro {
    my ( $self, $e ) = @_;
    my $intro =
         $e->look_down( '_tag', 'div', 'style', 'clear:both' )
      || $e->look_down( '_tag', 'div' )
      || $e;

    my $intro_html = $intro->as_HTML('<>&');
    my $h          = $self->get_inner_html($intro_html);
    $h =~ s#</?font[^<]*>\s*##gis;

    return $h;
}

sub parse_novel_single {

    #just single chapter content on index page
    my ( $self, $h ) = @_;

    my $pr = scraper {
        process_first '.bigtext',                       'book' => 'TEXT';
        process_first '//td[@class="noveltitle"]/h1/a', 'url'  => '@href';
        process_first '//td[@class="noveltitle"]/a',
          'writer'     => 'TEXT',
          'writer_url' => '@href';
        process_first '//h2', 'chap_title' => 'TEXT';
    };
    my $r = $pr->scrape($h);

    my $chap_url = $r->{url};
    $chap_url=~s#^.*?novelid=(\d+)#http://m.jjwxc.net/book2/$1/1#;

    my %chap = (
        id       => 1,
        title    => $r->{chap_title},
        abstract => $r->{chap_title},
        num      => $r->{word_num},
        url      => $chap_url,
    );
    push @{ $r->{chapter_list} }, \%chap;

    delete( $r->{chap_title} );

    return $r;

} ## end unless ( $ref->{title} )

sub parse_novel_list {
    my ( $self, $h, $index_ref ) = @_;

    my $s = scraper {
        process '//tr[@itemtype="http://schema.org/Chapter"]',
          'chap_list[]' => scraper {
            process '//td',      'info[]' => 'TEXT';
            process_first '//a', 'url'    => '@href';
          };
    };
    my $r = $s->scrape($h);
    return unless ( $r->{chap_list} );

    my @fields = qw/id title abstract word_num click_num time/;
    for my $c ( @{ $r->{chap_list} } ) {
        my $info = $c->{info};
        $c->{ $fields[$_] } = $info->[$_] for ( 0 .. $#fields );
        $c->{type} = $self->format_chapter_type( $c->{title} );
        $c->{id} =~ s/\s+//g;
        $c->{url}=~s#^.*?novelid=(\d+)&chapterid=(\d+).*#http://m.jjwxc.net/book2/$1/$2# if($c->{url});

        delete( $c->{info} );
    }

    return $r->{chap_list};
}

sub format_chapter_type {
    my ( $self, $title ) = @_;
    my $type =
        $title =~ /\[VIP\]$/ ? 'vip'
      : $title =~ /\[锁\]$/ ? 'lock'
      :                        'normal';
    return $type;
}

sub parse_board {
    my ( $self, $h ) = @_;

    my $parse_writer = scraper {
        process_first '//tr[@valign="bottom"]//b', writer => 'TEXT';
    };
    my $ref = $parse_writer->scrape($h);

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

    my $ref = $parse_writer->scrape($h);

    $self->tidy_string( $ref, 'writer' );
    $_->{writer} = $ref->{writer} for @book_list;

    return \@book_list;
} ## end sub parse_writer

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
    return unless ($book);

    my $book_url = $book->attr('href');

    my $bookname = $book->as_trimmed_text;
    substr( $bookname, 0, 1 ) = '';
    $bookname .= '[锁]' if ( $tr->look_down( 'color', 'gray' ) );

    my $progress = ( $tr->look_down( '_tag', 'td' ) )[4]->as_trimmed_text;
    return {
        series => $series,
        book   => "$bookname($progress)",
        url    => $self->base_url()."/$book_url",
    };

}

sub make_query_request {

    my ( $self, $keyword,  %opt ) = @_;
    $opt{query_type} ||= '作品';

    my %qt = (
        '作品' => '1',
        '作者' => '2',
        '主角' => '4',
        '配角' => '5',
        '其他' => '6',
    );

    my $url = $self->base_url().qq[/search.php?kw=$keyword&t=$qt{$opt{query_type}}];
    $url=encode($self->charset(), $url);

    return $url;
} ## end sub make_query_request

sub parse_query_list {
    my ( $self, $h ) = @_;
    my $parse_query = scraper {
        process '//div[@class="page"]/a', 'urls[]' => sub {
            return unless ( $_[0]->as_text =~ /^\[\d*\]$/ );
            my $url = $self->base_url() . ( $_[0]->attr('href') );
            $url = encode( $self->charset(), $url );
            return $url;
        };
    };
    my $r = $parse_query->scrape($h);
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
            my ($writer, $progress) = $_[0]->as_text =~ /作者：(.+?) \┃ 进度：(\S+)/s;
            return { writer => $writer, progress => $progress };
        };
    };
    my $ref = $parse_query->scrape($h);

    my @result;
    foreach my $i ( 0 .. $#{ $ref->{books} } ) {
        my $r = $ref->{books}[$i];
        next unless($r->{url});

        my $w = $ref->{writers}[$i];
        $r->{title} .= "($w->{progress})";
        push @result, { %$w, %$r };
    }

    return \@result;
} ## end sub parse_query

1;
