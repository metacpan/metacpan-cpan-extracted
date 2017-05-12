package Net::LDAPxs::Exception;

use 5.006;
use strict;
use vars qw($VERSION);

$VERSION = '1.01';


sub err {
	return 1 if shift->{code} != 0;
}

sub errstr { 
	my $self = shift;

	"Error code($self->{code}): $self->{mesg}";
}

sub code {
	shift->{code};
}

1;

__END__

=head1 NAME

Net::LDAPxs::Exception - Object handling the exceptions

=head1 SYNOPSIS

  use Net::LDAPxs;
  
  $mesg = $ldap->search( $dn, password => "secret" );
  die $mesg->errstr if $mesg->err;
  
=head1 DESCRIPTION

When exception happens, a B<Net::LDAPxs::Exception> object is returned 
from the methods of a L<Net::LDAPxs> object. It is used for displaying 
both error codes and error messages sent from LDAP server.

=head1 METHODS

=over 4

=item code

This method is for detecting whether there is an exception.

=item errstr

Method C<errstr> is in charge of displaying the error messages sent 
from the LDAP server.

=back

=head1 AUTHOR

Pan Yu <xiaocong@vip.163.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Pan Yu. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
