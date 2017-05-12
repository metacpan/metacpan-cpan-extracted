#!perl -T

use strict;
use warnings;
use Test::More tests => 3;

{
    package My::Browser;
    use base 'LWP::UserAgent';

    sub new {
        my $class = shift;
        my $new = $class->SUPER::new(@_);

        return bless $new, $class;
    }
}

BEGIN { use_ok 'Net::OAuth::Simple' }

my $browser = My::Browser->new(timeout => 20);

my $client = Net::OAuth::Simple->new(
    tokens => {
        consumer_key => 'test',
        consumer_secret => 'test',
    },
    urls => {
        authorization_url => 'http://localhost/auth',
        request_token_url => 'http://localhost/req',
        access_token_url  => 'http://localhost/acc',
    },
    browser => $browser,
);

isa_ok $client->{browser}, 'My::Browser';
is     $client->{browser}->timeout, 20, 'browser is preconfigured'
