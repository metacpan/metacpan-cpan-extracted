package POE::Component::DirWatch::New;

use POE;
use Moose;

our $VERSION = "0.300004";

extends 'POE::Component::DirWatch';
with 'POE::Component::DirWatch::Role::Signatures';

#--------#---------#---------#---------#---------#---------#---------#---------

around _file_callback => sub {
  my $orig = shift;
  my ($self, $file) = @_[OBJECT, ARG0];
  return if exists $self->signatures->{"$file"};
  $orig->(@_);
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------

=head1 NAME

POE::Component::DirWatch::New

=head1 DESCRIPTION

DirWatch::New extends DirWatch to exclude previously seen files.

This module consumes the L<POE::Component::DirWatch::Role::Signatures> role,
please see its documentation for information about methods or attributes
it provides or extends.

=head1 METHODS

=head2 file_callback

C<around '_file_callback'>  Don't call the callback if file has been seen.

=head2 meta

Keeping tests happy.

=head1 SEE ALSO

L<POE::Component::DirWatch>, L<Moose>

=head1 COPYRIGHT

Copyright 2006-2008 Guillermo Roditi. This is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

=cut

