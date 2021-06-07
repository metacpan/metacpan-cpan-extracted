#!perl
use strict;
use warnings;
use Test::More;

BEGIN {
  use_ok( 'Search::Tokenizer' ) || print "Bail out!";
}

diag( "Testing Search::Tokenizer $Search::Tokenizer::VERSION, Perl $], $^X" );


my $tokenizer = Search::Tokenizer->new(
  regex           => qr/\w+(?:'\w+)?/,
  filter_in_place => sub {$_[0] =~ s/'.*//}, # remove quotes
  stopwords       => {a => 1, the => 1, my => 1},
  lower           => 0,
 );
my $string    = q{Don't touch my guru};
my $iterator  = $tokenizer->($string);

is_deeply([Search::Tokenizer::unroll($iterator)],
          [  ['Don',    3,  0,  5, 0],
             ['touch',  5,  6, 11, 1],
             ['guru',   4, 15, 19, 3], ],
          'new tokenizer');

$string   = "il était une bergère";
$tokenizer = Search::Tokenizer::unaccent(stopwords => {il => 1, une => 1});
$iterator  = $tokenizer->($string);
is_deeply([Search::Tokenizer::unroll($iterator, 1)],
          [qw/etait bergere/],
          "unaccent");

$iterator  = $tokenizer->("IL ÉTAIT UNE BERGÈRE");
is_deeply([Search::Tokenizer::unroll($iterator, 1)],
          [qw/etait bergere/],
          "unaccent uppercase");

done_testing();


