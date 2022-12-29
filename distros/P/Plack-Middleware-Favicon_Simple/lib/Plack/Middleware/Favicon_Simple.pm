package Plack::Middleware::Favicon_Simple;
use strict;
use warnings;
use parent qw{Plack::Middleware};

our $VERSION = '0.01';

=head1 NAME

Plack::Middleware::Favicon_Simple - Perl Plack Middleware to provide favicon

=head1 SYNOPSIS

  use Plack::Builder qw{builder mount enable};
  builder {
    enable "Plack::Middleware::Favicon_Simple";
    $app;
  };

=head1 DESCRIPTION

Browsers request /favicon.ico automatically.  This Plack Middleware returns a favicon.ico file so that browsers do not get 404 HTTP codes.

=head1 METHODS

=head2 call

Middleware wrapper method.

=cut

sub call {
  my $self = shift;
  my $env  = shift;
  if ($env->{'PATH_INFO'} eq '/favicon.ico') {
    return [200, ['Content-Type' => 'image/x-icon'], [$self->favicon]];
  } else {
    return $self->app->($env);
  }
}

=head2 favicon

Sets the favicon from a binary source.

  builder {
    enable "Plack::Middleware::Favicon_Simple", favicon=>$binary_blob;
    $app;
  };

Default is a blank icon.

=cut

sub favicon {
  my $self = shift;
  $self->{'favicon'} = shift if @_;
  unless (defined $self->{'favicon'}) {
    #default: blank favicon.ico
    require MIME::Base64;
    $self->{'favicon'} = MIME::Base64::decode('
      AAABAAEAEBACAAEAAQCwAAAAFgAAACgAAAAQAAAAIAAAAAEAAQAAAAAAgAAAAAAAAA
      AAAAAAAAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
      AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD//wAA//8AAP//AAD//w
      AA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA//8AAP//AAD//wAA
    ');
  }
  return $self->{'favicon'};
}

=head1 SEE ALSO

L<Plack::Middleware>, L<Plack::Middleware::Favicon>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

=cut

1;
