package Net::Kafka::Producer::Avro;

=pod

=head1 NAME

Net::Kafka::Producer::Avro - Apache Kafka message producer based on librdkafka, Avro serialization and Confluent Schema Registry validation.

=head1 SYNOPSIS

  use Net::Kafka::Producer::Avro;
  use Confluent::SchemaRegistry;
  use AnyEvent;
  use JSON;
  
  
  my $producer = Net::Kafka::Producer::Avro->new(
    'bootstrap.servers' => 'localhost:9092',
    'schema-registry'  => Confluent::SchemaRegistry->new(), # defaults to http://localhost:8081
    'compression.codec' => 'gzip',  # optional, one of: 'none' (def.), 'gzip', 'snappy', 'lz4', 'zstd'
    'log_level' => 0, # suppress librdkafka internal logging
    'error_cb' => sub {
      my ($self, $err, $msg) = @_;
      die "Connection error:\n\t- err: " . $err . "\n\t- msg: " . $msg . "\n";
    }
  );
  
  # creates the header object (if you need to add headers to the message)
  my $headers = Net::Kafka::Headers->new();
  $headers->add('my-header-1', 'foo');
  $headers->add('my-header-2', 'bar');
  
  my $condvar = AnyEvent->condvar;
  
  my $promise = $producer->produce(
    topic          => 'mytopic',
    partition      => 0,
    key            => 1000,
    key_schema     => to_json(
                        {
                          name => 'id',
                          type => 'long'
                        }
                      ),
    payload        => {
                        id  => 1210120,
                        f1  => 'text message'
                      },
    payload_schema => to_json(
                        {
                          type => 'record',
                          name => 'myrecord',
                          fields => [
                            {
                              name => 'id',
                              type => 'long'
                            },
                            {
                              name => 'f1',
                              type => 'string'
                            }
                          ]
                        }
                      ),
    headers        => $headers
  );
  
  die "Error requesting message production: " . $producer->get_error() . "\n"
    unless $promise;
  
  $promise->then(
    sub {
      my $delivery_report = shift;
      $condvar->send; # resolve the promise
      print "Message delivered with offset " . $delivery_report->{offset};
    }, 
    sub {
      my $error = shift;
      $condvar->send; # resolve the promise
      die "Unable to produce message: " . $error->{error} . ", code: " . $error->{code};
    }
  );
  
  $condvar->recv; # wait for the promise resolution
  
  print "Message produced", "\n";

=head1 DESCRIPTION

C<Net::Kafka::Producer::Avro> main goal is to provide object-oriented API to 
produce Avro-serialized messages according to I<Confluent SchemaRegistry>.

C<Net::Kafka::Producer::Avro> inerhits from and extends L<Net::Kafka::Producer|Net::Kafka::Producer> module.

=cut

use 5.010;
use strict;
use warnings;

use base 'Net::Kafka::Producer';

use Memoize;
use JSON::XS;
use Try::Tiny;


use Avro::BinaryEncoder;
use Avro::Schema;
use Confluent::SchemaRegistry;


use constant MAGIC_BYTE => 0; 

use version; our $VERSION = version->declare('v0.0.1');

=head1 INSTALL

Installation of C<Net::Kafka::Producer::Avro> is a canonical:

  perl Makefile.PL
  make
  make test
  make install

=head2 TESTING TROUBLESHOOTING

Tests are focused on verifying Avro-formatted messages and theirs interactions with Confluent Schema Registry and are intended to extend the C<Net::Kafka::Producer>'s test suite.

It's expected that a local Apache Kafka and Schema Registry services are listening on C<localhost:9092> and C<http://localhost:8081>.

You can either set different endpoints by exporting the following environment variables:

=over 3

=item C<KAFKA_HOST>

=item C<KAFKA_PORT>

=item C<CONFLUENT_SCHEMA_REGISTY_URL>

=back

For example:

  export KAFKA_HOST=my-kafka-host.my-domain.org
  export KAFKA_PORT=9092
  export CONFLUENT_SCHEMA_REGISTY_URL=http://my-schema-registry-host.my-domain.org

=head1 USAGE

=head2 CONSTRUCTOR

=head3 C<new>

Creates a message producer.

C<new()> method expects the same arguments set as the L<Net::Kafka::Producer|Net::Kafka::Producer> parent constructor.

In addition, takes in the following mandatory argument:

=over 3

=item C<SchemaRegistry =E<gt> $schema_registry> (B<mandatory>)

Is a L<Confluent::SchemaRegistry|Confluent::SchemaRegistry> instance.

=back

=cut


sub new {
    my $this  = shift;
    my $class = ref($this) || $this;
    my $schema_registry_class = 'Confluent::SchemaRegistry';
    my %params = @_;

	# Check SchemaRegistry param
    die "Missing 'schema-registry' param"
    	unless exists $params{'schema-registry'};
    die "'schema-registry' param must be a $schema_registry_class instance object"
    	unless ref($params{'schema-registry'}) eq $schema_registry_class;
    my $schema_registry = delete $params{'schema-registry'};
    
    # Use parent class constructor
	my $self = $class->SUPER::new(%params);
	
	# Add ans internal reference to SchemaRegistry
	$self->{__SCHEMA_REGISTRY} = $schema_registry;
	
	return bless($self, $class);
}



##### Class methods

# Encode $payload in Avro format according to an Avro schema 
sub _encode {
	my $schema_ref = shift;
	my $payload = shift;
	return undef
		unless defined $payload;
	my $encoded = pack('bN', &MAGIC_BYTE, $schema_ref->{id});
	Avro::BinaryEncoder->encode(
		schema	=> $schema_ref->{schema},
		data	=> $payload,
		emit_cb	=> sub {
			$encoded .= ${ $_[0] };
		}
	);
	return $encoded;
}


##### Private methods

sub _clear_error { $_[0]->_set_error() } 
sub _set_error   { $_[0]->{__ERROR} = $_[1] } 
sub _get_error   { $_[0]->{__ERROR} }

# Interact with Schema Registry
memoize('_get_avro_schema');
sub _get_avro_schema {
	my $self = shift;
	my $topic = shift;
	my $type = shift;
	my $supplied_schema = shift;
	
	my $subject = $topic . '-' . $type;
	my $sr = $self->schema_registry();
	my ($schema_id, $avro_schema);
	
	# If a schema is supplied...	
	if ($supplied_schema) {
		
		# If the subject exixts...
		my $subjects = $sr->get_subjects();
		if (grep(/^$subject$/, @$subjects) ) {
			
			# ...check if it already exists in registry
			my $schema_info = $sr->check_schema(
				SUBJECT => $topic,
				TYPE => $type,
				SCHEMA => $supplied_schema 
			);
			if ( defined $schema_info ) {
				
				$schema_id   = $schema_info->{id};
				$avro_schema = $schema_info->{schema};

			# ...if it does not already exist in the registry....
			} else {
			
				# ...test new schema compliancy against latest version 
				my $compliant = $sr->test_schema(
					SUBJECT => $topic,
					TYPE => $type,
					SCHEMA => $supplied_schema
				);
				$self->_set_error("$type schema not compliant with latest one from registry for topic '$topic'") &&
					return undef
						unless $compliant;
			
			}
			
		}
		
		# ...if a previous id for the schema is not available, try to add the one supplied to the registry....
		unless ($schema_id) {
					  
			# ...procede adding it to the registry
			$schema_id = $sr->add_schema(
				SUBJECT => $topic,
				TYPE => $type,
				SCHEMA => $supplied_schema
			);
			$self->_set_error('Error adding schema to registry: ' . encode_json($sr->get_error())) &&
				return undef
					unless $schema_id;
			
			# ...and bless new schema into an Avro schema object 
			$avro_schema = Avro::Schema->parse($supplied_schema);
			
		}
		
	} else {
		
		# retreive latest schema for the topic value
		my $schema_info = $sr->get_schema(
			SUBJECT => $topic,
			TYPE => $type
		);
		if ( defined $schema_info ) {
			
			$schema_id = $schema_info->{id};
			$avro_schema = $schema_info->{schema};
			
		} else {
			$self->_set_error("No schema in registry for subject " . $topic . '-' . 'value') &&
				return undef
					unless $schema_info;
		}
		 
	}
	
	return ($schema_id, $avro_schema);
}





##### Public methods

=head2 METHODS

The following methods are defined for the C<Net::Kafka::Producer::Avro> class:

=cut


=head3 C<schema_registry>()

Returns the L<Confluent::SchemaRegistry|Confluent::SchemaRegistry> instance supplied to the construcor.

=cut

sub schema_registry { $_[0]->{__SCHEMA_REGISTRY} }


=head3 C<get_error>()

Returns a string containing last error message.

=cut

sub get_error { $_[0]->_get_error() }


=head3 C<produce( %named_params )>

Sends Avro-formatted key/message pairs.

According to C<Net::Kafka::Producer>, returns a promise value if the message was successfully sent.

In order to handle Avro format, the C<Net::Kafka::Producer|Net::Kafka::Producer>'s C<produce()> method has been
extended with two more arguments, C<key_schema> and C<payload_schema>:

  $producer->produce(
  	topic             => $topic,             # scalar 
  	partition         => $partition,         # scalar
  	key_schema        => $key_schema,        # (optional) scalar representing a JSON string of the Avro schema to use for the key
  	key               => $key,               # (optional) scalar | hashref
  	payload_schema    => $payload_schema,    # (optional) scalar representing a JSON string of the Avro schema to use for the payload
  	payload           => $payload,           # scalar | hashref
  	timestamp         => $timestamp,         # (optional) scalar representing milliseconds since epoch
  	headers           => $headers,           # (optional) Net::Kafka::Headers object
  	# ...other params accepted by Net::Kafka::Producer's produce() method
  );    

Both C<$key_schema> and C<$payload_schema> parameters are optional and must provide a JSON strings
representing the Avro schemas to use for validating and serializing key and payload.

These schemas will be validated against the C<$schema_registry> supplied to the C<new> method and, if compliant, 
will be added to the registry under the C<$topic+'key'> or C<$topic+'value'> Schema Registry subjects.

If a schema isn't provided, the latest version from Schema Registry will be used accordingly to the  
(topic + key/value) subject. 

=cut

sub produce {
    my $self   = shift;
    my %params = @_;
	my $avro_schemas = {
		key => {
			id => undef,
			schema => undef
		},
		value => {
			id => undef,
			schema => undef
		}
	};
	my ($encoded_key, $encoded_payload);

	$self->_clear_error();
	
	$self->_set_error('Missing topic param')
		and return undef
			unless defined $params{topic};
	$self->_set_error('Missing partition param')
		and return undef
			unless defined $params{partition};
	$self->_set_error('Missing payload')
		and return undef
			unless defined $params{payload};
		
	# if key is provided, encode it in Avro format according to the suggested schema or to the retrieved schema
	if ($params{key}) {

		# Retrieve target Avro schema for the key
		($avro_schemas->{key}->{id}, $avro_schemas->{key}->{schema}) = $self->_get_avro_schema($params{topic}, 'key', $params{key_schema});

		if (defined $avro_schemas->{key}->{id} && defined $avro_schemas->{key}->{schema}) {
			# encode key
			try {
				$encoded_key = _encode($avro_schemas->{key}, $params{key});
			} catch {};
			$self->_set_error('Key not compliant with supplied schema')
				and return undef
					unless defined $encoded_key;
		} else {
			# do not encode key
			$encoded_key = $params{key};
		}
				
	} else {
		$self->_set_error('Key schema not acceptable while key in not provided')
			and return undef
				unless $params{key_schema};
	}


	# Retrieve target Avro schema for the key
	($avro_schemas->{value}->{id}, $avro_schemas->{value}->{schema}) = $self->_get_avro_schema($params{topic}, 'value', $params{payload_schema});
	# Return if value Avro schema was not found
	$self->_set_error('No value schema found')
		and return undef
			unless defined $avro_schemas->{value}->{id} && defined $avro_schemas->{value}->{schema};
			
	# Avro encoding of message
	try {
		$encoded_payload = _encode($avro_schemas->{value}, $params{payload});
	} catch {};
	$self->_set_error('Payload not compliant with supplied schema')
		and return undef
			unless defined $encoded_payload;

	# Overwrite key and payload with encoded values
	$params{key} = $encoded_key if $encoded_key;
	$params{payload} = $encoded_payload if $encoded_payload;

	# Remove params unknown by the parent class method
	delete $params{key_schema};
	delete $params{payload_schema};

	# Send message through Net::Kafka::Producer parent class
	return $self->SUPER::produce(%params);
	
}


=head1 AUTHOR

Alvaro Livraghi, E<lt>alvarol@cpan.orgE<gt>

=head1 CONTRIBUTE

L<https://github.com/alivraghi/Net-Kafka-Producer-Avro>

=head1 BUGS

Please use GitHub project link above to report problems or contact authors.

=head1 COPYRIGHT AND LICENSE

Copyright 2026 by Alvaro Livraghi

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
