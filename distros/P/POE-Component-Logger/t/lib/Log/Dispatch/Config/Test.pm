use strict;
use warnings;

package t::lib::Log::Dispatch::Config::Test::Tester;

use base 't::lib::Log::Dispatch::Expect';
use Test::More;

sub expect
{
    my ($self, $got, $expected) = @_;
    unless (defined $expected) {
        Test::More::fail "message '$got->{message}' unexpected";
        return;
    }
    local $TODO = $expected->{TODO} if exists $expected->{TODO};
    Test::More::is($got->{level}, $expected->{level}, "level $expected->{level} ok");
    Test::More::is($got->{message}, $expected->{message}, "message '$expected->{message}' ok");
}


package t::lib::Log::Dispatch::Config::Test;

use Log::Dispatch::Config;
use t::lib::Log::Dispatch::Configurator::Static;

my $_configurator;


sub import
{
    my $exporter = shift;
    my $tests = shift;
    die "ARRAY expected" unless ref($tests) eq 'ARRAY';
    warn "No tests" if $#{$tests} == -1;
    $_configurator = t::lib::Log::Dispatch::Configurator::Static->new(
        format => undef,
        dispatchers => {
            test => {
                class => 't::lib::Log::Dispatch::Config::Test::Tester',
                min_level => 'debug',
                expected => [
                    @$tests
                ],
            },
        },
    );
    Log::Dispatch::Config->configure($_configurator);
}

sub configurator
{
    #my $self = shift;
    return $_configurator;
}

1;
# vim: set et ts=4 sw=4 sts=4 :
