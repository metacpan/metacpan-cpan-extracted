use Test::More;
use Net::Docker;
use IO::String;

my $api = Net::Docker->new;

my $id = $api->create(Cmd => ['echo', 'Hello world'], Image => 'ubuntu');
like($id, qr/^[0-9a-f]+$/);
$api->start($id);

## test named containers
my $named_id = $api->create(Cmd => ['echo', 'Hello world'], Image => 'ubuntu', Name => 'perl-test-' . int(rand(1000)+100));
my $ins = $api->inspect_container($named_id);
like($ins->{Name}, qr/^\/perl-test-\d+$/);

TODO: {
    local $TODO = 'needs anyevent http support for unix socket';

#    my $io = IO::String->new;
#    my $cv = $api->streaming_logs($id, stream => 1, logs => 1, stdout => 1, out_fh => $io, in_fh => \*STDIN);
#    $cv->recv;
#    is(${$io->string_ref}, "Hello world\r\n");
}

done_testing;
