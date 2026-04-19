package Net::Async::WebSearch::Provider::SearxNG;
our $VERSION = '0.002';
# ABSTRACT: SearxNG/Searx JSON endpoint provider
use strict;
use warnings;
use parent 'Net::Async::WebSearch::Provider';

use Carp qw( croak );
use Future;
use JSON::MaybeXS qw( decode_json );
use URI;
use HTTP::Request::Common qw( GET );
use Net::Async::WebSearch::Result;

sub _init {
  my ( $self ) = @_;
  croak "SearxNG provider requires 'endpoint'" unless $self->{endpoint};
  $self->{endpoint} =~ s{/+$}{};
  $self->{name} ||= 'searxng';
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  my $uri = URI->new( $self->endpoint . '/search' );
  my %q = (
    q      => $query,
    format => 'json',
  );
  $q{language}   = $opts->{language}   if defined $opts->{language};
  $q{safesearch} = $opts->{safesearch} if defined $opts->{safesearch};
  $q{categories} = $opts->{categories} if defined $opts->{categories};
  $q{engines}    = $opts->{engines}    if defined $opts->{engines};
  $q{pageno}     = $opts->{pageno}     if defined $opts->{pageno};
  $uri->query_form(%q);

  my $req = GET( $uri->as_string );
  $req->header( 'User-Agent' => $self->user_agent_string );
  $req->header( 'Accept'     => 'application/json' );
  $req->header( 'Authorization' => 'Bearer ' . $self->api_key ) if defined $self->api_key;

  return $http->do_request( request => $req )->then(sub {
    my ( $resp ) = @_;
    unless ( $resp->is_success ) {
      return Future->fail(
        $self->name.": HTTP ".$resp->status_line, 'websearch', $self->name,
      );
    }
    my $data = eval { decode_json( $resp->decoded_content ) };
    if ( my $e = $@ ) {
      return Future->fail( $self->name.": invalid JSON: $e", 'websearch', $self->name );
    }
    my @out;
    my $rank = 0;
    for my $r ( @{ $data->{results} || [] } ) {
      $rank++;
      push @out, Net::Async::WebSearch::Result->new(
        url          => $r->{url},
        title        => $r->{title},
        snippet      => $r->{content},
        provider     => $self->name,
        rank         => $rank,
        published_at => $r->{publishedDate},
        raw          => $r,
        extra        => {
          ( defined $r->{engine}    ? ( engine    => $r->{engine} )    : () ),
          ( defined $r->{category}  ? ( category  => $r->{category} )  : () ),
          ( defined $r->{thumbnail} ? ( thumbnail => $r->{thumbnail} ) : () ),
        },
      );
      last if $rank >= $limit;
    }
    return Future->done(\@out);
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch::Provider::SearxNG - SearxNG/Searx JSON endpoint provider

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $sx = Net::Async::WebSearch::Provider::SearxNG->new(
    endpoint => 'https://searxng.example.org',
    name     => 'my-searxng',
    api_key  => 'optional-bearer-token',
  );

=head1 DESCRIPTION

Provider for self-hosted or public SearxNG instances using the JSON format
(C<&format=json>). The endpoint instance must have the JSON output format
enabled in its C<settings.yml>.

=head1 RUNNING A LOCAL SEARXNG

The default SearxNG settings only serve HTML — hitting C<?format=json>
returns 403 Forbidden until you explicitly enable it. In modern SearxNG
the built-in rate limiter also requires both a Valkey instance (C<redis>
is deprecated in its config) AND a separate C</etc/searxng/limiter.toml>.

For a private single-user instance you don't need any of that complexity:
ship a C<settings.yml> that turns C<server.limiter> off and enables
C<json> in C<search.formats>, and you're done. See F<ex/docker-compose.searxng.yml>
and F<ex/searxng/settings.yml> in this distribution for a working config.
Paste your own C<server.secret_key> (C<openssl rand -hex 32>) into the
yaml before first start.

If you later expose the instance publicly you'll want to turn the limiter
back on — then add a Valkey container, set C<valkey.url>, and write a
C<limiter.toml>. See L<https://docs.searxng.org/admin/searx.limiter.html>.

=head2 endpoint

Required. Base URL of the SearxNG instance (no trailing slash needed).

=head2 api_key

Optional. Sent as a Bearer token (some private instances protect JSON).

=head2 search

Honours C<limit>, C<language>, C<safesearch>, C<categories>, C<engines>,
C<pageno>.

=head1 SEE ALSO

L<https://docs.searxng.org/>

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/p5-net-async-websearch/issues>.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudss.us/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
