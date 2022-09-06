package Password::OWASP::Bcrypt;
our $VERSION = '0.005';
use Moose;

# ABSTRACT: A BlowfishCrypt implemenation of Password::OWASP

with 'Password::OWASP::AbstractBase';

use Authen::Passphrase::BlowfishCrypt;

sub ppr { 'Authen::Passphrase::BlowfishCrypt' };

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Password::OWASP::Bcrypt - A BlowfishCrypt implemenation of Password::OWASP

=head1 VERSION

version 0.005

=head1 SYNOPSIS

    package MyApp::Authentication;

    use Password::OWASP::Bcrypt;

    my $user = get_from_db();
    my $from_web = "Some very secret password";

    my $owasp = Password::OWASP::Bcrypt->new(
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

Implements BlowfishCrypt password checking.

=head1 METHODS

=head2 crypt_password

Encrypt the password and return it as an RFC2307 formatted string.

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
