# ABSTRACT: Create a new empty stack

package Pinto::Action::New;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Types qw(StackName PerlVersion);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName,
    required => 1,
);

has default => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has description => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_description',
);

has target_perl_version => (
    is        => 'ro',
    isa       => PerlVersion,
    predicate => 'has_target_perl_version',
    coerce    => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my %attrs = ( name => $self->stack );
    my $stack = $self->repo->create_stack(%attrs);

    $stack->set_properties( $stack->default_properties );

    $stack->set_property( description => $self->description )
        if $self->has_description;

    $stack->set_property( target_perl_version => $self->target_perl_version )
        if $self->has_target_perl_version;

    $stack->mark_as_default
        if $self->default;

    return $self->result->changed;
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

Pinto::Action::New - Create a new empty stack

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
