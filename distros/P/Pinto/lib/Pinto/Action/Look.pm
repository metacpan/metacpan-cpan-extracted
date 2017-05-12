# ABSTRACT: Unpack and open a distribution with your shell

package Pinto::Action::Look;

use Moose;
use MooseX::StrictConstructor;
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::Shell;
use Pinto::Util qw(throw);
use Pinto::Types qw(StackName StackDefault TargetList);

use Path::Class qw(file);

#------------------------------------------------------------------------------

our $VERSION = '0.12'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has stack => (
    is       => 'ro',
    isa      => StackName | StackDefault,
    default  => undef,
);

has targets => (
    isa      => TargetList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
);

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my $stack = $self->repo->get_stack($self->stack);

    for my $target ( $self->targets ) {

        my $dist;
        if ($target->isa('Pinto::Target::Package')) {
            $dist = $stack->get_distribution( target => $target )
                or throw "Target $target is not in stack $stack";
        }
        else {
            $dist = $self->repo->get_distribution( target => $target )
                or throw "Target $target is not in the repository";
        }

        my $shell = Pinto::Shell->new( archive => $dist->native_path );
        $self->diag("Entering $dist with $shell\n");
        $shell->spawn;
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

Pinto::Action::Look - Unpack and open a distribution with your shell

=head1 VERSION

version 0.12

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
