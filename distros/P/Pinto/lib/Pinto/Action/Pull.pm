# ABSTRACT: Pull upstream distributions into the repository

package Pinto::Action::Pull;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Try::Tiny;

use Pinto::Util qw(throw);
use Pinto::Types qw(SpecList);

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa      => SpecList,
    traits   => [qw(Array)],
    handles  => { targets => 'elements' },
    required => 1,
    coerce   => 1,
);

has no_fail => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable Pinto::Role::Puller );

#------------------------------------------------------------------------------

sub BUILD {
    my ($self) = @_;

    $self->stack->assert_not_locked;

    return $self;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my ( @successful, @failed );
    for my $target ( $self->targets ) {

        try {
            $self->repo->svp_begin;
            $self->notice( "Pulling target $target to stack " . $self->stack );
            my $dist = $self->pull( target => $target );
            push @successful, $dist ? $dist : ();
        }
        catch {
            throw $_ unless $self->no_fail;
            $self->result->failed( because => $_ );

            $self->repo->svp_rollback;

            $self->error($_);
            $self->error("Target $target failed...continuing anyway");
            push @failed, $target;
        }
        finally {
            my ($error) = @_;
            $self->repo->svp_release unless $error;
        };
    }

    $self->chrome->progress_done;

    return @successful;
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

Pinto::Action::Pull - Pull upstream distributions into the repository

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
