package Reaction::UI::ViewPort::Field::Mutable::File;

use Reaction::Types::File qw/Upload/;
use Reaction::Class;

use namespace::clean -except => [ qw(meta) ];
extends 'Reaction::UI::ViewPort::Field';

with 'Reaction::UI::ViewPort::Field::Role::Mutable::Simple'
    => { value_type => Upload };

override apply_our_events => sub {
  my ($self, $events) = @_;
  my $value_key = $self->event_id_for('value_string');
  if (my $upload = $self->ctx->req->upload($value_key)) {
    local $events->{$value_key} = $upload;
    return super();
  } else {
    return super();
  }
};
sub adopt_value_string {
    my($self) = @_;
    $self->value($self->value_string) if $self->value_string;
};
override _value_string_from_value => sub { '' };

__PACKAGE__->meta->make_immutable;


1;
