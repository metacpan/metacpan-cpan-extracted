use strict;
use Test::More;
use Plack::Test;
use Plack::Util::Load;

sub check(@) { ## no strict
    my ($app, $content, $message) = @_;
    local $Carp::CarpLevel=1;
    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "/hello");
        my $res = $cb->($req);
        is $res->content, $content, $message;
    };
}

{
    package MyApp1;
    use parent 'Plack::Component';
    sub call { 
        [200,[],['MyApp1'.$_[1]->{PATH_INFO}]]; }
    1;
}

{ 
    package My::Dummy;
    sub new { bless {}, shift }
    1;
}

# $Plack::Util::Load::VERBOSE = 1;

check do('t/app.psgi'), 'app.psgi/hello', 'CODE';
check load_app(MyApp1->new), 'MyApp1/hello', 'instance';
check load_app('MyApp1'), 'MyApp1/hello', 'module (defined)';
ok load_app('Plack::App::File'), 'module (INC)';

chdir 't';
check load_app(), 'app.psgi/hello', 'default: app.psgi';
check load_app('MyApp2'), 'MyApp2/hello', 'module (from file)';
chdir '..';

check load_app('t/app.psgi'), 'app.psgi/hello', 'file';


my @errors = (
    undef,          'app.psgi',
    '',             'app.psgi',
    '-',            '-',
    'My::Dummy',    'My::Dummy from package',
    My::Dummy->new, 'from object or reference My::Dummy',
);
while (@errors) {
    my $app = eval { load_app(shift @errors) };
    my $msg = "failed to load app " . shift @errors;
    like $@, qr{^$msg at t/load_app\.t}, $msg;
}

eval { load_app('My::App0') };
ok $@, 'failed to load app, module not found';

done_testing;
