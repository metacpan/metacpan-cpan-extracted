# ABSTRACT: Show or change stack properties

package Pinto::Action::Props;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );
use MooseX::Types::Moose qw(Str HashRef);

use String::Format qw(stringf);

use Pinto::Constants qw(:color);
use Pinto::Util qw(is_system_prop);
use Pinto::Types qw(StackName StackDefault StackObject);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is  => 'ro',
    isa => StackName | StackDefault | StackObject,
);

has properties => (
    is        => 'ro',
    isa       => HashRef,
    predicate => 'has_properties',
);

has format => (
    is      => 'ro',
    isa     => Str,
    default => "%p = %v",
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack( $self->stack );

    $self->has_properties
        ? $self->_set_properties($stack)
        : $self->_show_properties($stack);

    return $self->result;
}

#------------------------------------------------------------------------------

sub _set_properties {
    my ( $self, $target ) = @_;

    $target->set_properties( $self->properties );

    $self->result->changed;

    return;
}

#------------------------------------------------------------------------------

sub _show_properties {
    my ( $self, $target ) = @_;

    my $props = $target->get_properties;
    while ( my ( $prop, $value ) = each %{$props} ) {

        my $string = stringf( $self->format, { p => $prop, v => $value } );
        my $color = is_system_prop($prop) ? $PINTO_COLOR_2 : undef;

        $self->show( $string, { color => $color } );
    }

    return;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer BenRifkah Fowler Jakob Voss Karen Etheridge Michael
G. Bergsten-Buret Schwern Oleg Gashev Steffen Schwigon Tommy Stanton
Wolfgang Kinkeldei Yanick Boris Champoux hesco popl Däppen Cory G Watson
David Steinbrunner Glenn

=head1 NAME

Pinto::Action::Props - Show or change stack properties

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
