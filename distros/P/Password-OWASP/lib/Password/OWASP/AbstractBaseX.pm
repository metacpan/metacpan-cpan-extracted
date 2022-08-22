package Password::OWASP::AbstractBaseX;
our $VERSION = '0.004';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Abstract base class to implement OWASP password recommendations

use Authen::Passphrase;
use Digest::SHA;
use Moose::Util::TypeConstraints qw(enum);
use Try::Tiny;

requires qw(
    crypt_password
    check_password
);

has cost => (
    is      => 'ro',
    isa     => 'Int',
    default => 12,
);

has hashing => (
    is      => 'ro',
    isa     => enum([qw(sha1 sha256 sha512)]),
    default => 'sha512',
);

has update_method => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_update_method',
);

sub check_legacy_password {
    my ($self, $given, $want) = @_;
    my $ok = try {
        my $ppr = Authen::Passphrase->from_rfc2307($want);
        return $ppr->match($given);
    };
    return 0 unless $ok;
    $self->update_password($given) if $self->has_update_method;
    return 1;
}

sub hash_password {
    my ($self, $pass) = @_;
    my $sha = Digest::SHA->new($self->hashing);
    $sha->add($pass);
    return $sha->b64digest;
}

sub update_password {
    my ($self, $given) = @_;
    return 0 unless $self->has_update_method;
    $self->update_method->($self->crypt_password($given));
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OWASP::AbstractBaseX - Abstract base class to implement OWASP password recommendations

=head1 VERSION

version 0.004

=head1 SYNOPSIS

    package Password::OWASP::MyThing;
    use Moose;

    with 'Password::OWASP::AbstractBaseX';

    # You need to implement this method
    sub crypt_password {
        ...;
    }

    sub check_password {
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
This is used for the L<Password::OWASP::AbstractBaseX/hash_password> function.

=item update_method

A code ref to update the password in your given store. The first argument is
the password that needs to be stored. Setting this value will also enable you
to update the password via L<Password::OWASP::AbstractBaseX/update_password>.

=back

=head1 METHODS

=head2 check_legacy_password

Check the password against the former password scheme, assuming it isn't a
password scheme that is understood by L<Authen::Passphrase> and the password
isn't hashed before it was stored.

In case the L<Password::OWASP::AbstractBaseX/update_method> was provided, the
password is updated in place.

=head2 update_password

Update the password if L<Password::OWASP::AbstractBaseX/update_method> was
provided.

=head2 hash_password

Hash the password with the given sha.

=head1 SEE ALSO

=head2 OWASP

=over

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
