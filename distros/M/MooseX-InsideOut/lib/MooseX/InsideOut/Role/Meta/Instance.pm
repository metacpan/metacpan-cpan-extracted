package MooseX::InsideOut::Role::Meta::Instance;
BEGIN {
  $MooseX::InsideOut::Role::Meta::Instance::VERSION = '0.106';
}

use Moose::Role;

use Hash::Util::FieldHash::Compat qw(fieldhash);
use Scalar::Util qw(refaddr weaken);
use namespace::clean -except => 'meta';

fieldhash our %attr;

around create_instance => sub {
  my $next = shift;
  my $instance = shift->$next(@_);
  $attr{refaddr $instance} = {};
  return $instance;
};

sub get_slot_value {
  my ($self, $instance, $slot_name) = @_;

  return $attr{refaddr $instance}->{$slot_name};
}

sub set_slot_value {
  my ($self, $instance, $slot_name, $value) = @_;

  return $attr{refaddr $instance}->{$slot_name} = $value;
}

sub deinitialize_slot {
  my ($self, $instance, $slot_name) = @_;
  return delete $attr{refaddr $instance}->{$slot_name};
}

sub deinitialize_all_slots {
  my ($self, $instance) = @_;
  $attr{refaddr $instance} = {};
}

sub is_slot_initialized {
  my ($self, $instance, $slot_name) = @_;

  return exists $attr{refaddr $instance}->{$slot_name};
}

sub weaken_slot_value {
  my ($self, $instance, $slot_name) = @_;
  weaken $attr{refaddr $instance}->{$slot_name};
}

around inline_create_instance => sub {
  my $next = shift;
  my ($self, $class_variable) = @_;
  my $code = $self->$next($class_variable);
  $code = "do { my \$instance = ($code);";
  $code .= sprintf(
    '$%s::attr{Scalar::Util::refaddr($instance)} = {};',
    __PACKAGE__,
  );
  $code .= '$instance }';
  return $code;
};

sub inline_slot_access {
  my ($self, $instance, $slot_name) = @_;
  return sprintf '$%s::attr{Scalar::Util::refaddr(%s)}->{%s}',
    __PACKAGE__, $instance, $slot_name;
}

1;



=pod

=head1 NAME

MooseX::InsideOut::Role::Meta::Instance

=head1 VERSION

version 0.106

=head1 DESCRIPTION

Meta-instance role implementing inside-out storage.

=head1 METHODS

=head2 create_instance

=head2 get_slot_value

=head2 set_slot_value

=head2 deinitialize_slot

=head2 deinitialize_all_slots

=head2 is_slot_initialized

=head2 weaken_slot_value

=head2 inline_create_instance

=head2 inline_slot_access

See L<Class::MOP::Instance>.

=head1 AUTHOR

Hans Dieter Pearcey <hdp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Hans Dieter Pearcey <hdp@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

