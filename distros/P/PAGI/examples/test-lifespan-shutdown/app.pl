#!/usr/bin/env perl
use strict;
use warnings;
use Future::AsyncAwait;
use PAGI::App::NotFound;

print STDERR "Parent PID: $$\n";

my $app = async sub {
    my ($scope, $receive, $send) = @_;

    if ($scope->{type} eq 'lifespan') {
        while (1) {
            my $event = await $receive->();
            my $type = $event->{type};

            if ($type eq 'lifespan.startup') {
                print STDERR "[$$] lifespan.startup\n";
                await $send->({ type => 'lifespan.startup.complete' });
            }
            elsif ($type eq 'lifespan.shutdown') {
                print STDERR "[$$] lifespan.shutdown\n";
                await $send->({ type => 'lifespan.shutdown.complete' });
                last;
            }
        }
        return;
    }

    # Default handler for HTTP
    return await PAGI::App::NotFound->new->to_app->($scope, $receive, $send);
};

$app;
