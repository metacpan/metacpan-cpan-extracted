package Plack::Middleware::BrowserDetector;
use strict;
use warnings;
use HTTP::BrowserDetect;
use parent 'Plack::Middleware';

sub call {
    my ($self, $env) = @_;
    $env->{'BrowserDetector.browser'} = HTTP::BrowserDetect->new($env->{HTTP_USER_AGENT});
    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::BrowserDetector - Plack middleware to identify browsers

=head1 SYNOPSIS

  # in your .psgi
  ...
  builder {
    enable 'BrowserDetector';
    $app;
  }

  # and after that in your aplication
  my $browser = $env->{'BrowserDetector.browser'}; # HTTP::BrowserDetect object

  # check if browser appears to be mobile device
  if ($browser->mobile) {
  }

  # check if browser appears to be chrome
  if ($browser->chrome) {
  }

=head1 DESCRIPTION

This Plack middleware sets a key in the PSGI environment which is
HTTP::BrowserDetect object. The HTTP::BrowserDetect determines Web browser,
version, and platform from an HTTP user agent string.

See also: L<Plack::Middleware::BotDetector>, L<HTTP::BrowserDetect>

=head1 AUTHOR

Dimitar Petrov <mitakaa@gmail.com>

=cut
