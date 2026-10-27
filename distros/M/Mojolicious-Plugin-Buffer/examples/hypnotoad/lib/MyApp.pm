package MyApp;

use strict;
use warnings;

use CHI;
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec ();
use Mojo::Base 'Mojolicious';

sub startup {
	my $self = shift;

	my $home      = $self->home;
	my $var_dir   = $home->child('var')->to_string;
	my $cache_dir = $ENV{MYAPP_CACHE_DIR} // File::Spec->catdir($var_dir, 'cache');
	my $lock_dir  = $ENV{MYAPP_LOCK_DIR} // File::Spec->catdir($var_dir, 'locks');
	my $pid_file  = $ENV{MYAPP_PID_FILE} // File::Spec->catfile($var_dir, 'hypnotoad.pid');
	my $listen    = $ENV{MYAPP_LISTEN} // 'http://*:8080';

	make_path($cache_dir, $lock_dir, dirname($pid_file));

	$self->config(hypnotoad => {
		listen   => [$listen],
		workers  => 4,
		pid_file => $pid_file,
	});

	$self->plugin('Buffer' => {
		optimise_content => 1,
		cache => CHI->new(
			driver    => 'File',
			root_dir  => $cache_dir,
			namespace => 'pages',
		),
		cache_lock_dir => $lock_dir,
		cache_duration => '10 minutes',
	});

	$self->routes->get('/expensive' => sub {
		my $c = shift;
		return if $c->buffer_is_cached;

		# ... expensive work ...

		$c->render(template => 'expensive', built_at => scalar localtime);
	});

	return;
}

1;
