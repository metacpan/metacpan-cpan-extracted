package RWDE::CCRproxy;

use strict;
use warnings;
use base qw(RWDE::Proxy);

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::CCRproxy

Proxy object for getting the specific functionality of a particular object

=cut

=head2 decode({ type=> object_type, enc =>object_enc})

To avoid require and instantiation the proxy object returns the decoded value of the passed encoded id.

=cut

sub decode {
  my ($self,$params) = @_;

  return $self->invoke({class => $$params{'type'}, function => 'decode', params => $$params{'enc'}});
}

=head2 ccr_to_id({ type=> object_type, ccr =>object_ccr})

To avoid require and instantiation the proxy object returns the id value from the passed ccr.

=cut

sub ccr_to_id {
  my ($self,$params) = @_;

  return $self->invoke({class => $$params{'type'}, function => 'ccr_to_id', params => $$params{'ccr'} });
}

=head2 invoke({ class => class_name, function => function_name, params => function_params})

override base method "invoke" from Proxy.pm

=cut

sub invoke {
  my ($self,$params) = @_;

  my $function = $$params{'function'} 
    or throw RWDE::DevelException({  info => 'Proxy::Parameter error - function not specified'});

  my $term = RWDE::AbstractFactory->instantiate({class => $$params{'class'}});

  return $term->$function($$params{'params'});
}

1;
