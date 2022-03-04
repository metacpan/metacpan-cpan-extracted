package MooX::Role::CryptedPassword;
use Moo::Role;

our $VERSION = '0.02';

use Crypt::CBC;
use constant CIPHER => 'Rijndael';
use constant CIPHER_KEY => 'BlahBlahBlahBlah';

has password => (
    is       => 'ro',
    isa      => sub { !ref $_[0] },
    required => 1
);

around BUILDARGS => sub {
    my $buildargs = shift;
    my $class = shift;
    my %args = @_;

    if (my $pwfile = delete($args{password_file})) {
        my $cipher_name = delete($args{cipher})     || CIPHER;
        my $cipher_key  = delete($args{cipher_key}) || CIPHER_KEY;

        use autodie;
        open my $fh, '<:raw', $pwfile;
        my $crypted_password = do {local $/; <$fh>};
        close($fh);

        my $cipher = Crypt::CBC->new(
            -cipher => $cipher_name,
            -key    => $cipher_key,
            -pbkdf => 'pbkdf2',
        );
        $args{password} = $cipher->decrypt($crypted_password);
    }

    $class->$buildargs(%args);
};

1;

__END__

=head1 NAME

MooX::Role::CryptedPassword - Password attribute from a encrypted file.

=head1 SYNOPSIS

Prepare:

    $ create_crypted_password --file-name etc/password.private \
                              --cipher-key 'This-is-the-cipher-key' \
                              --password 'This-is-a-nice-password'

Your class:

    package MyUserData;
    use Moo;
    with 'MooX::Role::CryptedPassword';

    has username => (is => 'ro', required => 1);

    ...

    1;

Somewhere else:

    my $ud = MyUserData->new(
        username => 'abeltje',

        password_file => 'etc/password.private',
        cipher_key    => 'This-is-the-cipher-key',
    );

=head1 ATTRIBUTES

=head2 password => $password

The decrypted version of the password found in the C<< password_file >> parameter.

=head1 DESCRIPTION

This role adds an attribute C<password> to your class. If the parameter
C<password_file> is passed, the contents are assumed to be encrypted with the
Rijndael cipher (and you should supply the C<cipher_key> argument).

Use the supplied C<< create_crypted_password >> tool to generate the file.

In case the password (for development reasons) doesn't need to be encrypted or
comes from a different source (like a key-value-store), one can always pass a
plain-text password directly by passing it as the C<password> parameter.

=head1 AUTHOR

E<copy> MMXVII - Abe Timmerman <abeltje@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut
