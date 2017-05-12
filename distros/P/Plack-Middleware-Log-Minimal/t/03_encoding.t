use strict;
use Test::More;

use Plack::Builder;
use Plack::Test;
use Log::Minimal;
use Encode;

eval {
  my $app = builder {
    enable 'Log::Minimal',
      autodump => 1,
      loglevel => 'WARN',
      encoding => '_unknown encoding_';
    sub { ["200",[ 'Content-Type' => 'text/plain' ],["OK"]] }
  };
};
ok( $@ );


my $app = builder {
    enable 'Log::Minimal',
        autodump => 1,
        loglevel => 'WARN',
        encoding => 'euc-jp';
    sub { warnf("\x{306b}"); ["200",[ 'Content-Type' => 'text/plain' ],["OK"]] }
};


{
    my $warn;
    test_psgi
        app => sub {
            my $env = shift;
            $env->{'psgi.errors'} = do { open my $io, ">", \$warn; $io };
            $app->($env)
        },
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/bar");
            my $res = $cb->($req);
            ok( $res->is_success );
       };

    my $euc = Encode::encode('euc-jp',"\x{306b}");
    like $warn, qr/$euc/;
}

done_testing;

