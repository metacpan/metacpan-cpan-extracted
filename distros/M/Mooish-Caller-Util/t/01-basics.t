#!perl

use 5.010;
use strict;
use warnings;

use Test::Exception;
use Test::More 0.98;

# XXX test with_args

sub fill_template {
    my ($template, $vars) = @_;
    $template =~ s/\[\[(\w+)\]\]/
        defined($vars->{$1}) ? $vars->{$1} : "[[undef:$1]]"/eg;
    $template;
}

subtest classic => sub {
    my $eval_err;
    eval q{
        package Local::Classic::Caller;
        use Mooish::Caller::Util qw(get_constructor_caller);
        sub new { get_constructor_caller }
        sub BUILD { get_constructor_caller }
        sub BUILDARGS { get_constructor_caller }

        package Local::Client;
        Local::Classic::Caller->new;
    };
    $eval_err = $@;
    like($eval_err, qr/Not called/,
         "dies (gccaller not called inside BUILD/BUILDARGS)")
        or diag $eval_err;

    eval q{
        package Local::Client;
        Local::Classic::Caller->BUILD;
    };
    $eval_err = $@;
    like($eval_err, qr/Unknown object system/,
         "dies (gccaller get unknown object system, BUILD)")
        or diag $eval_err;

    eval q{
        package Local::Client;
        Local::Classic::Caller->BUILDARGS;
    };
    $eval_err = $@;
    like($eval_err, qr/Unknown object system/,
         "dies (gccaller gets unknown object system, BUILDARGS)")
        or diag $eval_err;

   eval q{
        package Local::Classic::Callers;
        use Mooish::Caller::Util qw(get_constructor_callers);
        sub new { get_constructor_callers }
        sub BUILD { get_constructor_callers }
        sub BUILDARGS { get_constructor_callers }

        package Local::Client;
        Local::Classic::Callers->new;
    };
    $eval_err = $@;
    like($eval_err, qr/Not called/,
         "dies (gccallers not called inside BUILD/BUILDARGS)")
        or diag $eval_err;

    eval q{
        package Local::Client;
        Local::Classic::Callers->BUILD;
    };
    $eval_err = $@;
    like($eval_err, qr/Unknown object system/,
         "dies (gccallers get unknown object system, BUILD)")
        or diag $eval_err;

    eval q{
        package Local::Client;
        Local::Classic::Callers->BUILDARGS;
    };
    $eval_err = $@;
    like($eval_err, qr/Unknown object system/,
         "dies (gccallers gets unknown object system, BUILDARGS)")
        or diag $eval_err;
};

my $code_template = <<'_';
package Local::[[OBJSYS]]::p[[METHOD]];
use [[OBJSYS]] [[OBJSYS_ARGS]];
use Mooish::Caller::Util qw(get_constructor_caller
                            get_constructor_callers);
sub [[METHOD]] {
    $Local::ResultCaller0  = get_constructor_caller;
    $Local::ResultCaller1  = get_constructor_caller(1);
    $Local::ResultCallers0 = [get_constructor_callers];
    $Local::ResultCallers1 = [get_constructor_callers(1)];
    {};
}

package Local::Client::[[OBJSYS]]::p[[METHOD]];
undef $Local::ResultCaller0;
undef $Local::ResultCaller1;
undef $Local::ResultCallers0;
undef $Local::ResultCallers1;
sub f1 { Local::[[OBJSYS]]::p[[METHOD]]->new }
sub f2 { f1 }
sub f3 { f2 }
f3;
_

subtest Mo => sub {
    plan skip_all => 'Mo not available' unless eval { require Mo; diag "Mo::VERSION=$Mo::VERSION"; 1 };

    my $eval_err;
    eval fill_template($code_template,
                      {OBJSYS=>'Mo', OBJSYS_ARGS=>' qw(build)',
                       METHOD=>'BUILD'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Mo::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Mo::pBUILD::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Mo::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Mo::pBUILD::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Mo::pBUILD::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Mo::pBUILD::f2")
        or diag explain $Local::ResultCallers1->[0];
};

subtest Moo => sub {
    plan skip_all => 'Moo not available' unless eval { require Moo; diag "Moo::VERSION=$Moo::VERSION"; 1 };
    plan skip_all => 'Moo version is too old' unless version->parse($Moo::VERSION) >= version->parse("2.000002");

    my $eval_err;
    eval fill_template($code_template,
                      {OBJSYS=>'Moo', OBJSYS_ARGS=>'',
                       METHOD=>'BUILD'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Moo::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Moo::pBUILD::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Moo::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Moo::pBUILD::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Moo::pBUILD::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Moo::pBUILD::f2")
        or diag explain $Local::ResultCallers1->[0];

    eval fill_template($code_template,
                      {OBJSYS=>'Moo', OBJSYS_ARGS=>'',
                       METHOD=>'BUILDARGS'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Moo::pBUILDARGS::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Moo::pBUILDARGS::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Moo::pBUILDARGS::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Moo::pBUILDARGS::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Moo::pBUILDARGS::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Moo::pBUILDARGS::f2")
        or diag explain $Local::ResultCallers1->[0];
};

subtest Moose => sub {
    plan skip_all => 'Moose not available' unless eval { require Moose; diag "Moose::VERSION=$Moose::VERSION"; 1 };

    my $eval_err;
    eval fill_template($code_template,
                      {OBJSYS=>'Moose', OBJSYS_ARGS=>'',
                       METHOD=>'BUILD'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Moose::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Moose::pBUILD::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Moose::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Moose::pBUILD::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Moose::pBUILD::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Moose::pBUILD::f2")
        or diag explain $Local::ResultCallers1->[0];

    eval fill_template($code_template,
                      {OBJSYS=>'Moose', OBJSYS_ARGS=>'',
                       METHOD=>'BUILDARGS'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Moose::pBUILDARGS::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Moose::pBUILDARGS::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Moose::pBUILDARGS::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Moose::pBUILDARGS::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Moose::pBUILDARGS::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Moose::pBUILDARGS::f2")
        or diag explain $Local::ResultCallers1->[0];
};

subtest Mouse => sub {
    plan skip_all => 'Mouse not available' unless eval { require Mouse; diag "Mouse::VERSION=$Mouse::VERSION"; 1 };

    my $eval_err;
    eval fill_template($code_template,
                      {OBJSYS=>'Mouse', OBJSYS_ARGS=>'',
                       METHOD=>'BUILD'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Mouse::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Mouse::pBUILD::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Mouse::pBUILD::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Mouse::pBUILD::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Mouse::pBUILD::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Mouse::pBUILD::f2")
        or diag explain $Local::ResultCallers1->[0];

    eval fill_template($code_template,
                      {OBJSYS=>'Mouse', OBJSYS_ARGS=>'',
                       METHOD=>'BUILDARGS'});
    $eval_err = $@;
    ok(!$eval_err, "eval success") or diag $eval_err;
    is($Local::ResultCaller0->[3], "Local::Client::Mouse::pBUILDARGS::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCaller1->[3], "Local::Client::Mouse::pBUILDARGS::f2")
        or diag explain $Local::ResultCaller1;
    is($Local::ResultCaller0->[3], "Local::Client::Mouse::pBUILDARGS::f1")
        or diag explain $Local::ResultCaller0;
    is($Local::ResultCallers0->[0][3], "Local::Client::Mouse::pBUILDARGS::f1")
        or diag explain $Local::ResultCallers0->[0];
    is($Local::ResultCallers0->[1][3], "Local::Client::Mouse::pBUILDARGS::f2")
        or diag explain $Local::ResultCallers0->[1];
    is($Local::ResultCallers1->[0][3], "Local::Client::Mouse::pBUILDARGS::f2")
        or diag explain $Local::ResultCallers1->[0];
};

DONE_TESTING:
done_testing;
