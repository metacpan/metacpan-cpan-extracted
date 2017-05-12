use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Exception;
use Readonly;
use HTTP::Response;
use URI;

use lib 'lib';
use Sailthru::Client;

Readonly my $API_KEY => 'abcdef1234567890abcdef1234567890';

my $module = Test::MockModule->new('Sailthru::Client');

# mock so we don't actually make a call out to the network
# we'll use api_req_args to grab and hold on to the arguments passed in to compare
my $api_req_args;
$module->mock(
    _api_request => sub {
        my $self = shift;
        $api_req_args = \@_;
    }
);

my $sc = Sailthru::Client->new( $API_KEY, '00001111222233334444555566667777' );
isa_ok( $sc, 'Sailthru::Client' );

# helper method to verify object methods
sub verify_object_method {
    my ( $object_method, $args, $req_type, $api_action ) = @_;
    # clear saved args from mock
    $api_req_args = undef;
    # is the method in the module?
    can_ok( $sc, $object_method );
    lives_ok( sub { $sc->$object_method( @{$args} ) }, "$object_method: lives when called" );
    # see if right API action was accessed
    is( $api_req_args->[0], $api_action, "$object_method: api action '$api_action' was called" );
    # make sure the http request verb matches
    is( $api_req_args->[2], $req_type, "$object_method: request type was $req_type" );
}

my $object_method;
my $expected_req_type;
my $expected_api_action;
my @args;

# test send
$expected_req_type   = 'POST';
$expected_api_action = 'send';
$object_method       = 'send';
# test without optional arguments
@args = ( 'template_name', 'email@email.com' );
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# test with optional arguments
my %vars = my %save_vars = ( var1 => 'foo', var2 => 'bar', var3 => 'baz' );
my %options = my %save_options = ( replyto => 'someotheremail@email.com' );
@args = ( 'template_name', 'email@email.com', \%vars, \%options, '+6 hours' );
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hashes weren't munged
is_deeply( \%vars,    \%save_vars,    "$object_method: vars hash wasn't changed" );
is_deeply( \%options, \%save_options, "$object_method: options hash wasn't changed" );

# test get_send
$expected_req_type   = 'GET';
$expected_api_action = 'send';
$object_method       = 'get_send';
@args                = ('my-send-id-alskdjfals');
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test get_email
$expected_req_type   = 'GET';
$expected_api_action = 'email';
$object_method       = 'get_email';
@args                = ('anemail@email.com');
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test set_email
$expected_req_type   = 'POST';
$expected_api_action = 'email';
$object_method       = 'set_email';
# test without optional args
@args = ('atestemail@email.com');
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# test with optional args
%vars = %save_vars = ( var1 => 'foo', var2 => 'bar', var3 => 'baz' );
my %lists = my %save_lists = ( list1 => 1, list2 => 0, list3 => 1 );
my %templates = my %save_templates = ( template1 => 0, template2 => 1 );
@args = ( 'atestemail@email.com', \%vars, \%lists, \%templates );
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hashes weren't munged
is_deeply( \%vars,      \%save_vars,      "$object_method: vars hash wasn't changed" );
is_deeply( \%lists,     \%save_lists,     "$object_method: lists hash wasn't changed" );
is_deeply( \%templates, \%save_templates, "$object_method: templates hash wasn't changed" );

# test schedule_blast
$expected_req_type   = 'POST';
$expected_api_action = 'blast';
$object_method       = 'schedule_blast';
# test without optional arg
@args = (
    'blast name', 'list to send to',
    '+3 hours', 'From Name', 'fromemail@email.com',
    'Blast Subject Line',
    '<p><b>Some</b> html content!</p>',
    'Some text content'
);
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# test with optional arg
%options = %save_options = ( replyto => 'someotheremail@email.com' );
@args = (
    'blast name', 'list to send to',
    '+3 hours', 'From Name', 'fromemail@email.com',
    'Blast Subject Line',
    '<p><b>Some</b> html content!</p>',
    'Some text content', \%options
);
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hashes weren't munged
is_deeply( \%options, \%save_options, "$object_method: options hash wasn't changed" );

# test schedule_blast_from_template
$expected_req_type   = 'POST';
$expected_api_action = 'blast';
$object_method       = 'schedule_blast_from_template';
# test without optional arg
@args = ( 'template name to copy from', 'list to send to', '+3 hours' );
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# test with optional arg
%options = %save_options = ( from_name => 'a name', from_email => 'email@email.com' );
@args = ( 'template name to copy from', 'list to send to', '+3 hours', \%options );
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );
# make sure hashes weren't munged
is_deeply( \%options, \%save_options, "$object_method: options hash wasn't changed" );

# test get_blast
$object_method       = 'get_blast';
@args                = ('blast-id-sldkjfsdk');
$expected_req_type   = 'GET';
$expected_api_action = 'blast';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

# test get_template
$object_method       = 'get_template';
@args                = ('template name');
$expected_req_type   = 'GET';
$expected_api_action = 'template';
verify_object_method( $object_method, \@args, $expected_req_type, $expected_api_action );

done_testing;
