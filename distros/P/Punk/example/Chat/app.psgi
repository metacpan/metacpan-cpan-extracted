use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";

# The PSGI entry point. Plain HTTP: TLS is bin/punk-chat's business, and the
# app is the same either way.
#
#     plackup -s Hyperman -p 5010 app.psgi     # websockets work
#     plackup -p 5010 app.psgi                 # pages and API only
#
# Anything but Hyperman 0.11+ has no detach seam, so `websocket` routes croak
# at boot rather than let the app start serving routes it cannot honour. Use
# bin/punk-chat for the full thing, TLS included.

BEGIN {
    # Running from a Punk checkout that is built but not installed.
    my $punk = "$FindBin::Bin/..";
    unshift @INC, "$punk/blib/lib", "$punk/blib/arch"
        if -d "$punk/blib/arch" && !$ENV{PUNK_CHAT_NO_BLIB};
}

use Chat::Schema ();
use Chat;

Chat::Schema::ensure();

Chat->to_app;
