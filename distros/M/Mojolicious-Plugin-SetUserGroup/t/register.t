use strict;
use warnings;

use Mojolicious::Lite;
use Test::More;

open my $log_handle, '>', \my $log_buffer;
app->log->handle($log_handle);

eval {
	plugin 'SetUserGroup' => {
		user  => 'bad user name !!!!!',
	};
};

my $error = $@;
like(
	$error,
	qr/User "bad user name !!!!!" does not exist/,
	'plugin croaks on bad user at register'
);
like(
	$log_buffer,
	qr/User "bad user name !!!!!" does not exist/,
	'plugin logs error on bad user at register'
);

$log_buffer = '';

eval {
	plugin 'SetUserGroup' => {
		user  => scalar getpwuid $>,
		group => 'bad group name !!!!!',
	};
};

$error = $@;
like(
	$error,
	qr/Group "bad group name !!!!!" does not exist/,
	'plugin croaks on bad user at register'
);
like(
	$log_buffer,
	qr/Group "bad group name !!!!!" does not exist/,
	'plugin logs error on bad user at register'
);

done_testing;
