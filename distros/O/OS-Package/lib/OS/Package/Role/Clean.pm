use v5.14.0;
use warnings;

package OS::Package::Role::Clean;

# ABSTRACT: Provides the clean method.
our $VERSION = '0.2.7'; # VERSION

use Path::Tiny;
use OS::Package::Log;
use Role::Tiny;

sub clean {
    my $self = shift;

    if ( defined $self->workdir && -d $self->workdir ) {
        $LOGGER->info( sprintf 'cleaning work directory: %s',
            $self->workdir );

        path($self->workdir)->remove_tree;
    }

    if ( defined $self->fakeroot && -d $self->fakeroot ) {
        $LOGGER->info( sprintf 'cleaning fakeroot directory: %s',
            $self->fakeroot );

        path($self->fakeroot)->remove_tree;
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Role::Clean - Provides the clean method.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 clean

Provides method to clean the fakeroot directory.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
