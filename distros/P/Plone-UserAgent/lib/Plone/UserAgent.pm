package Plone::UserAgent;

use strict;
use warnings;

our $VERSION = '0.01';

use Config::INI::Reader;
use File::HomeDir;
use HTTP::Cookies;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::NonMoose;
use URI;

extends 'LWP::UserAgent';

has username =>
    ( is        => 'rw',
      isa       => 'Str',
      predicate => '_has_username',
      writer    => '_set_username',
    );

has password =>
    ( is        => 'rw',
      isa       => 'Str',
      predicate => '_has_password',
      writer    => '_set_password',
    );

my $uri = subtype as class_type('URI');
coerce $uri
    => from 'Str'
    => via { URI->new( $_ ) };

has base_uri =>
    ( is       => 'ro',
      isa      => $uri,
      required => 1,
      coerce   => 1,
    );

has config_file =>
    ( is      => 'ro',
      isa     => 'Str',
      lazy    => 1,
      default => sub { File::HomeDir->my_home() . '/.plone-useragentrc' },
    );

has _config_data =>
    ( is       => 'ro',
      isa      => 'HashRef',
      lazy     => 1,
      builder  => '_build_config_data',
      init_arg => undef,
    );


sub BUILD
{
    my $self = shift;

    unless ( $self->_has_username && $self->_has_password )
    {
        my $config = $self->_config_data();

        die 'Must provide a username and password or a valid config file'
            unless $config && $config->{'_'}{username} && $config->{'_'}{password};

        $self->_set_username( $config->{'_'}{username} );
        $self->_set_password( $config->{'_'}{password} );
    }

    $self->cookie_jar( HTTP::Cookies->new() )
        unless $self->cookie_jar();
}

sub FOREIGNBUILDARGS
{
    my $class = shift;
    my $args  = $class->BUILDARGS(@_);

    my %copy = %{ $args };

    delete @copy{ qw( base_uri username password config_file ) };

    return %copy;
}

sub _build_config_data
{
    my $self = shift;

    my $file = $self->config_file();

    return {} unless -f $file;

    return Config::INI::Reader->read_file($file) || {};
}

sub login
{
    my $self = shift;

    my $uri = $self->make_uri( '/login_form' );

    my $response =
        $self->post( $uri,
                     { __ac_name        => $self->username(),
                       __ac_password    => $self->password(),
                       came_from        => $self->base_uri(),
                       cookies_enabled  => q{},
                       'form.submitted' => 1,
                       js_enabled       => q{},
                       login_name       => q{},
                       submit           => 'Log in',
                     },
                   );

    die "Could not log in to $uri"
        unless $response->is_redirect();
}

sub make_uri
{
    my $self = shift;
    my $path = shift;

    my $uri = $self->base_uri()->clone();

    $uri->path( $uri->path() . $path );

    return $uri;
}

no Moose;

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Plone::UserAgent - An LWP agent with "logging into Plone" built-in

=head1 SYNOPSIS

    use Plone::UserAgent;

    my $ua =
        Plone::UserAgent->new
            ( username => 'foo',
              password => 'bar',
              base_uri => 'http://my.plone.site.example.com',
            );

    $ua->login();

    my $page_uri = $ua->make_uri( '/some/page' );

    my $response = $ua->get($page_uri);

=head1 DESCRIPTION

This module is a fairly trivial subclass of L<LWP::UserAgent> that
knows how to log in to a Plone site. It's been tested with 3.2.2.

Patches are welcome to add additional Plone-specific features (as long
as they're nice patches, not gross, ugly patches).

=head1 METHODS

This class provides these methods;

=head1 Plone::UserAgent->new( ... )

This method creates a new user agent object.

The constructor accepts the following parameters:

=over 4

=item * base_uri

The root URI of your Plone site. B<required>.

=item * username

The username to use when logging in to the site. B<required>, but see
below.

=item * password

The username to use when logging in to the site. B<required>, but see
below.

=item * config_file

An optional config file. This should be an INI config file. All that
is expected to be in the file is a username and password, with no
section header:

  username = foo
  password = bar

This defaults to F<$HOME/.plone-useragentrc>.

=back

The constructor requires a username and password, but if you don't
pass these , it will try to look them up the config file.

=head2 $ua->login()

Attempts to log in to the site. Throws an error if it fails.

=head2 $ua->make_uri($path)

Given a path, returns a URI based on the C<base_uri> passed to the
constructor. This is provided for convenience since it's used
internally.

=head1 AUTHOR

Dave Rolsky, E<gt>autarch@urth.orgE<lt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-plone-useragent@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 DONATIONS

If you'd like to thank me for the work I've done on this module,
please consider making a "donation" to me via PayPal. I spend a lot of
free time creating free software, and would appreciate any support
you'd care to offer.

Please note that B<I am not suggesting that you must do this> in order
for me to continue working on this particular software. I will
continue to do so, inasmuch as I have in the past, for as long as it
interests me.

Similarly, a donation made in this way will probably not make me work
on this software much more, unless I get so many donations that I can
consider working on free software full time, which seems unlikely at
best.

To donate, log into PayPal and send money to autarch@urth.org or use
the button on this page:
L<http://www.urth.org/~autarch/fs-donation.html>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
