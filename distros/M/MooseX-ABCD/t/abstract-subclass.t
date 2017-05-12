=head1 PURPOSE

Check abstract classes can inherit from other abstract classes, and that
concrete classes can then extend those.

This test is taken from MooseX-ABC with minor modifications.

=head1 AUTHOR 

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE 

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Foo;
    use Moose;
    use MooseX::ABCD;

    requires 'foo';
    requires 'bar';
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub;
    use Moose;
    use MooseX::ABCD;
    extends 'Foo';

    requires 'baz';

    sub bar { 'BAR' }
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub::Sub;
    use Moose;
    extends 'Foo::Sub';

    sub foo { 'FOO' }
    sub baz { 'BAZ' }
    __PACKAGE__->meta->make_immutable;
}

like(
    exception { Foo->new },
    qr/Foo is abstract, it cannot be instantiated/,
    "can't create Foo objects"
);
like(
    exception { Foo::Sub->new },
    qr/Foo::Sub is abstract, it cannot be instantiated/,
    "can't create Foo::Sub objects"
);

my $foo = Foo::Sub::Sub->new;
is($foo->foo, 'FOO', 'successfully created a Foo::Sub::Sub object');

done_testing;
