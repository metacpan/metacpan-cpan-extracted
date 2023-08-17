#!/usr/bin/env perl

=head1 DESCRIPTION

Ensure that mocked resources are not re-fetched.

=cut

use strict;
use warnings;
use Test::More;
use Test::Exception;

{
    package My::Project;
    use Carp;
    use Resource::Silo;

    resource foo => sub { croak "Foo unimplemented" };
    resource bar => sub { $_[0]->foo + 1 };
}

throws_ok {
    my $inst = My::Project->silo;
    $inst->bar;
} qr(Foo unimplemented), 'missing resource = no go';

lives_and {
    my $inst = My::Project->silo->new(foo => 41);
    is $inst->bar, 42, 'supplied resource = works';
};

done_testing;
