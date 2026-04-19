package Net::Async::WebSearch::Provider::Yandex;
our $VERSION = '0.002';
# ABSTRACT: Yandex Search API (XML) provider
use strict;
use warnings;
use parent 'Net::Async::WebSearch::Provider';

use Carp qw( croak );
use Future;
use URI;
use HTTP::Request::Common qw( GET );
use XML::LibXML ();
use Net::Async::WebSearch::Result;

sub _init {
  my ( $self ) = @_;
  croak "Yandex provider requires 'api_key'" unless $self->{api_key};
  croak "Yandex provider requires 'folderid' (Yandex Cloud folder)"
    unless $self->{folderid};
  $self->{endpoint} ||= 'https://yandex.com/search/xml';
  $self->{name}     ||= 'yandex';
  $self->{l10n}     ||= 'en';    # en | ru | tr | be | kk | uk
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }
sub folderid { $_[0]->{folderid} }
sub l10n     { $_[0]->{l10n} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  my $uri = URI->new( $self->endpoint );
  my %q = (
    folderid => $self->folderid,
    apikey   => $self->api_key,
    query    => $query,
    l10n     => $opts->{l10n} // $self->l10n,
    sortby   => $opts->{sortby} // 'rlv',
    groupby  => $opts->{groupby}
      // sprintf('attr=d.mode=deep.groups-on-page=%d.docs-in-group=1', $limit),
  );
  $q{filter} = $opts->{safesearch} if defined $opts->{safesearch};
  $q{lr}     = $opts->{region}     if defined $opts->{region};
  $uri->query_form(%q);

  my $req = GET( $uri->as_string );
  $req->header( 'User-Agent' => $self->user_agent_string );
  $req->header( 'Accept'     => 'application/xml' );

  return $http->do_request( request => $req )->then(sub {
    my ( $resp ) = @_;
    unless ( $resp->is_success ) {
      return Future->fail(
        $self->name.": HTTP ".$resp->status_line, 'websearch', $self->name,
      );
    }
    my $doc = eval { XML::LibXML->new->parse_string( $resp->decoded_content ) };
    if ( my $e = $@ ) {
      return Future->fail( $self->name.": XML parse: $e", 'websearch', $self->name );
    }
    # Yandex signals API-level errors inside the XML envelope.
    if ( my ($err) = $doc->findnodes('/yandexsearch/response/error') ) {
      my $code = $err->getAttribute('code') // '';
      my $msg  = $err->textContent;
      return Future->fail(
        $self->name.": API error $code: $msg", 'websearch', $self->name,
      );
    }
    my @out;
    my $rank = 0;
    for my $doc_node ( $doc->findnodes('/yandexsearch/response/results/grouping/group/doc') ) {
      my ($url_node)   = $doc_node->findnodes('./url');
      my ($title_node) = $doc_node->findnodes('./title');
      my @passages     = $doc_node->findnodes('./passages/passage');
      my @headline     = $doc_node->findnodes('./headline');
      my $url = $url_node   ? $url_node->textContent   : next;
      my $title = $title_node ? $title_node->textContent : '';
      my $snippet;
      if (@passages) {
        $snippet = join ' … ', map { $_->textContent } @passages;
      } elsif (@headline) {
        $snippet = $headline[0]->textContent;
      }
      $rank++;
      push @out, Net::Async::WebSearch::Result->new(
        url      => $url,
        title    => $title,
        snippet  => $snippet,
        provider => $self->name,
        rank     => $rank,
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

Net::Async::WebSearch::Provider::Yandex - Yandex Search API (XML) provider

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $y = Net::Async::WebSearch::Provider::Yandex->new(
    api_key  => $ENV{YANDEX_API_KEY},
    folderid => $ENV{YANDEX_FOLDER_ID},
    l10n     => 'en',
  );

=head1 DESCRIPTION

Provider for the Yandex Search API (the XML-over-HTTP interface, a.k.a.
Yandex XML, now billed through Yandex Cloud). Parses the grouped C<doc>
nodes out of the XML envelope via L<XML::LibXML>.

=head1 API KEY

=over 4

=item Signup: L<https://console.yandex.cloud/link/search-api/>

=item Docs:   L<https://yandex.cloud/en/docs/search-api/>

=back

You need a Yandex Cloud account and a "folder" (their project-scope
concept) — copy the folder id from the Cloud Console, that's your
C<folderid>. Then create a service account, grant it the
C<search-api.executor> role, and issue an API key (or IAM token) —
that's C<api_key>. Pricing is via Yandex Cloud credits; standard Cloud
welcome credits give you a working free trial.

=head2 api_key

Required. A Yandex Cloud API key (or IAM token, same placement) with access
to the search-api scope.

=head2 folderid

Required. Your Yandex Cloud folder id — the API is billed per folder.

=head2 l10n

Interface language: C<en> (default), C<ru>, C<tr>, C<be>, C<kk>, C<uk>.
Affects the language of system messages and, combined with C<lr> (C<region>),
the result set.

=head2 endpoint

Override the endpoint URL. Default C<https://yandex.com/search/xml>. Use the
C<.ru> host if you hit the TR/BY/KZ/UZ clusters.

=head2 search

Honours C<limit> (wired into C<groupby=groups-on-page>), C<l10n>, C<region>
(mapped to Yandex' C<lr> — numeric region codes), C<safesearch> (mapped to
C<filter>: C<strict> | C<moderate> | C<none>), C<sortby> (C<rlv> | C<tm>),
and C<groupby> (raw pass-through if you know Yandex' grouping DSL).

=head1 SEE ALSO

L<https://yandex.cloud/en/docs/search-api/>

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
