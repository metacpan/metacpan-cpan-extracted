# ABSTRACT: Join two stack histories together

package Pinto::Action::Merge;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(StackName StackObject StackDefault);

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


has into_stack => (
    is       => 'ro',
    isa      => StackName | StackObject | StackDefault,
    default  => undef,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);
    my $from_head  = $stack->head;

    my $into_stack = $self->repo->get_stack($self->into_stack);
    my $into_head  = $into_stack->head;

    return 1 && $self->warning("Both stacks are the same ($into_head)")
        if $into_head->id == $from_head->id;

    throw "Recursive merge is not supported yet"
        unless $from_head->is_descendant_of($into_head);

    $into_stack->update({head => $from_head->id});
    $into_stack->write_index;

    my $format = '%i: %{40}T';
    $self->diag("Fast-forward...");
    $self->diag("Stack $into_stack was " . $into_head->to_string($format));
    $self->diag("Stack $into_stack now " . $from_head->to_string($format));

    return 1;
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

Pinto::Action::Merge - Join two stack histories together

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
