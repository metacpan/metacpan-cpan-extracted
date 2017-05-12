package Plack::Middleware::Auth::QueryString;
use strict;
use warnings;
use utf8;
our $VERSION = '0.02';

use parent qw/Plack::Middleware/;

use Plack::Util::Accessor qw/key password/;
use Plack::Request;

sub prepare_app {
    my $self = shift;

    $self->key('key') unless $self->key;
    die 'requires password' unless $self->password;
}

sub call {
    my ($self, $env) = @_;

    return $self->validate($env) ? $self->app->($env) : $self->unauthorized;
}

sub validate {
    my ($self, $env) = @_;

    my $req = Plack::Request->new($env);
    $req->query_parameters->get($self->key) ~~ $self->password;
}

sub unauthorized {
    my $self = shift;

    my $body = 'Authorization required';
    return [
        401,
        [
            'Content-Type'    => 'text/plain',
            'Content-Lentgth' => length $body,
        ],
        [$body],
    ];
}

1;
__END__

=head1 NAME

Plack::Middleware::Auth::QueryString - simple query string authentication

=head1 SYNOPSIS

  use Plack::Middleware::Auth::QueryString;
  use Plack::Builder;
  my $app = sub { ... };

  builder {
    enable "Auth::QueryString", password => 'yourpasswordhere';
    $app;
  };
  # http://example.com/?key=yourpasswordhere

=head1 DESCRIPTION

Plack::Middleware::Auth::QueryString is query string authentication handler for Plack

=head1 CONFIGURATION

=over 4

=item key

Query key for authentication. 'key' is default.

=item password

Query value for authentication.

=back

=head1 AUTHOR

Masayuki Matsuki E<lt>y.songmu@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
