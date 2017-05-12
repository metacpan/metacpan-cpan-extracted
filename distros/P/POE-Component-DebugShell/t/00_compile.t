
use Test::More tests => 1;
BEGIN {
    $ENV{COLUMNS} = 80;
    $ENV{LINES} = 24;

    use_ok('POE::Component::DebugShell');
}
