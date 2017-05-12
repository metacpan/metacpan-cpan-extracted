
use strict;
use warnings;

use Test::More;
use MooseX::Types;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw(Int Str);

my $varchar = 
    subtype as Parameterizable[Str, Int], 
    where {
        my ($str, $int) = @_;
        $int > length($str);
    };

ok $varchar,
  'got anonymouse type';

ok $varchar->parameterize(5)->check('aaa'),
  'smaller than 5';

ok !$varchar->parameterize(5)->check('aaaaa'),
  'bigger than 5';

ok !$varchar->parameterize(5)->check([1..3]),
  'Not correct type';
  
done_testing;
