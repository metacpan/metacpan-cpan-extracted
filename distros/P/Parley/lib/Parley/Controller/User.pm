package Parley::Controller::User;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';

use JSON;

# deal with user login requests on user/login
sub login : Path('/user/login') {
    my ( $self, $c ) = @_;

    # default form message
    $c->stash->{'message'} = $c->localize(q{PASSWORD ENTER DETAILS});
    # if we have a custom message to use ..
    $c->stash->{'login_message'} = delete( $c->session->{login_message} );
    # make sure we use the correct template - we sometimes detach() here
    $c->stash->{template} = 'user/login';


    # deal with logins banned by IP
    my $ip = $c->request->address;
    my $login_banned =
        $c->model('ParleyDB::IpBan')->is_login_banned($ip);
    if ($login_banned) {
        $c->stash->{template} = 'user/login_ip_banned';
        return;
    }

    # if we have a username, try to log the user in
    if ( $c->request->param('username') ) {
        # try to log the user in
        my $login_status = $c->authenticate(
            {
                username => $c->request->param('username'),
                password => $c->request->param('password'),
            }
        );

        # if we have a user we're logged in
        if ( $login_status ) {
            my $base    = $c->request->base();
            my $action  = $c->request->action();

            $c->log->debug("base:   $base");
            $c->log->debug("action: $action");

            # if we've stored somewhere to go after we log-in, got there now
            if ( $c->session->{after_login} ) {
                $c->response->redirect( delete $c->session->{after_login} );
            }

            # (else) if we've just been through Forgotten Password, don't go back there
            elsif ($c->request->referer() =~ m{user/password/}) {
                # go to the default app URL
                $c->response->redirect( $c->uri_for($c->config()->{default_uri}) );
            }

            # (else) if we've just been through the Authentication, don't go back there
            elsif ($c->request->referer() =~ m{user/authenticate/}) {
                # go to the default app URL
                $c->response->redirect( $c->uri_for($c->config()->{default_uri}) );
            }

            # (else) redirect to where we were referred from, unless our referer is our action
            elsif ( $c->request->referer() =~ m{\A$base}xms and $c->request->referer() !~ m{$action\z}xms) {
                # go to where we came from
                $c->response->redirect( $c->request->referer() );
            }

            # (else) if all else fails go to the application's default_uri
            else {
                $c->response->redirect( $c->uri_for($c->config()->{default_uri}) );
            }
        }

        # otherwise we failed to login, try again!
        else {
            $c->stash->{'message'}
                = $c->localize(q{AUTHENTICATION FAILED});
        }
    }
}

sub logout : Path('/user/logout') {
    my ($self, $c) = @_;

#    # if no-one logged in, send them to the main page as a punishment
#    if (not exists $c->session->{authed_user}) {
#        $c->response->redirect( $c->uri_for($c->config()->{default_uri}) );
#        return;
#    }

    # session logout, and remove information we've stashed
    $c->logout;
    delete $c->session->{'authed_user'};

    # redisplay the page we were on, or just do the 'default' action
    my $base    = $c->request->base();
    my $action  = $c->request->action();
    # redirect to where we were referred from, unless our referer is our action
    if ( $c->request->referer() =~ m{\A$base}xms and $c->request->referer() !~ m{$action\z}xms) {
        $c->response->redirect( $c->request->referer() );
    }
    else {
        $c->response->redirect( $c->uri_for($c->config()->{default_uri}) );
    }
}

sub profile :Local {
    my ($self, $c) = @_;
    my ($user_id, $person);

    $user_id = $c->request->param('user');
    if (defined $user_id) {
        # make sure we got a sane looking user-id
        if (not $user_id =~ m{\A\d+\z}) {
            $c->stash->{error}{message}
                = $c->localize(q{non-integer user id passed});
            return;
        }

        # fetch the matching user
        $c->stash->{profiled_user}
            = $c->model('ParleyDB::Person')->find( $user_id );
    }
    else {
        $c->stash->{error}{message} = $c->localize(q{No User Specified});
        return;
    }
}

sub suspend :Local {
    my ($self, $c) = @_;
    my ($json, $return_data, $person);

    if (not $c->_authed_user->can_suspend_account) {
        $return_data->{error}{message} =
            $c->localize(q{You don't have the required privileges to do that});
    }

    else {
        my ($suspended, $person);

        # default to turning OFF a suspension
        $suspended = 0;

        # see if we meet the criteria for a suspend action
        if (
            defined $c->request->param('suspend')
                and
            1 == $c->request->param('suspend')
        ) {
            $suspended = 1;
        }

        eval {
            # see if we can find the person to suspend
            $person = $c->model('ParleyDB::Person')->find(
                $c->request->param('person')
            );

            if (defined $person) {
                $return_data->{data}{suspended} = $suspended;
                $return_data->{data}{name} = $person->forum_name;

                # suspend a person, giving a reson
                $person->set_suspended(
                    {
                        value   => $suspended,
                        reason  => $c->request->param('reason'),
                        admin   => $c->_authed_user,
                    }
                );
            }
            else {
                $return_data->{error}{message} =
                    $c->localize(q{We're not in Kansas any more});
            }
        };
        if ($@) {
            $return_data->{error}{message} = $@;
            $c->log->error($@);
        }
    }

    # return some JSON
    $json = to_json($return_data);
    $c->response->body( $json );
    $c->log->info( $json );
    return;
}

sub suspended :Local {
    my ($self, $c) = @_;
    $c->stash->{template} = 'user/suspended';
    return;
}

1;

__END__

=head1 NAME

Parley::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

vim: ts=8 sts=4 et sw=4 sr sta
