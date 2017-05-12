package Parley::Controller::User::SignUp;

use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller::FormValidator';
use base 'Catalyst::Controller::reCAPTCHA';
use base 'Parley::ControllerBase::FormValidation';

use List::MoreUtils qw{ uniq };
use Digest::MD5 qw{ md5_hex };
use Email::Valid;
use Readonly;
use Time::Piece;
use Time::Seconds;

use Parley::App::DFV qw( :constraints );

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Global class data
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Readonly my $LIFETIME => Time::Seconds::ONE_WEEK;

my %dfv_profile_for = (
    'signup' => {
        required => [ qw(
                new_username new_password confirm_password email confirm_email
                first_name last_name forum_name
        ) ],

        filters => [qw(trim)],

        constraint_methods => {
            confirm_password =>
                dfv_constraint_confirm_equal(
                    {
                        fields => [qw/new_password confirm_password/],
                    }
                ),

            email =>
                dfv_constraint_valid_email(
                    {
                        fields => [qw/email/],
                    }
                ),

            confirm_email =>
                dfv_constraint_confirm_equal(
                    {
                        fields => [qw/email confirm_email/],
                    }
                ),
        },

        msgs => {
            constraints => {
                confirm_password => q{The passwords do not match},
                confirm_email => q{The email addresses do not match},
                email => q{You must enter a valid email address},
            },
            missing => q{One or more required fields are missing},
            format => '%s',
        },
    },
);

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller Actions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub begin :Private {
    my ($self, $c) = @_;

    # deal with logins banned by IP
    my $ip = $c->request->address;
    my $signup_banned =
        $c->model('ParleyDB::IpBan')->is_signup_banned($ip);
    if ($signup_banned) {
        $c->stash->{template} = 'user/signup_ip_banned';
        return;
    }

    return 1;
}

sub authenticate : Path('/user/authenticate') {
    my ($self, $c, $auth_id) = @_;

    # we should have an auth-id in the url
    if (not defined $auth_id) {
        $c->stash->{error}{message}
            = $c->localize(q{Incomplete authentication URL});
        return;
    }

    # fetch the info from the database
    my $regauth = $c->model('ParleyDB')->resultset('RegistrationAuthentication')->find(
        {
            id => $auth_id,
        }
    );

    # if we don't have any matches then the id was bogus
    if (not defined $regauth) {
        $c->stash->{error}{message} = q{Bogus authentication ID};
        return;
    }

    # TODO
    # if we get this far, we've got a valid ID, so we can yank out their details,
    # and to be safe we'll finish the process by asking them for their password
    #
    # for now, we assume the link clicking is good enough, and we mark them
    # as authenticated

    # get the person matching the ID
    $c->stash->{signup_user} = $c->model('ParleyDB')->resultset('Person')->find(
        {
            id => $regauth->recipient_id,
        }
    );

    # get the first (and should be only) match

    # mark the person as authenticated
    $c->stash->{signup_user}->authentication->authenticated(1);
    $c->stash->{signup_user}->authentication->update();

    # delete registration_authentication record
    $regauth->delete;

    # set a suitable success template
    $c->stash->{template} = 'user/auth_success';
}


sub signup : Path('/user/signup') {
    my ( $self, $c ) = @_;
    my (@messages);

    # get a reCAPTCHA to use in the form
    if ($c->config->{recaptcha}{enabled}) {
        $c->forward('captcha_get');
    }

    # logged-in? no need to signup again...
    if ($c->is_logged_in()) {
        $c->response->redirect( $c->uri_for($c->config()->{default_uri}) );
        return;
    }

    # deal with form submissions
    if (defined $c->request->method()
            and $c->request->method() eq 'POST'
            and defined $c->request->param('form_submit')
    ) {
        @messages = $self->_user_signup($c);
    }

    if (scalar @messages) {
        $c->stash->{messages} = \@messages;
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Controller (Private/Helper) Methods
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _add_new_user {
    my ($self, $c) = @_;
    my ($valid_results, @messages, $new_user);

    # less typing
    $valid_results = $c->form->valid;

    # is the requested username already in use?
    if ($self->_username_exists($c, $valid_results->{new_username})) {
        push @messages, $c->localize(q{USERNAME IN USE});
    }
    # is the requested email address already in use?
    if ($self->_email_exists($c, $valid_results->{email})) {
        push @messages, $c->localize(
            q{EMAIL IN USE ([_1])},
            q{user/password/forgotten}
        );
    }
    # is the requested forum name already in use?
    if ($self->_forumname_exists($c, $valid_results->{forum_name})) {
        push @messages, $c->localize(q{FORUMNAME IN USE});
    }

    # if we DON'T have any messages, then there were no errors, so we can try
    # to add the new user
    if (not scalar @messages) {
        # make the new user inside a transaction
        eval {
            $new_user = $c->model('ParleyDB')->schema->txn_do(
                sub { return $self->_txn_add_new_user($c) }
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


    # return our error messages (if any)
    return sort(@messages);
}

sub _create_regauth {
    my ($self, $c, $person) = @_;
    my ($random, $invitation);

    # if it's good enough for Cozens, it's good enough for me
    $random = md5_hex(time.(0+{}).$$.rand);

    # create an invitation
    $invitation = $c->model('ParleyDB')->resultset('RegistrationAuthentication')->create(
        {
            'id'	    => $random,
            'recipient_id'  => $person->id,
            'expires'       => Time::Piece->new(time + $LIFETIME)->datetime,
        }
    );

    return $invitation;
}

sub _email_exists {
    my ($self, $c, $email) = @_;
    # look for the specified email
    $c->log->info("Looking for: $email");
    my $match_count = $c->model('ParleyDB')->resultset('Person')->count(
        email => $email,
    );
    # return the number of matches
    return $match_count;
}

sub _forumname_exists {
    my ($self, $c, $forum_name) = @_;
    # look for the specified forum_name
    $c->log->info("Looking for: $forum_name");
    my $match_count = $c->model('ParleyDB')->resultset('Person')->count(
        forum_name => $forum_name,
    );
    # return the number of matches
    return $match_count;
}

sub _new_user_authentication_email {
    my ($self, $c, $person) = @_;
    my ($invitation, $send_status);

    # create a new reg-auth entry
    $invitation = $self->_create_regauth($c, $person);

    # send an email off to the (new) user
    $send_status = $c->send_email(
        {
            template    => {
                text    => q{authentication_email.eml},
            },
            person      => $person,
            headers => {
                from    => $c->application_email_address(),
                subject => $c->localize(
                    q{Activate Your [_1] Registration},
                    $c->config->{name}
                ),
            },
            template_data => {
                regauth => $invitation,
            },
        }
    );

    return $send_status;
}

sub _user_signup {
    my ($self, $c) = @_;
    my ($results, @messages);

    # check the form for errors
    $c->forward('form_check', [$dfv_profile_for{signup}]);

    # if the captcha is enabled
    if ($c->config->{recaptcha}{enabled}) {
        # check the captcha
        $c->forward('captcha_check');
        # deal with any errors
        if ($c->stash->{recaptcha_error}) {
            # add to form validation failures
            $c->forward(
                'add_form_invalid',
                [ 'recaptcha', $c->stash->{recaptcha_error} ]
            );
        }
    }

    # check to see if the username has already been used
    $c->forward('check_unique_username', ['new_username']);

    # check to see if the username has already been used
    $c->forward('check_unique_forumname', ['forum_name']);

    if ($c->stash->{validation}->success) {
        @messages = $self->_add_new_user($c, $results);
    }

#
#    # validate the form data
#    $c->form(
#        $dfv_profile_for{signup}
#    );
#
#    # deal with missing/invalid fields
#    if ($c->form->has_missing()) {
#        $c->stash->{view}{error}{message}
#            = $c->localize(q{DFV FILL REQUIRED});
#        foreach my $f ( $c->form->missing ) {
#            push @{ $c->stash->{view}{error}{messages} }, $f;
#        }
#    }
#    elsif ($c->form->has_invalid()) {
#        $c->stash->{view}{error}{message}
#            = $c->localize(q{DFV FIELDS INVALID});
#        foreach my $f ( $c->form->invalid ) {
#            push @{ $c->stash->{view}{error}{messages} }, $f;
#        }
#    }
#
#    # otherwise the form data is ok...
#    else {
#        @messages = $self->_add_new_user($c, $results);
#    }

    return (uniq(sort @messages));
}

sub _username_exists {
    my ($self, $c, $username) = @_;
    # look for the specified username
    $c->log->info("Looking for: $username");
    my $match_count = $c->model('ParleyDB')->resultset('Authentication')->count(
        username => $username,
    );
    # return the number of matches
    return $match_count;
}


# send notification email

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Functions for database transactions
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

sub _txn_add_new_user {
    my ($self, $c) = @_;
    my ($valid_results, $new_auth, $new_person, $new_preference, $status_ok);

    # less typing
    $valid_results = $c->stash->{validation}->valid;
use Data::Dump qw(pp); $c->log->debug( pp($valid_results) );
    # add authentication record
    $new_auth = $c->model('ParleyDB')->resultset('Authentication')->create(
        {
            username => $valid_results->{new_username},
            password => md5_hex( $valid_results->{new_password} ),
        }
    );

    # add new person
    $new_person = $c->model('ParleyDB')->resultset('Person')->create(
        {
            first_name          => $valid_results->{first_name},
            last_name           => $valid_results->{last_name},
            forum_name          => $valid_results->{forum_name},
            email               => $valid_results->{email},
            authentication_id   => $new_auth->id(),
        }
    );

    # add (default) prefs for new person
    $new_preference = $c->model('ParleyDB')->resultset('Preference')->create(
        {
            # default everything
            show_tz => 1,
        }
    );
    # and link to the new person
    $new_person->preference_id( $new_preference->id() );
    $new_person->update;

    # send an authentication email
    $status_ok = $self->_new_user_authentication_email( $c, $new_person );

    # if we sent the email OK take them off to a "it worked" type screen
    if ($status_ok) {
        $c->stash->{newdata}  = $new_person;
        $c->stash->{template} = q{user/auth_emailed};
    }
}



1;
__END__

=pod

=head1 NAME

Parley::Controller::User::SignUp

=cut

vim: ts=8 sts=4 et sw=4 sr sta
