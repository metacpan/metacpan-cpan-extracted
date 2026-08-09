use strict;
use warnings;
use File::Basename ();
use File::Spec ();

# The web tier's PSGI entry point.
#
#     plackup -p 5000 app.psgi                    # pages, API, admin UI
#     plackup -s Hyperman -p 5000 app.psgi        # ...plus admin live mode
#
# The admin UI's live mode needs Hyperman's detach path; on any other
# server it warns once at boot and stays on polling, which is the fallback
# it is designed around.
#
# This process does not run jobs. Start a worker pool beside it:
#
#     punk-queue worker --app bin/queue.pl -q default,mail,reports -j 2
#
# __FILE__ and not FindBin, for the same reason bin/queue.pl says so: a
# server loads this file with `do`, and FindBin answers for whoever's
# process it is.

my $home;
BEGIN {
    $home = File::Basename::dirname(File::Spec->rel2abs(__FILE__));
    unshift @INC, "$home/lib";

    # Running from a Punk-Queue checkout that is built but not installed.
    my $dist = "$home/../..";
    unshift @INC, "$dist/blib/lib", "$dist/blib/arch"
        if -d "$dist/blib/arch" && !$ENV{MAILER_NO_BLIB};
}

use Mailer;

Mailer->to_app;
