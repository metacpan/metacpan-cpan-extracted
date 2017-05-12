package Parley::ResultSet::Post;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use base 'DBIx::Class::ResultSet';

sub record_from_id {
    my ($resultset, $post_id) = @_;
    my ($rs);

    $rs = $resultset->find(
        {
            'me.id'  => $post_id,
        },
        {
            prefetch => [
                { thread => 'forum' },
                'creator',
                'reply_to',
                'quoted_post',
            ],
        }
    );

    return $rs;
}

sub people_posting_from_ip {
    my ($resultset, $ip_addr) = @_;
    my ($rs);

    $rs = $resultset->search(
        {
            ip_addr     => $ip_addr,
        },
        {
            distinct    => 1,
            columns     => [ qw/creator_id/ ],
        }
    );

    return $rs;
}

# we used to use ->slice() but it sopped working on page #2 (!!)
# this may be slower [not benchmarked] but it works
sub last_post_in_list {
    my ($self, $post_list) = @_;
    my ($current_post);

    while (my $tmp = $post_list->next()) {
        # do nothing, we're just iterating the list
        $current_post = $tmp;
        #warn qq{LOOP: } . ref($current_post);
    }
    # return the current post, which is the last one we saw
    # i.e. the last one in the list
    #warn qq{CURRENT: } . ref($current_post);
    return $current_post;
}


sub next_post {
    my ($self, $post) = @_;
    my $next_post;

    # we want to find the next post after the one we've been given, based on
    # creation time
    # if for some reason there are no matches, just return the post we were passed
    $next_post = $self->search(
        {
            created    => { '>' => DateTime::Format::Pg->format_datetime($post->created()) },
            thread_id  => $post->thread()->id(),
        },
        {
            rows    => 1,
        }
    );

    if (defined $next_post->first()) {
        return $next_post->first();
    }

    return $post;
}


sub page_containing_post {
    my ($self, $post, $posts_per_page) = @_;

    my $position_in_thread = $self->thread_position($post);

    # work out what page the Nth post is on
    my $page_number = int(($position_in_thread - 1) / $posts_per_page) + 1;

    return $page_number;
}


sub thread_position {
    my ($self, $post) = @_;

    if (not defined $post) {
        warn('$post id undefined in call to Parley::Model::ParleyDB::Post->thread_position()');
        return;
    }

    # explicitly 'deflate' the creation time, as DBIx::Class (<=v0.06003) doesn't deflate on search()
    my $position = $self->count(
        {
            thread_id  => $post->thread()->id(),
            created => {
                '<='   => DateTime::Format::Pg->format_datetime($post->created())
            },
        }
    );

    return $position;
}

1;
