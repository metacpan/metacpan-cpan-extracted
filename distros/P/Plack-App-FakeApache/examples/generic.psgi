#
# Generic Plack wrapper for running mod_perl2 applications.
#
# Configuration: 
#
my $handler   = "My::ModPerl::Handler"; # Name of you ModPerl handler module
my $hostname  = "localhost";            # If defined this overrules the plackup server name
#
# Then you should be able to run your application with
#
#   $ plackup generic.psgi
#
# 
# To enable debugging run it as
#
#   $ PERLDB_OPTS=NonStop PERL5OPT=-d plackup generic.psgi
#
# When the server is started you can press ^C to get to the debugger prompt
# and then add breakpoints and whatnot.
#
#
# To enable profiling of all requests run as
#
#   $ NYTPROF="sigexit=1:start=no" PERL5OPT=-d:NYTProf plackup generic.psgi
#
# This will automatically enable and disable profiling in such way that only
# the actual requests is profiled.
#

use Plack::Builder;
use Plack::App::FakeApache;

my $profiling = defined( $Devel::NYTProf::VERSION );

my $setup = sub {
    my $app = shift;
    sub {
        my $env = shift;

        # By standard the SERVER_NAME is set to '0'. This breakes the COPY and
        # MOVE requests from some clients (including litmus). Set it to
        # 'localhost':
        $env->{SERVER_NAME} = $hostname if defined $hostname;

        DB::enable_profile()  if $profiling;
        my $res = $app->($env);
        DB::disable_profile() if $profiling;

        $res;
    }
};
        

builder {
    enable "Auth::Basic", authenticator => sub { 1 };
    enable $setup;

    Plack::App::FakeApache->new(
        handler    => $handler,
        dir_config => { Ping => "Pong" },
    )->to_app;
}

# Setup vim:
# vim: set filetype=perl

