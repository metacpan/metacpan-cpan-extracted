#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 10;

require_ok( 'SMS::MessageBird' );

my $messagebird = SMS::MessageBird->new(
    api_key    => 'test_abcd',
    originator => 'original_origin',
);
ok(defined $messagebird && ref $messagebird eq 'SMS::MessageBird',
    'We can instantiate SMS::MessageBird');

# Check that all the sub modules are loaded when the main SMS::MessageBird
# class is instantiated.
ok(@{ $messagebird->{loaded_modules} } == 6,
    'All sub-modules loaded into SMS::MessageBird ok');

# Check that the originator gets set properly in the constuctor and that
# the originiator mutator updates it correctly.
ok($messagebird->{module_data}{originator} eq 'original_origin',
    'Originator param was set correctly by the constructor');

ok($messagebird->originator('new_origin') eq 'new_origin',
    'We can set a new originator');

ok($messagebird->{module_data}{originator} eq 'new_origin',
    'The new originator is set correctly internally');

# Check that the api_url defaults to https://rest.messagebird.com
ok($messagebird->api_url eq 'https://rest.messagebird.com',
    'api_url defaults to MessageBird');

# Also check that api_url mutator works.
ok($messagebird->api_url('http://localhost') eq 'http://localhost',
    'api_url call returns expected data.');

ok($messagebird->{module_data}{api_url} eq 'http://localhost',
    'api_url was updated correctly internally');


# Finally, check that reloading the modules doesn't just add to the
# loaded_modules list.
$messagebird->_load_modules();
ok(@{ $messagebird->{loaded_modules} } == 6,
    'Reloading modules works ok');

