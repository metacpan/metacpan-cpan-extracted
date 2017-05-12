package Params::CheckCompiler::Exceptions;

use strict;
use warnings;

our $VERSION = '0.08';

use Exception::Class (
    'Params::CheckCompiler::Exception::BadArguments',
    'Params::CheckCompiler::Exception::Named::Extra' => {
        fields => ['parameters'],
    },
    'Params::CheckCompiler::Exception::Named::Required' => {
        fields => ['parameter'],
    },
    'Params::CheckCompiler::Exception::Positional::Extra' => {
        fields => [ 'got', 'maximum' ],
    },
    'Params::CheckCompiler::Exception::Positional::Required' => {
        fields => [ 'got', 'minimum' ],
    },
    'Params::CheckCompiler::Exception::ValidationFailedForMooseTypeConstraint'
        => {
        fields => [qw( parameter value type )],
        },
);

1;

# ABSTRACT: Defines exceptions thrown by Params::CheckCompiler

__END__

=pod

=encoding UTF-8

=head1 NAME

Params::CheckCompiler::Exceptions - Defines exceptions thrown by Params::CheckCompiler

=head1 VERSION

version 0.08

=head1 DESCRIPTION

This module defines the following exceptions:

=head2 Params::CheckCompiler::Exception::BadArguments

Exception thrown when @_ does not contain a hash or hashref.

=head2 Params::CheckCompiler::Exception::Named::Extra

Exception thrown when @_ contains unexpected extra named arguments.

=head2 Params::CheckCompiler::Exception::Named::Required

Exception thrown when a required named parameter is not passed.

=head2 Params::CheckCompiler::Exception::Positional::Extra.

Exception thrown when @_ contains unexpected extra arguments.

=head2 Params::CheckCompiler::Exception::Positional::Required

Exception thrown when a required positional parameter is not passed.

=head2 Params::CheckCompiler::Exception::ValidationFailedForMooseTypeConstraint

Exception thrown when a Moose type constraint check fails. This class provides
the following methods:

=head3 $e->parameter

This returns a string describing the parameter, something like C<The 'foo'
parameter> or C<Parameter #1>.

=head3 $e->value

This is the value that failed the type constraint check.

=head3 $e->type

This is the type constraint object that did not accept the value.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|http://rt.cpan.org/Public/Dist/Display.html?Name=Params-CheckCompiler>
(or L<bug-params-checkcompiler@rt.cpan.org|mailto:bug-params-checkcompiler@rt.cpan.org>).

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
