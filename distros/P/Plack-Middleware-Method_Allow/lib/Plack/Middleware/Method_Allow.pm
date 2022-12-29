package Plack::Middleware::Method_Allow;
use strict;
use warnings;
use parent qw{Plack::Middleware};

our $VERSION = '0.01';
our $PACKAGE = __PACKAGE__;
our %ALLOW   = ();

=head1 NAME

Plack::Middleware::Method_Allow - perl Plack Middleware to filter HTTP Methods

=head1 SYNOPSIS

  builder {
    enable "Plack::Middleware::Method_Allow", allow=>['GET', 'POST'];
    $app;
  };

=head1 DESCRIPTION

Explicitly allow HTTP methods and return 405 METHOD NOT ALLOWED for all others

=cut

=head1 PROPERTIES

=head2 allow

Method that sets the allowed HTTP methods.  Must be an array reference of strings.

=cut

sub allow {
  my $self = shift;
  $self->{'allow'} = shift if @_;
  $self->{'allow'} = [] unless defined $self->{'allow'}; #default is to deny all
  die("Error: Syntax `enable '$PACKAGE', allow=>['METHOD', ...]`") unless ref($self->{'allow'}) eq 'ARRAY';
  return $self->{'allow'};
}

=head1 METHODS

=head2 prepare_app

Method is called once at load to read the allow list.

=cut

sub prepare_app {
  my $self = shift;
  %ALLOW   = map {$_ => 1} @{$self->allow};
  return $self;
}

=head2 call

Method is called for each request which return 405 Method Not Allowed for any HTTP method that is not in list.

=cut

sub call {
  my $self   = shift;
  my $env    = shift;
  if (exists $ALLOW{$env->{'REQUEST_METHOD'}}) {
    return $self->app->($env);
  } else {
    return [405 => ['Content-Type' => 'text/plain'] => ['Method Not Allowed']];
  }
}

=head1 SEE ALSO

L<Plack::Middleware>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2022 Michael R. Davis

=cut

1;
