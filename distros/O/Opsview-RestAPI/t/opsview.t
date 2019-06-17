use 5.12.1;
use strict;
use warnings;

use Test::More;
use Test::Trap qw/ :on_fail(diag_all_once) /;
use Data::Dump qw(pp);
use Test::Deep;
use Storable 'dclone';

my %opsview = (
    url      => 'http://localhost',
    username => 'admin',
    password => 'initial',
);

for my $var (qw/ url username password /) {
    my $envvar = 'OPSVIEW_' . uc($var);
    if ( !$ENV{$envvar} ) {
        diag "Using default '$envvar' value of '$opsview{$var}' for testing.";
    }
    else {
        $opsview{$var} = $ENV{$envvar};
        note "Using provided '$envvar' for testing.";
    }
}

use_ok("Opsview::RestAPI");
use_ok("Opsview::RestAPI::Exception");

my $rest;
my $output;

$rest = trap {
    Opsview::RestAPI->new(%opsview);
};
isa_ok( $rest, 'Opsview::RestAPI' );
$trap->did_return(" ... returned");
$trap->quiet(" ... quietly");
isa_ok( $rest->{client}, 'REST::Client' );
is( $rest->url,      $opsview{url},      "URL set on object correctly" );
is( $rest->username, $opsview{username}, "Username set on object correctly" );
is( $rest->password, $opsview{password}, "Password set on object correctly" );

$output = trap {
    $rest->api_version();
};

SKIP: {
# object was created, we tried to access it, but the URL was not to an Opsview server
    if ( $trap->die && ref( $trap->die ) eq 'Opsview::RestAPI::Exception' ) {
        if (   $trap->die->message =~ m/was not found on this server/
            || $trap->die->http_code != 200 )
        {
            my $message
                = "HTTP STATUS CODE: "
                . $trap->die->http_code
                . " MESSAGE: "
                . $trap->die->message;
            $message =~ s/\n/ /g;

            my $exit_msg
                = "The configured URL '$opsview{url}' does NOT appear to be an opsview server: "
                . $message;
            diag $exit_msg;
            skip $exit_msg;
        }
    }

    $trap->did_return("api_version was returned");
    $trap->quiet("no further errors on api_version");
    is( ref($output), 'HASH', ' ... got a HASH in response' );

    like( $output->{api_min_version},
        qr/^\d\.\d$/, "api_version 'api_min_version' returned okay" );
    like( $output->{api_version},
        qr/^\d\.\d+$/, "api_version 'api_version' returned okay" );
    like( $output->{easyxdm_version},
        qr/^\d\.\d\.\d+$/, "api_version 'easyxdm_version' returned okay" );

    note( "Got 'api_version' from '$opsview{url}' of "
            . $output->{api_version} );

    # try to get rest/info, which auth is required for
    $output = trap {
        $rest->opsview_info;
    };
    $trap->did_die("Could not fetch opsview_info when not logged in");
    $trap->quiet("No extra output");
    isa_ok( $trap->die, 'Opsview::RestAPI::Exception' );
    is( $trap->die,
        "Not logged in",
        "Exception stringified to 'Not logged in' correctly"
    );

    # Now log in and try to get rest info again
    trap {
        $rest->login;
    };
    $trap->did_return("Logged in okay");
    $trap->quiet("no further errors on login");

    $output = trap {
        $rest->opsview_info;
    };
    $trap->did_return("Got opsview_info when logged in");
    $trap->quiet("No extra output");

    like( $output->{opsview_version},
        qr/^\d\.\d+\.\d$/, "opsview_info 'opsview_version' returned okay" );
    like( $output->{opsview_build},
        qr/^\d\.\d+\.\d\.\d+$/,
        "opsview_info 'opsview_build' returned okay" );
    like( $output->{opsview_edition},
        qr/^\w+$/, "opsview_info 'opsview_edition' returned okay" );
    like(
        $output->{uuid},
        qr/^\w{8}-\w{4}-\w{4}-\w{4}-\w{12}$/,
        "opsview_info 'uuid' returned okay"
    );

    # also check version capability
    my $version = trap { $rest->opsview_version; };
    $trap->did_return(" ... returned");
    $trap->quiet(" ... quietly");
    isa_ok( $version, 'version', "direct call to 'opsview_version' returned a version object");
    like ($version, qr/^\d\.\d+\.\d$/, "direct call to 'opsview_version' returned okay" );
    note("Opsview version: $version");

    # Now log out and make sure we can no longer get the info
    trap {
        $rest->logout
    };
    $trap->did_return("Logged out okay");
    $trap->quiet("no further errors on logout");

    $output = trap {
        $rest->opsview_info;
    };
    $trap->did_die("Could not fetch opsview_info when not logged in");
    $trap->quiet("No extra output");
    isa_ok( $trap->die, 'Opsview::RestAPI::Exception' );
    is( $trap->die,
        "Not logged in",
        "Exception stringified to 'Not logged in' correctly"
    );

    #log back in and check for a pending reload
    $rest->login;
    $output = trap {
        $rest->reload_pending();
    };
    $trap->did_return("reload_pending was returned");
    $trap->quiet("no further errors on reload_pending");

    SKIP: {
        # This can happen as other tests do make changes, but should
        # undo them after each test. This still counts as a pending
        # change, however.
        skip "Some pending changes detected", 1 if $output != 0;
        is( $output, 0, "No pending changes" );
    }

    # make a change and check it again

    trap {
        $rest->put(
            api  => 'config/contact/1',
            data => { enable_tips => 0, },
        );
    };
    $trap->did_return("config change for admin contact was okay");
    $trap->quiet("no further errors on admin contact change");

    # now test pending changes again
    $output = trap {
        $rest->reload_pending();
    };
    $trap->did_return("reload_pending was returned");
    $trap->quiet("no further errors on reload_pending");

    ok( $output > 0, "Pending change found" );

    # does a reload work
    note('Running a reload');
    $output = trap {
        $rest->reload();
    };
    $trap->did_return("reload was returned");
    $trap->quiet("no further errors on reload");

    $output = trap {
        $rest->reload_pending();
    };
    $trap->did_return("reload_pending was returned");
    $trap->quiet("no further errors on reload_pending");

    SKIP: {
        # This can happen as other tests do make changes, but should
        # undo them after each test. This still counts as a pending
        # change, however.
        skip "Some pending changes detected", 1 if $output != 0;
        is( $output, 0, "No pending changes" );
    }

    check_batched_endpoint('host');
    check_batched_endpoint('hosttemplate');
TODO: {
        local $TODO
            = "May fail on larger or slower systems due to Apache2 proxy timeout";
        check_batched_endpoint('servicecheck');
    }

    # test to strip out 'ref' hash entries
    $output = trap {
        $rest->get( api => 'config/hostcheckcommand' );
    };
    $trap->did_return("fetched host check commands using get");
    $trap->quiet("no further errors on get");

    # use dclone to deep copy the hasref somewhere new
    my $amended = $rest->remove_keys_from_hash( dclone($output), ['ref'] );

    my $output_copy = dclone($output);
    is_deeply(
        $amended,
        remove_refs_from_data($output_copy),
        "ref keys removed"
    );

    #my $stack = cmp_deeply($amended, remove_refs_from_data($output));
    #eq_deeply($amended, remove_refs_from_data($output)) || deep_diag($stack);

    # fetch the first host - should be the master server
    my $host_1 = trap {
        $rest->get(
            api => 'config/host/1',
        );
    };
    $trap->did_return("Fetched config for host ID 1");
    $trap->quiet("no error on fetch of host ID one");

    $host_1 = remove_refs_from_data( $host_1 );

    # now try to do a single param search on the name
    my $host_1_by_name = trap {
        $rest->get(
            api => 'config/host',
            params => {
                's.name' => $host_1->{object}->{name},
            },
        );
    };
    $trap->did_return("Fetched config for host ID 1 by single param name search");
    $trap->quiet("no error on fetch of host ID by name singe");

    $host_1_by_name = remove_refs_from_data( $host_1_by_name );

    is_deeply(
        $host_1->{object},
        $host_1_by_name->{list}->[0],
        "Search by ID and search by name match"
    );

    # now try an array of params when searching on the name.  Multiple
    # params should do an OR so the result should be no different
    my $host_1_by_name_multi = trap {
        $rest->get(
            api => 'config/host',
            params => {
                's.name' => [
                    $host_1->{object}->{name},
                    $host_1->{object}->{name},
                    $host_1->{object}->{name},
                    $host_1->{object}->{name},
                ],
            },
        );
    };
    $trap->did_return("Fetched config for host ID 1 by multiple param name search");
    $trap->quiet("no error on fetch of host ID by name multi");

    $host_1_by_name_multi = remove_refs_from_data( $host_1_by_name_multi );

    is_deeply(
        $host_1->{object},
        $host_1_by_name_multi->{list}->[0],
        "Search by ID and search by name match"
    );

    #diag(pp($host_1));
    #diag(pp($host_1_by_name));
}

sub remove_refs_from_data {
    my ($data) = @_;

    BAIL_OUT("Wrong type of data passed") unless ref($data) eq "HASH";

    for my $key ( keys %{$data} ) {
        if ( $key eq 'ref' ) {
            delete $data->{$key};
            next;
        }
        if ( ref $data->{$key} eq 'HASH' ) {
            $data->{$key} = remove_refs_from_data( $data->{$key} );
        }
        if ( ref $data->{$key} eq 'ARRAY' ) {
            my @newlist;
            for my $item ( @{ $data->{$key} } ) {
                push( @newlist, remove_refs_from_data($item) );
            }
            $data->{$key} = \@newlist;
        }
    }

    return $data;
}

sub check_batched_endpoint {
    my ($endpoint) = @_;

    note("Checking unbatched/batched get for endpoint 'config/$endpoint'");

    my $unbatched_endpoint = trap {
        $rest->get(
            api    => 'config/' . $endpoint,
            params => { rows => 'all' }
        );
    };
    $trap->did_return("config/$endpoint was returned");
    $trap->quiet("no further errors on config/$endpoint");

    is( ref($unbatched_endpoint),
        "HASH", "config/$endpoint output is a hash" );
    ok( $unbatched_endpoint->{summary}->{allrows} > 0,
        "config/$endpoint returns multiple ${endpoint}s"
    );

    note(
        "Got unbatched $unbatched_endpoint->{summary}->{allrows} ${endpoint}s"
    );
    note( "Unbatched summary: ", pp( $unbatched_endpoint->{summary} ) );

    my $batched_endpoint = trap {
        $rest->get( api => 'config/' . $endpoint, batch_size => 20 );
    };
    $trap->did_return("batched config/$endpoint was returned");
    $trap->quiet("no further errors on batched config/$endpoint");

    is( ref($batched_endpoint),
        "HASH", "batched config/$endpoint output is a hash" );
    ok( $batched_endpoint->{summary}->{allrows} > 0,
        "batched config/$endpoint returns multiple ${endpoint}s" );

    note("Got batched $batched_endpoint->{summary}->{allrows} ${endpoint}s");
    note( "Batched summary: ", pp( $batched_endpoint->{summary} ) );

    # got, expected, text
    is_deeply( $batched_endpoint, $unbatched_endpoint,
        "Batched vs unbatched ${endpoint}s match" );

    #note("unbatched: ", pp($unbatched_endpoint));
    #note("#" x 50);
    #note("batched: ", pp($batched_endpoint));
}

done_testing();
