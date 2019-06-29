package Telegram::Bot::Object::Base;
$Telegram::Bot::Object::Base::VERSION = '0.012';
# ABSTRACT: The base class for all Telegram::Bot::Object objects

use Mojo::Base -base;

sub send_method {
  my $self  = shift;
  my $class = ref($self);
  $class =~ s/Telegram::Bot::Object:://;
  return $class;
}

sub as_hashref {
  my $self = shift;
  my $hash = {};
  # add the simple scalar values
  foreach my $field ( @{ $self->fields->{scalar} } ) {
    $hash->{$field} = $self->$field;
  }
  return $hash;
}

sub is_array { 0 }

sub create_from_hash {
  my $class = shift;
  my $hash  = shift;
  my $msg   = $class->new;

  # warn " working on fields of type '$k'\n";
  if ($class->fields->{scalar}) {
    foreach my $field (@{ $class->fields->{scalar} } ) {
      # warn "  field: $field\n";
      $msg->$field($hash->{$field});
    }
  }
  if ($class->fields->{object}) {
    foreach my $o_to_create ( @{ $class->fields->{object} } ) {
      my ($o_field, $o_type) = %$o_to_create;
      eval "require $o_type;";
      $msg->$o_field($o_type->create_from_hash($hash->{$o_field}));
    }
  }
  if ($class->fields->{array}) {
    foreach my $o_to_create ( @{ $class->fields->{array} } ) {
      my ($o_field, $o_type) = %$o_to_create;
      eval "require $o_type;";
      foreach my $elem (@{ $hash->{$o_field} }) {
        push @{ $msg->$o_field }, $o_type->create_from_hash($hash->{$o_field});
      }
    }
  }
  return $msg;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Telegram::Bot::Object::Base - The base class for all Telegram::Bot::Object objects

=head1 VERSION

version 0.012

=head1 AUTHOR

Justin Hawkins <justin@eatmorecode.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Justin Hawkins.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
