package Mojo::WebService::Twitter::Media;
use Mojo::Base -base;

our $VERSION = '1.001';

has [qw(source display_url expanded_url id media_url source_status_id tweet type url)];
has variants => sub { [] };

sub from_source {
	my ($self, $source) = @_;
	$self->display_url($source->{display_url});
	$self->expanded_url($source->{expanded_url});
	$self->id($source->{id_str});
	$self->media_url($source->{media_url_https});
	$self->source_status_id($source->{source_status_id_str});
	$self->type($source->{type});
	$self->url($source->{url});
	$self->variants($source->{video_info}{variants})
		if defined $source->{video_info} and defined $source->{video_info}{variants};
	$self->source($source);
	return $self;
}

1;

=head1 NAME

Mojo::WebService::Twitter::Media - Media associated with a tweet

=head1 SYNOPSIS

 use Mojo::WebService::Twitter;
 my $twitter = Mojo::WebService::Twitter->new(api_key => $api_key, api_secret => $api_secret);
 my $tweet = $twitter->get_tweet($tweet_id);

 my $media = $tweet->media;
 foreach my $item (@$media) {
   my $media_type = $item->type;
   my $media_url = $item->media_url;
   say "Media ($media_type): $media_url";
 }

=head1 DESCRIPTION

L<Mojo::WebService::Twitter::Media> is an object representing native media
associated with a L<Twitter|https://twitter.com> tweet. See
L<https://developer.twitter.com/en/docs/tweets/data-dictionary/overview/extended-entities-object>
for more information.

=head1 ATTRIBUTES

=head2 source

 my $href = $media->source;

Source data hashref from Twitter API.

=head2 display_url

 my $url = $media->display_url;

URL of the media for display purposes.

=head2 expanded_url

 my $url = $media->expanded_url;

Expanded version of L</"display_url">.

=head2 id

 my $media_id = $media->id;

Media identifier. Note that media IDs are usually too large to be represented
as a number, so should always be treated as a string.

=head2 media_url

 my $url = $media->media_url;

Direct URL to media of L</"type"> C<photo>, or a static thumbnail for media of
type C<video> or C<animated_gif>. Direct access to these types of media may be
found in L</"variants">.

=head2 source_status_id

 my $tweet_id = $media->source_status_id;

Tweet ID which media was originally associated with, or C<undef> if media was
originally associated with the current tweet.

=head2 type

 my $type = $media->type;

Media type, one of C<photo>, C<video>, or C<animated_gif>.

=head2 tweet

 my $tweet = $media->tweet;

Tweet in which the media is contained, as a L<Mojo::WebService::Twitter::Tweet>
object.

=head2 variants

 my $variants = $media->variants;

Array reference of variant hashrefs for media of L</"type"> C<video> or
C<animated_gif>, with keys C<content_type>, C<url>, and possibly C<bitrate>,
representing direct access to the media if available.

=head1 METHODS

L<Mojo::WebService::Twitter::Media> inherits all methods from L<Mojo::Base>,
and implements the following new ones.

=head2 from_source

 $media = $media->from_source($hr);

Populate attributes from hashref of Twitter API source data.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Mojo::WebService::Twitter>
