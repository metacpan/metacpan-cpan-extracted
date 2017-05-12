package Penguin::PGP;
$VERSION = 3.0;

use IPC::Open3;

sub new { 
    my ($class, %args) = @_;

    my $self = { };

    if ($args{'Binary'}) {
        $self->{'Binary'} = $args{'Binary'};
    } elsif (-e "/usr/bin/pgp") {
        $self->{'Binary'} = "/usr/bin/pgp";
    } elsif (-e "/usr/local/bin/pgp") {
        $self->{'Binary'} = "/usr/local/bin/pgp";
    } else {
        die "unable to find PGP binary";
    }

    bless $self, $class;
}

sub Sign {
    my ($self, %args) = @_;
    my $signedtext = "";
    my $errortext = "";

    $ENV{'PGPPASSFD'} = 0; # we'll send password as first line (see pgp src)

    my @PGPCMDLINE = ( $self->{'Binary'},
                    '+force',
                    '+batchmode',
                    '+verbose=1',
                    '-f',
                    '-s',
                    '-a',
                  );
    open3(\*IN, \*OUT, \*ERR, @PGPCMDLINE) || die "can't open pgp!";
    print IN $args{'Password'}, "\n";
    print IN $args{'Text'};
    close(IN);
    $save = $/;
    undef $/;
    $signedtext = <OUT>;
    close(OUT);
    $errortext = <ERR>;
    close(ERR);
    $/ = $save;
    if ($errortext =~ /Bad pass phrase/) {
        warn "bad pass phrase for keyring";
        return undef;
    }
    $signedtext;
}

sub Decrypt {
    my ($self, %args) = @_;
    my $cleartext = "";
    my $errortext = "";

    $ENV{'PGPPASSFD'} = 0; # we'll send password as first line (see pgp src)

    my @PGPCMDLINE = ( $self->{'Binary'},
                    '+force',
                    '+batchmode',
                    '+verbose=1',
                    '-f',
                  );
    open3(\*IN, \*OUT, \*ERR, @PGPCMDLINE) || die "can't open pgp!";
    print IN $args{'Password'}, "\n";
    print IN $args{'Text'};
    close(IN);
    $save = $/;
    undef $/;
    $cleartext = <OUT>;
    close(OUT);
    $errortext = <ERR>;
    close(ERR);
    $/ = $save;
    if ($errortext =~ /Bad pass phrase/) {
        warn "bad pass phrase for keyring";
        return undef;
    }
    if ($errortext =~ /Good signature from user "(.+)"/i) {
        $signer = $1;
    }
    return ( { Text => $cleartext,
               Signature => $signer,
             }
           );
}
1;
