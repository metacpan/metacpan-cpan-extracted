# ABSTRACT: Install packages from the repository

package Pinto::Action::Install;

use Moose;
use MooseX::StrictConstructor;
use MooseX::Types::Moose qw(Bool ArrayRef Str);
use MooseX::MarkAsMethods ( autoclean => 1 );

use Pinto::SpecFactory;

#------------------------------------------------------------------------------

our $VERSION = '0.097'; # VERSION

#------------------------------------------------------------------------------

extends qw( Pinto::Action );

#------------------------------------------------------------------------------

has targets => (
    isa => ArrayRef [Str],
    traits   => ['Array'],
    handles  => { targets => 'elements' },
    required => 1,
);

has do_pull => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

has mirror_url => (
    is      => 'ro',
    isa     => Str,
    builder => '_build_mirror_url',
    lazy    => 1,
);

#------------------------------------------------------------------------------

with qw( Pinto::Role::Committable Pinto::Role::Puller Pinto::Role::Installer);

#------------------------------------------------------------------------------

sub _build_mirror_url {
    my ($self) = @_;

    my $stack      = $self->stack;
    my $stack_dir  = defined $stack ? "/stacks/$stack" : '';
    my $mirror_url = 'file://' . $self->repo->root->absolute . $stack_dir;

    return $mirror_url;
}

#------------------------------------------------------------------------------

sub execute {
    my ($self) = @_;

    my @dists;
    if ( $self->do_pull ) {

        for my $target ( $self->targets ) {
            next if -d $target or -f $target;

            require Pinto::SpecFactory;
            $target = Pinto::SpecFactory->make_spec($target);

            my $dist = $self->pull( target => $target );
            push @dists, $dist ? $dist : ();
        }
    }

    return @dists;
}

#------------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

#-----------------------------------------------------------------------------
1;

__END__

=pod

=encoding UTF-8

=for :stopwords Jeffrey Ryan Thalhammer

=head1 NAME

Pinto::Action::Install - Install packages from the repository

=head1 VERSION

version 0.097

=head1 AUTHOR

Jeffrey Ryan Thalhammer <jeff@stratopan.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jeffrey Ryan Thalhammer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
