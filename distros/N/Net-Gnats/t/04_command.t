use strict;
use warnings;
use Test::More;
use Net::Gnats::Command;
use Net::Gnats::PR;
use Net::Gnats::Field;
use Net::Gnats::FieldInstance;

isa_ok my $c = Net::Gnats::Command->new, 'Net::Gnats::Command';

my $field = Net::Gnats::FieldInstance->new;

is $c->field, undef, 'init field is undef';
is $c->field('foo'), undef, 'passing in just a string does nothing';
is $c->field(['foo']), undef, 'passing in an array ref does nothing';
is $c->field(bless ( {}, 'Net::Gnats::Field' )), undef,
  'passing in an object of wrong type does nothing';
is $c->field($field), $field, 'passing in field gets field';
is $c->field, $field, 'passing in nothing gets the field';

is $c->field_change_reason, undef, 'init field is undef';
is $c->field_change_reason('foo'), undef, 'passing in just a string does nothing';
is $c->field_change_reason(['foo']), undef, 'passing in an array ref does nothing';
is $c->field_change_reason(bless ( {}, 'Net::Gnats::Field' )), undef,
  'passing in an object of wrong type does nothing';
is $c->field_change_reason($field), $field, 'passing in field gets field';
is $c->field_change_reason, $field, 'passing in nothing gets the field';

is $c->pr, undef, 'init field is undef';
is $c->pr('foo'), undef, 'passing in just a string does nothing';
is $c->pr(['foo']), undef, 'passing in an array ref does nothing';
is $c->pr(bless ( {}, 'Net::Gnats::Field' )), undef,
  'passing in an object of wrong type does nothing';
my $pr = Net::Gnats::PR->new;
is $c->pr($pr), $pr, 'passing in PR gets a PR';
is $c->pr, $pr, 'passing in nothing gets the set PR';

# Error codes not used yet, will be undef
is $c->error_codes, undef;

# Success codes not used yet, will be undef
is $c->success_codes, undef;

# Requests Multi is used for subclasses
is $c->requests_multi, undef;

done_testing;
