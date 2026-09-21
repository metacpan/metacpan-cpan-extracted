#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;
use Test::MockModule;

use OpenStack::Client            ();
use OpenStack::Client::Auth      ();
use OpenStack::MetaAPI           ();
use OpenStack::MetaAPI::UserAgent ();

# LWP reads these when a user agent is made without verify_hostname.  HTTPS_CA_*
# turn the check off, for compatibility with Crypt::SSLeay.
local %ENV = %ENV;
delete @ENV{qw{PERL_LWP_SSL_VERIFY_HOSTNAME HTTPS_CA_FILE HTTPS_CA_DIR}};

my $ENDPOINT = 'https://keystone.test.test:5000/v3';

subtest 'OpenStack::Client alone turns the check off' => sub {
    my $client = OpenStack::Client->new($ENDPOINT);
    is $client->{ua}->ssl_opts('verify_hostname'), 0,
      'which is the reason this class exists';
};

subtest 'new() leaves the decision to LWP' => sub {
    my %ssl_opts = (verify_hostname => 0, SSL_ca_file => '/bogus/ca.pem');
    my $ua = OpenStack::MetaAPI::UserAgent->new(ssl_opts => \%ssl_opts);

    isa_ok $ua, 'LWP::UserAgent';
    is $ua->ssl_opts('verify_hostname'), 1,
      'verify_hostname => 0 is dropped, and LWP turns the check on';
    is $ua->ssl_opts('SSL_ca_file'), '/bogus/ca.pem',
      'the other ssl_opts reach LWP';
    is \%ssl_opts, {verify_hostname => 0, SSL_ca_file => '/bogus/ca.pem'},
      "the caller's hash is not changed";

    is(OpenStack::MetaAPI::UserAgent->new->ssl_opts('verify_hostname'), 1,
        'with no ssl_opts at all, the check is on');

    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    is(OpenStack::MetaAPI::UserAgent->new(ssl_opts => {verify_hostname => 1})
          ->ssl_opts('verify_hostname'),
        0, 'PERL_LWP_SSL_VERIFY_HOSTNAME=0 turns it off');
};

subtest 'HTTPS_CA_FILE turns the check off, as the POD says' => sub {
    local $ENV{HTTPS_CA_FILE} = '/bogus/ca.pem';
    is(OpenStack::MetaAPI::UserAgent->new->ssl_opts('verify_hostname'), 0,
        'without PERL_LWP_SSL_VERIFY_HOSTNAME');

    local $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 1;
    is(OpenStack::MetaAPI::UserAgent->new->ssl_opts('verify_hostname'), 1,
        'PERL_LWP_SSL_VERIFY_HOSTNAME=1 wins over it');
};

subtest 'OpenStack::Client with this class checks the hostname' => sub {
    my $client = OpenStack::Client->new($ENDPOINT,
        package_ua => 'OpenStack::MetaAPI::UserAgent');
    isa_ok $client->{ua}, 'OpenStack::MetaAPI::UserAgent';
    is $client->{ua}->ssl_opts('verify_hostname'), 1, 'the check is on';
};

subtest 'OpenStack::MetaAPI->new gives the auth object this class' => sub {
    my @got;
    my $mock = Test::MockModule->new('OpenStack::Client::Auth');
    $mock->redefine(new => sub { shift; @got = @_; return bless {}, 'Test::Auth' });

    OpenStack::MetaAPI->new($ENDPOINT, username => 'u', version => 3);
    my ($endpoint, %args) = @got;
    is $endpoint, $ENDPOINT, 'the endpoint is passed first, as before';
    is \%args,
      {username => 'u', version => 3, package_ua => 'OpenStack::MetaAPI::UserAgent'},
      'package_ua defaults to this class, and the other arguments are unchanged';

    OpenStack::MetaAPI->new($ENDPOINT, package_ua => 'LWP::UserAgent');
    ($endpoint, %args) = @got;
    is $args{package_ua}, 'LWP::UserAgent', 'a package_ua that the caller names wins';
};

done_testing;
