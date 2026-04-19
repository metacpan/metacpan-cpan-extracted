package Net::Async::WebSearch::Provider::Serper;
our $VERSION = '0.002';
# ABSTRACT: Serper.dev Google Search API provider
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
  croak "Serper provider requires 'api_key'" unless $self->{api_key};
  $self->{endpoint} ||= 'https://google.serper.dev/search';
  $self->{name}     ||= 'serper';
}

sub endpoint { $_[0]->{endpoint} }
sub api_key  { $_[0]->{api_key} }

sub search {
  my ( $self, $http, $query, $opts ) = @_;
  $opts ||= {};
  my $limit = $opts->{limit} || 10;

  my %body = ( q => $query, num => $limit );
  $body{gl}  = $opts->{region}   if defined $opts->{region};
  $body{hl}  = $opts->{language} if defined $opts->{language};
  $body{tbs} = $opts->{tbs}      if defined $opts->{tbs};

  my $req = HTTP::Request->new(
    POST => $self->endpoint,
    [
      'X-API-KEY'     => $self->api_key,
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
    for my $r ( @{ $data->{organic} || [] } ) {
      $rank++;
      push @out, Net::Async::WebSearch::Result->new(
        url          => $r->{link},
        title        => $r->{title},
        snippet      => $r->{snippet},
        provider     => $self->name,
        rank         => $r->{position} // $rank,
        published_at => $r->{date},
        raw          => $r,
        extra        => {
          ( defined $r->{sitelinks} ? ( sitelinks => $r->{sitelinks} ) : () ),
          ( defined $r->{imageUrl}  ? ( imageUrl  => $r->{imageUrl} )  : () ),
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

Net::Async::WebSearch::Provider::Serper - Serper.dev Google Search API provider

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  my $serper = Net::Async::WebSearch::Provider::Serper->new(
    api_key => $ENV{SERPER_API_KEY},
  );

=head1 DESCRIPTION

Provider for L<https://serper.dev>, a paid Google Search proxy. Parses the
C<organic> array from the JSON response.

=head1 API KEY

Sign up at L<https://serper.dev>. B<No credit card required> — you get
2500 free queries on signup. The API key is shown in the account
dashboard after you log in; there is no deep-link URL.

=head2 api_key

Required. Sent as C<X-API-KEY>.

=head2 endpoint

Override the endpoint URL. Default C<https://google.serper.dev/search>.

=head2 search

Honours C<limit> (C<num>), C<language> (C<hl>), C<region> (C<gl>), and C<tbs>.

=head1 SEE ALSO

L<https://serper.dev/>

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
