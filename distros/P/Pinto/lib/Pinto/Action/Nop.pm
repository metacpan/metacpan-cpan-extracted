# ABSTRACT: A no-op action

package Pinto::Action::Nop;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Int);
use MooseX::MarkAsMethods ( autoclean => 1 );

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has sleep => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    if ( my $sleep = $self->sleep ) {
        $self->notice("Process $$ sleeping for $sleep seconds");
        sleep $self->sleep;
    }

    return $self->result;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable();

#------------------------------------------------------------------------------


1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Action::Nop - A no-op action

=head1 VERSION

version 0.097

=head1 DESCRIPTION

This action does nothing.  It can be used to get Pinto to initialize
the store and load the indexes without performing any real operations
on them.

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
