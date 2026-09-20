package Net::Async::WebSearch::Provider::Tavily;
our $VERSION = '0.003';
# ABSTRACT: Tavily Search API provider
use strict;
use warnings;
use parent 'Net::Async::WebSearch::Provider';

use Carp qw( croak );
use Future;
use JSON::MaybeXS qw( encode_json decode_json );
use HTTP::Request ();
use Net::Async::WebSearch::Result;

sub _init {
  my ( $self ) = @_;
  croak "Tavily provider requires 'api_key'" unless $self->{api_key};
  $self->{endpoint} ||= 'https://api.tavily.com/search';
  $self->{name}     ||= 'tavily';
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;
  # max_results is capped at 20 upstream; clamp so the body param stays valid
  # and the trim below never overshoots.
  $limit = 20 if $limit > 20;

  my %body = (
    query       => $query,
    max_results => $limit,
    topic       => $opts->{topic} // 'general',
  );
  $body{language} = $opts->{language} if defined $opts->{language};
  $body{country}  = $opts->{region}   if defined $opts->{region};

  my $req = HTTP::Request->new(
    POST => $self->endpoint,
    [
      'Authorization' => 'Bearer ' . $self->api_key,
      'Content-Type'  => 'application/json',
      'Accept'        => 'application/json',
      'User-Agent'    => $self->user_agent_string,
    ],
    encode_json(\%body),
  );

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
        published_at => $r->{published_date},
        raw          => $r,
        extra        => {
          ( defined $r->{score}   ? ( score   => $r->{score} )   : () ),
          ( defined $r->{favicon} ? ( favicon => $r->{favicon} ) : () ),
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

Net::Async::WebSearch::Provider::Tavily - Tavily Search API provider

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $tavily = Net::Async::WebSearch::Provider::Tavily->new(
    api_key => $ENV{TAVILY_API_KEY},
  );

=head1 DESCRIPTION

Provider for L<https://tavily.com>, a search API built for LLM and agent
workflows. Sends a JSON C<POST> to the C</search> endpoint and parses the
C<results> array from the JSON response.

=head1 API KEY

Sign up at L<https://app.tavily.com>. B<No credit card required> — the free
tier grants a monthly allowance of API credits. The key (prefixed C<tvly->) is
shown in the account dashboard after you log in.

=head2 api_key

Required. Sent as an C<Authorization: Bearer> header.

=head2 endpoint

Override the endpoint URL. Default C<https://api.tavily.com/search>.

=head2 search

Honours C<limit> (C<max_results>, clamped to the upstream maximum of 20),
C<language> (C<language>, ISO 639-1), and C<region> (C<country>). A C<topic>
override may be passed; it defaults to C<general>.

=head1 SEE ALSO

L<https://tavily.com/>

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
