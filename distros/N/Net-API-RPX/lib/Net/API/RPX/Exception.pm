use 5.006;
use strict;
use warnings;

package Net::API::RPX::Exception;

# ABSTRACT: A Base class for Net::API::RPX exceptions.

our $VERSION = '1.000001';

our $AUTHORITY = 'cpan:KONOBI'; # AUTHORITY

use Moose qw( extends with );

extends 'Throwable::Error';

with qw( Throwable::X );

__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::API::RPX::Exception - A Base class for Net::API::RPX exceptions.

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
