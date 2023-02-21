package Mojolicious::Command::passphrase;
$Mojolicious::Command::passphrase::VERSION = '0.003';
use Mojo::Base 'Mojolicious::Command';
use Crypt::Passphrase;
use Mojo::Util ();

has description => 'hash a password using the settings in your Mojolicious app.';

has usage => sub { shift->extract_usage };

sub run {
	my ($self, $password, @args) = @_;
	die $self->usage unless defined $password;

	say $self->app->hash_password($password);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mojolicious::Command::passphrase

=head1 VERSION

version 0.003

=head1 SYNOPSIS

Usage: myapp.pl passphrase <password>

 The passphrase helper installed on your app will be used to generate the
 crypted text. See Mojolicious::Plugin::Passphrase for more info.

 # output password with your app's passphrase helper and settings
 ./myapp.pl passphrase password

=head1 DESCRIPTION

L<Mojolicious::Command::passphrase> allows you to crypt a password using
C<Crypt::Passphrase> via a L<Mojolicious::Command>.

If you are using L<Mojolicious::Plugin::Passphrase>, then this helper along
with any settings you provided the plugin will be used to generate the crypted text:

  # crypt using passphrase helper
  ./myapp.pl passphrase password

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
