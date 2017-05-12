#!/usr/bin/perl -c

package Test::Builder::Mock::Class::Role::Object;

=head1 NAME

Test::Builder::Mock::Class::Role::Object - Role for base object of mock class

=head1 DESCRIPTION

This role provides an API for changing behavior of mock class.

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0203';

use Moose::Role 0.89;


=head1 INHERITANCE

=over 2

=item *

with L<Test::Mock::Class::Role::Object>

=back

=cut

with 'Test::Mock::Class::Role::Object' => {
    -alias => {
        mock_invoke => '_mock_invoke_base',
        mock_tally  => '_mock_tally_base',
    },
    -excludes => [ 'mock_invoke', 'mock_tally' ],
};


use English '-no_match_vars';

use Test::Builder;


use Exception::Base (
    '+ignore_package' => [__PACKAGE__],
);


=head1 ATTRIBUTES

=over

=item B<_mock_test_builder> : Test::Builder

The L<Test::Builder> singleton object.

=back

=cut

has '_mock_test_builder' => (
    is      => 'rw',
    default => sub { Test::Builder->new },
);


use namespace::clean -except => 'meta';


## no critic qw(RequireCheckingReturnValueOfEval)

=head1 METHODS

=over

=item B<mock_tally>(I<>) : Self

Check the expectations at the end.  See L<Test::Mock::Class::Role::Object> for
more description.

The test passes if original C<mock_tally> method doesn't throw an exception.

=cut

sub mock_tally {
    my ($self) = @_;

    my $return = eval {
        $self->_mock_tally_base;
    };
    $self->_mock_test_builder->is_eq($EVAL_ERROR, '', 'mock_tally()');

    return $return;
};


=item B<mock_invoke>( I<method> : Str, I<args> : Array ) : Any

Returns the expected value for the method name and checks expectations.  See
L<Test::Mock::Class::Role::Object> for more description.

The test passes if original C<mock_tally> method doesn't throw an exception.

=cut

sub mock_invoke {
    my ($self, $method, @args) = @_;

    my ($return, @return);
    eval {
        if (wantarray) {
            @return = $self->_mock_invoke_base($method, @args);
        }
        else {
            $return = $self->_mock_invoke_base($method, @args);
        };
    };
    $self->_mock_test_builder->is_eq($EVAL_ERROR, '', "mock_invoke($method)");

    return wantarray ? @return : $return;
};


1;


=back

=begin umlwiki

= Class Diagram =

[                                <<role>>
                    Test::Builder::Mock::Class::Role::Object
 -----------------------------------------------------------------------------
 #_mock_test_builder : Test::Builder
 -----------------------------------------------------------------------------
 +mock_tally() : Self
 +mock_invoke( method : Str, args : Array ) : Any
                                                                              ]

[Test::Builder::Mock::Class::Role::Object] ---|> [<<role>> Test::Mock::Class::Role::Object]

=end umlwiki

=head1 SEE ALSO

L<Test::Mock::Class::Role::Object>, L<Test::Mock::Class>.

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
