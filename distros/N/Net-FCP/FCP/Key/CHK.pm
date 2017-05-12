=head1 NAME

Net::FCP::Key::CHK - manage CHK keys.

=head1 SYNOPSIS

 use Net::FCP::Key::CHK;

 my $key = new Net::FCP::Key::CHK;
 my $key = new_from_uri Net::FCP::Key::CHK $uri;
 my $key = new_from_data Net::FCP::Key::CHK $data, $metadata;
 ... more to come


=head1 DESCRIPTION

=head2 THE Net::FCP::Key::CHK CLASS

=over 4

=cut

package Net::FCP::Key::CHK;

use Carp;
use Digest::SHA1;
use MIME::Base64;

use Crypt::Rijndael;
use Crypt::Twofish;

use Net::FCP::Util;

no warnings;

=item my $key = new Net::FCP::Key::CHK;

Heavily under development, don't use :)

=cut

sub new {
   my $class = shift;

   bless { }, $class;
}

=item my $key = new_from_data Net::FCP::Key::CHK $metadata, $data[, $cipher];

Generate a CHK from the given data and metadata strings.

=cut

sub new_from_data {
   my ($class, $metadata, $data, $cipher) = @_;

   $class->new->set_data ($metadata, $data, $cipher);
}

sub rolling_hashpad($$$) {
   my $sha1 = $_[1];
   my $pad = "";
   my $dig;

   while ($_[2] > length $_[0]) {
      $sha1->add ($dig = $sha1->digest_noreset);
      $pad .= $dig;
      $_[0] .= $pad;
   }

   substr $_[0], $_[2], length $_[0], "";
}

sub encode_number($) {
   my $num = pack "N", $_[0];
   $num =~ s/^\x00+//;
   pack "n a*", length $num, $num;
}

sub set_data {
   my ($self, $metadata, $data, $cipher) = @_;

   $cipher ||= "Twofish";

   my $cipher_class = "Crypt::$cipher";

   $cipher_class->blocksize == 16 or die "only ciphers with a blocksize of 128 bits are supported";

   my $total_len = (length $metadata) + (length $data);
   my $padded_log = Net::FCP::Util::log2 $total_len, 10;
   my $padded_len = 1 << $padded_log;

   my $plaintext = "$metadata$data";

   # crypto key (hash) generation. this is an iterative
   # algorithm, but it is "unrolled" here for the
   # common keysize of 16 bytes.
   my $data_sha1 = Digest::SHA1->new->add ($plaintext);

   # only works for 128 bit keys
   my $k = new Digest::SHA1;
   $k->add ("\x00" x 1);
   $k->add ($data_sha1->clone->digest);

   my $hash = substr $k->digest, 0, 16; # extract leading 128 bit

   my $buf = "";

   $buf .= pack "n a20", 20, Digest::SHA1::sha1 $hash;

   $buf .= encode_number $total_len;
   $buf .= encode_number length $metadata;

   $buf .= "\x00\x00";

   rolling_hashpad $buf, Digest::SHA1->new->add ($buf), 1 << Net::FCP::Util::log2 length $buf;

   my $pcfb_cipher = $cipher_class->new ($hash);
   my $pcfb_reg = "\x00" x 16;

   my $pcfb_enc = sub  {
      my $length = length $_[0];
      my $enc = "";
      for (my $i = 0; $i < $length; $i += 16) {
         $enc .= $pcfb_reg = $pcfb_cipher->encrypt ($pcfb_reg) ^ substr $_[0], $i, 16;
      }
      $enc;
   };

   # buf length must be multiple of 16
   $buf = $pcfb_enc->($buf);

   my $senc = unpack "H*", $buf;

   rolling_hashpad $plaintext, $data_sha1, $padded_len;

   # plaintext length must be a multiple of 16, too
   $plaintext = $pcfb_enc->($plaintext);

   my $partsize = $padded_len < 16384      ? $padded_len
                : $padded_len < 16384 << 7 ? 16384
                :                            $padded_len >> 7; # 2MB

   my $dig = "";
   for (my $ofs = ($padded_len-1) - ($padded_len-1) % $partsize; $ofs >= 0; $ofs -= $partsize) {
      $dig = Digest::SHA1::sha1 substr ($plaintext, $ofs, $partsize) . $dig;
   }

   my $sini = unpack "H*", $dig;

   my $route = sprintf
           "Document-header\xfe%s\xff"
         . "Initial-digest\xfe%s\xff"
         . "Part-size\xfe%x\xff"
         . "Symmetric-cipher\xfe%s\xff",
           $senc, $sini, $partsize, $cipher;

   $route = Net::FCP::Util::encode_base64 +(Digest::SHA1::sha1 $route) . (pack "C", $padded_log) . "\x03\x02";
   $hash = Net::FCP::Util::encode_base64 $hash;

   return "freenet:CHK\@$route,$hash";
   $self;
}

=item $size = $key->size

Returns the size of the data (in bytes).

=cut

=item $digest = $key->digest

Return the store digest/hash.

=cut

=item $keynum = $key->keynumber

Returns the keynumber (version?)

=cut

=item $chk = $key->chk

Return the full CHK.

=cut

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

