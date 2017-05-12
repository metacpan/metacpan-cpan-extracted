=head1 PURPOSE

Checks classes extending abstract ones can have custom constructors.

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

our $custom_constructor_called = 0;

{
    package Foo;
    use Moose;
    use MooseX::ABCD;

    requires 'bar', 'baz';
    __PACKAGE__->meta->make_immutable;
}

{
    package Foo::Sub;
    use Moose;
    extends 'Foo';

    sub bar { }
    sub baz { }
    sub new { $::custom_constructor_called++; shift->SUPER::new(@_) }
    __PACKAGE__->meta->make_immutable(inline_constructor => 0);
}

my $foosub = Foo::Sub->new;
ok($custom_constructor_called, 'custom constructor was called');

done_testing;
