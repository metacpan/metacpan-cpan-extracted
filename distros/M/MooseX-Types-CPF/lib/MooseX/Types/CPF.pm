package MooseX::Types::CPF;
use strict;
use warnings;

our $VERSION = '0.02';
our $AUTHORITY = 'CPAN:TBR';

use MooseX::Types -declare => ['CPF'];
use MooseX::Types::Moose qw(Str);
use Business::BR::CPF;

sub _validate_cpf {
    my ($str) = @_;
    return test_cpf($str);
}

subtype CPF,
  as Str, 
  where { _validate_cpf($_) },
  message { 'CPF is invalid' };

1;

__END__

=head1 NAME

MooseX::Types::CPF - CPF type for Moose classes

=head1 SYNOPSIS

  package Class;
  use Moose;
  use MooseX::Types::CPF qw(CPF);
  
  has 'cpf' => ( is => 'ro', isa => CPF );

  package main;
  Class->new( cpf => '000.000.000-00' );

=head1 DESCRIPTION

This module lets you constrain attributes to only contain CPF.
No coercion is attempted.

=head1 EXPORT

None by default, you'll usually want to request C<CPF> explicitly.

=head1 AUTHOR

Thiago Rondon C<< <thiago@aware.com.br> >>

Aware TI (L<http://www.aware.com.br/>)

=head1 COPYRIGHT

This program is Free software, you may redistribute it under the same
terms as Perl itself.
