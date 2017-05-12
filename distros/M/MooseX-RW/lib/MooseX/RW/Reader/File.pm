package MooseX::RW::Reader::File;
{
  $MooseX::RW::Reader::File::VERSION = '0.003';
}
# ABSTRACT: A Moose::Role file reader

use Moose::Role;
use Carp;

with 'MooseX::RW::Reader';



has file => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $file) = @_;
        unless ( -e $file ) {
            croak "File doesn't exist: " . $file;
        }
        $self->{file} = $file;
        open my $fh, '<',$self->file
             or croak "Impossible to open file: " . $self->file;
        $self->fh($fh);
    },
);



has fh => ( is => 'rw', );




sub percentage {
    my $self = shift;
    my (undef, undef, undef, undef, undef, undef, undef, $size) =
      $self->fh->stat;
    my $p = ($self->fh->tell * 100) / $size;
    return sprintf("%.2f", $p);
}



1;


__END__
=pod

=encoding UTF-8

=head1 NAME

MooseX::RW::Reader::File - A Moose::Role file reader

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 file

Name of the file into which read something.  A error is thrown if the file
does't exist. Setting this attribute will set L<fh> attribute.

=head2 fh

File handle form which reading.

=head1 METHODS

=head2 percentage

Returns the percentage of the file which has been read, with 2 decimals. Based
on values returned by stat() and tell() method from the file handle.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

