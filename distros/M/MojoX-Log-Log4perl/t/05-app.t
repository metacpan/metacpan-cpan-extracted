use Mojo::Base -strict;
 
BEGIN {
  $ENV{MOJO_MODE}    = 'development';
  $ENV{MOJO_NO_IPV6} = 1;
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
 
use Test::More tests => 7;
use Mojolicious::Lite;
use MojoX::Log::Log4perl;
use Test::Mojo;

my $config = {
	'log4perl.rootLogger' => 'DEBUG, TEST',
	'log4perl.appender.TEST' => 'Log::Log4perl::Appender::TestBuffer',
        'log4perl.appender.TEST.layout' => 'SimpleLayout',
};

app->log( MojoX::Log::Log4perl->new($config) );
my $log = app->log;
isa_ok $log, 'MojoX::Log::Log4perl';

ok my $appender = Log::Log4perl->appenders()->{TEST}, 'able to fetch test appender';
is $appender->buffer, '', 'appender starts empty';

get '/' => sub {
	my $self = shift;
	app->log->error('this is my action error');
	$self->render( text => 'got to the action' );
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('got to the action');
like $appender->buffer, qr/ERROR - this is my action error/, 'found proper log message';

