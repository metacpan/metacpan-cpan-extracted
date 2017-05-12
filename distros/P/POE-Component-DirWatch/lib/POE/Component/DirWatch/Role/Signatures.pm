package POE::Component::DirWatch::Role::Signatures;

use POE;
use Moose::Role;
use File::Signature;

our $VERSION = "0.300004";

has signatures => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
  default => sub { {} }
);

after _file_callback => sub {
  my ($self, $file) = @_[OBJECT, ARG0];
  $self->signatures->{ "$file" } ||= $self->_generate_signature($file);
};

before _poll => sub {
  my $sigs = shift->signatures;
  delete($sigs->{$_}) for grep {! -e $_ } keys %$sigs;
};

sub _generate_signature{
  my ($self, $file) = @_;
  return "" . File::Signature->new( "$file" ) . "";
}

1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------


=head1 NAME

POE::Component::DirWatch::Role::Signatures

=head1 DESCRIPTION

POE::Component::DirWatch::Role::Signatures is a role which provides
L<File::Signature> functionality to DirWatch-based classes. It will keep a
hashref of signatures of the files processing to allow you to determine if
a file has changed.

=head1 ATTRIBUTES

=head2 signatures

Read-write. Will return a hashref in which keys will be the full path of the
files seen and the value will be a stringified L<File::Signature> object.

=head1 METHODS

=head2 file_callback

C<after '_file_callback'> Add the file's signature to C<signatures> if it
doesnt yet exist.

=head2 _poll

C<before '_poll'> the list of known files is checked and if any of the files no
longer exist they are removed from the list of known files.

=head1 SEE ALSO

L<File::Signature>, L<POE::Component::DirWatch>, L<Moose>

=head1 COPYRIGHT

Copyright 2006-2008 Guillermo Roditi. This is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

=cut

