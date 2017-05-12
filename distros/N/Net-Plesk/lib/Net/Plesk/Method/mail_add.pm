package Net::Plesk::Method::mail_add;

use strict;

use vars qw( $VERSION @ISA $AUTOLOAD $DEBUG );

@ISA = qw( Net::Plesk::Method );
$VERSION = '0.01';

$DEBUG = 0;

=head1 NAME

Net::Plesk::Method::mail_add - Perl extension for Plesk XML Remote API mail addition

=head1 SYNOPSIS

  use Net::Plesk::Method::mail_add

  my $p = new Net::Plesk::Method::mail_add ( $domainID, $mailbox, $passwd );

  $request = $p->endcode;

=head1 DESCRIPTION

This module implements an interface to construct a request for a mailbox
addition using SWSOFT's Plesk.

=head1 METHODS

=over 4

=item init args ...

Initializes a Plesk mail_add object.  The I<domainID>, I<mailbox>,
and I<passwd> options are required.

=cut

sub init {
  my ($self, $domainid, $mailbox, $password) = @_;
  $$self = join ( "\n", (
	            '<mail>',
	            '<create>',
	            '<filter>',
	            '<domain_id>',
	            $self->encode($domainid),
	            '</domain_id>',
	            '<mailname>',
	            '<name>',
	            $self->encode($mailbox),
	            '</name>',
	            '<password>',
	            $self->encode($password),
	            '</password>',
	            '</mailname>',
	            '</filter>',
	            '</create>',
	            '</mail>',
	          ));
}

=back

=head1 BUGS

  Creepy crawlies.

=head1 SEE ALSO

SWSOFT Plesk Remote API documentation (1.4.0.0 or later)

=head1 AUTHOR

Jeff Finucane E<lt>jeff@cmh.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Jeff Finucane

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

