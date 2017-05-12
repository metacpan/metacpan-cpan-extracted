# $Id: RSA1.pm,v 1.13 2001/06/27 22:49:55 btrott Exp $

package Net::SSH::Perl::Key::RSA1;
use strict;
use warnings;

use Net::SSH::Perl::Util qw( :ssh1mp :authfile );

use Net::SSH::Perl::Key;
use base qw( Net::SSH::Perl::Key );

use Carp qw( croak );
use Math::GMP;
use Digest::MD5 qw( md5 );

sub init {
    my $key = shift;
    $key->{rsa} = {};

    my($blob) = @_;
    return unless $blob;
    my($bits, $e, $n) = split /\s+/, $blob, 3;
    $key->{rsa}{bits} = $bits;
    $key->{rsa}{e} = $e;
    $key->{rsa}{n} = $n;
}

sub size { $_[0]->{rsa}{bits} }

sub keygen {
    my $class = shift;
    my($bits) = @_;

    eval {
        require Crypt::RSA;
        require Crypt::RSA::DataFormat;
        Crypt::RSA::DataFormat->import('bitsize');
    };
    if ($@) {
        croak "rsa1 key generation is unavailable without Crypt::RSA";
    }
    my $gmp = sub { Math::GMP->new("$_[0]") };

    my $rsa = Crypt::RSA->new;
    my $key = $class->new;
    my($pub, $priv) = $rsa->keygen(
                     Size      => $bits,
                     Password  => 'ssh',
                     Verbosity => 1,
                     Identity  => 'Net::SSH::Perl',
          );
    die $rsa->errstr unless $pub && $priv;

    $key->{rsa}{e} = $gmp->($pub->e);
    $key->{rsa}{n} = $gmp->($pub->n);
    $key->{rsa}{bits} = $gmp->(bitsize($pub->n));
    $key->{rsa}{d} = $gmp->($priv->d);
    $key->{rsa}{u} = $gmp->($priv->u);
    $key->{rsa}{p} = $gmp->($priv->p);
    $key->{rsa}{q} = $gmp->($priv->q);

    $key;
}

sub read_private {
    my $class = shift;
    my($keyfile, $passphrase) = @_;
    my($key, $comment);
    eval {
        ($key, $comment) = _load_private_key($keyfile, $passphrase);
    };
    if (wantarray) {
        return $key && !$@ ? ($key, $comment) : ();
    }
    else {
        return $key && !$@ ? $key : undef;
    }
}

sub write_private {
    my $key = shift;
    my($keyfile, $passphrase, $comment) = @_;
    _save_private_key($keyfile, $key, $passphrase, $comment);
}

sub extract_public {
    my $class = shift;
    $class->new(@_);
}

sub dump_public { $_[0]->as_blob }

sub equal {
    my($keyA, $keyB) = @_;
    $keyA->{rsa} && $keyB->{rsa} &&
    $keyA->{rsa}{bits} == $keyB->{rsa}{bits} &&
    $keyA->{rsa}{n} == $keyB->{rsa}{n} &&
    $keyA->{rsa}{e} == $keyB->{rsa}{e};
}

sub as_blob {
    my $key = shift;
    join ' ', $key->{rsa}{bits}, $key->{rsa}{e}, $key->{rsa}{n};
}

sub fingerprint_raw {
    my $key = shift;
    _mp_linearize($key->{rsa}->{n}) . _mp_linearize($key->{rsa}->{e});
}

1;
__END__

=head1 NAME

Net::SSH::Perl::Key::RSA1 - RSA SSH1 key object

=head1 SYNOPSIS

    use Net::SSH::Perl::Key::RSA1;
    my $key = Net::SSH::Perl::Key::RSA1->new;

=head1 DESCRIPTION

I<Net::SSH::Perl::Key::RSA1> subclasses I<Net::SSH::Perl::Key>
to implement a key object, SSH style. This object provides
functionality needed by I<Net::SSH::Perl>, ie. for checking
host key files, determining whether keys are equal, generating
key fingerprints, etc.

=head1 USAGE

I<Net::SSH::Perl::Key::RSA1> implements the interface described in
the documentation for I<Net::SSH::Perl::Key>.

=head1 AUTHOR & COPYRIGHTS

Please see the Net::SSH::Perl manpage for author, copyright,
and license information.

=cut
