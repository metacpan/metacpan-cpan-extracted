package Plack::Middleware::RefererCheck;

use strict;
use 5.008_001;
use parent qw(Plack::Middleware);
 
__PACKAGE__->mk_accessors(qw(host same_scheme error_app no_warn));
 
our $VERSION = '0.03';

sub prepare_app {
    my $self = shift;

    warn('Plack::Middleware::RefererCheck WAS DEPRECATED!') unless $self->no_warn;
}

sub call {
    my($self, $env) = @_;

    $self->_check($env) ? $self->app->($env) : $self->error_app ? $self->error_app->($env) : _default_error_app();
}

sub _check {
    my ( $self, $env ) = @_;

    return 1 if $env->{REQUEST_METHOD} ne 'POST';

    my $scheme = $self->same_scheme ? qr{\Q$env->{'psgi.url_scheme'}\E} : qr{https?};
    my $host = $self->host || $env->{HTTP_HOST};
        $host = qr{\Q$host\E};

    return $env->{HTTP_REFERER} =~ m{\A$scheme://$host(?:/|\Z)};
}

sub _default_error_app {
    return ['403', ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['Forbidden']];
}
 
1;
 
__END__
 
=head1 NAME
 
Plack::Middleware::RefererCheck - check referer for defensive CSRF attack.(DEPRECATED)

=head1 SYNOPSIS
 
  use Plack::Builder;

  builder {
      enable 'RefererCheck', host => 'www.example.com', same_scheme => 1, error_app => sub { [403, [], ['Forbidden']] };
      $app;
  };
 
  or more simply(host from $env->{HTTP_HOST} and same_scheme => 0)
  # this is vulnerabilly for DNS Rebinding
  builder {
      enable 'RefererCheck';
      $app;
  };


=head1 DESCRIPTION

Please note that this module has been DEPRECATED.

Because Referer is not required and RFC2616 strongly recommends that the user be able to select whether or not the field.

Please use other way. For example L<Plack::Middleware::CSRFBlock>, L<Catalyst::Controller::RequestToken> and L<Amon2::Plugin::Web::CSRFDefender>.
 

=head1 CONFIGURATION

=over 4

=item host

Instead of using $env->{HTTP_HOST} if you set.

=item same_scheme

Check if you are setting "1" the same scheme.default: "0"

=item error_app

Is an PSGI-app that runs on errors.default: return 403 Forbidden app.

=item no_warn

mute DEPRECATED warnings.

=back
 
=head1 AUTHOR
 
Masahiro Chiba

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
 
=head1 SEE ALSO
 
L<Plack::Middleware> L<Plack::Builder>
 
=cut
