package Mojo::Snoo;
use Moo;

extends 'Mojo::Snoo::Base';

use Mojo::Snoo::Multireddit;
use Mojo::Snoo::Subreddit;
use Mojo::Snoo::Link;
use Mojo::Snoo::Comment;
use Mojo::Snoo::User;

our $VERSION = '0.15';

has content => (is => 'rw');

sub multireddit {
    shift->_create_object('Mojo::Snoo::Multireddit', @_);
}

sub subreddit {
    shift->_create_object('Mojo::Snoo::Subreddit', @_);
}

sub link {
    shift->_create_object('Mojo::Snoo::Link', @_);
}

sub comment {
    shift->_create_object('Mojo::Snoo::Comment', @_);
}

sub user {
    shift->_create_object('Mojo::Snoo::User', @_);
}

1;


__END__

=head1 NAME

Mojo::Snoo - Mojo wrapper for the Reddit API

=head1 DESCRIPTION

L<Mojo::Snoo> is a Perl wrapper for the Reddit API which
relies heavily on the Mojo modules. L<Mojo::Collection>
was the initial inspiration for going the Mojo route.
Skip to L<synopsis|Mojo::Snoo/SYNOPSIS> to see how
L<Mojo::Snoo> can be great for one-liners, quick
scripts, and full-blown applications!

=head1 SYNOPSIS

    use Mojo::Snoo;

    # OAuth ONLY. Reddit is deprecating cookie auth soon.
    my $snoo = Mojo::Snoo->new(
        username      => 'foobar',
        password      => 'very_secret',
        client_id     => 'oauth_client_id',
        client_secret => 'very_secret_oauth',
    );

    # upvote first 10 posts from /r/perl after a specific post ID
    $snoo->subreddit('perl')->links(
        10 => {after => 't3_39ziem'} => sub {
            say shift->code;    # callback receives Mojo::Message::Response
        }
    )->each(sub { $_->upvote });

    # print names of moderators from /r/Perl
    # Warning: mods() is subject to change!
    Mojo::Snoo->new->subreddit('Perl')->mods->each( sub { say $_->name } );

    # Print moderators via Mojo::Snoo::Subreddit
    Mojo::Snoo::Subreddit->new('Perl')->mods->each( sub { say $_->name } );

    # print title and author of the newest "self" posts from /r/perl
    Mojo::Snoo::Subreddit->new('Perl')->links_new(50)->grep(sub { $_->is_self })
      ->each(sub { say $_->title, ' posted by ', $_->author });

    # get the top 3 controversial links on /r/AskReddit
    @links = Mojo::Snoo::Subreddit->new('Perl')->links_contro_all(3);

    # print past week's top video URLs from /r/videos
    Mojo::Snoo::Subreddit->new('Perl')->links_top_week->each( sub { say $_->url } );

    # print the /r/Perl subreddit description
    say Mojo::Snoo->new->subreddit('Perl')->about->description;

    # even fetch a subreddit's header image!
    say Mojo::Snoo->new->subreddit('Perl')->about->header_img;

=head1 METHODS

=head2 multireddit

Returns a L<Mojo::Snoo::Multireddit> object.

=head2 subreddit

Returns a L<Mojo::Snoo::Subreddit> object.

=head2 link

Returns a L<Mojo::Snoo::Link> object.

=head2 comment

Returns a L<Mojo::Snoo::Comment> object.

=head2 user

Returns a L<Mojo::Snoo::User> object.

=head1 WHY SNOO?

Snoo is reddit's alien mascot. Not to be confused
with L<snu-snu|https://en.wikipedia.org/wiki/Amazon_Women_in_the_Mood>.

Reddit's L<licensing changes|https://www.reddit.com/r/redditdev/comments/2ujhkr/important_api_licensing_terms_clarified/>
prohibit the word "reddit" from being used in the name of reddit API clients.

=head1 API DOCUMENTATION

Please see the official L<Reddit API documentation|http://www.reddit.com/dev/api>
for more details regarding the usage of endpoints. For a better idea of how
OAuth works, see the L<Quick Start|https://github.com/reddit/reddit/wiki/OAuth2-Quick-Start-Example>
and the L<full documentation|https://github.com/reddit/reddit/wiki/OAuth2>. There is
also a lot of useful information of the L<redditdev subreddit|http://www.reddit.com/r/redditdev>.

=head1 SEE ALSO

L<ojo::Snoo>

L<Mojolicious::Command::snoodoc>

=head1 LICENSE

Copyright (C) 2015 by Curtis Brandt

The (two-clause) FreeBSD License. See LICENSE for details.
