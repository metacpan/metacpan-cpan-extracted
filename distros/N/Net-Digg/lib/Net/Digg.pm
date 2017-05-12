package Net::Digg;
$AUTHOR      = 'Kurt Wilms <wilms@cs.umn.edu>';
$VERSION     = 0.11;
use warnings;
use strict;

use LWP::UserAgent;
use JSON::Any;

=head1 NAME

Net::Digg - Quickly consume and interface with the Digg API.

=head1 SYNOPSIS


    use Net::Digg;

    my $digg = Net::Digg->new();

    # Print the user that submitted the latest upcoming story.

    my $result = $digg->get_upcoming_stories();

    print $result->{ 'stories' }[0]->{'title'};

   # Print the titles of the twenty latest popular stories

    my %params = ('count' => 20);

    $result = $digg->get_popular_stories(\%params);

    my $stories = $result->{'stories'};

    foreach $story (@$stories) {

        print $story->{'title'} . "\n";

    }

See also FUNCTIONS, DESCRIPTION, and EXAMPLES below.

=head1 INSTALLATION

The typical:

=over

=item 0 perl Makefile.PL

=item 0 make test

=item 0 make install

=back

=head1 FUNCTIONS

=cut

=pod

=head2 new()

Creates the Digg object.

=cut

sub new {
    my $class = shift;
    my %conf = @_;
    
    $conf{apiurl} = 'http://services.digg.com' unless defined $conf{apiurl};
    $conf{useragent} = "Net::Digg/$Net::Digg::VERSION (PERL)" unless defined $conf{useragent};
    $conf{appkey} = 'http%3A%2F%2Fsearch.cpan.org%2Fdist%2FNet-Digg' unless defined $conf{appkey};
    $conf{type} = 'json' unless defined $conf{type};
    $conf{ua} = LWP::UserAgent->new();
    $conf{ua}->agent($conf{useragent});
    $conf{ua}->env_proxy();

    return bless {%conf}, $class;
}

=pod

=head2 get_stories (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all stories.

=cut

sub get_stories {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_stories (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all popular stories.

=cut

sub get_popular_stories {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/popular";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_stories (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all popular stories.

=cut

sub get_upcoming_stories {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/upcoming";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_top_stories (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get top stories.

=cut

sub get_top_stories {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/top";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_hot_stories (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get hot stories.

=cut

sub get_hot_stories {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/hot";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_by_container ($container, \%params)

Given

=over

=item 0 the desired container

=item 0 a map of optional API query arguments.

=back

Get all stories from a given container.

=cut

sub get_stories_by_container {
    my $self = shift;
    my $container = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/container" . "/" . $container;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_stories_by_container ($container, \%params)

Given

=over

=item 0 the desired container

=item 0 a map of optional API query arguments.

=back

Get all popular stories from a given container.

=cut

sub get_popular_stories_by_container {
    my $self = shift;
    my $container = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/container" . "/" . $container . "/popular";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_stories_by_container ($container, \%params)

Given

=over

=item 0 the desired container

=item 0 a map of optional API query arguments.

=back

Get all upcoming stories from a given container.

=cut

sub get_upcoming_stories_by_container {
    my $self = shift;
    my $container = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/container" . "/" . $container . "/upcoming";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_top_stories_by_container ($container, \%params)

Given

=over

=item 0 the desired container

=item 0 a map of optional API query arguments.

=back

Get top stories from a given container.

=cut

sub get_top_stories_by_container {
    my $self = shift;
    my $container = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/container" . "/" . $container . "/top";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_hot_stories_by_container ($container, \%params)

Given

=over

=item 0 the desired container

=item 0 a map of optional API query arguments.

=back

Get hot stories from a given container.

=cut

sub get_hot_stories_by_container {
    my $self = shift;
    my $container = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/container" . "/" . $container . "/hot";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_by_topic ($topic, \%params)

Given

=over

=item 0 the desired topic

=item 0 a map of optional API query arguments.

=back

Get all stories from a given topic.

=cut

sub get_stories_by_topic {
    my $self = shift;
    my $topic = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/topic" . "/" . $topic;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_stories_by_topic ($topic, \%params)

Given

=over

=item 0 the desired topic

=item 0 a map of optional API query arguments.

=back

Get all popular stories from a given topic.

=cut

sub get_popular_stories_by_topic {
    my $self = shift;
    my $topic = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/topic" . "/" . $topic ."/popular";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_stories_by_topic ($topic, \%params)

Given

=over

=item 0 the desired topic

=item 0 a map of optional API query arguments.

=back

Get all upcoming stories from a given topic.

=cut

sub get_upcoming_stories_by_topic {
    my $self = shift;
    my $topic = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/topic" . "/" . $topic ."/upcoming";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_top_stories_by_topic ($topic, \%params)

Given

=over

=item 0 the desired topic

=item 0 a map of optional API query arguments.

=back

Get top stories from a given topic.

=cut

sub get_top_stories_by_topic {
    my $self = shift;
    my $topic = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/topic" . "/" . $topic ."/top";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_hot_stories_by_topic ($topic, \%params)

Given

=over

=item 0 the desired topic

=item 0 a map of optional API query arguments.

=back

Get hot stories from a given topic.

=cut

sub get_hot_stories_by_topic {
    my $self = shift;
    my $topic = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/topic" . "/" . $topic ."/hot";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_story_by_id ($id, \%params)

Given

=over

=item 0 the story id

=item 0 a map of optional API query arguments.

=back

Get identified story.

=cut

sub get_story_by_id {
    my $self = shift;
    my $id = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story" . "/" . $id;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_by_ids (@ids, \%params)

Given

=over

=item 0 list of ids

=item 0 a map of optional API query arguments.

=back

Get a list of stories with the given ids.

=cut

sub get_stories_by_ids {
    my $self = shift;
    my @ids = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories";
    $url .= '/' . join(',', @ids);
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_story_by_title ($title, \%params)

Given

=over

=item 0 story clean title

=item 0 a map of optional API query arguments.

=back

Get identified story.

=cut

sub get_story_by_title {
    my $self = shift;
    my $title = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story" . "/" . $title;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_by_user ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get stories submitted by given user.

=cut

sub get_stories_by_user {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/submissions";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_stories_by_user ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get popular stories submitted by given user.

=cut

sub get_popular_stories_by_user {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/popular";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_stories_by_user ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get upcoming stories submitted by given user.

=cut

sub get_upcoming_stories_by_user {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/upcoming";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_dugg_by_user ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get stories dugg by given user.

=cut

sub get_stories_dugg_by_user {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/dugg";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_commented_by_user ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get stories commented by given user.

=cut

sub get_stories_commented_by_user {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/commented";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_by_friends ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get stories submitted by given user friends.

=cut

sub get_stories_by_friends {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/friends/submissions";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_stories_by_friends ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get popular stories submitted by given user friends.

=cut

sub get_popular_stories_by_friends {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/friends/popular";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_stories_by_friends ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get upcoming stories submitted by given user friends.

=cut

sub get_upcoming_stories_by_friends {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/friends/upcoming";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_dugg_by_friends ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get stories dugg by given user friends.

=cut

sub get_stories_dugg_by_friends {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/friends/dugg";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_stories_commented_by_friends ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get stories commented by given user friends.

=cut

sub get_stories_commented_by_friends {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/friends/commented";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_diggs (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all diggs.

=cut

sub get_diggs {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_diggs (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all popular diggs.

=cut

sub get_popular_diggs {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/popular/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_diggs (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all upcoming diggs.

=cut

sub get_upcoming_diggs {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/upcoming/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_diggs_by_storyid ($storyid, \%params)

Given

=over

=item 0 story id

=item 0 a map of optional API query arguments.

=back

Get all diggs for a given story.

=cut

sub get_diggs_by_storyid {
    my $self = shift;
    my $id = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story" . $id . "/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_diggs_by_storyids (@storyids, \%params)

Given

=over

=item 0 story ids

=item 0 a map of optional API query arguments.

=back

Get all diggs for a list of stories with the given ids.

=cut

sub get_diggs_by_storyids {
    my $self = shift;
    my @ids = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/stories";
    $url .= '/' . join(',', @ids) . "/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_diggs_by_user ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get one user's diggs for all stories.

=cut

sub get_diggs_by_user {
    my $self = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $user . "/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_diggs_by_userids (@ids, \%params)

Given

=over

=item 0 user names

=item 0 a map of optional API query arguments.

=back

Get several users' diggs for all stories

=cut

sub get_diggs_by_userids {
    my $self = shift;
    my @ids = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "users";
    $url .= '/' . join(',', @ids) . "/diggs";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_user_digg_by_storyid ($id, $user, \%params)

Given

=over

=item 0 story id

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get one user digg for a given story.

=cut

sub get_user_digg_by_storyid {
    my $self = shift;
    my $id = shift;
    my $user = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story" . "/" . $id . "/" . $user . "/digg";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_comments (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all comments.

=cut

sub get_comments {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_popular_comments (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all comments on popular stories.

=cut

sub get_popular_comments {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/popular/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_upcoming_comments (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all comments on upcoming stories.

=cut

sub get_upcoming_comments {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories/upcoming/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_comments_by_ids (@ids, \%params)

Given

=over

=item 0 a list of story ids

=item 0 a map of optional API query arguments.

=back

Get all comments for a list of stories with the given ids.

=cut

sub get_comments_by_ids {
    my $self = shift;
    my @ids = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "stories";
    $url .= '/' . join(',', @ids) . "/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_comments_by_id ($id, \%params)

Given

=over

=item 0 a story id

=item 0 a map of optional API query arguments.

=back

Get top-level comments for a given story.

=cut

sub get_comments_by_id {
    my $self = shift;
    my $id = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story/" . $id . "/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2  ($user, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get one user's comments for all stories.

=cut

sub get_comments_by_user {
    my $self = shift;
    my $user= shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user/" . $user . "/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_comments_by_users (@users, \%params)

Given

=over

=item 0 user names

=item 0 a map of optional API query arguments.

=back

Get several users' comments for all stories. 

=cut

sub get_comments_by_users {
    my $self = shift;
    my @users= shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "users";
    $url .= '/' . join(',', @users) . "/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_comment_by_storyid_commentid ($storyid, $commentid, \%params)

Given

=over

=item 0 storyid

=item 0 commentid

=item 0 a map of optional API query arguments.

=back

Get one comment for a given story.

=cut

sub get_comment_by_storyid_commentid {
    my $self = shift;
    my $storyid= shift;
    my $commentid= shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story/" . $storyid . "/comment/" . $commentid;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_comment_by_storyid_commentid ($storyid, $commentid, \%params)

Given

=over

=item 0 storyid

=item 0 commentid

=item 0 a map of optional API query arguments.

=back

Get one level of replies to one comment for a given story.

=cut

sub get_comment_replies {
    my $self = shift;
    my $storyid= shift;
    my $commentid= shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "story/" . $storyid . "/comment/" . $commentid . "/replies";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_errors (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get a list of all error codes and messages.

=cut

sub get_errors {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "errors";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_error_code ($code, \%params)

Given

=over

=item 0 error code

=item 0 a map of optional API query arguments.

=back

Get the message for a specific error code.

=cut

sub get_error_code {
    my $self = shift;
    my $code = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "error" . "/" . $code;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_topics (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get a list of all topics.

=cut

sub get_topics {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "topics";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_topic_by_name ($topic, \%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get the specified topic.

=cut

sub get_topic_by_name {
    my $self = shift;
    my $topic = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "topic" . "/" . $topic;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_users (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all users.

=cut

sub get_users {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "users";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_user_by_name ($name, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get named user.

=cut

sub get_user_by_name {
    my $self = shift;
    my $name = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $name;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_users_friends ($name, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get named user's friends.

=cut

sub get_users_friends {
    my $self = shift;
    my $name = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $name . "/" . "friends";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_users_fans ($name, \%params)

Given

=over

=item 0 user name

=item 0 a map of optional API query arguments.

=back

Get users who count the named user as a friend.

=cut

sub get_users_fans {
    my $self = shift;
    my $name = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $name . "/" . "fans";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_user_by_name_fan_name ($name, $fanName, \%params)

Given

=over

=item 0 user name

=item 0 fan name

=item 0 a map of optional API query arguments.

=back

Get named user's friend.

=cut

sub get_user_by_name_fan_name {
    my $self = shift;
    my $name = shift;
    my $fanName = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "user" . "/" . $name . "/" . "fan" . "/" . $fanName;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphotos (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all gallery photos.

=cut

sub get_galleryphotos {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphotos";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphotos_by_ids (@ids, \%params)

Given

=over

=item 0 gallery photo ids

=item 0 a map of optional API query arguments.

=back

Get a list of galleryphotos with the given ids

=cut

sub get_galleryphotos_by_ids {
    my $self = shift;
    my @ids = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphotos";
    $url .= '/' . join(',', @ids);
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphotos_by_id ($id, \%params)

Given

=over

=item 0 gallery photo id

=item 0 a map of optional API query arguments.

=back

Get a list of galleryphotos with the given ids

=cut

sub get_galleryphotos_by_id {
    my $self = shift;
    my $id = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphoto" . "/" . $id;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphotos_comments ($id, \%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get all gallery photo comments.

=cut

sub get_galleryphotos_comments {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphotos/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphotos_comments_by_ids (@ids, \%params)

Given

=over

=item 0 gallery photo ids

=item 0 a map of optional API query arguments.

=back

Get all gallery photo comments for given ids.

=cut

sub get_galleryphotos_comments_by_ids {
    my $self = shift;
    my @ids = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphotos";
    $url .= '/' . join(',', @ids) . "/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphoto_comments_by_id ($id, \%params)

Given

=over

=item 0 gallery photo id

=item 0 a map of optional API query arguments.

=back

Get top-level comments for a given gallery photo.

=cut

sub get_galleryphoto_comments_by_id {
    my $self = shift;
    my $id = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphoto" . "/" . $id . "/comments";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphoto_comment_by_photoid_commentid ($photoid, $commentid, \%params)

Given

=over

=item 0 gallery photo id

=item 0 comment id

=item 0 a map of optional API query arguments.

=back

Get one comment for a given gallery photo.

=cut

sub get_galleryphoto_comment_by_photoid_commentid {
    my $self = shift;
    my $photoid = shift;
    my $commentid = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphoto" . "/" . $photoid . "/comment" . "/" .$commentid;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_galleryphoto_comment_replies_by_photoid_commentid ($photoid, $commentid, \%params)

Given

=over

=item 0 gallery photo id

=item 0 comment id

=item 0 a map of optional API query arguments.

=back

Get one level of replies to one comment for a given gallery photo.

=cut

sub get_galleryphoto_comment_replies_by_photoid_commentid {
    my $self = shift;
    my $photoid = shift;
    my $commentid = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "galleryphoto" . "/" . $photoid . "/comment" . "/" .$commentid . "/replies";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_media (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get a list of all media.

=cut

sub get_media {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "media";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_media_by_name ($short_name, \%params)

Given

=over

=item 0 the medium short_name

=item 0 a map of optional API query arguments.

=back

Get a specified medium.

=cut

sub get_media_by_name {
    my $self = shift;
    my $short_name = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "medium" . "/" . $short_name;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_containers (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Get a list of all containers.

=cut

sub get_containers {
    my $self = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "containers";
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 get_container_by_name ($short_name, \%params)

Given

=over

=item 0 the container short_name

=item 0 a map of optional API query arguments.

=back

Get a specified container.

=cut

sub get_container_by_name {
    my $self = shift;
    my $short_name = shift;
    my $queryargs = shift;
    my $url = $self->{apiurl} . "/" . "container" . "/" . $short_name;
    $url .= $self->handle_args($queryargs);
    my $req = $self->{ua}->get($url);
    return ($req->is_success) ?  JSON::Any->jsonToObj($req->content) : undef;
}

=pod

=head2 handle_args (\%params)

Given

=over

=item 0 a map of optional API query arguments.

=back

Returns the query string for an API request.

=cut

sub handle_args {
    my $self = shift;
    my $queryargs = shift;
    $$queryargs{'type'} =  $self->{type};
    $$queryargs{'appkey'} =  $self->{appkey};
    my @sets = ();
    foreach my $k (keys (%{$queryargs})) {
         push(@sets, '' . $k . '=' . $$queryargs{$k});
    }
    my $url = '?' . join('&', @sets);
    return $url;
}
1;
__END__


=head1 DESCRIPTION

This module allows developers to quickly consume and interface with the Digg API as defined at L<http://apidoc.digg.com>

=head1 EXAMPLES

=over

=item my $digg = Net::Digg->new();

=item # Print the user that submitted the latest upcoming story.

=item my $result = $digg->get_upcoming_stories();

=item print $result->{ 'stories' }[0]->{'title'};

=item # Print the titles of the twenty latest popular stories

=item my %params = ('count' => 20);

=item $result = $digg->get_popular_stories(\%params);

=item my $stories = $result->{'stories'};

=item foreach $story (@$stories) {

=item print $story->{'title'} . "\n";

=item }

=back

=head1 CONFIGURATION AND ENVIRONMENT
  
Net::Digg uses LWP internally. Any environment variables that LWP supports should be supported by Net::Digg.

=head1 DEPENDENCIES

=over

=item L<LWP::UserAgent>

=item L<JSON::Any>

=back

=head1 BUGS AND LIMITATIONS

I decided to use JSON::Any to parse and convert the JSON returned from the Digg API.
The main reason for this is that other similar modules seemed to be using this strategy.
I should check to see if there is easier or more desirable way to handle the returned data.

Please report any bugs or feature requests to
C<bug-net-digg@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 VERSION

This document describes Net::Digg version 0.1.

=head1 AUTHOR

 Kurt Wilms
 wilms@cs.umn.edu
 http://www.kurtwilms.com/

 Hey, if you download this module, drop me an email! That's the fun
 part of this whole open source thing.
       
=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
in the distribution and available in the CPAN listing for
Net::Digg (see www.cpan.org or search.cpan.org).

=head1 DISCLAIMER

To the maximum extent permitted by applicable law, the author of this
module disclaims all warranties, either express or implied, including
but not limited to implied warranties of merchantability and fitness
for a particular purpose, with regard to the software and the
accompanying documentation.

=cut
