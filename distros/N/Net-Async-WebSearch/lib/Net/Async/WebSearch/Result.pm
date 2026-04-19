package Net::Async::WebSearch::Result;
our $VERSION = '0.002';
# ABSTRACT: Single web search result record
use strict;
use warnings;
use URI ();

sub new {
  my ( $class, %args ) = @_;
  my $self = {
    url          => $args{url},
    title        => $args{title},
    snippet      => $args{snippet},
    provider     => $args{provider},
    rank         => $args{rank},
    score        => $args{score},
    published_at => $args{published_at},
    language     => $args{language},
    nsfw         => $args{nsfw},
    domain       => $args{domain},
    fetched      => $args{fetched},
    raw          => $args{raw},
    extra        => $args{extra} || {},
  };
  bless $self, $class;
  # Auto-derive domain from URL if not supplied.
  if ( !defined $self->{domain} && defined $self->{url} ) {
    my $u = eval { URI->new( $self->{url} ) };
    if ( $u && $u->can('host') ) {
      my $h = eval { $u->host };
      $self->{domain} = $h if defined $h && length $h;
    }
  }
  return $self;
}

sub url          { $_[0]->{url} }
sub title        { $_[0]->{title} }
sub snippet      { $_[0]->{snippet} }
sub provider     { $_[0]->{provider} }
sub rank         { @_ > 1 ? ($_[0]->{rank}  = $_[1]) : $_[0]->{rank} }
sub score        { @_ > 1 ? ($_[0]->{score} = $_[1]) : $_[0]->{score} }
sub published_at { $_[0]->{published_at} }
sub language     { $_[0]->{language} }
sub nsfw         { $_[0]->{nsfw} }
sub domain       { $_[0]->{domain} }
sub fetched      { @_ > 1 ? ($_[0]->{fetched} = $_[1]) : $_[0]->{fetched} }
sub raw          { $_[0]->{raw} }
sub extra        { $_[0]->{extra} }

sub to_hash {
  my ( $self ) = @_;
  return {
    url      => $self->{url},
    title    => $self->{title},
    snippet  => $self->{snippet},
    provider => $self->{provider},
    rank     => $self->{rank},
    score    => $self->{score},
    ( defined $self->{published_at} ? ( published_at => $self->{published_at} ) : () ),
    ( defined $self->{language}     ? ( language     => $self->{language} )     : () ),
    ( defined $self->{nsfw}         ? ( nsfw         => $self->{nsfw} ? 1 : 0 ) : () ),
    ( defined $self->{domain}       ? ( domain       => $self->{domain} )       : () ),
    ( defined $self->{fetched}      ? ( fetched      => $self->{fetched} )      : () ),
    ( %{ $self->{extra} || {} } ? ( extra => $self->{extra} ) : () ),
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch::Result - Single web search result record

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $r = Net::Async::WebSearch::Result->new(
    url      => 'https://example.com/page',
    title    => 'Example Page',
    snippet  => 'Some descriptive snippet...',
    provider => 'duckduckgo',
    rank     => 3,
  );

=head1 DESCRIPTION

Plain value object produced by a L<Net::Async::WebSearch::Provider>. Carries the
per-provider rank position; the aggregate C<score> is filled in later by
L<Net::Async::WebSearch> when the C<collect> mode merges results from several
providers.

=head1 NORMALIZED FIELDS

Every provider promises these fields (though some may be C<undef> when the
upstream doesn't supply them):

=over 4

=item * C<url> — result URL (always present, used as the dedup key).

=item * C<title> — result title.

=item * C<snippet> — short description / passage.

=item * C<provider> — name of the emitting provider.

=item * C<rank> — 1-indexed position within the emitting provider.

=item * C<domain> — derived automatically from the URL via L<URI>, unless the
provider overrides it. Convenient for grouping/filtering.

=item * C<score> — aggregate RRF score (only set by C<collect> mode).

=back

Optional normalized fields, populated when the provider has the data:

=over 4

=item * C<published_at> — ISO 8601 string (or a human-readable age like
C<"3 days ago"> if the provider only gives that).

=item * C<language> — BCP-47 language hint (C<en>, C<de>, ...).

=item * C<nsfw> — 1 if the upstream flags this result as adult content.

=back

Provider-specific extras (subreddit, sitelinks, MIME type, engine name, ...)
live in C<< $r->extra >> as a hashref. Raw upstream payload, when retained,
lives in C<< $r->raw >>.

=head2 url

Result URL. Used as the dedup key (after normalization).

=head2 title

Result title as supplied by the provider.

=head2 snippet

Short description / snippet for the result.

=head2 provider

Name of the provider that emitted this result.

=head2 rank

1-indexed position within the emitting provider's result list.

=head2 score

Aggregate score (filled in by RRF in C<collect> mode). Read/write.

=head2 published_at

Publication timestamp (ISO 8601 or upstream-native string), if the provider
surfaces one.

=head2 language

BCP-47 language code, if the provider surfaces one.

=head2 nsfw

Boolean flag for adult content, if the provider surfaces one.

=head2 domain

The hostname parsed out of C<url> (auto-derived if not supplied).

=head2 fetched

Populated only when L<Net::Async::WebSearch/search> was called with C<fetch>.
A hashref describing the HTTP fetch of this result's URL:

  {
    ok           => 1,                        # bool
    status       => 200,                      # HTTP code (undef on transport error)
    status_line  => '200 OK',
    final_url    => 'https://example.com/...', # after redirects
    content_type => 'text/html; charset=utf-8',
    charset      => 'utf-8',
    body         => '<html>...</html>',
    error        => undef,                    # error string on failure
  }

=head2 raw

Optional raw provider payload fragment.

=head2 extra

Hashref of provider-specific fields that don't fit the normalized schema
(e.g. subreddit, sitelinks, display link, MIME type, engine name).

=head2 to_hash

Plain hash representation suitable for JSON serialization (MCP, logs).

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
