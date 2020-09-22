#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 6;

use FindBin;
use lib "$FindBin::Bin/lib";
use Mock::Plasp;
use Path::Tiny;

BEGIN { use_ok 'Plasp'; }
BEGIN { use_ok 'Plasp::Application'; }

my ( $session_id, $Session, $Application );

$Session     = mock_asp->Session;
$Application = mock_asp->Application;

is( $Application->Lock,
    undef,
    'Unimplemented method $Application->Lock'
);
is( $Application->UnLock,
    undef,
    'Unimplemented method $Application->UnLock'
);
$Session->{foo} = 'baz';
$session_id = mock_asp->req->env->{'psgix.session.options'}{id};
is_deeply( $Application->GetSession( $session_id ),
    { foo => 'baz', IsAbandoned => 0, Timeout => 60, SessionID => $session_id },
    '$Application->GetSession returned hash matching expected $Session'
);
is( $Application->SessionCount,
    undef,
    'Unimplemented method $Application->SessionCount'
);
