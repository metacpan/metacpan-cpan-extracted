use Test::Spec;    # not rpec style but the other test is and this brings other goodies we want
use Perl::Phase;

diag("Testing Perl::Phase::AtRunTime $Perl::Phase::VERSION");

plan tests => 6;

package Local::Test {
    use vars '$res', '$cnt';
    use Perl::Phase::AtRunTime sub { $res->{ ++$cnt } = { stage => ${^GLOBAL_PHASE}, package => __PACKAGE__ } };
};

is $Local::Test::cnt, 1, "when loaded at compile time: only executed once";
is $Local::Test::res->{1}{stage},   "INIT",        "when loaded at compile time: stage is INIT";
is $Local::Test::res->{1}{package}, "Local::Test", "when loaded at compile time: it is run in the context of the caller";

package Local::Test {
    $res = {};
    $cnt = 0;
    Perl::Phase::AtRunTime->import( sub { $res->{ ++$cnt } = { stage => ${^GLOBAL_PHASE}, package => __PACKAGE__ } } );
}

is $Local::Test::cnt, 1, "when loaded at run time: only executed once";
is $Local::Test::res->{1}{stage},   "RUN",         "when loaded at run time: stage is INIT";
is $Local::Test::res->{1}{package}, "Local::Test", "when loaded at runt time: it is run in the context of the caller";
