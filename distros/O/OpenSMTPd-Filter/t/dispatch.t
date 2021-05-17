use Test2::V0
    -target => 'OpenSMTPd::Filter',
    qw< ok like mock dies diag done_testing >;

my $has_pledge = do { local $@; eval { local $SIG{__DIE__};
    require OpenBSD::Pledge } };

# Failed tests attempt to load this and cause pledge violations.
{ local $@; eval { local $SIG{__DIE__};
    require Test2::API::Breakage } };

diag "Testing $CLASS on perl $^V" . ( $has_pledge ? " with pledge" : "" );
OpenBSD::Pledge::pledge() || die "Unable to pledge: $!" if $has_pledge;

ok my $filter = CLASS->new, "Created a new $CLASS instance";

like dies { $filter->_dispatch }, qr{^Unsupported: undef at},
    "Fails to dispatch undef line";

like dies { $filter->_dispatch('') }, qr{^Unsupported:  at},
    "Fails to parse empty line";

like dies { $filter->_dispatch('unknown|protocol') },
    qr{^Unsupported: unknown|line at},
    "Fails to parse unknown line";

{
    my $mock = mock $CLASS => (
        track    => 1,
        set      => [ _handle_subclass => sub {1}, ],
        override => [
            _handle_config => sub {1},
            _handle_report => sub {1},
        ],
    );

    $filter->_dispatch('subclass|xxx');
    like $mock->call_tracking, [
        {   sub_name => '_handle_subclass',
            args     => [ $filter, 'xxx' ],
        }
    ], "Called _handle_subclass with expected args";
    $mock->clear_call_tracking;

    $filter->_dispatch('config|foo|bar');
    like $mock->call_tracking, [
        {   sub_name => '_handle_config',
            args     => [ $filter, 'foo|bar' ],
        }
    ], "Called _handle_config with expected args";
    $mock->clear_call_tracking;

    $filter->_dispatch('report|foo|bar');
    like $mock->call_tracking, [
        {   sub_name => '_handle_report',
            args     => [ $filter, 'foo|bar' ],
        }
    ], "Called _handle_report with expected args";
    $mock->clear_call_tracking;
}

done_testing;
