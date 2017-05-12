use strict;
use Test::More;

use Plack::Builder;
use Plack::Test;

my $app = builder {
    enable 'LogFilter', filter => sub {
        my ($env, $output) = @_;

        if ($output =~ /\[DEBUG\]/) {
            return 0;
        }

        return 1;
    };
    sub {
        my $env = shift;
        $env->{'psgi.errors'}->print("[DEBUG] debug message\n");
        $env->{'psgi.errors'}->print("[INFO] info message\n");
        ["200",[ 'Content-Type' => 'text/plain' ], ["OK"]];
    };
};

{
    my $warn;
    test_psgi
        app => sub {
            my $env = shift;
            $env->{'psgi.errors'} = do { open my $io, '>', \$warn; $io };
            $app->($env);
        },
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/bar");
            my $res = $cb->($req);
            ok( $res->is_success );
        };
    is $warn, "[INFO] info message\n";
}


done_testing();
