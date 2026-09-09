package Punk::Command::SAML;

use 5.010;
use strict;
use warnings;

use Punk::SAML ();

sub run {
    my ($class, @argv) = @_;
    my $sub = shift(@argv) // '';
    my $m = $class->can("cmd_$sub");
    return $class->usage unless $m;
    return $class->$m(@argv);
}

sub usage {
    print <<'USAGE';
punk saml key                        a secret for the flow cookie
punk saml metadata                   this application's SP metadata
punk saml idp <file-or-url>          what this plugin reads from metadata
punk saml verify <file> [--at N]     run the checks over a saved Response
USAGE
    return 1;
}

sub cmd_key {
    require Crypt::JWS;
    print Crypt::JWS::b64url(Crypt::JWS::random_bytes(32)), "\n";
    return 0;
}

sub cmd_metadata {
    my ($class, %o) = @_;
    require Punk::SAML::Metadata;
    print Punk::SAML::Metadata->build(%o), "\n";
    return 0;
}

sub cmd_idp {
    my ($class, $src, @rest) = @_;
    return $class->usage unless defined $src;
    require Punk::SAML::IdP;
    my $bytes = _slurp($src);
    my %o = @rest;
    my $idp = eval { Punk::SAML::IdP->read($bytes, %o) };
    if (my $e = $@) {
        print ref $e ? "refused: $e->{code}: $e->{message}\n" : "refused: $e";
        return 1;
    }
    printf "entity_id  %s\n", $idp->{entity_id};
    printf "sso_url    %s\n", $idp->{sso_url};
    printf "signed     WantAuthnRequestsSigned=%s\n",
        $idp->{want_authn_requests_signed} ? 'true' : 'false';
    for my $i (0 .. $#{ $idp->{certs} }) {
        printf "cert %-2d    sha256:%s\n", $i, $idp->{fingerprints}[$i];
    }
    printf "nameid     %s\n", $_ for @{ $idp->{name_id_formats} };
    return 0;
}

sub cmd_verify {
    my ($class, $file, %o) = @_;
    return $class->usage unless defined $file;
    require Punk::SAML::Response;
    my $bytes = _slurp($file);
    # the base64 as it came, or the XML
    $bytes = Punk::SAML::_decode_field($bytes, 0)
        unless $bytes =~ /\A\s*</;
    my $at = delete $o{'--at'};
    my $id = eval {
        Punk::SAML::Response->verify($bytes, %o,
            ($at ? (now => $at) : ()));
    };
    if (my $e = $@) {
        print ref $e ? "refused: $e->{code}\n  $e->{message}\n" : "refused: $e";
        return 1;
    }
    printf "accepted\n  name_id  %s\n  idp      %s\n", $id->{name_id},
        $id->{idp} // '';
    for my $k (sort keys %{ $id->{attributes} }) {
        printf "  %-8s %s\n", $k, join ', ', @{ $id->{attributes}{$k} };
    }
    return 0;
}

sub _slurp {
    my ($src) = @_;
    $src =~ s{^file:}{};
    open my $fh, '<:raw', $src or die "Punk::SAML: $src: $!\n";
    local $/;
    return <$fh>;
}

1;

__END__

=head1 NAME

Punk::Command::SAML - the punk saml subcommands

=head1 DESCRIPTION

C<punk saml key>, C<punk saml metadata>, C<punk saml idp> and
C<punk saml verify>.

Perl rather than XS, and it stays that way: they run once, by hand, and
their whole job is printing.

=head2 punk saml key

A secret for the flow cookie. The plugin croaks for one at the C<plugin>
line and names this command, so the command exists.

=head2 punk saml metadata

This application's SP metadata, for the operator setting up the provider
with no server running.

=head2 punk saml idp <file-or-url>

Entity id, single sign-on URL, each certificate's fingerprint,
C<WantAuthnRequestsSigned> and the name id formats. What an operator runs
to see why a provider's metadata was refused, and what they paste into a
ticket to the provider's administrator.

=head2 punk saml verify <file>

Runs the phase-6 checks over a saved C<SAMLResponse>, the base64 as it
came or the XML, and prints the first refusal with its code. This is the
tool for the ticket that says "SSO stopped working": save the POST from
the browser's network tab, run this, and the answer is C<audience>.

C<--at> moves C<now>, so an assertion saved yesterday can be checked
today.

=head1 METHODS

=head2 run (@argv)

=head2 usage

=head2 cmd_key

=head2 cmd_metadata

=head2 cmd_idp

=head2 cmd_verify

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under the Artistic License 2.0.

=cut
