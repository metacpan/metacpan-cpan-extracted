package Mojolicious::Command::bcrypt;
use Mojo::Base 'Mojolicious::Command';
use Crypt::Eksblowfish::Bcrypt ();
use Crypt::URandom ();
use Mojo::Util ();

our $VERSION = '0.03';

has description => 'bcrypt a password using the settings in your Mojolicious app.';

has usage => sub { shift->extract_usage };

sub run {
    my ($self, $password, @args) = @_;
    die $self->usage unless defined $password;

    Mojo::Util::getopt(
        \@args,
        'c|cost=i' => \my $cost,
        'nkn|no-key-nul' => \my $no_key_nul,
        's|salt=s' => \my $salt,
    ) or die 'Error parsing options';
    die "unknown args passed: @{[join ', ', map qq{'$_'}, @args]}" if @args;

    if (grep defined, $cost, $no_key_nul, $salt) {
        if (defined $cost) {
            die 'cost must be between 1 and 99' unless defined $cost and $cost =~ /^\d{1,2}$/ and $cost > 0;
        } else {
            $cost = 12;
        }

        unless ($salt) {
            $salt = Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::URandom::urandom(16));
        }

        my $nul = $no_key_nul ? '' : 'a';

        say Crypt::Eksblowfish::Bcrypt::bcrypt($password, join '', '$2', $nul, sprintf('$%02i', $cost), '$', $salt);
    } else {
        say $self->app->bcrypt($password);
    }
}

1;
__END__

=encoding utf-8

=head1 NAME

Mojolicious::Command::bcrypt - bcrypt a password using the settings in your Mojolicious app.

=head1 STATUS

=for html <a href="https://travis-ci.org/srchulo/Mojolicious-Command-bcrypt"><img src="https://travis-ci.org/srchulo/Mojolicious-Command-bcrypt.svg?branch=master"></a>

=head1 SYNOPSIS

  Usage: myapp.pl bcrypt password [OPTIONS]

  NOTE: If no options are provided, the bcrypt helper installed on your app will
  be used to generate the crypted text. See Mojolicious::Plugin::BcryptSecure for more info.

  Options:
    -c, --cost           Uses this cost instead of the one used in your application. Must be an integer between 1 and 99. Default is 12.
    -nkn, --no-key-nul   Flag that specifies that NUL should not be appended to the password before using it as a key. Default is to append NUL.
                         If an empty password is provided, NUL must be appended and will be by Crypt::Eksblowfish::Bcrypt.
    -s, --salt           22 base 64 digits. Default is Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::URandom::urandom(16))

  # output password with your app's bcrypt helper and settings
  ./myapp.pl bcrypt password

  # output password not using a bcrypt helper by providing custom settings
  ./myapp.pl bcrypt password --c 8
  ./myapp.pl bcrypt password --cost 8

  # do not append a NUL before the password (not recommended)
  ./myapp.pl bcrypt password --nkn
  ./myapp.pl bcrypt password --no-key-nul

  # provide your own salt
  ./myapp.pl bcrypt password --s YndOHub.EV9Y37VeobUeSu
  ./myapp.pl bcrypt password --salt YndOHub.EV9Y37VeobUeSu

  # combine options
  ./myapp.pl bcrypt password --c 8 --nkn --s YndOHub.EV9Y37VeobUeSu

=head1 DESCRIPTION

L<Mojolicious::Command::bcrypt> allows you to crypt a password using C<bcrypt> via a L<Mojolicious::Command>.

If you are using a L<Mojolicious::Plugin> like L<Mojolicious::Plugin::BcryptSecure> or L<Mojolicious::Plugin::Bcrypt> that installs a
C<bcrypt> helper, then this helper along with any settings you provided the plugin will be used to generate the crypted text:

  # crypt using bcrypt helper
  ./myapp.pl bcrypt password

If you provide any L</OPTIONS>, the C<bcrypt> helper (if present) will be ignored, and crypted text will be generated from the provided
L</OPTIONS> and any defaults:

  ./myapp.pl bcrypt password --cost 8

=head1 COMMAND OPTIONS

=head2 --cost

A non-negative integer with at most two digits that controls the cost of the hash function.
The number of operations is proportional to 2^cost. The default value is 12.
This option is described more in L<Crypt::Eksblowfish::Bcrypt>.

  ./myapp.pl bcrypt password --cost 8

  # short option
  ./myapp.pl bcrypt password --c 8

=head2 --no-key-nul

If present, a NUL is not appended to the password before it is used as a key. The default is to append a NUL and this flag is not recommended.
This option is described more in L<Crypt::Eksblowfish::Bcrypt>.

  ./myapp.pl bcrypt password --no-key-nul

  # short option
  ./myapp.pl bcrypt password --nkn

=head2 --salt

22 base 64 digits that will be used as the salt. The default is C<Crypt::Eksblowfish::Bcrypt::en_base64(Crypt::URandom::urandom(16))>.
This option is described more in L<Crypt::Eksblowfish::Bcrypt>.

  ./myapp.pl bcrypt password --salt YndOHub.EV9Y37VeobUeSu

  # short option
  ./myapp.pl bcrypt password --s YndOHub.EV9Y37VeobUeSu

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

L<Mojolicious::Plugin::BcryptSecure>

=item

L<Crypt::Eksblowfish::Bcrypt>

=item

L<Crypt::URandom>

=item

L<Mojolicious::Plugin::Bcrypt>

=back

=cut
