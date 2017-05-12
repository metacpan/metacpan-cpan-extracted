#!/usr/bin/perl -c

package Test::Builder::Mock::Class::Role::Meta::Class;

=head1 NAME

Test::Builder::Mock::Class::Role::Meta::Class - Metaclass for mock class

=head1 DESCRIPTION

This role provides an API for defining mock class.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0203';

use Moose::Role;


=head1 INHERITANCE

=over 2

=item *

L<Test::Mock::Class::Role::Meta::Class>

=back

=cut

with 'Test::Mock::Class::Role::Meta::Class';


use Exception::Base (
    '+ignore_package' => [__PACKAGE__],
);


=head1 ATTRIBUTES

=over

=item B<mock_base_object_role> : Str = "Test::Builder::Mock::Class::Role::Object"

Base object role for mock class.  The default is
L<Test::Builder::Mock::Class::Role::Object>.

=cut

has 'mock_base_object_role' => (
    is      => 'rw',
    default => 'Test::Builder::Mock::Class::Role::Object',
);


use namespace::clean -except => 'meta';


1;


=back

=begin umlwiki

= Class Diagram =

[                              <<role>>
                  Test::Builder::Mock::Class::Role::Meta::Class
 ------------------------------------------------------------------------------
 +mock_base_object_role = "Test::Builder::Mock::Class::Role::Object"
 ------------------------------------------------------------------------------
                                                                               ]

[Test::Builder::Mock::Class::Role::Meta::Class] ---|> [<<role>> Test::Mock::Class::Role::Meta::Class]

=end umlwiki

=head1 SEE ALSO

L<Test::Mock::Class::Role::Meta::Class>, L<Test::Builder::Mock::Class>.

=head1 BUGS

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Based on SimpleTest, an open source unit test framework for the PHP
programming language, created by Marcus Baker, Jason Sweat, Travis Swicegood,
Perrick Penet and Edward Z. Yang.

Copyright (c) 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under GNU Lesser General Public License.
