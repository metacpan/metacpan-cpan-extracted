package POE::Component::DirWatch::Modified;

use POE;
use Moose;

our $VERSION = "0.300004";

extends 'POE::Component::DirWatch';
with 'POE::Component::DirWatch::Role::Signatures';

#--------#---------#---------#---------#---------#---------#---------#---------

around '_file_callback' => sub {
  my $orig = shift;
  my ($self, $file) = @_[OBJECT, ARG0];
  my $sigs = $self->signatures;
  my $new_sig = $self->_generate_signature($file);
  return if exists $sigs->{"$file"} && $sigs->{"$file"} eq $new_sig;
  $sigs->{"$file"} = $new_sig;
  return $orig->(@_);
};

__PACKAGE__->meta->make_immutable;

1;

__END__;

#--------#---------#---------#---------#---------#---------#---------#---------


=head1 NAME

POE::Component::DirWatch::Modified

=head1 DESCRIPTION

POE::Component::DirWatch::Modified extends DirWatch::New in order to exclude
files that have already been seen, but still pick up files that have been
changed. Usage is identical to L<POE::Component::DirWatch>.

This module consumes the L<POE::Component::DirWatch::Role::Signatures> role,
please see its documentation for information about methods or attributes
it provides or extends.

=head1 METHODS

=head2 _file_callback

C<override '_file_callback'>  Don't call the callback if file has been seen
before and is unchanged.

=head2 meta

See L<Moose>

=head1 SEE ALSO

L<POE::Component::DirWatch::New>, L<POE::Component::DirWatch>

=head1 COPYRIGHT

Copyright 2006-2008 Guillermo Roditi. This is free software; you may
redistribute it and/or modify it under the same terms as Perl itself.

=cut

