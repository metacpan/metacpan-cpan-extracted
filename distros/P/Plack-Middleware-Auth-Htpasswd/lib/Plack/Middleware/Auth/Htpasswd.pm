package Plack::Middleware::Auth::Htpasswd;
BEGIN {
  $Plack::Middleware::Auth::Htpasswd::VERSION = '0.02';
}
use strict;
use warnings;
use base 'Plack::Middleware::Auth::Basic';
use Plack::Util::Accessor qw(file file_root);
use Plack::Request;

use Authen::Htpasswd;
use MIME::Base64;
use Path::Class ();

# ABSTRACT: http basic authentication through apache-style .htpasswd files


sub prepare_app {
    my $self = shift;
    $self->authenticator(sub { $self->authenticate(@_) });
    die "must specify either file or file_root"
        unless defined $self->file || $self->file_root;
    return $self->SUPER::prepare_app;
}

sub _check_password {
    my $self = shift;
    my ($file, $user, $pass) = @_;
    my $htpasswd = Authen::Htpasswd->new($file);
    my $htpasswd_user = $htpasswd->lookup_user($user);
    return unless $htpasswd_user;
    return $htpasswd_user->check_password($pass);
}

sub authenticate {
    my $self = shift;
    my ($user, $pass, $env) = @_;

    return $self->_check_password($self->file, $user, $pass)
        if defined $self->file;

    my $path = Plack::Request->new($env)->path;
    my $dir = Path::Class::Dir->new($self->file_root);
    my @htpasswd = $path ne '/'
        ? reverse
          map { $_->file('.htpasswd')->stringify }
          map { $dir = $dir->subdir($_) }
          split m{/}, $path
        : ($dir->file('.htpasswd')->stringify);

    for my $htpasswd (@htpasswd) {
        next unless -f $htpasswd && -r _;
        return $self->_check_password($htpasswd, $user, $pass);
    }

    return;
}


1;

__END__
=pod

=head1 NAME

Plack::Middleware::Auth::Htpasswd - http basic authentication through apache-style .htpasswd files

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Plack::Builder;
  my $app = sub { ... };

  builder {
      enable "Auth::Htpasswd", file => '/path/to/.htpasswd';
      $app;
  };

or

  builder {
      enable "Auth::Htpasswd", file_root => '/path/to/my/static/files';
      $app;
  };

=head1 DESCRIPTION

This middleware enables HTTP Basic authenication, based on the users in an
L<Apache-style htpasswd file|http://httpd.apache.org/docs/2.0/programs/htpasswd.html>.
You can either specify the file directly, through the C<file> option, or use
the C<file_root> option to specify the root directory on the filesystem that
corresponds to the web application root. This second option is more useful when
using an app that is closely tied to the filesystem, such as
L<Plack::App::Directory>. If C<file_root> is used, the requested path will be
inspected, and a file named C<.htpasswd> will be checked in each containing
directory, up to the C<file_root>. The first one found will be used to validate
the requested user.

=head1 CONFIGURATION

=head2 file

Name of a .htpasswd file to read authentication information from. Required if
C<file_root> is not set.

=head2 file_root

Path to the on-disk directory that corresponds to the root URL path of the app.
Required C<file> is not set, and ignored if C<file> is set.

=head2 realm

Realm name to display in the basic authentication dialog. Defaults to
'restricted area'.

=head1 CREDITS

Large parts of this code were modeled after (read: stolen from)
L<Plack::Middleware::Auth::Basic> by Tatsuhiko Miyagawa.

=for Pod::Coverage   authenticate

=head1 BUGS

No known bugs.

Please report any bugs through RT: email
C<bug-plack-middleware-auth-htpasswd at rt.cpan.org>, or browse to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Middleware-Auth-Htpasswd>.

=head1 SEE ALSO

=over 4

=item *

L<Plack>

=item *

L<Plack::Middleware::Auth::Basic>

=back

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Plack::Middleware::Auth::Htpasswd

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Middleware-Auth-Htpasswd>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Middleware-Auth-Htpasswd>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Middleware-Auth-Htpasswd>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Middleware-Auth-Htpasswd>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

