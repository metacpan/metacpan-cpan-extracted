package Silki::Role::Controller::User;
{
  $Silki::Role::Controller::User::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use File::MimeInfo qw( mimetype );
use Silki::I18N qw( loc );

use Moose::Role -traits => 'MooseX::MethodAttributes::Role::Meta::Role';

requires qw( _set_user _make_user_uri );

after '_set_user' => sub {
    my $self    = shift;
    my $c       = shift;
    my $user_id = shift;

    my $user;

    if ( $user_id eq 'guest' ) {
        $user = Silki::Schema::User->GuestUser();
    }
    else {
        $user = Silki::Schema::User->new( user_id => $user_id );
    }

    $c->redirect_and_detach( $c->domain()->uri( with_host => 1 ) )
        unless $user;

    my $wiki = $c->stash()->{wiki};

    my %profile
        = $c->user()->user_id() == $user->user_id()
        ? (
        label   => loc('Your profile'),
        tooltip => loc('View details about your profile'),
        )
        : (
        label   => $user->best_name(),
        tooltip => loc( 'Information about %1', $user->best_name() ),
        );

    $c->add_tab(
        {
            uri => $self->_make_user_uri( $c, $user ),
            id  => 'profile',
            %profile,
        }
    );

    $c->stash()->{user} = $user;
};

sub user : Chained('_set_user') : PathPart('') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub user_GET_html {
    my $self = shift;
    my $c    = shift;

    $c->tab_by_id('profile')->set_is_selected(1);

    my $user = $c->stash()->{user};

    unless ( $user->is_system_user() ) {
        if ( $user->user_id() == $c->user()->user_id() ) {
            $c->stash()->{user_wikis} = $user->all_wikis()
                if $user->all_wiki_count();
        }
        elsif ( !$c->user()->is_system_user() ) {
            $c->stash()->{shared_wikis}
                = $user->wikis_shared_with( $c->user() );
        }
    }

    $c->stash()->{template} = '/user/profile';
}

sub user_PUT {
    my $self = shift;
    my $c    = shift;

    my $params = $c->request()->params();

    my $user = $c->stash()->{user};

    my $can_edit = 0;
    my $key      = $params->{confirmation_key};
    if ($key) {
        $can_edit = 1
            if ( $user->confirmation_key() || q{} ) eq $key;
    }
    else {
        $can_edit = $c->user()->can_edit_user($user);
    }

    $c->redirect_and_detach( $self->_make_user_uri( $c, $user ) )
        unless $can_edit;

    my $message;
    my $uri;

    if (   exists $params->{is_disabled}
        && $c->user()->is_admin()
        && $c->user()->user_id() != $user->user_id() ) {

        $user->update(
            is_disabled => $params->{is_disabled},
            user        => $c->user(),
        );

        $message
            = $params->{is_disabled}
            ? loc(
            'The account for %1 has been disabled.',
            $user->best_name()
            )
            : loc(
            'The account for %1 has been enabled.',
            $user->best_name()
            );

        $uri = $c->domain()->application_uri( path => '/users' );
    }
    else {
        my %update = $c->request()->user_params();
        $update{confirmation_key} = undef
            if defined $key;
        $update{preserve_password} = 1;

        my @errors = $self->_check_passwords_match( \%update );

        my $required_activation = $user->requires_activation();

        unless (@errors) {
            my $upload = $c->request()->upload('image');

            eval {
                $user->update( %update, user => $c->user(), );

                if ($upload) {
                    if ( my $image = $user->image() ) {
                        $image->delete();
                    }

                    Silki::Schema::UserImage->insert(
                        user_id   => $user->user_id(),
                        mime_type => mimetype( $upload->tempname() ),
                        file_size => $upload->size(),
                        contents =>
                            do { my $fh = $upload->fh(); local $/; <$fh> },
                    );
                }
            };

            my $e = $@;
            die $e if $e && !ref $e;

            push @errors, @{ $e->errors() } if $e;
        }

        $self->_user_update_error( $c, \@errors, \%update )
            if @errors;

        $c->set_authen_cookie( value => { user_id => $user->user_id() } )
            if $c->user()->is_guest();

        $message
            = $required_activation ? loc(
            'Your account has been activated. Welcome to the site, %1',
            $user->best_name()
            )
            : $key || $user->user_id() == $c->user()->user_id()
            ? loc('Your preferences have been updated.')
            : loc(
            'Preferences for ' . $user->best_name() . ' have been updated.' );

        $uri = $self->_make_user_uri( $c, $user );
    }

    $c->session_object()->add_message($message);

    $c->redirect_and_detach($uri);
}

sub _check_passwords_match {
    my $self   = shift;
    my $params = shift;

    return unless defined $params->{password};

    my $pw2 = delete $params->{password2};
    return
        if defined $pw2 && $params->{password} eq $pw2;

    # Deleting both passwords ensures that any update we attempt after this
    # will fail, unless the user also provided an openid, in which case we
    # might as well let it succeed.
    delete @{$params}{qw( password password2 )};

    return {
        field => 'password',
        message =>
            loc('The two passwords you provided did not match'),
    };
}

sub _user_update_error {
    my $self      = shift;
    my $c         = shift;
    my $errors    = shift;
    my $form_data = shift;

    delete @{$form_data}{qw( password password2 )};

    my $uri
        = $c->request()->params()->{confirmation_key}
        ? $c->stash()->{user}->confirmation_uri(
        view => 'preferences_form',
        host => $c->domain()->web_hostname(),
        )
        : $self->_make_user_uri(
        $c,
        $c->stash()->{user},
        'preferences_form',
        );

    $c->redirect_with_error(
        error     => $errors,
        uri       => $uri,
        form_data => $form_data,
    );
}

sub preferences_form : Chained('_set_user') : PathPart('preferences_form') : Args(0) {
    my $self = shift;
    my $c    = shift;

    my $user = $c->stash()->{user};

    $c->redirect_and_detach( $self->_make_user_uri( $c, $user ) )
        unless $c->user()->can_edit_user($user);

    $c->stash()->{template} = '/user/preferences-form';
}

1;

# ABSTRACT: Provides user-related methods and actions

__END__
=pod

=head1 NAME

Silki::Role::Controller::User - Provides user-related methods and actions

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

