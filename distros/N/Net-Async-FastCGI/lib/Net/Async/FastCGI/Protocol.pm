#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2010-2011 -- leonerd@leonerd.org.uk

package Net::Async::FastCGI::Protocol;

use strict;
use warnings;

use base qw( IO::Async::Protocol::Stream );

our $VERSION = '0.25';

use Net::FastCGI::Constant qw( 
   FCGI_UNKNOWN_TYPE
);

use Net::FastCGI::Protocol qw(
   parse_header
   build_record
   build_unknown_type_body
);

sub on_read
{
   my $self = shift;
   my ( $buffref, $handleclosed ) = @_;

   my $blen = length $$buffref;

   if( $handleclosed ) {
      # Abort
      my $fcgi = $self->{fcgi};
      $fcgi->remove_child( $self );
      return;
   }

   # Do we have a record header yet?
   return 0 unless( $blen >= 8 );

   # Excellent - parse it
   my ( $type, $reqid, $contentlen, $padlen ) = parse_header( $$buffref );

   # Do we have enough for a complete record?
   return 0 unless( $blen >= 8 + $contentlen + $padlen );

   substr( $$buffref, 0, 8, "" ); # Header

   my $rec = {
      type  => $type,
      reqid => $reqid,
      len   => $contentlen,
      plen  => $padlen,
   };

   $rec->{content} = substr( $$buffref, 0, $contentlen, "" );

   substr( $$buffref, 0, $rec->{plen}, "" ); # Padding

   if( $reqid == 0 ) {
      $self->on_mgmt_record( $type, $rec );
   }
   else {
      $self->on_record( $reqid, $rec );
   }

   return 1;
}

sub on_mgmt_record
{
   my $self = shift;
   my ( $type, $rec ) = @_;

   $self->write_record( { type => FCGI_UNKNOWN_TYPE, reqid => 0 }, build_unknown_type_body( $type ) );
}

sub write_record
{
   my $self = shift;
   my ( $rec, $content ) = @_;

   $self->write( build_record( $rec->{type}, $rec->{reqid}, $content ) );
}

0x55AA;
