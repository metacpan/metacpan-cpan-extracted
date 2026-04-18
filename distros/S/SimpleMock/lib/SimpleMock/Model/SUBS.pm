package SimpleMock::Model::SUBS;
use strict;
use warnings;
use SimpleMock::Util qw(
    generate_args_sha
    file_from_namespace
);
use Data::Dumper;

our $VERSION = '0.04';

our %DELEGATED;

sub validate_mocks {
    my $mocks_data = shift;

    my $new_mocks = {};

    NAMESPACE: foreach my $ns (keys %$mocks_data) {

        # the module should already be loaded, but doesn't have to be
        eval {
            my $file = file_from_namespace($ns);
            require $file;
        };
        $@ and die "Cannot load $ns - $@";

        SUB: foreach my $sub (keys %{$mocks_data->{$ns}}) {
            SUBCALL: foreach my $subcall (@{ $mocks_data->{$ns}->{$sub}}) {
                my $sha = generate_args_sha($subcall->{args});
                my $returns = $subcall->{returns};
                $new_mocks->{SUBS}->{$ns}->{$sub}->{$sha} = $returns;
            }

            # alias the subroutine to the mock service — only once per sub
            my $key = "$ns\::$sub";
            unless ($DELEGATED{$key}) {
                $DELEGATED{$key} = 1;
                my $sub_full_name = $ns . '::' . $sub;
                no strict 'refs'; ## no critic
                no warnings 'redefine';
                *{$sub_full_name} = sub { _get_return_value_for_args($ns, $sub, \@_) };
            }
        }
    }
    return $new_mocks;
}

sub _get_return_value_for_args {
    my ($ns, $sub, $args) = @_;
    my $sha = generate_args_sha($args);

    for my $layer (reverse @SimpleMock::MOCK_STACK) {
        my $mock_sub = $layer->{SUBS}{$ns}{$sub} or next;

        # if no specific-args match, use layer _default, if exists
        my $returns = exists $mock_sub->{$sha}      ? $mock_sub->{$sha}
                    : exists $mock_sub->{'_default'} ? $mock_sub->{'_default'}
                    : next;   # nothing in this layer for this sub, keep looking down
        return ref($returns) eq 'CODE' ? $returns->(@$args) : $returns;
    }

    die "No mock found for $ns\::$sub with args: " . Dumper($args);
}

1;

=head1 NAME

SimpleMock::Model::SUBS - Mock model for subroutine calls

=head1 DESCRIPTION

Allows you to override subroutines in a namespace with mock implementations. By
using this along with reasonable design patterns, you can unit test your code
in a very simple way.

=head1 USAGE

=head2 via SimpleMock::Mocks::* modules

Use this approach to set global mocks for subs in your own code. If you have (say)
a module called MyModule.pm with a sub called 'load_conf_file' that loads data and
returns the content, to mock it, you would just add the sub to the relevant Mocks file, eg:

    package SimpleMock::Mocks::MyModule;
    use strict;
    use warnings;

    sub load_conf_file {
        return 'a static conf file';
    }

    1;

And that's it. In every test where you load SimpleMock, that mock will automatically
load when your test code uses the MyMock module.

=head2 via calls to C<register_mocks()> and C<register_mocks_scoped()>

    # load this before any of the code that will need mocking
    use SimpleMock qw(register_mocks register_mocks_scoped);

    # this loads My::Module and, if they exist, the mocks in SimpleMock::Mocks::My::Module
    use My::Module;

    # manually register overrides
    register_mocks(
        # the model namespace
        SUBS => {
            # the namespace we are mocking in
            'My::Module' => {
                # the sub we are mocking
                'my_sub' => [
                    # mocks are hashrefs with keys 'args' and 'returns'
                    # if 'args' is omitted, the 'returns' value is used as a default

                    # return a specific value for these args
                    { args => [1, 2],
                      returns => 'return value for args 1,2' },

                    # run the code reference for these args
                    { args => [3, 4],
                      # just return a random number from 1 to 10
                      returns => sub { return int(rand(10))+1; } },

                    # return value for any other args
                    # you can use a subref here (as above) for a more powerful default,
                    # or just return a static value
                    { returns => sub { my ($arg1, $arg2) = @_; return $arg1+$arg2 } },
                ],
            },
        },
    );

If the catchall (returns with no args) is omitted, the sub call will die if the args
sent do not match any of the defined mocks.

The return value can be a literal value, or a code reference. If it is a code
reference, it will be called with the args passed to the subroutine. This is
useful for generating dynamic return values based on the input arguments. You'll probably
want static return values, but the sub ref option is there in case it's needed
(eg for a random response).

Use the coderef approach too if you need to return a hash or array, or if
you need to support wantarray calls. I originally considered doing this via another
key in the mock definition, but it seemed simpler to just use a coderef for these.

eg:

    { returns => sub { wantarray ? ('one', 'two', 'three') : 3; } }

If you want to override these default mocks temporarily in sub tests, you can use C<register_mocks_scoped>

    # global test mocks are set at the beginning of the test, but we want to override
    # them for the next block only
    {
        # assign to a scope guard, same arg syntax as for C<register_mocks>
        my $scope_guard = register_mocks_scoped(...);

        # any tests you run here will use the mocks you have created above
    }
    # after the block ends, the scoped mocks are destroyed and the original mocks
    # are used again

There is a dummy app in the ./t directory of this distribution. Please examine to see examples
of the different mocking options.

=cut


