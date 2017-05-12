use Test::Able::Runner;
use Test::More;
use Scalar::Util qw( blessed );

use_test_packages
    -base_package => 'Test::Test::Able::Runner',
    -test_path    => 't/base';

our $ran = 0;

test plan => 2, finds_packages => sub {
    my $self = shift;

    is_deeply(
        [ sort $self->meta->test_classes ],
        [ qw(
            Test::Test::Able::Runner::Dickory
            Test::Test::Able::Runner::Dock
            Test::Test::Able::Runner::Hickory
            Test::Test::Able::Runner::Role
        ) ],
        'hickory, dickory, dock packages'
    );

    is_deeply(
        [ sort map { blessed $_ } @{ $self->meta->test_objects } ],
        [ qw(
            Test::Test::Able::Runner::Dickory
            Test::Test::Able::Runner::Dock
            Test::Test::Able::Runner::Hickory
            main
        ) ],
        'hickory, dickory, dock (and self) objects'
    );

    $ran++;
}; 

run;

die "find_packages did not run" unless $ran;
