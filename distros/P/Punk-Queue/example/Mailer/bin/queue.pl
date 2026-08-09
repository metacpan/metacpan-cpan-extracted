use strict;
use warnings;
use File::Basename ();
use File::Spec ();

# The worker pool's view of the application: a file that returns the app's
# queue, with every task body registered.
#
#     punk-queue worker  --app bin/queue.pl -q default,mail,reports -j 2
#     punk-queue jobs    --app bin/queue.pl --state failed
#     punk-queue crons   --app bin/queue.pl
#     punk-queue enqueue --app bin/queue.pl mail.welcome you@example.com
#
# Why a file and not `--app Mailer`: the class alone is enough to reach the
# queue (registration happens when the class is compiled), but task and
# cron TARGETS are resolved at to_app - that is what makes a typo a boot
# croak. A worker that never calls to_app would hold a queue with no task
# bodies in it and fail every job it claimed. So: compile the app, then
# hand back its queue.
#
# Read commands (jobs, stats, locks) need none of this and take a plain
# --dsn instead; this file is for anything that runs a body.
#
# __FILE__ and not FindBin: punk-queue reaches this file with `do`, so
# $FindBin::Bin is punk-queue's own bin directory, not this one. Anything
# a --app file locates relative to itself has to start here.

my $home;
BEGIN {
    $home = File::Basename::dirname(File::Spec->rel2abs(__FILE__)) . '/..';
    unshift @INC, "$home/lib";

    my $dist = "$home/../..";
    unshift @INC, "$dist/blib/lib", "$dist/blib/arch"
        if -d "$dist/blib/arch" && !$ENV{MAILER_NO_BLIB};
}

use Mailer;

Mailer->to_app;      # resolves every task and cron target - the boot gate
Mailer::queue();     # the last expression: what `do $file` hands back
