package Password::OWASP::Argon2;
our $VERSION = '0.004';
use Moose;

# ABSTRACT: An Argon2 implemenation of Password::OWASP

with 'Password::OWASP::AbstractBaseX';

use Try::Tiny;

use Authen::Passphrase::Argon2;

sub crypt_password {
    my ($self, $pass) = @_;

    my $ppr = Authen::Passphrase::Argon2->new(
        cost        => $self->cost,
        salt_random => 1,
        passphrase  => $self->hash_password($pass),
    );
    return $ppr->as_rfc2307;
}

sub check_password {
    my ($self, $given, $want) = @_;

    my $ok = try {
        my $ppr = Authen::Passphrase::Argon2->from_rfc2307($want);
        return 1 if $ppr->match($self->hash_password($given));
        return 0;
    };
    return 1 if $ok;
    return 1 if $self->check_legacy_password($given, $want);
    return 0;
};

around check_legacy_password => sub {
    my ($orig, $self, $given, $want) = @_;

    my $ok = try {
        my $ppr = Authen::Passphrase::Argon2->from_rfc2307($want);
        return $ppr->match($given);
    };
    if ($ok) {
        $self->update_password($given) if $self->has_update_method;
        return 1;
    }

    return $orig->($self, $given, $want);

};

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OWASP::Argon2 - An Argon2 implemenation of Password::OWASP

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package MyApp::Authentication;

    use Password::OWASP::Argon2;

    my $user = get_from_db();
    my $from_web = "Super secret password";

    my $owasp = Password::OWASP::Argon2->new(
        # optional
        hashing => 'sha512',
        update_method => sub {
            my $password = shift;
            $user->update_password($password);
            return;
        },
    );

    if (!$owasp->check_password($from_web)) {
        die "You cannot login";
    }

=head1 DESCRIPTION

Implements Argon2 password checking.

=head1 METHODS

=head2 crypt_password

Encrypt the password and return it as an RFC2307 formatted string.

=head2 check_password

Check if the password is the same as what was stored.

=head1 SEE ALSO

=over

=item * L<Password::OWASP::AbstractBase>

=item * L<Authen::Passphrase::BlowfishCrypt>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
