package Net::Async::WebSearch::Provider::Brave;
our $VERSION = '0.002';
# ABSTRACT: Brave Search API provider
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
  croak "Brave provider requires 'api_key'" unless $self->{api_key};
  $self->{endpoint} ||= 'https://api.search.brave.com/res/v1/web/search';
  $self->{name}     ||= 'brave';
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  my $uri = URI->new( $self->endpoint );
  my %q = ( q => $query, count => $limit );
  $q{country}    = $opts->{region}     if defined $opts->{region};
  $q{search_lang}= $opts->{language}   if defined $opts->{language};
  $q{safesearch} = $opts->{safesearch} if defined $opts->{safesearch};
  $uri->query_form(%q);

  my $req = GET( $uri->as_string );
  $req->header( 'User-Agent'        => $self->user_agent_string );
  $req->header( 'Accept'            => 'application/json' );
  $req->header( 'X-Subscription-Token' => $self->api_key );

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
    for my $r ( @{ ($data->{web} || {})->{results} || [] } ) {
      $rank++;
      push @out, Net::Async::WebSearch::Result->new(
        url          => $r->{url},
        title        => $r->{title},
        snippet      => $r->{description},
        provider     => $self->name,
        rank         => $rank,
        # Brave gives both age (human-readable like "3 days ago") and
        # page_age (ISO 8601). Prefer the ISO one.
        published_at => $r->{page_age} // $r->{age},
        language     => $r->{language},
        raw          => $r,
        extra        => {
          ( defined $r->{age}      ? ( age      => $r->{age} )      : () ),
          ( defined $r->{profile}  ? ( profile  => $r->{profile} )  : () ),
          ( defined $r->{subtype}  ? ( subtype  => $r->{subtype} )  : () ),
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

Net::Async::WebSearch::Provider::Brave - Brave Search API provider

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $brave = Net::Async::WebSearch::Provider::Brave->new(
    api_key => $ENV{BRAVE_API_KEY},
  );

=head1 DESCRIPTION

Provider for the Brave Search Web API. Parses the C<web.results> array from
the JSON response.

=head1 API KEY

Sign up at L<https://brave.com/search/api/>. Free tier is now B<$5 in
credits per month> (roughly 1000 queries at the Search plan's
$5 / 1000 rate). B<You must pick a plan even to use the free credits>,
and B<a credit card is required> as an anti-fraud check — the card
isn't billed while you stay within the credit allowance. API key is
issued at L<https://api.search.brave.com/app/dashboard>.

=head2 api_key

Required. Sent as C<X-Subscription-Token>.

=head2 endpoint

Override the endpoint URL. Default
C<https://api.search.brave.com/res/v1/web/search>.

=head2 search

Honours C<limit> (C<count>), C<language> (C<search_lang>), C<region>
(C<country>), C<safesearch>.

=head1 SEE ALSO

L<https://brave.com/search/api/>

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
