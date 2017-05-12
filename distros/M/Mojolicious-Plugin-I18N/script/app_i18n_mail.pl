#!/usr/bin/env perl
use common::sense;
use lib qw(../lib ../../mojox-loader/lib ../../mojolicious-plugin-mail/lib ../../mojo/lib);

use MojoX::Loader;

my $self = MojoX::Loader->load;
warn $self->app->test;

warn my $mail = $self->render_mail('test', hall => {id => 1, title => 'test'});

$self->mail(
	to     => 'sharifulin@gmail.com',
	type   => 'multipart/mixed',
	attach => [
		{
			Type     => 'text/html',
			Data     => $mail,
		},
	],
);
