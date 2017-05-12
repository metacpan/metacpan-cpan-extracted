package Osgood::Server::Controller::Script;
use strict;
use warnings;
use base 'Catalyst::Controller';

use MIME::Base64;
use Osgood::Event;
use Osgood::EventList;

sub add : Local {
    my ($self, $c, $arg) = @_;

    my $json = MIME::Base64::decode($arg);

    my $el = Osgood::EventList->thaw($json);

    my ($count, $error) = $c->add_from_list($el);

    $c->log->error($count);
    $c->res->body("<script type=\"text/javascript\">var osadded = $count;</script>");
}

1;