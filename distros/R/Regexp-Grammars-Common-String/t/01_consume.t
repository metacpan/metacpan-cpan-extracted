
use strict;
use warnings;

use Test::More 0.96;

use Regexp::Grammars;
use Regexp::Grammars::Common::String;
use Data::Dumper qw( Dumper );

my $grammar = qr{
    <[pair]>+

    <extends: Regexp::Grammars::Common::String>
    <token: everything_else>
        (.*?)
    <token: pair>
        <nocontext: >
        <everything_else><String>

}x;

my $sample  = 'foo bar "\Foo" "Quux\"" blah "Do\"oo"';
my $matches = ( $sample =~ $grammar );
my $result  = undef;
$result = \%/ if $matches;

ok( $matches, "Expression matches" );
is_deeply(
  $result->{'pair'},
  [
    {
      'String'          => 'Foo',
      'everything_else' => 'foo bar ',
    },
    {
      'String'          => 'Quux"',
      'everything_else' => ' ',
    },
    {
      'String'          => 'Do"oo',
      'everything_else' => ' blah ',
    }
  ],
  'Parse returns right structure'
);

done_testing();
if ( $sample =~ $grammar ) {
  print Dumper ( \%/ );
}

