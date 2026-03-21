#!/bin/env perl

use strict;
use warnings;

# use Test::More qw( no_plan );
use Test::More tests => 27;

BEGIN { use_ok('Confluent::SchemaRegistry'); }
BEGIN { use_ok('Net::Kafka::Producer::Avro'); }
BEGIN { use_ok('Time::HiRes'); }
BEGIN { use_ok('AnyEvent'); }
BEGIN { use_ok('Try::Tiny'); }
BEGIN { use_ok('JSON'); }

sub _nvl_str {
	return defined $_[0] ? $_[0] : ''; 
}

my $class = 'Net::Kafka::Producer::Avro';

my $kafka_host = $ENV{KAFKA_HOST} || 'localhost';
my $kafka_port = $ENV{KAFKA_PORT} || '9092';

SKIP: {

	my $sr_url = $ENV{CONFLUENT_SCHEMA_REGISTY_URL} || 'http://localhost:8081';
	my $sr = Confluent::SchemaRegistry->new('host' => $sr_url);
	unless (ref($sr) eq 'Confluent::SchemaRegistry') {
		diag(   "\n",
				"\n",
				('*' x 80), "\n",
				"WARNING! Confluent Schema Registry service is not up or isn't listening on $sr_url.", "\n",
				"Please, try setting CONFLUENT_SCHEMA_REGISTY_URL environment variable to specify it's URL.", "\n",
				('*' x 80) . "\n",
				"\n");
        skip(qq/Confluent Schema Registry service is not up or isn't listening on $sr_url/, 16);
	}

	my $producer;

	try {
		$class->new(
			'bootstrap.servers', $kafka_host.':'.$kafka_port , 
		);
		ok(0, "Invalid client config");
	} catch {
		ok(1, "Invalid client config");
	};


	$producer = new_ok(
		$class => [
			'bootstrap.servers', $kafka_host.':'.$kafka_port , 
			'schema-registry', $sr ,
			'error_cb', sub {
				my ($self, $err, $msg) = @_;
				diag(   "\n",
						"\n",
						('*' x 80), "\n",
						"WARNING! Apache Kafka is not up or isn't listening on $kafka_host:$kafka_port.", "\n",
						"Please, try setting KAFKA_HOST and KAFKA_PORT environment variables.", "\n",
						('*' x 80) . "\n",
						"\n");
				skip(qq/Confluent Schema Registry service is not up or isn't listening on $kafka_host:$kafka_port/, 16);
			} ,
		], qq/Valid client config/
	);
	isa_ok($producer, $class);


	my $topic = 'perl-net-kafka-producer-avro-test'; # -' . time;
	my $partition = 0;
	my $messages = [ 
		{ 'f1' => 'foo ' . localtime }, 
		{ 'f1' => 'bar ' . localtime },
		{ 'f2' => 'BAD ' . localtime },
		{ 'f1' => 'foo ' . localtime, 'f2' => 'baz ' . localtime },
	];
	my $compression_codec = undef;
 	my $key_schema = to_json({
		"name" => "_id",
		"type" => "long"
	});
	my $value_schema = to_json({
		"type" => "record",
		"name" => "myrecord",
		"fields" => [
			{
				"name" => "f1",
				"type" => "string"
			}
		]
	});
	my $value_schema_evolved = to_json({
		"type" => "record",
		"name" => "myrecord",
		"fields" => [
			{
				"name" => "f1",
				"type" => "string"
			},
			{
				"name" => "f2",
				"type" => ["null", "string"],
				"default" => undef
			}
		]
	});
	my $value_schema_not_compliant = to_json({
		"type" => "string",
		"name" => "myrecord"
	});
	my $value_schema_bad = to_json({
		"typ" => "string",
		"name" => "myrecord"
	});

	my $unexpected_param = 0;
	my $res;

	# Clear Schema Registry subjects used for testing
	my $clear_schemas = sub {
		$producer->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'key');
		$producer->schema_registry()->delete_subject(SUBJECT => $topic, TYPE => 'value');
	};
	$clear_schemas->();

	my ($condvar, $msgid, $promise);

	# invalid value schema
	$msgid = 1;
	$condvar = AnyEvent->condvar;
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  0+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema_bad,
	);
	$condvar->end();
	is($promise, undef, 'Expected undef instead of a promise when an invalid value schema is supplied');

	# first successful message production
	$msgid = 0;
	$condvar = AnyEvent->condvar;
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  0+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema,
	);
	isa_ok($promise, 'AnyEvent::XSPromises::PromisePtr', 'Produce method returns a promise of class ' . ref($promise));
    $promise->then(
        sub {
            my $delivery_report = shift;
			ok(1, 'first successful message sent');
            $condvar->send(1);
        }, 
        sub {
            my $error = shift;
			ok(0, 'error sending first message');
            $condvar->send(1);
        }
    );
    ok($condvar->recv, 'wait for the first successful message');

	# second successful message production without schemas
	$msgid = 1;
	$condvar = AnyEvent->condvar;
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  0+$msgid,
		# key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		# payload_schema  =>  $value_schema,
	);
	isa_ok($promise, 'AnyEvent::XSPromises::PromisePtr', 'Produce method returns a promise of class ' . ref($promise));
    $promise->then(
        sub {
            my $delivery_report = shift;
			ok(1, 'second successful message sent');
            $condvar->send(1);
        }, 
        sub {
            my $error = shift;
			ok(0, 'error sending second message');
            $condvar->send(1);
        }
    );
    ok($condvar->recv, 'wait for the second successful message');

	# invalid message production
	$msgid = 2;
	$condvar = AnyEvent->condvar;
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  0+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema,
	);
	$condvar->end();
	is($promise, undef, 'Expected undef instead of a promise when an invalid message is supplied');

	# value schema not compliant with the latest registered schema
	$msgid = 1;
	$condvar = AnyEvent->condvar;
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  0+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema_not_compliant,
	);
	$condvar->end();
	is($promise, undef, 'Expected undef instead of a promise when a not compliant schema is supplied');

	# fourth successful message production with evolved schema
	$msgid = 3;
	$condvar = AnyEvent->condvar;
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  0+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema_evolved,
	);
	isa_ok($promise, 'AnyEvent::XSPromises::PromisePtr', 'Produce method returns a promise of class ' . ref($promise));
    $promise->then(
        sub {
            my $delivery_report = shift;
			ok(1, 'fourth successful message sent');
            $condvar->send(1);
        }, 
        sub {
            my $error = shift;
			ok(0, 'error sending fourth message');
            $condvar->send(1);
        }
    );
    ok($condvar->recv, 'wait for the fourth successful message');

	# supplied timestamp
	$msgid = 3;
	$condvar = AnyEvent->condvar;
	my $timestamp = int( Time::HiRes::time * 1000 ) + 60000; # current time + 60 seconds
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  2000+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema_evolved,
		timestamp       =>  $timestamp,
	);
	isa_ok($promise, 'AnyEvent::XSPromises::PromisePtr', 'Produce method returns a promise of class ' . ref($promise));
    $promise->then(
        sub {
            my $delivery_report = shift;
			ok($delivery_report->{timestamp} == $timestamp, 'message sent with supplied timestamp');
            $condvar->send(1);
        }, 
        sub {
            my $error = shift;
			ok(0, 'error sending message with supplied timestamp');
            $condvar->send(1);
        }
    );
    ok($condvar->recv, 'wait for the message sent with supplied timestamp');

	# supplied header
	$msgid = 0;
	$condvar = AnyEvent->condvar;
	my $headers = Net::Kafka::Headers->new();
	$headers->add('my-header', 'ABC-1234567890');
	$promise = $producer->produce(
		topic           =>  $topic,
		partition       =>  $partition,
		key             =>  1000+$msgid,
		key_schema      =>  $key_schema,
		payload         =>  $messages->[$msgid],
		payload_schema  =>  $value_schema_evolved,
		headers         =>  $headers,
	);
	isa_ok($promise, 'AnyEvent::XSPromises::PromisePtr', 'Produce method returns a promise of class ' . ref($promise));
    $promise->then(
        sub {
            my $delivery_report = shift;
			ok($delivery_report->{headers}->get_last('my-header') eq $headers->get_last('my-header'), 'message sent with supplied headers');
            $condvar->send(1);
        }, 
        sub {
            my $error = shift;
			ok(0, 'error sending message with supplied headers');
            $condvar->send(1);
        }
    );
    ok($condvar->recv, 'wait for the message sent with supplied headers');


	$clear_schemas->();
	$producer->close();

}
