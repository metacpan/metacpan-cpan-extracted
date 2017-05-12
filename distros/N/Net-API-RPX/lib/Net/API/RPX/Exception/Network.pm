use 5.006;
use strict;
use warnings;

package Net::API::RPX::Exception::Network;

# ABSTRACT: A Class of exceptions for network connectivity issues.

our $VERSION = '1.000001';

our $AUTHORITY = 'cpan:KONOBI'; # AUTHORITY

use Moose qw( has extends );
use namespace::autoclean;

extends 'Net::API::RPX::Exception';

has 'ua_result'   => ( isa => 'Ref', is => 'ro', required => 1 );
has 'status_line' => ( isa => 'Str', is => 'ro', required => 1 );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::API::RPX::Exception::Network - A Class of exceptions for network connectivity issues.

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
