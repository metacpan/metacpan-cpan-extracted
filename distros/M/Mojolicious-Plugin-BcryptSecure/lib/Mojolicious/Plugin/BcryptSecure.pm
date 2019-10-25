package Mojolicious::Plugin::BcryptSecure;
use Mojo::Base 'Mojolicious::Plugin';
use Crypt::Eksblowfish::Bcrypt ();
use Crypt::URandom ();

our $VERSION = '0.02';

sub register {
    my (undef, $app, $config) = @_;

    my $cost;
    if (exists $config->{cost}) {
        $cost = delete $config->{cost};
        Carp::confess 'cost must be a positive int <= 99' unless defined $cost and $cost =~ /^\d{1,2}$/ and $cost > 0;
    } else {
        $cost = 12;
    }

    Carp::confess 'Unknown keys/values provided: ' . Mojo::Util::dumper $config if %$config;

    my $settings_without_salt = '$2a' . sprintf '$%02i', $cost;
    $app->helper(bcrypt => sub {
        return Crypt::Eksblowfish::Bcrypt::bcrypt(
            $_[1],
            $_[2] // $settings_without_salt . '$' . Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::URandom::urandom(16)),
        );
    });

    $app->helper(bcrypt_validate => sub {
        return Mojo::Util::secure_compare Crypt::Eksblowfish::Bcrypt::bcrypt($_[1], $_[2]), $_[2];
    });
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Plugin::BcryptSecure - Securely bcrypt and validate your passwords.

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Plugin-BcryptSecure"><img src="https://travis-ci.org/srchulo/Mojolicious-Plugin-BcryptSecure.svg?branch=master"></a>

=head1 SYNOPSIS

  # Mojolicious::Lite

  # use the default cost of 12
  plugin 'BcryptSecure'

  # set your own cost
  plugin BcryptSecure => { cost => 8 };

  # Mojolicious

  sub startup {
    my $self = shift;

    # use the default cost of 12
    $self->plugin('BcryptSecure');

    # set your own cost
    $self->plugin('BcryptSecure', { cost => 8 })
  }

=head1 DESCRIPTION

L<Mojolicious::Plugin::BcryptSecure> is a fork of L<Mojolicious::Plugin::Bcrypt> with two main differences:

=over

=item

L<Crypt::URandom> is used to generate the salt used in L</bcrypt> with strongest available source of non-blocking randomness on the current platform.

=item

L<Mojo::Util/secure_compare> is used in L</bcrypt_validate> when comparing the crypted passwords to
help prevent timing attacks.

=back

You also may want to look at L<Mojolicious::Command::bcrypt> to help easily generate crypted passwords
with your app's C<bcrypt> settings via a L<Mojolicious::Command>.

=head1 OPTIONS

=head2 cost

A non-negative integer with at most two digits that controls the cost of the hash function.
The number of operations is proportional to 2^cost. The default value is 12.
This option is described more in L<Crypt::Eksblowfish::Bcrypt>.

  # Mojolicious::Lite
  plugin BcryptSecure => { cost => 8 };

  # Mojolicious
  sub startup {
    my $self = shift;

    $self->plugin('BcryptSecure', { cost => 8 })
  }

=head1 HELPERS

=head2 bcrypt

Crypts a password via the bcrypt algorithm and returns the resulting crypted value.

  my $crypted_password = $c->bcrypt($plaintext_password);

  # optionally pass your own settings
  my $crypted_password = $c->bcrypt($plaintext_password, $settings);

C<$settings> is an optional string which encodes the algorithm parameters, as described in L<Crypt::Eksblowfish::Bcrypt>.

=head2 bcrypt_validate

Validates a password against a crypted password (from your database, for example):

  if ($c->bcrypt_validate($plaintext_password, $crypted_password)) {
      # Authenticated
  } else {
      # Uh oh...
  }

=head1 AUTHOR

Adam Hopkins E<lt>srchulo@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2019- Adam Hopkins

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=over

=item

L<Mojolicious::Command::bcrypt>

=item

L<Crypt::Eksblowfish::Bcrypt>

=item

L<Crypt::URandom>

=item

L<Mojolicious::Plugin::Bcrypt>

=back

=cut
