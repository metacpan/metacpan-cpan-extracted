package Passwords;

use 5.010;
use strict;
use warnings;
use autodie;
use utf8;
use Carp;
use Crypt::Eksblowfish::Bcrypt qw(bcrypt_hash en_base64 de_base64);
use Data::Entropy::Algorithms qw(rand_bits);

=encoding utf8

=head1 NAME

Passwords - Provides an easy to use API for the creation and management of passwords in a secure manner

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

    use Passwords;

    # create password-hash (simple way with bcrypt, random-salt, cost of 14)
    my $hash = password_hash('perlhipster');
    say $hash;
    
    # custom options
    # my $hash = password_hash('perlhipster', PASSWORD_BCRYPT, ( 'cost' => 20, 'salt' => 'This-Is-ASillySalt2014'));
    
    # verify password
    if (password_verify('perlhipster', $hash)) {
        say 'ok';
    } else {
        say 'nok';
    }

=head1 EXPORT

    PASSWORD_DEFAULT
    PASSWORD_BCRYPT
    
    password_get_info
    password_hash
    password_needs_rehash
    password_verify

=cut

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(
    PASSWORD_DEFAULT
    PASSWORD_BCRYPT
    password_get_info
    password_hash
    password_needs_rehash
    password_verify
);

use constant PASSWORD_DEFAULT => 1;
use constant PASSWORD_BCRYPT => 1;

=head1 SUBROUTINES

=head2 password_get_info( $hash )

Returns information about the given hash

    {
        'algoName' => 'bcrypt',
        'algo' => 1,
        'options' => {
            'cost' => 14
        }
    };

=cut

sub password_get_info {
    my $hash = shift;
    my %return = (
        'algo' => 0,
        'algoName' => 'unknown',
        'options' => undef,
    );
    
    if (not defined $hash) {
        carp 'password_get_info(): Hash must be supplied';
        return;
    }
    
    if (_is_bcrypt($hash)) {
        $return{'algo'} = PASSWORD_BCRYPT;
        $return{'algoName'} = 'bcrypt';
        $return{'options'}{'cost'} = $1 if $hash =~ m#\A\$2y\$([0-9]{2})\$#x;
        $return{'options'}{'cost'} += 0;
    }
    
    return %return;
}

=head2 password_hash ( $password, $algo, %options )

Creates a password hash

Use the constant C<PASSWORD_DEFAULT> for the current default algorithm which is
C<PASSWORD_BCRYPT>.
Per default a cost of 14 will be used and a secure salt will be generated.

=cut

sub password_hash {
    my $password = shift;
    my $algo = shift;
    my %options = @_;
    
    if (not defined $password) {
        carp 'password_hash(): Password must be supplied';
        return;
    }
    
    if (not defined $algo) {
        $algo = PASSWORD_DEFAULT;
    }

    # parse options
    if ($algo == PASSWORD_BCRYPT) {
                
        # get cost
        if (not exists $options{'cost'} or $options{'cost'} =~ /\D/ or 0+$options{'cost'} < 4) {
            $options{'cost'} = 14;
        } else {
            $options{'cost'} = 0+$options{'cost'};
        }
        
        # get/generate salt
        if (not exists $options{'salt'}) {
            $options{'salt'} = rand_bits(128);
        } elsif ($options{'salt'} !~ m#\A[\x00-\xff]{16}\z#) {
            carp 'password_hash(): Provided salt needs to have 16 octets';
            return;
        }
        
        # hash password
        $password = bcrypt_hash({
            'key_nul' => 1,
            'cost' => $options{'cost'},
            'salt' => $options{'salt'},
        }, $password);
        
        return sprintf('$2y$%02d$%s%s', $options{'cost'}, en_base64($options{'salt'}), en_base64($password));
        
    } else {
        carp sprintf('password_hash(): Unknown password hashing algorithm: %s', $algo);
        return;
    }
}

=head2 password_needs_rehash ( $hash, $algo, %options )

Checks if the given hash matches the given options

=cut

sub password_needs_rehash {
    my $hash = shift;
    my $algo = shift;
    my %options = @_;
    
    if (not defined $hash) {
        carp 'password_needs_rehash(): Hash must be supplied';
        return;
    }
    
    if (not defined $algo or $algo =~ /\D/) {
        carp 'password_needs_rehash(): Algo must be supplied';
        return;
    }
    
    my %info = password_get_info($hash);
    if ($info{'algo'} != $algo) {
        return 1;
    }
    
    if ($info{'algo'} == PASSWORD_BCRYPT) {
        my $cost = 14;
        if (exists $options{'cost'}) {
            $cost = 0+$options{'cost'};
        }
        
        if ($cost != $info{'options'}{'cost'}) {
            return 1;
        }
    }
    
    return 0;
}

=head2 password_verify ( $password, $hash )

Verifies that a password matches a hash

=cut

sub password_verify {
    my ($password, $hash) = @_;
    
    if (not defined $password) {
        carp 'password_verify(): Password must be supplied';
        return;
    } elsif (not defined $hash) {
        carp 'password_verify(): Hash must be supplied';
        return;
    }
    
    if (not _is_bcrypt($hash)) {
        carp 'password_verify(): Unsupported password hashing algorithm';
        return;
    }
    
    $hash =~ m#\A\$2y\$([0-9]{2})\$([./A-Za-z0-9]{22})([./A-Za-z0-9]{31})\z#x;
    my ($p_cost, $p_salt_base64, $p_hash_base64) = ($1, $2, $3);
    
    $password = bcrypt_hash({
        'key_nul' => 1,
        'cost' => $p_cost,
        'salt' => de_base64($p_salt_base64),
    }, $password);
    
    return $password eq de_base64($p_hash_base64);
    
}

sub _is_bcrypt {
    my $hash = shift;
    if (substr($hash, 0, 4) eq '$2y$' and length($hash) == 60) {
        return 1;
    }
    return 0;
}

=head1 AUTHOR

Günter Grodotzki E<lt>guenter@perlhipster.comE<gt>

=head1 BUGS

Please report any bugs or feature requests via L<Github|https://github.com/lifeofguenter/p5-passwords/issues>

=head1 ACKNOWLEDGEMENTS

This package is not a new invention, everything needed was already out there.
To avoid confusion, especially to newer developers this offers a dead simple
wrapper on a easy to remember namespace. Additionally this package is compatible
with PHP (and most likely other languages) which makes it a great addition on
multi-lang plattforms.

Therefore props go to:

=over 3

=item * crypt_blowfish

L<http://www.openwall.com/crypt/>

=item * Andrew Main (ZEFRAM)

L<Crypt::Eksblowfish::Bcrypt> L<Authen::Passphrase::BlowfishCrypt> 

=item * Anthony Ferrara (ircmaxell)

L<https://github.com/ircmaxell>

=back


=head1 LICENSE AND COPYRIGHT

Copyright (C) 2014 Günter Grodotzki.

This [library|program|code|module] is free software; you
can redistribute it and/or modify it under the same terms
as Perl 5.10.0. For more details, see the full text of the
licenses in the file LICENSE.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

1; # End of Passwords
