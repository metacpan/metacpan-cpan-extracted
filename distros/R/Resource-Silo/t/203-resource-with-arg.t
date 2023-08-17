#!/usr/bin/env perl

=head1 DESCRIPTION

Test passing parameters to resources.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

use Resource::Silo;
resource real_foo   => sub { 42 };
resource foo        =>
    argument            => qr/[0-9]+/,
    init                => sub { $_[0]->real_foo + $_[2] };
resource recursive  =>
    argument            => qr/[0-9]+/,
    init                => sub {
        my ($self, $name, $arg) = @_;
        return $arg <= 1? $arg : $self->$name($arg - 1) + $self->$name($arg - 2);
    };

lives_and {
    is silo->foo( 0 ), 42, 'resource with args works';
    is silo->foo( '11' ), 53, 'and another one';
};

throws_ok {
    silo->foo;
} qr/resource 'foo'/, 'missing arg';

throws_ok {
    silo->foo( {} );
} qr/resource 'foo'/, 'non-scalar arg';

throws_ok {
    silo->foo( 'i18n' );
} qr/resource 'foo'/, 'arg mismatches rex';

lives_and {
    is silo->recursive(10), 55, 'recursive resource instantiated';
};

done_testing;
