package Reaction::UI::ViewPort::InterfaceModel::Field::File;

use Reaction::Class;
use Reaction::Types::File;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::InterfaceModel::Field';



has '+value' => (isa => 'File', required => 0);

override apply_our_events => sub {
  my ($self, $ctx, $events) = @_;
  my $value_key = join(':', $self->location, 'value');
  if (my $upload = $ctx->req->upload($value_key)) {
    local $events->{$value_key} = $upload;
    return super();
  } else {
    return super();
  }
};

__PACKAGE__->meta->make_immutable;


1;

=head1 NAME

Reaction::UI::ViewPort::Field::File

=head1 DESCRIPTION

=head1 SEE ALSO

=head2 L<Reaction::UI::ViewPort::Field>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
