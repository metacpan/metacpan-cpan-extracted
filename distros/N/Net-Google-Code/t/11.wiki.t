#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 15;
use Test::MockModule;
use FindBin qw/$Bin/;
use File::Slurp;
use Net::Google::Code;

my $svn_file = "$Bin/sample/11.TestPage.wiki";
my $svn_content = read_file( $svn_file );
my $wiki_file = "$Bin/sample/11.TestPage.html";

use Net::Google::Code::Wiki;

my $mock_wiki = Test::MockModule->new('Net::Google::Code::Wiki');
$mock_wiki->mock(
    'fetch',
    sub {
        shift;
        my $url = shift;
        if ( $url =~ /svn/ ) {
            $svn_content;
        }
        else {
            read_file($wiki_file);
        }
    }
);

my $wiki = Net::Google::Code::Wiki->new(
    project => 'net-google-code',
    name    => 'TestPage',
);

isa_ok( $wiki, 'Net::Google::Code::Wiki' );
is( $wiki->name, 'TestPage', 'name' );
$wiki->load;

# test source
is( $wiki->source, $svn_content, 'source' );
is(
    $wiki->summary,
    'One-sentence summary of this page.',
    'summary is parsed'
);
is_deeply( $wiki->labels, [ 'Phase-QA', 'Phase-Support' ], 'labels are parsed' );

is( $wiki->updated, 'Sat Jan 17 15:21:27 2009', 'updated is parsed' );
is( $wiki->updated_by, 'fayland', 'updated_by is parsed' );
like( $wiki->content, qr/<p>Add your content here/, 'content is parsed' );
is( scalar @{$wiki->comments}, 2, '2 comments' );
my $comments = $wiki->comments;

is( $comments->[0]->author, 'fayland', '1st comment author is parsed' );
is( $comments->[0]->date, 'Wed Jan  7 22:37:57 2009',
    '1st comment date is parsed' );
is( $comments->[0]->content, 'comment1', '1st comment content is parsed' );

is( $comments->[1]->author, 'fayland', '2nd comment author is parsed' );
is( $comments->[1]->date, 'Wed Jan  7 22:38:07 2009',
    '2nd comment date is parsed' );
is( $comments->[1]->content, 'two line comment 2.', '2nd comment content is parsed' );

1;

