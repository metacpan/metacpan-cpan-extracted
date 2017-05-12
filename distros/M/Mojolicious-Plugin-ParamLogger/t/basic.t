package App;

use Mojo::Base 'Mojolicious';

use Data::Dumper;
use File::Spec;

has options => sub { {} };

sub startup
{
    $Data::Dumper::Sortkeys = 1;

    my $self = shift;
    $self->plugin('ParamLogger', %{$self->options});

    my %log;
    $self->app->log->path(File::Spec->devnull);
    $self->app->log->on(message => sub {
	my ($log, $level, @messages) = @_;
	$log{$messages[0]} = $level;
    });

    $self->routes->get('/')->to(cb => sub {
	my $data = '';
	$data .= "$log{$_}: $_\n" for keys %log;

	shift->render(text => $data);
	%log = ();
    });
}

package main;

use Mojo::Base -strict;
use Test::More tests => 17;
use Test::Mojo;

$ENV{MOJO_LOG_LEVEL} = 'debug';

eval { App->new(options => { level => 'bad' }) };
like($@, qr/unknown log level 'bad'/);

my $t = Test::Mojo->new(App->new);
$t->get_ok('/')->content_like(qr|debug: GET / \{}|, 'no params logged');
$t->get_ok('/?a=1&b=2')->content_like(qr|debug: GET / \{ "a" => 1, "b" => 2 }|, 'multiple params logged');
$t->get_ok('/?password=p@ss')->content_like(qr|debug: GET / \{ "password" => "########" }|, 'password filtered');

$t = Test::Mojo->new(App->new(options => { filter => 'a' }));
$t->get_ok('/?a=1')->content_like(qr|debug: GET / \{ "a" => "########" }|, 'single param filtered');

$t = Test::Mojo->new(App->new(options => { filter => ['a', 'b'] }));
$t->get_ok('/?a=1&b=2&c=3')->content_like(qr|debug: GET / \{ "a" => "########", "b" => "########", "c" => 3 }|, 'multiple params filtered');

$t = Test::Mojo->new(App->new(options => { level => 'info' }));
$t->get_ok('/')->content_like(qr|info: GET / \{}|, 'log level');

$t = Test::Mojo->new(App->new(mode => 'production'));
$t->get_ok('/')->content_unlike(qr|info: GET / \{}|, 'disabled for production');

$t = Test::Mojo->new(App->new(mode => 'production', options => { production => 1 }));
$t->get_ok('/')->content_like(qr|info: GET / \{}|, 'enabled for production');
