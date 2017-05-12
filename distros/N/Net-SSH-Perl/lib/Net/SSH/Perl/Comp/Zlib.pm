# $Id: Zlib.pm,v 1.3 2008/10/02 20:46:17 turnstep Exp $

package Net::SSH::Perl::Comp::Zlib;

use strict;
use warnings;
use Carp qw( croak );
require Compress::Zlib;

use Net::SSH::Perl::Comp;
use base qw( Net::SSH::Perl::Comp );

sub init {
    my $comp = shift;
    my($level) = @_;
    my($err);

    ($comp->{d}, $err) = Compress::Zlib::deflateInit({ Level => $level });
    croak "Can't create outgoing compression stream"
        unless $err == Compress::Zlib::Z_OK();

    ($comp->{i}, $err) = Compress::Zlib::inflateInit();
    croak "Can't create incoming compression stream"
        unless $err == Compress::Zlib::Z_OK();
}

sub compress {
    my $comp = shift;
    my($data) = @_;
    my $d = $comp->{d};
    my($compressed, $err);
    {
        my($output, $out);
        ($output, $err) = $d->deflate($data);
        last unless $err == Compress::Zlib::Z_OK();
        ($out, $err) = $d->flush(Compress::Zlib::Z_PARTIAL_FLUSH());
        last unless $err == Compress::Zlib::Z_OK();

        $compressed = $output . $out;
    }
    croak "Error while compressing: $err" unless defined $compressed;
    $compressed;
}

sub uncompress {
    my $comp = shift;
    my($data) = @_;
    my $i = $comp->{i};
    my($inflated, $err);
    {
        my($out);
        ($out, $err) = $i->inflate($data);
        last unless $err == Compress::Zlib::Z_OK();

        $inflated = $out;
    }
    croak "Error while inflating: $err"
        unless defined $inflated;
    $inflated;
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Comp::Zlib - Wrapper for SSH Zlib Compression

=head1 SYNOPSIS

    use Net::SSH::Perl::Comp;
    my $comp = Net::SSH::Perl::Comp->new('Zlib');
    print $comp->compress($data);

=head1 DESCRIPTION

I<Net::SSH::Perl::Comp::Zlib> subclasses I<Net::SSH::Perl::Comp> to
provide Zlib compression support for I<Net::SSH::Perl>. To do so it
wraps around I<Compress::Zlib>, an XS hook into the I<zlib> library.

Read through the I<Net::SSH::Perl::Comp> docs for usage information.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright, and
license information.

=cut
