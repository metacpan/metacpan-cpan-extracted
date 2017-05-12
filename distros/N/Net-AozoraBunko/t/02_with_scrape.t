use strict;
use warnings;
use utf8;
use Test::More 0.88;
use LWP::Online ':skip_all';
use YAML;

use Net::AozoraBunko;

sub _dump {
    print YAML::Dump $_[0] if $_[1] || $ENV{TEST_AOZORA_DUMP};
}

# 「河口湖」伊藤 左千夫
my $SAMPLE_WORK_URL = 'http://www.aozora.gr.jp/cards/000058/card1198.html';
# 芥川 竜之介
my $SAMPLE_AUTHOR_URL = 'http://www.aozora.gr.jp/index_pages/person879.html';

unless ( $ENV{TEST_AOZORA} || $ENV{TRAVIS} ) {
    plan( skip_all => "Please set \$ENV{TEST_AOZORA}, and run test $0" );
}

my $ab = Net::AozoraBunko->new;
my $author;
{
    #----- authors
    my $authors;
    {
        $authors = $ab->authors;
        is ref $authors, 'ARRAY', 'authors is ARRAY';
        _dump $authors;
    }
    $author = shift @{$authors};
    {
        ok $author->{name} ne '', 'get name of author';
        like $author->{url}, qr!^http://!, 'get url of author';
        _dump $author;
    }
}

{
    #----- author
    {
        eval {
            my $author_info = $ab->author();
        };
        like $@, qr!^uri is blank!, 'author blank URL';
        eval {
            my $author_info = $ab->author('foo');
        };
        like $@, qr!^not author's URL:!, 'wrong author URL';
    }
    {
        my $author_info = $ab->author($author->{url});
        is ref $author_info, 'HASH', 'author info is HASH';
        _dump $author_info;
    }
}

{
    #----- works
    {
        eval {
            my $works = $ab->works();
        };
        like $@, qr!^uri is blank!, 'works blank URL';
    }
    {
        my $works = $ab->works($author->{url});
        is ref $works, 'ARRAY', 'works is ARRAY';
        _dump $works;
    }
}

{
    #----- all_works
    {
        eval {
            my $works = $ab->all_works();
        };
        like $@, qr!^uri is blank!, 'all_works blank URL';
    }
    {
        my $all_works = $ab->all_works($author->{url});
        is ref $all_works, 'ARRAY', 'all_works is ARRAY';
        _dump $all_works;
    }
}

{
    #----- get_text
    {
        eval {
            my $text = $ab->get_text();
        };
        like $@, qr!^uri is blank!, 'get_text blank URL';
        eval {
            my $text = $ab->get_text('foo');
        };
        like $@, qr!^wrong uri:!, 'wrong get_text URL';
    }
    {
        my $text = $ab->get_text($SAMPLE_WORK_URL);
        ok $text ne '', 'get text';
        _dump $text; # 改行コードは "\r\n" として表示される
    }
}

{
    #----- get_zip
    {
        eval {
            my $zip = $ab->get_zip();
        };
        like $@, qr!^uri is blank!, 'get_zip blank URL';
    }
    {
        my $zip = $ab->get_zip($SAMPLE_WORK_URL);
        ok $zip ne '', 'get zip';
        _dump $zip; # zip is binary
    }
}

{
    #----- search_author
    {
        my $search_author_result_blank = $ab->search_author('');
        is ref $search_author_result_blank, 'ARRAY', 'search_author';
        is scalar @{$search_author_result_blank}, 0, 'search_author result is 0';
    }
    {
        my $search_author_result = $ab->search_author('佐藤');
        ok scalar @{$search_author_result} > 0, 'search_author result';
        _dump $search_author_result;
    }
}

{
    #----- search_work
    {
        my $search_work_result = $ab->search_work(
            $SAMPLE_AUTHOR_URL,
            ''
        );
        is ref $search_work_result, 'ARRAY', 'search_work no keyword';
        ok scalar @{$search_work_result} == 0, 'search_work result is 0';
    }
    {
        my $search_work_result = $ab->search_work(
            '',
            'foo'
        );
        is ref $search_work_result, 'ARRAY', 'search_work no URL';
        ok scalar @{$search_work_result} == 0, 'search_work result is 0';
    }
    {
        eval {
            my $search_work_result = $ab->search_work(qw/foo bar/);
        };
        like $@, qr!^not author's URL:!, 'search_work wrong URL';
    }
    {
        my $search_work_result = $ab->search_work(
            $SAMPLE_AUTHOR_URL,
            'あばばばば'
        );
        is ref $search_work_result, 'ARRAY', 'search_work';
        ok scalar @{$search_work_result} > 0, 'search_work result';
        _dump $search_work_result;
    }
}

done_testing;


