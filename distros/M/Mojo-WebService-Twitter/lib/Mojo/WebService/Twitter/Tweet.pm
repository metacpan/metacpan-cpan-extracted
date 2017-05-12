package Mojo::WebService::Twitter::Tweet;
use Mojo::Base -base;

use Mojo::WebService::Twitter::User;
use Mojo::WebService::Twitter::Util 'parse_twitter_timestamp';

our $VERSION = '0.002';

has [qw(source coordinates created_at favorites id in_reply_to_screen_name
	in_reply_to_status_id in_reply_to_user_id retweets text user)];

sub from_source {
	my ($self, $source) = @_;
	$self->coordinates($source->{coordinates}{coordinates}) if defined $source->{coordinates};
	$self->created_at(parse_twitter_timestamp($source->{created_at})) if defined $source->{created_at};
	$self->favorites($source->{favorite_count});
	$self->id($source->{id_str});
	$self->in_reply_to_screen_name($source->{in_reply_to_screen_name}) if defined $source->{in_reply_to_screen_name};
	$self->in_reply_to_status_id($source->{in_reply_to_status_id_str}) if defined $source->{in_reply_to_status_id_str};
	$self->in_reply_to_user_id($source->{in_reply_to_user_id_str}) if defined $source->{in_reply_to_user_id_str};
	$self->retweets($source->{retweet_count});
	$self->text($source->{text});
	$self->user(Mojo::WebService::Twitter::User->new->from_source($source->{user})) if defined $source->{user};
	$self->source($source);
	return $self;
}

1;

=head1 NAME

Mojo::WebService::Twitter::Tweet - A tweet

=head1 SYNOPSIS

 use Mojo::WebService::Twitter;
 my $twitter = Mojo::WebService::Twitter->new(api_key => $api_key, api_secret => $api_secret);
 my $tweet = $twitter->get_tweet($tweet_id);
 
 my $username = $tweet->user->screen_name;
 my $created_at = $tweet->created_at;
 my $text = $tweet->text;
 say "[$created_at] \@$username: $text";

=head1 DESCRIPTION

L<Mojo::WebService::Twitter::Tweet> is an object representing a
L<Twitter|https://twitter.com> tweet. See L<https://dev.twitter.com/overview/api/tweets>
for more information.

=head1 ATTRIBUTES

=head2 source

 my $href = $tweet->source;

Source data hashref from Twitter API.

=head2 coordinates

 my $coords = $tweet->coordinates;

Array reference of geographic coordinates (longitude then latitude), or
C<undef> if tweet does not have coordinates.

=head2 created_at

 my $ts = $tweet->created_at;

L<Time::Piece> object representing the creation time of the tweet in UTC.

=head2 favorites

 my $count = $tweet->favorites;

Number of times the tweet has been favorited.

=head2 id

 my $tweet_id = $tweet->id;

Tweet identifier. Note that tweet IDs are usually too large to be represented
as a number, so should always be treated as a string.

=head2 in_reply_to_screen_name

 my $screen_name = $tweet->in_reply_to_screen_name;

Screen name of user whom tweet was in reply to, or C<undef> if tweet was not a
reply.

=head2 in_reply_to_status_id

 my $tweet_id = $tweet->in_reply_to_status_id;

Tweet ID which tweet was in reply to, or C<undef> if tweet was not a reply.

=head2 in_reply_to_user_id

 my $user_id = $tweet->in_reply_to_user_id;

User ID of user whom tweet was in reply to, or C<undef> if tweet was not a
reply.

=head2 retweets

 my $count = $tweet->retweets;

Number of times the tweet has been retweeted.

=head2 text

 my $text = $tweet->text;

Text contents of tweet.

=head2 user

 my $user = $tweet->user;

User who sent the tweet, as a L<Mojo::WebService::Twitter::User> object.

=head1 METHODS

L<Mojo::WebService::Twitter::Tweet> inherits all methods from L<Mojo::Base>,
and implements the following new ones.

=head2 from_source

 $tweet = $tweet->from_source($hr);

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
