#!/usr/bin/env perl
use strict;
use warnings;

# Disable IPv6, epoll and kqueue
BEGIN { $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 }

use Test::More;

use lib '../lib';
eval "use DBD::AnyData";
plan skip_all => 'DBD::AnyData required for this test!' if $@;
plan tests => 29;

# testing code starts here
use Mojolicious::Lite;
use Test::Mojo;
use DBI;
use Try::Tiny;

plugin 'any_data', {
    load_data => {
	users => [
	    ['id_user', 'user_name'],
	    [1,         'Alex'],
	    [2,         'John'],
	]
    },
    helper => 'dbh',
};

get '/get-user' => sub {
    my $self = shift;
    
    my $user_name = $self->dbh->selectrow_array(qq{
	select user_name
	from users
	where
	    id_user = ?
    }, undef, 1);

    $self->render(text => ( $user_name eq 'Alex' ) ? 'ok' : 'failed');
};

get '/make-func' => sub {
    my $self = shift;
    
    $self->dbh->func('ages', 'ARRAY', [
            ['age', 'id_user'],
	    [28,    1],
	    [32,    2],
	],
	'ad_import'
    );
    
    $self->render(text => 'ok');
};

get '/make-func-error' => sub {
    my $self = shift;
    
    $self->dbh->func('ages', 'ARRAY', [
            ['age', 'id_user'],
	    [28,    1],
	    [32,    2],
	],
	'ad_import'
    );
    
    $self->dbh->func('ages', 'ARRAY', [
            ['age', 'id_user'],
	    [28,    1],
	    [32,    2],
	],
	'ad_import'
    );
    
    $self->render(text => 'ok');
};

get '/get-age' => sub {
    my $self = shift;
    
    my $age = $self->dbh->selectrow_array(qq{
	select age
	from ages
	join users using (id_user)
	where
	    user_name = ?
    }, undef, 'Alex');
    
    $self->render(text => ($age == 28) ? 'ok' : 'failed');
};

# With recently added helper any_data 
get '/version' => sub {
    my $self = shift;
    
    $self->render( text => $self->any_data->version );
};

get '/any_data/load_data' => sub {
    my $self = shift;
    
    $self->any_data->load_data({
	cars => [
	    ['id', 'model'],
	    [ '1', 'Honda'],
	],
    });
    
    my $model = $self->dbh->selectrow_array(qq{
	select model from cars where id = ?
    }, undef, 1);
    
    $self->render( text => $model );
};

get '/any_data/load_data_2' => sub {
    my $self = shift;
    
    $self->any_data->load_data({
	cars => [
	    ['id', 'model'],
	    [ '1', 'Honda'],
	],
    });
    
    $self->any_data->load_data({
	cars => [
	    ['id', 'model'],
	    [ '1', 'Honda'],
	],
    });
    
    my $model = $self->dbh->selectrow_array(qq{
	select model from cars where id = ?
    }, undef, 1);
    
    $self->render( text => $model );
};

get '/any_data/load_data_3/:id' => sub {
    my $self = shift;
    
    $self->any_data->load_data('data.conf');
    my $id = $self->stash('id');
    
    my $cd_title = $self->dbh->selectrow_array('select title from cd where id = ?', undef, $id);
    
    $self->render( text => $cd_title );
};

get '/any_data/func' => sub {
    my $self = shift;
    
    $self->any_data->func('table1', 'ARRAY', [
        ['col1', 'col2'],
	['28',   '1'],
	['32',   '2'],
    ],
    'ad_import' );
    my $age = $self->dbh->selectrow_array('select col1 from table1 where col2 = ?', undef, 1);
    
    $self->render( text => $age );
};

my $t = Test::Mojo->new();

$t->get_ok('/get-user')->status_is(200)->content_is('ok');
$t->get_ok('/make-func')->status_is(200)->content_is('ok');
$t->get_ok('/get-age')->status_is(200)->content_is('ok');
$t->get_ok('/version')->status_is(200)->content_is('1.20');
$t->get_ok('/any_data/load_data')->status_is(200)->content_is('Honda');

$t->get_ok('/make-func-error')->status_is(500);
$t->get_ok('/any_data/load_data_2')->status_is(200)->content_is('Honda');
$t->get_ok('/any_data/load_data_3/1')->status_is(200)->content_is('Load');
$t->get_ok('/any_data/load_data_3/2')->status_is(200)->content_is('Death Magnetic');

$t->get_ok('/any_data/func')->status_is(200)->content_is(28);

