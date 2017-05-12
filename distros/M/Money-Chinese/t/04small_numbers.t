#########################

use Test::More "no_plan";

#########################

use Money::Chinese;

my $object = Money::Chinese->new;

is($object->convert('10.56'), '壹拾元伍角陆分', '10.56 is 壹拾元伍角陆分');
is($object->convert('10.56789'), '壹拾元伍角陆分', '10.56789 is 壹拾元伍角陆分');
is($object->convert('0.56'), '伍角陆分', '0.56 is 伍角陆分');
is($object->convert('10'), '壹拾元整', '10 is 壹拾元整');
is($object->convert('10.0'), '壹拾元整', '10.0 is 壹拾元整');
is($object->convert('10.00'), '壹拾元整', '10.00 is 壹拾元整');

