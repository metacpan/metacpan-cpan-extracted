package MooseX::Types::CIDR;
{
  $MooseX::Types::CIDR::VERSION = '1.000000';
}
use strict;
use warnings;

our $AUTHORITY = 'CPAN:TBR';

use MooseX::Types -declare => ['CIDR'];
use MooseX::Types::Moose qw(Str);
use Net::CIDR;

sub _validate_cidr {
    my ($str) = @_;
    return Net::CIDR::cidrvalidate($str);
}

subtype CIDR,
  as Str, 
  where { _validate_cidr($_) },
  message { 'CIDR is invalid' };

1;

__END__

=head1 NAME

MooseX::Types::CIDR - CIDR type for Moose classes

=head1 SYNOPSIS

  package Class;
  use Moose;
  use MooseX::Types::CIDR qw(CIDR);
  
  has 'cidr' => ( is => 'ro', isa => CIDR );

  package main;
  Class->new( cidr => '192.168.1.1/32' );

=head1 DESCRIPTION

This module lets you constrain attributes to only contain CIDR.
No coercion is attempted.

=head1 EXPORT

None by default, you'll usually want to request C<Net::CIDR> explicitly.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Types::CIDR

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MooseX-Types-CIDR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Types-CIDR>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MooseX-Types-CIDR>

=item * Search CPAN

L<http://search.cpan.org/dist/MooseX-Types-CIDR>

=back

