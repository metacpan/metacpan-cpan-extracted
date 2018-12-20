package Protocol::DBus::Authn::Mechanism::DBUS_COOKIE_SHA1::Pieces;

use strict;
use warnings;

use File::Spec ();

use constant KEYRINGS_DIR => '.dbus-keyrings';

my $sha1_module;

sub _sha1_module {
    return $sha1_module ||= do {
        if ( eval { require Digest::SHA1; 1 } ) {
            'Digest::SHA1';
        }
        elsif ( eval { require Digest::SHA; 1 } ) {
            'Digest::SHA';
        }
        else {
            die "No SHA module available!";
        }
    };
}

sub create_challenge {
    my $cl_challenge = join(',', map { rand } 1 .. 4 );

    # Ensure that we use only hex characters for the challenge,
    # or else the challenge might have a colon, space, or something else
    # problematic.
   return sha1_hex($cl_challenge);
}

sub sha1_hex {
    return _sha1_module()->can('sha1_hex')->(@_);
}

sub get_cookie {
    my ($homedir, $ck_ctx, $ck_id) = @_;

    my $path = File::Spec->catfile(
        $homedir,
        KEYRINGS_DIR(),
        $ck_ctx,
    );

    open my $rfh, '<', $path or die "open(< $path): $!";

    while ( my $line = <$rfh> ) {
        chomp $line;

        next if 0 != index( $line, "$ck_id " );

        return substr( $line, 1 + index($line, q< >, 2 + length($ck_id)) );
    }

    warn "readline: $!" if $!;

    die "Failed to find cookie “$ck_id” in “$path”!";
}

1;
