#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

# Making true calls on linkedin, and dropping tokens so they are recquired

use strict;
use warnings;
use Test::Most tests => 10;

my ($reply, $obj);

use_ok('OAuthomatic');

my $oauthomatic = new_ok(
    'OAuthomatic' => [
        app_name => "OAuthomatic demo",
        password_group => "OAuthomatic ad-hoc keys (private)",
        server => 'LinkedIn',
       ]);

$oauthomatic->ensure_authorized();
pass("authorized");
diag("Access token: " . $oauthomatic->token_cred->token);

{
    package My::LinkedIn::User;
    use XML::Rabbit::Root;
    has_xpath_value 'first_name' => '/person/first-name';
    has_xpath_value 'last_name' => '/person/last-name';
    has_xpath_value 'headline' => '/person/headline';
    finalize_class();
};

$reply = $oauthomatic->get_xml('https://api.linkedin.com/v1/people/~');
ok($reply);
$obj = My::LinkedIn::User->new(xml => $reply);
ok($obj);
is($obj->first_name, 'Marcin');

$oauthomatic->erase_token_cred();
diag("Dropped credentials");

throws_ok { $oauthomatic->_caller->build_oauth_request } "OAuthomatic::Error::Generic";

$reply = $oauthomatic->get_xml('https://api.linkedin.com/v1/people/~');
ok($reply);
$obj = My::LinkedIn::User->new(xml => $reply);
ok($obj);
is($obj->first_name, 'Marcin');

diag("Access token: " . $oauthomatic->token_cred->token);


done_testing;
