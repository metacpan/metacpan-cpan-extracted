#line 1
package Test::SharedFork;
use strict;
use warnings;
use base 'Test::Builder::Module';
our $VERSION = '0.11';
use Test::Builder 0.32; # 0.32 or later is needed
use Test::SharedFork::Scalar;
use Test::SharedFork::Array;
use Test::SharedFork::Store;
use 5.008000;

my $STORE;

BEGIN {
    $STORE = Test::SharedFork::Store->new(
        cb => sub {
            my $store = shift;
            tie __PACKAGE__->builder->{Curr_Test}, 'Test::SharedFork::Scalar', 0, $store;
            tie @{ __PACKAGE__->builder->{Test_Results} }, 'Test::SharedFork::Array', $store;
        }
    );

    no strict 'refs';
    no warnings 'redefine';
    for my $name (qw/ok skip todo_skip current_test/) {
        my $orig = *{"Test::Builder::${name}"}{CODE};
        *{"Test::Builder::${name}"} = sub {
            local $Test::Builder::Level += 4;
            my @args = @_;
            $STORE->lock_cb(sub {
                $orig->(@args);
            });
        };
    };
}

{
    # backward compatibility method
    sub parent { }
    sub child  { }
    sub fork   { fork() }
}

1;
__END__

#line 96
