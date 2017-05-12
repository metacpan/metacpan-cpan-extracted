package SPOPS::Exception::LDAP;

# $Id: LDAP.pm,v 3.2 2004/06/02 00:48:22 lachoy Exp $

use strict;
use base qw( SPOPS::Exception );

$SPOPS::Exception::LDAP::VERSION   = sprintf("%d.%02d", q$Revision: 3.2 $ =~ /(\d+)\.(\d+)/);
@SPOPS::Exception::LDAP::EXPORT_OK = qw( spops_ldap_error );

my @FIELDS = qw( code action filter error_text error_name );
SPOPS::Exception::LDAP->mk_accessors( @FIELDS );

sub get_fields {
    return ( $_[0]->SUPER::get_fields, @FIELDS );
}

sub spops_ldap_error {
    goto &SPOPS::Exception::throw( 'SPOPS::Exception::LDAP', @_ );
}

1;

__END__

=pod

=head1 NAME

SPOPS::Exception::LDAP - SPOPS exception with extra LDAP parameters

=head1 SYNOPSIS

 my $iterator = eval { My::LDAPUser->fetch_iterator };
 if ( $@ and $@->isa( 'SPOPS::Exception::LDAP' ) ) {
     print "Failed LDAP execution with: $@\n",
           "Action: ", $@->action, "\n",
           "Code: ", $@->code, "\n",
           "Error Name: ", $@->error_name, "\n",
           "Error Text: ", $@->error_text, "\n",
 }

=head1 DESCRIPTION

Same as L<SPOPS::Exception|SPOPS::Exception> but we add four new
properties:

B<code> ($)

The LDAP code returned by the server.

B<action> ($)

The LDAP action we were trying to execute when the error occurred.

B<error_name> ($)

Name of the error corresponding to C<code> as returned by
L<Net::LDAP::Util|Net::LDAP::Util>.

B<error_text> ($)

Text of the error corresponding to C<code> as returned by
L<Net::LDAP::Util|Net::LDAP::Util>. This is frequently the same as the
error message, but not necessarily.

=head1 METHODS

No extra methods, but you can use a shortcut if you are throwing
errors:

 use SPOPS::Exception::LDAP qw( spops_ldap_error );

 ...
 spops_ldap_error "I found an LDAP error with code ", $ldap->code, "...";

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Exception|SPOPS::Exception>

L<Net::LDAP|Net::LDAP>

L<Net::LDAP::Util|Net::LDAP::Util>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

=cut
