package Password::OWASP;
use warnings;
use strict;

our $VERSION = '0.002';

# ABSTRACT: OWASP recommendations for password storage in perl

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OWASP - OWASP recommendations for password storage in perl

=head1 VERSION

version 0.002

=head1 SYNOPSIS

    package MyApp::Authentication;

    use Password::OWASP::Scrypt; # or Bcrypt or Argon2

    my $user = get_from_db();

    my $owasp = Password::OWASP::Scrypt->new(

        # optional
        hashing => 'sha512',

        # Optional
        update_method => sub {
            my ($password) = @_;
            $user->update_password($password);
            return;
        },
    );

=head1 DESCRIPTION

This module tries to implement L<OWASP|https://owasp.org> password
recommendations for safe storage in Perl. In short OWASP recommends the
following:

=over

=item * Don't limit password length or characters

=item * Hash the password before you crypt them

=item * Use either Argon2, PBKDF2, Scrypt or Bcrypt

=back

This module currently supports Argon2, Scrypt and Bcrypt. All implementations
hash the password first with SHA-512. SHA-256 and SHA-1 are also supported.
This allows for storing password which are longer that 72 characters.

The check_password method allows for weaker schemes as the module also allows
for inplace updates on these passwords. Please note that clear text passwords
need to be prepended with C<{CLEARTEXT}> in order for L<Authen::Passphrase> to
do its work.

=head1 SEE ALSO

=over

=item * L<Password::OWASP::Argon2>

=item * L<Password::OWASP::Scrypt>

=item * L<Password::OWASP::Bcrypt>

=item * L<OWASP cheatsheet for password storage|https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md>

=item * L<OWASP cheatsheet for authentication storage|https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Authentication_Cheat_Sheet.md>

=item * L<Authen::Passphrase>

=item * L<Authen::Passphrase::Argon2>

=item * L<Authen::Passphrase::Scrypt>

=item * L<Authen::Passphrase::BlowfishCrypt>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
