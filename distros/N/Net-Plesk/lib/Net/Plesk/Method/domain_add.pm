package Net::Plesk::Method::domain_add;

use strict;

use vars qw( $VERSION @ISA $AUTOLOAD $DEBUG );

@ISA = qw( Net::Plesk::Method );
$VERSION = '0.02';

$DEBUG = 0;

=head1 NAME

Net::Plesk::Method::domain_add - Perl extension for Plesk XML Remote API domain addition

=head1 SYNOPSIS

  use Net::Plesk::Method::domain_add

  my $p = new Net::Plesk::Method::domain_add ( $clientID, 'domain.com' );

  $request = $p->endcode;

=head1 DESCRIPTION

This module implements an interface to construct a request for a domain
addition using SWSOFT's Plesk.

=head1 METHODS

=over 4

=item init args ...

Initializes a Plesk domain_add object.  The I<domain>, I<client>, and
$<ip_address> options are required.

=cut

sub init {
  my ($self, $domain, $client, $ip, $template, $user, $pass) = @_;
  my $xml = join ( "\n", (
	            '<domain>',
	            '<add>',
	            '<gen_setup>',
	            '<name>',
	            $self->encode($domain),
	            '</name>',
	            '<client_id>',
	            $self->encode($client),
	            '</client_id>',
                 ));
  $xml .= '<htype>vrt_hst</htype>' if defined($user);
  $xml .= join ( "\n", ( '<ip_address>',
	          $self->encode($ip),
	          '</ip_address>',
	          '</gen_setup>',
               ));
  if (defined($user)) {
    $xml .= "<hosting><vrt_hst><ftp_login>" . $self->encode($user);
    $xml .= "</ftp_login><ftp_password>" . $self->encode($pass);
    $xml .= "</ftp_password><ip_address>" . $self->encode($ip);
    $xml .= "</ip_address></vrt_hst></hosting>";
  }
  if ($template) {
    $xml .= "<template-name>" . $self->encode($template) . "</template-name>";
  }
  $xml .= '</add></domain>';

  $$self = $xml;
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

