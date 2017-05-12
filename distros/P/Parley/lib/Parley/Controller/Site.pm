package Parley::Controller::Site;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';

use JSON;
use Proc::Daemon;
use Proc::PID::File;

use Parley::App::Error qw( :methods );

# there are ACL rules in Parley.pm #

sub ip_bans :Local {
    my ($self, $c) = @_;

    # a list of ban types
    $c->stash->{ip_ban_types} =
        $c->model('ParleyDB::IpBanType')
            ->ban_type_list;
}

sub ip_info : Local {
    my ($self, $c) = @_;
    my $ip = $c->request->param('address');

    # the address
    $c->stash->{ip_address} = $ip;
    # a breakdown of posts/users for the address
    $c->stash->{people_posting} = 
        $c->model('ParleyDB::Post')->people_posting_from_ip($ip);
}

sub services : Local {
    my ($self, $c) = @_;

    # does the email engine appear to be running?
    # get the pid file ...
    my $pid = Proc::PID::File->running(
        debug   => 0,
        name    => q{parley_email_engine},
        dir     => q{/tmp},
    );
    $c->stash->{email_engine}{pid} = $pid;
}

sub users : Local {
    my ($self, $c) = @_;

    $c->stash->{users_with_roles} =
        $c->model('ParleyDB::Person')->users_with_roles()
    ;
}

sub user : Local {
    my ($self, $c) = @_;
    my $pid = $c->request->param('pid');

    if (defined $pid && $pid =~ m{\A\d+\z}xms) {
        $c->stash->{person} =
            $c->model('ParleyDB::Person')->find($pid)
        ;

        $c->stash->{roles} =
            $c->model('ParleyDB::Role')->role_list();
    }
    else {
        $c->response->redirect(
            $c->uri_for('/site/users/')
        );
        return;
    }
}

sub users_autocomplete : Local {
    my ($self, $c) = @_;
    my @results;

    my $stuff = $c->model('ParleyDB::Person')->search(
        {
            forum_name => { -ilike => $c->request->param('query') . q{%} },
        },
        {
            'order_by' => [\'forum_name ASC'],
            columns => [qw/id forum_name first_name last_name/],
        }
    );

    while (my $person = $stuff->next) {
        my %data = $person->get_columns;
        push @results, \%data;
    }

    $c->response->body(
        to_json( 
            {
                ResultSet => {
                    person => \@results,
                }
            }
        )
    );
    return;
}

sub roleSaveHandler :Local {
    my ($self, $c) = @_;
    my ($return_data, $json);
    my ($person_id, $role_id, $value, $person);

    $person_id  = $c->request->param('person');
    $role_id    = $c->request->param('role');
    $value      = $c->request->param('value');

    # default to responding with "nothing changed"
    $return_data->{updated} = 0;

    # check incoming values
    if (not defined $person_id or $person_id !~ m{\A\d+\z}) {
        $return_data->{error}{message} =
            $c->localize('Invalid %1', 'user-id');
    }
    elsif (not defined $role_id or $role_id !~ m{\A\d+\z}) {
        $return_data->{error}{message} =
            $c->localize('Invalid %1', 'role-id');
    }
    elsif (not defined $value or $value !~ m{\A[01]}) {
        $return_data->{error}{message} =
            $c->localize('Invalid requested value');
    }

    # find the person
    $person = $c->model('ParleyDB::Person')->find( $person_id );

    # remove the role?
    if (0 == $value) {
        # try to remove the join table entry
        eval {
            $c->model('ParleyDB')->schema->txn_do(
                sub {
                    my $userrole = $c->model('ParleyDB::UserRole')->find(
                        {
                            authentication_id   => $person->authentication_id,
                            role_id             => $role_id,
                        }
                    );

                    # moderator suicide?
                    if (
                        $person_id == $c->_authed_user->id
                            and
                        q{site_moderator} eq $userrole->role->name
                    ) {
                        $return_data->{error}{message} =
                            $c->localize(
                                q{You can't commit moderator suicide}
                            );
                    }
                    else {
                        # remove the role
                        $userrole->delete;
                    }
                }
            );
            $return_data->{updated} = 1;
        };
        # deal with any transaction errors
        if ($@) {                                   # Transaction failed
            die "something terrible has happened!"  #
                if ($@ =~ /Rollback failed/);       # Rollback failed

            $return_data->{error}{message} =
                qq{Database transaction failed: $@};
            $c->log->error( $@ );
            return;
        }
    }

    # add the role?
    elsif (1 == $value) {
        # try to remove the join table entry
        eval {
            $c->model('ParleyDB')->schema->txn_do(
                sub {
                    $c->model('ParleyDB::UserRole')->update_or_create(
                        {
                            authentication_id   => $person->authentication_id,
                            role_id     => $role_id,
                        }
                    )
                }
            );
            $return_data->{updated} = 1;
        };
        # deal with any transaction errors
        if ($@) {                                   # Transaction failed
            die "something terrible has happened!"  #
                if ($@ =~ /Rollback failed/);       # Rollback failed

            $return_data->{error}{message} =
                qq{Database transaction failed: $@};
            $c->log->error( $@ );
            return;
        }
    }

    # else ... um, how did we end up here?
    else {
        $return_data->{error}{message} =
            $c->localize(q{We're not in Kansas any more});
    }

    # return some JSON
    $json = to_json($return_data);
    $c->response->body( $json );
    #$c->log->info( $json );
    return;
}

sub fmodSaveHandler :Local {
    my ($self, $c) = @_;
    my ($fieldname, $return_data, $json);
    my ($value, $person_id, $forum_id);

    $return_data->{updated}     = 0;

    eval {
        $value      = $c->request->param('value');
        $person_id  = $c->request->param('person');
        $forum_id   = $c->request->param('forum');

        $c->model('ParleyDB')->schema->txn_do(
            sub {
                $c->model('ParleyDB::ForumModerator')->update_or_create(
                    {
                        person_id       => $person_id,
                        forum_id        => $forum_id,
                        can_moderate    => $value,
                    },
                    {
                        key => 'forum_moderator_person_key',
                    }
                );
                $return_data->{updated} = 1;
            }
        )
    };
    # deal with any transaction errors
    if ($@) {                                   # Transaction failed
        die "something terrible has happened!"  #
            if ($@ =~ /Rollback failed/);       # Rollback failed

        $return_data->{error}{message} =
            qq{Database transaction failed: $@};
        $c->log->error( $@ );
        $json = to_json($return_data);
        $c->response->body( $json );
        return;
    }

    # return some JSON
    $json = to_json($return_data);
    $c->response->body( $json );
    #$c->log->info( $json );
    return;
}


sub saveBanHandler :Local {
    my ($self, $c) = @_;
    my ($fieldname, $return_data, $json);

    $return_data->{updated}     = 0;
    $return_data->{old_value}   = $c->request->param('ovalue');

    $fieldname = $c->request->param('fieldname');

    # update an existing ban?
    if ($fieldname =~ m{\Aipban_(\d+)\z}xms) {
        eval {
            my $id = $1;

            $c->model('ParleyDB')->schema->txn_do(
                sub {
                    $c->model('ParleyDB::IpBan')->find($id)
                        ->update(
                            {
                                ip_range    => $c->request->param('value'),
                            },
                    )
                }
            );
            $return_data->{updated} = 1;
        };
        # deal with any transaction errors
        if ($@) {                                   # Transaction failed
            die "something terrible has happened!"  #
                if ($@ =~ /Rollback failed/);       # Rollback failed

            $return_data->{error}{message} =
                qq{Database transaction failed: $@};
            $c->log->error( $@ );
            $json = to_json($return_data);
            $c->response->body( $json );
            return;
        }
    }

    # add a new ban?
    elsif ($fieldname =~ m{\Aipbannewtype_(\d+)\z}xms) {
        eval {
            my $id = $1;

            $c->model('ParleyDB')->schema->txn_do(
                sub {
                    $c->model('ParleyDB::IpBan')->update_or_create(
                        {
                            ban_type_id => $id,
                            ip_range    => $c->request->param('value'),
                        },
                    )
                }
            );
            $return_data->{updated} = 1;
        };
        # deal with any transaction errors
        if ($@) {                                   # Transaction failed
            die "something terrible has happened!"  #
                if ($@ =~ /Rollback failed/);       # Rollback failed

            $return_data->{error}{message} =
                qq{Database transaction failed: $@};
            $c->log->error( $@ );
            $json = to_json($return_data);
            $c->response->body( $json );
            #$c->log->info( $json );
            return;
        }
    }

    # unknown
    else {
        $return_data->{error}{message} =
            $c->localize(q{Unrecognised field-name format});
    }

    # return some JSON
    $json = to_json($return_data);
    $c->response->body( $json );
    #$c->log->info( $json );
    return;
}

=head1 NAME

Parley::Controller::Site - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

=head2 index 

=cut


=head1 AUTHOR

Chisel Wright C<< <chiselwright@users.berlios.de> >>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
