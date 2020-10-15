
use strict;
use warnings;

use feature qw/ state /;

use CHI;
use Log::Log4perl qw/ :easy /;
use Plack::App::Prerender;

my $cache = CHI->new(
    driver => 'File',
    root_dir => '/tmp/test-chi',
);

use Robots::Validate v0.2.0;

sub validator {
    my ($path, $env) = @_;

    # state $rv = Robots::Validate->new();

    # unless ($rv->validate( $env->{REMOTE_ADDR}, { agent => $env->{USER_AGENT} } )) {
    #     return [ 403, [], [] ];
    # }

    return "https://www.sciencephoto.com" . $path;
}

Log::Log4perl->easy_init($ERROR);

my $app = Plack::App::Prerender->new(
    rewrite => \&validator,
    cache   => $cache,
)->to_app;
