package Redis::JobQueue;

=head1 NAME

Redis::JobQueue - Job queue management implemented using Redis server.

=head1 VERSION

This documentation refers to C<Redis::JobQueue> version 1.19

=cut

#-- Pragmas --------------------------------------------------------------------

use 5.010;
use strict;
use warnings;

# ENVIRONMENT ------------------------------------------------------------------

our $VERSION = '1.19';

use Exporter qw(
    import
);
our @EXPORT_OK  = qw(
    DEFAULT_SERVER
    DEFAULT_PORT
    DEFAULT_TIMEOUT
    DEFAULT_CONNECTION_TIMEOUT
    DEFAULT_OPERATION_TIMEOUT
    NAMESPACE
    E_NO_ERROR
    E_MISMATCH_ARG
    E_DATA_TOO_LARGE
    E_NETWORK
    E_MAX_MEMORY_LIMIT
    E_JOB_DELETED
    E_REDIS
);

#-- load the modules -----------------------------------------------------------

use Carp;
use Data::UUID;
use Digest::SHA1 qw(
    sha1_hex
);
use List::Util qw(
    min
    shuffle
);
use List::MoreUtils qw(
    firstidx
);
use Mouse;
use Mouse::Util::TypeConstraints;
use Params::Util qw(
    _ARRAY0
    _INSTANCE
    _NONNEGINT
    _STRING
);
use Redis '1.976';
use Redis::JobQueue::Job qw(
    STATUS_CREATED
    STATUS_WORKING
    STATUS_COMPLETED
    STATUS_FAILED
);
use Redis::JobQueue::Util qw(
    format_message
);
use Storable qw(
    nfreeze
    thaw
);
use Time::HiRes ();
use Try::Tiny;

#-- declarations ---------------------------------------------------------------

=head1 SYNOPSIS

    use 5.010;
    use strict;
    use warnings;

    #-- Common
    use Redis::JobQueue qw(
        DEFAULT_SERVER
        DEFAULT_PORT
    );

    my $connection_string = DEFAULT_SERVER.':'.DEFAULT_PORT;
    my $jq = Redis::JobQueue->new( redis => $connection_string );

    #-- Producer
    my $job = $jq->add_job(
        {
            queue       => 'xxx',
            workload    => \'Some stuff',
            expire      => 12*60*60,            # 12h,
        }
    );

    #-- Worker
    sub xxx {
        my $job = shift;

        my $workload = ${ $job->workload };
        # do something with workload;

        $job->result( 'XXX JOB result comes here' );
    }

    while ( $job = $jq->get_next_job(
            queue       => 'xxx',
            blocking    => 1,
        ) ) {
        $job->status( 'working' );
        $jq->update_job( $job );

        # do my stuff
        xxx( $job );

        $job->status( 'completed' );
        $jq->update_job( $job );
    }

    #-- Consumer
    my $id = $ARGV[0];
    my $status = $jq->get_job_data( $id, 'status' );

    if ( $status eq 'completed' ) {
        # it is now safe to remove it from JobQueue, since it's completed
        my $job = $jq->load_job( $id );

        $jq->delete_job( $id );
        say 'Job result: ', ${ $job->result };
    } else {
        say "Job is not complete, has current '$status' status";
    }

To see a brief but working code example of the C<Redis::JobQueue>
package usage look at the L</"An Example"> section.

Description of the used by C<Redis::JobQueue> data
structures (on Redis server) is provided in L</"JobQueue data structure stored in Redis"> section.

=head1 ABSTRACT

The C<Redis::JobQueue> package is a set of Perl modules which
allows creation of a simple job queue based on Redis server capabilities.

=head1 DESCRIPTION

The main features of the package are:

=over 3

=item *

Supports the automatic creation of job queues, job status monitoring,
updating the job data set, obtaining a consistent job from the queue,
removing jobs, and the classification of possible errors.

=item *

Contains various reusable components that can be used separately or together.

=item *

Provides an object oriented API.

=item *

Support of storing arbitrary job-related data structures.

=item *

Simple methods for organizing producer, worker, and consumer clients.

=back

=head3 Atributes

=over

=item C<id>

An id that uniquely identifies the job, scalar.

=item C<queue>

Queue name in which job is placed, scalar.

=item C<expire>

For how long (seconds) job data structures will be kept in memory.

=item C<status>

Job status, scalar. See L<Redis::JobQueue::Job|Redis::JobQueue::Job> L<EXPORT|Redis::JobQueue::Job/EXPORT> section
for the list of pre-defined statuses.
Can be also set to any arbitrary value.

=item C<workload>, C<result>

User-set data structures which will be serialized before stored in Redis server.
Suitable for passing large amounts of data.

=item C<*>

Any other custom-named field passed to L</constructor> or L</update_job> method
will be stored as metadata scalar in Redis server.
Suitable for storing scalar values with fast access
(will be serialized before stored in Redis server).

=back

=cut

=head2 EXPORT

None by default.

The following additional constants, defining defaults for various parameters, are available for export:

=over

=item C<Redis::JobQueue::MAX_DATASIZE>

Maximum size of the data stored in C<workload>, C<result>: 512MB.

=cut
use constant MAX_DATASIZE       => 512*1024*1024;   # A String value can be at max 512 Megabytes in length.

=item C<DEFAULT_SERVER>

Default address of the Redis server - C<'localhost'>.

=cut
use constant DEFAULT_SERVER     => 'localhost';

=item C<DEFAULT_PORT>

Default port of the Redis server - 6379.

=cut
use constant DEFAULT_PORT       => 6379;

=item C<DEFAULT_TIMEOUT>

Maximum time (in seconds) to wait for a new job from the queue,
0 - unlimited.

=cut
use constant DEFAULT_TIMEOUT    => 0;           # 0 for an unlimited timeout

=item C<DEFAULT_CONNECTION_TIMEOUT>

Default socket timeout for connection, number of seconds: 0.1 .

=cut
use constant DEFAULT_CONNECTION_TIMEOUT => 0.1;

=item C<DEFAULT_OPERATION_TIMEOUT>

Default socket timeout for read and write operations, number of seconds: 1.

=cut
use constant DEFAULT_OPERATION_TIMEOUT  => 1;

=item C<NAMESPACE>

Namespace used for keys on the Redis server - C<'JobQueue'>.

=cut
use constant NAMESPACE          => 'JobQueue';

=item Error codes are identified

More details about error codes are provided in L</DIAGNOSTICS> section.

=back

Possible error codes:

=cut

=over 3

=item C<E_NO_ERROR>

0 - No error

=cut
use constant E_NO_ERROR         => 0;

=item C<E_MISMATCH_ARG>

1 - Invalid argument of C<new> or other L<method|/METHODS>.

=cut
use constant E_MISMATCH_ARG     => 1;

=item C<E_DATA_TOO_LARGE>

2 - Provided data is too large.

=cut
use constant E_DATA_TOO_LARGE   => 2;

=item C<E_NETWORK>

3 - Error connecting to Redis server.

=cut
use constant E_NETWORK          => 3;

=item C<E_MAX_MEMORY_LIMIT>

4 - Command failed because its execution requires more than allowed memory, set in C<maxmemory>.

=cut
use constant E_MAX_MEMORY_LIMIT => 4;

=item C<E_JOB_DELETED>

5 - Job's data was removed.

=cut
use constant E_JOB_DELETED      => 5;

=item C<E_REDIS>

6 - Other error on Redis server.

=back

=cut
use constant E_REDIS            => 6;

our @ERROR = (
    'No error',
    'Invalid argument',
    'Data is too large',
    'Error in connection to Redis server',
    "Command not allowed when used memory > 'maxmemory'",
    'job was removed prior to use',
    'Redis error',
);

our $WAIT_USED_MEMORY   = 0;    # No attempt to protect against used_memory > maxmemory
#our $WAIT_USED_MEMORY   = 1;

my $_ID_IN_QUEUE_FIELD = '__id_in_queue__';

my $NAMESPACE = NAMESPACE;

my @job_fields = Redis::JobQueue::Job->job_attributes;  # sorted list
splice @job_fields, ( firstidx { $_ eq 'meta_data' } @job_fields ), 1;
my %job_fnames = map { $_ => 1 } @job_fields;

my $uuid = new Data::UUID;

my ( $_running_script_name, $_running_script_body );
my %lua_script_body;
my $lua_id_rgxp = '([^:]+)$';

my $lua_body_start = <<"END_BODY_START";
local job_id        = ARGV[1]
local data_fields   = { unpack( ARGV, 2 ) }

local job_key       = '${NAMESPACE}:'..job_id
local job_exists    = redis.call( 'EXISTS', job_key )
local job_data      = {}

if job_exists == 1 then
END_BODY_START

my $lua_body_end = <<"END_BODY_END";
end
return { job_exists, unpack( job_data ) }
END_BODY_END

# Deletes the job data in Redis server
$lua_script_body{delete_job} = <<"END_DELETE_JOB";
local job_id        = ARGV[1]

local job_key = '${NAMESPACE}:'..job_id
if redis.call( 'EXISTS', job_key ) == 1 then
    redis.call( 'LREM', '${NAMESPACE}:queue:'..redis.call( 'HGET', job_key, 'queue' ), 0, redis.call( 'HGET', job_key, '${_ID_IN_QUEUE_FIELD}' ) )
    return redis.call( 'DEL', job_key )
else
    return nil
end
END_DELETE_JOB

# Adds a job to the queue on the Redis server
$lua_script_body{load_job} = <<"END_LOAD_JOB";
$lua_body_start

    for _, field in ipairs( redis.call( 'HKEYS', job_key ) ) do
        if field ~= '${_ID_IN_QUEUE_FIELD}' then
            -- return the field names and values for the data fields
            table.insert( job_data, field )
            table.insert( job_data, redis.call( 'HGET', job_key, field ) )
        end
    end

$lua_body_end
END_LOAD_JOB

# Data of the job is requested from the Redis server
$lua_script_body{get_job_data} = <<"END_GET_JOB_DATA";
$lua_body_start

    for _, field in ipairs( data_fields ) do
        table.insert( job_data, redis.call( 'HGET', job_key, field ) )
    end

$lua_body_end
END_GET_JOB_DATA

# Gets queue status from the Redis server
$lua_script_body{queue_status} = <<"END_QUEUE_STATUS";
local queue         = ARGV[1]
local tm            = tonumber( ARGV[2] )   -- a floating seconds since the epoch

local queue_key     = '${NAMESPACE}:queue:'..queue
local queue_status  = {}

-- if it is necessary to determine the status of a particular queue
if queue then
    -- Queue length
    queue_status[ 'length' ] = redis.call( 'LLEN', queue_key )
    -- if the queue is set
    if queue_status[ 'length' ] > 0 then
        -- for each item in the queue
        for _, in_queue_id in ipairs( redis.call( 'LRANGE', queue_key, 0, -1 ) ) do
            -- select the job ID and determine the value of a field 'created'
            local created = redis.call( 'HGET', '${NAMESPACE}:'..in_queue_id:match( '^(%S+)' ), 'created' )
            if created then
                created = tonumber( created )   -- values are stored as strings (a floating seconds since the epoch)
                -- initialize the calculated values
                if not queue_status[ 'max_job_age' ] then
                    queue_status[ 'max_job_age' ] = 0
                    queue_status[ 'min_job_age' ] = 0
                end
                -- time of birth
                if queue_status[ 'max_job_age' ] == 0 or created < queue_status[ 'max_job_age' ] then
                    queue_status[ 'max_job_age' ] = created
                end
                if queue_status[ 'min_job_age' ] == 0 or created > queue_status[ 'min_job_age' ] then
                    queue_status[ 'min_job_age' ] = created
                end
            end
        end

        -- time of birth -> age
        if queue_status[ 'max_job_age' ] then -- queue_status[ 'min_job_age' ] also ~= 0
            -- The age of the old job (the lifetime of the queue)
            queue_status[ 'max_job_age' ] = tm - queue_status[ 'max_job_age' ]
            -- The age of the younger job
            queue_status[ 'min_job_age' ] = tm - queue_status[ 'min_job_age' ]
            -- Duration of queue activity (the period during which new jobs were created)
            queue_status[ 'lifetime' ] = queue_status[ 'max_job_age' ] - queue_status[ 'min_job_age' ]
        end
    end
end

-- all jobs in the queue, including inactive ones
queue_status[ 'all_jobs' ] = 0
-- review all job keys on the server, including inactive ones
for _, key in ipairs( redis.call( 'KEYS', '${NAMESPACE}:*' ) ) do
    -- counting on the basic structures of jobs
    if key:find( '^${NAMESPACE}:${lua_id_rgxp}' ) then
        -- consider only the structure related to a given queue
        if redis.call( 'HGET', key, 'queue' ) == queue then
            queue_status[ 'all_jobs' ] = queue_status[ 'all_jobs' ] + 1
        end
    end
end

local result_status = {}
-- memorize the names and values of what was possible to calculate
for key, val in pairs( queue_status ) do
    table.insert( result_status, key )
    table.insert( result_status, tostring( val ) )
end

return result_status
END_QUEUE_STATUS

# Gets a list of job IDs on the Redis server
$lua_script_body{get_job_ids} = <<"END_GET_JOB_IDS";
local is_queued = tonumber( ARGV[1] )
local queues    = { unpack( ARGV, 3, 2 + ARGV[2] ) }
local statuses  = { unpack( ARGV, 3 + ARGV[2] ) }

local tmp_ids   = {}

if is_queued == 1 then                          -- jobs in the queues
    -- if not limited to specified queues
    if #queues == 0 then
        -- determine the queues still have not served the job
        for _, queue_key in ipairs( redis.call( 'KEYS', '${NAMESPACE}:queue:*' ) ) do
            table.insert( queues, queue_key:match( '${lua_id_rgxp}' ) )
        end
    end
    -- view each specified queue
    for _, queue in ipairs( queues ) do
        -- for each identifier contained in the queue
        for _, in_queue_id in ipairs( redis.call( 'LRANGE', '${NAMESPACE}:queue:'..queue, 0, -1 ) ) do
            -- distinguish and remember the ID of the job
            tmp_ids[ in_queue_id:match( '^(%S+)' ) ] = 1
        end
    end
else                                            -- all jobs on the server
    local all_job_ids = {}
    for _, key in ipairs( redis.call( 'KEYS', '${NAMESPACE}:*' ) ) do
        -- considering only the basic structure of jobs
        if key:find( '^${NAMESPACE}:${lua_id_rgxp}' ) then
            -- forming a "hash" of jobs IDs
            all_job_ids[ key:match( '${lua_id_rgxp}' ) ] = 1
        end
    end
    -- if a restriction is set on the queues
    if #queues > 0 then
        -- analyze each job on a server
        for job_id, _ in pairs( all_job_ids ) do
            -- get the name of the job queue
            local tmp_queue = redis.call( 'HGET', '${NAMESPACE}:'..job_id, 'queue' )
            -- associate job queue name with the names of the queues from the restriction
            for _, queue in ipairs( queues ) do
                if tmp_queue == queue then
                    -- memorize the appropriate job ID
                    tmp_ids[ job_id ] = 1
                    break
                end
            end
        end
    else
        -- if there is no restriction on the queues, then remember all the jobs on the server
        tmp_ids = all_job_ids
    end
end

-- if the restriction is set by the statuses
if #statuses > 0 then
    -- analyze each job from a previously created "hash"
    for job_id, _ in pairs( tmp_ids ) do
        -- determine the current status of the job
        local job_status = redis.call( 'HGET', '${NAMESPACE}:'..job_id, 'status' )
        -- associate job status with the statuses from the restriction
        for _, status in ipairs( statuses ) do
            if job_status == status then
                -- mark the job satisfying the restriction
                tmp_ids[ job_id ] = 2   -- Filter by status sign
                break
            end
        end
    end
    -- reanalyze each job from a previously created "hash"
    for job_id, _ in pairs( tmp_ids ) do
        if tmp_ids[ job_id ] ~= 2 then
            -- remove unfiltered by status
            tmp_ids[ job_id ] = nil
        end
    end
end

local job_ids = {}
for id, _ in pairs( tmp_ids ) do
    -- remember identifiers of selected jobs
    table.insert( job_ids, id )
end

return job_ids
END_GET_JOB_IDS

#-- constructor ----------------------------------------------------------------

=head2 CONSTRUCTOR

=head3 C<new( redis =E<gt> $server, timeout =E<gt> $timeout, check_maxmemory =E<gt> $mode, ... )>

Creates a new C<Redis::JobQueue> object to communicate with Redis server.
If invoked without any arguments, the constructor C<new> creates and returns
a C<Redis::JobQueue> object that is configured with the default settings and uses
local C<redis> server.

In the parameters of the constructor 'redis' may be either a Redis object
or a server string or a hash reference of parameters to create a Redis object.

Optional C<check_maxmemory> boolean argument (default is true)
defines if attempt is made to find out maximum available memory from Redis.

In some cases Redis implementation forbids such request,
but setting <check_maxmemory> to false can be used as a workaround.

This example illustrates a C<new()> call with all the valid arguments:

    my $coll = Redis::CappedCollection->create(
        redis   => { server => "$server:$port" },   # Redis object
                                    # or hash reference to parameters to create a new Redis object.
        timeout => $timeout,        # wait time (in seconds)
                                    # for blocking call of get_next_job.
                                    # Set 0 for unlimited wait time
        check_maxmemory => $mode,   # boolean argument (default is true)
                                    # defines if attempt is made to find out
                                    # maximum available memory from Redis.
        reconnect_on_error  => 1,   # Boolean argument - default is true and conservative_reconnect is true.
                                    # Controls ability to force re-connection with Redis on error.
        connection_timeout  => DEFAULT_CONNECTION_TIMEOUT,  # Socket timeout for connection,
                                    # number of seconds (can be fractional).
                                    # NOTE: Changes external socket configuration.
        operation_timeout   => DEFAULT_OPERATION_TIMEOUT,   # Socket timeout for read and write operations,
                                    # number of seconds (can be fractional).
                                    # NOTE: Changes external socket configuration.
    );

=head3 Caveats related to connection with Redis server

=over 3

=item *

According to L<Redis|Redis> documentation:

This module consider that any data sent to the Redis server is a raw octets string,
even if it has utf8 flag set.
And it doesn't do anything when getting data from the Redis server.

=item *

Non-serialize-able fields (like status or message) passed in UTF-8 can not be
correctly restored from Redis server. To avoid potential data corruction, passing
UTF-8 encoded value causes error.

=item *

L</DEFAULT_TIMEOUT> value is used when a L<Redis|Redis> class object is
passed to the C<new> constructor without additional C<timeout> argument.

=back

This example illustrates C<new()> call with all possible arguments:

    my $jq = Redis::JobQueue->new(
        redis   => "$server:$port", # Connection info for Redis which hosts queue
        timeout => $timeout,        # wait time (in seconds)
                                    # for blocking call of get_next_job.
                                    # Set 0 for unlimited wait time
    );
    # or
    my $jq = Redis::JobQueue->new(
        redis => {                  # The hash reference of parameters
                                    # to create a Redis object
            server => "$server:$port",
        },
    );

The following examples illustrate other uses of the C<new> method:

    $jq = Redis::JobQueue->new();
    my $next_jq = Redis::JobQueue->new( $jq );

    my $redis = Redis->new( server => "$server:$port" );
    $next_jq = Redis::JobQueue->new(
        $redis,
        timeout => $timeout,
    );
    # or
    $next_jq = Redis::JobQueue->new(
        redis   => $redis,
        timeout => $timeout,
    );

An invalid argument causes die (C<confess>).

=cut
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( _INSTANCE( $_[0], 'Redis' ) ) {
        my $redis = shift;
        return $class->$orig(
            # have to look into the Redis object ...
            redis   => $redis->{server},
            # it is impossible to know from Redis now ...
            #timeout => $redis->???,
            _redis  => $redis,
            @_
        );
    } elsif ( _INSTANCE( $_[0], 'Test::RedisServer' ) ) {
        # to test only
        my $redis = shift;
        # have to look into the Test::RedisServer object ...
        my $conf = $redis->conf;
        $conf->{server} = '127.0.0.1:'.$conf->{port} unless exists $conf->{server};
        return $class->$orig(
            redis   => $conf->{server},
            _redis  => Redis->new( %$conf ),
            @_
        );
    } elsif ( _INSTANCE( $_[0], __PACKAGE__ ) ) {
        my $jq = shift;
        return $class->$orig(
            redis   => $jq->_server,
            _redis  => $jq->_redis,
            timeout => $jq->timeout,
            @_
        );
    } else {
        my %args = @_;
        my $redis = $args{redis};
        if ( _INSTANCE( $redis, 'Redis' ) ) {
            delete $args{redis};
            return $class->$orig(
                # have to look into the Redis object ...
                redis   => $redis->{server},
                # it is impossible to know from Redis now ...
                #timeout => $redis->???,
                _redis  => $redis,
                %args,
            );
        }
        elsif ( ref( $redis ) eq 'HASH' ) {
            $args{_use_external_connection} = 0;
            my $conf = $redis;
            $conf->{server}                 = DEFAULT_SERVER.':'.DEFAULT_PORT   unless exists $conf->{server};
            $conf->{reconnect}              = 1                                 unless exists $conf->{reconnect};
            $conf->{every}                  = 1000                              unless exists $conf->{every};   # 1 ms
            $conf->{conservative_reconnect} = 1                                 unless exists $conf->{conservative_reconnect};
            $conf->{cnx_timeout}    = $args{connection_timeout} = $conf->{cnx_timeout}  // $args{connection_timeout}    // DEFAULT_CONNECTION_TIMEOUT;
            $conf->{read_timeout}   = $args{operation_timeout}  = $conf->{read_timeout} // $args{operation_timeout}     // DEFAULT_OPERATION_TIMEOUT;
            $conf->{write_timeout}  = $conf->{read_timeout};
            delete $args{redis};
            return $class->$orig(
                redis   => $conf->{server},
                _redis  => Redis->new( %$conf ),
                %args,
            );
        } else {
            return $class->$orig( %args );
        }
    }

    return;
};

sub BUILD {
    my ( $self ) = @_;

    $self->_redis( $self->_redis_constructor )
        unless ( $self->_redis );
    $self->_redis->connect if
           exists( $self->_redis->{no_auto_connect_on_new} )
        && $self->_redis->{no_auto_connect_on_new}
        && !$self->_redis->{sock}
    ;

    if ( $self->_check_maxmemory ) {
        my ( undef, $max_datasize ) = $self->_call_redis( 'CONFIG', 'GET', 'maxmemory' );
        defined( _NONNEGINT( $max_datasize ) )
            or die $self->_error( E_NETWORK );
        $self->max_datasize( min $max_datasize, $self->max_datasize )
            if $max_datasize;
    }

    $self->_connection_timeout_trigger( $self->connection_timeout );
    $self->_operation_timeout_trigger( $self->operation_timeout );

    my ( $major, $minor ) = $self->_redis->info->{redis_version} =~ /^(\d+)\.(\d+)/;
    if ( $major < 2 || $major == 2 && $minor < 8 ) {
        $self->_error( E_REDIS );
        confess 'Needs Redis server version 2.8 or higher';
    }

    return;
}

#-- public attributes ----------------------------------------------------------

subtype __PACKAGE__.'::NonNegNum',
    as 'Num',
    where { $_ >= 0 },
    message { format_message( '%s is not a non-negative number!', $_ ) }
;

=head2 METHODS

The following methods are available for object of the C<Kafka::Producer> class:

=cut

=head3 C<timeout>

Accessor to the C<timeout> attribute.

Returns current value of the attribute if called without an argument.

Non-negative integer value can be used to specify a new value of the maximum
waiting time for queue (of the L</get_next_job> method). Use
C<timeout> = 0 for an unlimited wait time.

=cut
has 'timeout'           => (
    is          => 'rw',
    isa         => 'Redis::JobQueue::Job::NonNegInt',
    default     => DEFAULT_TIMEOUT,
);

=head3 reconnect_on_error

Controls ability to force re-connection with Redis on error.

=cut
has reconnect_on_error      => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 0,
);

=head3 connection_timeout

Controls socket timeout for Redis server connection, number of seconds (can be fractional).

NOTE: Changes external socket configuration.

=cut
has connection_timeout      => (
    is          => 'rw',
    isa         => 'Maybe['.__PACKAGE__.'::NonNegNum]',
    default     => undef,
    trigger     => \&_connection_timeout_trigger,
);

sub _connection_timeout_trigger {
    my ( $self, $timeout, $old_timeout ) = @_;

    return if scalar( @_ ) == 2 && ( !defined( $timeout ) && !defined( $old_timeout ) );

    if ( my $redis = $self->_redis ) {
        my $socket = _INSTANCE( $redis->{sock}, 'IO::Socket' ) or confess( 'Bad socket object' );
        # IO::Socket provides a way to set a timeout on the socket,
        # but the timeout will be used only for connection,
        # not for reading / writing operations.
        $socket->timeout( $redis->{cnx_timeout} = $timeout );
    }

    return;
}

=head3 operation_timeout

Controls socket timeout for Redis server read and write operations, number of seconds (can be fractional).

NOTE: Changes external socket configuration.

=cut
has operation_timeout       => (
    is          => 'rw',
    isa         => 'Maybe['.__PACKAGE__.'::NonNegNum]',
    default     => undef,
    trigger     => \&_operation_timeout_trigger,
);

sub _operation_timeout_trigger {
    my ( $self, $timeout, $old_timeout ) = @_;

    return if scalar( @_ ) == 2 && ( !defined( $timeout ) && !defined( $old_timeout ) );

    if ( my $redis = $self->_redis ) {
        my $socket = _INSTANCE( $redis->{sock}, 'IO::Socket' ) or confess( 'Bad socket object' );
        # IO::Socket::Timeout provides a way to set a timeout
        # on read / write operations on an IO::Socket instance,
        # or any IO::Socket::* modules, like IO::Socket::INET.
        if ( defined $timeout ) {
            $redis->{write_timeout} = $redis->{read_timeout} = $timeout;
            $redis->_maybe_enable_timeouts( $socket );
            $socket->enable_timeout;
        } else {
            $redis->{write_timeout} = $redis->{read_timeout} = 0;
            $redis->_maybe_enable_timeouts( $socket );
            $socket->disable_timeout;
        }
    }

    return;
}

=head3 C<max_datasize>

Provides access to the C<max_datasize> attribute.

Returns current value of the attribute if called with no argument.

Non-negative integer value can be used to specify a new value for the maximum
size of data in the attributes of a
L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

The check is done before sending data to the module L<Redis|Redis>,
after possible processing by methods of module L<Storable|Storable>
(attributes L<workload|Redis::JobQueue::Job/workload>, L<result|Redis::JobQueue::Job/result>
and L<meta_data|Redis::JobQueue::Job/meta_data>).
It is automatically serialized.

The C<max_datasize> attribute value is used in the L<constructor|/CONSTRUCTOR>
and data entry job operations on the Redis server.

The L<constructor|/CONSTRUCTOR> uses the smaller of the values of 512MB and
C<maxmemory> limit from a F<redis.conf> file.

=cut
has 'max_datasize'      => (
    is          => 'rw',
    isa         => 'Redis::JobQueue::Job::NonNegInt',
    default     => MAX_DATASIZE,
);

=head3 C<last_errorcode>

Returns the code of the last identified error.

See L</DIAGNOSTICS> section for description of error codes.

=cut
has 'last_errorcode'    => (
    reader      => 'last_errorcode',
    writer      => '_set_last_errorcode',
    isa         => 'Int',
    default     => E_NO_ERROR,
);

#-- private attributes ---------------------------------------------------------

has '_server'           => (
    is          => 'rw',
    init_arg    => 'redis',
    isa         => 'Str',
    default     => DEFAULT_SERVER.':'.DEFAULT_PORT,
    trigger     => sub {
                        my $self = shift;
                        $self->_server( $self->_server.':'.DEFAULT_PORT )
                            unless $self->_server =~ /:/;
                    },
);

has '_redis'            => (
    is          => 'rw',
    isa         => 'Maybe[Redis]',
    default     => undef,
);

has '_transaction'      => (
    is          => 'rw',
    isa         => 'Bool',
    default     => undef,
);

has '_lua_scripts'          => (
    is          => 'rw',
    isa         => 'HashRef[Str]',
    lazy        => 1,
    init_arg    => undef,
    builder     => sub { return {}; },
);

has '_check_maxmemory'            => (
    is          => 'ro',
    init_arg    => 'check_maxmemory',
    isa         => 'Bool',
    default     => 1,
);

has '_use_external_connection'     => (
    is          => 'rw',
    isa         => 'Bool',
    default     => 1,
);

#-- public methods -------------------------------------------------------------

=head3 C<last_error>

Returns error message of the last identified error.

See L</DIAGNOSTICS> section for more info on errors.

=cut
sub last_error {
    my ( $self ) = @_;

    return $ERROR[ $self->last_errorcode ];
}

=head3 C<add_job( $job_data, LPUSH =E<gt> 1 )>

Adds a job to the queue on the Redis server.

The first argument should be either L<Redis::JobQueue::Job|Redis::JobQueue::Job>
object (which is modified by the method) or a reference to a hash representing
L<Redis::JobQueue::Job|Redis::JobQueue::Job> - in the latter case
a new L<Redis::JobQueue::Job|Redis::JobQueue::Job> object is created.

Returns a L<Redis::JobQueue::Job|Redis::JobQueue::Job> object with a new
unique identifier.

Job status is set to L<STATUS_CREATED|Redis::JobQueue::Job/STATUS_CREATED>.

C<add_job> optionally takes arguments in key-value pairs.

The following example illustrates a C<add_job()> call with all possible arguments:

    my $job_data = {
        id           => '4BE19672-C503-11E1-BF34-28791473A258',
        queue        => 'lovely_queue', # required
        job          => 'strong_job',   # optional attribute
        expire       => 12*60*60,
        status       => 'created',
        workload     => \'Some stuff',
        result       => \'JOB result comes here',
    };

    my $job = Redis::JobQueue::Job->new( $job_data );

    my $resulting_job = $jq->add_job( $job );
    # or
    $resulting_job = $jq->add_job(
        $pre_job,
        LPUSH       => 1,
    );

If used with the optional argument C<LPUSH =E<gt> 1>, the job is placed at the beginnig of
the queue and will be returned by the next call to get_next_job.

TTL of job data on Redis server is set in accordance with the L</expire>
attribute of the L<Redis::JobQueue::Job|Redis::JobQueue::Job> object. Make
sure it's higher than the time needed to process all the jobs in the queue.

=cut
sub add_job {
    my $self        = shift;

    $self->_error( E_NO_ERROR );
    ref( $_[0] ) eq 'HASH' || _INSTANCE( $_[0], 'Redis::JobQueue::Job' )
        || confess $self->_error( E_MISMATCH_ARG );
    my $job = _INSTANCE( $_[0], 'Redis::JobQueue::Job' ) ? shift : Redis::JobQueue::Job->new( shift );

    my %args = ( @_ );

    my ( $id, $key );
    do {
        $self->_call_redis( 'UNWATCH' );
        $key = $self->_jkey( $id = $uuid->create_str );
        $self->_call_redis( 'WATCH', $key );
    } while ( $self->_call_redis( 'EXISTS', $self->_jkey( $id ) ) );

    $job->id( $id );
    my $expire = $job->expire;

    # transaction start
    $self->_call_redis( 'MULTI' );

    $self->_call_redis( 'HSET', $key, $_, $job->$_ // q{} )
        for @job_fields;
    $self->_call_redis( 'HSET', $key, $_, $job->meta_data( $_ ) // q{} )
        for keys %{ $job->meta_data };

    my $id_in_list = $id;

    if ( $expire ) {
        $id_in_list .= ' '.( time + $expire );
        $self->_call_redis( 'EXPIRE', $key, $expire );
    }

    $self->_call_redis( 'HSET', $key, $_ID_IN_QUEUE_FIELD, $id_in_list );

    $self->_call_redis( $args{LPUSH} ? 'LPUSH' : 'RPUSH', $self->_qkey( $job->queue ), $id_in_list );

    # transaction end
    $self->_call_redis( 'EXEC' ) // return;

    $job->clear_modified;
    return $job;
}

=head3 C<get_job_data( $job, $data_key )>

Data of the job is requested from the Redis server. First argument can be either
a job ID or L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

Returns C<undef> when the job was not found on Redis server.

The method returns the jobs data from the Redis server.
See L<Redis::JobQueue::Job|Redis::JobQueue::Job> for the list of standard jobs data fields.

The method returns a reference to a hash of the standard jobs data fields if only the first
argument is specified.

If given a key name C<$data_key>, it returns data corresponding to
the key or C<undef> when the value is undefined or key is not in the data or metadata.

The following examples illustrate uses of the C<get_job_data> method:

    my $data_href = $jq->get_job_data( $id );
    # or
    $data_href = $jq->get_job_data( $job );
    # or
    my $data_key = 'foo';
    my $data = $jq->get_job_data( $job->id, $data_key );

You can specify a list of names of key data or metadata.
In this case it returns the corresponding list of data. For example:

    my ( $status, $foo ) = $jq->get_job_data( $job->id, 'status', 'foo' );

See L<meta_data|Redis::JobQueue::Job/meta_data> for more informations about
the jobs metadata.

=cut
sub get_job_data {
    my ( $self, $id_source, @data_keys ) = @_;

    my $job_id      = $self->_get_job_id( $id_source );
    my $data_fields = scalar @data_keys;
    my @right_keys  = map { _STRING( $_ ) || q{} } @data_keys;
    my %right_names = map { $_ => 1 } grep { $_ } @right_keys;

    my @additional = ();
    if ( $data_fields ) {
        if ( exists $right_names{elapsed} ) {
            foreach my $field ( qw( started completed failed ) ) {
                push @additional, $field if !exists $right_names{ $field };
            }
        }
    } else {
        @additional = @job_fields;
    }
    my @all_fields = ( @right_keys, @additional );
    my $total_fields = scalar( @all_fields );

    $self->_error( E_NO_ERROR );

    my $tm = time;
    my ( $job_exists, @data ) = $self->_call_redis(
        $self->_lua_script_cmd( 'get_job_data' ),
        0,
        $job_id,
        @all_fields,
    );

    return unless $job_exists;

    for ( my $i = 0; $i < $total_fields; ++$i ) {
        my $field = $all_fields[ $i ];
        if ( $field ne 'elapsed' && ( $field =~ /^(workload|result)$/ || !$job_fnames{ $field } ) ) {
            $data[ $i ] = ${ thaw( $data[ $i ] ) }
                if $data[ $i ];
        }
    }

    if ( !$data_fields ) {
        my %result_data;
        for ( my $i = 0; $i < $total_fields; ++$i ) {
            $result_data{ $all_fields[ $i ] } = $data[ $i ];
        }

        if ( my $started = $result_data{started} ) {
            $result_data{elapsed} = (
                   $result_data{completed}
                || $result_data{failed}
                || time
            ) - $started;
        } else {
            $result_data{elapsed} = undef;
        }

        return \%result_data;
    } else {
        for ( my $i = 0; $i < $data_fields; ++$i ) {
            if ( $right_keys[ $i ] eq 'elapsed' ) {
                if ( my $started = $data[ firstidx { $_ eq 'started' } @all_fields ] ) {
                    $data[ $i ] = (
                           $data[ firstidx { $_ eq 'completed' } @all_fields ]
                        || $data[ firstidx { $_ eq 'failed' } @all_fields ]
                        || $tm
                    ) - $started;
                } else {
                    $data[ $i ] = undef;
                }
            }

            return $data[0] unless wantarray;
        }

        return @data;
    }

    return;
}

=head3 C<get_job_meta_fields( $job )>

The list of names of metadata fields of the job is requested from the Redis server.
First argument can be either a job ID or
L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

Returns empty list when the job was not found on Redis server or
the job does not have metadata.

The following examples illustrate uses of the C<get_job_meta_fields> method:

    my @fields = $jq->get_job_meta_fields( $id );
    # or
    @fields = $jq->get_job_meta_fields( $job );
    # or
    @fields = $jq->get_job_meta_fields( $job->id );

See L<meta_data|Redis::JobQueue::Job/meta_data> for more informations about
the jobs metadata.

=cut
sub get_job_meta_fields {
    my ( $self, $id_source ) = @_;

    return grep { !$job_fnames{ $_ } && $_ ne $_ID_IN_QUEUE_FIELD } $self->_call_redis( 'HKEYS', $self->_jkey( $self->_get_job_id( $id_source ) ) );
}

=head3 C<load_job( $job )>

Loads job data from the Redis server. The argument is either job ID or
a L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

Method returns the object corresponding to the loaded job.
Returns C<undef> if the job is not found on the Redis server.

The following examples illustrate uses of the C<load_job> method:

    $job = $jq->load_job( $id );
    # or
    $job = $jq->load_job( $job );

=cut
sub load_job {
    my ( $self, $id_source ) = @_;

    my $job_id = $self->_get_job_id( $id_source );

    $self->_error( E_NO_ERROR );

    my ( $job_exists, @job_data ) = $self->_call_redis(
        $self->_lua_script_cmd( 'load_job' ),
        0,
        $job_id,
        @job_fields,
    );

    return unless $job_exists;

    my ( $pre_job, $key, $val );
    while ( @job_data ) {
        $key = shift @job_data;
        $val = shift @job_data;
        if ( $job_fnames{ $key } ) {
            $pre_job->{ $key } = $val;
        } else {
            $pre_job->{meta_data}->{ $key } = $val;
        }
    }

    foreach my $field ( qw( workload result ) ) {
        $pre_job->{ $field } = ${ thaw( $pre_job->{ $field } ) }
            if $pre_job->{ $field };
    }
    if ( $pre_job->{meta_data} ) {
        my $meta_data = $pre_job->{meta_data};
        foreach my $field ( keys %$meta_data ) {
            $meta_data->{ $field } = ${ thaw( $meta_data->{ $field } ) }
                if $meta_data->{ $field };
        }
    }

    my $new_job = Redis::JobQueue::Job->new( $pre_job );
    $new_job->clear_modified;

    return $new_job;
}

=head3 C<get_next_job( queue =E<gt> $queue_name, blocking =E<gt> 1 )>

Selects the job identifier which is at the beginning of the queue.

C<get_next_job> takes arguments in key-value pairs.
You can specify a queue name or a reference to an array of queue names.
Queues from the list are processed in random order.

By default, each queue is processed in a separate request with the result
returned immediately if a job is found (waiting) in that queue. If no waiting
job found, returns undef.
In case optional C<blocking> argument is true, all queues are processed in
a single request to Redis server and if no job is found waiting in queue(s),
get_next_job execution will be paused for up to C<timeout> seconds or until
a job becomes available in any of the listed queues.

Use C<timeout> = 0 for an unlimited wait time.
Default - C<blocking> is false (0).

Method returns the job object corresponding to the received job identifier.
Returns the C<undef> if there is no job in the queue.

These examples illustrate a C<get_next_job> call with all the valid arguments:

    $job = $jq->get_next_job(
        queue       => 'xxx',
        blocking    => 1,
    );
    # or
    $job = $jq->get_next_job(
        queue       => [ 'aaa', 'bbb' ],
        blocking    => 1,
    );

TTL job data for the job resets on the Redis server in accordance with
the L</expire> attribute of the job object.

=cut
sub get_next_job {
    my $self        = shift;

    !( scalar( @_ ) % 2 )
        || confess $self->_error( E_MISMATCH_ARG );
    my %args        = ( @_ );
    my $queues      = $args{queue};
    my $blocking    = $args{blocking};
    my $only_id     = $args{_only_id};

    $queues = [ $queues // () ]
        if !ref( $queues );

    foreach my $arg ( ( @{$queues} ) ) {
        defined _STRING( $arg )
            or confess $self->_error( E_MISMATCH_ARG );
    }

    my @keys = ();
    push @keys, map { $self->_qkey( $_ ) } @$queues;

    $self->_error( E_NO_ERROR );

    if ( @keys ) {
        @keys = shuffle( @keys );

        my $full_id;
        if ( $blocking ) {
            # 'BLPOP' waiting time of a given $self->timeout parameter
            my @cmd = ( 'BLPOP', ( @keys ), $self->timeout );
            while (1) {
                ( undef, $full_id ) = $self->_call_redis( @cmd );
                # if the job is no longer
                last unless $full_id;

                my $ret = $self->_get_next_job( $full_id, $only_id );
                return $ret if $ret;
            }
        } else {
            # 'LPOP' takes only one queue name at a time
            foreach my $key ( @keys ) {
                next unless $self->_call_redis( 'EXISTS', $key );
                my @cmd = ( 'LPOP', $key );
                while (1) {
                    $full_id = $self->_call_redis( @cmd );
                    # if the job is no longer
                    last unless $full_id;

                    my $ret = $self->_get_next_job( $full_id, $only_id );
                    return $ret if $ret;
                }
            }
        }
    }

    return;
}

=head3 C<get_next_job_id( queue =E<gt> $queue_name, blocking =E<gt> 1 )>

Like L</get_next_job>, but returns job identifier only.

TTL job data for the job does not reset on the Redis server.

=cut
sub get_next_job_id {
    my $self        = shift;

    return $self->get_next_job( @_, _only_id => 1 );
}

sub _get_next_job {
    my ( $self, $full_id, $only_id ) = @_;

    my ( $id, $expire_time ) = split ' ', $full_id;
    my $key = $self->_jkey( $id );
    if ( $self->_call_redis( 'EXISTS', $key ) ) {
        if ( $only_id ) {
            return $id;
        } else {
            my $job = $self->load_job( $id );
            if ( my $expire = $job->expire ) {
                $self->_call_redis( 'EXPIRE', $key, $expire );
            }
            return $job;
        }
    } else {
        if ( !$expire_time || time < $expire_time ) {
            confess format_message( '%s %s', $id, $self->_error( E_JOB_DELETED ) );
        }
        # If the queue contains a job identifier that has already been removed due
        # to expiration, the cycle will ensure the transition
        # to the next job ID selection
        return;
    }

    return;
}

=head3 C<update_job( $job )>

Saves job data changes to the Redis server. Job ID is obtained from
the argument, which can be a L<Redis::JobQueue::Job|Redis::JobQueue::Job>
object.

Returns the number of attributes that were updated if the job was found on the Redis
server and C<undef> if it was not.
When you change a single attribute, returns C<2> because L<updated|Redis::JobQueue::Job/updated> also changes.

Changing the L</expire> attribute is ignored.

The following examples illustrate uses of the C<update_job> method:

    $jq->update_job( $job );

TTL job data for the job resets on the Redis server in accordance with
the L</expire> attribute of the job object.

=cut
sub update_job {
    my ( $self, $job ) = @_;

    _INSTANCE( $job, 'Redis::JobQueue::Job' )
        or confess $self->_error( E_MISMATCH_ARG );

    my @modified = $job->modified_attributes;
    return 0 unless @modified;

    $self->_error( E_NO_ERROR );

    my $id = $job->id;
    my $key = $self->_jkey( $id );
    $self->_call_redis( 'WATCH', $key );
    if ( !$self->_call_redis( 'EXISTS', $key ) ) {
        $self->_call_redis( 'UNWATCH' );
        return;
    }

    # transaction start
    $self->_call_redis( 'MULTI' );

    my $expire = $job->expire;
    if ( $expire ) {
        $self->_call_redis( 'EXPIRE', $key, $expire );
    } else {
        $self->_call_redis( 'PERSIST', $key );
    }

    my $updated = 0;
    foreach my $field ( @modified ) {
        if ( !$job_fnames{ $field } ) {
            $self->_call_redis( 'HSET', $key, $field, $job->meta_data( $field ) // q{} );
            ++$updated;
        } elsif ( $field ne 'expire' && $field ne 'id' ) {
            $self->_call_redis( 'HSET', $key, $field, $job->$field // q{} );
            ++$updated;
        } else {
            # Field 'expire' and 'id' shall remain unchanged
        }
    }

    # transaction end
    $self->_call_redis( 'EXEC' ) // return;
    $job->clear_modified;

    return $updated;
}

=head3 C<delete_job( $job )>

Deletes job's data from Redis server.
The Job ID is obtained from the argument, which can be either a string or
a L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

Returns true if job and its metadata was successfully deleted from Redis server.
False if jobs or its metadata wasn't found.

The following examples illustrate uses of the C<delete_job> method:

    $jq->delete_job( $job );
    # or
    $jq->delete_job( $id );

Use this method soon after receiving the results of the job to free memory on
the Redis server.

See description of the C<Redis::JobQueue> data structure used on the Redis server
at the L</"JobQueue data structure stored in Redis"> section.

Note that job deletion time is proportional to number of jobs currently in the queue.

=cut
sub delete_job {
    my ( $self, $id_source ) = @_;

    defined( _STRING( $id_source ) ) || _INSTANCE( $id_source, 'Redis::JobQueue::Job' )
        || confess $self->_error( E_MISMATCH_ARG );

    $self->_error( E_NO_ERROR );

    return $self->_call_redis(
        $self->_lua_script_cmd( 'delete_job' ),
        0,
        ref( $id_source ) ? $id_source->id : $id_source,
    );
}

=head3 C<get_job_ids>

Gets list of job IDs on the Redis server.
These IDs are identifiers of job data structures, not only the identifiers which
get derived from the queue by L</get_next_job>.

The following examples illustrate simple uses of the C<get_job_ids> method
(IDs of all existing jobs):

    @jobs = $jq->get_job_ids;

These are identifiers of jobs data structures related to the queue
determined by the arguments.

C<get_job_ids> takes arguments in key-value pairs.
You can specify a queue name or job status
(or a reference to an array of queue names or job statuses)
to filter the list of identifiers.

You can also specify an argument C<queued> (true or false).

When filtering by the names of the queues and C<queued> is set to true,
only the identifiers of the jobs which have not yet been derived from
the queues using L</get_next_job> are returned.

Filtering by status returns the task IDs whose status is exactly the same
as the specified status.

The following examples illustrate uses of the C<get_job_ids> method:

    # filtering the identifiers of jobs data structures
    @ids = $jq->get_job_ids( queue => 'some_queue' );
    # or
    @ids = $jq->get_job_ids( queue => [ 'foo_queue', 'bar_queue' ] );
    # or
    @ids = $jq->get_job_ids( status => STATUS_COMPLETED );
    # or
    @ids = $jq->get_job_ids( status => [ STATUS_COMPLETED, STATUS_FAILED ] );

    # filter the IDs are in the queues
    @ids = $jq->get_job_ids( queued => 1, queue => 'some_queue' );
    # etc.

=cut
sub get_job_ids {
    my $self        = shift;

    confess format_message( '%s (Odd number of elements in hash assignment)', $self->_error( E_MISMATCH_ARG ) )
        if ( scalar( @_ ) % 2 );

    my %args = @_;

    # Here are the arguments to references to arrays
    foreach my $field ( qw( queue status ) ) {
        $args{ $field } = [ $args{ $field } ] if exists( $args{ $field } ) && ref( $args{ $field } ) ne 'ARRAY';
    }

    my @queues      = grep { _STRING( $_ ) } @{ $args{queue} };
    my @statuses    = grep { _STRING( $_ ) } @{ $args{status} };

    $self->_error( E_NO_ERROR );

    my @ids = $self->_call_redis(
        $self->_lua_script_cmd( 'get_job_ids' ),
        0,
        $args{queued} ? 1 : 0,
        scalar( @queues ),                      # the number of queues to filter
        scalar( @queues )   ? @queues   : (),   # the queues to filter
        scalar( @statuses ) ? @statuses : (),   # the statuses to filter
    );

    return @ids;
}

=head3 C<server>

Returns the address of the Redis server used by the queue
(in form of 'host:port').

The following example illustrates use of the C<server> method:

    $redis_address = $jq->server;

=cut
sub server {
    my ( $self ) = @_;

    return $self->_server;
}

=head3 C<ping>

This command is used to test connection to Redis server.

Returns 1 if a connection is still alive or 0 otherwise.

The following example illustrates use of the C<ping> method:

    $is_alive = $jq->ping;

External connections to the server object (eg, C <$redis = Redis->new( ... );>),
and the queue object can continue to work after calling ping only if the method returned 1.

If there is no connection to the Redis server (methods return 0), the connection to the server closes.
In this case, to continue working with the queue,
you must re-create the C<Redis::JobQueue> object with the L</new> method.
When using an external connection to the server,
to check the connection to the server you can use the C<$redis-E<gt>echo( ... )> call.
This is useful to avoid closing the connection to the Redis server unintentionally.

=cut
sub ping {
    my ( $self ) = @_;

    $self->_error( E_NO_ERROR );

    my $ret = $self->_redis->ping;

    $ret = ( $ret // '<undef>' ) eq 'PONG' ? 1 : 0;

    return $ret;
}

=head3 C<quit>

Closes connection to the Redis server.

The following example illustrates use of the C<quit> method:

    $jq->quit;

It does not close the connection to the Redis server if it is an external connection provided
to queue constructor as existing L<Redis> object.
When using an external connection (eg, C<$redis = Redis-E<gt> new (...);>),
to close the connection to the Redis server, call C<$redis-E<gt>quit> after calling this method.

=cut
sub quit {
    my ( $self ) = @_;

    return if $] >= 5.14 && ${^GLOBAL_PHASE} eq 'DESTRUCT';

    $self->_error( E_NO_ERROR );
    $self->_redis->quit unless $self->_use_external_connection;

    return;
}

=head3 C<queue_status>

Gets queue status from the Redis server.
Queue name is obtained from the argument. The argument can be either a
string representing a queue name or a
L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

Returns a reference to a hash describing state of the queue or a reference
to an empty hash when the queue wasn't found.

The following examples illustrate uses of the C<queue_status> method:

    $qstatus = $jq->queue_status( $queue_name );
    # or
    $qstatus = $jq->queue_status( $job );

The returned hash contains the following information related to the queue:

=over 3

=item * C<length>

The number of jobs in the active queue that are waiting to be selected by L</get_next_job> and then processed.

=item * C<all_jobs>

The number of ALL jobs tagged with the queue, i.e. including those that were processed before and other jobs,
not presently waiting in the active queue.

=item * C<max_job_age>

The age of the oldest job (the lifetime of the queue) in the active queue.

=item * C<min_job_age>

The age of the youngest job in the active queue.

=item * C<lifetime>

Time it currently takes for a job to pass through the queue.

=back

Statistics based on the jobs that have not yet been removed.
Some fields may be missing if the status of the job prevents determining
the desired information (eg, there are no jobs in the queue).

=cut
# Statistics based on the jobs that have not yet been removed
sub queue_status {
    my ( $self, $maybe_queue ) = @_;

    defined( _STRING( $maybe_queue ) ) || _INSTANCE( $maybe_queue, 'Redis::JobQueue::Job' )
        || confess $self->_error( E_MISMATCH_ARG );

    $maybe_queue = $maybe_queue->queue
        if ref $maybe_queue;

    $self->_error( E_NO_ERROR );

    my %qstatus = $self->_call_redis(
        $self->_lua_script_cmd( 'queue_status' ),
        0,
        $maybe_queue,
        Time::HiRes::time(),
    );

    return \%qstatus;
}

=head3 C<queue_length>

Gets queue length from the Redis server.
Queue name is obtained from the argument. The can be a string representing a queue name
or a L<Redis::JobQueue::Job|Redis::JobQueue::Job> object.

If queue does not exist, it is interpreted as an empty list and 0 is returned.

The following examples illustrate uses of the C<queue_length> method:

    $queue_length = $jq->queue_length( $queue_name );
    # or
    $queue_length = $jq->queue_status( $job );

=cut
sub queue_length {
    my ( $self, $maybe_queue ) = @_;

    defined( _STRING( $maybe_queue ) ) || _INSTANCE( $maybe_queue, 'Redis::JobQueue::Job' )
        || confess $self->_error( E_MISMATCH_ARG );

    $maybe_queue = $maybe_queue->queue
        if ref $maybe_queue;

    $self->_error( E_NO_ERROR );

    my $queue_lenght = $self->_call_redis( 'LLEN', $self->_qkey( $maybe_queue ) );

    return $queue_lenght;
}

#-- private methods ------------------------------------------------------------

sub _redis_exception {
    my ( $self, $error ) = @_;

    my $err_msg = '';

    # Use the error messages from Redis.pm
    if (
               $error =~ /Could not connect to Redis server at /    # not in start if not reconnected
            || $error =~ /^Can't close socket: /
            || $error =~ /^Not connected to any server/
            # Maybe for pub/sub only
            || $error =~ /^Error while reading from Redis server: /
            || $error =~ /^Redis server closed connection/
        ) {
        $self->_error( E_NETWORK );
        $err_msg = $self->_do_reconnect( E_NETWORK, $err_msg ) if !$self->_transaction && $self->reconnect_on_error;
    } elsif (
            $error =~ /^\[[^]]+\]\s+NOSCRIPT No matching script. Please use EVAL./
        ) {
        $self->_clear_sha1;
        return 1;
    } elsif (
               $error =~ /[\S+] ERR command not allowed when used memory > 'maxmemory'/
            || $error =~ /[\S+] OOM command not allowed when used memory > 'maxmemory'/
        ) {
        $self->_error( E_MAX_MEMORY_LIMIT );
    } else {
        $self->_error( E_REDIS );
        $err_msg = $self->_do_reconnect( E_REDIS, $err_msg ) if !$self->_transaction && $self->reconnect_on_error;
    }

    if ( $self->_transaction ) {
        try {
            $self->_redis->discard;
        };
        $self->_transaction( 0 );
    }

    die( format_message( '%s %s', $error, $err_msg ) );

    return;
}

sub _redis_constructor {
    my ( $self ) = @_;

    $self->_error( E_NO_ERROR );
    my $redis;

    try {
        $redis = Redis->new(
            server      => $self->_server,
        );
    } catch {
        $self->_redis_exception( $_ );
    };
    return $redis;
}

# Keep in mind the default 'redis.conf' values:
# Close the connection after a client is idle for N seconds (0 to disable)
#    timeout 300

# Send a request to Redis
sub _call_redis {
    my $self   = shift;
    my $method = shift;

    $self->_error( E_NO_ERROR );

    $self->_wait_used_memory if $self && $method =~ /^EVAL/i;

    my @result;
    my $error;
    # if you use "$method eq 'HSET'" then use $_[0..2] to reduce data copies
    # $_[0] - key
    # $_[1] - field
    # $_[2] - value
    if ( $method eq 'HSET' && $_[1] eq $_ID_IN_QUEUE_FIELD ) {
        my ( $key, $field, $value ) = @_;
        try {
            @result = $self->_redis->$method(
                $key,
                $field,
                $value,
            );
        } catch {
            $error = $_;
        };
    } elsif ( $method eq 'HSET' && ( $_[1] =~ /^(workload|result)$/ || !$job_fnames{ $_[1] } ) ) {
        my $data_ref = \nfreeze( \$_[2] );

        if ( length( $$data_ref ) > $self->max_datasize ) {
            if ( $self->_transaction ) {
                try {
                    $self->_redis->discard;
                };
                $self->_transaction( 0 );
            }
            # 'die' as maybe too long to analyze the data output from the 'confess'
            die format_message( '%s: %s', $self->_error( E_DATA_TOO_LARGE ), $_[1] );
        }

        my ( $key, $field ) = @_;
        try {
            @result = $self->_redis->$method(
                $key,
                $field,
                $$data_ref,
            );
        } catch {
            $error = $_;
        };
    } elsif ( $method eq 'HSET' && utf8::is_utf8( $_[2] ) ) {
        # In our case, the user sends data to the job queue and then gets it back.
        # Workload and result are fine with Unicode - they're properly serialized by Storable and stored as bytes in Redis;
        # Storable takes care about Unicode etc.
        # The main string job data fields (id, queue, job, status, message),
        # however, is not serialized for performance and convenience reasons, and stored in Redis as-is.
        # If there is Unicode in these fields, we have the following options:
        # 1. Assume everything is Unicode, turn utf-8 encoding in Redis.pm settings and take a substantial performance hit;
        #    as we store the biggest parts of job data - workload and result - serialized already,
        #    encoding and decoding them again is not a good idea.
        # 2. Assume that all fields is Unicode, encode and decode it;
        #    this may lead to subtle errors if user provides it which is binary, not Unicode.
        # 3. Detect Unicode data and store "utf-8" flag along with data on redis,
        #    to decode only utf-8 data when it is requested by user.
        #    This makes data management more complicated.
        # 4. Assume that data is for application internal use,
        #    and that application must ensure that it does not contain Unicode;
        #    if Unicode is really needed, it should be either stored in workload or result,
        #    or the application must take care about encoding and decoding Unicode data before sending to the job queue.
        #    The job queue will throw an exception if Unicode data is encountered.
        #
        # We choose (4) as it is consistent, does not degrade performance and does not cause subtle errors with damaged data.

        # For non-serialized fields: UTF8 can not be transferred to the Redis server
        confess format_message( '%s (utf8 in %s)', $self->_error( E_MISMATCH_ARG ), $_[1] );
    } else {
        my $try_again;
        my @args = @_;
        RUN_METHOD: {
            try {
                @result = $self->_redis->$method( @args );
            } catch {
                $error = $_;
                $try_again = $self->_redis_exception( $error );
            };

            if ( $try_again && $method eq 'EVALSHA' ) {
                $self->_lua_scripts->{ $_running_script_name } = $args[0];  # sha1
                $args[0] = $_running_script_body;
                $method = 'EVAL';
                redo RUN_METHOD;
            }
        }
    }

    $self->_redis_exception( $error )
        if $error;

    $self->_transaction( 1 )
        if $method eq 'MULTI';
    if ( $method eq 'EXEC' ) {
        $self->_transaction( 0 );
        $result[0] // return;                   # 'WATCH': the transaction is not entered at all
    }

    if ( $method eq 'HGET' and $_[1] =~ /^(workload|result)$/ ) {
        if ( $result[0] ) {
            $result[0] = ${ thaw( $result[0] ) };
            $result[0] = ${ $result[0] } if ref( $result[0] ) eq 'SCALAR';
        }
    }

    return wantarray ? @result : $result[0];
}

sub _wait_used_memory {
    return unless $WAIT_USED_MEMORY;

    my ( $self ) = @_;

    my ( undef, $maxmemory ) = $self->_call_redis( 'CONFIG', 'GET', 'maxmemory' );
    my $sleepped;
    if ( $maxmemory ) {
        my $max_timeout = $self->operation_timeout || DEFAULT_OPERATION_TIMEOUT;
        my $timeout = 0.01;
        $sleepped = 0;
        WAIT_USED_MEMORY: {
            my ( $used_memory ) = $self->_call_redis( 'INFO', 'memory' ) =~ /used_memory:(\d+)/;
            if ( $used_memory < $maxmemory || $sleepped > $max_timeout ) {
                last WAIT_USED_MEMORY;
            }

            Time::HiRes::sleep $timeout;
            $sleepped += $timeout;
#            $self->_redis->connect;
            redo WAIT_USED_MEMORY;
        }
    }

    return $sleepped;
}

sub _reconnect {
    my ( $self ) = @_;

    if ( !$self->_transaction && $self->reconnect_on_error && !$self->ping ) {
        my $err_msg = $self->_do_reconnect;
        $self->_redis_exception( $err_msg )
            if $err_msg;
    }
}

sub _do_reconnect {
    my $self    = shift;
    my $err     = shift // 0;
    my $msg     = shift;

    my $err_msg = '';
    if (
            !$err || (
                   $err != E_MISMATCH_ARG
                && $err != E_DATA_TOO_LARGE
                && $err != E_MAX_MEMORY_LIMIT
                && $err != E_JOB_DELETED
            )
        ) {
        try {
            # NOTE: socket recreated
            $self->_redis->quit;
            $self->_redis->connect;
        } catch {
            my $error = $_;
            $err_msg = "(Not reconnected: $error)";
        };
    }

    if ( $err_msg ) {
        $msg = defined( $msg )
            ? ( $msg ? "$msg " : '' )."($err_msg)"
            : $err_msg;
    }

    return $msg;
}

sub _jkey {
    my $self        = shift;

    local $" = ':';
    return "$NAMESPACE:@_";
}

sub _qkey {
    my $self        = shift;

    local $" = ':';
    return "$NAMESPACE:queue:@_";
}

sub _get_job_id {
    my ( $self, $id_source ) = @_;

    defined( _STRING( $id_source ) ) || _INSTANCE( $id_source, 'Redis::JobQueue::Job' )
        || confess $self->_error( E_MISMATCH_ARG );

    return ref( $id_source ) ? $id_source->id : $id_source;
}

sub _lua_script_cmd {
    my ( $self, $name ) = @_;

    $_running_script_name = $name;
    $_running_script_body = $lua_script_body{ $name };

    my $sha1 = $self->_lua_scripts->{ $_running_script_name };
    unless ( $sha1 ) {
        $sha1 = $self->_lua_scripts->{ $_running_script_name } = sha1_hex( $_running_script_body );
        unless ( ( $self->_call_redis( 'SCRIPT', 'EXISTS', $sha1 ) )[0] ) {
            return( 'EVAL', $_running_script_body );
        }
    }
    return( 'EVALSHA', $sha1 );
}

sub _clear_sha1 {
    my ( $self ) = @_;

    $self->_lua_scripts( {} );

    return;
}

sub _error {
    my ( $self, $error_code ) = @_;

    $self->_set_last_errorcode( $error_code );
    return $self->last_error;
}

#-- Closes and cleans up -------------------------------------------------------

no Mouse::Util::TypeConstraints;
no Mouse;                                       # keywords are removed from the package
__PACKAGE__->meta->make_immutable();

__END__

=head2 DIAGNOSTICS

Use the method to retrieve last error for analysis: L</last_errorcode>.

A L<Redis|Redis> error will cause the program to halt (C<confess>).
In addition to errors in the L<Redis|Redis> module detected errors
L</E_MISMATCH_ARG>, L</E_DATA_TOO_LARGE>, L</E_JOB_DELETED>.
All recognizable errors in C<Redis::JobQueue> lead to
the installation of the corresponding value in the L</last_errorcode> and cause
an exception (C<confess>).
Unidentified errors cause an exception (L</last_errorcode> remains equal to 0).
The initial value of C<$@> is preserved.

The user has the choice:

=over 3

=item *

Use the package methods and independently analyze the situation without the use
of L</last_errorcode>.

=item *

Wrapped code in C<eval {...};> and analyze L</last_errorcode>
(see L</"An Example"> section).

=back

=head2 An Example

This example shows handling for possible errors.

    use 5.010;
    use strict;
    use warnings;

    #-- Common ---------------------------------------------------------------
    use Redis::JobQueue qw(
        DEFAULT_SERVER
        DEFAULT_PORT

        E_NO_ERROR
        E_MISMATCH_ARG
        E_DATA_TOO_LARGE
        E_NETWORK
        E_MAX_MEMORY_LIMIT
        E_JOB_DELETED
        E_REDIS
    );
    use Redis::JobQueue::Job qw(
        STATUS_CREATED
        STATUS_WORKING
        STATUS_COMPLETED
    );

    my $server = DEFAULT_SERVER.':'.DEFAULT_PORT;   # the Redis Server

    # Example of error handling
    sub exception {
        my $jq  = shift;
        my $err = shift;

        if ( $jq->last_errorcode == E_NO_ERROR ) {
            # For example, to ignore
            return unless $err;
        } elsif ( $jq->last_errorcode == E_MISMATCH_ARG ) {
            # Necessary to correct the code
        } elsif ( $jq->last_errorcode == E_DATA_TOO_LARGE ) {
            # You must use the control data length
        } elsif ( $jq->last_errorcode == E_NETWORK ) {
            # For example, sleep
            #sleep 60;
            # and return code to repeat the operation
            #return "to repeat";
        } elsif ( $jq->last_errorcode == E_JOB_DELETED ) {
            # For example, return code to ignore
            my $id = $err =~ /^(\S+)/;
            #return "to ignore $id";
        } elsif ( $jq->last_errorcode == E_REDIS ) {
            # Independently analyze the $err
        } else {
            # Unknown error code
        }
        die $err if $err;
    }

    my $jq;

    eval {
        $jq = Redis::JobQueue->new(
            redis   => $server,
            timeout => 1,   # DEFAULT_TIMEOUT = 0 for an unlimited timeout
        );
    };
    exception( $jq, $@ ) if $@;

    #-- Producer -------------------------------------------------------------
    #-- Adding new job

    my $job;
    eval {
        $job = $jq->add_job(
            {
                queue       => 'xxx',
                workload    => \'Some stuff',
                expire      => 12*60*60,
            }
        );
    };
    exception( $jq, $@ ) if $@;
    say( 'Added job ', $job->id ) if $job;

    eval {
        $job = $jq->add_job(
            {
                queue       => 'yyy',
                workload    => \'Some stuff',
                expire      => 12*60*60,
            }
        );
    };
    exception( $jq, $@ ) if $@;
    say( 'Added job ', $job->id ) if $job;

    #-- Worker ---------------------------------------------------------------

    #-- Run your jobs

    sub xxx {
        my $job = shift;

        my $workload = ${$job->workload};
        # do something with workload;
        say "XXX workload: $workload";

        $job->result( 'XXX JOB result comes here' );
    }

    sub yyy {
        my $job = shift;

        my $workload = ${$job->workload};
        # do something with workload;
        say "YYY workload: $workload";

        $job->result( \'YYY JOB result comes here' );
    }

    eval {
        while ( my $job = $jq->get_next_job(
                queue       => [ 'xxx','yyy' ],
                blocking    => 1,
            ) ) {
            my $id = $job->id;

            my $status = $jq->get_job_data( $id, 'status' );
            say "Job '$id' was '$status' status";

            $job->status( STATUS_WORKING );
            $jq->update_job( $job );

            $status = $jq->get_job_data( $id, 'status' );
            say "Job '$id' has new '$status' status";

            # do my stuff
            if ( $job->queue eq 'xxx' ) {
                xxx( $job );
            } elsif ( $job->queue eq 'yyy' ) {
                yyy( $job );
            }

            $job->status( STATUS_COMPLETED );
            $jq->update_job( $job );

            $status = $jq->get_job_data( $id, 'status' );
            say "Job '$id' has last '$status' status";
        }
    };
    exception( $jq, $@ ) if $@;

    #-- Consumer -------------------------------------------------------------

    #-- Check the job status

    eval {
        # For example:
        # my $status = $jq->get_job_data( $ARGV[0], 'status' );
        # or:
        my @ids = $jq->get_job_ids;

        foreach my $id ( @ids ) {
            my $status = $jq->get_job_data( $id, 'status' );
            say "Job '$id' has '$status' status";
        }
    };
    exception( $jq, $@ ) if $@;

    #-- Fetching the result

    eval {
        # For example:
        # my $id = $ARGV[0];
        # or:
        my @ids = $jq->get_job_ids;

        foreach my $id ( @ids ) {
            my $status = $jq->get_job_data( $id, 'status' );
            say "Job '$id' has '$status' status";

            if ( $status eq STATUS_COMPLETED ) {
                my $job = $jq->load_job( $id );

                # it is now safe to remove it from JobQueue, since it is completed
                $jq->delete_job( $id );

                say 'Job result: ', ${$job->result};
            } else {
                say "Job is not complete, has current '$status' status";
            }
        }
    };
    exception( $jq, $@ ) if $@;

    #-- Closes and cleans up -------------------------------------------------

    eval { $jq->quit };
    exception( $jq, $@ ) if $@;

=head2 JobQueue data structure stored in Redis

The following data structures are stored on Redis server:

    #-- To store the job data:
    # HASH    Namespace:id

For example:

    $ redis-cli
    redis 127.0.0.1:6379> KEYS JobQueue:*
    1) "JobQueue:478B9C84-C5B8-11E1-A2C5-D35E0A986783"
    2) "JobQueue:478C81B2-C5B8-11E1-B5B1-16670A986783"
    3) "JobQueue:89116152-C5BD-11E1-931B-0A690A986783"
    #      |                 |
    #   Namespace            |
    #                     Job id (UUID)
    ...
    redis 127.0.0.1:6379> hgetall JobQueue:478B9C84-C5B8-11E1-A2C5-D35E0A986783
    1) "queue"                                  # hash key
    2) "xxx"                                    # the key value
    3) "job"                                    # hash key
    4) "Some description"                       # the key value
    5) "workload"                               # hash key
    6) "Some stuff"                             # the key value
    7) "expire"                                 # hash key
    8) "43200"                                  # the key value
    9) "status"                                 # hash key
    10) "_created_"                             # the key value
    ...

Each call to L</add_job> or L</update_job> methods renews objects expiration accroding to
L</expire> attribute (seconds).
For example:

    redis 127.0.0.1:6379> TTL JobQueue:478B9C84-C5B8-11E1-A2C5-D35E0A986783
    (integer) 42062

Hash containing job data is deleted when you delete the job
(L</delete_job> method). Job is also removed from the LIST object.

    # -- To store the job queue (the list created but not yet requested jobs):
    # LIST    JobQueue:queue:queue_name:job_name

For example:

    redis 127.0.0.1:6379> KEYS JobQueue:queue:*
    ...
    4) "JobQueue:queue:xxx"
    5) "JobQueue:queue:yyy"
    #      |       |    |
    #   Namespace  |    |
    #    Fixed key word |
    #            Queue name
    ...
    redis 127.0.0.1:6379> LRANGE JobQueue:queue:xxx 0 -1
    1) "478B9C84-C5B8-11E1-A2C5-D35E0A986783 1344070066"
    2) "89116152-C5BD-11E1-931B-0A690A986783 1344070067"
    #                        |                   |
    #                     Job id (UUID)          |
    #                                      Expire time (UTC)
    ...

Job queue data structures are created automatically when job is placed in the queue and
deleted when all jobs are removed from the queue.

=head1 DEPENDENCIES

In order to install and use this package it's recommended to use Perl version
5.010 or later. Some modules within this package depend on other
packages that are distributed separately from Perl. We recommend that
you have the following packages installed before you install C<Redis::JobQueue>
package:

    Data::UUID
    Digest::SHA1
    List::MoreUtils
    Mouse
    Params::Util
    Redis
    Storable

C<Redis::JobQueue> package has the following optional dependencies:

    Net::EmptyPort
    Test::Deep
    Test::Exception
    Test::NoWarnings
    Test::RedisServer

If the optional modules are missing, some "prereq" tests are skipped.

=head1 BUGS AND LIMITATIONS

By design C<Redis::JobQueue> uses freeze before storing job data on Redis
(L<workload|Redis::JobQueue::Job/workload>, L<result|Redis::JobQueue::Job/result> containers and the custom-named fields).
This ensures that among other things, UTF8-encoded strings are safe when passed this way.
The other main string job data fields (L<id|Redis::JobQueue::Job/id>, L<queue|Redis::JobQueue::Job/queue>, L<job|Redis::JobQueue::Job/job>, L<status|Redis::JobQueue::Job/status>, L<message|Redis::JobQueue::Job/message>)
are not processed in any way and passed to L<Redis|Redis> as-is.
They are designed as an easy and fast way for software developer to store some internal / supplemental
data among job details.

For the main string job data fields (L<id|Redis::JobQueue::Job/id>, L<queue|Redis::JobQueue::Job/queue>, L<job|Redis::JobQueue::Job/job>, L<status|Redis::JobQueue::Job/status>, L<message|Redis::JobQueue::Job/message>)
you can do one of the following:

=over 3

=item *

forcefully downgrade string to ASCII (see perldoc L<utf8|utf8>) before attempting
to pass it to C<Redis::JobQueue>

=item *

use freeze (L<Storable|Storable>) before passing it to C<Redis::JobQueue>

=item *

store such string as part of L<workload|Redis::JobQueue::Job/workload> / L<result|Redis::JobQueue::Job/result> data structures

=back

Needs Redis server version 2.8 or higher as module uses Redis Lua scripting.

The use of C<maxmemory-policy all*> in the F<redis.conf> file could lead to
a serious (but hard to detect) problem as Redis server may delete
the job queue objects.

It may not be possible to use this module with the cluster of Redis servers
because full name of some Redis keys may not be known at the time of the call
to Lua script (C<'EVAL'> or C<'EVALSHA'> command). Redis server may not be able
to forward the request to the appropriate node in the cluster.

We strongly recommend using of C<maxmemory> option in the F<redis.conf> file if
the data set may be large.

WARN: Not use C<maxmemory> less than for example 70mb (60 connections) for avoid 'used_memory > maxmemory' problem.

The C<Redis::JobQueue> package was written, tested, and found working on recent
Linux distributions.

There are no known bugs in this package.

Please report problems to the L</"AUTHOR">.

Patches are welcome.

=head1 MORE DOCUMENTATION

All modules contain detailed information on the interfaces they provide.

=head1 SEE ALSO

The basic operation of the C<Redis::JobQueue> package modules:

L<Redis::JobQueue|Redis::JobQueue> - Object interface for creating and
executing jobs queues, as well as monitoring the status and results of jobs.

L<Redis::JobQueue::Job|Redis::JobQueue::Job> - Object interface for creating
and manipulating jobs.

L<Redis::JobQueue::Util|Redis::JobQueue::Util> - String manipulation utilities.

L<Redis|Redis> - Perl binding for Redis database.

=head1 SOURCE CODE

Redis::JobQueue is hosted on GitHub:
L<https://github.com/TrackingSoft/Redis-JobQueue>

=head1 AUTHOR

Sergey Gladkov, E<lt>sgladkov@trackingsoft.comE<gt>

Please use GitHub project link above to report problems or contact authors.

=head1 CONTRIBUTORS

Alexander Solovey

Jeremy Jordan

Sergiy Zuban

Vlad Marchenko

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2016 by TrackingSoft LLC.

This package is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See I<perlartistic> at
L<http://dev.perl.org/licenses/artistic.html>.

This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
