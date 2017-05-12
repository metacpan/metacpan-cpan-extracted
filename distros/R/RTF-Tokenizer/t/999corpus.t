#!perl

use strict;
use warnings;
use Test::More;
use lib 't/lib/';

use RTF::Tokenizer::TestCorpus;

opendir (DIR, 't/corpus/') or die $!;
while (my $file = readdir(DIR)) {
	next unless $file =~ m/\.corpus$/;
	$file = 't/corpus/' . $file;
    
	RTF::Tokenizer::TestCorpus::test_corpus( $file );
}

done_testing();
