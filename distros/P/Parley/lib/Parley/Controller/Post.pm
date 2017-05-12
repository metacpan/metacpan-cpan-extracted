package Parley::Controller::Post;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';
use DateTime;
use HTML::ForumCode;

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Global class data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

my %dfv_profile_for = (
    # DFV validation profile for adding a new topic
    edit_post => {
        required    => [qw( post_message )],
        optional    => [qw( lock_post )],
        filters     => [qw( trim )],
        msgs => {
            format  => q{%s},
            missing => q{One or more required fields are missing},
        },
    },
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller Actions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub edit : Local {
    my ($self, $c) = @_;

    # if we don't have a post param, then return with an error
    unless (defined $c->_current_post) {
        $c->stash->{error}{message} = $c->localize(q{Incomplete URL});
        return;
    }

    # you need to be logged in to edit a post
    # (although non-logged users shouldn't see an edit link, you never know
    # what people will make-up or bookmark)
    $c->login_if_required($c->localize(q{EDIT LOGIN REQUIRED}));

    # deal with posting banned by IP
    my $ip = $c->request->address;
    my $posting_banned =
        $c->model('ParleyDB::IpBan')->is_posting_banned($ip);
    if ($posting_banned) {
        $c->stash->{template} = 'user/posting_ip_banned';
        return;
    }

    # you can only edit you own posts
    # (unless you're a moderator)
    if (
        (not $c->stash->{moderator})
            and
        ($c->_authed_user()->id() != $c->_current_post()->creator()->id())
    ) {
        $c->stash->{error}{message} = $c->localize(q{EDIT OWN POSTS ONLY});
        return;
    }

    # you can't edit post in a locked thread
    # you also can't edit individually locked posts (unless you are a
    # moderator)
    elsif (
        $c->_current_post->thread->locked
            or
        ($c->_current_post->locked and not $c->stash->{moderator})
    ) {
        $c->stash->{error}{message} = $c->localize(q{EDIT LOCKED POST});
        return;
    }

    # process the form submission
    elsif (defined $c->request->method() and $c->request->method() eq 'POST') {
        # validate the form data
        $c->form(
            $dfv_profile_for{edit_post}
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
        # otherwise; everything seems fine - edit the post
        # XXX why the HELL isn't this in a txn_do?!
        else {
            # update the post with the new information
            $c->_current_post->message( $c->form->valid->{post_message} );

            # set the edited time
            $c->_current_post->edited( DateTime->now() );

            # did an 'evil' admin edit the post?
            if (
                ($c->_current_post->creator_id != $c->_authed_user->id)
                    and
                $c->stash->{moderator}
            ) {
                # stamp the post with the admin editor's mark
                $c->_current_post->admin_editor_id(
                    $c->_authed_user->id
                );
                # if they asked for the thread to be locked
                # make it so...
                if ($c->form->valid->{lock_post}) {
                    $c->_current_post->locked( 1 );
                }
            }

            # store the updates in the db
            $c->_current_post->update();

            # view the (updated) post
            $c->detach('/post/view');
        }
    }
}

sub view : Local {
    my ($self, $c) = @_;

    # if we don't have a post param, then return with an error
    unless (defined $c->_current_post) {
        $c->stash->{error}{message} = $c->localize(q{Incomplete URL});
        return;
    }

    # work out what page in which thread the post lives
    my $thread = $c->_current_post->thread->id();
    my $page_number =  $c->model('ParleyDB')->resultset('Post')->page_containing_post(
        $c->_current_post,
        $c->config->{posts_per_page},
    );

    # build the URL to redirect to
    my $redirect_url =
        $c->uri_for(
            '/thread/view',
            {
                thread  => $thread,
                page    => $page_number,
            }
        )
        . "#" . $c->_current_post->id()
    ;

    # redirect to the relevant place in the appropriate thread
    $c->log->debug( "post/view: redirecting to $redirect_url" );
    $c->response->redirect( $redirect_url );
    return;
}

sub preview : Local {
    my ($self, $c) = @_;
    $c->log->warn('/post/preview used; please replace with /forumcode/preview');
    $c->forward('/forumcode/preview');
    return;
}


1;
__END__

=pod

=head1 NAME

Parley::Controller::Post - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 ACTIONS

=head2 view 

View a specific post, specified by the post in $c->_current_post

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

vim: ts=8 sts=4 et sw=4 sr sta
