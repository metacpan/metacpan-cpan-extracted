use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;
use Plack::App::FakeModPerl1::Dispatcher;

use FindBin::libs;

# evil globals
my ($pafmp1d, $parsed_config);

# can we create a really simple object?
# does it 'do the right things'?
$pafmp1d = Plack::App::FakeModPerl1::Dispatcher->new;
isa_ok($pafmp1d, 'Plack::App::FakeModPerl1::Dispatcher');
can_ok($pafmp1d,
    qw/
        new

        config_file_name
        debug
        dispatches
        parsed_apache_config

        dispatch_for

        _build_dispatches
        _build_parsed_apache_config
        _call_handler
        _location_to_regexp
        _prepare_location_config_for
        _require_handler_module
    /
);

# but we won't get far without specifying anything useful
throws_ok {
    $parsed_config = $pafmp1d->parsed_apache_config;
} qr{cannot stat '/etc/myapp/apache_locations.conf':},
    'died with call to parsed_apache_config()';

# now build one that has an apache config that exists
$pafmp1d = Plack::App::FakeModPerl1::Dispatcher->new({
    config_file_name => $FindBin::Bin . '/50-app/testapp.conf'
});
lives_ok {
    $parsed_config = $pafmp1d->parsed_apache_config;
} 'survived call to parsed_apache_config()';
isa_ok($parsed_config, 'Apache::ConfigParser');

# ->dispatches is a list in 'file order'
# we currently build it rather strangely with an entry per
# location-handlertype
my @dispatches = @{ $pafmp1d->dispatches };
my @expected_dispatch_data = (
    {
        location    => '~ "^/regexp-[0-9]+"',
        handles     => 'perlinithandler',
    },
    {
        location    => "/FakedApp",
        handles     => 'perlinithandler',
    },
    {
        location    => "/FakedApp",
        handles     => 'perlcleanuphandler',
    },
    {
        location    => "/FakedApp",
        handles     => 'perlhandler',
    },
    {
        location    => "/ajax/something_magic",
        handles     => 'perlhandler',
    },
);

while (my $dispatch_data = shift @dispatches) {
    my $expected_data = shift @expected_dispatch_data;
    my $subtest_name = sprintf(
        'Correct dispatch data for %s <%s>',
        $expected_data->{location},
        $expected_data->{handles},
    );
    subtest $subtest_name => sub {
        ok(
            defined $expected_data,
            'we have expected data for the current dispatch'
        );

        # we dispatch to the location we were expecting
        is(
            $dispatch_data->{location},
            $expected_data->{location},
            q{found expected location: } . $expected_data->{location}
        );

        # we handle the handler phase we expected to
        ok(
            exists( $dispatch_data->{ $expected_data->{handles} } ),
            q{this location entry correctly handles: } . $expected_data->{handles}
        );
    };
}

# getting here we should have popped everything off the
# @expected_dispatch_data list (now that we've exhausted our parsed dispatch
# list)
is(
    scalar(@expected_dispatch_data),
    0,
    'exhausted expected dispatch data list'
);

use Data::Printer alias=>'dpp';
# check the 'prepared location' hash for URIs
my @location_for_tests = (
    {
        uri                 => '/ajax/something_magic',

        handlers            => ['perlhandler'],
        perlhandler_list    => ['Test::FakedApp::AJAX']
    },
    {
        uri                 => '/FakedApp',

        handlers            => ['perlhandler'],
        perlhandler_list    => ['Test::FakedApp']
    }
);

=for later

while (my $location_test_data = shift @location_for_tests) {
    my $uri = $location_test_data->{uri};
    subtest "Location config for $uri" => sub {
        my %location_config = %{ $pafmp1d->_prepare_location_config_for( $uri ) };
        diag dpp(%location_config);

        my @handlers  = $location_test_data->{handlers};
        foreach my $handler (@handlers) {
            ok(
                exists $location_config{$handler . '_list'},
                "expected handler type exists: $handler",
            );
            cmp_bag(
                $location_config{$handler},
                $location_test_data->{$handler . '_list'},
                "correct handler classes: " .
                    join(',', @{$location_test_data->{$handler . '_list'}})
            );
        }
    };
}

=cut

done_testing;
