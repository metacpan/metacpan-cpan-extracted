#!/usr/bin/perl
use lib '../lib';
use Novel::Robot;
use Test::More;
#use Data::Dumper;
use Encode::Locale;
use Encode;
use Smart::Comments;

$| = 1;
binmode( STDIN,  ":encoding(console_in)" );
binmode( STDOUT, ":encoding(console_out)" );
binmode( STDERR, ":encoding(console_out)" );
use utf8;

my $dq_r = { site            => 'jjwxc',
	index_url       => 'https://www.jjwxc.net/onebook.php?novelid=14838',
	chapter_url     => 'https://m.jjwxc.net/book2/14838/1',
	writer          => '牵机',
	book            => '断情逐妖记',
	chapter_title   => '序章',
	chapter_content => '大江',
};

my $yg_r = 
{ site            => 'default',
	index_url       => 'https://www.aliwx.com.cn/chapter?bid=7964189',
	chapter_url     => 'https://www.aliwx.com.cn/reader?bid=7964189&cid=1197667',
	book            => '青春期妖怪',
	writer          => '飘灯',
	chapter_title   => '普通',
	chapter_content => '周小云',
};

my @test_r = ( $dq_r, 
	#	$yq_r,
);

for my $r (@test_r){
	print "check: $r->{index_url}\n";

	my $xs = Novel::Robot->new( site => $r->{site});

	my $c = $xs->{browser}->request_url($r->{index_url});

	my $index_ref = $xs->get_novel_info( $r->{index_url} );
	is( $index_ref->{book} , $r->{book}     , "book" );
	is( $index_ref->{writer} ,  $r->{writer}, "writer" );


	#  my $html =
	#    ref( $r->{chapter_url} ) eq 'HASH'
	#    ? $xs->{browser}->request_url( $r->{chapter_url}{url}, $r->{chapter_url}{post_data} )
	#    : $xs->{browser}->request_url( $r->{chapter_url} );
	#  my $chapter_ref = $xs->{parser}->extract_elements(
	#    \$html,
	#    path => $xs->{parser}->scrape_novel_item(),
	#    sub  => $xs->{parser}->can( 'parse_novel_item' ),
	#  );
	#  is( $chapter_ref->{content} =~ /$r->{chapter_content}/ ? 1 : 0, 1, 'chapter_content' );
	#  print join( ",", $index_ref->{book}, $index_ref->{writer}, $index_ref->{item_list}[0]{title} ), "\n";

	#print $chapter_ref->{content},"\n";

	print "---------\n\n";
}

done_testing;

