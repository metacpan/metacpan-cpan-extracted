#!perl

use strict;
use warnings;

use JSON::PP;
use Test::Most;
use Test::PayProp::API::Public::Emulator;

use PayProp::API::Public::Client::Authorization::APIKey;


use_ok('PayProp::API::Public::Client::Request::Tags');

my $SCHEME = 'http';
my $EMULATOR_HOST = '127.0.0.1';

my $Emulator = Test::PayProp::API::Public::Emulator->new(
	scheme => 'http',
	exec => 'payprop_api_client.pl',
	host => $EMULATOR_HOST,
);

isa_ok(
	my $Tags = PayProp::API::Public::Client::Request::Tags->new(
		scheme => $SCHEME,
		api_version => 'v1.1',
		domain => $Emulator->url,
		authorization => PayProp::API::Public::Client::Authorization::APIKey->new( token => 'AgencyAPIKey' ),
	),
	'PayProp::API::Public::Client::Request::Tags'
);

is $Tags->url, $Emulator->url . '/api/agency/v1.1/tags', 'Got expected Tags URL';

subtest '->list_p | Retrieve tags' => sub {

	$Emulator->start;

	$Tags
		->list_p
		->then( sub {
			my ( $tags, $optional ) = @_;

			is scalar $tags->@*, 2;
			isa_ok( $tags->[0], 'PayProp::API::Public::Client::Response::Tag' );

			cmp_deeply
				$optional,
				{
					pagination => {
						rows => 2,
						page => 1,
						total_pages => 1,
						total_rows => 2,
					}
				},
				'optional args'
			;

		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->create_p | Create tag' => sub {

	$Emulator->start;

	$Tags
		->create_p({
			content => { name => 'New tag1' },
		})
		->then( sub {
			my ( $Tag ) = @_;

			is $Tag->id, 'woRZQl1mA4', 'Got expected tag id';
			is $Tag->name, 'New tag1', 'Got expected tag name';
			isa_ok( $Tag, 'PayProp::API::Public::Client::Response::Tag', 'PayProp::API::Public::Client::Response::Tag' );

		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->link_entities_p | Link tags with entities' => sub {

	$Emulator->start;

	$Tags
		->link_entities_p({
			path_params => {
				entity_type => 'property',
				entity_id => 'oz2JkGJbgm',
			},
			content => { names => ['New tag1', 'new_tag2'] },
		})
		->then( sub {
			my ( $tags ) = @_;

			my $Tag = shift @$tags;
			is $Tag->id, 'woRZQl1mA4', 'Got expected tag id';
			is $Tag->name, 'New tag1', 'Got expected tag name';
			isa_ok( $Tag, 'PayProp::API::Public::Client::Response::Tag', 'PayProp::API::Public::Client::Response::Tag' );
		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->list_tagged_entities_p | Retrieve tagged entities' => sub {

	$Emulator->start;

	$Tags
		->list_tagged_entities_p({
			path_params => {
				external_id => 'woRZQl1mA4',
			},
		})
		->then( sub {
			my ( $tags, $optional ) = @_;

			is scalar $tags->@*, 2, 'Got expected number of tagged entities';
			isa_ok( my $Tag = shift @$tags, 'PayProp::API::Public::Client::Response::Tag', 'Got exprected ref type' );

			is $Tag->id, 'qv1pKQBXdN', 'Got expected tagged entity id';
			is $Tag->type, 'property', 'Got expected tagged entity type';
			is $Tag->name, 'Fontana Road 51, Lephalale', 'Got expected tagged entity name';

			cmp_deeply
				$optional,
				{
					pagination => {
						rows => 2,
						page => 1,
						total_pages => 1,
						total_rows => 2,
					}
				},
				'optional args'
			;

		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->update_p | Update tag' => sub {

	$Emulator->start;

	$Tags
		->update_p({
			content => { name => 'New tag name' },
			path_params => { external_id => 'oz2JkGJbgm'},
		})
		->then( sub {
			my ( $Tag ) = @_;

			is $Tag->id, 'oz2JkGJbgm', 'Got expected tag id';
			is $Tag->name, 'New tag name', 'Got expected tag name';
			isa_ok( $Tag, 'PayProp::API::Public::Client::Response::Tag', 'PayProp::API::Public::Client::Response::Tag' );

		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->delete_p | Delete tag' => sub {

	$Emulator->start;

	$Tags
		->delete_p({
			path_params => { external_id => 'oz2JkGJbgm'}
		})
		->then( sub {
			my ( $response ) = @_;
			is $response->{message}, 'Tag has been successfully deleted.', 'Got expected message';
		} )
		->wait
	;

	$Emulator->stop;

};

subtest '->delete_entity_link_p | Delete tag entity link' => sub {

	$Emulator->start;

	$Tags
		->delete_entity_link_p({
			path_params => {
				external_id => 'oz2JkGJbgm'
			},
			params => {
				entity_type => 'property',
				entity_id => 'oz2JkGJbgm',
			},
		})
		->then( sub {
			my ( $response ) = @_;
			is $response->{message}, 'Tag link successfully removed from entity.', 'Got expected message';
		} )
		->wait
	;

	$Emulator->stop;

};

done_testing;
