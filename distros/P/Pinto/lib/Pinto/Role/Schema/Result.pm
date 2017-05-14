# ABSTRACT: Attributes and methods for all Schema::Result objects

package Pinto::Role::Schema::Result;

use Moose::Role;
use MooseX::MarkAsMethods ( autoclean => 1 );

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

has repo => (
    is       => 'ro',
    isa      => 'Pinto::Repository',
    default  => sub { $_[0]->result_source->schema->repo },
    init_arg => undef,
    lazy     => 1,
);

#------------------------------------------------------------------------------

sub refresh {
    my ($self) = @_;

    $self->discard_changes;

    return $self;
}

#------------------------------------------------------------------------------

sub refresh_column {
    my ( $self, $column ) = @_;

    $self->mark_column_dirty($column);

    return $self->get_column($column);
}

#------------------------------------------------------------------------------

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Role::Schema::Result - Attributes and methods for all Schema::Result objects

=head1 VERSION

version 0.097

=head1 DESCRIPTION

This role adds a L<Pinto::Repository> attributes.  It should only be
applied to L<Pinto::Schema::Result> subclasses, as it will reach into
the underlying L<Pinto::Schema> object to get at the repo.

This gives us a back door for injecting additional attributes into
L<Pinto::Schema::Result> objects, since those are usually created by
L<DBIx::Class> and we don't have control over the construction
process.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
