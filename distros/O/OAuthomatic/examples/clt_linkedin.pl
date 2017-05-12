#!/usr/bin/perl -w
use strict;
use warnings;
use feature 'say';
use Const::Fast;
use Data::Dumper;

# https://developer.linkedin.com/oauth-10a-overview

=head1 auth_to_linkedin

This example performs OAuth authorization sequence and then calls some
Twitter method which require authorization (grabs user details).
Various keys used in the process are saved in keyring (if any is
available) so re-run need not ask for them anymore.

See L<https://developer.linkedin.com/apis> for some API details.

=cut

use OAuthomatic;

my $oauthomatic = OAuthomatic->new(
    app_name => "OAuthomatic demo",
    password_group => "OAuthomatic ad-hoc keys (private)",
    server => 'LinkedIn',
    # browser => "firefox",
    # debug => 1,     # Print various info about progress
   );

print "*** Setting up OAuth communication\n";

$oauthomatic->ensure_authorized();

print "*** Getting user info\n";

# LinkedIn uses XML, let's parse it a little bit
{
    package My::LinkedIn::User;
    use XML::Rabbit::Root;
    has_xpath_value 'first_name' => '/person/first-name';
    has_xpath_value 'last_name' => '/person/last-name';
    has_xpath_value 'headline' => '/person/headline';
    finalize_class();
};

my $reply = $oauthomatic->get_xml('https://api.linkedin.com/v1/people/~');
my $obj = My::LinkedIn::User->new(xml => $reply);
say "First name: ", $obj->first_name;
say "Last name:  ", $obj->last_name;
say "Headline:   ", $obj->headline;
# print $reply;
