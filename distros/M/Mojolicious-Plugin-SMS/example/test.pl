#!/usr/bin/env perl
use utf8;
use Mojolicious::Lite;

plugin 'SMS' => { driver => 'Nexmo', '_username'=>'bb419dbf', '_password'=>'26976322', '_from'=>'SUBARU' };

get '/' => sub {
	my $self = shift;
	$self->sms(to => '+380506022374', text => 'Hello!');
	$self->render_text('OK');
};

app->start;
