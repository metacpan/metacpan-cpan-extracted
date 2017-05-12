# ABSTRACT: Create a new stack by copying another

package Pinto::Action::Copy;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Types qw(StackName StackObject);

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackObject,
    required => 1,
);

has to_stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);

has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has lock => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has description => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_description',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my %changes = ( name => $self->to_stack );
    my $orig    = $self->repo->get_stack( $self->stack );
    my $copy    = $self->repo->copy_stack( stack => $orig, %changes );

    my $description =
          $self->has_description
        ? $self->description
        : "Copy of stack $orig";

    $copy->set_description($description);
    $copy->mark_as_default if $self->default;
    $copy->lock            if $self->lock;

    return $self->result->changed;
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

Pinto::Action::Copy - Create a new stack by copying another

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
