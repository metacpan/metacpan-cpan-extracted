# DESCRIPTION

This module tries to implement [OWASP](https://owasp.org) password
recommendations for safe storage in Perl. In short OWASP recommends the
following:

- Don't limit password length or characters
- Hash the password before you crypt them (deprecated)
- Use either Argon2, PBKDF2, Scrypt or Bcrypt

This module currently supports Argon2, Scrypt and Bcrypt. All implementations
hash the password first with SHA-512. SHA-256 and SHA-1 are also supported.
This allows for storing password which are longer that 72 characters. OWASP now
recommends against this. This module will move away from prehashing.
In order to allow for a transition the default will stay, but emit a
deprecation warning. You can now set `none` as a hashing option. This will
become the new default.

The check\_password method allows for weaker schemes as the module also allows
for inplace updates on these passwords. Please note that clear text passwords
need to be prepended with `{CLEARTEXT}` in order for [Authen::Passphrase](https://metacpan.org/pod/Authen%3A%3APassphrase) to
do its work.

# SYNOPSIS

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

# SEE ALSO

- [Password::OWASP::Argon2](https://metacpan.org/pod/Password%3A%3AOWASP%3A%3AArgon2)
- [Password::OWASP::Scrypt](https://metacpan.org/pod/Password%3A%3AOWASP%3A%3AScrypt)
- [Password::OWASP::Bcrypt](https://metacpan.org/pod/Password%3A%3AOWASP%3A%3ABcrypt)
- [OWASP cheatsheet for password storage](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md)
- [OWASP cheatsheet for authentication storage](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Authentication_Cheat_Sheet.md)
- [Authen::Passphrase](https://metacpan.org/pod/Authen%3A%3APassphrase)
- [Authen::Passphrase::Argon2](https://metacpan.org/pod/Authen%3A%3APassphrase%3A%3AArgon2)
- [Authen::Passphrase::Scrypt](https://metacpan.org/pod/Authen%3A%3APassphrase%3A%3AScrypt)
- [Authen::Passphrase::BlowfishCrypt](https://metacpan.org/pod/Authen%3A%3APassphrase%3A%3ABlowfishCrypt)
