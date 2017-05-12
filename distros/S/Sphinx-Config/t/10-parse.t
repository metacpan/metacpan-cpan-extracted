#!/usr/bin/perl

use strict;
use warnings;

use Test::More ( tests => 8 );

BEGIN {
    use_ok( 'Sphinx::Config' );
}

my $c = Sphinx::Config->new;
isa_ok( $c, 'Sphinx::Config' );

my $FILE = "t/sphinx2.conf";
$c->parse( $FILE );
pass( "Didn't explode on $FILE" );

my $index = $c->get( 'indexer' );
is_deeply( $index, { mem_limit => "1024M", write_buffer => "64M" }, "Got indexer section" );

my $s = $c->get( source => 'SCUR' );
is_deeply( $s, {
  type => "xmlpipe",
  xmlpipe_command => "/home/dw/prive/dw-app/t/scripts/sphinx-feed --year CUR"
}, "Got whole section" );

$s = $c->get( index => YCUR => 'charset_type' );
is( $s, 'utf-8', "Got a single value" );

$s = $c->get( source => dbi => 'sql_query' );
is( $s, "SELECT id, title, content, author_id, forum_id, post_date FROM my_forum_posts",
        "Got line-continued value" );

$s = $c->get( source => dbi => 'sql_attr_uint' );
is_deeply( $s, [ qw( author_id forum_id ) ], "Got mutlple value variable" );


#use Data::Dump qw( pp );
#warn pp $s;
