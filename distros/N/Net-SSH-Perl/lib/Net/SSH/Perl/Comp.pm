# $Id: Comp.pm,v 1.5 2001/04/18 06:36:57 btrott Exp $

package Net::SSH::Perl::Comp;

use strict;
use warnings;
use Carp qw( croak );

use vars qw( %COMP );
%COMP = (
    'zlib' => 'Zlib',
);

sub new {
    my $class = shift;
    my $type = shift;
    return if $type eq 'none';
    my $comp_class = join '::', __PACKAGE__, $COMP{$type} || $type;
    eval "use $comp_class;";
    my $comp = bless {}, $comp_class;
    $comp->init(@_) if @_;
    $comp;
}

sub enabled { $_[0]->{enabled} }
sub enable { $_[0]->{enabled} = 1 }

sub init { }

sub compress { $_[0] }
sub uncompress { $_[0] }

1;
__END__

=head1 NAME

Net::SSH::Perl::Comp - Compression/Decompression base class

=head1 SYNOPSIS

    use Net::SSH::Perl::Comp;
    my $comp = Net::SSH::Perl::Comp->new( $comp_type );
    $comp->compress($data);

=head1 DESCRIPTION

I<Net::SSH::Perl::Comp> is a base class for compression/decompression
classes. Currently the only such class is the Zlib implementation
(using I<Compress::Zlib>), which is the class I<Net::SSH::Perl::Comp::Zlib>.

Each compression object generally has its own internal "state"; this
state changes when you compress or decompress data. The SSH protocol
dictates that you must have two I<separate> objects to compress and
decompress data: one for compression, one for decompression. So, for
example, you would create two I<Net::SSH::Perl::Comp> objects:

    my $in = Net::SSH::Perl::Comp->new('Zlib');
    my $inflated = $in->decompress($data);

    my $out = Net::SSH::Perl::Comp->new('Zlib');
    my $deflated = $out->compress($data);

=head1 USAGE

=head2 $comp = Net::SSH::Perl::Comp->new( $comp_type [, @args ] )

Constructs a new compression object of compression type I<$comp_type>
and returns that object.

If I<@args> are provided, the class's I<init> method is called with
those arguments, for any post-creation initialization.

=head2 $comp->init($level)

Initializes I<$comp> and sets the compression level to I<$level>.
This method will be called automatically from I<new> if you've
provided I<@args> to I<new>. So, for example, you could write:

    my $comp = Net::SSH::Perl::Comp->new('Zlib', 5);

To create a new I<Zlib> compression object and initialize its
compression level to 5.

=head2 $comp->compress( $data )

Compresses I<$data> using the underlying compression mechanism;
returns the compressed data.

=head2 $comp->decompress( $data )

Decompresses I<$data> using the underlying decompression mechanism;
returns the decompressed data.

=head2 $comp->enable

"Enables" the compression object. This is useful in the context of
the key exchange (I<Kex>) classes, which create a new compression
object during key negotiation, but don't actually turn it on ("enable"
it) until receiving/sending the I<SSH2_MSG_NEWKEYS> message.

I<Net::SSH::Perl::Comp> objects (and subclasses) are disabled by
default.

=head2 $comp->enabled

Returns the state of the "enabled" flag, ie. whether the compression
object is "turned on".

This is used by I<Net::SSH::Perl::Packet> when determining whether
data it receives/sends to the server should be decompressed/compressed,
respectively.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
