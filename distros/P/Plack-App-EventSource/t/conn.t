use strict;
use warnings;

use Test::More;
use Plack::App::EventSource::Connection;

subtest 'calls write_cb on push' => sub {
    my $written = 0;
    my $conn = _build_conn(push_cb => sub { $written++ });

    $conn->push('foo');

    is $written, 1;
};

subtest 'calls close_cb on push' => sub {
    my $closed = 0;
    my $conn = _build_conn(close_cb => sub { $closed++ });

    $conn->close;

    is $closed, 1;
};

done_testing;

sub _build_conn {
    Plack::App::EventSource::Connection->new(@_);
}
