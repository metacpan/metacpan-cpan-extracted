package Net::Plesk::Method::client_add;

use strict;

use vars qw( $VERSION @ISA $AUTOLOAD $DEBUG );

@ISA = qw ( Net::Plesk::Method );
$VERSION = '0.01';

$DEBUG = 0;

=head1 NAME

Net::Plesk::Method::client_add - Perl extension for Plesk XML Remote API client addition

=head1 SYNOPSIS

  use Net::Plesk::Method::client_add

  my $p = new Net::Plesk::client_add ( $clientID, 'client.com' );

=head1 DESCRIPTION

This module implements an interface to construct a request for a client
addition using SWSOFT's Plesk.

=head1 METHODS

=over 4

=item init args ...

Initializes a Plesk client_add object.  The I<login> and I<password>
options are required.

=cut

sub init {
  my ($self, $pname, $login, $passwd, $phone, $fax, $email, $address, $city,
      $state, $pcode, $country) = @_;
  $$self = join ( "\n", (
	            '<client>',
	            '<add>',
	            '<gen_info>',
	            '<pname>',
	            $self->encode($pname),
	            '</pname>',
	            '<login>',
	            $self->encode($login),
	            '</login>',
	            '<passwd>',
	            $self->encode($passwd),
	            '</passwd>',
	            '<phone>',
	            $self->encode($phone),
	            '</phone>',
	            '<fax>',
	            $self->encode($fax),
	            '</fax>',
	            '<email>',
	            $self->encode($email),
	            '</email>',
	            '<address>',
	            $self->encode($address),
	            '</address>',
	            '<city>',
	            $self->encode($city),
	            '</city>',
	            '<state>',
		    $self->encode($state),
	            '</state>',
	            '<pcode>',
		    $self->encode($pcode),
	            '</pcode>',
	            '<country>',
		    $self->encode($country),
	            '</country>',
	            '</gen_info>',
	            '</add>',
	            '</client>',
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

