package Mojo::WebService::Twitter::User;
use Mojo::Base -base;

use Mojo::WebService::Twitter::Tweet;
use Mojo::WebService::Twitter::Util 'parse_twitter_timestamp';
use Scalar::Util 'weaken';

our $VERSION = '0.002';

has [qw(source created_at description followers friends id last_tweet name
	protected screen_name statuses time_zone url utc_offset verified)];

sub from_source {
	my ($self, $source) = @_;
	$self->created_at(parse_twitter_timestamp($source->{created_at})) if defined $source->{created_at};
	$self->description($source->{description});
	$self->followers($source->{followers_count});
	$self->friends($source->{friends_count});
	$self->id($source->{id});
	$self->name($source->{name});
	$self->protected($source->{protected} ? 1 : 0);
	$self->screen_name($source->{screen_name});
	$self->statuses($source->{statuses_count});
	$self->time_zone($source->{time_zone});
	$self->url($source->{url});
	$self->utc_offset($source->{utc_offset});
	$self->verified($source->{verified} ? 1 : 0);
	if (defined $source->{status}) {
		my $tweet = Mojo::WebService::Twitter::Tweet->new->from_source($source->{status});
		weaken($tweet->{user} = $self);
		$self->last_tweet($tweet);
	}
	$self->source($source);
	return $self;
}

1;

=head1 NAME

Mojo::WebService::Twitter::User - A Twitter user

=head1 SYNOPSIS

 use Mojo::WebService::Twitter;
 my $twitter = Mojo::WebService::Twitter->new(api_key => $api_key, api_secret => $api_secret);
 my $user = $twitter->get_user(user_id => $user_id);
 
 my $username = $user->screen_name;
 my $name = $user->name;
 my $created_at = $user->created_at;
 my $description = $user->description;
 say "[$created_at] \@$username ($user): $description";

=head1 DESCRIPTION

L<Mojo::WebService::Twitter::User> is an object representing a
L<Twitter|https://twitter.com> user. See L<https://dev.twitter.com/overview/api/users>
for more information.

=head1 ATTRIBUTES

=head2 source

 my $href = $user->source;

Source data hashref from Twitter API.

=head2 created_at

 my $ts = $user->created_at;

L<Time::Piece> object representing the creation time of the user in UTC.

=head2 description

 my $description = $user->description;

User's profile description.

=head2 followers

 my $count = $user->followers;

Number of followers of the user.

=head2 friends

 my $count = $user->friends;

Number of friends of the user.

=head2 id

 my $user_id = $user->id;

User identifier.

=head2 last_tweet

 my $tweet = $user->last_tweet;

Most recent tweet by the user (if any), as a L<Mojo::WebService::Twitter::Tweet>
object.

=head2 name

 my $name = $user->name;

User's full name.

=head2 protected

 my $bool = $user->protected;

Whether the user's tweets are protected.

=head2 screen_name

 my $screen_name = $user->screen_name;

User's twitter screen name.

=head2 statuses

 my $count = $user->statuses;

Number of tweets the user has sent.

=head2 time_zone

 my $tz = $user->time_zone;

String describing the user's time zone.

=head2 url

 my $url = $user->url;

User's profile URL.

=head2 utc_offset

 my $seconds = $user->utc_offset;

User's current offset from UTC in seconds.

=head2 verified

 my $bool = $user->verified;

Whether the user is a L<Verified Account|https://twitter.com/help/verified>.

=head1 METHODS

L<Mojo::WebService::Twitter::User> inherits all methods from L<Mojo::Base>, and
implements the following new ones.

=head2 from_source

 $user = $user->from_source($hr);

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
