use v5.14.0;
use warnings;

package OS::Package::Artifact;

# ABSTRACT: OS::Package::Artifact object.
our $VERSION = '0.2.7'; # VERSION

use Moo;
use Types::Standard qw( Str InstanceOf );
use Path::Tiny;

with qw(
    OS::Package::Artifact::Role::Download
    OS::Package::Artifact::Role::Extract
    OS::Package::Artifact::Role::Validate
);

my @string_methods = qw( distfile savefile url md5 sha1 );

has [@string_methods] => ( is => 'rw', isa => Str );

has repository => ( is => 'rw', isa => InstanceOf ['Path::Tiny'] );

has archive => ( is => 'rw', isa => InstanceOf ['Archive::Extract'] );

has workdir => (
    is       => 'rw',
    isa      => InstanceOf ['Path::Tiny'],
    required => 1,
    default  => sub { return Path::Tiny->tempdir }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OS::Package::Artifact - OS::Package::Artifact object.

=head1 VERSION

version 0.2.7

=head1 METHODS

=head2 url

The URL to download the application.

=head2 distfile

The name of the distribution file.

=head2 savefile

The location of the distribution file on local filesystem.

=head2 repository

Base directory to store artifacts.

=head2 archive

The Archive::Extract object of the extracted distfile.

=head2 workdir

Temporary directory to extract and stage artifact.

=head1 AUTHOR

James F Wilkus <jfwilkus@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by James F Wilkus.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
