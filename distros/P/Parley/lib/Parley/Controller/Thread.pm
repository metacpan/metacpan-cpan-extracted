package Parley::Controller::Thread;

use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';
use Data::SpreadPagination;

use Parley::App::Error qw( :methods );
use Parley::App::Notification qw( :watch );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Global class data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my %dfv_profile_for = (
    # DFV validation profile for adding a new topic
    new_topic => {
        required    => [qw( thread_subject thread_message )],
        optional    => [qw( watch_on_post )],
        filters     => [qw( trim )],
        msgs => {
            format  => q{%s},
            missing => q{One or more required fields are missing},
        },
    },

    # DFV validation profile for adding a reply to an existing topic
    new_reply => {
        required    => [qw( thread_message )],
        optional    => [qw( thread_subject lock_thread watch_on_post )],
        filters     => [qw( trim )],
    },
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller Actions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub add : Local {
    my ($self, $c) = @_;

    # make sure we're logged in
    $c->login_if_required($c->localize(q{LOGIN NEW TOPIC}));

    # make sure we're authenticated
    # XXX

    # deal with posting banned by IP
    my $ip = $c->request->address;
    my $posting_banned =
        $c->model('ParleyDB::IpBan')->is_posting_banned($ip);
    if ($posting_banned) {
        $c->stash->{template} = 'user/posting_ip_banned';
        return;
    }

    # if we have a form POST ...
    if (defined $c->request->method() and $c->request->method() eq 'POST') {
        $self->_add_new_thread($c);
    }
    # otherwise we continue merrily on our way, and simply display the
    # thread/add page
    else {
        # thread/add template shown automagically
    }
}

sub next_post : Local {
    my ($self, $c) = @_;

    # make sure we're logged in
    $c->login_if_required($c->localize(q{LOGIN THREAD CONTINUE}));

    # get the most recent post the user has seen
    my $last_viewed_post = $c->model('ParleyDB')->resultset('Thread')->last_post_viewed_in_thread(
        $c->_authed_user(),
        $c->_current_thread(),
    );

    # get the post after the last one viewed, and make this the current post
    $c->_current_post(
        $c->model('ParleyDB')->resultset('Post')->next_post(
            $last_viewed_post
        )
    );

    # view the next post (now the current post)
    $c->detach('/post/view');
}

sub recent : Local {
    my ($self, $c) = @_;
    $c->stash->{thread_list} =
        $c->model('ParleyDB')->resultset('Thread')->recent($c);

    # setup the pager
    $self->_prepare_pager($c, $c->stash->{thread_list});

    return;
}

sub reply : Local {
    my ($self, $c) = @_;

    # make sure we're logged in
    $c->login_if_required($c->localize(q{LOGIN ADD REPLY}));

    # make sure we're authenticated
    # XXX

    # deal with posting banned by IP
    my $ip = $c->request->address;
    my $posting_banned =
        $c->model('ParleyDB::IpBan')->is_posting_banned($ip);
    if ($posting_banned) {
        $c->stash->{template} = 'user/posting_ip_banned';
        return;
    }

    # can't reply to a locked thread
    if ($c->_current_thread()->locked()) {
        #die q{can't reply to a locked thread!};
        $c->stash->{error}{message} = $c->localize(q{REPLY LOCKED THREAD});
        return;
    };

    # if we have a current post, then we're performing a quoted reply
    # (otherwise we should have the thread that we're adding a reply to)
    # are we quoting a post that we're replying to?
    if (defined $c->_current_post()) {
        $c->stash->{quote_post} = $c->_current_post();
    }

    # get the post we're replying to
    $self->_get_thread_reply_post($c);

    # if we have a form POST ...
    if (defined $c->request->method()
            and $c->request->method() eq 'POST'
            and defined $c->request->param('post_reply')
    ) {
        $self->_add_new_reply($c);
    }
    # other wise we continue merrily on our way, and simply display the
    # thread/reply page
    else {
        # thread/reply template shown automagically
    }
}

sub view : Local {
    my ($self, $c) = @_;

    if (not defined $c->_current_thread) {
        parley_die($c, $c->localize('There is no current thread to view'));
        return;
    }

    # page to show - either a param, or show the first
    $c->stash->{current_page}= $c->request->param('page') || 1;

    # if we have a current_post, view the page with the post on it
    if ($c->_current_post) {
        $c->detach('/post/view');
    }

    ##################################################
    # get all the posts in the thread
    ##################################################
    $c->stash->{post_list} = $c->model('ParleyDB')->resultset('Post')->search(
        {
            'me.thread_id' => $c->_current_thread->id(),
        },
        {
            order_by    => [\'me.created ASC'],
            rows        => $c->config->{posts_per_page},
            page        => $c->stash->{current_page},

            prefetch => [
                { thread => {'forum'=>'last_post'} },
                { creator => 'authentication' },
                #{ reply_to => 'creator' },
                #{ quoted_post => 'creator' },
                'reply_to',
                'quoted_post',
            ],
        }
    );

    ##################################################
    # updates triggered by viewing a thread
    ##################################################
    {
        $self->_increase_thread_view_count($c);
    }

    ##################################################
    # some updates for logged in users
    ##################################################
    if ($c->_authed_user) {
        # update thread_view for user
        $self->_update_thread_view($c);

        # store thread watch status info
        $self->_watching_thread($c);
    }

    ##################################################
    # general information for all viewers
    ##################################################
    {
        # get the number of people watching the thread
        $self->_thread_watch_count($c);

        # setup the pager
        #$self->_thread_view_pager($c);
        $self->_prepare_pager($c, $c->stash->{post_list});
    }

    1; # return 'true'
}

sub watch :Local {
    my ($self, $c) = @_;

    # the watch parameter tells us if we're adding or removing a watch
    # if it's not specified, default action os to ADD a watch
    my $watched = $c->request->param('watch');
    if (not defined $watched) {
        $watched = 1;
    }

    # need to be logged in to watch threads
    $c->login_if_required($c->localize(q{LOGIN WATCH TOPIC}));

    # get the ThreadView so we can update it
    my $thread_view = $c->model('ParleyDB')->resultset('ThreadView')->find(
        {
            person_id  => $c->_authed_user()->id(),
            thread_id  => $c->_current_thread()->id(),
        },
        {
            prefetch => [
                'person',
                { 'thread' => [qw/ forum creator last_post/] },
            ],
        }
    );

    # if we couldn't find a thread view, then something odd is happening -
    # logged in users should always have a thread_view entry
    if (not defined $thread_view) {
        $c->stash->{error}{message} = $c->localize(q{THREAD WATCH FAILED});
        $c->log->error(q{User doesn't have a thread_view entry});
        return;
    }

    # we have a thread_view entry for the user, so update it, and redirect the
    # user back to the thread

    # update the watched status
    $thread_view->watched( $watched );
    $thread_view->update();

    # if we have a current post we can use that to return to the "right
    # place" in the thread
    if (defined $c->_current_post()) {
        $c->detach('/post/view');
    }
    # otherwise we want to redirect back to the same page in the current
    # thread
    else {
        my ($page_number, $redirect_url);

        # page to show - either a param, or show the first
        $page_number = $c->request->param('page') || 1;

        # build the URL to redirect to
        $redirect_url = $c->uri_for(
            '/thread/view',
            {
                thread  => $c->_current_thread()->id(),
                page    => $page_number,
            }
        );

        # redirect to the apropriate place
        $c->response->redirect( $redirect_url );
        return;
    }
}

sub watches : Local {
    my ($self, $c) = @_;

    # make sure we're logged in
    $c->login_if_required($c->localize(q{LOGIN VIEW WATCHES}));

    # watched threads
    my $watches = $c->model('ParleyDB')->resultset('ThreadView')->search(
        {
            person_id   => $c->_authed_user()->id(),
            watched     => 1,
        },
        {
            order_by    => [\'last_post.created DESC'],
            join        => {
                'thread' => 'last_post',
            },

            prefetch => [
                { person   => 'authentication' },
                { 'thread' => [
                    'forum',
                    #'creator',
                    { creator   => 'authentication' },
                    { 'last_post' => 'creator' },
                  ]
                },
            ],
        }
    );
    $c->stash->{thread_watches} = $watches;

    # if we've got a list of threads to stop watching ...
    if (my @thread_ids = $c->request->param('stop_watching')) {
        foreach my $thread_id ( @thread_ids ) {
            # get the ThreadView so we can update it
            my $thread_view = $c->model('ParleyDB')->resultset('ThreadView')->find(
                {
                    person_id  => $c->_authed_user()->id(),
                    thread_id  => $thread_id,
                },
                {
                    prefetch => [
                        'person',
                        { 'thread' => [qw/ forum creator last_post/] },
                    ],
                }
            );

            # if we couldn't find a thread view, then something odd is happening -
            # logged in users should always have a thread_view entry
            if (not defined $thread_view) {
                $c->stash->{error}{message} = $c->localize(q{THREAD WATCH FAILED});
                $c->log->error(q{User doesn't have a thread_view entry});
                return;
            }

            # we have a thread_view entry for the user, so update it

            # update the watched status
            $thread_view->watched( 0 );
            $thread_view->update();
        }
    }

    return;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller (Private/Helper) Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _add_new_reply {
    my ($self, $c) = @_;
    my ($new_reply);

    # validate the form data
    $c->form(
        $dfv_profile_for{new_reply}
    );

    # deal with missing/invalid fields
    if ($c->form->has_missing()) {
        $c->stash->{view}{error}{message} = $c->localize(q{DFV FILL REQUIRED});
        foreach my $f ( $c->form->missing ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
        return;
    }
    elsif ($c->form->has_invalid()) {
        $c->stash->{view}{error}{message} = $c->localize(q{DFV FIELDS INVALID});
        foreach my $f ( $c->form->invalid ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
        return;
    }

    # otherwise, the form data is ok ...
    else {
        # try to add the reply to the thread
        eval {
            $new_reply = $c->model('ParleyDB')->schema->txn_do(
                sub { return $self->_txn_add_new_reply($c) }
            );
        };
        # deal with any transaction errors
        if ($@) {                                   # Transaction failed
            die "something terrible has happened!"  #
                if ($@ =~ /Rollback failed/);       # Rollback failed

            $c->stash->{error}{message} = qq{Database transaction failed: $@};
            $c->log->error( $@ );
            return;
        }
    }

    # getting here means we validated the form, and added required data for the
    # new thread

    # set the current post
    $c->_current_post( $new_reply );

    # let interested parties know about the new post
    notify_watchers( $c, $new_reply );

    # view the "next post" in the new thread
    $c->detach('next_post');
}

sub _add_new_thread {
    my ($self, $c) = @_;
    my ($new_thread);

    # validate the form data
    $c->form(
        $dfv_profile_for{new_topic}
    );

    # deal with missing/invalid fields
    if ($c->form->has_missing()) {
        $c->stash->{view}{error}{message} = $c->localize(q{DFV FILL REQUIRED});
        foreach my $f ( $c->form->missing ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
    }
    elsif ($c->form->has_invalid()) {
        $c->stash->{view}{error}{message} = $c->localize(q{DFV FIELDS INVALID});
        foreach my $f ( $c->form->invalid ) {
            push @{ $c->stash->{view}{error}{messages} }, $f;
        }
    }

    # otherwise, the form data is ok ...
    else {
        # try to add the thread
        eval {
            $new_thread = $c->model('ParleyDB')->schema->txn_do(
                sub { return $self->_txn_add_new_thread($c) }
            );
        };
        # deal with any transaction errors
        if ($@) {                                   # Transaction failed
            die "something terrible has happened!"  #
                if ($@ =~ /Rollback failed/);       # Rollback failed

            $c->stash->{error}{message} = qq{Database transaction failed: $@};
            $c->log->error( $@ );
            return;
        }
        # set the current thread
        $c->_current_thread( $new_thread );

        # view the "next post" in the new thread
        $c->detach('next_post');
    }

    # getting here means we validated the form, and added required data for the
    # new thread

}

sub _get_thread_reply_post {
    my ($self, $c) = @_;
    my ($posts);

    # it would be good to display the relevant post in the thread, so people know
    # what they're replying to
    # - if adding a reply, assume the first post
    # - if we have a post value, then that's the one we're replying to
    if (defined $c->_current_post()) {
        # get the specific post we're responding to
        $posts = $c->model('ParleyDB')->resultset('Post')->search(
            {
                'me.id'     => $c->_current_post()->id(),
            },
            {
                rows        => 1,
            }
        );
    }
    elsif (defined $c->_current_thread()) {
        # get the first post in the thread
        $posts = $c->model('ParleyDB')->resultset('Post')->search(
            {
                'thread_id' => $c->_current_thread()->id(),
            },
            {
                order_by    => [\'created ASC'],
                rows        => 1,
            }
        );
    }
    else {
        $c->stash->{error}{message} = $c->localize(q{THREAD NO INFORMATION});
        return;
    }

    # if we don't have one post, something really odd happened
    if (1 != $posts->count()) {
        $c->stash->{error}{message} = $c->localize(q{THREAD NO POSTS});
        return;
    }

    # save the first (and only) post from our results
    $c->stash->{responding_to_post} = $posts->first();

    # be successful
    return 1;
}

sub _increase_post_count {
    my ($self, $c, $thread) = @_;

    # make the update in a transaction
    eval {
        # make sure $post_count is sane
        my $post_count = $thread->post_count() || 0;

        # increase the number of replies for the thread
        $thread->post_count(
            $post_count + 1
        );
        $thread->update();

        # increase the number of posts for the forum
        $thread->forum->post_count(
            ($thread->forum->post_count() || 0) + 1
        );
        $thread->forum->update;
    };
    # deal with any transaction errors
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        $c->stash->{error}{message} = qq{Database transaction failed: $@};
        $c->log->error( $@ );
        return;
    }
}


sub _increase_thread_view_count {
    my ($self, $c) = @_;

    # do nothing if we don't have a current_thread
    if (not defined $c->_current_thread) {
        $c->log->error( q{Can't increase view count for undefined thread} );
        return;
    }

    # increase the post count
    eval {
        $c->model('ParleyDB')->schema->txn_do(
            sub {
                $c->_current_thread->view_count(
                    $c->_current_thread->view_count + 1
                );
                $c->_current_thread->update;
            }
        )
    };
    # deal with any transaction errors
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        $c->stash->{error}{message} = qq{Database transaction failed: $@};
        $c->log->error( $@ );
        return;
    }
}

sub _prepare_pager {
    my ($self, $c, $list) = @_;

    $c->stash->{page} = $list->pager();

    my $pagination = Data::SpreadPagination->new(
        {
            totalEntries        => $c->stash->{page}->total_entries(),
            entriesPerPage      => $c->stash->{page}->entries_per_page(),
            currentPage         => $c->stash->{page}->current_page(),
            maxPages            => 4,
        }
    );
    $c->stash->{page_range_spread} = $pagination->pages_in_spread();
}


sub _thread_watch_count {
    my ($self, $c) = @_;

    # how many people are watching the current thread?
    $c->stash->{watcher_count} =
        $c->model('ParleyDB')->resultset('ThreadView')->count(
            {
                'thread_id' => $c->_current_thread()->id(),
                watched     => 1,
            }
        )
    ;
}

sub _update_last_post {
    my ($self, $c, $new_post) = @_;

    # do the updates in a transaction
    eval {
        $c->model('ParleyDB')->schema->txn_do(
            sub {
                # get the thread the post lives in
                my $thread = $new_post->thread;

                # get the forum the thread lives in
                my $forum = $thread->forum;

                # set the last_post for both forum and thread
                $forum-> last_post_id($new_post->id());
                $thread->last_post_id($new_post->id());
                $forum ->update();
                $thread->update();
            }
        );
    };
    # deal with any transaction errors
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        $c->stash->{error}{message} = qq{Database transaction failed: $@};
        $c->log->error( $@ );
        return;
    }
}

sub _update_person_post_info {
    my ($self, $c, $post) = @_;
    my $person = $c->_authed_user();

    # make the update in a transaction
    eval {
        # increase the post count for the user
        $person->post_count( $person->post_count() + 1 );
        # make a note of their last post
        $person->last_post_id( $post->id() );
        # push the changes back tot the db
        $person->update();
    };
    # deal with any transaction errors
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        $c->stash->{error}{message} = qq{Database transaction failed: $@};
        $c->log->error( $@ );
        return;
    }
}

sub _update_thread_view {
    my ($self, $c) = @_;
    my ($last_post, $last_post_timestamp);

    $c->log->info(q{called: _update_thread_view()});
    
    # get the last post on the page
    $last_post = $c->model('ParleyDB')->resultset('Post')->last_post_in_list(
        $c->stash->{post_list}
    );

    # get the timestamp of the last post
    $last_post_timestamp = $last_post->created();

    # make a note of when the user last viewed this thread, if a record doesn't already exist
    my $thread_view =
        $c->model('ParleyDB')->resultset('ThreadView')->find_or_create(
            {
                person_id   => $c->_authed_user()->id(),
                thread_id   => $c->_current_thread()->id(),
                timestamp   => $last_post_timestamp,
            },
            {
                prefetch => [
                    'person',
                    { 'thread' => [qw/ forum creator last_post/] },
                ],
            }
        )
    ;

    # set the timestamp the time of the last post on the page (unless the
    # existing time is later)
    if ($thread_view->timestamp() < $last_post_timestamp) {
        $thread_view->timestamp( $last_post_timestamp );
    }

    # update/store the thread_view record
    $thread_view->update;
}

sub _watching_thread {
    my ($self, $c) = @_;
    
    # find out if the user is watching the thread, and store it in the stash
    $c->stash->{watching_thread} =
        $c->model('ParleyDB')->resultset('ThreadView')->watching_thread(
            $c->_current_thread(),
            $c->_authed_user(),
        )
    ;
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions for database transactions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _txn_add_new_reply {
    my ($self, $c) = @_;
    $c->log->info( q{_txn_add_new_reply} );

    my ($new_post);

    # make sure we have a current thread
    if(not $c->_current_thread) {
        die q{No current thread in _txn_add_new_reply()};
    }

    # create a new post in the current thread
    $new_post = $c->model('ParleyDB')->resultset('Post')->create(
        {
            'thread_id' => $c->_current_thread()->id(),
            subject     => $c->form->valid->{thread_subject},
            message     => $c->form->valid->{thread_message},
            creator_id  => $c->_authed_user->id(),
            ip_addr     => $c->request->address(),
        }
    );

    # if we have current post information, then the post is in reply to another
    # post (i.e. quoted reply, not just reply-to-thread)
    if (defined $c->_current_post()) {
        # mark what the new post is in reply-to
        $new_post->reply_to_id( $c->_current_post()->id() );
    }

    # do we have a quoted post? if we do we need to store the
    # (potentially ammended) quoted text, and the actual post being
    # quoted (so we can get author, date, etc)
    if (defined $c->request->param('have_quoted_post')) {
        $new_post->quoted_post_id( $c->_current_post()->id() );
        $new_post->quoted_text   ( $c->req->param('quote_message') );
    }

    # the thread's last post is the one we just created
    $c->_current_thread()->last_post_id( $new_post->id );

    # we've got one post in our new thread
    $self->_increase_post_count($c, $c->_current_thread());

    # update information about the most recent forum/thread post
    $self->_update_last_post($c, $new_post);

    # update information about the poster (count, etc)
    $self->_update_person_post_info($c, $new_post);

    # would we like to lock the thread?
    if ($c->form->valid->{lock_thread} and $c->stash->{moderator}) {
        $new_post->thread->locked(1);
        $new_post->thread->update;
    }

    # would we like to set a thread watch at the time of posting?
    if ($c->form->valid->{watch_on_post}) {
        my $thread_view =
            $c->model('ParleyDB')->resultset('ThreadView')->find(
                {
                    person_id   => $c->_authed_user()->id(),
                    thread_id   => $c->_current_thread()->id(),
                },
            )
        ;
        if (defined $thread_view) {
            #$thread_view->timestamp( $new_post->created() );
            $thread_view->watched( 1 );
            $thread_view->update;
        }
    }

    # update the records
    $new_post->update;

    # return the new topic/thread
    return $new_post;
}

sub _txn_add_new_thread {
    my ($self, $c) = @_;
    
    my ($new_thread, $new_post);

    # create a new thread
    $new_thread = $c->model('ParleyDB')->resultset('Thread')->create(
        {
            forum_id    => $c->_current_forum->id(),
            subject     => $c->form->valid->{thread_subject},
            creator_id  => $c->_authed_user->id(),
        }
    );

    # create a new post in the new thread
    $new_post = $c->model('ParleyDB')->resultset('Post')->create(
        {
            thread_id   => $new_thread->id(),
            subject     => $c->form->valid->{thread_subject},
            message     => $c->form->valid->{thread_message},
            creator_id  => $c->_authed_user->id(),
            ip_addr     => $c->request->address(),
        }
    );

    # the thread's last post is the one we just created
    $new_thread->last_post_id( $new_post->id );

    # we've got one post in our new thread
    $new_thread->post_count( 1 );
    $new_thread->forum->post_count(
        ($new_thread->forum->post_count() || 0) + 1
    );

    # if the poster wants to add a watch we need to create the ThreadView record here
    # (it's a new thread so they can't have viewed it yet)
    if ($c->form->valid->{watch_on_post}) {
        my $thread_view =
            $c->model('ParleyDB')->resultset('ThreadView')->create(
                {
                    person_id   => $c->_authed_user()->id(),
                    thread_id   => $new_thread->id(),
                    watched     => 1,
                },
            )
        ;
    }

    # update information about the most recent forum/thread post
    $self->_update_last_post($c, $new_post);

    # update information about the poster (count, etc)
    $self->_update_person_post_info($c, $new_post);

    # update the records
    $new_thread->update;
    $new_thread->forum->update;
    $new_post->update;

    # return the new topic/thread
    return $new_thread;
}

1;

__END__

=pod

=head1 NAME

Parley::Controller::Thread - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 ACTIONS

=head2 add

Adds a new thread to a specified forum

=head2 next_post

Take the logged-in user to the post after the last one they have viewed. If
they haven't viewed any posts they should be taken to the first in the thread.
If the last post they saw was the last in the thread they should be taken to
the last post in the thread.

=head2 reply

Reply to a post in an existing thread.

=head2 view

This action prepares data in the stash for viewing the current thread.

=head2

This action is used to add/remove a watch for a given thread

=head1 PRIVATE METHODS

=head2 _add_new_reply($self,$c)

The guts of the process to add a new reply to an existing thread

=head2 _add_new_thread($self,$c)

The guts of the process to add a new thread/topic to a forum

=head2 _get_thread_reply_post($self,$c)

Returns the post being replied to in a thread.

=head2 _increase_post_count($self,$c,$thread)

Increase the number of posts (by one) for a given thread

=head2 _increase_thread_view_count($self,$c)

Inside a transaction, increase the number of views a thread has by one.

=head2 _thread_view_pager($self,$c)

Set-up C<$c-E<gt>stash-E<gt>{page}> and
C<$c-E<gt>stash-E<gt>{page_range_spread}> for the current thread.
These are used by the pager in the templates (Page X of Y, etc).

=head2 _thread_watch_count($self,$c)

Sets C<$c-E<gt>stash-E<gt>{watcher_count}> with the number of people who have a
watch set for the current thread.

=head2 _update_last_post($self,$c,$new_post)

Given a (new) post, update the values for the last post in the relevant thread
and forum.

=head2 _update_person_post_info($self,$c,$post)

Called when someone makes a new post, increments the total number of posts made
by the user, and updates the record of the last post they made.

=head2 _watching_thread

Sets C<$c-E<gt>stash-E<gt>{watching_thread}> with a true|false value indicating
whether the current authenticated user is watching the current thread.

Sets 

=head2 _update_thread_view

This method updates an existing record in the thread_view table, or creates a
new one if it doesn't exist.

The timestamp value for the record (keyed on I<person-thread>) is updated to
the timestamp of the creation time for the last post on the page - unless the
user has already viewed a page containing later posts.

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

vim: ts=8 sts=4 et sw=4 sr sta
