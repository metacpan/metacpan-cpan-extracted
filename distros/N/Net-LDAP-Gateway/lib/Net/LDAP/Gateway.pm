package Net::LDAP::Gateway;

our $VERSION = '0.03';

use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( ldap_peek_message

		  ldap_shift_message

		  ldap_pack_bind_request
		  ldap_pack_bind_response
		  ldap_pack_unbind_request
		  ldap_pack_search_request
		  ldap_pack_search_entry_response
		  ldap_pack_search_reference_response
		  ldap_pack_search_done_response
		  ldap_pack_modify_request
		  ldap_pack_modify_response
		  ldap_pack_add_request
		  ldap_pack_add_response
		  ldap_pack_delete_request
		  ldap_pack_delete_response
		  ldap_pack_modify_dn_request
		  ldap_pack_modify_dn_response
		  ldap_pack_compare_request
		  ldap_pack_compare_response
		  ldap_pack_abandon_request
		  ldap_pack_extended_request
		  ldap_pack_extended_response
		  ldap_pack_intermediate_response

		  ldap_pack_message_ref
		  ldap_pack_bind_request_ref
		  ldap_pack_bind_response_ref
		  ldap_pack_unbind_request_ref
		  ldap_pack_search_request_ref
		  ldap_pack_search_entry_response_ref
		  ldap_pack_search_reference_response_ref
		  ldap_pack_search_done_response_ref
		  ldap_pack_modify_request_ref
		  ldap_pack_modify_response_ref
		  ldap_pack_add_request_ref
		  ldap_pack_add_response_ref
		  ldap_pack_delete_request_ref
		  ldap_pack_delete_response_ref
		  ldap_pack_modify_dn_request_ref
		  ldap_pack_modify_dn_response_ref
		  ldap_pack_compare_request_ref
		  ldap_pack_compare_response_ref
		  ldap_pack_abandon_request_ref
		  ldap_pack_extended_request_ref
		  ldap_pack_extended_response_ref
		  ldap_pack_intermediate_response_ref

		  ldap_dn_normalize
	       );

require XSLoader;
XSLoader::load('Net::LDAP::Gateway', $VERSION);


1;
__END__

=head1 NAME

Net::LDAP::Gateway - Infrastructure to build LDAP gateways

=head1 SYNOPSIS

  use Net::LDAP::Gateway;

=head1 DESCRIPTION

This module provides a set of low level functions to encode and decode
LDAP packets

=head2 EXPORT

The following functions can be imported from this module:

=over

=item $normalized = ldap_dn_normalize($dn)

returns a normalized version of the given dn.

=item $len = ldap_peek_message($buffer)

=item ($len, $msgid, $op, $more) = ldap_peek_message($buffer)

If enough data is available in buffer, this function returns the size
of the incomming packet. Otherwise it returns undef.

When called in list context, besides the packet len, if enough data is
available from the buffer, this function also returns the message ID,
the LDAP operation code and depending on the packet type, the dn or
the error code.

=item ($msgid, $op, $data) = ldap_shift_message($buffer)

Extracts and parses the next LDAP message available from $buffer.

C<$msgid> is the message id.

C<$op> is the number associated to the requested operation as defined
by the LDAP specification (symbolic names for those constants can be
imported from L<Net::LDAP::Gateway::Constant>).

C<$data> is a hash representing all the data available on the
packet as follows:

=over

=item LDAP_OP_BIND_REQUEST [0]

  $data = { version  => $protocol_version,
            dn       => $bind_dn,
            method   => $auth_method,
            %method_data
  }

=over

=item $auth_method == LDAP_AUTH_SIMPLE

  %method_data  =(password => $password)

=back

other authentication methods are currently not supported

=item LDAP_OP_UNBIND_REQUEST [2]

The unbind request does not carry any extra data:

  $data = {}

=item LDAP_OP_SEARCH_REQUEST [3]

  $data = { base_dn       => $base_dn,
            scope         => $scope,
            deref_aliases => $deref,
            size_limit    => $sl,      # optional
            time_limit    => $tl,      # optional
            types_only    => 1,        # optional
            filter        => \@filter
            attributes    => \@attr,   # optional
  }

C<$scope> can take the values C<LDAP_SCOPE_BASE_OBJECT> [0],
C<LDAP_SCOPE_SINGLE_LEVEL> [1] or C<LDAP_SCOPE_WHOLE_SUBTREE> [2].

C<$deref> can take the values C<LDAP_DEREF_ALIASES_NEVER> [0],
C<LDAP_DEREF_ALIASES_IN_SEARCHING> [1],
C<LDAP_DEREF_ALIASES_FINDING_BASE_OBJ> [2] or
C<LDAP_DEREF_ALIASES_ALWAYS> [3]

=item LDAP_OP_MODIFY_REQUEST [6]

  $data = { dn      => $dn,
            add     => $add,
            changes => \@changes
  }

  @changes = ( { operation => $op,
                 attribute => $attribute,
                 values    => \@values },
                 ...
             )

C<$op> can take the values C<LDAP_MODOP_REPLACE>, C<LDAP_MODOP_ADD> or
C<LDAP_MODOP_DELETE>.

=item LDAP_OP_ADD_REQUEST [8]

  $data = { dn     => $dn,
            $attr1 => \@values1,
            $attr2 => \@values2,
            ...
  }

=item LDAP_OP_DELETE_REQUEST [10]

  $data = { dn => $dn }

=item LDAP_OP_MODIFY_DN_REQUEST [12]

  $data = { dn             => $dn,
            new_rdn        => $new_rdn,
            delete_old_rdn => 1,          # optional
            new_superior   => $superior,  # optional

=item LDAP_OP_COMPARE_REQUEST [14]

  $data = { dn        => $dn,
            attribute => $attr,
            value     => $value }

=item LDAP_OP_ABANDON_REQUEST [16]

  $data = { message_id => $message_id }

=item LDAP_OP_EXTENDED_REQUEST [23]

  $data = { oid   => $oid,
            value => $value }

=item LDAP_OP_BIND_RESPONSE [1]

  $data = { result => $result_code,
            matched_dn => $dn,
            message => $message,
            referrals => \@referrals,        # optional
            sasl_credentials => $credentials # optional
  }

=item LDAP_OP_SEARCH_ENTRY_RESPONSE [5]

  $data = { dn => $entry_dn,
            $attr1 => \@values1,
            $attr2 => \@values2,
            ...
  }

=item LDAP_OP_SEARCH_DONE_RESPONSE [5]

=item LDAP_OP_MODIFY_RESPONSE [7]

=item LDAP_OP_ADD_RESPONSE [9]

=item LDAP_OP_DELETE_RESPONSE [11]

=item LDAP_OP_MODIFY_DN_RESPONSE [13]

=item LDAP_OP_COMPARE_RESPONSE [15]

=item LDAP_OP_EXTENDED_RESPONSE [24]

  $data = { result     => $result_code,
            matched_dn => $dn,
            message    => $message,
            referrals  => \@referrals    # optional
  }

C<$result_code> contains the status of the operation (see
L<Net::LDAP::Gateway::Constant/Error codes>).

=back

=item $msg = ldap_pack_message_ref($msgid, $op, \%data)

=item $msg = ldap_pack_bind_request_ref($msgid, \%data)

=item $msg = ldap_pack_bind_response_ref($msgid, \%data)

=item $msg = ldap_pack_unbind_request_ref($msgid, \%data)

=item $msg = ldap_pack_search_request_ref($msgid, \%data)

=item $msg = ldap_pack_search_entry_response_ref($msgid, \%data)

=item $msg = ldap_pack_search_done_response_ref($msgid, \%data)

=item $msg = ldap_pack_modify_request_ref($msgid, \%data)

=item $msg = ldap_pack_modify_response_ref($msgid, \%data)

=item $msg = ldap_pack_add_request_ref($msgid, \%data)

=item $msg = ldap_pack_add_response_ref($msgid, \%data)

=item $msg = ldap_pack_delete_request_ref($msgid, \%data)

=item $msg = ldap_pack_delete_response_ref($msgid, \%data)

=item $msg = ldap_pack_modify_dn_request_ref($msgid, \%data)

=item $msg = ldap_pack_modify_dn_response_ref($msgid, \%data)

=item $msg = ldap_pack_compare_request_ref($msgid, \%data)

=item $msg = ldap_pack_compare_response_ref($msgid, \%data)

=item $msg = ldap_pack_abandon_request_ref($msgid, \%data)

=item $msg = ldap_pack_extended_request_ref($msgid, \%data)

=item $msg = ldap_pack_extended_response_ref($msgid, \%data)

These functions take a C<$msgid> and a reference to a hash
containing the message data and return the LDAP message.

The data structured passed must be as documented on
C<ldap_shift_message>.

=item $msg = ldap_pack_bind_request($msgid, ...)

=item $msg = ldap_pack_bind_response($msgid, $result, $matched_dn, $message, \@referrals, $SASL_creds)

=item $msg = ldap_pack_unbind_request($msgid)

=item $msg = ldap_pack_search_request($msgid, $base_dn, $scope, $deref, $size_limit, $time_limit, $types_only, $filter, \@attributes)

=item $msg = ldap_pack_search_entry_response($msgid, $dn, $attr1 => \@values1, $attr2 => \@values2)

=item $msg = ldap_pack_search_done_response($msgid, $result, $matched_dn, $message, \@referrals)

=item $msg = ldap_pack_modify_request($msgid, ...)

=item $msg = ldap_pack_modify_response($msgid, $result, $matched_dn, $message, \@referrals)

=item $msg = ldap_pack_add_request($msgid, ...)

=item $msg = ldap_pack_add_response($msgid, $result, $matched_dn, $message, \@referrals)

=item $msg = ldap_pack_delete_request($msgid, ...)

=item $msg = ldap_pack_delete_response($msgid, $result, $matched_dn, $message, \@referrals)

=item $msg = ldap_pack_modify_dn_request($msgid, ...)

=item $msg = ldap_pack_modify_dn_response($msgid, $result, $matched_dn, $message, \@referrals)

=item $msg = ldap_pack_compare_request($msgid, ...)

=item $msg = ldap_pack_compare_response($msgid, $result, $matched_dn, $message, \@referrals)

=item $msg = ldap_pack_abandon_request($msgid, ...)

=item $msg = ldap_pack_extended_request($msgid, ...)

=item $msg = ldap_pack_extended_response($msgid, ...)

These functions take a C<$msgid> and a list of arguments and return
the corresponding LDAP message.

=back

=head1 TODO

=over

=item - add support for SASL authentication

=item - add support for common controls and extensions (requests welcome!)

=item - support controls in packing methods

=back

=head1 SEE ALSO

Other Perl LDAP related modules: L<Net::LDAP>, L<Net::LDAPapi>,
L<Net::LDAP::Server>.

LDAP RFCs 4511, 4513, 4515, 4517, 4519, 4510, 4512, 4514, 4516 and 4518.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009, 2010, 2011 by Qindel Formacion y Servicios S.L.

This Perl module is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This Perl module is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this package. If not, see L<http://www.gnu.org/licenses/>.

=cut
