use Test::More;
use Test::Fatal qw( exception );

use Data::Monad::Either qw( right left );
use Mouse::Util::TypeConstraints qw( find_type_constraint );

require_ok 'MouseX::Types::Data::Monad::Either';

my $left_t   = find_type_constraint('Left');
my $right_t  = find_type_constraint('Right');
my $either_t = find_type_constraint('Either');

ok $left_t;
ok $right_t;
ok $either_t;

subtest 'left' => sub {
  my $left = left(10);
  ok $either_t->check($left);
  ok $left_t->check($left);
  ok $left_t->parameterize('Int')->check($left);
  ok ! $right_t->check($left);
};

subtest 'right' => sub {
  my $right = right('a');
  ok $either_t->check($right);
  ok ! $left_t->check($right);
  ok $right_t->check($right);
};

subtest 'Either[Int, Str]' => sub {
  my $str_or_arrayref_t = $either_t->parameterize('Left[Str] | Right[ArrayRef]');
  ok $str_or_arrayref_t;

  ok $str_or_arrayref_t->check( left('a') );
  ok $str_or_arrayref_t->check( right([]) );

  ok ! $str_or_arrayref_t->check( left([]) );
  ok ! $str_or_arrayref_t->check( right(1) );
};

subtest 'ill-defined Either' => sub {
  my $pattern = qr/Either must have Left and Right/;
  like +(exception { $either_t->parameterize('Left[Str]') }), $pattern;
  like +(exception { $either_t->parameterize('Left[Str] | Int') }), $pattern;
};

done_testing;
