=head1 NAME

Net::SNMP::XS - speed up Net::SNMP by decoding in XS, with limitations

=head1 SYNOPSIS

 use Net::SNMP::XS;

 # loading it is enough to speed up Net::SNMP

=head1 DESCRIPTION

This module tries to speed up Net::SNMP response packet decoding.

It does this by overriding a few selected internal method by (almost)
equivalent XS methods.

This currently reduces decode time by a factor of ten for typical bulk
responses.

There are currently the following limitations when using this module:

=over 4

=item overriding internal functions might cause the module to
malfunction with future versions of Net::SNMP

=item error messages will be simpler/different

=item translation will be ignored (all values will be delivered "raw")

=item a moderately modern (>= C99) C compiler is required

=item only tested with 5.10, no intentions to port to older perls

=item duplicate OIDs are not supported

=item REPORT PDUs are not supported

=back

=cut

package Net::SNMP::XS;

use common::sense;

use Exporter qw(import);

use Net::SNMP ();
use Net::SNMP::PDU ();
use Net::SNMP::Message ();
use Net::SNMP::MessageProcessing ();

our $VERSION;

BEGIN {
   $VERSION = 1.34;

   # this overrides many methods inside Net::SNMP and it's submodules
   require XSLoader;
   XSLoader::load Net::SNMP::XS, $VERSION;
}

package Net::SNMP::Message;

Net::SNMP::XS::set_type INTEGER          , \&_process_integer32;
Net::SNMP::XS::set_type OCTET_STRING     , \&_process_octet_string;
Net::SNMP::XS::set_type NULL             , \&_process_null;
Net::SNMP::XS::set_type OBJECT_IDENTIFIER, \&_process_object_identifier;
Net::SNMP::XS::set_type SEQUENCE         , \&_process_sequence;
Net::SNMP::XS::set_type IPADDRESS        , \&_process_ipaddress;
Net::SNMP::XS::set_type COUNTER          , \&_process_counter;
Net::SNMP::XS::set_type GAUGE            , \&_process_gauge;
Net::SNMP::XS::set_type TIMETICKS        , \&_process_timeticks;
Net::SNMP::XS::set_type OPAQUE           , \&_process_opaque;
Net::SNMP::XS::set_type COUNTER64        , \&_process_counter64;
Net::SNMP::XS::set_type NOSUCHOBJECT     , \&_process_nosuchobject;
Net::SNMP::XS::set_type NOSUCHINSTANCE   , \&_process_nosuchinstance;
Net::SNMP::XS::set_type ENDOFMIBVIEW     , \&_process_endofmibview;
Net::SNMP::XS::set_type GET_REQUEST      , \&_process_get_request;
Net::SNMP::XS::set_type GET_NEXT_REQUEST , \&_process_get_next_request;
Net::SNMP::XS::set_type GET_RESPONSE     , \&_process_get_response;
Net::SNMP::XS::set_type SET_REQUEST      , \&_process_set_request;
Net::SNMP::XS::set_type TRAP             , \&_process_trap;
Net::SNMP::XS::set_type GET_BULK_REQUEST , \&_process_get_bulk_request;
Net::SNMP::XS::set_type INFORM_REQUEST   , \&_process_inform_request;
Net::SNMP::XS::set_type SNMPV2_TRAP      , \&_process_v2_trap;
Net::SNMP::XS::set_type REPORT           , \&_process_report;

package Net::SNMP::PDU;

# var_bind_list hardcodes oid_lex_sort. *sigh*
# we copy it 1:1, except for using oid_lex_sort.

sub var_bind_list
{
   my ($this, $vbl, $types) = @_;

   return if defined($this->{_error});

   if (@_ > 1) {
      # The VarBindList HASH is being updated from an external
      # source.  We need to update the VarBind names ARRAY to
      # correspond to the new keys of the HASH.  If the updated
      # information is valid, we will use lexicographical ordering
      # for the ARRAY entries since we do not have a PDU to use
      # to determine the ordering.  The ASN.1 types HASH is also
      # updated here if a cooresponding HASH is passed.  We double
      # check the mapping by populating the hash with the keys of
      # the VarBindList HASH. 

      if (!defined($vbl) || (ref($vbl) ne 'HASH')) {

         $this->{_var_bind_list}  = undef;
         $this->{_var_bind_names} = [];
         $this->{_var_bind_types} = undef; 

      } else {

         $this->{_var_bind_list} = $vbl;

         @{$this->{_var_bind_names}} = Net::SNMP::oid_lex_sort keys %$vbl;

         if (!defined($types) || (ref($types) ne 'HASH')) {
             $types = {};
         }

         map { 
            $this->{_var_bind_types}->{$_} = 
               exists($types->{$_}) ? $types->{$_} : undef; 
         } keys(%{$vbl});

      }

   }

   $this->{_var_bind_list};
}

1;

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

