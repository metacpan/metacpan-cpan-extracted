package Parley::App::Terms;
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Parley::Version;  our $VERSION = $Parley::VERSION;

use Perl6::Export::Attrs;

sub terms_check :Export( :terms ) {
    my ($c, $user) = @_;
    my $latest_terms = $c->model('ParleyDB')->resultset('Terms')->latest_terms();

    my $path = $c->request->path();
    my $action = $c->action;

    if ($c->request->path() eq 'terms/accept') {
        #$c->log->debug('visiting: terms/accept');
        return 1;
    }

    # if the user is trying to login ... that's ok
    if ($c->request->path() eq 'user/login') {
        #$c->log->debug('visiting: user/login');
        return 1;
    }

    # if we don't have any terms ... just carry on
    if (not defined $latest_terms) {
        #$c->log->debug('no site terms');
        return 1;
    }

    if ($latest_terms->user_accepted_latest_terms($user)) {
        #$c->log->debug('user already accepted terms');
        return 1;
    }

    #$c->log->debug('forwarding to acceptance page: '.  $c->config->{terms_accept_uri});

    if (not defined $c->session->{after_terms_accept_uri}) {
        $c->session->{after_terms_accept_uri} = $c->uri_for(
            $action,
            $c->request->query_parameters()
        );
    }
    $c->response->redirect(
        $c->uri_for($c->config->{terms_accept_uri})
    );
    return 0;
}



1;
