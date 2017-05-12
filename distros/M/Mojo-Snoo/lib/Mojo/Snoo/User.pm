package Mojo::Snoo::User;
use Moo;

extends 'Mojo::Snoo::Base';

use Mojo::Collection;

use constant FIELD => 'name';

has name => (
    is  => 'ro',
    isa => sub {
        die "User needs a name!" unless $_[0];
    },
    required => 1
);

sub BUILDARGS { shift->SUPER::BUILDARGS(@_ == 1 ? (name => shift) : @_) }

sub send_message {
    my $self = shift;

    # make sure we're clear of any captcha if required
    my ($captcha_id, $captcha_text) = $self->_solve_captcha();

    my %form = (
        api_type => 'json',
        captcha  => $captcha_text,
        iden     => $captcha_id,
        subject  => 'subject goes here',
        text     => 'body goes here',
        to       => $self->name,
    );
    $self->_do_request('POST', '/api/compose', %form);
}

1;

__END__

=head1 NAME

Mojo::Snoo::User - Mojo wrapper for Reddit Users

=head1 SYNOPSIS

    use Mojo::Snoo::User;

    # OAuth ONLY. Reddit is deprecating cookie auth soon.
    my $user = Mojo::Snoo::User->new(
        username      => 'foobar',
        password      => 'very_secret',
        client_id     => 'oauth_client_id',
        client_secret => 'very_secret_oauth',
    );

    # send message to /u/foobar
    $user->send_message(
        title => 'this is not spam',
        body  => q@Hi, how ya doin'?@,
    );

    # or do non-OAuth things with a user object
    my $user = Mojo::Snoo::User->new('username');

=head1 ATTRIBUTES

=head2 name

The name of the user. This is required for object
instantiation. The constructor can accept a single
string value or key/value pairs. Examples:

    Mojo::Snoo::User->new('reddit_buddy')->name;
    Mojo::Snoo::User->new(name => 'reddit_buddy')->name;

=head1 METHODS

=head2 send_message

Send private message to user.

    POST /api/compose.

OAuth is required for this method.

    # OAuth is required for this endpoint
    my $user = Mojo::Snoo::User->new(%oauth, name => 'some_user');

    $user->send_message(
        title => 'title goes here',
        body  => 'body goes here',
    );

B<Be aware!> This endpoint may require you to complete a CAPTCHA
if your account lacks sufficient karma. If this happens,
L<Mojo::Snoo::User> will provide you with a CAPTCHA image
link and wait for the answer via STDIN before proceding.

STDIN is really only useful for personal bots and scripts.
When L<Mojo::Snoo> supports more forms of authentication,
it would be nice to let the user change this via the
class constructor.

=head2 subreddit

Returns a L<Mojo::Snoo::Subreddit> object.

=head2 thing

Returns a L<Mojo::Snoo::Link> object.

=head2 comment

Returns a L<Mojo::Snoo::Comment> object.

=head2 user

Returns a L<Mojo::Snoo::User> object.

=head1 API DOCUMENTATION

Please see the official L<Reddit API documentation|http://www.reddit.com/dev/api>
for more details regarding the usage of endpoints. For a better idea of how
OAuth works, see the L<Quick Start|https://github.com/reddit/reddit/wiki/OAuth2-Quick-Start-Example>
and the L<full documentation|https://github.com/reddit/reddit/wiki/OAuth2>. There is
also a lot of useful information of the L<redditdev subreddit|http://www.reddit.com/r/redditdev>.

=head1 LICENSE

The (two-clause) FreeBSD License. See LICENSE for details.
