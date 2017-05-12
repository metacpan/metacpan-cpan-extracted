package MooseX::Types::CNPJ;
use strict;
use warnings;

our $VERSION = '0.02';
our $AUTHORITY = 'CPAN:TBR';

use MooseX::Types -declare => ['CNPJ'];
use MooseX::Types::Moose qw(Str);
use Business::BR::CNPJ;

sub _validate_cnpj {
    my ($str) = @_;
    return test_cnpj($str);
}

subtype CNPJ,
  as Str, 
  where { _validate_cnpj($_) },
  message { 'CNPJ is invalid' };


1;

__END__

=head1 NAME

MooseX::Types::CNPJ - CNPJ type for Moose classes

=head1 SYNOPSIS

  package Class;
  use Moose;
  use MooseX::Types::CNPJ qw(CNPJ);
  
  has 'cnpj' => ( is => 'ro', isa => CNPJ );

  package main;
  Class->new( cnpj => '00.000.000/0000-00' );

=head1 DESCRIPTION

This module lets you constrain attributes to only contain CNPJ.
No coercion is attempted.

=head1 EXPORT

None by default, you'll usually want to request C<CNPJ> explicitly.

=head1 AUTHOR

Thiago Rondon C<< <thiago@aware.com.br> >>

Aware TI (L<http://www.aware.com.br/>)

=head1 COPYRIGHT

This program is Free software, you may redistribute it under the same
terms as Perl itself.
