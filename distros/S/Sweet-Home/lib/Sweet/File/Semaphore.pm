package Sweet::File::Semaphore;
use latest;
use Moose;

use Sweet::Types;

use MooseX::AttributeShortcuts;

use namespace::autoclean;

extends 'Sweet::File';

has linked_file => (
    is       => 'ro',
    isa      => 'Sweet::File',
    required => 1,
);

sub _build_lines { return [$$] }

sub _build_extension { 'ok' }

sub _build_dir { shift->linked_file->dir }

sub _build_name {
    my $self = shift;

    my $extension = $self->extension;
    my $linked_file = $self->linked_file;

    my $name = $linked_file->name . '.' . $extension;

    return $name;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Sweet::File::Semaphore

=head1 SYNOPSIS

    use Sweet::File::Semaphore;

    my $file = Sweet::File->new(
        dir => '/path/to/dir',
        name => 'foo.dat',
    );

    my $semaphore = Sweet::File::Semaphore->new(linked_file=>$file);
    say $semaphore; # /path/to/dir/foo.dat.ok

    $semaphore->write;

=head1 INHERITANCE

Inherits from L<Sweet::File>.

=head1 ATTRIBUTES

=head2 linked_file

Instance of L<Sweet::File>.

=head1 PRIVATE METHODS

=head2 _build_extension

Returns C<ok>.

=head2 _build_dir

Returns L</linked_file> dir.

=head2 _build_name

Returns L</linked_file> name suffixed with C<.extension>.

=head2 _build_lines

Returns one line containing PID.

=cut

