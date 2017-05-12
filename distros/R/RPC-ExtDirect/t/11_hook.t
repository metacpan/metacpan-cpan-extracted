use strict;
use warnings;

use Test::More tests => 22;

use RPC::ExtDirect::Test::Util;

use RPC::ExtDirect::Test::Pkg::Hooks;
use RPC::ExtDirect::Test::Pkg::Meta;
use RPC::ExtDirect::Test::Pkg::PollProvider;

use RPC::ExtDirect::Router;
use RPC::ExtDirect::EventProvider;
use RPC::ExtDirect::Event;

use RPC::ExtDirect::API before => \&before_hook, after => \&after_hook;

{
    package RPC::ExtDirect::Event;

    use Data::Dumper;

    use overload '""' => \&stringify,
                 'eq' => \&equals;

    sub stringify {
        my ($self) = @_;

        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Terse  = 1;

        my $str = $self->name . ':' . Dumper( $self->data );
        $str =~ s/^'//;
        $str =~ s/'$//;

        return $str;
    }

    sub equals {
        my ($self, $comparison) = @_;

        return $self->stringify eq "$comparison";
    }

    # This cheating is to avoid rewriting test modules

    package RPC::ExtDirect::Test::Pkg::Hooks;

    RPC::ExtDirect->import( Action => 'Hooks',
                            before => \&main::before_hook,
                            after  => \&main::after_hook );
}

use RPC::ExtDirect::API::Hook;

# These variables get set when hooks are called
my ($before, $after, $modify, $modify_meta, $throw_up, $cancel);

sub before_hook {
    my ($class, %params) = @_;

    $before = [ $class, { %params } ];

    $params{arg}->[0] = 'bar' if $modify;
    
    $modify_meta->(%params) if $modify_meta;

    die "Exception\n" if $throw_up;

    return "Method canceled" if $cancel;

    return 1;
}

sub after_hook {
    $after = [ shift @_, { @_ } ];
}

my $tests = eval do { local $/; <DATA> };
die "Can't read DATA: $@\n" if $@;

my %run_only = map { $_ => 1 } @ARGV;

TEST:
for my $test ( @$tests ) {
    my $name       = $test->{name};
    my $input      = $test->{input};
    my $type       = $test->{type};
    my $env        = $test->{env};
    my $exp_before = $test->{expected_before};
    my $exp_after  = $test->{expected_after};
    my $arg_type   = $test->{arg_type} || 'array';
    
    next TEST if %run_only && !$run_only{$name};
    
    $before = $after = $modify = $modify_meta
            = $throw_up = $cancel = undef;
    
    $modify      = $test->{modify};
    $modify_meta = $test->{modify_meta};
    $throw_up    = $test->{throw_up};
    $cancel      = $test->{cancel};
    
    if ( $type eq 'router' ) {
        RPC::ExtDirect::Router->route($input, $env);
    }
    else {
        RPC::ExtDirect::EventProvider->poll($env);
    };

    # Orig is a closure in RPC::ExtDirect::Hook, impossible to take ref of
    eval { delete $before->[1]->{orig}; delete $after->[1]->{orig}; };
    $@ = undef;
    
    # Argument output is a list that would be coerced into a hash in
    # real world Methods with no issues; however in tests it is captured
    # in arrayref that is compared to the expected values.
    # Hash randomization feature may change the order, screwing up
    # some tests.
    if ( $arg_type =~ /hash/i ) {
        my $have_before = $before->[1];
        
        $have_before->{arg} = { @{ $have_before->{arg} } }
            if ref $have_before->{arg};
        
        my $want_before = $exp_before->[1];
        
        $want_before->{arg} = { @{ $want_before->{arg} } }
            if ref $want_before->{arg};
        
        my $have_after = $after->[1];
        
        $have_after->{arg} = { @{ $have_after->{arg} } }
            if ref $have_after->{arg};
        
        my $want_after = $exp_after->[1];
        
        $want_after->{arg} = { @{ $want_after->{arg} } }
            if ref $want_after->{arg};
    }

    is_deep $before, $exp_before, "$name: before data";
    is_deep $after,  $exp_after,  "$name: after data";
};

sub get_method_ref {
    my ($action_name, $method_name) = @_;

    my $api = RPC::ExtDirect->get_api;

    return $api->get_method_by_name($action_name, $method_name);
}

sub get_hook_ref {
    my ($action_name, $method_name, $type) = @_;

    my $api = RPC::ExtDirect->get_api;

    return $api->get_hook(
        action => $action_name,
        method => $method_name,
        type   => $type,
    );
}

__DATA__
#line 139
[
    # Cancel Method call by throwing error
    {
        name => 'Router throw error',
        input => q|{"type":"rpc","tid":1,"action":"Hooks",|.
                 q|"method":"foo_hook","data":["foo"]}|,
        env => 'env',
        throw_up => 1,
        type => 'router',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'foo' ],
                env           => 'env',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'foo' ],
                env           => 'env',
                result        => undef,
                exception     => "Exception\n",
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => undef,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },

    # Cancel Method call by returning non-1 from before hook
    {
        name => 'Router cancel Method',
        input => q|{"type":"rpc","tid":1,"action":"Hooks",|.
                 q|"method":"foo_hook","data":["foo"]}|,
        env => 'env',
        cancel => 1,
        type => 'router',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'foo' ],
                env           => 'env',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'foo' ],
                env           => 'env',
                result        => 'Method canceled',
                exception     => undef,
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => undef,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },

    # Simple Router request
    {
        name => 'Router method call',
        input => q|{"type":"rpc","tid":1,"action":"Hooks",|.
                 q|"method":"foo_hook","data":["foo"]}|,
        env => 'env',
        type => 'router',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'foo' ],
                env           => 'env',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'foo' ],
                env           => 'env',
                result        => [ 'RPC::ExtDirect::Test::Pkg::Hooks', 'foo' ],
                exception     => '',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },

    # Argument modification in "before" hook
    {
        name => 'Router arg modification',
        input => q|{"type":"rpc","tid":1,"action":"Hooks",|.
                 q|"method":"foo_hook","data":["foo"]}|,
        env => 'env',
        modify => 1,
        type => 'router',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'bar' ],
                env           => 'env',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [ 'bar' ],
                env           => 'env',
                result        => [ 'RPC::ExtDirect::Test::Pkg::Hooks', 'bar' ],
                exception     => '',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },
    
    # Passing metadata to hooks
    {
        name  => 'Passing metadata to hooks',
        input => q|{"type":"rpc","tid":1,"action":"Meta",|.
                 q|"method":"arg0","data":null,|.
                 q|"metadata":[42,43]}|,
        env   => 'env',
        type  => 'router',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Meta arg0 before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Meta arg0 after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Meta',
                method        => 'arg0',
                code          => \&RPC::ExtDirect::Test::Pkg::Meta::arg0,
                arg           => [ [42, 43] ],
                env           => 'env',
                param_names   => undef,
                param_no      => 0,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Meta arg0 /),
                metadata      => [42, 43],
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Meta arg0 before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Meta arg0 after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Meta',
                method        => 'arg0',
                code          => \&RPC::ExtDirect::Test::Pkg::Meta::arg0,
                arg           => [ [42, 43] ],
                env           => 'env',
                result        => { meta => [42, 43] },
                exception     => '',
                param_names   => undef,
                param_no      => 0,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::Meta::arg0,
                method_ref    => get_method_ref(qw/ Meta arg0 /),
                metadata      => [42, 43],
                aux_data      => undef,
            },
        ],
    },
    
    {
        name  => 'Munging metadata in a hook',
        input => q|{"type":"rpc","tid":1,"action":"Meta",|.
                 q|"method":"named_arg","data":{"fred":"frob"},|.
                 q|"metadata":["quack"]}|,
        env   => 'env',
        type  => 'router',
        arg_type => 'hash',
        modify_meta => sub {
            my (%arg) = @_;
            
            my @meta = @{ delete $arg{metadata} };
            
            s/a/i/g for @meta;
            
            push @{ $arg{arg} }, 'bar', \@meta;
        },
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Meta named_arg before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Meta named_arg after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Meta',
                method        => 'named_arg',
                code          => \&RPC::ExtDirect::Test::Pkg::Meta::named_arg,
                arg           => ['foo', ['quack'], 'fred', 'frob', 'bar', ['quick']],
                env           => 'env',
                param_names   => [],
                param_no      => undef,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Meta named_arg /),
                metadata      => ['quack'],
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Meta named_arg before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Meta named_arg after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Meta',
                method        => 'named_arg',
                code          => \&RPC::ExtDirect::Test::Pkg::Meta::named_arg,
                arg           => ['foo', ['quack'], 'fred', 'frob', 'bar', ['quick']],
                env           => 'env',
                result        => { fred => 'frob', bar => ['quick'], meta => ['quack'] },
                exception     => '',
                param_names   => [],
                param_no      => undef,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::Meta::named_arg,
                method_ref    => get_method_ref(qw/ Meta named_arg /),
                metadata      => ['quack'],
                aux_data      => undef,
            },
        ],
    },
    
    {
        name  => 'Ancillary data in hooks',
        input => q|{"type":"rpc","tid":1,"action":"Hooks",|.
                 q|"method":"foo_hook","data":[42],|.
                 q|"token":"kaboom!","frob":"bazoo"}|,
        env   => 'env',
        type  => 'router',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [42],
                env           => 'env',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => { frob => 'bazoo', token => 'kaboom!' },
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ Hooks foo_hook before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ Hooks foo_hook after /),
                package       => 'RPC::ExtDirect::Test::Pkg::Hooks',
                method        => 'foo_hook',
                code          => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                arg           => [42],
                env           => 'env',
                result        => [ 'RPC::ExtDirect::Test::Pkg::Hooks', 42 ],
                exception     => '',
                param_names   => undef,
                param_no      => 1,
                pollHandler   => 0,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::Hooks::foo_hook,
                method_ref    => get_method_ref(qw/ Hooks foo_hook /),
                metadata      => undef,
                aux_data      => { frob => 'bazoo', token => 'kaboom!' },
            },
        ],
    },

    # Cancel EventProvider call by throwing error
    {
        name => 'Poll throw error',
        env => 'env',
        throw_up => 1,
        type => 'poll',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ ],
                env           => 'env',
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ ],
                env           => 'env',
                result        => undef,
                exception     => "Exception\n",
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_called => undef,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },

    # Cancel Method call by returning non-1 from before hook
    {
        name => 'Poll cancel Method',
        env => 'env',
        cancel => 1,
        type => 'poll',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ ],
                env           => 'env',
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ ],
                env           => 'env',
                result        => 'Method canceled',
                exception     => undef,
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_called => undef,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },

    # Argument modification in "before" hook
    {
        name => 'Poll arg modification',
        env => 'env',
        modify => 1,
        type => 'poll',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ 'bar' ],
                env           => 'env',
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ 'bar' ],
                env           => 'env',
                result        => [q|foo_event:['foo']|, q|bar_event:{'foo' => 'bar'}|],
                exception     => '',
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },

    # Event polling
    {
        name => 'Poll method call',
        env => 'env',
        type => 'poll',
        expected_before => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ ],
                env           => 'env',
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
        expected_after => [
            'main',
            {
                before        => \&before_hook,
                before_ref    => get_hook_ref(qw/ PollProvider foo before /),
                instead       => undef,
                instead_ref   => undef,
                after         => \&after_hook,
                after_ref     => get_hook_ref(qw/ PollProvider foo after /),
                package       => 'RPC::ExtDirect::Test::Pkg::PollProvider',
                method        => 'foo',
                code          => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                arg           => [ ],
                env           => 'env',
                result        => [q|foo_event:['foo']|, q|bar_event:{'foo' => 'bar'}|],
                exception     => '',
                param_names   => undef,
                param_no      => undef,
                pollHandler   => 1,
                formHandler   => 0,
                method_called => \&RPC::ExtDirect::Test::Pkg::PollProvider::foo,
                method_ref    => get_method_ref(qw/ PollProvider foo /),
                metadata      => undef,
                aux_data      => undef,
            },
        ],
    },
]
