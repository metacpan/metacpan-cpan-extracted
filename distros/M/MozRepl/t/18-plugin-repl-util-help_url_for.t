use Test::More tests => 4;
use MozRepl;
use MozRepl::Util;

SKIP: {
    my $repl = MozRepl->new;

    eval {
        $repl->setup(
            { plugins => { plugins => [qw/Repl::Util::HelpUrlFor/] } } );
    };
    skip( "MozRepl is not started or MozLab is not installed.", 4 ) if ($@);

    ok( $repl->can('repl_help_url') );

    is( $repl->repl_help_url(
            {   source => q|window.document.getElementsByTagName('window')[0]|
            }
        ),
        "http://xulplanet.com/references/elemref/ref_window.html"
    );
    is( $repl->repl_help_url(
            {   source => MozRepl::Util->javascript_value(
                    q|@mozilla.org/network/protocol;1?name=view-source|)
            }
        ),
        "http://xulplanet.com/references/xpcomref/comps/c_networkprotocol1nameviewsource.html"
    );
    is( $repl->repl_help_url(
            {   source => MozRepl::Util->javascript_value(
                    q|@mozilla.org/supports-float;1|)
            }
        ),
        "http://xulplanet.com/references/xpcomref/comps/c_supportsfloat1.html"
    );
}
