package Parley::ResultSet::Thread;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::ResultSet';

# This is slightly complicated; the way we find the last post a user has seen
# in a thread is:
#
# - If there is a thread_view entry for person-thread then find the last post
#    made on or before that time
# - If there is no thread_view entry, then the user has never seen the thread
#   before, in which case the last post viewed is considered to be the
#   first post in the thread
sub last_post_viewed_in_thread {
    my ($self, $person, $thread) = @_;
    my ($last_viewed, $last_post) = @_;

    if (not defined $thread) {
        die "no thread defined";
    }

    my $schema = $self->result_source()->schema();

    # we need to be careful that we haven't deleted/hidden the post that
    # matches the exact timestamp of last_viewed for a thread - this is why we
    # use <= and not ==, since we can just return the latest undeleted post

    # get the entry (if any) for person-thread from the thread_view table
    $last_viewed = $schema->resultset('ThreadView')->find(
        {
            person_id  => $person->id(),
            thread_id  => $thread->id(),
        }
    );

    # if we don't have a $last_viewed, then return the thread's first post
    if (not defined $last_viewed) {
        warn "thread has never been viewed - returning first post in thread";

        # get all the posts in the thread, oldest first
        my $posts_in_thread = $schema->resultset('Post')->search(
            {
                thread_id  => $thread->id(),
            },
            {
                rows        => 1,
                order_by    => [\'created ASC'],
            }
        );

        # set the first post
        $last_post = $posts_in_thread->first();
    }

    # otherwise, find the most recent post made on or before the timestamp in
    # $last_viewed
    else {
        warn q{looking for a post on or before } . $last_viewed->timestamp();

        # get a list of posts created on or before our last-post time, newest
        # first
        my $list_of_posts = $schema->resultset('Post')->search(
            {
                created => {
                    '<=',
                    DateTime::Format::Pg->format_datetime(
                        $last_viewed->timestamp()
                    )
                },
                thread_id  => $thread->id(),
            },
            {
                rows        => 1,
                order_by    => [\'created DESC'],
            }
        );

        # the most recent post is the first (and only) post in our list
        $last_post = $list_of_posts->first();
    }

    # we should now have a Post object in $last_post
    if (not defined $last_post) {
        warn q{$last_post is undefined in last_post_viewed_in_thread()};
        return;
    }

    # return the last post ..
    return $last_post;
}

sub recent {
    my ($resultset, $c) = @_;
    my ($thread_list, $where, @join);

    # page to show - either a param, or show the first
    $c->stash->{current_page}= $c->request->param('page') || 1;

    # always want to join with last_post table
    @join = qw(last_post);

    # only search active forums
    $where->{'me.active'} = 1;

    # if we're only interested in a given forum
    if (defined $c->_current_forum()) {
        $where->{forum} = $c->_current_forum->id();
    }

    $resultset->search(
        $where,
        {
            join        => \@join,
            order_by    => [\'last_post.created DESC'],

            rows        => $c->config->{threads_per_page},
            page        => $c->stash->{current_page},

            prefetch => [
                {'creator' => 'authentication'},
                {'last_post' => 'creator'},
                'forum',
            ],
        }
    );
}

sub record_from_id {
    my ($resultsource, $thread_id) = @_;
    my ($rs);

    $rs = $resultsource->find(
        {
            'me.id'  => $thread_id,
        },
        {
            prefetch => [
                { 'forum' => 'last_post' },
                'creator',
                'last_post',
            ]
        }
    );

    return $rs;
}

1;
