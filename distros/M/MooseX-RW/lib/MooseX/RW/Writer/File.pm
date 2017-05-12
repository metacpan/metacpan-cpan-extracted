package MooseX::RW::Writer::File;
{
  $MooseX::RW::Writer::File::VERSION = '0.003';
}
# ABSTRACT: A role for file writer

use Moose::Role;
use Carp;

with 'MooseX::RW::Writer';



has file => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $file) = @_; 
        $self->{file} = $file;
        open my $fh, '>',$self->file
             or croak "Impossible to create file: " . $self->file;
        $self->fh($fh);
    }   
);



has fh => ( is => 'rw' );


1;


__END__
=pod

=encoding UTF-8

=head1 NAME

MooseX::RW::Writer::File - A role for file writer

=head1 VERSION

version 0.003

=head1 ATTRIBUTES

=head2 file

Name of the file into which write something. If the file already exist, it is
replaced. An error is thrown if the file can't be created. Setting this
attribute will set L<fh> attribute

=head2 fh

File handle form which writing.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

