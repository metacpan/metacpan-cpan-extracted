package Mojolicious::Plugin::Passphrase;
$Mojolicious::Plugin::Passphrase::VERSION = '0.003';
use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use Crypt::Passphrase;

sub register {
	my (undef, $app, $config) = @_;

	my $passphrase = Crypt::Passphrase->new(%{$config});

	$app->helper(hash_password => sub {
		my ($c, @args) = @_;
		return $passphrase->hash_password(@args);
	});

	$app->helper(verify_password => sub {
		my ($c, @args) = @_;
		return $passphrase->verify_password(@args);
	});

	$app->helper(password_needs_rehash => sub {
		my ($c, @args) = @_;
		return $passphrase->needs_rehash(@args);
	});

	return;
}

1;


#ABSTRACT: Securely hash and validate your passwords.

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Plugin::Passphrase - Securely hash and validate your passwords.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 # Mojolicious::Lite

 # set your own cost
 plugin Passphrase => { encoder => 'Argon2' };

 # Mojolicious

 sub startup {
   my $self = shift;

   $self->plugin(Passphrase => { encoder => 'Argon2' });
 }

=head1 DESCRIPTION

This module plugs L<Crypt::Passphrase|Crypt::Passphrase> into your Mojolicious application. It takes a C<Crypt::Passphrase> configuration as its configuration and exposes its methods as helpers. This way it allows you to define a single scheme that will be used for new passwords, but several schemes to check passwords against. It will be able to tell you if you should rehash your password, not only because the scheme is outdated, but also because the desired parameters have changed.

=head1 HELPERS

=head2 hash_password

Crypts a password via the encoder algorithm and returns the resulting crypted value.

 my $crypted_password = $c->hash_password($plaintext_password);

=head2 verify_password

Validates a password against a crypted password (from your database, for example):

 if ($c->verify_password($plaintext_password, $crypted_password)) {
   # Authenticated
 } else {
   # Uh oh...
 }

=head2 password_needs_rehash

Checks if a hash needs rehashing.

 if ($c->verify_password($plaintext_password, $crypted_password)) {
   if ($c->password_needs_rehash($crypted_password)) {
     my $new_hash = $c->hash_password($plaintext_password);
     # store new hash to the database
   }
 }

=head1 SEE ALSO

=over

=item * L<DBIx::Class::CryptColumn|DBIx::Class::CryptColumn>

=item * L<Mojolicious::Plugin::BcryptSecure|<Mojolicious::Plugin::BcryptSecure>

=back

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
