
use strict;
use warnings;

use Test::More 0.96;

use Paludis::ResumeState::Serialization::Grammar;

my $grammar = Paludis::ResumeState::Serialization::Grammar->grammar();

my $sample = 'ResumeState@1234(a="b";c=D();e=F(g="H");i=J(k=c(1=c();count="1")))';

my $expected = {
  'ResumeSpec' => bless {
    '_classname' => 'ResumeState',
    'a'          => 'b',
    'c'          => ( bless { _classname => 'D', }, 'Paludis::ResumeState::Serialization::Grammar::FakeClass' ),
    'e'          => (
      bless {
        _classname => 'F',
        g          => 'H',
      },
      'Paludis::ResumeState::Serialization::Grammar::FakeClass'
    ),
    'i' => (
      bless {
        _classname => 'J',
        k          => bless(
          [
            bless( [], 'Paludis::ResumeState::Serialization::Grammar::FakeArray' )

          ],
          'Paludis::ResumeState::Serialization::Grammar::FakeArray'
        ),

      },
      'Paludis::ResumeState::Serialization::Grammar::FakeClass'
    ),

  },
  'Paludis::ResumeState::Serialization::Grammar::FakeClass'
};

my $results;

if ( $sample =~ $grammar ) {
  $results = \%/;
}

ok( defined $results, 'Expression matches data' );
is_deeply( $results, $expected, 'Simple parsing' );
done_testing();

