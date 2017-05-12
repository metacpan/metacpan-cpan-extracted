package Net::IPMessenger::EncryptOption;

use warnings;
use strict;
use overload '""' => \&get_option, fallback => 1;
use Scalar::Util qw( looks_like_number );

our $AUTOLOAD;

my %ENCRYPT_OPT = (
    RSA_512         => 0x00000001,
    RSA_1024        => 0x00000002,
    RSA_2048        => 0x00000004,
    RC2_40          => 0x00001000,
    RC2_128         => 0x00004000,
    RC2_256         => 0x00008000,
    BLOWFISH_128    => 0x00020000,
    BLOWFISH_256    => 0x00040000,
    SIGN_MD5        => 0x10000000,
    RC2_40OLD       => 0x00000010,
    RC2_128OLD      => 0x00000040,
    BLOWFISH_128OLD => 0x00000400,
);

sub new {
    my $class = shift;
    my $option = shift || 0;

    return unless looks_like_number($option);
    my $self = { _option => $option };
    bless $self, $class;
}

sub AUTOLOAD {
    my $self = shift;
    return unless ref $self;

    my $option = $self->{_option};
    my $name   = $AUTOLOAD;
    $name =~ s/.*://;

    if ( $name =~ /^get_(.+)/ ) {
        my $enc = uc $1;
        if ( exists $ENCRYPT_OPT{$enc} ) {
            return ( $option & $ENCRYPT_OPT{$enc} ? 1 : 0 );
        }
        else {
            return;
        }
    }
    elsif ( $name =~ /^set_(.+)/ ) {
        my $enc = uc $1;
        if ( exists $ENCRYPT_OPT{$enc} ) {
            $self->{_option} = $option | $ENCRYPT_OPT{$enc};
            return $self;
        }
        else {
            return;
        }
    }
    else {
        return;
    }
}

sub get_option {
    my $self = shift;
    return $self->{_option};
}

1;
__END__

=head1 NAME

Net::IPMessenger::EncryptOption - encrypt option definition

=head1 SYNOPSIS

    use Net::IPMessenger::EncryptOption;

    my $option = Net::IPMessenger::EncryptOption->new;
    $option->set_rsa_1024->set_blowfish_128;

=head1 DESCRIPTION

This defines IP Messenger encrypt and option flags.
This also gives you accessors of those option flags.

=head1 METHODS

=head2 new

This creates object and return it.
if argument is given and it looks like number,
store it and use as default option value.


=head2 get_option

Returns option value.

=cut
