use strict;
use warnings;
use Carp;

use Test::More;
use RPC::ExtDirect::Test::Util;

if ( $ENV{REGRESSION_TESTS} ) {
    plan tests => 69;
}
else {
    plan skip_all => 'Regression tests are not enabled.';
}

# We will test deprecated API and don't want the warnings
# cluttering STDERR
$SIG{__WARN__} = sub {};

sub global_before {
}

sub global_after {
}

use RPC::ExtDirect;        # Checking case insensitiveness, too
use RPC::ExtDirect::API      Before => \&global_before,
                             aFtEr  => \&global_after,
                             ;

use lib 't/lib2';
use RPC::ExtDirect::Test::Foo;
use RPC::ExtDirect::Test::Bar;
use RPC::ExtDirect::Test::Qux;
use RPC::ExtDirect::Test::PollProvider;

my %test_for = (
    # foo is plain basic package with ExtDirect methods and hooks
    'Foo' => {
        methods => [ sort qw( foo_foo foo_bar foo_baz foo_zero foo_blessed ) ],
        list    => {
            foo_foo => { package => 'RPC::ExtDirect::Test::Foo',
                         method  => 'foo_foo', param_no => 1,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef,
                         before => \&RPC::ExtDirect::Test::Foo::foo_before,
                       },
            foo_bar => { package => 'RPC::ExtDirect::Test::Foo',
                         method  => 'foo_bar', param_no => 2,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef,
                         instead => \&RPC::ExtDirect::Test::Foo::foo_instead,
                       },
            foo_baz => { package => 'RPC::ExtDirect::Test::Foo',
                         method  => 'foo_baz', param_no => undef,
                         formHandler => 0, pollHandler => 0,
                         param_names => [ qw( foo bar baz ) ],
                         before => \&RPC::ExtDirect::Test::Foo::foo_before,
                         after  => \&RPC::ExtDirect::Test::Foo::foo_after,
                       },
            foo_zero =>{ package => 'RPC::ExtDirect::Test::Foo',
                         method  => 'foo_zero', param_no => 0,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            foo_blessed => { package => 'RPC::ExtDirect::Test::Foo',
                         method => 'foo_blessed', param_no => undef,
                         formHandler => 0, pollHandler => 0,
                         param_names => [], },

        },
    },
    # bar package has only its own methods as we don't support inheritance
    'Bar' => {
        methods => [ sort qw( bar_foo bar_bar bar_baz ) ],
        list    => {
            bar_foo => { package => 'RPC::ExtDirect::Test::Bar',
                         method  => 'bar_foo', param_no => 4,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            bar_bar => { package => 'RPC::ExtDirect::Test::Bar',
                         method  => 'bar_bar', param_no => 5,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            bar_baz => { package => 'RPC::ExtDirect::Test::Bar',
                         method  => 'bar_baz', param_no => undef,
                         formHandler => 1, pollHandler => 0,
                         param_names => undef, },
        },
    },
    # Now, qux package redefines all methods so we have 'em here
    'Qux' => {
        methods => [sort qw(foo_foo foo_bar foo_baz bar_foo bar_bar bar_baz)],
        list    => {
            foo_foo => { package => 'RPC::ExtDirect::Test::Qux',
                         method  => 'foo_foo', param_no => 1,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            foo_bar => { package => 'RPC::ExtDirect::Test::Qux',
                         method  => 'foo_bar', param_no => 2,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            foo_baz => { package => 'RPC::ExtDirect::Test::Qux',
                         method  => 'foo_baz', param_no => undef,
                         formHandler => 0, pollHandler => 0,
                         param_names => [ qw( foo bar baz ) ], },
            bar_foo => { package => 'RPC::ExtDirect::Test::Qux',
                         method  => 'bar_foo', param_no => 4,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            bar_bar => { package => 'RPC::ExtDirect::Test::Qux',
                         method  => 'bar_bar', param_no => 5,
                         formHandler => 0, pollHandler => 0,
                         param_names => undef, },
            bar_baz => { package => 'RPC::ExtDirect::Test::Qux',
                         method  => 'bar_baz', param_no => undef,
                         formHandler => 1, pollHandler => 0,
                         param_names => undef, },
        },
    },
    # PollProvider implements Event provider for polling mechanism
    'PollProvider' => {
        methods => [ sort qw( foo ) ],
        list    => {
            foo => { package => 'RPC::ExtDirect::Test::PollProvider',
                     method  => 'foo', param_no => undef,
                     formHandler => 0, pollHandler => 1,
                     param_names => undef, },
        },
    },
);

my @expected_classes = sort qw( Foo Bar Qux PollProvider );

my @full_classes = sort eval { RPC::ExtDirect->get_action_list() };

is      $@, '', "full get_action_list() eval $@";
ok       @full_classes, "full get_action_list() not empty";
is_deep \@full_classes, \@expected_classes, "full get_action_list() deep";

my @expected_methods = sort qw(
    Qux::bar_bar            Qux::bar_baz        Qux::bar_foo
    Qux::foo_bar            Qux::foo_baz        Qux::foo_foo
    Foo::foo_foo            Foo::foo_bar        Foo::foo_baz
    Foo::foo_zero           Foo::foo_blessed
    Bar::bar_foo            Bar::bar_bar        Bar::bar_baz
    PollProvider::foo
);

my @full_methods = sort eval { RPC::ExtDirect->get_method_list() };

is      $@, '',         "full get_method_list() eval $@";
ok       @full_methods, "full get_method_list() not empty";
is_deep \@full_methods, \@expected_methods, "full get_method_list() deep";

my @expected_poll_handlers = ( [ 'PollProvider', 'foo' ] );

my @full_poll_handlers = eval { RPC::ExtDirect->get_poll_handlers() };

is      $@, '',              "full get_poll_handlers() eval $@";
ok      @full_poll_handlers, "full get_poll_handlers() not empty";
is_deep \@full_poll_handlers, \@expected_poll_handlers,
                        "full get_poll_handlers() deep";

# We have RPC::ExtDirect already loaded so let's go
for my $module ( sort keys %test_for ) {
    my $test = $test_for{ $module };

    my @method_list = sort eval { RPC::ExtDirect->get_method_list($module) };
    is $@, '', "$module get_method_list eval $@";

    my @expected_list = sort @{ $test->{methods} };

    is_deep \@method_list, \@expected_list,
                          "$module get_method_list() deeply";

    my %expected_parameter_for = %{ $test->{list  } };

    for my $method_name ( @method_list ) {
        my %parameters = eval {
            RPC::ExtDirect->get_method_parameters($module, $method_name)
        };

        is $@, '', "$module get_method_parameters() list eval $@";

        my $expected_ref = $expected_parameter_for{ $method_name };

        # No way to compare referents (and no sense in that, too);
        delete $parameters{referent};

        is_deep \%parameters, $expected_ref,
            "$module get_method_parameters() deeply";
    };
};

# Check if we have hooks properly defined
my $hook_tests = [
    {
        name    => 'foo_foo method scope before hook',
        package => 'RPC::ExtDirect::Test::Foo',
        method  => 'foo_foo',
        type    => 'before',
        code    => \&RPC::ExtDirect::Test::Foo::foo_before,
    },
    {
        name    => 'foo_baz method scope instead hook',
        package => 'RPC::ExtDirect::Test::Foo',
        method  => 'foo_bar',
        type    => 'instead',
        code    => \&RPC::ExtDirect::Test::Foo::foo_instead,
    },
    {
        name    => 'foo_baz method scope before hook',
        package => 'RPC::ExtDirect::Test::Foo',
        method  => 'foo_baz',
        type    => 'before',
        code    => \&RPC::ExtDirect::Test::Foo::foo_before,
    },
    {
        name    => 'foo_baz method scope after hook',
        package => 'RPC::ExtDirect::Test::Foo',
        method  => 'foo_baz',
        type    => 'after',
        code    => \&RPC::ExtDirect::Test::Foo::foo_after,
    },
    {
        name    => 'bar_foo package scope before hook',
        package => 'RPC::ExtDirect::Test::Bar',
        method  => 'bar_foo',
        type    => 'before',
        code    => \&RPC::ExtDirect::Test::Bar::bar_before,
    },
    {
        name    => 'bar_foo package scope after hook',
        package => 'RPC::ExtDirect::Test::Bar',
        method  => 'bar_foo',
        type    => 'after',
        code    => \&RPC::ExtDirect::Test::Bar::bar_after,
    },
    {
        name    => 'bar_bar package scope before hook',
        package => 'RPC::ExtDirect::Test::Bar',
        method  => 'bar_bar',
        type    => 'before',
        code    => \&RPC::ExtDirect::Test::Bar::bar_before,
    },
    {
        name    => 'bar_bar package scope after hook',
        package => 'RPC::ExtDirect::Test::Bar',
        method  => 'bar_bar',
        type    => 'after',
        code    => \&RPC::ExtDirect::Test::Bar::bar_after,
    },
    {
        name    => 'bar_baz package scope before hook',
        package => 'RPC::ExtDirect::Test::Bar',
        method  => 'bar_baz',
        type    => 'before',
        code    => \&RPC::ExtDirect::Test::Bar::bar_before,
    },
    {
        name    => 'bar_baz package scope after hook',
        package => 'RPC::ExtDirect::Test::Bar',
        method  => 'bar_baz',
        type    => 'after',
        code    => \&RPC::ExtDirect::Test::Bar::bar_after,
    },
    {
        name    => 'Global scope Qux foo_foo before hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'foo_foo',
        type    => 'before',
        code    => \&global_before,
    },
    {
        name    => 'Global scope Qux foo_foo after hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'foo_foo',
        type    => 'after',
        code    => \&global_after,
    },
    {
        name    => 'Global scope Qux foo_bar before hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'foo_bar',
        type    => 'before',
        code    => \&global_before,
    },
    {
        name    => 'Global scope Qux foo_bar after hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'foo_bar',
        type    => 'after',
        code    => \&global_after,
    },
    {
        name    => 'Global scope Qux foo_baz before hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'foo_baz',
        type    => 'before',
        code    => \&global_before,
    },
    {
        name    => 'Global scope Qux foo_baz after hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'foo_baz',
        type    => 'after',
        code    => \&global_after,
    },
    {
        name    => 'Global scope Qux bar_foo before hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'bar_foo',
        type    => 'before',
        code    => \&global_before,
    },
    {
        name    => 'Global scope Qux bar_foo after hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'bar_foo',
        type    => 'after',
        code    => \&global_after,
    },
    {
        name    => 'Global scope Qux bar_bar before hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'bar_bar', 
        type    => 'before',
        code    => \&global_before,
    },
    {
        name    => 'Global scope Qux bar_bar after hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'bar_bar',
        type    => 'after',
        code    => \&global_after,
    },
    {
        name    => 'Global scope Qux bar_baz before hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'bar_baz', 
        type    => 'before',
        code    => \&global_before,
    },
    {
        name    => 'Global scope Qux bar_baz after hook',
        package => 'RPC::ExtDirect::Test::Qux',
        method  => 'bar_baz',
        type    => 'after',
        code    => \&global_after,
    },
];

for my $test ( @$hook_tests ) {
    my $name = $test->{name};

    my $code = RPC::ExtDirect->get_hook(
        package => $test->{package},
        method  => $test->{method},
        type    => $test->{type},
    );

    is $code, $test->{code}, "$name code matches";
};

