use 5.006;    # our
use strict;
use warnings;

package Net::Travis::API::Auth::GitHub;

our $VERSION = '0.002001';

# ABSTRACT: Authorize with Travis using a GitHub token

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( with );
use Scalar::Util qw(blessed);

with 'Net::Travis::API::Role::Client';














sub _get_token_for {
  my ( $self, $gh_token ) = @_;
  return $self->http_engine->post_form( '/auth/github', { github_token => $gh_token } );
}









sub get_token_for {
  my ( $self, $gh_token ) = @_;
  if ( not blessed $self ) {
    $self = $self->new();
  }
  my $result = $self->_get_token_for($gh_token);
  return if not '200' eq $result->status;
  return if not length $result->content;
  return unless my $json = $result->content_json;
  return $json->{access_token};
}












sub get_authorised_ua_for {
  my ( $self, $gh_token ) = @_;
  $self = $self->new() if not blessed $self;
  my $token = $self->get_token_for($gh_token);
  $self->http_engine->authtokens( [$token] );
  return $self->http_engine;
}

no Moo;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Travis::API::Auth::GitHub - Authorize with Travis using a GitHub token

=head1 VERSION

version 0.002001

=head1 METHODS

=head2 C<get_token_for>

Pass a GitHub token and receive a Travis token in exchange, if it is valid.

    my $travis_token = ($class|$instance)->get_token_for(<githubtoken>);

=head2 C<get_authorised_ua_for>

Authenticate using a GitHub token and return a C<Net::Travis::API::UA> instance for subsequent requests that will execute
requests as authorized by that token.

    if ( my $ua = ($class|$instance)->get_authorized_ua_for( <githubtoken> ) ) {
        pp ( $ua->get('/users')->content_json );
    }

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Net::Travis::API::Auth::GitHub",
    "inherits":"Moo::Object",
    "does":"Net::Travis::API::Role::Client",
    "interface":"class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
