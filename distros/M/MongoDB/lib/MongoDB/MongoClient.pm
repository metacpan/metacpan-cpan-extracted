#
#  Copyright 2009-2013 MongoDB, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

use strict;
use warnings;
package MongoDB::MongoClient;

# ABSTRACT: A connection to a MongoDB server or multi-server deployment

use version;
our $VERSION = 'v1.8.0';

use Moo;
use MongoDB;
use MongoDB::BSON;
use MongoDB::BSON::Binary;
use MongoDB::BSON::Regexp;
use MongoDB::Cursor;
use MongoDB::DBRef;
use MongoDB::Error;
use MongoDB::Op::_Command;
use MongoDB::Op::_FSyncUnlock;
use MongoDB::ReadPreference;
use MongoDB::WriteConcern;
use MongoDB::ReadConcern;
use MongoDB::_Topology;
use MongoDB::_Constants;
use MongoDB::_Credential;
use MongoDB::_URI;
use Digest::MD5;
use Tie::IxHash;
use Time::HiRes qw/usleep/;
use Carp 'carp', 'croak', 'confess';
use Safe::Isa;
use Scalar::Util qw/reftype weaken/;
use boolean;
use Encode;
use Try::Tiny;
use MongoDB::_Types qw(
    ArrayOfHashRef
    AuthMechanism
    BSONCodec
    HeartbeatFreq
    MaxStalenessNum
    NonNegNum
    ReadPrefMode
    ReadPreference
);
use Types::Standard qw(
    Bool
    HashRef
    InstanceOf
    Undef
    Int
    Num
    Str
    Maybe
);

use namespace::clean -except => 'meta';

#--------------------------------------------------------------------------#
# deprecated global variables
#--------------------------------------------------------------------------#

# These are used to configure a BSON codec options if none is provided.
$MongoDB::BSON::looks_like_number = 0;
$MongoDB::BSON::char = '$';

#--------------------------------------------------------------------------#
# public attributes
#
# Of these, only host, port and bson_codec are set without regard for
# connection string options.  The rest are built lazily in BUILD so that
# option precedence can be resolved.
#--------------------------------------------------------------------------#

#pod =attr host
#pod
#pod The C<host> attribute specifies either a single server to connect to (as
#pod C<hostname> or C<hostname:port>), or else a L<connection string URI|/CONNECTION
#pod STRING URI> with a seed list of one or more servers plus connection options.
#pod
#pod Defaults to the connection string URI C<mongodb://localhost:27017>.
#pod
#pod For IPv6 support, you must have a recent version of L<IO::Socket::IP>
#pod installed.  This module ships with the Perl core since v5.20.0 and is
#pod available on CPAN for older Perls.
#pod
#pod =cut

has host => (
    is      => 'ro',
    isa     => Str,
    default => 'mongodb://localhost:27017',
);

#pod =attr app_name
#pod
#pod This attribute specifies an application name that should be associated with
#pod this client.  The application name will be communicated to the server as
#pod part of the initial connection handshake, and will appear in
#pod connection-level and operation-level diagnostics on the server generated on
#pod behalf of this client.  This may be set in a connection string with the
#pod C<appName> option.
#pod
#pod The default is the empty string, which indicates a lack of an application
#pod name.
#pod
#pod The application name must not exceed 128 bytes.
#pod
#pod =cut

has app_name => (
    is  => 'lazy',
    isa => Str,
    builder => '_build_app_name',
);

sub _build_app_name {
    my ($self) = @_;
    my $app_name = $self->__uri_or_else(
        u => 'appname',
        e => 'app_name',
        d => '',
    );
    unless ( length($app_name) <= 128 ) {
        MongoDB::UsageError->throw("app name must be at most 128 bytes");
    }
    return $app_name;
}

#pod =attr auth_mechanism
#pod
#pod This attribute determines how the client authenticates with the server.
#pod Valid values are:
#pod
#pod =for :list
#pod * NONE
#pod * DEFAULT
#pod * MONGODB-CR
#pod * MONGODB-X509
#pod * GSSAPI
#pod * PLAIN
#pod * SCRAM-SHA-1
#pod
#pod If not specified, then if no username is provided, it defaults to NONE.
#pod If a username is provided, it is set to DEFAULT, which chooses SCRAM-SHA-1 if
#pod available or MONGODB-CR otherwise.
#pod
#pod This may be set in a connection string with the C<authMechanism> option.
#pod
#pod =cut

has auth_mechanism => (
    is      => 'lazy',
    isa     => AuthMechanism,
    builder => '_build_auth_mechanism',
);

sub _build_auth_mechanism {
    my ($self) = @_;

    my $default =
        $self->sasl     ? $self->sasl_mechanism
      : $self->username ? 'DEFAULT'
      :                   'NONE';

    return $self->__uri_or_else(
        u => 'authmechanism',
        e => 'auth_mechanism',
        d => $default,
    );
}

#pod =attr auth_mechanism_properties
#pod
#pod This is an optional hash reference of authentication mechanism specific properties.
#pod See L</AUTHENTICATION> for details.
#pod
#pod This may be set in a connection string with the C<authMechanismProperties>
#pod option.  If given, the value must be key/value pairs joined with a ":".
#pod Multiple pairs must be separated by a comma.  If ": or "," appear in a key or
#pod value, they must be URL encoded.
#pod
#pod =cut

has auth_mechanism_properties => (
    is      => 'lazy',
    isa     => HashRef,
    builder => '_build_auth_mechanism_properties',
);

sub _build_auth_mechanism_properties {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'authmechanismproperties',
        e => 'auth_mechanism_properties',
        d => {},
    );
}

#pod =attr bson_codec
#pod
#pod An object that provides the C<encode_one> and C<decode_one> methods, such as
#pod from L<MongoDB::BSON>.  It may be initialized with a hash reference that will
#pod be coerced into a new L<MongoDB::BSON> object.
#pod
#pod If not provided, one will be generated as follows:
#pod
#pod     MongoDB::BSON->new(
#pod         dbref_callback => sub { return MongoDB::DBRef->new(shift) },
#pod         dt_type        => $client->dt_type,
#pod         prefer_numeric => $MongoDB::BSON::looks_like_number || 0,
#pod         (
#pod             $MongoDB::BSON::char ne '$' ?
#pod                 ( op_char => $MongoDB::BSON::char ) : ()
#pod         ),
#pod     );
#pod
#pod This will inflate all DBRefs to L<MongoDB::DBRef> objects, set C<dt_type>
#pod based on the client's C<db_type> accessor, and set the C<prefer_numeric>
#pod and C<op_char> attributes based on the deprecated legacy global variables.
#pod
#pod =cut

has bson_codec => (
    is      => 'lazy',
    isa     => BSONCodec,
    coerce  => BSONCodec->coercion,
    writer  => '_set_bson_codec',
    builder => '_build_bson_codec',
);

# skipping op_char unless $MongoDB::BSON::char is not '$' is an optimization
sub _build_bson_codec {
    my ($self) = @_;
    return MongoDB::BSON->new(
        dbref_callback => sub { return MongoDB::DBRef->new(shift) },
        dt_type        => $self->dt_type,
        prefer_numeric => $MongoDB::BSON::looks_like_number || 0,
        ( $MongoDB::BSON::char ne '$' ? ( op_char => $MongoDB::BSON::char ) : () ),
    );
}

#pod =attr connect_timeout_ms
#pod
#pod This attribute specifies the amount of time in milliseconds to wait for a
#pod new connection to a server.
#pod
#pod The default is 10,000 ms.
#pod
#pod If set to a negative value, connection operations will block indefinitely
#pod until the server replies or until the operating system TCP/IP stack gives
#pod up (e.g. if the name can't resolve or there is no process listening on the
#pod target host/port).
#pod
#pod A zero value polls the socket during connection and is thus likely to fail
#pod except when talking to a local process (and perhaps even then).
#pod
#pod This may be set in a connection string with the C<connectTimeoutMS> option.
#pod
#pod =cut

has connect_timeout_ms => (
    is      => 'lazy',
    isa     => Num,
    builder => '_build_connect_timeout_ms',
);

sub _build_connect_timeout_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'connecttimeoutms',
        e => 'connect_timeout_ms',
        d => $self->timeout, # deprecated legacy attribute as default
    );
}

#pod =attr db_name
#pod
#pod Optional.  If an L</auth_mechanism> requires a database for authentication,
#pod this attribute will be used.  Otherwise, it will be ignored. Defaults to
#pod "admin".
#pod
#pod This may be provided in the L<connection string URI|/CONNECTION STRING URI> as
#pod a path between the authority and option parameter sections.  For example, to
#pod authenticate against the "admin" database (showing a configuration option only
#pod for illustration):
#pod
#pod     mongodb://localhost/admin?readPreference=primary
#pod
#pod =cut

has db_name => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_db_name',
);

sub _build_db_name {
    my ($self) = @_;
    return __string( $self->_uri->db_name, $self->_deferred->{db_name} );
}

#pod =attr heartbeat_frequency_ms
#pod
#pod The time in milliseconds (non-negative) between scans of all servers to
#pod check if they are up and update their latency.  Defaults to 60,000 ms.
#pod
#pod This may be set in a connection string with the C<heartbeatFrequencyMS> option.
#pod
#pod =cut

has heartbeat_frequency_ms => (
    is      => 'lazy',
    isa     => HeartbeatFreq,
    builder => '_build_heartbeat_frequency_ms',
);

sub _build_heartbeat_frequency_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'heartbeatfrequencyms',
        e => 'heartbeat_frequency_ms',
        d => 60000,
    );
}

#pod =attr j
#pod
#pod If true, the client will block until write operations have been committed to the
#pod server's journal. Prior to MongoDB 2.6, this option was ignored if the server was
#pod running without journaling. Starting with MongoDB 2.6, write operations will fail
#pod if this option is used when the server is running without journaling.
#pod
#pod This may be set in a connection string with the C<journal> option as the
#pod strings 'true' or 'false'.
#pod
#pod =cut

has j => (
    is      => 'lazy',
    isa     => Bool,
    builder => '_build_j',
);

sub _build_j {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'journal',
        e => 'j',
        d => 0,
    );
}

#pod =attr local_threshold_ms
#pod
#pod The width of the 'latency window': when choosing between multiple suitable
#pod servers for an operation, the acceptable delta in milliseconds
#pod (non-negative) between shortest and longest average round-trip times.
#pod Servers within the latency window are selected randomly.
#pod
#pod Set this to "0" to always select the server with the shortest average round
#pod trip time.  Set this to a very high value to always randomly choose any known
#pod server.
#pod
#pod Defaults to 15 ms.
#pod
#pod See L</SERVER SELECTION> for more details.
#pod
#pod This may be set in a connection string with the C<localThresholdMS> option.
#pod
#pod =cut

has local_threshold_ms => (
    is      => 'lazy',
    isa     => NonNegNum,
    builder => '_build_local_threshold_ms',
);

sub _build_local_threshold_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'localthresholdms',
        e => 'local_threshold_ms',
        d => 15,
    );
}

#pod =attr max_staleness_seconds
#pod
#pod The C<max_staleness_seconds> parameter represents the maximum replication lag in
#pod seconds (wall clock time) that a secondary can suffer and still be
#pod eligible for reads. The default is -1, which disables staleness checks.
#pod Otherwise, it must be a positive integer.
#pod
#pod B<Note>: this will only be used for server versions 3.4 or greater, as that
#pod was when support for staleness tracking was added.
#pod
#pod If the read preference mode is 'primary', then C<max_staleness_seconds> must not
#pod be supplied.
#pod
#pod The C<max_staleness_seconds> must be at least the C<heartbeat_frequency_ms>
#pod plus 10 seconds (which is how often the server makes idle writes to the
#pod oplog).
#pod
#pod This may be set in a connection string with the C<maxStalenessSeconds> option.
#pod
#pod =cut

has max_staleness_seconds => (
    is      => 'lazy',
    isa     => MaxStalenessNum,
    builder => '_build_max_staleness_seconds',
);

sub _build_max_staleness_seconds {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'maxstalenessseconds',
        e => 'max_staleness_seconds',
        d => -1,
    );
}

#pod =attr max_time_ms
#pod
#pod Specifies the maximum amount of time in (non-negative) milliseconds that the
#pod server should use for working on a database command.  Defaults to 0, which disables
#pod this feature.  Make sure this value is shorter than C<socket_timeout_ms>.
#pod
#pod B<Note>: this will only be used for server versions 2.6 or greater, as that
#pod was when the C<$maxTimeMS> meta-operator was introduced.
#pod
#pod You are B<strongly> encouraged to set this variable if you know your
#pod environment has MongoDB 2.6 or later, as getting a definitive error response
#pod from the server is vastly preferred over a getting a network socket timeout.
#pod
#pod This may be set in a connection string with the C<maxTimeMS> option.
#pod
#pod =cut

has max_time_ms => (
    is      => 'lazy',
    isa     => NonNegNum,
    builder => '_build_max_time_ms',
);

sub _build_max_time_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'maxtimems',
        e => 'max_time_ms',
        d => 0,
    );
}

#pod =attr password
#pod
#pod If an L</auth_mechanism> requires a password, this attribute will be
#pod used.  Otherwise, it will be ignored.
#pod
#pod This may be provided in the L<connection string URI|/CONNECTION STRING URI> as
#pod a C<username:password> pair in the leading portion of the authority section
#pod before a C<@> character.  For example, to authenticate as user "mulder" with
#pod password "trustno1":
#pod
#pod     mongodb://mulder:trustno1@localhost
#pod
#pod If the username or password have a ":" or "@" in it, they must be URL encoded.
#pod An empty password still requires a ":" character.
#pod
#pod =cut

has password => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_password',
);

sub _build_password {
    my ($self) = @_;
    return
        defined( $self->_uri->password )        ? $self->_uri->password
      : defined( $self->_deferred->{password} ) ? $self->_deferred->{password}
      :                                           '';
}

#pod =attr port
#pod
#pod If a network port is not specified as part of the C<host> attribute, this
#pod attribute provides the port to use.  It defaults to 27107.
#pod
#pod =cut

has port => (
    is      => 'ro',
    isa     => Int,
    default => 27017,
);

#pod =attr read_pref_mode
#pod
#pod The read preference mode determines which server types are candidates
#pod for a read operation.  Valid values are:
#pod
#pod =for :list
#pod * primary
#pod * primaryPreferred
#pod * secondary
#pod * secondaryPreferred
#pod * nearest
#pod
#pod For core documentation on read preference see
#pod L<http://docs.mongodb.org/manual/core/read-preference/>.
#pod
#pod This may be set in a connection string with the C<readPreference> option.
#pod
#pod =cut

has read_pref_mode => (
    is      => 'lazy',
    isa     => ReadPrefMode,
    coerce  => ReadPrefMode->coercion,
    builder => '_build_read_pref_mode',
);

sub _build_read_pref_mode {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'readpreference',
        e => 'read_pref_mode',
        d => 'primary',
    );
}

#pod =attr read_pref_tag_sets
#pod
#pod The C<read_pref_tag_sets> parameter is an ordered list of tag sets used to
#pod restrict the eligibility of servers, such as for data center awareness.  It
#pod must be an array reference of hash references.
#pod
#pod The application of C<read_pref_tag_sets> varies depending on the
#pod C<read_pref_mode> parameter.  If the C<read_pref_mode> is 'primary', then
#pod C<read_pref_tag_sets> must not be supplied.
#pod
#pod For core documentation on read preference see
#pod L<http://docs.mongodb.org/manual/core/read-preference/>.
#pod
#pod This may be set in a connection string with the C<readPreferenceTags> option.
#pod If given, the value must be key/value pairs joined with a ":".  Multiple pairs
#pod must be separated by a comma.  If ": or "," appear in a key or value, they must
#pod be URL encoded.  The C<readPreferenceTags> option may appear more than once, in
#pod which case each document will be added to the tag set list.
#pod
#pod =cut

has read_pref_tag_sets => (
    is      => 'lazy',
    isa     => ArrayOfHashRef,
    coerce  => ArrayOfHashRef->coercion,
    builder => '_build_read_pref_tag_sets',
);

sub _build_read_pref_tag_sets {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'readpreferencetags',
        e => 'read_pref_tag_sets',
        d => [ {} ],
    );
}

#pod =attr replica_set_name
#pod
#pod Specifies the replica set name to connect to.  If this string is non-empty,
#pod then the topology is treated as a replica set and all server replica set
#pod names must match this or they will be removed from the topology.
#pod
#pod This may be set in a connection string with the C<replicaSet> option.
#pod
#pod =cut

has replica_set_name => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_replica_set_name',
);

sub _build_replica_set_name {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'replicaset',
        e => 'replica_set_name',
        d => '',
    );
}

#pod =attr server_selection_timeout_ms
#pod
#pod This attribute specifies the amount of time in milliseconds to wait for a
#pod suitable server to be available for a read or write operation.  If no
#pod server is available within this time period, an exception will be thrown.
#pod
#pod The default is 30,000 ms.
#pod
#pod See L</SERVER SELECTION> for more details.
#pod
#pod This may be set in a connection string with the C<serverSelectionTimeoutMS>
#pod option.
#pod
#pod =cut

has server_selection_timeout_ms => (
    is      => 'lazy',
    isa     => Num,
    builder => '_build_server_selection_timeout_ms',
);

sub _build_server_selection_timeout_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'serverselectiontimeoutms',
        e => 'server_selection_timeout_ms',
        d => 30000,
    );
}

#pod =attr server_selection_try_once
#pod
#pod This attribute controls whether the client will make only a single attempt
#pod to find a suitable server for a read or write operation.  The default is true.
#pod
#pod When true, the client will B<not> use the C<server_selection_timeout_ms>.
#pod Instead, if the topology information is stale and needs to be checked or
#pod if no suitable server is available, the client will make a single
#pod scan of all known servers to try to find a suitable one.
#pod
#pod When false, the client will continually scan known servers until a suitable
#pod server is found or the C<serverSelectionTimeoutMS> is reached.
#pod
#pod See L</SERVER SELECTION> for more details.
#pod
#pod This may be set in a connection string with the C<serverSelectionTryOnce>
#pod option.
#pod
#pod =cut

has server_selection_try_once => (
    is      => 'lazy',
    isa     => Bool,
    builder => '_build_server_selection_try_once',
);

sub _build_server_selection_try_once {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'serverselectiontryonce',
        e => 'server_selection_try_once',
        d => 1,
    );
}

#pod =attr socket_check_interval_ms
#pod
#pod If a socket to a server has not been used in this many milliseconds, an
#pod C<ismaster> command will be issued to check the status of the server before
#pod issuing any reads or writes. Must be non-negative.
#pod
#pod The default is 5,000 ms.
#pod
#pod This may be set in a connection string with the C<socketCheckIntervalMS>
#pod option.
#pod
#pod =cut

has socket_check_interval_ms => (
    is      => 'lazy',
    isa     => NonNegNum,
    builder => '_build_socket_check_interval_ms',
);

sub _build_socket_check_interval_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'socketcheckintervalms',
        e => 'socket_check_interval_ms',
        d => 5000,
    );
}

#pod =attr socket_timeout_ms
#pod
#pod This attribute specifies the amount of time in milliseconds to wait for a
#pod reply from the server before issuing a network exception.
#pod
#pod The default is 30,000 ms.
#pod
#pod If set to a negative value, socket operations will block indefinitely
#pod until the server replies or until the operating system TCP/IP stack
#pod gives up.
#pod
#pod A zero value polls the socket for available data and is thus likely to fail
#pod except when talking to a local process (and perhaps even then).
#pod
#pod This may be set in a connection string with the C<socketTimeoutMS> option.
#pod
#pod =cut

has socket_timeout_ms => (
    is      => 'lazy',
    isa     => Num,
    builder => '_build_socket_timeout_ms',
);

sub _build_socket_timeout_ms {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'sockettimeoutms',
        e => 'socket_timeout_ms',
        d => $self->query_timeout, # deprecated legacy timeout as default
    );
}

#pod =attr ssl
#pod
#pod     ssl => 1
#pod     ssl => \%ssl_options
#pod
#pod This tells the driver that you are connecting to an SSL mongodb instance.
#pod
#pod You must have L<IO::Socket::SSL> 1.42+ and L<Net::SSLeay> 1.49+ installed for
#pod SSL support.
#pod
#pod The C<ssl> attribute takes either a boolean value or a hash reference of
#pod options to pass to IO::Socket::SSL.  For example, to set a CA file to validate
#pod the server certificate and set a client certificate for the server to validate,
#pod you could set the attribute like this:
#pod
#pod     ssl => {
#pod         SSL_ca_file   => "/path/to/ca.pem",
#pod         SSL_cert_file => "/path/to/client.pem",
#pod     }
#pod
#pod If C<SSL_ca_file> is not provided, server certificates are verified against a
#pod default list of CAs, either L<Mozilla::CA> or an operating-system-specific
#pod default CA file.  To disable verification, you can use
#pod C<< SSL_verify_mode => 0x00 >>.
#pod
#pod B<You are strongly encouraged to use your own CA file for increased security>.
#pod
#pod Server hostnames are also validated against the CN name in the server
#pod certificate using C<< SSL_verifycn_scheme => 'http' >>.  You can use the
#pod scheme 'none' to disable this check.
#pod
#pod B<Disabling certificate or hostname verification is a security risk and is not
#pod recommended>.
#pod
#pod This may be set to the string 'true' or 'false' in a connection string with the
#pod C<ssl> option, which will enable ssl with default configuration.  (A future
#pod version of the driver may support customizing ssl via the connection string.)
#pod
#pod =cut

has ssl => (
    is      => 'lazy',
    isa     => Bool|HashRef,
    builder => '_build_ssl',
);

sub _build_ssl {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'ssl',
        e => 'ssl',
        d => 0,
    );
}

#pod =attr username
#pod
#pod Optional username for this client connection.  If this field is set, the client
#pod will attempt to authenticate when connecting to servers.  Depending on the
#pod L</auth_mechanism>, the L</password> field or other attributes will need to be
#pod set for authentication to succeed.
#pod
#pod This may be provided in the L<connection string URI|/CONNECTION STRING URI> as
#pod a C<username:password> pair in the leading portion of the authority section
#pod before a C<@> character.  For example, to authenticate as user "mulder" with
#pod password "trustno1":
#pod
#pod     mongodb://mulder:trustno1@localhost
#pod
#pod If the username or password have a ":" or "@" in it, they must be URL encoded.
#pod An empty password still requires a ":" character.
#pod
#pod =cut

has username => (
    is      => 'lazy',
    isa     => Str,
    builder => '_build_username',
);

sub _build_username {
    my ($self) = @_;

    return
        defined( $self->_uri->username )        ? $self->_uri->username
      : defined( $self->_deferred->{username} ) ? $self->_deferred->{username}
      :                                           '';
}

#pod =attr w
#pod
#pod The client I<write concern>.
#pod
#pod =over 4
#pod
#pod =item * C<0> Unacknowledged. MongoClient will B<NOT> wait for an acknowledgment that
#pod the server has received and processed the request. Older documentation may refer
#pod to this as "fire-and-forget" mode.  This option is not recommended.
#pod
#pod =item * C<1> Acknowledged. This is the default. MongoClient will wait until the
#pod primary MongoDB acknowledges the write.
#pod
#pod =item * C<2> Replica acknowledged. MongoClient will wait until at least two
#pod replicas (primary and one secondary) acknowledge the write. You can set a higher
#pod number for more replicas.
#pod
#pod =item * C<all> All replicas acknowledged.
#pod
#pod =item * C<majority> A majority of replicas acknowledged.
#pod
#pod =back
#pod
#pod In MongoDB v2.0+, you can "tag" replica members. With "tagging" you can
#pod specify a custom write concern For more information see L<Data Center
#pod Awareness|http://docs.mongodb.org/manual/data-center-awareness/>
#pod
#pod This may be set in a connection string with the C<w> option.
#pod
#pod =cut

has w => (
    is      => 'lazy',
    isa     => Int|Str|Undef,
    builder => '_build_w',
);

sub _build_w {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'w',
        e => 'w',
        d => undef,
    );
}

#pod =attr wtimeout
#pod
#pod The number of milliseconds an operation should wait for C<w> secondaries to
#pod replicate it.
#pod
#pod Defaults to 1000 (1 second).
#pod
#pod See C<w> above for more information.
#pod
#pod This may be set in a connection string with the C<wTimeoutMS> option.
#pod
#pod =cut

has wtimeout => (
    is      => 'lazy',
    isa     => Int,
    builder => '_build_wtimeout',
);

sub _build_wtimeout {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'wtimeoutms',
        e => 'wtimeout',
        d => 1000,
    );
}

#pod =attr read_concern_level
#pod
#pod The read concern level determines the consistency level required
#pod of data being read.
#pod
#pod The default level is C<undef>, which means the server will use its configured
#pod default.
#pod
#pod If the level is set to "local", reads will return the latest data a server has
#pod locally.
#pod
#pod Additional levels are storage engine specific.  See L<Read
#pod Concern|http://docs.mongodb.org/manual/search/?query=readConcern> in the MongoDB
#pod documentation for more details.
#pod
#pod This may be set in a connection string with the the C<readConcernLevel> option.
#pod
#pod =cut

has read_concern_level => (
    is      => 'lazy',
    isa     => Maybe [Str],
    builder => '_build_read_concern_level',
);

sub _build_read_concern_level {
    my ($self) = @_;
    return $self->__uri_or_else(
        u => 'readconcernlevel',
        e => 'read_concern_level',
        d => undef,
    );
}

#--------------------------------------------------------------------------#
# deprecated public attributes
#--------------------------------------------------------------------------#

#pod =attr dt_type (DEPRECATED AND READ-ONLY)
#pod
#pod Sets the type of object which is returned for DateTime fields. The default
#pod is L<DateTime>. Other acceptable values are L<DateTime::Tiny>,
#pod L<Time::Moment> and C<undef>. The latter will give you the raw epoch value
#pod (possibly as a floating point value) rather than an object.
#pod
#pod This will be used to construct L</bson_codec> object if one is not provided.
#pod
#pod As this has a one-time effect, it is now read-only to help you detect
#pod code that was trying to change after the fact during program execution.
#pod
#pod For temporary or localized changes, look into overriding the C<bson_codec>
#pod object for a database or collection object.
#pod
#pod =cut

has dt_type => (
    is      => 'ro',
    default => 'DateTime'
);

#pod =attr query_timeout (DEPRECATED AND READ-ONLY)
#pod
#pod     # set query timeout to 1 second
#pod     my $client = MongoDB::MongoClient->new(query_timeout => 1000);
#pod
#pod This option has been renamed as L</socket_timeout_ms>.  If this option is set
#pod and that one is not, this will be used.
#pod
#pod This value is in milliseconds and defaults to 30000.
#pod
#pod =cut

has query_timeout => (
    is      => 'ro',
    isa     => Int,
    default => 30000,
);

#pod =attr sasl (DEPRECATED)
#pod
#pod If true, the driver will set the authentication mechanism based on the
#pod C<sasl_mechanism> property.
#pod
#pod =cut

has sasl => (
    is      => 'ro',
    isa     => Bool,
    default => 0
);

#pod =attr sasl_mechanism (DEPRECATED)
#pod
#pod This specifies the SASL mechanism to use for authentication with a MongoDB server.
#pod It has the same valid values as L</auth_mechanism>.  The default is GSSAPI.
#pod
#pod =cut

has sasl_mechanism => (
    is      => 'ro',
    isa     => AuthMechanism,
    default => 'GSSAPI',
);

#pod =attr timeout (DEPRECATED AND READ-ONLY)
#pod
#pod This option has been renamed as L</connect_timeout_ms>.  If this option is set
#pod and that one is not, this will be used.
#pod
#pod Connection timeout is in milliseconds. Defaults to C<10000>.
#pod
#pod =cut

has timeout => (
    is        => 'ro',
    isa       => Int,
    default   => 10000,
);

#--------------------------------------------------------------------------#
# computed attributes - these are private and can't be set in the
# constructor, but have a public accessor
#--------------------------------------------------------------------------#

#pod =method read_preference
#pod
#pod Returns a L<MongoDB::ReadPreference> object constructed from
#pod L</read_pref_mode> and L</read_pref_tag_sets>
#pod
#pod B<The use of C<read_preference> as a mutator has been removed.>  Read
#pod preference is read-only.  If you need a different read preference for
#pod a database or collection, you can specify that in C<get_database> or
#pod C<get_collection>.
#pod
#pod =cut

has _read_preference => (
    is       => 'lazy',
    isa      => ReadPreference,
    reader   => 'read_preference',
    init_arg => undef,
    builder  => '_build__read_preference',
);

sub _build__read_preference {
    my ($self) = @_;
    return MongoDB::ReadPreference->new(
        ( defined $self->read_pref_mode     ? ( mode     => $self->read_pref_mode )     : () ),
        ( defined $self->read_pref_tag_sets ? ( tag_sets => $self->read_pref_tag_sets ) : () ),
        ( defined $self->max_staleness_seconds ? ( max_staleness_seconds => $self->max_staleness_seconds ) : () ),
    );
}

#pod =method write_concern
#pod
#pod Returns a L<MongoDB::WriteConcern> object constructed from L</w>, L</write_concern>
#pod and L</j>.
#pod
#pod =cut

has _write_concern => (
    is     => 'lazy',
    isa    => InstanceOf['MongoDB::WriteConcern'],
    reader   => 'write_concern',
    init_arg => undef,
    builder  => '_build__write_concern',
);

sub _build__write_concern {
    my ($self) = @_;
    return MongoDB::WriteConcern->new(
        ( $self->w        ? ( w        => $self->w )        : () ),
        ( $self->wtimeout ? ( wtimeout => $self->wtimeout ) : () ),
        ( $self->j        ? ( j        => $self->j )        : () ),
    );
}

#pod =method read_concern
#pod
#pod Returns a L<MongoDB::ReadConcern> object constructed from
#pod L</read_concern_level>.
#pod
#pod =cut

has _read_concern => (
    is     => 'lazy',
    isa    => InstanceOf['MongoDB::ReadConcern'],
    reader   => 'read_concern',
    init_arg => undef,
    builder  => '_build__read_concern',
);

sub _build__read_concern {
    my ($self) = @_;

    return MongoDB::ReadConcern->new(
        ( $self->read_concern_level ?
            ( level => $self->read_concern_level ) : () ),
    );
}

#--------------------------------------------------------------------------#
# private attributes
#--------------------------------------------------------------------------#

# collects constructor options and defer them so precedence can be resolved
# against the _uri options; unlike other private args, this needs a valid
# init argument
has _deferred => (
    is       => 'ro',
    isa      => HashRef,
    init_arg => '_deferred',
    default  => sub { {} },
);

#pod =method topology_type
#pod
#pod Returns an enumerated topology type.  If the L</replica_set_name> is
#pod set, the value will be either 'ReplicaSetWithPrimary' or 'ReplicaSetNoPrimary'
#pod (if the primary is down or not yet discovered).  Without L</replica_set_name>,
#pod the type will be 'Single' if there is only one server in the list of hosts, and
#pod 'Sharded' if there are more than one.
#pod
#pod N.B. A single mongos will have a topology type of 'Single', as that mongos will
#pod be used for all reads and writes, just like a standalone mongod.  The 'Sharded'
#pod type indicates a sharded cluster with multiple mongos servers, and reads/writes
#pod will be distributed acc
#pod
#pod =cut

has _topology => (
    is       => 'lazy',
    isa      => InstanceOf ['MongoDB::_Topology'],
    init_arg => undef,
    builder  => '_build__topology',
    handles  => { topology_type => 'type' },
    clearer  => '_clear__topology',
);

sub _build__topology {
    my ($self) = @_;

    my $type =
        length( $self->replica_set_name ) ? 'ReplicaSetNoPrimary'
      : @{ $self->_uri->hostids } > 1   ? 'Sharded'
      :                                     'Single';

    MongoDB::_Topology->new(
        uri                         => $self->_uri,
        bson_codec                  => $self->bson_codec,
        type                        => $type,
        app_name                    => $self->app_name,
        replica_set_name            => $self->replica_set_name,
        server_selection_timeout_sec => $self->server_selection_timeout_ms / 1000,
        server_selection_try_once    => $self->server_selection_try_once,
        local_threshold_sec          => $self->local_threshold_ms / 1000,
        heartbeat_frequency_sec      => $self->heartbeat_frequency_ms / 1000,
        max_wire_version            => MAX_WIRE_VERSION,
        min_wire_version            => MIN_WIRE_VERSION,
        credential                  => $self->_credential,
        link_options                => {
            connect_timeout => $self->connect_timeout_ms >= 0 ? $self->connect_timeout_ms / 1000 : undef,
            socket_timeout  => $self->socket_timeout_ms  >= 0 ? $self->socket_timeout_ms  / 1000 : undef,
            with_ssl   => !!$self->ssl,
            ( ref( $self->ssl ) eq 'HASH' ? ( SSL_options => $self->ssl ) : () ),
        },
    );
}

has _credential => (
    is       => 'lazy',
    isa      => InstanceOf ['MongoDB::_Credential'],
    init_arg => undef,
    builder  => '_build__credential',
);

sub _build__credential {
    my ($self) = @_;
    my $mechanism = $self->auth_mechanism;
    my $cred = MongoDB::_Credential->new(
        mechanism            => $mechanism,
        mechanism_properties => $self->auth_mechanism_properties,
        ( $self->username ? ( username => $self->username ) : () ),
        ( $self->password ? ( password => $self->password ) : () ),
        ( $self->db_name  ? ( source   => $self->db_name )  : () ),
    );
    return $cred;
}

has _uri => (
    is       => 'lazy',
    isa      => InstanceOf ['MongoDB::_URI'],
    init_arg => undef,
    builder  => '_build__uri',
);

sub _build__uri {
    my ($self) = @_;
    if ( $self->host =~ m{^\w+://} ) {
        return MongoDB::_URI->new( uri => $self->host );
    }
    else {
        my $uri = $self->host =~ /:\d+$/
                ? $self->host
                : sprintf("%s:%s", map { $self->$_ } qw/host port/ );
        return MongoDB::_URI->new( uri => ("mongodb://$uri") );
    }
}

#--------------------------------------------------------------------------#
# Constructor customization
#--------------------------------------------------------------------------#

# these attributes are lazy, built from either _uri->options or from
# _config_options captured in BUILDARGS
my @deferred_options = qw(
  app_name
  auth_mechanism
  auth_mechanism_properties
  connect_timeout_ms
  db_name
  heartbeat_frequency_ms
  j
  local_threshold_ms
  max_staleness_seconds
  max_time_ms
  read_pref_mode
  read_pref_tag_sets
  replica_set_name
  server_selection_timeout_ms
  server_selection_try_once
  socket_check_interval_ms
  socket_timeout_ms
  ssl
  username
  password
  w
  wtimeout
  read_concern_level
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    my $hr = $class->$orig(@_);
    my $deferred = {};
    for my $k ( @deferred_options ) {
        $deferred->{$k} = delete $hr->{$k}
          if exists $hr->{$k};
    }
    $hr->{_deferred} = $deferred;
    return $hr;
};

sub BUILD {
    my ($self, $opts) = @_;

    my $uri = $self->_uri;

    my @addresses = @{ $uri->hostids };

    # resolve and validate all deferred attributes
    $self->$_ for @deferred_options;

    # resolve and validate read pref and write concern
    $self->read_preference;
    $self->write_concern;

    # Add error handler to codec if user didn't provide their own
    unless ( $self->bson_codec->error_callback ) {
        $self->_set_bson_codec(
            $self->bson_codec->clone(
                error_callback => sub {
                    my ($msg, $ref, $op) = @_;
                    if ( $op =~ /^encode/ ) {
                        MongoDB::DocumentError->throw(
                            message => $msg,
                            document => $ref
                        );
                    }
                    else {
                        MongoDB::DecodingError->throw($msg);
                    }
                },
            )
        );
    }

    # Instantiate topology
    $self->_topology;

    return;
}

#--------------------------------------------------------------------------#
# helper functions
#--------------------------------------------------------------------------#

sub __uri_or_else {
    my ( $self, %spec ) = @_;
    my $uri_options = $self->_uri->options;
    my $deferred    = $self->_deferred;
    my ( $u, $e, $default ) = @spec{qw/u e d/};
    return
        exists $uri_options->{$u} ? $uri_options->{$u}
      : exists $deferred->{$e}    ? $deferred->{$e}
      :                             $default;
}

sub __string {
    local $_;
    my ($first) = grep { defined && length } @_;
    return $first || '';
}

#--------------------------------------------------------------------------#
# public methods - network communication
#--------------------------------------------------------------------------#

#pod =method connect
#pod
#pod     $client->connect;
#pod
#pod Calling this method is unnecessary, as connections are established
#pod automatically as needed.  It is kept for backwards compatibility.  Calling it
#pod will check all servers in the deployment which ensures a connection to any
#pod that are available.
#pod
#pod See L</reconnect> for a method that is useful when using forks or threads.
#pod
#pod =cut

sub connect {
    my ($self) = @_;
    $self->_topology->scan_all_servers;
    return 1;
}

#pod =method disconnect
#pod
#pod     $client->disconnect;
#pod
#pod Drops all connections to servers.
#pod
#pod =cut

sub disconnect {
    my ($self) = @_;
    $self->_topology->close_all_links;
    return 1;
}

#pod =method reconnect
#pod
#pod     $client->reconnect;
#pod
#pod This method closes all connections to the server, as if L</disconnect> were
#pod called, and then immediately reconnects.  Use this after forking or spawning
#pod off a new thread.
#pod
#pod =cut

sub reconnect {
    my ($self) = @_;
    $self->_topology->close_all_links;
    $self->_topology->scan_all_servers;
    return 1;
}

#pod =method topology_status
#pod
#pod     $client->topology_status;
#pod     $client->topology_status( refresh => 1 );
#pod
#pod Returns a hash reference with server topology information like this:
#pod
#pod     {
#pod         'topology_type' => 'ReplicaSetWithPrimary'
#pod         'replica_set_name' => 'foo',
#pod         'last_scan_time'   => '1433766895.183241',
#pod         'servers'          => [
#pod             {
#pod                 'address'     => 'localhost:50003',
#pod                 'ewma_rtt_ms' => '0.223462326',
#pod                 'type'        => 'RSSecondary'
#pod             },
#pod             {
#pod                 'address'     => 'localhost:50437',
#pod                 'ewma_rtt_ms' => '0.268435456',
#pod                 'type'        => 'RSArbiter'
#pod             },
#pod             {
#pod                 'address'     => 'localhost:50829',
#pod                 'ewma_rtt_ms' => '0.737782272',
#pod                 'type'        => 'RSPrimary'
#pod             }
#pod         },
#pod     }
#pod
#pod If the 'refresh' argument is true, then the topology will be scanned
#pod to update server data before returning the hash reference.
#pod
#pod =cut

sub topology_status {
    my ($self, %opts) = @_;
    $self->_topology->scan_all_servers if $opts{refresh};
    return $self->_topology->status_struct;
}

#--------------------------------------------------------------------------#
# semi-private methods; these are public but undocumented and their
# semantics might change in future releases
#--------------------------------------------------------------------------#

# Undocumented in old MongoDB::MongoClient; semantics don't translate, but
# best approximation is checking if we can send a command to a server
sub connected {
    my ($self) = @_;
    return eval { $self->send_admin_command([ismaster => 1]); 1 };
}

sub send_admin_command {
    my ( $self, $command, $read_pref ) = @_;

    $read_pref = MongoDB::ReadPreference->new(
        ref($read_pref) ? $read_pref : ( mode => $read_pref ) )
      if $read_pref && ref($read_pref) ne 'MongoDB::ReadPreference';

    my $op = MongoDB::Op::_Command->_new(
        db_name     => 'admin',
        query       => $command,
        query_flags => {},
        bson_codec  => $self->bson_codec,
        read_preference => $read_pref,
    );

    return $self->send_read_op( $op );
}

# op dispatcher written in highly optimized style
sub send_direct_op {
    my ( $self, $op, $address ) = @_;
    my ( $link, $result );
    ( $link = $self->{_topology}->get_specific_link($address) ), (
        eval { ($result) = $op->execute($link); 1 } or do {
            my $err = length($@) ? $@ : "caught error, but it was lost in eval unwind";
            if ( $err->$_isa("MongoDB::ConnectionError") ) {
                $self->{_topology}->mark_server_unknown( $link->server, $err );
            }
            elsif ( $err->$_isa("MongoDB::NotMasterError") ) {
                $self->{_topology}->mark_server_unknown( $link->server, $err );
                $self->{_topology}->mark_stale;
            }
            # regardless of cleanup, rethrow the error
            WITH_ASSERTS ? ( confess $err ) : ( die $err );
          }
      ),
      return $result;
}

# op dispatcher written in highly optimized style
sub send_write_op {
    my ( $self, $op ) = @_;
    my ( $link, $result );
    ( $link = $self->{_topology}->get_writable_link ), (
        eval { ($result) = $op->execute($link, $self->{_topology}->type); 1 } or do {
            my $err = length($@) ? $@ : "caught error, but it was lost in eval unwind";
            if ( $err->$_isa("MongoDB::ConnectionError") ) {
                $self->{_topology}->mark_server_unknown( $link->server, $err );
            }
            elsif ( $err->$_isa("MongoDB::NotMasterError") ) {
                $self->{_topology}->mark_server_unknown( $link->server, $err );
                $self->{_topology}->mark_stale;
            }
            # regardless of cleanup, rethrow the error
            WITH_ASSERTS ? ( confess $err ) : ( die $err );
          }
      ),
      return $result;
}

# Sometimes, seeing an op dispatched as "send_write_op" is confusing when
# really, we're just insisting that it be sent only to a primary or
# directly connected server.
BEGIN {
    no warnings 'once';
    *send_primary_op = \&send_write_op;
}

# op dispatcher written in highly optimized style
sub send_read_op {
    my ( $self, $op ) = @_;
    my ( $link, $type, $result );
    ( $link = $self->{_topology}->get_readable_link( $op->read_preference ) ),
      ( $type = $self->{_topology}->type ), (
        eval { ($result) = $op->execute( $link, $type ); 1 } or do {
            my $err = length($@) ? $@ : "caught error, but it was lost in eval unwind";
            if ( $err->$_isa("MongoDB::ConnectionError") ) {
                $self->{_topology}->mark_server_unknown( $link->server, $err );
            }
            elsif ( $err->$_isa("MongoDB::NotMasterError") ) {
                $self->{_topology}->mark_server_unknown( $link->server, $err );
                $self->{_topology}->mark_stale;
            }
            # regardless of cleanup, rethrow the error
            WITH_ASSERTS ? ( confess $err ) : ( die $err );
          }
      ),
      return $result;
}

#--------------------------------------------------------------------------#
# database helper methods
#--------------------------------------------------------------------------#

#pod =method database_names
#pod
#pod     my @dbs = $client->database_names;
#pod
#pod Lists all databases on the MongoDB server.
#pod
#pod =cut

sub database_names {
    my ($self) = @_;

    my @databases;
    my $max_tries = 3;
    for my $try ( 1 .. $max_tries ) {
        last if try {
            my $output = $self->send_admin_command([ listDatabases => 1 ])->output;
            if (ref($output) eq 'HASH' && exists $output->{databases}) {
                @databases = map { $_->{name} } @{ $output->{databases} };
            }
            return 1;
        } catch {
            if ( $_->$_isa("MongoDB::DatabaseError" ) ) {
                return if $_->result->output->{code} == CANT_OPEN_DB_IN_READ_LOCK() || $try < $max_tries;
            }
            die $_;
        };
    }

    return @databases;
}

#pod =method get_database, db
#pod
#pod     my $database = $client->get_database('foo');
#pod     my $database = $client->get_database('foo', $options);
#pod     my $database = $client->db('foo', $options);
#pod
#pod Returns a L<MongoDB::Database> instance for the database with the given
#pod C<$name>.
#pod
#pod It takes an optional hash reference of options that are passed to the
#pod L<MongoDB::Database> constructor.
#pod
#pod The C<db> method is an alias for C<get_database>.
#pod
#pod =cut

sub get_database {
    my ( $self, $database_name, $options ) = @_;
    return MongoDB::Database->new(
        read_preference => $self->read_preference,
        write_concern   => $self->write_concern,
        read_concern    => $self->read_concern,
        bson_codec      => $self->bson_codec,
        max_time_ms     => $self->max_time_ms,
        ( $options ? %$options : () ),
        # not allowed to be overridden by options
        _client       => $self,
        name          => $database_name,
    );
}

{ no warnings 'once'; *db = \&get_database }

#pod =method get_namespace, ns
#pod
#pod     my $collection = $client->get_namespace('test.foo');
#pod     my $collection = $client->get_namespace('test.foo', $options);
#pod     my $collection = $client->ns('test.foo', $options);
#pod
#pod Returns a L<MongoDB::Collection> instance for the given namespace.
#pod The namespace has both the database name and the collection name
#pod separated with a dot character.
#pod
#pod This is a quick way to get a collection object if you don't need
#pod the database object separately.
#pod
#pod It takes an optional hash reference of options that are passed to the
#pod L<MongoDB::Collection> constructor.  The intermediate L<MongoDB::Database>
#pod object will be created with default options.
#pod
#pod The C<ns> method is an alias for C<get_namespace>.
#pod
#pod =cut

sub get_namespace {
    my ( $self, $ns, $options ) = @_;
    MongoDB::UsageError->throw("namespace requires a string argument")
      unless defined($ns) && length($ns);
    my ( $db, $coll ) = split /\./, $ns, 2;
    MongoDB::UsageError->throw("$ns is not a valid namespace")
      unless defined($db) && defined($coll);
    return $self->db($db)->coll( $coll, $options );
}

{ no warnings 'once'; *ns = \&get_namespace }

#pod =method fsync(\%args)
#pod
#pod     $client->fsync();
#pod
#pod A function that will forces the server to flush all pending writes to the storage layer.
#pod
#pod The fsync operation is synchronous by default, to run fsync asynchronously, use the following form:
#pod
#pod     $client->fsync({async => 1});
#pod
#pod The primary use of fsync is to lock the database during backup operations. This will flush all data to the data storage layer and block all write operations until you unlock the database. Note: you can still read while the database is locked.
#pod
#pod     $conn->fsync({lock => 1});
#pod
#pod =cut

sub fsync {
    my ($self, $args) = @_;

    $args ||= {};

    # Pass this in as array-ref to ensure that 'fsync => 1' is the first argument.
    return $self->get_database('admin')->run_command([fsync => 1, %$args]);
}

#pod =method fsync_unlock
#pod
#pod     $conn->fsync_unlock();
#pod
#pod Unlocks a database server to allow writes and reverses the operation of a $conn->fsync({lock => 1}); operation.
#pod
#pod =cut

sub fsync_unlock {
    my ($self) = @_;

    my $op = MongoDB::Op::_FSyncUnlock->_new(
        db_name    => 'admin',
        client     => $self,
        bson_codec => $self->bson_codec,
    );

    return $self->send_primary_op($op);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MongoDB::MongoClient - A connection to a MongoDB server or multi-server deployment

=head1 VERSION

version v1.8.0

=head1 SYNOPSIS

    use MongoDB; # also loads MongoDB::MongoClient

    # connect to localhost:27017
    my $client = MongoDB::MongoClient->new;

    # connect to specific host and port
    my $client = MongoDB::MongoClient->new(
        host => "mongodb://mongo.example.com:27017"
    );

    # connect to a replica set (set name *required*)
    my $client = MongoDB::MongoClient->new(
        host => "mongodb://mongo1.example.com,mongo2.example.com",
        replica_set_name => 'myset',
    );

    # connect to a replica set with URI (set name *required*)
    my $client = MongoDB::MongoClient->new(
        host => "mongodb://mongo1.example.com,mongo2.example.com/?replicaSet=myset",
    );

    my $db = $client->get_database("test");
    my $coll = $db->get_collection("people");

    $coll->insert({ name => "John Doe", age => 42 });
    my @people = $coll->find()->all();

=head1 DESCRIPTION

The C<MongoDB::MongoClient> class represents a client connection to one or
more MongoDB servers.

By default, it connects to a single server running on the local machine
listening on the default port 27017:

    # connects to localhost:27017
    my $client = MongoDB::MongoClient->new;

It can connect to a database server running anywhere, though:

    my $client = MongoDB::MongoClient->new(host => 'example.com:12345');

See the L</"host"> attribute for more options for connecting to MongoDB.

MongoDB can be started in L<authentication
mode|http://docs.mongodb.org/manual/core/authentication/>, which requires
clients to log in before manipulating data.  By default, MongoDB does not start
in this mode, so no username or password is required to make a fully functional
connection.  To configure the client for authentication, see the
L</AUTHENTICATION> section.

The actual socket connections are lazy and created on demand.  When the client
object goes out of scope, all socket will be closed.  Note that
L<MongoDB::Database>, L<MongoDB::Collection> and related classes could hold a
reference to the client as well.  Only when all references are out of scope
will the sockets be closed.

=head1 ATTRIBUTES

=head2 host

The C<host> attribute specifies either a single server to connect to (as
C<hostname> or C<hostname:port>), or else a L<connection string URI|/CONNECTION
STRING URI> with a seed list of one or more servers plus connection options.

Defaults to the connection string URI C<mongodb://localhost:27017>.

For IPv6 support, you must have a recent version of L<IO::Socket::IP>
installed.  This module ships with the Perl core since v5.20.0 and is
available on CPAN for older Perls.

=head2 app_name

This attribute specifies an application name that should be associated with
this client.  The application name will be communicated to the server as
part of the initial connection handshake, and will appear in
connection-level and operation-level diagnostics on the server generated on
behalf of this client.  This may be set in a connection string with the
C<appName> option.

The default is the empty string, which indicates a lack of an application
name.

The application name must not exceed 128 bytes.

=head2 auth_mechanism

This attribute determines how the client authenticates with the server.
Valid values are:

=over 4

=item *

NONE

=item *

DEFAULT

=item *

MONGODB-CR

=item *

MONGODB-X509

=item *

GSSAPI

=item *

PLAIN

=item *

SCRAM-SHA-1

=back

If not specified, then if no username is provided, it defaults to NONE.
If a username is provided, it is set to DEFAULT, which chooses SCRAM-SHA-1 if
available or MONGODB-CR otherwise.

This may be set in a connection string with the C<authMechanism> option.

=head2 auth_mechanism_properties

This is an optional hash reference of authentication mechanism specific properties.
See L</AUTHENTICATION> for details.

This may be set in a connection string with the C<authMechanismProperties>
option.  If given, the value must be key/value pairs joined with a ":".
Multiple pairs must be separated by a comma.  If ": or "," appear in a key or
value, they must be URL encoded.

=head2 bson_codec

An object that provides the C<encode_one> and C<decode_one> methods, such as
from L<MongoDB::BSON>.  It may be initialized with a hash reference that will
be coerced into a new L<MongoDB::BSON> object.

If not provided, one will be generated as follows:

    MongoDB::BSON->new(
        dbref_callback => sub { return MongoDB::DBRef->new(shift) },
        dt_type        => $client->dt_type,
        prefer_numeric => $MongoDB::BSON::looks_like_number || 0,
        (
            $MongoDB::BSON::char ne '$' ?
                ( op_char => $MongoDB::BSON::char ) : ()
        ),
    );

This will inflate all DBRefs to L<MongoDB::DBRef> objects, set C<dt_type>
based on the client's C<db_type> accessor, and set the C<prefer_numeric>
and C<op_char> attributes based on the deprecated legacy global variables.

=head2 connect_timeout_ms

This attribute specifies the amount of time in milliseconds to wait for a
new connection to a server.

The default is 10,000 ms.

If set to a negative value, connection operations will block indefinitely
until the server replies or until the operating system TCP/IP stack gives
up (e.g. if the name can't resolve or there is no process listening on the
target host/port).

A zero value polls the socket during connection and is thus likely to fail
except when talking to a local process (and perhaps even then).

This may be set in a connection string with the C<connectTimeoutMS> option.

=head2 db_name

Optional.  If an L</auth_mechanism> requires a database for authentication,
this attribute will be used.  Otherwise, it will be ignored. Defaults to
"admin".

This may be provided in the L<connection string URI|/CONNECTION STRING URI> as
a path between the authority and option parameter sections.  For example, to
authenticate against the "admin" database (showing a configuration option only
for illustration):

    mongodb://localhost/admin?readPreference=primary

=head2 heartbeat_frequency_ms

The time in milliseconds (non-negative) between scans of all servers to
check if they are up and update their latency.  Defaults to 60,000 ms.

This may be set in a connection string with the C<heartbeatFrequencyMS> option.

=head2 j

If true, the client will block until write operations have been committed to the
server's journal. Prior to MongoDB 2.6, this option was ignored if the server was
running without journaling. Starting with MongoDB 2.6, write operations will fail
if this option is used when the server is running without journaling.

This may be set in a connection string with the C<journal> option as the
strings 'true' or 'false'.

=head2 local_threshold_ms

The width of the 'latency window': when choosing between multiple suitable
servers for an operation, the acceptable delta in milliseconds
(non-negative) between shortest and longest average round-trip times.
Servers within the latency window are selected randomly.

Set this to "0" to always select the server with the shortest average round
trip time.  Set this to a very high value to always randomly choose any known
server.

Defaults to 15 ms.

See L</SERVER SELECTION> for more details.

This may be set in a connection string with the C<localThresholdMS> option.

=head2 max_staleness_seconds

The C<max_staleness_seconds> parameter represents the maximum replication lag in
seconds (wall clock time) that a secondary can suffer and still be
eligible for reads. The default is -1, which disables staleness checks.
Otherwise, it must be a positive integer.

B<Note>: this will only be used for server versions 3.4 or greater, as that
was when support for staleness tracking was added.

If the read preference mode is 'primary', then C<max_staleness_seconds> must not
be supplied.

The C<max_staleness_seconds> must be at least the C<heartbeat_frequency_ms>
plus 10 seconds (which is how often the server makes idle writes to the
oplog).

This may be set in a connection string with the C<maxStalenessSeconds> option.

=head2 max_time_ms

Specifies the maximum amount of time in (non-negative) milliseconds that the
server should use for working on a database command.  Defaults to 0, which disables
this feature.  Make sure this value is shorter than C<socket_timeout_ms>.

B<Note>: this will only be used for server versions 2.6 or greater, as that
was when the C<$maxTimeMS> meta-operator was introduced.

You are B<strongly> encouraged to set this variable if you know your
environment has MongoDB 2.6 or later, as getting a definitive error response
from the server is vastly preferred over a getting a network socket timeout.

This may be set in a connection string with the C<maxTimeMS> option.

=head2 password

If an L</auth_mechanism> requires a password, this attribute will be
used.  Otherwise, it will be ignored.

This may be provided in the L<connection string URI|/CONNECTION STRING URI> as
a C<username:password> pair in the leading portion of the authority section
before a C<@> character.  For example, to authenticate as user "mulder" with
password "trustno1":

    mongodb://mulder:trustno1@localhost

If the username or password have a ":" or "@" in it, they must be URL encoded.
An empty password still requires a ":" character.

=head2 port

If a network port is not specified as part of the C<host> attribute, this
attribute provides the port to use.  It defaults to 27107.

=head2 read_pref_mode

The read preference mode determines which server types are candidates
for a read operation.  Valid values are:

=over 4

=item *

primary

=item *

primaryPreferred

=item *

secondary

=item *

secondaryPreferred

=item *

nearest

=back

For core documentation on read preference see
L<http://docs.mongodb.org/manual/core/read-preference/>.

This may be set in a connection string with the C<readPreference> option.

=head2 read_pref_tag_sets

The C<read_pref_tag_sets> parameter is an ordered list of tag sets used to
restrict the eligibility of servers, such as for data center awareness.  It
must be an array reference of hash references.

The application of C<read_pref_tag_sets> varies depending on the
C<read_pref_mode> parameter.  If the C<read_pref_mode> is 'primary', then
C<read_pref_tag_sets> must not be supplied.

For core documentation on read preference see
L<http://docs.mongodb.org/manual/core/read-preference/>.

This may be set in a connection string with the C<readPreferenceTags> option.
If given, the value must be key/value pairs joined with a ":".  Multiple pairs
must be separated by a comma.  If ": or "," appear in a key or value, they must
be URL encoded.  The C<readPreferenceTags> option may appear more than once, in
which case each document will be added to the tag set list.

=head2 replica_set_name

Specifies the replica set name to connect to.  If this string is non-empty,
then the topology is treated as a replica set and all server replica set
names must match this or they will be removed from the topology.

This may be set in a connection string with the C<replicaSet> option.

=head2 server_selection_timeout_ms

This attribute specifies the amount of time in milliseconds to wait for a
suitable server to be available for a read or write operation.  If no
server is available within this time period, an exception will be thrown.

The default is 30,000 ms.

See L</SERVER SELECTION> for more details.

This may be set in a connection string with the C<serverSelectionTimeoutMS>
option.

=head2 server_selection_try_once

This attribute controls whether the client will make only a single attempt
to find a suitable server for a read or write operation.  The default is true.

When true, the client will B<not> use the C<server_selection_timeout_ms>.
Instead, if the topology information is stale and needs to be checked or
if no suitable server is available, the client will make a single
scan of all known servers to try to find a suitable one.

When false, the client will continually scan known servers until a suitable
server is found or the C<serverSelectionTimeoutMS> is reached.

See L</SERVER SELECTION> for more details.

This may be set in a connection string with the C<serverSelectionTryOnce>
option.

=head2 socket_check_interval_ms

If a socket to a server has not been used in this many milliseconds, an
C<ismaster> command will be issued to check the status of the server before
issuing any reads or writes. Must be non-negative.

The default is 5,000 ms.

This may be set in a connection string with the C<socketCheckIntervalMS>
option.

=head2 socket_timeout_ms

This attribute specifies the amount of time in milliseconds to wait for a
reply from the server before issuing a network exception.

The default is 30,000 ms.

If set to a negative value, socket operations will block indefinitely
until the server replies or until the operating system TCP/IP stack
gives up.

A zero value polls the socket for available data and is thus likely to fail
except when talking to a local process (and perhaps even then).

This may be set in a connection string with the C<socketTimeoutMS> option.

=head2 ssl

    ssl => 1
    ssl => \%ssl_options

This tells the driver that you are connecting to an SSL mongodb instance.

You must have L<IO::Socket::SSL> 1.42+ and L<Net::SSLeay> 1.49+ installed for
SSL support.

The C<ssl> attribute takes either a boolean value or a hash reference of
options to pass to IO::Socket::SSL.  For example, to set a CA file to validate
the server certificate and set a client certificate for the server to validate,
you could set the attribute like this:

    ssl => {
        SSL_ca_file   => "/path/to/ca.pem",
        SSL_cert_file => "/path/to/client.pem",
    }

If C<SSL_ca_file> is not provided, server certificates are verified against a
default list of CAs, either L<Mozilla::CA> or an operating-system-specific
default CA file.  To disable verification, you can use
C<< SSL_verify_mode => 0x00 >>.

B<You are strongly encouraged to use your own CA file for increased security>.

Server hostnames are also validated against the CN name in the server
certificate using C<< SSL_verifycn_scheme => 'http' >>.  You can use the
scheme 'none' to disable this check.

B<Disabling certificate or hostname verification is a security risk and is not
recommended>.

This may be set to the string 'true' or 'false' in a connection string with the
C<ssl> option, which will enable ssl with default configuration.  (A future
version of the driver may support customizing ssl via the connection string.)

=head2 username

Optional username for this client connection.  If this field is set, the client
will attempt to authenticate when connecting to servers.  Depending on the
L</auth_mechanism>, the L</password> field or other attributes will need to be
set for authentication to succeed.

This may be provided in the L<connection string URI|/CONNECTION STRING URI> as
a C<username:password> pair in the leading portion of the authority section
before a C<@> character.  For example, to authenticate as user "mulder" with
password "trustno1":

    mongodb://mulder:trustno1@localhost

If the username or password have a ":" or "@" in it, they must be URL encoded.
An empty password still requires a ":" character.

=head2 w

The client I<write concern>.

=over 4

=item * C<0> Unacknowledged. MongoClient will B<NOT> wait for an acknowledgment that
the server has received and processed the request. Older documentation may refer
to this as "fire-and-forget" mode.  This option is not recommended.

=item * C<1> Acknowledged. This is the default. MongoClient will wait until the
primary MongoDB acknowledges the write.

=item * C<2> Replica acknowledged. MongoClient will wait until at least two
replicas (primary and one secondary) acknowledge the write. You can set a higher
number for more replicas.

=item * C<all> All replicas acknowledged.

=item * C<majority> A majority of replicas acknowledged.

=back

In MongoDB v2.0+, you can "tag" replica members. With "tagging" you can
specify a custom write concern For more information see L<Data Center
Awareness|http://docs.mongodb.org/manual/data-center-awareness/>

This may be set in a connection string with the C<w> option.

=head2 wtimeout

The number of milliseconds an operation should wait for C<w> secondaries to
replicate it.

Defaults to 1000 (1 second).

See C<w> above for more information.

This may be set in a connection string with the C<wTimeoutMS> option.

=head2 read_concern_level

The read concern level determines the consistency level required
of data being read.

The default level is C<undef>, which means the server will use its configured
default.

If the level is set to "local", reads will return the latest data a server has
locally.

Additional levels are storage engine specific.  See L<Read
Concern|http://docs.mongodb.org/manual/search/?query=readConcern> in the MongoDB
documentation for more details.

This may be set in a connection string with the the C<readConcernLevel> option.

=head2 dt_type (DEPRECATED AND READ-ONLY)

Sets the type of object which is returned for DateTime fields. The default
is L<DateTime>. Other acceptable values are L<DateTime::Tiny>,
L<Time::Moment> and C<undef>. The latter will give you the raw epoch value
(possibly as a floating point value) rather than an object.

This will be used to construct L</bson_codec> object if one is not provided.

As this has a one-time effect, it is now read-only to help you detect
code that was trying to change after the fact during program execution.

For temporary or localized changes, look into overriding the C<bson_codec>
object for a database or collection object.

=head2 query_timeout (DEPRECATED AND READ-ONLY)

    # set query timeout to 1 second
    my $client = MongoDB::MongoClient->new(query_timeout => 1000);

This option has been renamed as L</socket_timeout_ms>.  If this option is set
and that one is not, this will be used.

This value is in milliseconds and defaults to 30000.

=head2 sasl (DEPRECATED)

If true, the driver will set the authentication mechanism based on the
C<sasl_mechanism> property.

=head2 sasl_mechanism (DEPRECATED)

This specifies the SASL mechanism to use for authentication with a MongoDB server.
It has the same valid values as L</auth_mechanism>.  The default is GSSAPI.

=head2 timeout (DEPRECATED AND READ-ONLY)

This option has been renamed as L</connect_timeout_ms>.  If this option is set
and that one is not, this will be used.

Connection timeout is in milliseconds. Defaults to C<10000>.

=head1 METHODS

=head2 read_preference

Returns a L<MongoDB::ReadPreference> object constructed from
L</read_pref_mode> and L</read_pref_tag_sets>

B<The use of C<read_preference> as a mutator has been removed.>  Read
preference is read-only.  If you need a different read preference for
a database or collection, you can specify that in C<get_database> or
C<get_collection>.

=head2 write_concern

Returns a L<MongoDB::WriteConcern> object constructed from L</w>, L</write_concern>
and L</j>.

=head2 read_concern

Returns a L<MongoDB::ReadConcern> object constructed from
L</read_concern_level>.

=head2 topology_type

Returns an enumerated topology type.  If the L</replica_set_name> is
set, the value will be either 'ReplicaSetWithPrimary' or 'ReplicaSetNoPrimary'
(if the primary is down or not yet discovered).  Without L</replica_set_name>,
the type will be 'Single' if there is only one server in the list of hosts, and
'Sharded' if there are more than one.

N.B. A single mongos will have a topology type of 'Single', as that mongos will
be used for all reads and writes, just like a standalone mongod.  The 'Sharded'
type indicates a sharded cluster with multiple mongos servers, and reads/writes
will be distributed acc

=head2 connect

    $client->connect;

Calling this method is unnecessary, as connections are established
automatically as needed.  It is kept for backwards compatibility.  Calling it
will check all servers in the deployment which ensures a connection to any
that are available.

See L</reconnect> for a method that is useful when using forks or threads.

=head2 disconnect

    $client->disconnect;

Drops all connections to servers.

=head2 reconnect

    $client->reconnect;

This method closes all connections to the server, as if L</disconnect> were
called, and then immediately reconnects.  Use this after forking or spawning
off a new thread.

=head2 topology_status

    $client->topology_status;
    $client->topology_status( refresh => 1 );

Returns a hash reference with server topology information like this:

    {
        'topology_type' => 'ReplicaSetWithPrimary'
        'replica_set_name' => 'foo',
        'last_scan_time'   => '1433766895.183241',
        'servers'          => [
            {
                'address'     => 'localhost:50003',
                'ewma_rtt_ms' => '0.223462326',
                'type'        => 'RSSecondary'
            },
            {
                'address'     => 'localhost:50437',
                'ewma_rtt_ms' => '0.268435456',
                'type'        => 'RSArbiter'
            },
            {
                'address'     => 'localhost:50829',
                'ewma_rtt_ms' => '0.737782272',
                'type'        => 'RSPrimary'
            }
        },
    }

If the 'refresh' argument is true, then the topology will be scanned
to update server data before returning the hash reference.

=head2 database_names

    my @dbs = $client->database_names;

Lists all databases on the MongoDB server.

=head2 get_database, db

    my $database = $client->get_database('foo');
    my $database = $client->get_database('foo', $options);
    my $database = $client->db('foo', $options);

Returns a L<MongoDB::Database> instance for the database with the given
C<$name>.

It takes an optional hash reference of options that are passed to the
L<MongoDB::Database> constructor.

The C<db> method is an alias for C<get_database>.

=head2 get_namespace, ns

    my $collection = $client->get_namespace('test.foo');
    my $collection = $client->get_namespace('test.foo', $options);
    my $collection = $client->ns('test.foo', $options);

Returns a L<MongoDB::Collection> instance for the given namespace.
The namespace has both the database name and the collection name
separated with a dot character.

This is a quick way to get a collection object if you don't need
the database object separately.

It takes an optional hash reference of options that are passed to the
L<MongoDB::Collection> constructor.  The intermediate L<MongoDB::Database>
object will be created with default options.

The C<ns> method is an alias for C<get_namespace>.

=head2 fsync(\%args)

    $client->fsync();

A function that will forces the server to flush all pending writes to the storage layer.

The fsync operation is synchronous by default, to run fsync asynchronously, use the following form:

    $client->fsync({async => 1});

The primary use of fsync is to lock the database during backup operations. This will flush all data to the data storage layer and block all write operations until you unlock the database. Note: you can still read while the database is locked.

    $conn->fsync({lock => 1});

=head2 fsync_unlock

    $conn->fsync_unlock();

Unlocks a database server to allow writes and reverses the operation of a $conn->fsync({lock => 1}); operation.

=for Pod::Coverage connected
send_admin_command
send_direct_op
send_read_op
send_write_op

=head1 DEPLOYMENT TOPOLOGY

MongoDB can operate as a single server or as a distributed system.  One or more
servers that collectively provide access to a single logical set of MongoDB
databases are referred to as a "deployment".

There are three types of deployments:

=over 4

=item *

Single server – a stand-alone mongod database

=item *

Replica set – a set of mongod databases with data replication and fail-over capability

=item *

Sharded cluster – a distributed deployment that spreads data across one or more shards, each of which can be a replica set.  Clients communicate with a mongos process that routes operations to the correct share.

=back

The state of a deployment, including its type, which servers are members, the
server types of members and the round-trip network latency to members is
referred to as the "topology" of the deployment.

To the greatest extent possible, the MongoDB driver abstracts away the details
of communicating with different deployment types.  It determines the deployment
topology through a combination of the connection string, configuration options
and direct discovery communicating with servers in the deployment.

=head1 CONNECTION STRING URI

MongoDB uses a pseudo-URI connection string to specify one or more servers to
connect to, along with configuration options.

To connect to more than one database server, provide host or host:port pairs
as a comma separated list:

    mongodb://host1[:port1][,host2[:port2],...[,hostN[:portN]]]

This list is referred to as the "seed list".  An arbitrary number of hosts can
be specified.  If a port is not specified for a given host, it will default to
27017.

If multiple hosts are given in the seed list or discovered by talking to
servers in the seed list, they must all be replica set members or must all be
mongos servers for a sharded cluster.

A replica set B<MUST> have the C<replicaSet> option set to the replica set
name.

If there is only single host in the seed list and C<replicaSet> is not
provided, the deployment is treated as a single server deployment and all
reads and writes will be sent to that host.

Providing a replica set member as a single host without the set name is the
way to get a "direct connection" for carrying out administrative activities
on that server.

The connection string may also have a username and password:

    mongodb://username:password@host1:port1,host2:port2

The username and password must be URL-escaped.

A optional database name for authentication may be given:

    mongodb://username:password@host1:port1,host2:port2/my_database

Finally, connection string options may be given as URI attribute pairs in a query
string:

    mongodb://host1:port1,host2:port2/?ssl=1&wtimeoutMS=1000
    mongodb://username:password@host1:port1,host2:port2/my_database?ssl=1&wtimeoutMS=1000

The currently supported connection string options are:

=over 4

*appName
*authMechanism
*authMechanism.SERVICE_NAME
*connectTimeoutMS
*journal
*readPreference
*readPreferenceTags
*replicaSet
*ssl
*w
*wtimeoutMS

=back

See the official MongoDB documentation on connection strings for more on the URI
format and connection string options:
L<http://docs.mongodb.org/manual/reference/connection-string/>.

=head1 SERVER SELECTION

For a single server deployment or a direct connection to a mongod or
mongos, all reads and writes and sent to that server.  Any read-preference
is ignored.

When connected to a deployment with multiple servers, such as a replica set
or sharded cluster, the driver chooses a server for operations based on the
type of operation (read or write), the types of servers available and a
read preference.

For a replica set deployment, writes are sent to the primary (if available)
and reads are sent to a server based on the L</read_preference> attribute,
which defaults to sending reads to the primary.  See
L<MongoDB::ReadPreference> for more.

For a sharded cluster reads and writes are distributed across mongos
servers in the seed list.  Any read preference is passed through to the
mongos and used by it when executing reads against shards.

If multiple servers can service an operation (e.g. multiple mongos servers,
or multiple replica set members), one is chosen at random from within the
"latency window".  The server with the shortest average round-trip time
(RTT) is always in the window.  Any servers with an average round-trip time
less than or equal to the shortest RTT plus the L</local_threshold_ms> are
also in the latency window.

If a suitable server is not immediately available, what happens next
depends on the L</server_selection_try_once> option.

If that option is true, a single topology scan will be performed.
Afterwards if a suitable server is available, it will be returned;
otherwise, an exception is thrown.

If that option is false, the driver will do topology scans repeatedly
looking for a suitable server.  When more than
L</server_selection_timeout_ms> milliseconds have elapsed since the start
of server selection without a suitable server being found, an exception is
thrown.

B<Note>: the actual maximum wait time for server selection could be as long
C<server_selection_timeout_ms> plus the amount of time required to do a
topology scan.

=head1 SERVER MONITORING AND FAILOVER

When the client first needs to find a server for a database operation, all
servers from the L</host> attribute are scanned to determine which servers to
monitor.  If the deployment is a replica set, additional hosts may be
discovered in this process.  Invalid hosts are dropped.

After the initial scan, whenever the servers have not been checked in
L</heartbeat_frequency_ms> milliseconds, the scan will be repeated.  This
amortizes monitoring time over many of operations.  Additionally, if a
socket has been idle for a while, it will be checked before being used for
an operation.

If a server operation fails because of a "not master" or "node is
recovering" error, or if there is a network error or timeout, then the
server is flagged as unavailable and exception will be thrown.  See
L<MongoDB::Errors> for exception types.

If the error is caught and handled, the next operation will rescan all
servers immediately to update its view of the topology.  The driver can
continue to function as long as servers are suitable per L</SERVER
SELECTION>.

When catching an exception, users must determine whether or not their
application should retry an operation based on the specific operation
attempted and other use-case-specific considerations.  For automating
retries despite exceptions, consider using the L<Try::Tiny::Retry> module.

=head1 AUTHENTICATION

The MongoDB server provides several authentication mechanisms, though some
are only available in the Enterprise edition.

MongoDB client authentication is controlled via the L</auth_mechanism>
attribute, which takes one of the following values:

=over 4

=item *

MONGODB-CR -- legacy username-password challenge-response

=item *

SCRAM-SHA-1 -- secure username-password challenge-response (3.0+)

=item *

MONGODB-X509 -- SSL client certificate authentication (2.6+)

=item *

PLAIN -- LDAP authentication via SASL PLAIN (Enterprise only)

=item *

GSSAPI -- Kerberos authentication (Enterprise only)

=back

The mechanism to use depends on the authentication configuration of the
server.  See the core documentation on authentication:
L<http://docs.mongodb.org/manual/core/access-control/>.

Usage information for each mechanism is given below.

=head2 MONGODB-CR and SCRAM-SHA-1 (for username/password)

These mechnisms require a username and password, given either as
constructor attributes or in the C<host> connection string.

If a username is provided and an authentication mechanism is not specified,
the client will use SCRAM-SHA-1 for version 3.0 or later servers and will
fall back to MONGODB-CR for older servers.

    my $mc = MongoDB::MongoClient->new(
        host => "mongodb://mongo.example.com/",
        username => "johndoe",
        password => "trustno1",
    );

    my $mc = MongoDB::MongoClient->new(
        host => "mongodb://johndoe:trustno1@mongo.example.com/",
    );

Usernames and passwords will be UTF-8 encoded before use.  The password is
never sent over the wire -- only a secure digest is used.  The SCRAM-SHA-1
mechanism is the Salted Challenge Response Authentication Mechanism
definedin L<RFC 5802|http://tools.ietf.org/html/rfc5802>.

The default database for authentication is 'admin'.  If another database
name should be used, specify it with the C<db_name> attribute or via the
connection string.

    db_name => auth_db

    mongodb://johndoe:trustno1@mongo.example.com/auth_db

=head2 MONGODB-X509 (for SSL client certificate)

X509 authentication requires SSL support (L<IO::Socket::SSL>), requires
that a client certificate be configured in the ssl parameters, and requires
specifying the "MONGODB-X509" authentication mechanism.

    my $mc = MongoDB::MongoClient->new(
        host => "mongodb://sslmongo.example.com/",
        ssl => {
            SSL_ca_file   => "certs/ca.pem",
            SSL_cert_file => "certs/client.pem",
        },
        auth_mechanism => "MONGODB-X509",
    );

=head2 PLAIN (for LDAP)

This mechanism requires a username and password, which will be UTF-8
encoded before use.  The C<auth_mechanism> parameter must be given as a
constructor attribute or in the C<host> connection string:

    my $mc = MongoDB::MongoClient->new(
        host => "mongodb://mongo.example.com/",
        username => "johndoe",
        password => "trustno1",
        auth_mechanism => "PLAIN",
    );

    my $mc = MongoDB::MongoClient->new(
        host => "mongodb://johndoe:trustno1@mongo.example.com/authMechanism=PLAIN",
    );

=head2 GSSAPI (for Kerberos)

Kerberos authentication requires the CPAN module L<Authen::SASL> and a
GSSAPI-capable backend.

On Debian systems, L<Authen::SASL> may be available as
C<libauthen-sasl-perl>; on RHEL systems, it may be available as
C<perl-Authen-SASL>.

The L<Authen::SASL::Perl> backend comes with L<Authen::SASL> and requires
the L<GSSAPI> CPAN module for GSSAPI support.  On Debian systems, this may
be available as C<libgssapi-perl>; on RHEL systems, it may be available as
C<perl-GSSAPI>.

Installing the L<GSSAPI> module from CPAN rather than an OS package
requires C<libkrb5> and the C<krb5-config> utility (available for
Debian/RHEL systems in the C<libkrb5-dev> package).

Alternatively, the L<Authen::SASL::XS> or L<Authen::SASL::Cyrus> modules
may be used.  Both rely on Cyrus C<libsasl>.  L<Authen::SASL::XS> is
preferred, but not yet available as an OS package.  L<Authen::SASL::Cyrus>
is available on Debian as C<libauthen-sasl-cyrus-perl> and on RHEL as
C<perl-Authen-SASL-Cyrus>.

Installing L<Authen::SASL::XS> or L<Authen::SASL::Cyrus> from CPAN requires
C<libsasl>.  On Debian systems, it is available from C<libsasl2-dev>; on
RHEL, it is available in C<cyrus-sasl-devel>.

To use the GSSAPI mechanism, first run C<kinit> to authenticate with the ticket
granting service:

    $ kinit johndoe@EXAMPLE.COM

Configure MongoDB::MongoClient with the principal name as the C<username>
parameter and specify 'GSSAPI' as the C<auth_mechanism>:

    my $mc = MongoDB::MongoClient->new(
        host => 'mongodb://mongo.example.com',
        username => 'johndoe@EXAMPLE.COM',
        auth_mechanism => 'GSSAPI',
    );

Both can be specified in the C<host> connection string, keeping in mind
that the '@' in the principal name must be encoded as "%40":

    my $mc = MongoDB::MongoClient->new(
        host =>
          'mongodb://johndoe%40EXAMPLE.COM@mongo.examplecom/?authMechanism=GSSAPI',
    );

The default service name is 'mongodb'.  It can be changed with the
C<auth_mechanism_properties> attribute or in the connection string.

    auth_mechanism_properties => { SERVICE_NAME => 'other_service' }

    mongodb://.../?authMechanism=GSSAPI&authMechanismProperties=SERVICE_NAME:other_service

=head1 THREAD-SAFETY AND FORK-SAFETY

You B<MUST> call the L</reconnect> method on any MongoDB::MongoClient objects
after forking or spawning a thread.

=head1 AUTHORS

=over 4

=item *

David Golden <david@mongodb.com>

=item *

Rassi <rassi@mongodb.com>

=item *

Mike Friedman <friedo@friedo.com>

=item *

Kristina Chodorow <k.chodorow@gmail.com>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by MongoDB, Inc.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
