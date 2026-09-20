package Net::Async::WebSearch::Provider::Mojeek;
our $VERSION = '0.003';
# ABSTRACT: Mojeek Search API provider
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
  # Mojeek runs its own index (not a Google reseller) and has no public/shared
  # key, so — like Brave — an api_key is mandatory.
  croak "Mojeek provider requires 'api_key'" unless $self->{api_key};
  $self->{endpoint} ||= 'https://api.mojeek.com/search';
  $self->{name}     ||= 'mojeek';
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  # Two Mojeek quirks live in this request: the key travels as the `api_key`
  # *query parameter* (not a header, unlike Brave), and `fmt=json` is mandatory
  # — without it Mojeek answers XML, which the JSON decode below cannot parse.
  my $uri = URI->new( $self->endpoint );
  my %q = (
    q       => $query,
    t       => $limit,
    fmt     => 'json',
    api_key => $self->api_key,
  );
  $q{lb}   = $opts->{language}   if defined $opts->{language};
  $q{rb}   = $opts->{region}     if defined $opts->{region};
  $q{safe} = $opts->{safesearch} if defined $opts->{safesearch};
  $uri->query_form(%q);

  my $req = GET( $uri->as_string );
  $req->header( 'User-Agent' => $self->user_agent_string );
  $req->header( 'Accept'     => 'application/json' );

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
    # Mojeek nests everything under a `response` container: the hit list is
    # response.results (NOT a top-level `results`), alongside response.head
    # (query metadata) and response.status (OK/ERROR). Reach through it before
    # walking the results.
    my $response = $data->{response} || {};
    my $status   = $response->{status};
    my @out;
    my $rank = 0;
    for my $r ( @{ $response->{results} || [] } ) {
      $rank++;
      push @out, Net::Async::WebSearch::Result->new(
        url      => $r->{url},
        title    => $r->{title},
        snippet  => $r->{desc},
        provider => $self->name,
        rank     => $rank,
        raw      => $r,
        extra    => {
          ( defined $status ? ( status => $status ) : () ),
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

Net::Async::WebSearch::Provider::Mojeek - Mojeek Search API provider

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $mojeek = Net::Async::WebSearch::Provider::Mojeek->new(
    api_key => $ENV{MOJEEK_API_KEY},
  );

=head1 DESCRIPTION

Provider for L<https://www.mojeek.com>, a search engine built on its own
independent crawl and index (it is I<not> a Google/Bing reseller). Sends a
C<GET> to the JSON API and parses the C<response.results> array — Mojeek nests
its payload under a C<response> container rather than returning a top-level
C<results> list.

=head1 API KEY

Mojeek has B<no public or shared key>; an API key is required. Request one via
the Mojeek Search API at L<https://www.mojeek.com/services/search/web-search-api/>.
The key is sent as the C<api_key> query parameter (not a header).

=head2 api_key

Required. Sent as the C<api_key> query parameter.

=head2 endpoint

Override the endpoint URL. Default C<https://api.mojeek.com/search>.

=head2 search

Honours C<limit> (C<t>), C<language> (C<lb>, ISO 639-1), C<region> (C<rb>,
ISO 3166-1 alpha-2) and C<safesearch> (C<safe>, 0/1). Always sends
C<fmt=json>, without which Mojeek would return XML.

=head1 SEE ALSO

L<https://www.mojeek.com/services/search/web-search-api/>

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
