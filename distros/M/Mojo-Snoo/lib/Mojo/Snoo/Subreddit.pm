package Mojo::Snoo::Subreddit;
use Moo;

extends 'Mojo::Snoo::Base';

use Mojo::Collection;
use Mojo::Snoo::Link;

use constant FIELD => 'name';

has name => (
    is  => 'ro',
    isa => sub {
        die "Subreddit needs a name!" unless $_[0];
    },
    required => 1
);

sub BUILDARGS { shift->SUPER::BUILDARGS(@_ == 1 ? (name => shift) : @_) }

sub mods {
    my $self = shift;
    my $path = '/r/' . $self->name . '/about/moderators';
    my $res = $self->_do_request('GET', $path);

    # Do we have a callback?
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    $res->$cb if $cb;

    my @mods = @{$res->json->{data}{children}};

    # FIXME should we return User objects instead? or combined?
    my @collection;
    for my $child (@mods) {
        my $pkg = 'Mojo::Snoo::Subreddit::Mods::' . $self->name . '::' . $child->{name};
        push @collection, $self->_monkey_patch($pkg, $child);
    }
    Mojo::Collection->new(@collection);
}

sub about {
    my $self = shift;
    my $path = '/r/' . $self->name . '/about';
    my $res = $self->_do_request('GET', $path);

    # Do we have a callback?
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    $res->$cb if $cb;

    my $pkg = 'Mojo::Snoo::Subreddit::About::' . $self->name;
    $self->_monkey_patch($pkg, $res->json->{data});
}

sub _toggle_subscribe {
    my ($self, $action) = @_;

    # Calling $self->about feels like a hack
    # However, a request is needed to get the t5_ name of a subreddit
    my %params = (action => $action, sr => $self->about->name);

    my $res = $self->_do_request('POST', '/api/subscribe', %params);

    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;
    $res->$cb if $cb;
}

sub subscribe   { shift->_toggle_subscribe('sub',   @_) }
sub unsubscribe { shift->_toggle_subscribe('unsub', @_) }

sub _submit {
    my $cb     = ref $_[-1] eq 'CODE' ? pop : undef;
    my $params = ref $_[-1] eq 'HASH' ? pop : {};

    my ($self, $kind, $title, $content) = @_;

    my $post_type = $kind eq 'self' ? 'text' : 'url';
    $params->{$post_type} = $content;

    $params->{title}  //= $title // '';
    $params->{sr}       = $self->name;
    $params->{api_type} = 'json';
    $params->{kind}     = $kind;

    my $res = $self->_do_request('POST', '/api/submit', %$params);

    $res->$cb if $cb;
}

sub submit_link { shift->_submit('link', @_) }
sub submit_text { shift->_submit('self', @_) }

sub _get_links {
    my $self = shift;

    my $path = '/r/' . $self->name;

    if (my $sort = shift) {
        $path .= "/$sort";
    }

    # Do we have a callback?
    my $cb = ref $_[-1] eq 'CODE' ? pop : undef;

    # Did we receive extra endpoint parameters?
    my $params = ref $_[-1] eq 'HASH' ? pop : {};

    # Define these from special method calls unless
    #   user has already done so via the params hash
    my $t     = shift;
    my $limit = shift;

    $params->{t}     ||= $t     || '';
    $params->{limit} ||= $limit || '';

    my $res = $self->_do_request('GET', $path, %$params);

    # run callback
    $res->$cb if $cb;

    my @children =
      map { $_->{kind} eq 't3' ? $_->{data} : () }    #
      @{$res->json->{data}{children}};

    my %args = map { $_ => $self->$_ } (
        qw(
          username
          password
          client_id
          client_secret
          )
    );
    Mojo::Collection->new(map { Mojo::Snoo::Link->new(%args, %$_) } @children);
}

sub links              { shift->_get_links(''             , ''     , @_) }
sub links_new          { shift->_get_links('new'          , ''     , @_) }
sub links_rising       { shift->_get_links('rising'       , ''     , @_) }
sub links_contro       { shift->_get_links('controversial', ''     , @_) }
sub links_contro_week  { shift->_get_links('controversial', 'week' , @_) }
sub links_contro_month { shift->_get_links('controversial', 'month', @_) }
sub links_contro_year  { shift->_get_links('controversial', 'year' , @_) }
sub links_contro_all   { shift->_get_links('controversial', 'all'  , @_) }
sub links_top          { shift->_get_links('top'          , ''     , @_) }
sub links_top_week     { shift->_get_links('top'          , 'week' , @_) }
sub links_top_month    { shift->_get_links('top'          , 'month', @_) }
sub links_top_year     { shift->_get_links('top'          , 'year' , @_) }
sub links_top_all      { shift->_get_links('top'          , 'all'  , @_) }

1;

__END__

=head1 NAME

Mojo::Snoo::Subreddit - Mojo wrapper for Reddit Subreddits

=head1 SYNOPSIS

    use Mojo::Snoo::Subreddit;

    # OAuth ONLY. Reddit is deprecating cookie auth soon.
    my $snoo = Mojo::Snoo::Subreddit->new(
        name          => 'perl',
        username      => 'foobar',
        password      => 'very_secret',
        client_id     => 'oauth_client_id',
        client_secret => 'very_secret_oauth',
    );

    # print each title from /r/perl post
    # (OAuth not required for this action)
    $snoo->links->each(sub { say $_->title });

=head1 ATTRIBUTES

=head2 name

The name of the subreddit. This is required for object
instantiation. The constructor can accept a single
string value or key/value pairs. Examples:

    Mojo::Snoo::Subreddit->new('perl')->name;
    Mojo::Snoo::Subreddit->new(name => 'perl')->name;

=head2 about

Returns the About section of a subreddit.

    GET /r/$subreddit/about

Returns a monkey-patched object containing all of the
keys under the JSON's "data" key. Example:

    my $about = Mojo::Snoo::Subreddit->new('perl')->about;

    say $about-title;
    say $about->description;
    say $about->description_html;

=head2 mods

Returns a list of the subreddit's moderators.

    GET /r/$subreddit/about/moderators

Returns a L<Mojo::Collection> object containing a list of
monkey-patched objects. Example:

    Mojo::Snoo::Subreddit->new('perl')->mods->each(
        sub {
            say $_->id;
            say $_->name;
            say $_->date;
            say $_->mod_permissions;
        }
    );

=head1 METHODS

=head2 links

Returns a L<Mojo::Collection> object containing a list of
L<Mojo::Snoo::Link> objects.

    GET /r/$subreddit

Accepts arguments for limit, API endpoint parameters, and
a callback (in that order). The default limit is 25 and
cannot be greater than 100. Callback receives a
L<Mojo::Message::Response> object.

    Mojo::Snoo::Subreddit-new('perl')->links;
    Mojo::Snoo::Subreddit-new('perl')->links(20);
    Mojo::Snoo::Subreddit->new('pics')->links_top(
        50 => {after => 't3_92dd8'} => sub {
            my $res = shift;
            say 'Response code: ' . $res->code;
        }
      )->each(
        sub {
            say $_->title;
        }
      );

=head2 links_new

Like L</links> but sorted by new.

    GET /r/$subreddit/new

=head2 links_rising

Like L</links> but sorted by rising.

    GET /r/$subreddit/rising

=head2 links_top

Like L</links> but sorted by top (most upvoted).

    GET /r/$subreddit/top

=head2 links_top_week

Like L</links_top> but from the past week.

    GET /r/$subreddit/top?t=week

=head2 links_top_month

Like L</links_top> but from the past month.

    GET /r/$subreddit/top?t=month

=head2 links_top_year

Like L</links_top> but from the past year.

    GET /r/$subreddit/top?t=year

=head2 links_top_all

Like L</links_top> but from all time.

    GET /r/$subreddit/top?t=all

=head2 links_contro

Like L</links> but sorted by controversial.

    GET /r/$subreddit/controversial

=head2 links_contro_week

Like L</links_contro> but from the past week.

    GET /r/$subreddit/controversial?t=week

=head2 links_contro_month

Like L</links_contro> but from the past month.

    GET /r/$subreddit/controversial?t=month

=head2 links_contro_year

Like L</links_contro> but from the past year.

    GET /r/$subreddit/controversial?t=year

=head2 links_contro_all

Like L</links_contro> but from all time.

    GET /r/$subreddit/controversial?t=all

=head2 subscribe

Subscribe to subreddit. Accepts callback.

    POST /api/subscribe

=head2 unsubscribe

Unsubscribe from subreddit. Accepts callback.

    POST /api/subscribe

=head1 API DOCUMENTATION

Please see the official L<Reddit API documentation|http://www.reddit.com/dev/api>
for more details regarding the usage of endpoints. For a better idea of how
OAuth works, see the L<Quick Start|https://github.com/reddit/reddit/wiki/OAuth2-Quick-Start-Example>
and the L<full documentation|https://github.com/reddit/reddit/wiki/OAuth2>. There is
also a lot of useful information of the L<redditdev subreddit|http://www.reddit.com/r/redditdev>.

=head1 LICENSE

The (two-clause) FreeBSD License. See LICENSE for details.
