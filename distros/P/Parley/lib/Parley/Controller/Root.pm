package Parley::Controller::Root;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base qw<
    Catalyst::Controller::Validation::DFV
>;

use DateTime;
use List::MoreUtils qw(uniq);

use Parley::App::Terms qw( :terms );
use Parley::App::Error qw( :methods );

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

sub begin :Private {
    my ($self, $c) = @_;

    # deal with access banned by IP
    my $ip = $c->request->address;
    my $access_banned =
        $c->model('ParleyDB::IpBan')->is_access_banned($ip);
    if ($access_banned) {
        $c->stash->{template} = 'user/access_ip_banned';
        return;
    }

    return 1;
}

# pre-populate values in the stash if we're given "appropriate" information:
# - _authed_user
# - _current_post
# - _current_thread
# - _current_forum
sub auto : Private {
    my ($self, $c) = @_;

    # the cookie name for language choice(s)
    my $cookie_name = $c->config->{name} . q{_languages};

    ##################################################
    # do we have a request for a chosen language?
    ##################################################
    if (defined $c->request->param('lang')) {
        $c->response->cookies->{ $cookie_name } = {
            value       => $c->request->param('lang'),
            expires     => '+14d',
        };
        # redirect back to the page they were on
        $c->response->redirect(
            $c->request->referer()
        );
        return;
    }

    # preserve cookies
    if ($c->request->cookie($cookie_name)) {
        $c->response->cookies->{ $cookie_name } = {
            value       => $c->request->cookie($cookie_name)->value,
            expires     => '+14d',
        };

        # push cookie saved languages onto list of i18n languages the user accepts
        my (@languages);
        # fetch cookie language prefs (if any)
        push @languages,
            split(
                /\s+/,
                $c->request->cookie($cookie_name)->value
            )
        ;
        # get current list of accepted languages
        push @languages, @{$c->languages};
        # make the list have unique entries
        @languages = uniq @languages;
        # set new list of accepted languages
        $c->languages(
            \@languages
        );
    }

    # get a list of (all/available) forums
    $c->stash->{available_forums} =
        $c->model('ParleyDB::Forum')->available_list();

    ##################################################
    # do we have a post id in the URL?
    ##################################################
    if (defined $c->request->param('post')) {
        # make sure the paramter looks sane
        if (not $c->request->param('post') =~ m{\A\d+\z}) {
            $c->stash->{error}{message} =
                  $c->localize('non-integer post id passed')
                . ': ['
                . $c->request->param('post')
                . ']';
            return;
        }

        # get the matching post
        $c->_current_post(
            $c->model('ParleyDB::Post')->record_from_id(
                $c->request->param('post')
            )
        );

        # set the current_thread from the current_post
        $c->_current_thread(
            $c->_current_post->thread()
        );

        # set the current_forum from the current thread
        $c->_current_forum(
            $c->_current_thread->forum()
        );
    }
    ##################################################
    # (elsif) do we have a thread id in the URL?
    ##################################################
    elsif (defined $c->request->param('thread')) {
        # make sure the paramter looks sane
        if (not $c->request->param('thread') =~ m{\A\d+\z}) {
            $c->stash->{error}{message} =
                  $c->localize('non-integer thread id passed')
                . ': ['
                . $c->request->param('thread')
                . ']';
            return;
        }

        # get the matching thread
        $c->_current_thread(
            $c->model('ParleyDB::Thread')->record_from_id(
                $c->request->param('thread')
            )
        );

        # set the current_forum from the current thread
        $c->_current_forum(
            $c->_current_thread->forum()
        );
    }
    ##################################################
    # do we have a forum id in the URL?
    ##################################################
    elsif (defined $c->request->param('forum')) {
        # make sure the paramter looks sane
        if (not $c->request->param('forum') =~ m{\A\d+\z}) {
            $c->stash->{error}{message} =
                  $c->localize('non-integer forum id passed')
                . ': ['
                . $c->request->param('forum')
                . ']';
            return;
        }

        # get the matching forum
        $c->_current_forum(
            $c->model('ParleyDB::Forum')->record_from_id(
                $c->request->param('forum')
            )
        );
    }

    ############################################################
    # if we have a user ... fetch some info (if we don't already have it)
    ############################################################
    if ( $c->user and not defined $c->_authed_user ) {
        # FIXME : move this to the ResultSet class?
        # get the person info for the username
        my $row = $c->model('ParleyDB')->resultset('Person')->find(
            {
                'authentication.username'   => $c->user->username(),
            },
            {
                prefetch => [
                    'authentication',
                    { 'preference' => 'time_format' },
                ],
            },
        );
        $c->_authed_user( $row );

        # make sure they've agreed to any (new) T&Cs
        my $status = terms_check($c, $c->_authed_user);
        if (not $status) {
            $c->res->body('need to accept');
            return 0;
        }
    }

    ############################################################
    # if we have a suspended user ...
    ############################################################
    if (
        $c->_authed_user
            and
        $c->_authed_user->suspended
            and
        $c->request->path() !~ m{user/suspended}
            and
        $c->request->path() !~ m{user/logout}
    ) {
        $c->forward('/user/suspended');
        return 0;
    }


    ######################################
    # user's with 'site_moderator' role
    # get flagged as such
    # ####################################
    if (
        defined $c->_authed_user()
            and
        $c->check_user_roles('site_moderator')
    ) {
        $c->stash->{site_moderator} = 1;
    }

    ##################################################
    # if we are logged in and if we have a current_forum, can the (current)
    # user moderate it?
    ##################################################
    if (defined $c->_authed_user() and defined $c->_current_forum()) {
        # site_moderators can moderate anything
        if ($c->check_user_roles('site_moderator')) {
            $c->stash->{moderator} = 1;
        }
        else {
            # FIXME : move this to the ResultSet class?
            # look up person/forum
            my $results = $c->model('ParleyDB')->resultset('ForumModerator')->find(
                {
                    person_id       => $c->_authed_user()->id(),
                    forum_id        => $c->_current_forum()->id(),
                    can_moderate    => 1,
                },
                {
                    key     => 'forum_moderator_person_key',
                }
            );
            # if we found something, they must moderate the current forum
            if ($results) {
                $c->stash->{moderator} = 1;
            }
        }
    }

    # let things continue ...
    return 1;
}

# if someone hits the application index '/' then send them off to the default
# action (defined in the app-config)
sub index : Private {
    my ( $self, $c ) = @_;
    # redirect to the default action
    $c->response->redirect( $c->uri_for($c->config->{default_uri}) );
}

# by default show a 404 for anything we don't know about
sub default : Private {
    my ( $self, $c ) = @_;

    $c->response->status(404);
    $c->response->body( $c->localize('404 Not Found') );
}

sub access_denied :Local {
    my ($self, $c) = @_;
    parley_die($c,$c->localize('Unauthorized!'));
}

# deal with the end of the phase
sub render : ActionClass('RenderView') {
    my ($self, $c) = @_;
    
    # deal with any skinning
    $c->forward('skin');

    # if we have any error(s) in the stash, automatically show the error page
    if (defined $c->stash->{error}) {
        $c->stash->{template} = 'error/simple';
        $c->log->error( $c->stash->{error}{message} );
    }

    if (has_died($c)) {
        $c->stash->{template} = 'error/simple';
        $c->log->error( @{ $c->stash->{view}{error}{messages} } );
    }
}

sub skin : Private {
    my ($self, $c) = @_;

    my $skin = $c->skin;

    # we always want root (do we?)
    my $include_path = [
        $c->path_to( 'root' ),
    ];

    # if we are skinned?
    if (defined $skin) {
        # we always want root and "skin dir"
        push @{$include_path}, 
            $c->path_to( 'root', $skin);

        # we /might/ want to fall back on the default (base)
        if ($c->config->{skin_default_fallback}) {
            push @{$include_path}, 
                $c->path_to( 'root', 'base' );
        }
    }
    # use the base/ templates
    else {
        push @{$include_path}, 
            $c->path_to( 'root', 'base' );
    }

    # always (re)set the INCLUDE_PATH for TT
    $c->view('TT')->{include_path} = $include_path;
}

sub end : Private {
    my ($self, $c) = @_;

    # move some data into the stash
    $c->stash->{authed_user}    = $c->_authed_user;
    $c->stash->{current_post}   = $c->_current_post;
    $c->stash->{current_thread} = $c->_current_thread;
    $c->stash->{current_forum}  = $c->_current_forum;

    # render the page
    $c->forward('render');
    # fill in any forms
    $c->forward('refill_form');
}


1;

__END__


=pod

=head1 NAME

Parley::Controller::Root - Root Controller for Parley

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 auto

Used to fetch user-information if the user has authenticated.

Also pre-populate current_(post|thread|forum) values in the stash if we have
appropriate information in the URL's query parameters.

=head2 default

Emit a 404 status and a 'Not Found' message.

=head2 end

Attempt to render a view, if needed.

If I<error> is defined in the stash, render the error template.

=head2 index

Redirect to the applications default action, as defined by I<default_uri> in
parley.yml

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

vim: ts=8 sts=4 et sw=4 sr sta
