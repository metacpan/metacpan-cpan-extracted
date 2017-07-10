use strict;
use warnings;
use Test::More;
use Test::Mojo;
use Mojolicious::Lite;
use Capture::Tiny 'capture_stderr';
use Mojo::Log::Colored;

$ENV{MOJO_LOG_LEVEL} = 'debug'; # so we can run in on-verbose prove

my $logger = Mojo::Log::Colored->new;
$logger->format( sub { "$_[1]\n" } );
app->log($logger);

get '/debug' => sub { app->log->debug('foo'); shift->render( template => 'foo' ); };
get '/info'  => sub { app->log->info('foo');  shift->render( template => 'foo' ); };
get '/warn'  => sub { app->log->warn('foo');  shift->render( template => 'foo' ); };
get '/error' => sub { app->log->error('foo'); shift->render( template => 'foo' ); };
get '/fatal' => sub { app->log->fatal('foo'); shift->render( template => 'foo' ); };

my %defaults = (
    debug => "\e[1;97m",
    info  => "\e[1;94m",
    warn  => "\e[1;32m",
    error => "\e[1;33m",
    fatal => "\e[1;33;41m",
);

my $t = Test::Mojo->new;
for my $level ( sort keys %defaults ) {
    my $stderr = capture_stderr {
        $t->get_ok("/$level")->status_is(200)->content_is("ok\n");
    };

    like $stderr, qr{
        \Q$defaults{$level}\E   # color of this level, escaped
        $level
        \n
        \e\[0m                  # end of coloring
    }x, "log contains colors for $level";
}
done_testing;

__DATA__
@@ foo.html.ep
ok
