package Password::OWASP::Argon2;
our $VERSION = '0.005';
use Moose;

# ABSTRACT: An Argon2 implemenation of Password::OWASP

with 'Password::OWASP::AbstractBase';

use Authen::Passphrase::Argon2;

sub ppr { 'Authen::Passphrase::Argon2' };

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OWASP::Argon2 - An Argon2 implemenation of Password::OWASP

=head1 VERSION

version 0.005

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
