package RxPerl::Base;

use strict;
use warnings;

use Carp 'croak';
use Module::Load 'load';

our $VERSION = "v6.7.1";

# Abstract base class for RxPerl::AnyEvent, RxPerl::IOAsync and RxPerl::Mojo

sub set_promise_class {
    my ($class, $promise_class) = @_;

    @_ == 2 or croak 'missing $promise_class parameter';

    load $promise_class if length $promise_class;
    no strict 'refs';
    ${ "${class}::promise_class" } = $promise_class;
}

1;