use Test::More tests => 3;

BEGIN {
    use_ok('Net::Detect');
}

Net::Detect->import();
ok( defined &detect_net, 'detect_net() exported by import()' );

diag("Testing Net::Detect $Net::Detect::VERSION");

SKIP: {
    skip 'detect_net() tests require manual enabling/disabling of the network', 1 if !$ENV{'RELEASE_TESTING'};

    if ( $ENV{'NO_NETWORK'} ) {
        ok( !detect_net(), 'detect_net() false when there is no network' );
    }
    else {
        ok( detect_net(), 'detect_net() true when there is a network' );
    }
}
