# ABSTRACT: Delete archives from the repository

package Pinto::Action::Delete;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Util qw(throw);
use Pinto::Types qw(DistSpecList);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

with qw( Pinto::Role::Transactional );

#------------------------------------------------------------------------------

has targets => (
    isa      => DistSpecList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
);

has force => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    for my $target ( $self->targets ) {

        my $dist = $self->repo->get_distribution( spec => $target );

        throw "Distribution $target is not in the repository" if not defined $dist;

        $self->notice("Deleting $dist from the repository");

        $self->repo->delete_distribution( dist => $dist, force => $self->force );
    }

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

Pinto::Action::Delete - Delete archives from the repository

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
