
#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 5;

use_ok( 'Steemit::OperationSerializer' ) || print "Bail out!\n";

my $serializer = Steemit::OperationSerializer->new;

isa_ok( $serializer, 'Steemit::OperationSerializer', 'constructor works');

my $vote_operation = [
   vote => {
      voter    => 'voterr',
      author   => 'authorrr',
      permlink => 'permliiiiing',
      weight   => 596,
   }
];

my $vote_serialisation = '0006766f7465727208617574686f7272720c7065726d6c69696969696e675402';

is( unpack( "H*",$serializer->serialize_operation(@$vote_operation)), $vote_serialisation, "vote serialisation is correct");


my $comment_operation = [
   comment => {
         "parent_author"   => 'sime-guy',
         "parent_permlink" => 'important_post-siming-something',
         "author"          => 'itsa_me_mario',
         "permlink"        => 're-important_post-siming-something.time()',
         "title"           => '',
         "body"            => 'wow nice post',
         "json_metadata"   => '{ "tags" => ["utopian-io"]}',
   }
];

my $comment_seroalisation = '010873696d652d6775791f696d706f7274616e745f706f73742d73696d696e672d736f6d657468696e670d697473615f6d655f6d6172696f2972652d696d706f7274616e745f706f73742d73696d696e672d736f6d657468696e672e74696d652829000d776f77206e69636520706f73741b7b20227461677322203d3e205b2275746f7069616e2d696f225d7d';
is( unpack( "H*",$serializer->serialize_operation(@$comment_operation)), $comment_seroalisation, "comment serialisation is correct");



my $delete_comment_operation = [
   delete_comment => {
         "author"          => 'itsa_me_mario',
         "permlink"        => 're-important_post-siming-something.time()',
   }
];

my $delete_comment_operation_serial = '110d697473615f6d655f6d6172696f2972652d696d706f7274616e745f706f73742d73696d696e672d736f6d657468696e672e74696d652829';
is( unpack( "H*",$serializer->serialize_operation(@$delete_comment_operation)), $delete_comment_operation_serial, "delete_comment serialisation is correct");
