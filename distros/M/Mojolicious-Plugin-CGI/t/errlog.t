use lib '.';
use t::Helper;

unlink 't/err.log';

my $app = Mojolicious->new;
my $t   = Test::Mojo->new($app);
my ($s, @err);

$app->plugin(CGI => {route => '/err', script => cgi_script('errlog')});
$app->log->on(
  message => sub {
    my ($log, $level, $message) = @_;
    push @err, $message if $level eq 'warn';
  }
);

$t->get_ok('/err');
like $err[0], qr{\[CGI:errlog:\d+\] yikes! at .*errlog line 4}, 'logged stderr';

$app = Mojolicious->new;
$t   = Test::Mojo->new($app);

$app->plugin(CGI => {route => '/err', script => cgi_script('errlog'), errlog => 't/err.log'});

$t->get_ok('/err');
$s = -s 't/err.log';
ok $s, 't/err.log has data';

$t->get_ok('/err');
ok -s 't/err.log' >= $s * 2, 't/err.log has more data';

unlink 't/err.log';
done_testing;
