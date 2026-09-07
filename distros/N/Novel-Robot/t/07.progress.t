#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use lib 'lib';

use Novel::Robot;
use Encode qw(decode);
use Test::More;

{
    package Local::ProgressBrowser;
    sub new { bless {}, shift }
    sub request_url { return '<p>chapter content</p>' }
}

{
    package Local::ProgressBar;
    sub update {
        my ( $self, $value ) = @_;
        push @{ $self->{updates} }, $value;
    }
}

my $robot = Novel::Robot->new( site => 'default' );
$robot->{browser} = Local::ProgressBrowser->new;

my $bar;
my $output = '';
{
    no warnings 'redefine';
    local *Term::ProgressBar::new = sub {
        my ( $class, $opt ) = @_;
        $bar = bless { count => $opt->{count}, updates => [] }, 'Local::ProgressBar';
        return $bar;
    };
    open my $stdout, '>:encoding(UTF-8)', \$output or die $!;
    local *STDOUT = $stdout;

    $robot->get_novel_items(
        'https://example.test/book/',
        info_sub => sub { return { writer => '作者', book => '书名' } },
        item_list_sub => sub { return [] },
        item_sub => sub { return { content => '<p>content</p>' } },
        item_list => [ map {
            { id => $_, title => "chapter $_", url => "$_.html" }
        } 1 .. 5 ],
        min_item_num => 2,
        max_item_num => 4,
        back_index   => 1,
        progress     => 1,
    );
}

$output = decode( 'UTF-8', $output );

is( $bar->{count}, 3, 'progress total counts only chapters to download' );
is_deeply( $bar->{updates}, [ 1, 2, 3 ], 'progress advances once per downloaded chapter' );

my $writer_pos = index $output, "writer: 作者\n";
my $book_pos   = index $output, "book: 书名\n";
my $total_pos  = index $output, "num: 3\n";
ok( $writer_pos >= 0, 'print writer' );
ok( $book_pos > $writer_pos, 'print book after writer' );
ok( $total_pos > $book_pos, 'print download total after book and before progress creation' );

done_testing;
