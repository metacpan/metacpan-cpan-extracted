package SleepTest::Handler;

use strict;
use warnings;

use Sleep::Routes;

require Sleep::Handler;
our @ISA = qw/Sleep::Handler/;

my $routes = Sleep::Routes->new([
    { 
        route => qr{/test1(?:/(\d+))?$},
        class => 'SleepTest::Test1' 
    },
]);

sub new {
    return __PACKAGE__->BUILD(undef, $routes);
}

sub handler : method {
    my $self = shift;
    return $self->SUPER::handler(@_);
}

1;

