package Parse::FieldPath::Role;
{
  $Parse::FieldPath::Role::VERSION = '0.005';
}

use Moose::Role;
use Parse::FieldPath;

sub all_fields {
    my ($self) = @_;
    return [ grep { defined }
          map { $_->accessor || $_->reader } $self->meta->get_all_attributes ];
}

sub extract_fields {
    return Parse::FieldPath::extract_fields(@_);
}

1;

=pod

=head1 NAME

Parse::FieldPath::Role

=head1 ABSTRACT

Moose role to provide an C<extract_fields> method.

=head1 SYNOPSIS

  package Boris;

  use Moose;
  with 'Parse::FieldPath::Role';

  has plan => ( is => 'rw' );
  has tnt => ( is => 'rw' );

  # Meanwhile..
  my $boris = Boris->new(plan => 'a very evil plan', tnt => 'lots');
  $boris->extract_fields(""); # returns: {
                                           plan => 'a very evil plan',
                                           tnt => 'lots',
                                         }

=head1 PROVIDED METHODS

=over 4

=item B<all_fields()>

Called by C<extract_fields()> to get a list of every available field for the
object. This implementation return the name of every attribute reader method.

=item B<extract_fields($field_path)>

Calls C<extract_fields> from L<Parse::FieldPath> on the object.

=back

=cut
