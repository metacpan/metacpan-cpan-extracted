package Parley::Controller::Admin;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';

sub index : Private {
    my ( $self, $c ) = @_;

    $c->response->body('Matched Parley::Controller::Admin in Admin.');
}

sub auto : Private {
    my ($self, $c) = @_;
    $c->log->debug( 'Admin::auto()' );

    # if we're not a moderator, bounce back to where we came from
    if (not $c->stash->{moderator}) {
        $c->log->debug( 'not a moderator' );
        $c->response->redirect( $c->request->referer() );
        return 0;
    }

    # succeed
    $c->log->debug( 'a moderator' );
    return 1;
}

sub lock :Local {
    my ($self, $c) = @_;

    # the 'lock' parameter tells us if we're adding or removing a lock
    # if it's not specified, default action os to ADD a lock
    my $locked = $c->request->param('lock');
    if (not defined $locked) {
        $locked = 1;
    }
    $c->log->debug( qq{lock: $locked} );

    # we should already have the thread we're locking, but let's check anyway
    if (not defined $c->_current_thread()) {
        $c->stash->{error}{message} = $c->localize(q{ADMIN SPECIFY LOCK THREAD});
        $c->log->error( $c->localize(q{ADMIN SPECIFY LOCK THREAD}) );
        return;
    }

    # update the lock status
    $c->_current_thread()->locked( $locked );
    $c->_current_thread()->update();

    # go back to where we came from
    $c->response->redirect( $c->request->referer() );
    return;
}

sub sticky :Local {
    my ($self, $c) = @_;

    # the 'sticky' parameter tells us if we're adding or removing a sticky
    # if it's not specified, default action os to ADD a sticky
    my $sticky = $c->request->param('sticky');
    if (not defined $sticky) {
        $sticky = 1;
    }
    $c->log->debug( qq{sticky: $sticky} );

    # we should already have the thread we're sticking, but let's check anyway
    if (not defined $c->_current_thread()) {
        $c->stash->{error}{message}
            = $c->localize(q{ADMIN SPECIFY STICK THREAD});
        $c->log->error( $c->localize(q{ADMIN SPECIFY STICK THREAD}) );
        return;
    }

    # update the stick status
    $c->_current_thread()->sticky( $sticky );
    $c->_current_thread()->update();

    # go back to where we came from
    $c->response->redirect( $c->request->referer() );
    return;
}

=head1 NAME

Parley::Controller::Admin - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head2 index 

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
