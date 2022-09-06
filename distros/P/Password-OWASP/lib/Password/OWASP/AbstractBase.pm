package Password::OWASP::AbstractBase;
our $VERSION = '0.005';
use Moose::Role;
use namespace::autoclean;

# ABSTRACT: Abstract base class to implement OWASP password recommendations

use Authen::Passphrase;
use Digest::SHA;
use Moose::Util::TypeConstraints qw(enum);
use Try::Tiny;

requires qw(ppr);

has cost => (
    is      => 'ro',
    isa     => 'Int',
    default => 12,
);

has hashing => (
    is      => 'ro',
    isa     => enum([qw(sha1 sha256 sha512 none sha384 sha224)]),
    lazy    => 1,
    builder => '_build_hashing_default',
);

has update_method => (
    is        => 'ro',
    isa       => 'CodeRef',
    predicate => 'has_update_method',
);

sub crypt_password {
    my $self = shift;
    my $pass = shift;
    my $ppr = $self->ppr->new(
        cost        => $self->cost,
        salt_random => 1,
        passphrase  => $self->prehash_password($pass),
    );
    return $ppr->as_rfc2307;
}

sub check_password {
    my $self  = shift;
    my $given = shift;
    my $want  = shift;

    my $ok = try {
        my $ppr = $self->ppr->from_rfc2307($want);
        return 1 if $ppr->match($self->prehash_password($given));
    };
    return 1 if $ok;
    return 1 if $self->check_legacy_password($given, $want);
    return 0;
}

sub check_legacy_password {
    my ($self, $given, $want) = @_;

    my $ok = try {
        my $ppr = $self->ppr->from_rfc2307($want);
        return 1 if $ppr->match($self->_prehash_password($given));
        return 1 if $ppr->match($given);
    };
    if ($ok) {
        $self->update_password($given);
        return 1;
    }

    $ok = try {
        my $ppr = Authen::Passphrase->from_rfc2307($want);
        return $ppr->match($given);
    };
    return 0 unless $ok;
    $self->update_password($given);
    return 1;
}

sub _build_hashing_default {
    my $self = shift;
    warn "DEPRECATION: Please supply a hashing default";
    return 'sha512';
}

sub prehash_password {
    my $self = shift;
    my $pass = shift;

    if ($self->hashing eq 'none') {
        return $pass;
    }

    my $sha = Digest::SHA->new($self->hashing);
    $sha->add($pass);
    return $sha->b64digest;
}

sub _prehash_password {
    my $self = shift;
    my $pass = shift;

    my $sha = Digest::SHA->new('sha512');
    $sha->add($pass);
    return $sha->b64digest;
}

sub hash_password {
    my $self = shift;
    warn "DEPRECATION: Please use prehash_password instead";
    return $self->prehash_password(@_);
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

Password::OWASP::AbstractBase - Abstract base class to implement OWASP password recommendations

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package Password::OWASP::MyThing;
    use Moose;

    with 'Password::OWASP::AbstractBase';

    use Authen::Passphrase::SomeThing

    # You need to implement this method
    sub ppr { 'Authen::Passphrase::SomeThing' }

=head1 DESCRIPTION

An abstract base class for modules that want to implement OWASP recommendations
for password storage.

This class implements the following methods and attributes.

=head2 ATTRIBUTES

=over

=item hashing

An enumeration of C<none>, C<sha1>, C<sha224>, C<sha256>, C<sha384>, C<sha512>.
The latter is the default. This default will change in the future to C<none>,
as the new OWASP policy states that prehashing is a security risk.  This is
used for the L<Password::OWASP::AbstractBase/prehash_password> function.

=item update_method

A code ref to update the password in your given store. The first argument is
the password that needs to be stored. Setting this value will also enable you
to update the password via L<Password::OWASP::AbstractBase/update_password>.

=back

=head1 METHODS

=head2 check_legacy_password

Check the password against the former password scheme, assuming it isn't a
password scheme that is understood by L<Authen::Passphrase> and the password
isn't hashed before it was stored.

In case the L<Password::OWASP::AbstractBase/update_method> was provided, the
password is updated in place.

=head2 update_password

Update the password if L<Password::OWASP::AbstractBase/update_method> was
provided.

=head2 prehash_password

Hash the password with the given sha. When hashing is set to C<none>, no hashing
wil be performed and the password is returned instead of the hash.

=head2 hash_password

DEPRECATED: This method will be removed in a future release, please use
L<Password::OWASP::AbstractBase/prehash_password> instead.

=head2 check_password

Check the password against the current password scheme

=head2 crypt_password

Crypt/hash the password for storage

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
