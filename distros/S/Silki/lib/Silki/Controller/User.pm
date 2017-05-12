package Silki::Controller::User;
{
  $Silki::Controller::User::VERSION = '0.29';
}

use strict;
use warnings;
use namespace::autoclean;

use File::MimeInfo qw( mimetype );
use Silki::I18N qw( loc );
use Silki::Schema::TimeZone;
use Silki::Schema::User;
use Silki::Schema::UserImage;
use Silki::Util qw( string_is_empty );

use Moose;

BEGIN { extends 'Silki::Controller::Base' }

with qw(
    Silki::Role::Controller::Pager
    Silki::Role::Controller::User
);

sub _set_user : Chained('/') : PathPart('user') : CaptureArgs(1) {
}

sub _make_user_uri {
    my $self = shift;
    my $c    = shift;
    my $user = shift;
    my $view = shift || q{};

    return $user->uri( view => $view );
}

sub wikis : Chained('_set_user') : PathPart('wikis') : Args(0) : ActionClass('+Silki::Action::REST') {
}

sub wikis_GET {
    my $self = shift;
    my $c    = shift;

    my $user = $c->stash()->{user};

    my $wikis = $user->all_wikis();

    my @entity = map {
        {
            wiki_id    => $_->wiki_id(),
            title      => $_->title(),
            short_name => $_->short_name(),
        }
    } $wikis->all();

    return $self->status_ok( $c, entity => \@entity );
}

sub _set_confirmation : Chained('_set_user') : PathPart('confirmation') : CaptureArgs(1) {
    my $self = shift;
    my $c    = shift;
    my $key  = shift;

    my $user = Silki::Schema::User->new( confirmation_key => $key );

    $c->redirect_and_detach( $c->domain()->uri( with_host => 1 ) )
        unless $user && $user->user_id() == $c->stash()->{user}->user_id();

    return;
}

sub pending_confirmation : Chained('_set_confirmation') : PathPart('status') : Args(0)  {
    my $self = shift;
    my $c    = shift;

    $c->stash()->{template} = '/user/pending-confirmation';
}

sub confirmation_form : Chained('_set_confirmation') : PathPart('preferences_form') : Args(0)  {
    my $self = shift;
    my $c    = shift;

    $c->stash()->{template} = '/user/confirmation-form';
}

sub login_form : Local {
    my $self = shift;
    my $c    = shift;

    $c->stash()->{template} = '/user/login-form';
}

sub authentication : Local : ActionClass('+Silki::Action::REST') {
}

sub authentication_GET_html {
    my $self = shift;
    my $c    = shift;

    my $method = $c->request()->param('x-tunneled-method');

    if ( $method && $method eq 'DELETE' ) {
        $self->authentication_DELETE($c);
        return;
    }
    else {
        $c->redirect_and_detach(
            $c->domain()->application_uri( path => '/user/login_form' ) );
    }
}

sub authentication_POST {
    my $self = shift;
    my $c    = shift;

    my $username = $c->request()->params->{username};
    my $pw       = $c->request()->params->{password};

    my @errors;

    push @errors, {
        field   => 'password',
        message => loc('You must provide a password.')
        }
        if string_is_empty($pw);

    my $user;
    unless (@errors) {
        $user = Silki::Schema::User->new(
            username => $username,
        );

        if ($user) {
            if ( $user->is_disabled() ) {
                undef $user;

                push @errors,
                    loc(
                    'This user account has been disabled by a site admin.');
            }
            else {
                undef $user unless $user->check_password($pw);

                if ($user) {
                    $c->redirect_and_detach(
                        $user->confirmation_uri(
                            view      => 'status',
                            host      => $c->domain()->web_hostname(),
                            with_host => 1,
                        )
                    ) if $user->requires_activation();
                }

                push @errors,
                    loc(
                    'The username or password you provided was not valid.')
                    unless $user;
            }
        }
    }

    unless ($user) {
        $c->redirect_with_error(
            error => \@errors,
            uri   => $c->domain()->application_uri(
                path      => '/user/login_form',
                with_host => 1
            ),
            form_data => $c->request()->params(),
        );
    }

    $self->_login_user( $c, $user );
}

sub _login_user {
    my $self = shift;
    my $c    = shift;
    my $user = shift;

    my %expires
        = $c->request()->param('remember') ? ( expires => '+1y' ) : ();

    $c->set_authen_cookie(
        value => { user_id => $user->user_id() },
        %expires,
    );

    $c->session_object()
        ->add_message( 'Welcome to the site, ' . $user->best_name() );

    my $redirect_to = $c->request()->params()->{return_to}
        || $c->domain()->application_uri( path => q{} );

    $c->redirect_and_detach($redirect_to);
}

sub authentication_DELETE {
    my $self = shift;
    my $c    = shift;

    $c->unset_authen_cookie();

    $c->session_object()->add_message('You have been logged out.');

    my $redirect = $c->request()->params()->{return_to}
        || $c->domain()->application_uri( path => q{} );
    $c->redirect_and_detach($redirect);
}

sub forgot_password_form : Local {
    my $self = shift;
    my $c    = shift;

    $c->stash()->{template} = '/user/forgot-password-form';
}

sub password_reminder : Local : ActionClass('+Catalyst::Action::REST') {
}

sub password_reminder_POST {
    my $self = shift;
    my $c    = shift;

    my $username = $c->request()->params()->{username};

    my $user;

    my @errors;
    if ( string_is_empty($username) ) {
        push @errors, {
            field   => 'username',
            message => loc('You must provide an email address.'),
            };
    }
    else {
        $user = Silki::Schema::User->new( username => $username );

        if ($user) {
            push @errors,
                loc('This user account has been disabled by a site admin.')
                if $user->is_disabled();
        }
        else {
            push @errors, {
                field => 'username',
                message =>
                    loc( "There is no user with the email address %1.", $username ),
                };
        }
    }

    if (@errors) {
        $c->redirect_with_error(
            error => \@errors,
            uri   => $c->domain()->application_uri(
                path      => '/user/forgot_password_form',
                with_host => 1,
            ),
            form_data => {
                username  => $username,
                return_to => $c->request()->params()->{return_to},
            },
        );
    }

    $user->forgot_password( domain => $c->domain() );

    $c->session_object()->add_message(
        loc(
            'A message telling you how to change your password has been sent to your email address.'
        )
    );

    $c->redirect_and_detach(
        $c->domain()->application_uri(
            path      => '/user/forgot_password_form',
            with_host => 1,
            query =>
                { return_to => $c->request()->parameters()->{return_to} },
            with_host => 1,
        )
    );
}

sub purge_confirmation : Chained('_set_user') : PathPart('purge_confirmation') : Args(0) {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    $c->stash()->{template} = '/user/purge-confirmation';
}

sub user_DELETE {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my $user = $c->stash()->{user};

    my $msg = loc(
        'Deleted the user %1 - %2',
        $user->best_name(),
        $user->email_address()
    );

    $user->delete( user => $c->user() );

    $c->session_object()->add_message($msg);

    $c->redirect_and_detach(
        $c->domain()->uri( view => 'users', with_host => 1 ) );
}

sub new_user_form : Local {
    my $self = shift;
    my $c    = shift;

    $c->stash()->{template} = '/user/new-user-form';
}

sub users_collection : Path('/users') : ActionClass('+Silki::Action::REST') {
}

sub users_collection_GET_html {
    my $self = shift;
    my $c    = shift;

    $self->_require_site_admin($c);

    my $include_disabled = $c->request()->params()->{include_disabled};

    my $count_meth = $include_disabled ? 'Count' : 'ActiveUserCount';

    my ( $limit, $offset ) = $self->_make_pager( $c, Silki::Schema::User->$count_meth() );

    my $meth = $include_disabled ? 'All' : 'ActiveUsers';

    $c->stash()->{include_disabled} = $include_disabled;

    $c->stash()->{users} = Silki::Schema::User->$meth(
        limit  => $limit,
        offset => $offset,
    );

    $c->stash()->{template} = '/user/users';
}

sub users_collection_POST {
    my $self = shift;
    my $c    = shift;

    my %insert = $c->request()->user_params();

    my $upload = $c->request()->upload('image');

    my @errors = $self->_check_passwords_match(\%insert);

    $insert{requires_activation} = 1;

    my $user;
    unless (@errors) {
        eval {
            Silki::Schema->RunInTransaction(
                sub {
                    $user = Silki::Schema::User->insert(
                        %insert,
                        user => $c->user(),
                    );

                    if ($upload) {
                        Silki::Schema::UserImage->insert(
                            user_id   => $user->user_id(),
                            mime_type => mimetype( $upload->tempname() ),
                            file_size => $upload->size(),
                            contents =>
                                do { my $fh = $upload->fh(); local $/; <$fh> },
                        );
                    }
                }
            );
        };

        my $e = $@;
        die $e if $e && ! ref $e;

        push @errors, @{ $e->errors() } if $e;
    }

    if (@errors) {
        $c->redirect_with_error(
            error => \@errors,
            uri   => $c->domain()->application_uri(
                path      => '/user/new_user_form',
                with_host => 1
            ),
            form_data => \%insert,
        );
    }

    $user->send_activation_email(
        sender => Silki::Schema::User->SystemUser(),
        domain => $c->domain(),
    );

    $c->redirect_and_detach(
        $user->confirmation_uri(
            view      => 'status',
            host      => $c->domain()->web_hostname(),
            with_host => 1,
        )
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Controller class for users

__END__
=pod

=head1 NAME

Silki::Controller::User - Controller class for users

=head1 VERSION

version 0.29

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dave Rolsky.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut

