use strict;
use warnings;

use Test::More tests => 1;
use Plack::Test;
use Plack::Builder;
use Plack::Debugger;
use Plack::App::Debugger;
use Plack::Debugger::Storage;
use HTTP::Request::Common;
use Path::Class qw[dir];
use JSON::XS;

use Plack::Debugger::Panel::Dancer2::Version;

my $DATA_DIR = dir('./t/tmp/');

# create tmp dir if needed
mkdir $DATA_DIR unless -e $DATA_DIR;

# cleanup tmp dir
{
    ( ( -f $_ && $_->remove ) || ( -d $_ && $_->rmtree ) )
        foreach $DATA_DIR->children( no_hidden => 1 )
}

{

    package TestApp;
    use Dancer2;
    get '/' => sub {
        return <<'EOF';
<html>
    <head><title>Test App</title></head>
    <body>
        <h1>This is a test App</h1>
        <p>Hello World</p>
    </body>
</html>
EOF
    };
    1;
}

my $debugger = Plack::Debugger->new(
    storage => Plack::Debugger::Storage->new(
        data_dir     => $DATA_DIR,
        serializer   => sub { encode_json(shift) },
        deserializer => sub { decode_json(shift) },
        filename_fmt => "%s.json",
    ),
    panels => [ Plack::Debugger::Panel::Dancer2::Version->new, ]
);

my $debugger_app = Plack::App::Debugger->new( debugger => $debugger );
my $test = Plack::Test->create(
    builder {
        mount $debugger_app->base_url => $debugger_app->to_app;

        mount '/' => builder {
            enable $debugger_app->make_injector_middleware;
            enable $debugger->make_collector_middleware;
            TestApp->to_app;
        }
    }
);
my $res = $test->request( GET "/" );
ok( $res->content =~ /plack-debugger-js-init/, q{debugger inserted} );

# cleanup tmp dir
{
    ( ( -f $_ && $_->remove ) || ( -d $_ && $_->rmtree ) )
        foreach $DATA_DIR->children( no_hidden => 1 )
}

