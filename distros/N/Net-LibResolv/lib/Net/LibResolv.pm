#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2011 -- leonerd@leonerd.org.uk

package Net::LibResolv;

use strict;
use warnings;

our $VERSION = '0.03';

use Exporter 'import';
our @EXPORT_OK = qw(
   res_query
   res_search

   $h_errno
);
our %EXPORT_TAGS;

our $h_errno;

require XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

$EXPORT_TAGS{"errors"} = [qw( HOST_NOT_FOUND NO_ADDRESS NO_DATA NO_RECOVERY TRY_AGAIN )];

=head1 NAME

C<Net::LibResolv> - a Perl wrapper around F<libresolv>

=head1 SYNOPSIS

 use Net::LibResolv qw( res_query NS_C_IN NS_T_A $h_errno );
 use Net::DNS::Packet;
 
 my $answer = res_query( "www.cpan.org", NS_C_IN, NS_T_A );
 defined $answer or die "DNS failure - $h_errno\n";
 
 foreach my $rr ( Net::DNS::Packet->new( \$answer )->answer ) {
    print $rr->string, "\n";
 }

=head1 DESCRIPTION

The F<libresolv> library provides functions to use the platform's standard DNS
resolver to perform DNS queries. This Perl module provides a wrapping for the
two primary functions, C<res_query(3)> and C<res_search(3)>, allowing them to
be used from Perl.

The return value from each function is a byte buffer containing the actual DNS
response packet. This will need to be parsed somehow to obtain the useful
information out of it; most likely by using L<Net::DNS>.

=cut

=head1 FUNCTIONS

=cut

# These functions are implemented in XS

=head2 $answer = res_query( $dname, $class, $type )

Calls the C<res_query(3)> function on the given domain name, class and type
number. Returns the answer byte buffer on success, or C<undef> on failure. On
failure sets the value of the C<$h_errno> package variable.

C<$dname> should be a plain string. C<$class> and C<$type> should be numerical
codes. See the C<CONSTANTS> section for convenient definitions.

=cut

=head2 $answer = res_search( $dname, $class, $type )

Calls the C<res_search(3)> function on the given domain name, class and type
number. Returns the answer byte buffer on success, or C<undef> on failure. On
failure sets the value of the C<$h_errno> package variable.

C<$dname> should be a plain string. C<$class> and C<$type> should be numerical
codes. See the C<CONSTANTS> section for convenient definitions.

=cut

=head1 VARIABLES

=head2 $h_errno

After an error from C<res_query> or C<res_search>, this variable will be set
to the error value, as a dual-valued scalar. Its numerical value will be one
of the error constants (see below); it string value will be an error message
version of the same (similar to the C<$!> perl core variable).

 if( !defined( my $answer = res_query( ... ) ) ) {
    print "Try again later...\n" if $h_errno == TRY_AGAIN;
 }

Z<>

 defined( my $answer = res_query( ... ) ) or
    die "Cannot res_query() - $h_errno\n";

=cut

=head1 CONSTANTS

=cut

sub _setup_constants
{
   my %args = @_;

   my $name   = $args{name};
   my $prefix = $args{prefix};
   my $values = $args{values};
   my $tag    = $args{tag};

   my %name2value = %$values;
   my %value2name = reverse %name2value;

   require constant;
   constant->import( "$prefix$_" => $name2value{$_} ) for keys %name2value;

   push @EXPORT_OK, map "$prefix$_", keys %name2value;

   $EXPORT_TAGS{$tag} = [ map "$prefix$_", keys %name2value ];

   no strict 'refs';
   *{"${name}_name2value"} = sub { $name2value{uc shift} };
   *{"${name}_value2name"} = sub { $value2name{+shift} };

   push @EXPORT_OK, "${name}_name2value", "${name}_value2name";
}

# These constants are defined by RFCs, primarily RFC 1035 and friends. We
# shouldn't need to pull these out of platform .h files as they're portable
# constants

=head2 Class IDs

The following set of constants define values for the C<$class> parameter.
Typically only C<NS_C_IN> is actually used, for Internet.

 NS_C_IN NS_C_CHAOS NS_C_HS
 NS_C_INVALD NS_C_NONE NS_C_ANY

=head2 $id = class_name2value( $name )

=head2 $name = class_value2name( $id )

Functions to convert between class names and ID values.

=cut

_setup_constants
   name   => "class",
   prefix => "NS_C_",
   tag    => "classes",
   values => {
      INVALID => 0,
      IN      => 1,
      CHAOS   => 3,
      HS      => 4,
      NONE    => 254,
      ANY     => 255,
   };

=head2 Type IDs

The following are examples of constants define values for the C<$type>
parameter. (They all follow the same naming pattern, named after the record
type, so only a few are listed here.)

 NS_T_A NS_T_NS NS_T_CNAME NS_T_PTR NS_T_MX NS_T_TXT NS_T_SRV NS_T_AAAA
 NS_T_INVALID NS_T_ANY

=head2 $id = type_name2value( $name )

=head2 $name = type_value2name( $id )

Functions to convert between type names and ID values.

=cut

# The following list shamelessly stolen from <arpa/nameser.h>
_setup_constants
   name   => "type",
   prefix => "NS_T_",
   tag    => "types",
   values => {
      INVALID  => 0,
      A        => 1,
      NS       => 2,
      MD       => 3,
      MF       => 4,
      CNAME    => 5,
      SOA      => 6,
      MB       => 7,
      MG       => 8,
      MR       => 9,
      NULL     => 10,
      WKS      => 11,
      PTR      => 12,
      HINFO    => 13,
      MINFO    => 14,
      MX       => 15,
      TXT      => 16,
      RP       => 17,
      AFSDB    => 18,
      X25      => 19,
      ISDN     => 20,
      RT       => 21,
      NSAP     => 22,
      NSAP_PTR => 23,
      SIG      => 24,
      KEY      => 25,
      PX       => 26,
      GPOS     => 27,
      AAAA     => 28,
      LOC      => 29,
      NXT      => 30,
      EID      => 31,
      NIMLOC   => 32,
      SRV      => 33,
      ATMA     => 34,
      NAPTR    => 35,
      KX       => 36,
      CERT     => 37,
      A6       => 38,
      DNAME    => 39,
      SINK     => 40,
      OPT      => 41,
      APL      => 42,
      TKEY     => 249,
      TSIG     => 250,
      IXFR     => 251,
      AXFR     => 252,
      MAILB    => 253,
      MAILA    => 254,
      ANY      => 255,
   };

=head2 Errors

The following constants define error values for C<$h_errno>.

 HOST_NOT_FOUND NO_ADDRESS NO_DATA NO_RECOVERY TRY_AGAIN

The values of C<NO_ADDRESS> and C<NO_DATA> may be the same.

=head1 SEE ALSO

=over 4

=item *

L<Net::DNS> - Perl interface to the DNS resolver

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
