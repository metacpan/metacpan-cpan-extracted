package MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint;

use strict;
use warnings;

our $VERSION = '0.21';

use Moose;
use Moose::Util::TypeConstraints qw( duck_type );

extends 'Moose::Exception';

has parameter => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has value => (
    is       => 'ro',
    isa      => 'Any',
    required => 1,
);

has type => (
    is       => 'ro',
    isa      => duck_type( [qw( get_message name )] ),
    required => 1,
);

sub _build_message {
    my $self = shift;

    return
          $self->parameter
        . ' does not pass the type constraint because: '
        . $self->type()->get_message( $self->value() );
}

no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Exception thrown when a type constraint check fails

__END__

=pod

=head1 NAME

MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint - Exception thrown when a type constraint check fails

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use MooseX::Params::Validate qw( validated_list );
    use Scalar::Util qw( blessed );
    use Try::Tiny;

    try {
        my @p = validated_list( @_, foo => { isa => 'Str' } );
    }
    catch {
        if (
            blessed $_
            && $_->isa(
                'MooseX::Params::Validate::Exception::ValidationFailedForTypeConstraint'
            )
            ) {
            ...;
        }
    };

=head1 DESCRIPTION

This class provides information about type constraint failures.

=head1 METHODS

This class provides the following methods:

=head2 $e->parameter()

This returns a string describing the parameter, something like C<The 'foo'
parameter> or C<Parameter #1>.

=head2 $e->value()

This is the value that failed the type constraint check.

=head2 $e->type()

This is the type constraint object that did not accept the value.

=head1 STRINGIFICATION

This object stringifies to a reasonable error message.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 - 2015 by Stevan Little <stevan@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
