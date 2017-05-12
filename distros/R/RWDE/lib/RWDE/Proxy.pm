package RWDE::Proxy;

use strict;
use warnings;

use RWDE::AbstractFactory;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 507 $ =~ /(\d+)/;

=pod

=head1 RWDE::Proxy

Proxy object for getting the specific functionality of a particular object

=cut

=head2 invoke({ class => class_name, function => function_name, params => function_params})

To avoid require, eval and invocation from within a block of code, which is suboptimal, 
the proxy object instantiates the object, invokes the function with the given params hash and returns the result.

=cut

sub invoke {
  my ($self,$params) = @_;

  my $function = $$params{'function'} 
    or throw RWDE::DevelException({  info => 'Proxy::Parameter error - function not specified'});

  my $term = RWDE::AbstractFactory->instantiate($params);

  return $term->$function($params);
}

1;
