package Net::Async::WebSearch::Provider::Google;
our $VERSION = '0.003';
# ABSTRACT: Google Programmable Search (CSE) JSON API provider
use strict;
use warnings;
use parent 'Net::Async::WebSearch::Provider';

use Carp qw( croak );
use Future;
use Future::Utils qw( repeat );
use JSON::MaybeXS qw( decode_json );
use URI;
use HTTP::Request::Common qw( GET );
use Net::Async::WebSearch::Result;

sub _init {
  my ( $self ) = @_;
  croak "Google provider requires 'api_key'" unless $self->{api_key};
  croak "Google provider requires 'cx' (Programmable Search engine id)" unless $self->{cx};
  $self->{endpoint} ||= 'https://www.googleapis.com/customsearch/v1';
  $self->{name}     ||= 'google';
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }
sub cx       { $_[0]->{cx} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  # CSE serves at most 10 results per call and never past the 100th hit
  # overall, so satisfy limit > 10 by paging over the 1-based `start` index
  # (start=1,11,21,…) until we have `limit` results or the API runs dry.
  my @out;
  my $rank      = 0;
  my $exhausted = 0;

  my $paging = repeat {
    my $start = @out + 1;                          # CSE `start` is 1-based
    my $num   = $limit - @out;
    $num = 10 if $num > 10;                         # CSE hard-caps num to 10
    $num = 100 - @out if @out + $num > 100;         # never page past hit #100

    my $uri = URI->new( $self->endpoint );
    my %q = (
      q     => $query,
      key   => $self->api_key,
      cx    => $self->cx,
      num   => $num,
      start => $start,
    );
    $q{gl}        = $opts->{region}     if defined $opts->{region};
    $q{hl}        = $opts->{language}   if defined $opts->{language};
    $q{safe}      = $opts->{safesearch} if defined $opts->{safesearch};
    $q{dateRestrict} = $opts->{date_restrict} if defined $opts->{date_restrict};
    $uri->query_form(%q);

    my $req = GET( $uri->as_string );
    $req->header( 'User-Agent' => $self->user_agent_string );
    $req->header( 'Accept'     => 'application/json' );

    $http->do_request( request => $req )->then(sub {
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
      my $items = $data->{items} || [];
      $exhausted = 1 unless @$items;                # no more results upstream
      for my $r ( @$items ) {
        $rank++;
        my $pagemap = $r->{pagemap} || {};
        my ($metatags) = @{ $pagemap->{metatags} || [] };
        push @out, Net::Async::WebSearch::Result->new(
          url      => $r->{link},
          title    => $r->{title},
          snippet  => $r->{snippet},
          provider => $self->name,
          rank     => $rank,
          published_at => (
            $metatags && ( $metatags->{'article:published_time'}
                        // $metatags->{'og:article:published_time'}
                        // $metatags->{'date'} )
          ),
          raw      => $r,
          extra    => {
            ( defined $r->{displayLink} ? ( displayLink => $r->{displayLink} ) : () ),
            ( defined $r->{mime}        ? ( mime        => $r->{mime} )        : () ),
            ( defined $r->{fileFormat}  ? ( fileFormat  => $r->{fileFormat} )  : () ),
          },
        );
        last if @out >= $limit;                     # honour limit exactly
      }
      return Future->done;
    });
  } until => sub {
    my ( $trial ) = @_;
    return 1 if $trial->failure;                    # stop and propagate on error
    return 1 if @out >= $limit;                     # limit satisfied
    return 1 if @out >= 100;                         # CSE result ceiling reached
    return $exhausted;                              # nothing left to page
  };

  return $paging->then(sub { Future->done( \@out ) });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::WebSearch::Provider::Google - Google Programmable Search (CSE) JSON API provider

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  my $g = Net::Async::WebSearch::Provider::Google->new(
    api_key => $ENV{GOOGLE_API_KEY},
    cx      => $ENV{GOOGLE_CSE_ID},
  );

=head1 DESCRIPTION

Provider for Google Programmable Search (Custom Search Engine) JSON API.
The API returns at most 10 C<items> per call, so a C<limit> above 10 is
satisfied by paging over the C<start> index (C<start=1,11,21,…>) and merging
the pages, up to CSE's hard ceiling of 100 results per query.

=head1 API KEY

Two moving parts, both free at low volume:

=over 4

=item 1.

Create a Programmable Search Engine at
L<https://programmablesearchengine.google.com>. That hands you the C<cx>
value ("Search engine ID"). By default a PSE is scoped to specific sites
you list — for full-web results, open the engine's I<Search features>
panel and turn B<Search the entire web> on. (The toggle has been moved
around and buried over the years but it's still there.)

=item 2.

Enable the Custom Search API in a Google Cloud project
(L<https://console.cloud.google.com/apis/library/customsearch.googleapis.com>)
and mint an API key under I<Credentials>. No credit card needed at the
free tier.

=back

Quota: 100 free queries/day; paid is $5 / 1000 up to 10,000/day.

=head2 api_key

Required. Your Google API key.

=head2 cx

Required. The Programmable Search Engine id (a.k.a. C<cx>).

=head2 endpoint

Override the endpoint URL. Default
C<https://www.googleapis.com/customsearch/v1>.

=head2 search

Honours C<limit> — paging over C<start> in blocks of C<num> (capped at 10 per
call) until C<limit> results are collected, the upstream runs out, or CSE's
100-result ceiling is reached — plus C<language> (C<hl>), C<region> (C<gl>),
C<safesearch> (C<safe>), C<date_restrict> (C<dateRestrict>).

=head1 SEE ALSO

L<https://developers.google.com/custom-search/v1/overview>

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
