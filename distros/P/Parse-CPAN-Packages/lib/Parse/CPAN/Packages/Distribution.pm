package Parse::CPAN::Packages::Distribution;
use Moo;
use Archive::Peek;
use Path::Class 'file';
use Types::Standard qw( ArrayRef Maybe Str );

has 'prefix'     => ( is => 'rw', isa => Str );
has 'dist'       => ( is => 'rw', isa => Maybe [Str] );
has 'version'    => ( is => 'rw', isa => Maybe [Str] );
has 'maturity'   => ( is => 'rw', isa => Str );
has 'filename'   => ( is => 'rw', isa => Str );
has 'cpanid'     => ( is => 'rw', isa => Str );
has 'distvname'  => ( is => 'rw', isa => Maybe [Str] );
has 'packages'   => ( is => 'rw', isa => ArrayRef, default => sub { [] } );
has 'mirror_dir' => ( is => 'rw', isa => Maybe [Str] );

sub contains {
    my $self = shift;
    return @{ $self->packages };
}

sub add_package {
    my $self = shift;
    push @{ $self->packages }, @_;
}

sub list_files {
    my ( $self ) = @_;

    my @filenames = $self->_tarball->files;
    return @filenames;
}

sub get_file_from_tarball {
    my ( $self, $filename ) = @_;

    my $contents = $self->_tarball->file( $filename );
    return $contents;
}

sub _tarball {
    my ( $self ) = @_;

    my $file = file( $self->mirror_dir, 'authors', 'id', $self->prefix );
    my $peek = Archive::Peek->new( filename => $file );

    return $peek;
}

1;

__END__

=head1 NAME

Parse::CPAN::Packages::Distribution

=head1 DESCRIPTION

Represents a CPAN distribution. Note: The functions list_files and
get_file_from_tarball work only if a mirror directory was supplied for parsing
or the package file was situated inside a cpan mirror structure.

=head1 METHODS

=head2 contains

Returns the packages in the distribution.

=head2 add_package

Adds a package to the distribution.

=head2 list_files

Tries to list all files in the distribution.

=head2 get_file_from_tarball( $filename )

Tries to retrieve the contents of a file from the distribution.
