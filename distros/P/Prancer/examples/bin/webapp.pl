#!/usr/bin/env perl

use strict;
use warnings FATAL => 'all';

use File::Basename ();
use Plack::Runner;
use MyApp;

sub main {
    # figure out where exist to make finding config files possible
    my (undef, $root, undef) = File::Basename::fileparse($0);

    # load configurations out of /conf
    my $myapp = MyApp->new("${root}/../conf");
    $myapp->config->set('static', { 'dir' => "${root}/../static" });

    # this just returns a PSGI application. $psgi can be wrapped with
    # additional middleware before sending it along to Plack::Runner.
    my $psgi = $myapp->to_psgi_app();

    # run the psgi app through Plack and send it everything from @ARGV. this
    # way Plack::Runner will get options like what listening port to use and
    # application server to use -- Starman, Twiggy, etc.
    my $runner = Plack::Runner->new();
    $runner->parse_options(@_);
    $runner->run($psgi);

    return;
}

main(@ARGV) unless caller;

1;
