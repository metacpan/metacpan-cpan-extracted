package Net::Async::WebSearch::Provider::DuckDuckGo;
our $VERSION = '0.002';
# ABSTRACT: DuckDuckGo HTML endpoint provider (keyless)
use strict;
use warnings;
use parent 'Net::Async::WebSearch::Provider';

use Future;
use HTTP::Request::Common qw( POST );
use URI;
use HTML::TreeBuilder;
use Net::Async::WebSearch::Result;

sub _init {
  my ( $self ) = @_;
  $self->{endpoint} ||= 'https://html.duckduckgo.com/html/';
  $self->{name}     ||= 'duckduckgo';
}

sub endpoint { $_[0]->{endpoint} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  my %form = ( q => $query );
  $form{kl} = $opts->{region}     if defined $opts->{region};
  $form{kp} = $opts->{safesearch} if defined $opts->{safesearch};

  my $req = POST( $self->endpoint, [ %form ] );
  $req->header( 'User-Agent'      => $self->user_agent_string );
  $req->header( 'Accept'          => 'text/html' );
  $req->header( 'Accept-Language' => $opts->{language} // 'en-US,en;q=0.5' );

  return $http->do_request( request => $req )->then(sub {
    my ( $resp ) = @_;
    unless ( $resp->is_success ) {
      return Future->fail(
        "duckduckgo: HTTP ".$resp->status_line, 'websearch', $self->name,
      );
    }
    my $results = $self->_parse_html( $resp->decoded_content, $limit );
    return Future->done($results);
  });
}

sub _parse_html {
  my ( $self, $html, $limit ) = @_;
  my @out;
  my $tree = HTML::TreeBuilder->new_from_content( $html );
  my @blocks = $tree->look_down( _tag => 'div', class => qr/\bresult\b/ );
  my $rank = 0;
  for my $b (@blocks) {
    my $a = $b->look_down( _tag => 'a', class => qr/\bresult__a\b/ );
    next unless $a;
    my $href = $a->attr('href') or next;
    # DDG wraps real URL in //duckduckgo.com/l/?uddg=...
    if ( $href =~ m{[?&]uddg=([^&]+)} ) {
      require URI::Escape;
      $href = URI::Escape::uri_unescape($1);
    }
    my $title = $a->as_trimmed_text;
    my $sn    = $b->look_down( _tag => 'a', class => qr/\bresult__snippet\b/ );
    my $snippet = $sn ? $sn->as_trimmed_text : undef;
    $rank++;
    push @out, Net::Async::WebSearch::Result->new(
      url      => $href,
      title    => $title,
      snippet  => $snippet,
      provider => $self->name,
      rank     => $rank,
    );
    last if $rank >= $limit;
  }
  $tree->delete;
  return \@out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch::Provider::DuckDuckGo - DuckDuckGo HTML endpoint provider (keyless)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $ddg = Net::Async::WebSearch::Provider::DuckDuckGo->new;

=head1 DESCRIPTION

Keyless provider backed by DuckDuckGo's non-JS HTML endpoint
(C<https://html.duckduckgo.com/html/>). Parses the result list out of the HTML
with L<HTML::TreeBuilder>. This is inherently fragile — DuckDuckGo can change
the markup at any time — but works without an API key.

=head2 endpoint

Override the endpoint URL. Default C<https://html.duckduckgo.com/html/>.

=head2 search

See L<Net::Async::WebSearch::Provider/search>. Honours C<limit>, C<language>,
C<region> (mapped to C<kl>), and C<safesearch> (mapped to C<kp>).

=head1 SEE ALSO

L<Net::Async::WebSearch>, L<https://duckduckgo.com/>

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
