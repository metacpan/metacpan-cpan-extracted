#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use File::ChangeNotify;

my $run_upon_lib_change = join ' ', @ARGV;

$ENV{REPO_PATH} ||= $FindBin::Bin . '/../../';
chdir $ENV{REPO_PATH};

my $watcher = File::ChangeNotify->instantiate_watcher(
    directories => [ 't/', 'lib/' ],
    filter      => qr/\.(t|pm)$/,
);

while (my @events = $watcher->wait_for_events) {
    foreach my $event (@events) {
        print $event->path . " " . $event->type . "\n";
        if ($event->path =~ m{\.pm$}) {
            if ($run_upon_lib_change) {
                system "prove -l -v $run_upon_lib_change";
            }
            else {
                system "prove -l -v t/";
            }
        }
        elsif ($event->path =~ m{\.t$}) {
            system "prove -l -v ".$event->path;
        }
    }
}
