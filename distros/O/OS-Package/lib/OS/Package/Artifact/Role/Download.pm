use v5.14.0;
use warnings;

package OS::Package::Artifact::Role::Download;

use FileHandle;
use HTTP::Tiny;
use OS::Package::Log;
use Path::Tiny;
use Role::Tiny;

# ABSTRACT: Provides the download method for Artifact role.
our $VERSION = '0.2.7'; # VERSION

sub download {

    my $self = shift;

    if ( !$self->url ) {
        $LOGGER->debug('did not define url');
        return 1;
    }

    if ( path( $self->savefile )->exists ) {

        $LOGGER->info( sprintf 'distfile exists: %s', $self->savefile );

        if ( $self->validate ) {
            return 1;
        }
        else {
            $LOGGER->warn( sprintf 'removing bad distfile: %s',
                $self->savefile );
            path( $self->savefile )->remove;
        }
    }

    $LOGGER->info( sprintf 'downloading: %s', $self->distfile );
    $LOGGER->debug( sprintf 'saving to: %s', $self->savefile );

    my $response = HTTP::Tiny->new->get( $self->url );

    my $save_file = path( $self->savefile )->realpath;

    $save_file->spew( $response->{content} );

    if ( !$self->validate ) {
        $LOGGER->logcroak( sprintf 'cannot download: %s', $self->url );
    }

    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Artifact::Role::Download - Provides the download method for Artifact role.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 download

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
