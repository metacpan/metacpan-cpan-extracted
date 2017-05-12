package Parley::Controller::Terms;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;
use base 'Catalyst::Controller';

use Parley::App::Terms qw( :terms );
use Parley::App::Error qw( :methods );

sub auto : Private {
    my ($self, $c) = @_;

    # it's always useful to have a copy of the T&Cs to show
    $c->stash->{latest_terms} =
        $c->model('ParleyDB')->resultset('Terms')->latest_terms();

    return 1;
}

sub index : Private {
    my ( $self, $c ) = @_;

    # we'd like to be able to give the use the option
    # of viewing older T&Cs
    $c->stash->{all_site_terms} =
        $c->model('ParleyDB')->resultset('Terms')->search(
            {},
            {
                'order_by' => [\'created DESC'],
            }
        )
    ;

    if (    'GET' eq $c->request->method()
        and defined $c->request->param('site_term_id')
    ) {
        # get the terms for the given id
        $c->stash->{terms} =
            $c->model('ParleyDB')->resultset('Terms')->find(
                $c->request->param('site_term_id')
            );
    }

    # otherwise show the latest terms
    else {
        $c->stash->{terms} = $c->stash->{latest_terms};
    }
}

sub accept : Local {
    my ( $self, $c ) = @_;

    my $status = $c->login_if_required(
        $c->localize(q{LOGIN REQUIRED}) 
    );
    if (not defined $status) {
        return 0;
    }

    # no need to accept the terms again
    my $latest_terms = $c->stash->{latest_terms};
    if ($latest_terms and $latest_terms->user_accepted_latest_terms($c->_authed_user)) {
        $c->response->redirect(
            $c->uri_for('/terms')
        );
        return;
    }

    # make sure to set the template to view as we expect to get forwarded to
    $c->stash->{template} = 'terms/accept';

    # deal with form submits
    if (defined $c->request->method()
            and $c->request->method() eq 'POST'
    ) {
        if ($c->request->param('terms_reject')) {
            # session logout, and remove information we've stashed
            $c->logout;
            delete $c->session->{'authed_user'};
            $c->response->redirect(
                $c->uri_for($c->config()->{default_uri})
            );
            return;
        }
        elsif ($c->request->param('terms_accept')) {
            # insert the appropriate record
            $c->model('ParleyDB')->resultset('TermsAgreed')->create(
                {
                    person_id   => $c->_authed_user()->id(),
                    terms_id    => $c->stash->{latest_terms}->id(),
                }
            );
            $c->model('ParleyDB')->schema->txn_commit;

            # if we can, send them back to where they were trying to go
            if ( $c->session->{after_terms_accept_uri} ) {
                $c->response->redirect(
                    delete $c->session->{after_terms_accept_uri}
                );
            }
            else {
                $c->response->redirect(
                    $c->uri_for($c->config()->{default_uri})
                );
            }
            return;
        }
    }

    else {
        # otherwise, show the terms to be accepted
    }
}

sub add : Local {
    my ($self, $c) = @_;

    # currently only a global moderator can add new site terms
    if (not $c->stash->{site_moderator}) {
        parley_die($c, $c->localize(q{SITE MODERATOR REQUIRED}));
        return;
    }

    # deal with form submits
    if (defined $c->request->method()
            and $c->request->method() eq 'POST'
    ) {
        if (defined $c->request->param('new_site_terms')) {
            $c->log->debug('found: new_site_terms');
            $c->model('ParleyDB')->schema->txn_do(
                sub {
                    # add new T&Cs to database
                    my $new_terms = $c->model('ParleyDB')->resultset('Terms')->create(
                        {
                            content => $c->request->param('new_site_terms'),
                        }
                    );
                }
            );

            #$c->model('ParleyDB')->schema->txn_commit;
            #$new_terms->update;

            $c->response->redirect( $c->uri_for($c->config->{default_uri}) );
            return;
        }
        else {
            $c->log->debug('NOT found: new_site_terms');
        }
    }
    else {
        $c->log->debug('No POST method');
    }
}


1;

__END__

=head1 NAME

Parley::Controller::Terms - Catalyst Controller

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
