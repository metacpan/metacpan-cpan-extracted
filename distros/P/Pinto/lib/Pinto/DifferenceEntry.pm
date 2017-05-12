# ABSTRACT: Represents one addition or deletion in a diff

package Pinto::DifferenceEntry;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str);

use String::Format;

#------------------------------------------------------------------------------

use overload (
    q{""} => 'to_string',
    'cmp' => 'string_compare',
);

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

# TODO: Consider breaking this into separate Addition and Deletion subclasses,
# rather than using an "op" attribute to indicate which kind it is.  That sort
# of "type" flag is always a code smell to me.

#------------------------------------------------------------------------------

has op => (
    is       => 'ro',
    isa      => Str,
    required => 1
);

has registration => (
    is       => 'ro',
    isa      => 'Pinto::Schema::Result::Registration',
    required => 1,
);

#------------------------------------------------------------------------------

sub is_addition { shift->op eq '+' }

sub is_deletion { shift->op eq '-' }

#------------------------------------------------------------------------------

sub to_string {
    my ( $self, $format ) = @_;

    my %fspec = ( o => $self->op );

    $format ||= $self->default_format;
    return $self->registration->to_string( String::Format::stringf($format, %fspec) );
}

#------------------------------------------------------------------------------

sub default_format {
    my ($self) = @_;

    return '%o[%F] %-40p %12v %a/%f',
}

#------------------------------------------------------------------------------

sub string_compare {
    my ( $self, $other ) = @_;

    return $self->registration->distribution->name
        cmp $other->registration->distribution->name;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::DifferenceEntry - Represents one addition or deletion in a diff

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
