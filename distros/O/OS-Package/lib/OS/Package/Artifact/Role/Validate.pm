use v5.14.0;
use warnings;

package OS::Package::Artifact::Role::Validate;

# ABSTRACT: Provides the validation methods for Artifact role.
our $VERSION = '0.2.7'; # VERSION

use Digest::MD5;
use Digest::SHA;
use OS::Package::Log;
use Path::Tiny;
use Role::Tiny;

sub validate {
    my $self = shift;

    if ( defined $self->md5 ) {
        if ( !$self->validate_md5 ) {
            return 0;
        }
    }

    if ( defined $self->sha1 ) {
        if ( !$self->validate_sha1 ) {
            return 0;
        }
    }

    return 1;
}

sub validate_md5 {
    my $self = shift;

    my $md5 = Digest::MD5->new();
    my $fh  = path( $self->savefile )->openr;

    $md5->addfile($fh)
        or
        $LOGGER->logcroak( sprintf 'cannot open file %s', $self->savefile );

    if ( $md5->hexdigest eq $self->md5 ) {
        $LOGGER->info( sprintf 'md5 checksum ok: %s', $self->distfile );
        return 1;
    }

    $LOGGER->fatal( sprintf 'md5 checksum bad: %s', $self->distfile );
    return 0;
}

sub validate_sha1 {
    my $self = shift;

    my $sha = Digest::SHA->new;

    $sha->addfile( $self->savefile );

    if ( $sha->hexdigest eq $self->sha1 ) {
        $LOGGER->info( sprintf 'sha1 checksum ok: %s', $self->distfile );
        return 1;
    }

    $LOGGER->fatal( sprintf 'sha1 checksum bad: %s', $self->distfile );
    return 0;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Artifact::Role::Validate - Provides the validation methods for Artifact role.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 validate

Provides the validate method which is a wrapper for validate_md5 and validate_sha1.

=head2 validate_md5

Validates the MD5 hash of the downloaded save file to the application configuration
file.

=head2 validate_sha1

Validates the SHA1 hash of the downloaded save file to the application configuration
file.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
