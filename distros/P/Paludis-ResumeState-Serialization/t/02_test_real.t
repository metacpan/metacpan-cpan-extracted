use strict;
use warnings;

use Test::More 0.96;
use IO::Uncompress::Gunzip qw( gunzip );
use Paludis::ResumeState::Serialization::Grammar;

my (@files) = ( 'resume-1293352490.gz', 'resume-1293483679.gz', 'resumefile-1293138973.gz' );

my $grammar = Paludis::ResumeState::Serialization::Grammar->grammar();

for (@files) {
  gunzip "t/tfiles/$_", \my $data;

  ok( $data =~ $grammar, "$_ matches the grammar" );
}

done_testing();
