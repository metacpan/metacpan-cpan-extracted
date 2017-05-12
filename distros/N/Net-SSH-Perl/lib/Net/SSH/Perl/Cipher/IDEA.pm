# $Id: IDEA.pm,v 1.7 2001/05/02 21:59:33 btrott Exp $

package Net::SSH::Perl::Cipher::IDEA;

use strict;
use warnings;

use Net::SSH::Perl::Cipher;
use base qw( Net::SSH::Perl::Cipher );

use Net::SSH::Perl::Cipher::CFB;
use Crypt::IDEA;

sub new {
    my $class = shift;
    my $ciph = bless { }, $class;
    $ciph->init(@_) if @_;
    $ciph;
}

sub init {
    my $ciph = shift;
    my($key, $iv) = @_;
    my $idea = IDEA->new(substr $key, 0, 16);
    $ciph->{cfb} = Net::SSH::Perl::Cipher::CFB->new($idea, $iv);
}

sub encrypt {
    my($ciph, $text) = @_;
    $ciph->{cfb}->encrypt($text);
}

sub decrypt {
    my($ciph, $text) = @_;
    $ciph->{cfb}->decrypt($text);
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Cipher::IDEA - Wrapper for SSH IDEA support

=head1 SYNOPSIS

    use Net::SSH::Perl::Cipher;
    my $cipher = Net::SSH::Perl::Cipher->new('IDEA', $key);
    print $cipher->encrypt($plaintext);

=head1 DESCRIPTION

I<Net::SSH::Perl::Cipher::IDEA> provides IDEA encryption
support for I<Net::SSH::Perl>. To do so it wraps around
I<Crypt::IDEA>, a C/XS implementation of the IDEA algorithm.

The IDEA algorithm used here is in CFB filter mode with a
key length of 16 bytes.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
