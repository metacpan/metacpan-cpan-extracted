
use strict;
use Test::Most;
use FindBin;
use lib "$FindBin::Bin/lib";

use Test::DBIx::Class
{
    schema_class => 'OpusVL::Preferences::Schema',
	traits       => 'Testpostgresql',
}, 'TestOwner';

my $rs = ResultSet ('TestOwner');

my $defaults = $rs->prf_defaults;

is_resultset ($defaults); #  'Resultset sanity check'

$defaults->populate
([
	[qw/ name    default_value      /],
	[qw/ test1   111                /],
]);

my $owner = $rs->create ({ name => 'test' });

throws_ok { $owner->prf_get('blah') } qr/Field blah not setup/i, 'Check non existant field access throws an error';
is $owner->prf_get ('test1'), '111'    => 'Preference uses the default';

$owner->prf_set ('test1' => '222');
is $owner->prf_get ('test1'), '222'    => 'Preference can be overridden';

$owner->prf_reset ('test1');
is $owner->prf_get ('test1'), '111'    => 'Preference reset back to default';

is_fields [qw/name default_value/] => $defaults,
[
	[qw/test1 111/]
], 'Check final fields are sensible';

my $default = $defaults->first; 
$default->create_related('values', { value => 'test' });
$default->create_related('values', { value => 'test2' });
eq_or_diff $default->form_options, [[ 'test', 'test' ], ['test2', 'test2']];

$defaults->create({
    name => 'another',
    data_type => 'text',
    comment => 'blah',
    default_value => '',
});

ok my $results = TestOwner->with_fields({
    test1 => '222',
    name => 'again',
});
is $results->count, 0;

ok my $test = TestOwner->join_by_name('test1');
is $test->count, 1;

ok my $s = TestOwner->select_extra_fields('test1', 'name');
is $s->{rs}->count, 1;
ok my $s2 = TestOwner->prefetch_extra_fields('test1', 'name');
is $s->{rs}->count, 1;

my $email_field = $defaults->create({
    name => 'email',
    data_type => 'email',
    comment => 'Email',
    default_value => '',
    unique_field => 1,
});

$owner->prf_set('email', 'colin@opusvl.com');
is $owner->prf_get('email'), 'colin@opusvl.com';

my $second = $rs->create ({ name => 'another' });
throws_ok { $second->prf_set('email', 'colin@opusvl.com') } qr/unique_vals/i;
ok ! $second->prf_get('email');

$email_field->update({ unique_field => 0 });

$second->prf_set('email', 'colin@opusvl.com');
is $second->prf_get('email'), 'colin@opusvl.com';

throws_ok { $email_field->update({ unique_field => 1 })} qr/unique_vals/i;;

$second->prf_reset('email');
$email_field->discard_changes;
$email_field->update({ unique_field => 1 });
ok ! $second->prf_get('email');
throws_ok { $second->prf_set('email', 'colin@opusvl.com') } qr/unique_vals/i;
throws_ok { $second->prf_set('not_there', 'colin@opusvl.com') } qr/Field not_there not setup/i;

is $email_field->mask_function->('rabbits'), 'rabbits';
$email_field->display_mask('(\d{3}).*(\d{4})');
$email_field->update;
is $email_field->mask_function->('rabbits'), '*******';
is $email_field->mask_function->('1234567890123'), '123******0123';

done_testing;
