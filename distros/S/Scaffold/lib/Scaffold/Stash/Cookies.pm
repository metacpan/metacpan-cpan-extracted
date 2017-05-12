package Scaffold::Stash::Cookies;

our $VERSION = '0.01';

use 5.8.8;
use CGI::Simple::Cookie;

use Scaffold::Class
  version  => $VERSION,
  base     => 'Scaffold::Base',
  utils    => 'self_params blessed',
  constants => 'HASH TRUE FALSE',
  messages => {
      badformat => "Attribute (cookies) does not pass the type constraint because: Vaidation failed for 'HASHREF' reference",
  }
;

use Data::Dumper;

# ----------------------------------------------------------------------
# Public Methods
# ----------------------------------------------------------------------

sub set {
    my ($self, $params) = self_params(@_);

    my $name = $params->{name};

    $self->{cookies}->{$name} = CGI::Simple::Cookie->new(
        -name  => $name,
        -value => $params->{value}
    );

    $self->{cookies}->{$name}->expires($params->{expires})   if defined($params->{expires});
    $self->{cookies}->{$name}->domain($params->{domain})     if defined($params->{name});
    $self->{cookies}->{$name}->path($params->{path})         if defined($params->{path});
    $self->{cookies}->{$name}->secure($params->{secure})     if defined($params->{secure});
    $self->{cookies}->{$name}->httponly($params->{httponly}) if defined($params->{httponly});

}

sub get {
    my ($self, $name) = @_;

    return keys %{ $self->{cookies} } if (! defined($name));

    if (exists($self->{cookies}->{$name})) {

        return $self->{cookies}->{$name};

    }

    return undef;

}

sub delete {
    my ($self, $name) = @_;

    if (exists($self->{cookies}->{$name})) {

        $self->{cookies}->{$name}->value("");
        $self->{cookies}->{$name}->expires("-1d");

        return TRUE;

    }

    return FALSE;

}

# ----------------------------------------------------------------------
# Private Methods
# ----------------------------------------------------------------------

sub init {
    my ($self, $config) = @_;

    $self->{config} = $config;

    my $req = $config->{request};

    # thank you HTTP::Session for this code...

    my $cookie_header = $ENV{HTTP_COOKIE} || (blessed($req) ? $req->header('Cookie') : $req->{HTTP_COOKIE});

    $self->{cookies} = CGI::Simple::Cookie->parse($cookie_header);

    return $self;

}

1;

__END__

=head1 NAME

Scaffold::Stash::Cookies - A stash of cookies

=head1 DESCRIPTION

This module handles a stash of CGI::Simple::Cookie objects.

=head1 METHODS

=over 4

=item delete

Marks the cookie for deletion. Returns TRUE on success.

 my $stat = $self->stash->cookies->delete('name');

=item get

Returns the named cookie or an array of cookie names.

 my $cookie = $self->stash->cookies->get('name');

 my @names = $self->stash->cookies->get;

 foreach my $key (@names) {

     my $cookie = $self->stash->cookied->get($key);

 }

=item set

Creates a new cookie and places it in the stash. Uses CGI::Simple::Cookie
symantics when creating the cookie.

 $self->stash->cookies->set(
    name  => 'cookie',
    value => 'this is really cool'
 );

=back

=head1 SEE ALSO

 Scaffold
 Scaffold::Base
 Scaffold::Cache
 Scaffold::Cache::FastMmap
 Scaffold::Cache::Manager
 Scaffold::Cache::Memcached
 Scaffold::Class
 Scaffold::Constants
 Scaffold::Engine
 Scaffold::Handler
 Scaffold::Handler::Default
 Scaffold::Handler::Favicon
 Scaffold::Handler::Robots
 Scaffold::Handler::Static
 Scaffold::Lockmgr
 Scaffold::Lockmgr::KeyedMutex
 Scaffold::Lockmgr::UnixMutex
 Scaffold::Plugins
 Scaffold::Render
 Scaffold::Render::Default
 Scaffold::Render::TT
 Scaffold::Routes
 Scaffold::Server
 Scaffold::Session::Manager
 Scaffold::Stash
 Scaffold::Stash::Controller
 Scaffold::Stash::Cookie
 Scaffold::Stash::Manager
 Scaffold::Stash::View
 Scaffold::Uaf::Authenticate
 Scaffold::Uaf::AuthorizeFactory
 Scaffold::Uaf::Authorize
 Scaffold::Uaf::GrantAllRule
 Scaffold::Uaf::Login
 Scaffold::Uaf::Logout
 Scaffold::Uaf::Manager
 Scaffold::Uaf::Rule
 Scaffold::Uaf::User
 Scaffold::Utils

=head1 AUTHOR

Kevin L. Esteb, E<lt>kevin@kesteb.usE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
