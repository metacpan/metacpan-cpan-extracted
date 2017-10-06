package MooseX::DIC::PackageNotFoundException;

use Moose;
use namespace::autoclean;
extends 'MooseX::DIC::ContainerException';

has package_name => ( is=>'ro', isa=>'Str', required => 1);
has '+message' => ( lazy=>1,default => sub { 
  my $self = shift;
  "Package ".($self->package_name)." was not found";
});

__PACKAGE__->meta->make_immutable;
1;

=head1 NAME

MooseX::DIC::PackageNotFoundException

=head1 DESCRIPTION

This exception is thrown when a package is being loaded and it could not be found.
