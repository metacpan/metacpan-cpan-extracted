use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Config;

if (not -d 't/app')
{
    my $sharedir = eval { File::ShareDir::dist_dir('Plack-App-BeanstalkConsole') };

    if (-d $sharedir and glob("$sharedir/*"))
    {
        plan skip_all => 'cannot create symlinks on this system' if not $Config{d_symlink};
        diag "symlinking $sharedir <- t/app for override tests";
        symlink($sharedir, 't/app');
        END { unlink 't/app' }
    }
    else
    {
        # if we hit this case, we must be running a copy directly out of git
        # rather than an uploaded version, *and* do not have a copy of the app
        # in t/app/ that the primary developer has
        die 'missing t/app: run in-repo Makefile.PL!';
    }
}

use Plack::Test;
use HTTP::Request::Common;
use Plack::App::BeanstalkConsole;

my $app = Plack::App::BeanstalkConsole->new(
    root => 't/app',
)->to_app;

foreach my $url (
    '/',
    '/public/',
)
{
    my $http_request = GET $url;

    # TODO: Plack::Test should do this.
    my $response;
    do {
        $response = test_psgi($app, sub { shift->($http_request) });
        $http_request->uri($response->header('location')) if $response->code eq '301';
    }
    until $response->code ne '301';

    is($response->code, '200', "can successfully contact the app at $url");
}

done_testing;
