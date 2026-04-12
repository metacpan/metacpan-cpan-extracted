# Tests for SimpleMock::Model::SUBS
# Covers: static returns, coderef returns, wantarray, default mocks, die on no match
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../../lib";
use Test::Most;
use SimpleMock qw(register_mocks clear_mocks);
use TestModule;

use SimpleMock::Model::SUBS;

register_mocks(
    SUBS => {
        TestModule => {

            # demo each static return type
            'sub_three' => [
                { returns => 'default mocked value' },
                { args => ['scalar'],
                  returns => 'scalar' },
                { args => ['hashref'],
                  returns => { key => 'value' } },
                { args => ['arrayref'],
                  returns => [ 'value1', 'value2' ] },
                { args => ['array'],
                  returns => sub { (1,2,3) } },
                { args => ['hash'],
                  returns => sub { (key => 'value') } },
            ],

            # demo a coderef mock that uses the args sent
            sub_four => [
                { returns => sub { my ($arg) = @_; return $arg * 2 } },
            ],

            # wantarray example
            sub_six => [
                { returns => sub {
                    my ($arg) = @_;
                    return wantarray ? ($arg, $arg * 2) : $arg * 2;
                  }
                },
            ],
        },
    },
);

is TestModule::sub_three(), 'default mocked value', 'default mock';
is TestModule::sub_three('scalar'), 'scalar', 'scalar mock';
is_deeply TestModule::sub_three('hashref'), { key => 'value' }, 'hashref mock';
is_deeply TestModule::sub_three('arrayref'), [ 'value1', 'value2' ], 'arrayref mock';
my @array = TestModule::sub_three('array');
is_deeply \@array, [ 1, 2, 3 ], 'array mock';
my %hash = TestModule::sub_three('hash');
is_deeply \%hash, { key => 'value' }, 'hash mock';

is TestModule::sub_four(5), 10, 'coderef mock';
is TestModule::sub_four(10), 20, 'coderef mock with different arg';

is TestModule::sub_five(), "mocked sub_five", 'mocked sub_five in SimpleMocks::Mocks::TestModule';
is TestModule::sub_five(1,2), "mocked sub_five with args", 'mocked sub_five in SimpleMocks::Mocks::TestModule with args';

my @s6 = TestModule::sub_six(5);
is_deeply \@s6, [5, 10], 'wantarray mock array';
my $s6 = TestModule::sub_six(5);
is $s6, 10, 'wantarray mock scalar';

################################################################################
# Die behaviour when no mock matches
################################################################################
clear_mocks();
register_mocks(
    SUBS => {
        TestModule => {
            sub_one => [
                { args => ['expected'], returns => 'matched' },
                # no default — unmatched args must die
            ],
        },
    },
);
is   TestModule::sub_one('expected'),  'matched', 'specific-arg mock matches correctly';
dies_ok { TestModule::sub_one('unexpected') } 'dies when args have no match and no default';

done_testing();
