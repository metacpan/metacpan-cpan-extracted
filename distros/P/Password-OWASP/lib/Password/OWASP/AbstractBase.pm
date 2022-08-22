package Password::OWASP::AbstractBase;
our $VERSION = '0.004';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Abstract base class to implement OWASP password recommendations

use Authen::Passphrase;
use Digest::SHA;
use Moose::Util::TypeConstraints qw(enum);
use Try::Tiny;

with 'Password::OWASP::AbstractBaseX';

sub check_password {
    my ($self, $given, $want) = @_;
    my $ok = try {
        my $ppr = Authen::Passphrase->from_rfc2307($want);
        return 1 if $ppr->match($self->hash_password($given));
        return 0;
    };
    return 1 if $ok || $self->check_legacy_password($given, $want);
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OWASP::AbstractBase - Abstract base class to implement OWASP password recommendations

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package Password::OWASP::MyThing;
    use Moose;

    with 'Password::OWASP::AbstractBase';

    # You need to implement this method
    sub crypt_password {
        ...;
    }

=head1 DESCRIPTION

An abstract base class for modules that want to implement OWASP recommendations
for password storage.

This class implements the following methods and attributes.

=head2 ATTRIBUTES

=over

=item hashing

An enumeration of C<sha1>, C<sha256>, C<sha512>. The latter is the default.
This is used for the L<Password::OWASP::AbstractBase/hash_password> function.

=item update_method

A code ref to update the password in your given store. The first argument is
the password that needs to be stored. Setting this value will also enable you
to update the password via L<Password::OWASP::AbstractBase/update_password>.

=back

=head1 METHODS

=head2 check_password

Check the user password, returns true or false depending on the correctness of
the password. The password needs to be in a RFC2307 format.

=head2 check_legacy_password

Check the password against the former password scheme, assuming it isn't a
password scheme that is understood by L<Authen::Passphrase> and the password
isn't hashed before it was stored.

In case the L<Password::OWASP::AbstractBase/update_method> was provided, the
password is updated in place.

=head2 update_password

Update the password if L<Password::OWASP::AbstractBase/update_method> was
provided.

=head2 hash_password

Hash the password with the given sha.

=head1 SEE ALSO

=over

=item * L<Password::OWASP::AbstractBaseX>

=item * L<OWASP cheatsheet for password storage|https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Password_Storage_Cheat_Sheet.md>

=item * L<OWASP cheatsheet for authentication storage|https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Authentication_Cheat_Sheet.md>

=item * L<Authen::Passphrase>

=back

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
