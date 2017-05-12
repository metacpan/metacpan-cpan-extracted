package Plack::Client::Backend::psgi_local;
BEGIN {
  $Plack::Client::Backend::psgi_local::VERSION = '0.06';
}
use strict;
use warnings;
# ABSTRACT: backend for handling local app requests

use Carp;
use Plack::Middleware::ContentLength;

use base 'Plack::Client::Backend';



sub new {
    my $class = shift;
    my %params = @_;
    my $self = $class->SUPER::new(@_);

    croak 'apps must be a hashref'
        if ref($params{apps}) ne 'HASH';

    $self->{apps} = $params{apps};

    return $self;
}

sub _apps { shift->{apps} }


sub app_for {
    my $self = shift;
    my ($for) = @_;
    return $self->_apps->{$for};
}


sub app_from_request {
    my $self = shift;
    my ($req) = @_;

    my $app_name;
    if (my $uri = $req->env->{'plack.client.original_uri'}) {
        $app_name = $uri->authority;
    }
    else {
        $app_name = $req->uri->authority;
        $app_name =~ s/(.*):.*/$1/; # in case a port was added at some point
    }

    my $app = $self->app_for($app_name);
    croak "Unknown app: $app_name" unless $app;
    return Plack::Middleware::ContentLength->wrap($app);
}

1;

__END__
=pod

=head1 NAME

Plack::Client::Backend::psgi_local - backend for handling local app requests

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  Plack::Client->new(
      'psgi-local' => {
          apps => { myapp => sub { ... } },
      },
  );

  Plack::Client->new(
      'psgi-local' => Plack::Client::Backend::psgi_local->new(
          apps => { myapp => sub { ... } },
      ),
  );

=head1 DESCRIPTION

This backend implements requests made against local PSGI apps.

=head1 METHODS

=head2 new

Constructor. Takes a hash of arguments, with these keys being valid:

=over 4

=item apps

A mapping of local app names to PSGI app coderefs.

=back

=head2 app_for

Returns the PSGI app coderef for the given app name.

=head2 app_from_request

Takes a L<Plack::Request> object, and returns the app corresponding to the app
corresponding to the app name given in the C<authority> section of the given
URL.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Plack::Client|Plack::Client>

=back

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

