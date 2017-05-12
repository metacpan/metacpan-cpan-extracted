#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 26 );

BEGIN {
    use_ok( 'Sphinx::Config' );
}

my $c = Sphinx::Config->new;
isa_ok( $c, 'Sphinx::Config' );

my $FILE = "t/sphinx2.conf";
$c->parse( $FILE );
pass( "Didn't explode on $FILE" );

$c->set( index => YCUR => source => 'HONK' );
my $s = $c->get( source => 'SCUR' );
$s->{xmlpipe_command} =~ s/CUR/HONK/;
$c->set( source => HONK => $s );
$c->set( source => HONK => type => 'brand new' );
$c->set( index => YCUR => newkey  => 'difficult' );
$c->set( index => YCUR => morphology => 'libstemmer_french' );
$c->set( source => 'dbi' );

#####
my $text = $c->as_string;
ok( $text, "->as_string worked" );
like( $text, qr/# Hello world/, " ... kept prefix comment" );
like( $text, qr/# max_iosize\s+=/, " ... inline comment" );

like( $text, qr/source = HONK\n /, " ... set index/YCUR/HONK" );
like( $text, qr/source HONK/, " ... created source HONK" );
like( $text, qr/type = brand new/, " ... set source/HONK/type" );
like( $text, qr/sphinx-feed --year HONK/, " ... with the right command" );
like( $text, qr/newkey = difficult/, " ... with an added index/YCUR/newkey" );
like( $text, qr/    # morphology=libstemmer_english\n    morphology = libstemmer_french/, 
            " ... with an added index/YCUR/morphology" );

unlike( $text, qr/source dbi/, " ... deleted source/dbi" );

#####
$c->parse_string( $text );
pass( "Text is parsable" );
my $v;

$v = $c->get( index => YCUR => 'source' );
is( $v, 'HONK', " ... index/YCUR/source" );

$v = $c->get( source => 'HONK' );
$s->{type} = 'brand new';
is_deeply( $v, $s, " ... source/HONK" );

$v = $c->get( source => HONK => 'type' );
is( $v, 'brand new', " ... source/HONK/type" );

$v = $c->get( source => HONK => 'xmlpipe_command' );
like( $v, qr/sphinx-feed --year HONK/, " ... source/HONK/xmlpipe_command" );
 
$v = $c->get( index => YCUR => 'newkey' );
is( $v, 'difficult', " ... index/YCUR/newkey" );

$v = $c->get( source => 'dbi' );
is( $v, undef, " ... source/dbi stayed gone" );


##### Now we fight with arrays
$c->parse_string( <<TEXT );
source dbi {
    sql_query = SELECT id, title, content, \\
        author_id, forum_id, post_date FROM my_forum_posts
    sql_attr_uint = author_id
    sql_attr_timestamp = post_date
    sql_attr_uint = \\
            forum_id
}
TEXT
#use Data::Dump qw( pp );
#warn pp $c;
$v = $c->get( source => dbi => 'sql_attr_uint' );
is_deeply( $v, [ qw( author_id forum_id ) ], "Got source/dbi/sql_attr_uint" );
$c->set( source => dbi => sql_attr_uint => [ qw( honk bonk ) ] );
$c->set( source => dbi => sql_query => 'SELECT id, title, content, honk, bonk FROM my_forum_posts' );

$text = $c->as_string;
like( $text, qr/sql_query = SELECT id, title, content, honk, bonk FROM my_forum_posts\n\s+sql_attr/, 
        "Set multi-line value" );
like( $text, qr/sql_attr_uint = honk/, "Set first of array" );
like( $text, qr/sql_attr_uint = bonk/, "Set second of array" );
unlike( $text, qr/sql_attr_uint = author_id/, "Removed previous first of array" );
unlike( $text, qr/sql_attr_uint = forum_id/, "Removed previous second of array" );

