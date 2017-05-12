use 5.14.1;
use strict;

use Moops;

class SplintTestMethods using Moose {

    method a_test_method(Int $thing!  does doc('The first argument') = '',
                         Int $woo!    does doc('More arg'),
                         HashRef :$h  does doc('An empty hash ref') = {},
                         ArrayRef :$a does doc('Non-empty array ref') = ['value'],
                         Bool :$maybe does doc("If necessary\nmethod_doc|Just a test")
                     --> Str          does doc('In the future')
    ) {
        return 'woo';
    }

    method another(Int $before does doc('whooo'), ArrayRef[Int] $thirsty is slurpy does doc('slurper')) {
        return;
    }
}

1;

__END__

=pod

=encoding utf-8

:splint classname SplintTestMethods

:splint method a_test_method

:splint method another
