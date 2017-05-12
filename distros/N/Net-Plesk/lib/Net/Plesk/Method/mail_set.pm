package Net::Plesk::Method::mail_set;

use strict;

use vars qw( $VERSION @ISA $AUTOLOAD $DEBUG );

@ISA = qw( Net::Plesk::Method );
$VERSION = '0.01';

$DEBUG = 0;

=head1 NAME

Net::Plesk::Method::mail_set - Perl extension for Plesk XML Remote API mailbox setting

=head1 SYNOPSIS

  use Net::Plesk::Method::mail_set

  my $p = new Net::Plesk::Method::mail_set
    ( $domainID, $mailbox, $passwd, $enabled );

  $request = $p->endcode;

=head1 DESCRIPTION

This module implements an interface to construct a request for setting a
mailbox using SWSOFT's Plesk.

=head1 METHODS

=over 4

=item init args ...

Initializes a Plesk mail_set object.  The I<domainID>, I<mailbox>, and
I<password> options are required.

=cut

sub init {
  my ($self, $domainid, $mailbox, $password, $enabled) = @_;
  my $enabledflag = $enabled ? "true" : "false";
  $$self = join ( "\n", (
	            '<mail>',
	            '<update>',
	            '<set>',
	            '<filter>',
	            '<domain_id>',
	            $self->encode($domainid),
	            '</domain_id>',
	            '<mailname>',
	            '<name>',
	            $self->encode($mailbox),
	            '</name>',
		    '<mailbox>',
		    '<enabled>',
		    $self->encode($enabledflag),
		    '</enabled>',
		    '</mailbox>',
	            '<password>',
	            $self->encode($password),
	            '</password>',
	            '</mailname>',
	            '</filter>',
	            '</set>',
	            '</update>',
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

