=head1 PURPOSE

General tests that abstract base classes work.

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

my $xyz;
$xyz = q{
	use Test::Pod;
	use Test::Pod::Coverage;
};

{
    package Foo;
    use Moose;
    use MooseX::ABCD;

    requires 'bar', 'baz';
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub1;
    use Moose;
    ::is(::exception { extends 'Foo' }, undef,
        "extending works when the requires are fulfilled");
    sub bar { }
    sub baz { }
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub2;
    use Moose;
    extends 'Foo';
    sub bar { }
    ::like(
        ::exception { __PACKAGE__->meta->make_immutable },
        qr/Foo requires Foo::Sub2 to implement baz/,
        "extending fails with the correct error when requires are not fulfilled"
    );
}

{
    package Foo::Sub::Sub;
    use Moose;
    ::is(::exception { extends 'Foo::Sub1' }, undef,
        "extending twice works");
    __PACKAGE__->meta->make_immutable;
}

{
    my $foosub;
    is(exception { $foosub = Foo::Sub1->new }, undef,
       "instantiating concrete subclasses works");
    isa_ok($foosub, 'Foo', 'inheritance is correct');
}

{
    my $foosubsub;
    is(exception { $foosubsub = Foo::Sub::Sub->new }, undef,
       "instantiating deeper concrete subclasses works");
    isa_ok($foosubsub, 'Foo', 'inheritance is correct');
    isa_ok($foosubsub, 'Foo::Sub1', 'inheritance is correct');
}

like(exception { Foo->new }, qr/Foo is abstract, it cannot be instantiated/,
     "instantiating abstract classes fails");

done_testing;
