use Test::More;
use Test::Moose::More 0.014;
use Moose::Util::TypeConstraints 'class_type';
use autobox::Core;
use Hash::Merge::Simple 'merge';

use lib 't/lib';

use MooseX::Types::Moose ':all';
use Test::Class::__WONKY__;

# debugging...
#use Smart::Comments '###';

with_immutable {

    # TODO merge is Ok here as there should be no key/etc conflicts (or
    # duplicates) between these hashes.  For the sake of being rigorous, we
    # should probably address this.
    my $test_hash = merge
        related('One'),
        related('Sub::One'),
        ;

    ### $test_hash
    validate_class 'Test::Class::__WONKY__' => %$test_hash;


} 'Test::Class::__WONKY__'; #  (map { "Test::Class::__WONKY__$_" } q{}, 'One', 'Sub::One');

done_testing;  # <=======================

sub related {
    my $related = shift;
    my $flat    = $related->split(qr/::/)->join('__')->lc;

    my $test_hash = {
        attributes => [
            (
                "${flat}_class" => {
                    reader   => "${flat}_class",
                    isa      => class_type("Test::Class::__WONKY__::$related"),
                    lazy     => 1,
                    init_arg => undef,
                },
                "${flat}_class_traits" => {
                    traits  => ['Array'],
                    reader  => "${flat}_class_traits",
                    handles => { "has_${flat}_class_traits" => 'count' },
                    builder => "_build_${flat}_class_traits",
                    isa     => ArrayRef[class_type("Test::Class::__WONKY__::${related}")],
                    lazy    => 1,
                },
                "original_${flat}_class" => {
                    reader   => "original_${flat}_class",
                    isa      => class_type("Test::Class::__WONKY__::${related}"),
                    lazy     => 1,
                    init_arg => "${flat}_class",
                },
            ),
        ],
        methods => [ "_build_${flat}_class" ],
    };

    ### $test_hash
    return $test_hash;
}

