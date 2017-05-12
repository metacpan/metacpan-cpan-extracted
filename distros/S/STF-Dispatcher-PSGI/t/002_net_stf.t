use strict;
use Test::More;
BEGIN {
    foreach my $module (qw(Net::STF::Client Test::TCP Plack::Runner)) {
        eval "require $module";
        if ($@) {
            plan skip_all => "$module is not installed"
        }
    }
}

use_ok "STF::Dispatcher::PSGI";
use_ok "STF::Dispatcher::Impl::Hash";

my $server = Test::TCP->new(
    code => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options( '-p' => $port );
        $runner->run( STF::Dispatcher::PSGI->new(impl => STF::Dispatcher::Impl::Hash->new())->to_app );
    }
);
my $stf_uri = sprintf "http://127.0.0.1:%d", $server->port;

subtest 'synopsis' => sub {
    my $key = "selftest";
    my $filename = $0;
    my $opts = {};

    my $stf = Net::STF::Client->new({
        url        => $stf_uri,
        username   => 'user',
        password   => 'Your Password',
        repl_count => 3,
    });

    my $bucket = $stf->create_bucket('bucket') or die $stf->errstr;
    $bucket->put_object( $key, $filename, $opts ) or die $bucket->errstr;
    my $obj = $bucket->get_object( $key );

    ok $obj;
    is $obj->content, do { open my $fh, '<', $0; local $/; <$fh> }, "Content matches";
    is $obj->bucket_name, "bucket";

    $bucket->delete_object( $key );
    $obj = $bucket->get_object( $key );

    ok ! $obj;
};

END { undef $server };

done_testing;