package t::cancel_fail;

use strict;
use warnings;
use autodie;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use Time::HiRes;

use Net::Curl::Easy qw(:constants);

use Net::Curl::Promiser::Select;

use Socket;

{
    my $promiser = Net::Curl::Promiser::Select->new();

    my @list;

    my ($srv, $server_port) = _create_server_socket();
    my $easy = _make_req($server_port);

    $promiser->add_handle($easy)->then(
        sub {
            diag explain [ res => @_ ];
            push @list, [ res => @_ ];
        },
        sub {
            diag explain [ rej => @_ ];
            push @list, [ rej => @_ ];
        },
    );

    _wait_until_polling($promiser);

    $promiser->cancel_handle($easy);

    my ($r, $w, $e) = $promiser->get_vecs();

    cmp_deeply(
        [$r, $w, $e],
        array_each( none( re( qr<[^\0]> ) ) ),
        'no vecs are non-NUL',
    );

    is_deeply( \@list, [], 'promise remains pending' ) or diag explain \@list;
}

for my $fail_ar ( [0], ['haha'] ) {
    my $promiser = Net::Curl::Promiser::Select->new();

    # diag "fail: " . (explain $fail_ar)[0];

    my @list;

    my ($srv, $server_port) = _create_server_socket();
    my $easy = _make_req($server_port);

    $promiser->add_handle($easy)->then(
        sub {
            push @list, [ res => @_ ];
        },
        sub {
            push @list, [ rej => @_ ];
        },
    );

    _wait_until_polling($promiser);

    $promiser->fail_handle($easy, @$fail_ar);

    my ($r, $w, $e) = $promiser->get_vecs();

    cmp_deeply(
        [$r, $w, $e],
        array_each( none( re( qr<[^\0]> ) ) ),
        'no vecs are non-NUL',
    );

    is_deeply(
        \@list,
        [ [ rej => $fail_ar->[0] ] ],
        'promise rejected',
    ) or diag explain \@list;
}

sub _wait_until_polling {
    my $promiser = shift;

    my $times = 100;

    for (1 .. $times) {
        my ($r, $w, $e) = $promiser->get_vecs();

        $promiser->process( $r, $w );

        ($r, $w, $e) = $promiser->get_vecs();

        if (grep { tr<\0><>c } ($r, $w)) {
            diag 'Curl told us to poll; continuing …';
            return;
        }

        my $timeout = $promiser->get_timeout();

        diag "Curl didn’t tell us to poll yet; retrying after $timeout seconds …";

        Time::HiRes::sleep($timeout) if $timeout > 0;
    }

    warn "Curl didn’t tell us to poll after $times times. Continuing …\n";
}

#----------------------------------------------------------------------

sub _create_server_socket {
    socket my $srv, Socket::AF_INET, Socket::SOCK_STREAM, 0;
    bind $srv, Socket::pack_sockaddr_in(0, "\x7f\0\0\1");
    listen $srv, 10;

    my ($server_port) = Socket::unpack_sockaddr_in( getsockname($srv) );

    diag "Created listening socket on port $server_port";

    return ($srv, $server_port);
}

sub _make_req {
    my $port = shift;

    my $easy = Net::Curl::Easy->new();
    $easy->setopt( CURLOPT_URL() => "http://127.0.0.1:$port" );

    $_ = q<> for @{$easy}{ qw(_head _body) };
    $easy->setopt( CURLOPT_HEADERDATA() => \$easy->{'_head'} );
    $easy->setopt( CURLOPT_FILE() => \$easy->{'_body'} );
    $easy->setopt( CURLOPT_VERBOSE() => 1 );

    return $easy;
}

done_testing;
