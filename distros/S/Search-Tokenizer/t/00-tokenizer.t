#!perl
use strict;
use warnings;
use Test::More;
use Time::HiRes qw/time/;

use lib "../lib";


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

is_deeply([unroll($iterator)],
          [  ['Don',    3,  0,  5, 0],
             ['touch',  5,  6, 11, 1],
             ['guru',   4, 15, 19, 3], ],
          'new tokenizer');


$string   = "il était une bergère";
$tokenizer = Search::Tokenizer::unaccent(stopwords => {il => 1, une => 1});
$iterator  = $tokenizer->($string);
is_deeply([unroll($iterator, 1)], [qw/etait bergere/], "unaccent");

$iterator  = $tokenizer->("IL ÉTAIT UNE BERGÈRE");
is_deeply([unroll($iterator, 1)], [qw/etait bergere/], "unaccent uppercase");

open my $fh, "<", $INC{'Search/Tokenizer.pm'} or die $!;
my $large_string = do {local $/; <$fh>};
close $fh;

my $time_for_native_string = time_for(sub {count_words($large_string)});
utf8::upgrade($large_string);
my $time_for_utf8_string   = time_for(sub {count_words($large_string)});
note sprintf "large_string : %.4f native, %.4f utf8", $time_for_native_string, $time_for_utf8_string;
ok ($time_for_utf8_string <= 3*$time_for_native_string, "utf8 string not too much slower than native");

done_testing();

sub unroll {
  my $iterator      = shift;
  my $just_the_term = shift;
  my @results;

  while (my @r = $iterator->() ) {
    push @results, $just_the_term ? $r[0] : \@r;
  }
  return @results;
}


sub count_words {
  my $string   = shift;
  my $iterator = $tokenizer->($string);
  my @words    = unroll($iterator, 1);
  return scalar @words;
}


sub time_for {
  my $sub = shift;
  my $t0 = time;
  $sub->();
  my $t1 = time;
  return $t1 - $t0;
}
