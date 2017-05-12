use 5.006;
use strict;
use warnings;

package Net::API::RPX::Exception::Service;

# ABSTRACT: A Class of exceptions for delivering problems from the RPX service.

our $VERSION = '1.000001';

our $AUTHORITY = 'cpan:KONOBI'; # AUTHORITY

use Moose qw( has extends );
use namespace::autoclean;

extends 'Net::API::RPX::Exception';

my $rpx_errors = {
  -1 => 'Service Temporarily Unavailable',
  0  => 'Missing parameter',
  1  => 'Invalid parameter',
  2  => 'Data not found',
  3  => 'Authentication error',
  4  => 'Facebook Error',
  5  => 'Mapping exists',
};

has 'data'              => ( isa => 'Any', is => 'ro', required => 1 );
has 'status'            => ( isa => 'Any', is => 'ro', required => 1 );
has 'rpx_error'         => ( isa => 'Any', is => 'ro', required => 1 );
has 'rpx_error_code'    => ( isa => 'Any', is => 'ro', required => 1 );
has 'rpx_error_message' => ( isa => 'Any', is => 'ro', required => 1 );
has
  'rpx_error_code_description' => ( isa => 'Any', is => 'ro', required => 1, lazy => 1, ),
  , builder => '_build_rpx_error_code_description';

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;

sub _build_rpx_error_code_description {
  my ($self) = shift;
  return $rpx_errors->{ $self->rpx_error_code };
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::API::RPX::Exception::Service - A Class of exceptions for delivering problems from the RPX service.

=head1 VERSION

version 1.000001

=head1 AUTHORS

=over 4

=item *

Scott McWhirter <konobi@cpan.org>

=item *

Kent Fredric <kentnl@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Cloudtone Studios.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
