package Net::SSH::Perl::Mac;

use strict;
use warnings;
use Carp qw( croak );

use vars qw( %MAC %MAC_REVERSE %SUPPORTED );
%MAC = (
    'hmac-sha1' => 'SHA1',
    'hmac-md5'  => 'MD5',
    'hmac-sha2-256'  => 'SHA2_256',
    'hmac-sha2-512'  => 'SHA2_512',
    'hmac-sha2-256-etm@openssh.com'
                     => 'SHA2_256',
    'hmac-sha2-512-etm@openssh.com'
                     => 'SHA2_512',
);

sub new {
    my $class = shift;
    my $type = shift;
    my $mac_class = join '::', __PACKAGE__, $MAC{$type};
    my $mac = bless {}, $mac_class;
    $mac->init(@_) if @_;
    $mac->{etm} = $type =~ /-etm\@openssh.com$/;
    $mac;
}

sub enabled { $_[0]->{enabled} }
sub enable { $_[0]->{enabled} = 1 }

sub init {
    my $mac = shift;
    my($key) = @_;
    $mac->{key} = substr($key, 0, $mac->key_len);
}

sub hmac { }
sub key_len {
    my $mac = shift;
    $mac->{key_len} = shift if @_;
    $mac->{key_len};
}
sub etm { shift->{etm} }

package Net::SSH::Perl::Mac::MD5;
use strict;
use Crypt::Mac::HMAC;
use vars qw( @ISA );
@ISA = qw( Net::SSH::Perl::Mac );

sub hmac {
    Crypt::Mac::HMAC::hmac('MD5', shift->{key}, shift);
}

sub len { 16 }

package Net::SSH::Perl::Mac::SHA1;
use strict;
use Crypt::Mac::HMAC;
use vars qw( @ISA );
@ISA = qw( Net::SSH::Perl::Mac );

sub hmac {
    Crypt::Mac::HMAC::hmac('SHA1', shift->{key}, shift);
}

sub len { 20 }

package Net::SSH::Perl::Mac::SHA2_256;
use strict;
use Crypt::Mac::HMAC;
use vars qw( @ISA );
@ISA = qw( Net::SSH::Perl::Mac );

sub hmac {
    Crypt::Mac::HMAC::hmac('SHA256', shift->{key}, shift);
}

sub len { 32 }

package Net::SSH::Perl::Mac::SHA2_512;
use strict;
use Crypt::Mac::HMAC;
use vars qw( @ISA );
@ISA = qw( Net::SSH::Perl::Mac );

sub hmac {
    Crypt::Mac::HMAC::hmac('SHA512', shift->{key}, shift);
}

sub len { 64 }

1;
__END__

=head1 NAME

Net::SSH::Perl::Mac - MAC support for SSH2

=head1 SYNOPSIS

    use Net::SSH::Perl::Mac;
    my $mac = Net::SSH::Perl::Mac->new('hmac-sha1', $key);
    $mac->hmac("foo bar");

=head1 DESCRIPTION

I<Net::SSH::Perl::Mac> (and its subclasses) provides MAC support
for the SSH2 implementation in I<Net::SSH::Perl>. In the SSH2
protocol, each packet sent between client and server (after the
key exchange and algorithm negotiation phase) contains a MAC
to protect its integrity. The sending party computes the MAC over
the length, padding, and (encrypted) payload fields of the packet,
then appends the MAC; and the receiving party recomputes the MAC
against the data that it receives.

The MAC is computed using part of the key that is negotiated
during the key exchange phase. During negotiation, packets do
not contain MAC; after the I<SSH_MSG_NEWKEYS> message is sent,
each side turns on its respective encryption, MAC, and compression
code, for each packet that is sent after that point.

I<Net::SSH::Perl> supports two MAC algorithms: I<hmac-sha1> and
I<hmac-md5>. These algorithms are implemented, respectively,
by I<Digest::HMAC_SHA1> and I<Digest::HMAC_MD5>.

=head1 USAGE

Each MAC object supports the following methods:

=head2 $mac = Net::SSH::Perl::Mac->new( $name )

Constructs a new MAC object and returns that object.

=head2 $mac->init( $key )

Initializes I<$mac> and sets its key to I<$key> (or rather,
to a substring of key, I<key_len> bytes long). As this implies,
the I<key_len> method should be called before I<init> to set
the intended length of the key.

=head2 $mac->hmac( $data )

Computes the MAC over I<$data>, using the key set in the
initialization phase, and returns the MAC.

=head2 $mac->len

Returns the length of the MAC (eg. C<20> for HMAC_SHA1).

=head2 $mac->key_len( $len )

Given I<$len> sets the key length of I<$mac> to I<$len>.
This should be called I<before> the I<init> method, because
I<init> uses this value to take a substring of the provided
key value.

Most of the time this should just be set to the MAC length
(the I<len> method); certain SSH implementations have a bug,
however, wherein they always use only the first 16 bytes of
the provided key.

=head2 $mac->enable

Enables the MAC object. This is used by I<Net::SSH::Perl::Kex>
to "turn on" the MAC after key negotiation.

=head2 $mac->enabled

Tests the I<enabled> flag (set with the I<enable> method).
This is used by I<Net::SSH::Perl::Packet> to determine whether
or not to compute a MAC on an outgoing packet.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

hmac-sha2-256 and hmac-sha2-512 support added by:
Lance Kinley E<lkinley@loyaltymethods.com>

Copyright (c) 2015 Loyalty Methods, Inc.

=cut
