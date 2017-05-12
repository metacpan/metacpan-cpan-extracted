=head1 NAME

Net::FCP::Util - utility functions.

=head1 SYNOPSIS

 use Net::FCP::Util;


=head1 DESCRIPTION

=over 4

=cut

package Net::FCP::Util;

use Carp ();
use Digest::SHA1;
use MIME::Base64 ();

no warnings;

use base Exporter::;

@EXPORT_OK = qw(tolc touc xeh);

=item touc $string

Returns the uppercased version of the given identifier. Used internally to
map from e.g. URIError/KeyCollision to the form used in this module, i.e.
uri_error/key_collision etc.

=cut

sub touc($) {
   local $_ = shift;
   1 while s/((?:^|_)(?:svk|chk|uri)(?:_|$))/\U$1/;
   s/(?:^|_)(.)/\U$1/g;
   $_;
}

=item tolc $string

Returns the lowercased version of the given identifier. See C<touc>.

=cut

sub tolc($) {
   local $_ = shift;
   1 while s/(SVK|CHK|URI)([^_])/$1\_$2/i;
   1 while s/([^_])(SVK|CHK|URI)/$1\_$2/i;
   s/(?<=[a-z])(?=[A-Z])/_/g;
   lc $_;
}

=item xeh $number

The opposite of C<hex>, i.e. returns the the number as hex string. Mainly
useful due to it's prototype of C<$>.

=cut

sub xeh($) {
   sprintf "%x", $_[0];
}

=item log2 $num[, $minlog]

Calculate the (integer) log2 of a number, rounded up. If C<$minlog> is
given it will be the minimum value returned.

=cut

sub log2($;$) { # n, minlog
   $_[0] && length sprintf "%$_[1]b", $_[0] - 1;
}
# the above line is much faster than the equivalent
# below, which illustrates a fine point of perl...
#  my ($n, $b) = @_;
#  $b++ while 1 << $b < $n;
#  $b;

=item encode_mpi $num

Encode the given number as a multiple-precision number (2 byte bitlength + bytes)

=cut

sub encode_mpi($) {
   my $num = pack "N", $_[0];
   my $len = log2 $_[0], 1;
   $num =~ s/^\x00+//;
   pack "n a*", $len, $num;
}

=item decode_base64 $string

Decode freenet's perverted version of base64.

=cut

sub decode_base64($) {
   my $s = shift;

   $s =~ y%~\-%+/%;
   MIME::Base64::decode_base64 "$s======";
}

=item encode_base64 $data

Encode into freenet's perverted version of base64.

=cut

sub encode_base64($) {
   my $s = MIME::Base64::encode_base64 shift, "";
   $s =~ s/=+$//;
   $s =~ y%+/%~\-%;
   $s;
}

=item generate_chk_hash $metadata, $data

Generate and return they hash portion (the part after the comma, the
crypto key) that would be used in the CHK (as binary). This can be used to
verify contents of a CHK, since this key is a hash over the data.

(This function assumes a 128 bit key, which seems standard in freenet).

=cut

sub generate_chk_hash($$) {
   my $d = new Digest::SHA1;

   $d->add ($_[0]);
   $d->add ($_[1]);
   $d = $d->digest;

   my $k = new Digest::SHA1;
   $k->add ("\x00" x 1); # only one iteration
   $k->add ($d);
   
   substr $k->digest, 0, 16; # extract leading 128 bit
}

=item extract_chk_hash $uri

Extract the hash portion (the part after the comma, the crypto key) of a
CHK (in binary). Useful to compare against the output of generate_chk_key.

=cut

sub extract_chk_hash($) {
   $_[0] =~ /CHK\@[a-zA-Z0-9~\-]{31},([a-zA-Z0-9~\-]{22})/
      or Carp::croak "unable to parse CHK key from '$_[0]'";

   decode_base64 $1;
}

=back

=head1 SEE ALSO

L<Net::FCP>.

=head1 BUGS

Not heavily tested.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1;

