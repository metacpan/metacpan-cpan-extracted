package Nagios::NSCA::Encrypt;
use strict;
use warnings;
use base 'Nagios::NSCA::Base';
use constant DEFAULT_ENCRYPTION_ALGORITHM => 'NONE';
use constant DEFAULT_ENCRYPTION_KEY => "";

our $VERSION = sprintf("%d", q$Id: Encrypt.pm,v 1.2 2006/04/10 22:39:38 matthew Exp $ =~ /\s(\d+)\s/);

### CLASS METHODS ###

sub new {
    my ($class, %args) = @_;
    my $fields = {
        iv => undef,
        key => DEFAULT_ENCRYPTION_KEY,
        algorithm => DEFAULT_ENCRYPTION_ALGORITHM,
    };
    my $self = $class->SUPER::new(%args);
    $self->_initFields($fields);

    # Set arguments passed in to the constructor
    $self->iv($args{iv});
    $self->key($args{key});
    $self->algorithm($args{algorithm});

    return $self;
}

sub hasMcrypt {
    my $class = shift;
    eval { require Mcrypt };
    return($@ ? 0 : 1);
}

sub numberToName {
    my ($class, $number) = @_;

    # Make sure we have a number
    if (not defined $number or $number !~ /^\d+$/) {
        $number ||= "undef";
        die "Invalid encryption number: $number\n";
    }

    my @map = $class->listAlgorithms();
    my $name = $map[$number];

    if (not $name or $name eq 'NOT_IMPLEMENTED') {
        die "Invalid encryption number: $number\n";
    }

    return $name;
}

sub listAlgorithms {
    return qw(NONE XOR DES 3DES CAST_128 CAST_256 XTEA 3WAY BLOWFISH TWOFISH
              LOKI97 RC2 ARCFOUR NOT_IMPLEMENTED RIJNDAEL_128 RIJNDAEL_192
              RIJNDAEL_256 NOT_IMPLEMENTED NOT_IMPLEMENTED WAKE SERPENT
              NOT_IMPLEMENTED ENIGMA GOST SAFER_SK64 SAFER_SK128 SAFERPLUS);
}

sub _algorithmIsListed {
    my ($class, $algorithm) = @_;

    # NOT_IMPLEMENTED is a special sentinal value to act as a place holder in
    # an array.  Disallow it as a legal type.
    return 0 if not $algorithm or $algorithm eq 'NOT_IMPLEMENTED';

    # See if the algorithm is listed.
    my %map = map {$_ => 1} $class->listAlgorithms;
    return exists $map{$algorithm};
}

sub hasAlgorithm {
    my ($class, $algorithm) = @_;

    # Make sure that algorithm is listed as a valid algorithm.  This doesn't
    # mean it works, however.
    return 0 if not $class->_algorithmIsListed($algorithm);

    # Just b/c it's listed doesn't mean Mcrypt was compiled with it, so test
    # that.  NONE and XOR are special non-Mcrypt encryption types.
    if ($algorithm ne 'NONE' and $algorithm ne 'XOR') {
        eval { $class->_getMcryptObject($algorithm) };
        return 0 if $@;
    }

    return 1;
}

### Accessors ###

sub encrypt {
    my ($self, $data) = @_;
    my $result;

    if ($self->algorithm eq 'NONE') {
        $result = $data;
    } elsif ($self->algorithm eq 'XOR') {
        $result = $self->_encryptXOR($data);
    } else {
        my $encrypter = $self->_makeEncrypter();
        $result = $encrypter->encrypt($data);
    }

    return $result;
}

sub decrypt {
    my ($self, $data) = @_;
    my $result;

    if ($self->algorithm eq 'NONE') {
        $result = $data;
    } elsif ($self->algorithm eq 'XOR') {
        $result = $self->_decryptXOR($data);
    } else {
        my $encrypter = $self->_makeEncrypter();
        $result = $encrypter->decrypt($data);
    }

    return $result;
}

### Private Methods ###

sub _encryptXOR {
    my ($self, $data) = @_;
    warn "XOR unimplemented.\n";
    return $data;
}

sub _decryptXOR {
    my ($self, $data) = @_;
    warn "XOR unimplemented.\n";
    return $data;
}

sub _getMcryptObject {
    my ($self, $algorithm) = @_;
    my $td;

    # Make sure we have Mcrypt and the algorithm is an Mcrypt algorithm, the
    # NONE and XOR types are legal but aren't implemented via Mcrypt.
    if (not $self->hasMcrypt()) {
        die "The Perl Mcrypt library does not appear to be installed.\n";
    } elsif (not $self->_algorithmIsListed($algorithm)) {
        $algorithm ||= "undef";
        die "Algorithm \"$algorithm\" is not known.\n";
    } elsif ($algorithm eq 'NONE' or $algorithm eq 'XOR') {
        die "Algorithm \"$algorithm\" is internal and not implemented by " .
            "Mcrypt.\n";
    }

    # Load up the library and try and create the object.
    require Mcrypt;
    no strict 'refs';  # So we can load up the algorithm symbolically
    my $algo = "Mcrypt::$algorithm";
    eval {
        $td = Mcrypt->new(algorithm => &$algo,
                          mode => &Mcrypt::CFB, 
                          verbose => 0);
    };

    if (not $td or $@) {
        die "Mcrypt failed to load.  Was $algorithm compiled into Mcrypt?\n";
    }

    return $td;
}

sub _makeEncrypter {
    my $self = shift;

    # Load up Mcrypt and create the object.
    my $td = $self->_getMcryptObject($self->algorithm);

    # Possibly shorten the given IV and key to the desired size.
    my $iv = substr($self->iv, 0, $td->{IV_SIZE});
    my $key = substr($self->key, 0, $td->{KEY_SIZE});
    $td->init($key, $iv);

    return $td;
}

1;
