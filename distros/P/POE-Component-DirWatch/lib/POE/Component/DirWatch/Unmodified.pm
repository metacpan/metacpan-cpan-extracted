package POE::Component::DirWatch::Unmodified;

use POE;
use Moose;

our $VERSION = "0.300004";

extends 'POE::Component::DirWatch';
with 'POE::Component::DirWatch::Role::Signatures';

#--------#---------#---------#---------#---------#---------#---------#---------

around _file_callback => sub {
  my $orig = shift;
  my ($self, $kernel, $file) = @_[OBJECT, KERNEL, ARG0];
  my $sig = delete $self->signatures->{"$file"};
  return unless defined $sig && $sig->is_same;
  $orig->(@_);
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------


=head1 NAME

POE::Component::DirWatch::Unmodified

=head1 DESCRIPTION

POE::Component::DirWatch::Unmodified extends DirWatch::New to
exclude files that appear to be in use or are actively being changed. To
prevent files from being processed multiple times it is adviced that files
are moved after successful processing.

This module consumes the L<POE::Component::DirWatch::Role::Signatures> role,
please see its documentation for information about methods or attributes
it provides or extends.

=head1 METHODS

=head2 _file_callback

C<around '_file_callback'> is modified to only execute the callback if the file
has been seen previously and its signature has not changed since the last
poll. This behavior means that callbacks will not be called until the second
time they are seen.

=head2 meta

Keeping tests happy.

=head1 SEE ALSO

L<POE::Component::DirWatch>, L<Moose>

=head1 COPYRIGHT

Copyright 2006-2008 Guillermo Roditi. This is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

=cut

