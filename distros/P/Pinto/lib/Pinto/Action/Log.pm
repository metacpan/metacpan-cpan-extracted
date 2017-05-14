# ABSTRACT: Show revision log for a stack

package Pinto::Action::Log;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::RevisionWalker;
use Pinto::Constants qw(:color);
use Pinto::Types qw(StackName StackDefault);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is      => 'ro',
    isa     => StackName | StackDefault,
    default => undef,
);

has format => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_format',
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack( $self->stack );
    my $walker = Pinto::RevisionWalker->new( start => $stack->head );

    while ( my $revision = $walker->next ) {

        my $revid = $revision->to_string("revision %I");
        $self->show( $revid, { color => $PINTO_COLOR_1 } );

        my $rest = $revision->to_string("Date: %u\nUser: %j\n\n%{4}G\n");
        $self->show($rest);
    }

    return $self->result;
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

Pinto::Action::Log - Show revision log for a stack

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
