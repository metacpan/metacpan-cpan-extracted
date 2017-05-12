package RWDE::AbstractFactory;

use strict;
use warnings;

use Error qw(:try);
use RWDE::Exceptions;

use vars qw($VERSION);
$VERSION = sprintf "%d", q$Revision: 506 $ =~ /(\d+)/;

=pod

=head1 RWDE::AbstractFactory

Abstract Factory, instantiates and returns any App object

=cut

=head2 instantiate

Instantiate an instance of the class specified in the parameter

Requires class parameter

=cut

sub instantiate {
  my ($self, $params) = @_;

  throw RWDE::DevelException({ info => 'AbstractFactory::Parameter error - class not specified' }) unless ($$params{'class'});

  my $proto = $$params{class};

  my $requested_type = ref $proto || $proto;

  delete $$params{class};

  my $library = $requested_type . '.pm';

  $library =~ s/::/\//g;

  require $library;

  return $requested_type->new($params);
}

1;
