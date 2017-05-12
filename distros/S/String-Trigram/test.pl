# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'.
# A command parameter evaluating to true will make the script more verbose
#########################

use Test;
use strict;

#use Data::Dumper;
BEGIN { plan tests => 20 }
use String::Trigram qw (compare);

my %tests = ();

#my $verbose = $ARGV[0];
my $verbose = 1;

$tests{"1-gram"} = sub {
	( ( sprintf( "%.2f", compare( "abc", "aabc", ngram => 1 ) ) == 0.75 )
		  and ( sprintf( "%.1f", compare( "ab", "aabc", ngram => 1 ) ) == 0.5 )
	);
};

$tests{"2-gram"} = sub {
	(         ( sprintf( "%.2f", compare( "abc", "aabc", ngram => 2 ) ) == 0.8 )
		  and ( sprintf( "%.2f", compare( "ab", "aabc", ngram => 2 ) ) == 0.33 )
	);
};

$tests{"3-gram"} = sub {
	( ( sprintf( "%.4f", compare( "abc", "aabc", ngram => 3 ) ) == 0.5714 )
		  and
		  ( sprintf( "%.4f", compare( "ab", "aabc", ngram => 3 ) ) == 0.1111 )
	);
};

$tests{"4-gram"} = sub {
	( ( sprintf( "%.2f", compare( "abc", "aabc", ngram => 4 ) ) == 0.44 )
		  and
		  ( sprintf( "%.4f", compare( "ab", "aabc", ngram => 4 ) ) == 0.0909 )
		  and ( compare( "yz", "aabc", ngram => 4 ) == 0 ) );
};

$tests{"7-gram"} = sub {
	(
		( sprintf( "%.4f", compare( "abc", "aabc", ngram => 7 ) ) == 0.2667 )
		  and
		  ( sprintf( "%.4f", compare( "ab", "aabc", ngram => 7.2 ) ) == 0.0588 )
		  and
		  ( sprintf( "%.4f", compare( "aabc", "ab", ngram => 7 ) ) == 0.0588 )
	);
};

$tests{"identical strings"} = sub {
	(         ( compare( "abc", "abc" ) == 1 )
		  and ( compare( "abbbcdef",  "abbbcdef" ) == 1 )
		  and ( compare( "abcdefghi", "abcdefghi" ) == 1 ) );
};

$tests{"completely different strings"} = sub {
	(         ( compare( "abc", "def" ) == 0 )
		  and ( compare( "abcdef",    "ghkl" ) == 0 )
		  and ( compare( "abcdefghi", "jklmnopqrurwt" ) == 0 ) );
};

$tests{"several tokens of one trigram type"} = sub {
	(         ( compare( "abcabc", "abcabc" ) == 1 )
		  and ( compare( "abc", "abcabc" ) == 0.625 ) );
};

$tests{"compare a to b equals compare b to a"} =
  sub { compare( "kangaroo", "cockatoo" ) == compare( "cockatoo", "kangaroo" ) };

$tests{"warp"} = sub {
	sprintf( "%.2f",       compare( "abc", "abcabc", warp => 1.5 ) ) == 0.65
	  and sprintf( "%.2f", compare( "abc", "abcabc", warp => 2.3 ) ) == 0.9;
};

$tests{"keep only alphanumerics"} = sub {
	(         ( compare( "a+bc%}", "--:a.b?c##", keepOnlyAlNums => 1 ) == 1 )
		  and ( compare( "a+bc%}", "--:a.b?c##", keepOnlyAlNums => 0 ) == 0 ) );
};

$tests{"ignore case"} =
  sub { sprintf( "%.2f", compare( "Abc", "abCabc", warp => 1.5 ) ) == 0.77 };

$tests{"warp"} = sub {
	(         ( compare( "abc", "AbC", ignoreCase => 1 ) == 1 )
		  and ( compare( "abc", "AbC", ignoreCase => 0 ) == 0 ) );
};

$tests{"reInit/1"} = sub {
	my $trig = new String::Trigram( cmpBase => [ "abc", "def", "ghi" ] );
	$trig->reInit( [ "jkl", "mno" ], debug => 1 );
	my $res = {};
	( $trig->getSimilarStrings( "abc",       $res ) == 0 )
	  and ( $trig->getSimilarStrings( "def", $res ) == 0 )
	  and ( $trig->getSimilarStrings( "ghi", $res ) == 0 )
	  and ( $trig->getSimilarStrings( "xyz", $res ) == 0 )
	  and ( $trig->getSimilarStrings( "jkl", $res ) == 1 )
	  and ( $trig->getSimilarStrings( "mno", $res ) == 1 );
};

$tests{"reInit/2"} = sub {
	my @lista1 = qw/abacate laranja abobora/;
	my @lista2 = qw/abacate laranja abobora/;

	my $trig = String::Trigram->new(
		"cmpBase"        => [],
		"minSim"         => 0.1,
		"warp"           => 1.0,
		"ignoreCase"     => 1,
		"keepOnlyAlNums" => 1,
		"ngram"          => 3,
		"debug"          => 0
	);

	my @bm1 = ();
	my @bm2 = ();

	$trig->reInit( \@lista1 );
	my $sim1 = $trig->getBestMatch( 'abacate', \@bm1 );

	$trig->reInit( \@lista2 );
	my $sim2 = $trig->getBestMatch( 'abacate', \@bm2 );

	my $res = {};
	( $sim1 == $sim2 and @bm1 == @bm2 and @bm1 == 1 );
};

$tests{"extendBase"} = sub {
	my $trig = new String::Trigram( cmpBase => [ "abc", "def", "ghi" ] );
	$trig->extendBase( [ "jkl", "mno" ] );
	my $res = {};
	( $trig->getSimilarStrings( "abc",       $res ) == 1 )
	  and ( $trig->getSimilarStrings( "def", $res ) == 1 )
	  and ( $trig->getSimilarStrings( "ghi", $res ) == 1 )
	  and ( $trig->getSimilarStrings( "xyz", $res ) == 0 )
	  and ( $trig->getSimilarStrings( "jkl", $res ) == 1 )
	  and ( $trig->getSimilarStrings( "mno", $res ) == 1 );
};

$tests{"getBestMatch/1"} = sub {
	my $trig = new String::Trigram( cmpBase => [ "abc", "abcabc", "aabc" ] );
	my $best = [];

	( $trig->getBestMatch( "abc", $best ) == 1 )
	  and ( @$best == 1 )
	  and ( $best->[0] eq "abc" );
};

$tests{"getBestMatch/2"} = sub {
	my $trig = new String::Trigram( cmpBase => ["abc"], minSim => 0.3 );

	( sprintf( "%.2f", $trig->getBestMatch( "ab", [], warp => 3 ) ) != 0 )
	  and ( sprintf( "%.2f", $trig->getBestMatch( "ab", [] ) ) == 0 )
	  and (
		sprintf( "%.2f", $trig->getBestMatch( "ab", [], minSim => 0.1 ) ) ==
		0.29 );
};

$tests{"minSim"} = sub {
	my $trig  = new String::Trigram( cmpBase => [ "abc", "abcabc", "aabc" ] );
	my $sims1 = {};
	my $sims2 = {};

	my $msBeg = $trig->minSim();

	$trig->getSimilarStrings( "abc", $sims1 );

	$trig->minSim(0.9);

	$trig->getSimilarStrings( "abc", $sims2 );

	my $msEnd = $trig->minSim();

	( $msBeg == 0 )
	  and ( $msEnd == 0.9 )
	  and ( keys(%$sims1) == 3 )
	  and ( keys(%$sims2) == 1 );
};

$tests{"keeping base of comparison unique"} = sub {
	my $trig1 = new String::Trigram( cmpBase => ["abcabc"] );
	my $trig2 =
	  new String::Trigram( cmpBase => [ "abcabc", "abcabc", "abcabc" ] );

	$trig1->getBestMatch( "cabcab",   [] ) ==
	  $trig2->getBestMatch( "cabcab", [] );
};

$tests{"padding"} = sub {
	(         ( compare( "abc", "aabc", padding => 0 ) == 1 / 2 )
		  and ( compare( "abc", "aabc", padding => 1 ) == 2 / 5 )
		  and ( compare( "abc", "aabc", padding => 1.5 ) == 2 / 5 )
		  and ( compare( "abc", "aabc", padding => 2 ) == 4 / 7 ) );
};

my @names   = keys(%tests);
my $longest = getLongestName();

foreach ( sort(@names) ) {
	testMe( $_, $longest );
}

sub testMe {
	my $name = shift;
	my $lon  = shift;

	print "$name ", '.' x ( $lon + 1 - length($name) ), ' ' if $verbose;
	ok( $tests{$name} );
}

sub getLongestName {
	my $len = 0;

	foreach (@names) {
		$len = length if ( length > $len );
	}

	return $len;
}

#########################
