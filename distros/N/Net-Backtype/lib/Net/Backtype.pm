package Net::Backtype;

# ABSTRACT: client for the backtype API

use Net::HTTP::API;

our $VERSION = '0.03';

net_api_declare backtype => (
    base_url    => 'http://api.backtype.com',
    format      => 'json',
    format_mode => 'append',
);

net_api_method comments_search => (
    description => 'Search all the comments on BackType for a given string.',
    path        => '/comments/search',
    method      => 'GET',
    params      => [qw/key q start end/],
    required    => [qw/key q/],
    expected    => [qw/200/],
);

net_api_method comments_connect => (
    description => 'Retrieve all conversations related to a given URL.',
    path        => '/comments/connects',
    method      => 'GET',
    params      => [qw/key url sources sort/],
    required    => [qw/url key/],
    expected    => [qw/200/],
);

net_api_method comments_connect_stats => (
    description =>
      'Retrieve statistics on the conversations related to a given URL.',
    path     => '/comments/connect/stats/',
    method   => 'GET',
    params   => [qw/key url/],
    required => [qw/url key/],
    expected => [qw/200/],
);

net_api_method comments_author => (
    description => 'Retrieve comments written by a particular author.',
    path        => '/url/:url/comments',
    method      => 'GET',
    params      => [qw/key url/],
    required    => [qw/key url/],
    expected    => [qw/200/],
);

net_api_method comments_page => (
    description =>
      'Retrieve excerpts of comments published on a particular page.',
    path     => '/post/comments',
    method   => 'GET',
    params   => [qw/url key/],
    required => [qw/key url/],
    expected => [qw/200/],
);

net_api_method comments_page_stats => (
    description =>
      'Retrieve statistics for the comments published on a particular page.',
    path     => '/post/stats',
    method   => 'GET',
    params   => [qw/url key/],
    required => [qw/key url/],
    expected => [qw/200/],
);

1;


__END__
=pod

=head1 NAME

Net::Backtype - client for the backtype API

=head1 VERSION

version 0.03

=head1 SYNOPSIS

  use Net::Backtype;
  my $client = Net::Backtype->new();
  my $res = $client->comments_page(url => 'http://...', key => $mykey);

=head1 DESCRIPTION

Net::Backtype is a client for the backtype API

=head2 METHODS

=over 4

=item B<comments_search>

Search all the comments on BackType for a given string.

    my $res = $client->comments_page(key => 's3kr3t', q => 'lumberjaph' );

=over 2

=item B<q> query (required)

=item B<key> API key (required)

=item B<start> date start (optional)

=item B<end> date end (optional)

=back

See L<http://www.backtype.com/developers/comments-search>.

=item B<comments_connect>

Retrieve all conversations related to a given URL.

    my $res = $client->comments_connect(key => 's3kr3t', url => 'lumberjaph');

=over 2

=item B<url> url (required)

=item B<key> API key (required)

=item B<sources> (optional)

=item B<sort> (optional)

=back

See L<http://www.backtype.com/developers/comments-connect>.

=item B<comments_connect_stats>

Retrieve statistics on the conversations related to a given URL.

    my $res = $client->comments_connect_stats(url => 'lumberjaph', key => 's3kr3t');

=over 2

=item B<url> url (required)

=item B<key> API key (required)

=back

See L<http://www.backtype.com/developers/comments-connect-stats>.

=item B<comments_author>

Retrieve comments written by a particular author.

    my $res = $client->comments_author(url => 'lumberjaph', key => 's3kr3t');

=over 2

=item B<url> url (required)

=item B<key> API key (required)

=back

See L<http://www.backtype.com/developers/url-comments>.

=item B<comments_page>

Retrieve excerpts of comments published on a particular page.

    my $res = $client->comments_page_stats(url => 'lumberjaph', key => 's3kr3t');

=over 2

=item B<url> url (required)

=item B<key> API key (required)

=back

See L<http://www.backtype.com/developers/page-comments>.

=item B<comments_page_stats>

Retrieve statistics for the comments published on a particular page.

See L<http://www.backtype.com/developers/page-comments-stats>

=back

=head1 AUTHOR

  franck cuny <franck@lumberjaph.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by linkfluence.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

