#!perl
use Test::More tests => 4;
use warnings;
use strict;

use Test::Exception;

BEGIN { use_ok('Net::Fritz::IsNoError') };

# a role has no constructor, so we need a dummy class
{
    package Net::Fritz::IsNoError::Stub;
    use Moo;
    with 'Net::Fritz::IsNoError';
}


### public tests

subtest 'check stub role' => sub {
    # given

    # when
    my $obj = Net::Fritz::IsNoError::Stub->new;

    # then
    ok( $obj->does('Net::Fritz::IsNoError'), 'does Net::Fritz::IsNoError role' );
};

subtest 'check error getter' => sub {
    # given
    my $obj = Net::Fritz::IsNoError::Stub->new;

    # when
    my $result = $obj->error;

    # then
    is( $result, '', 'error message is empty' );
};

subtest 'check errorcheck()' => sub {
    # given
    my $obj = Net::Fritz::IsNoError::Stub->new;

    # when/then
    lives_ok( sub { $obj->errorcheck() }, 'errorcheck() does not die' );
};
