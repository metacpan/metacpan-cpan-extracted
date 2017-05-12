use Test::More;

use Data::Monad::Maybe qw( just nothing );
use Mouse::Util::TypeConstraints qw( find_type_constraint );

require_ok 'MouseX::Types::Data::Monad::Maybe';

my $maybe_t = find_type_constraint('MaybeM');
my $maybe_str_t = $maybe_t->parameterize('Str');
my $maybe_object_t = $maybe_t->parameterize('Object');
ok $maybe_t;
ok $maybe_str_t;
ok $maybe_object_t;

subtest 'just a value' => sub {
  my $just_a_str = just 'a';
  ok $maybe_t->check($just_a_str);
  ok $maybe_str_t->check($just_a_str);
  ok ! $maybe_object_t->check($just_a_str);
};

subtest 'nothing' => sub {
  ok $maybe_t->check(nothing);
  ok $maybe_str_t->check(nothing);
  ok $maybe_object_t->check(nothing);
};

subtest 'something not maybe' => sub {
  my $x = bless {}, 'x';
  ok ! $maybe_t->check($x);
};

done_testing;
