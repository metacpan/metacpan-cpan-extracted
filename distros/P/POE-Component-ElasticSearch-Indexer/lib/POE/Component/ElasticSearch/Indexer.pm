package POE::Component::ElasticSearch::Indexer;
# ABSTRACT: POE session to index data to ElasticSearch

use strict;
use warnings;

our $VERSION = '0.011'; # VERSION

use Const::Fast;
use Digest::SHA1 qw(sha1_hex);
use Fcntl qw(:flock);
use HTTP::Request;
use JSON::MaybeXS;
use List::Util qw(shuffle);
use Log::Log4perl qw(:easy);
use Path::Tiny;
use POSIX qw(strftime);
use Ref::Util qw(is_ref is_arrayref is_blessed_ref is_hashref is_coderef);
use Time::HiRes qw(time);
use URI;

use POE qw(
    Component::Client::HTTP
    Component::Client::Keepalive
);


sub spawn {
    my $type = shift;
    my %params = @_;

    # Setup Logging
    my $loggingConfig = exists $params{LoggingConfig} && -f $params{LoggingConfig} ? $params{LoggingConfig}
                      : \q{
                            log4perl.logger = DEBUG, Sync
                            log4perl.appender.File = Log::Log4perl::Appender::File
                            log4perl.appender.File.layout   = PatternLayout
                            log4perl.appender.File.layout.ConversionPattern = %d [%P] %p - %m%n
                            log4perl.appender.File.filename = es_indexer.log
                            log4perl.appender.File.mode = truncate
                            log4perl.appender.Sync = Log::Log4perl::Appender::Synchronized
                            log4perl.appender.Sync.appender = File
                        };
    Log::Log4perl->init($loggingConfig) unless Log::Log4perl->initialized;

    # Build Configuration
    my %CONFIG = (
        Alias              => 'es',
        Servers            => [qw(localhost)],
        Timeout            => 5,
        FlushInterval      => 30,
        FlushSize          => 1_000,
        DefaultIndex       => 'logs-%Y.%m.%d',
        DefaultType        => 'log',
        BatchDir           => '/tmp/es_index_backlog',
        StatsInterval      => 60,
        BacklogInterval    => 60,
        CleanupInterval    => 60,
        PoolConnections    => 1,
        KeepAliveTimeout   => 2,
        MaxConnsPerServer  => 3,
        MaxPendingRequests => 5,
        MaxRecoveryBatches => 10,
        MaxFailedRatio     => 0.8,
        %params,
    );
    if( $CONFIG{BatchDiskSpace} ) {
        # Human Readable to Computer Readable
        if( my ($size,$unit) = ($CONFIG{BatchDiskSpace} =~ /(\d+(?:\.\d+)?)\s*([kmgt])b?/i) ) {
            $unit = lc $unit;
            $CONFIG{BatchDiskSpace} = $unit eq 'k' ? $size * 1_000
                                    : $unit eq 'm' ? $size * 1_000_000
                                    : $unit eq 'g' ? $size * 1_000_000_000
                                    : $unit eq 't' ? $size * 1_000_000_000_000
                                    : $size;
        }
        else {
            WARN("Disabling cleanup due to bad argument for BatchDiskSpace: '$CONFIG{BatchDiskSpace}', see try something like: 2gb or see docs");
            delete $CONFIG{BatchDiskSpace};
        }
    }
    if( $CONFIG{MaxFailedRatio} > 1 ) {
        WARN("Attempt to set MaxFailedRatio to a number greater than 1, reset to default 0.8");
        $CONFIG{MaxFailedRatio} = 0.8;
    }

    # Management Session
    my $session = POE::Session->create(
        inline_states => {
            _start    => \&_start,
            _child    => \&_child,
            stats     => \&_stats,
            queue     => \&es_queue,
            flush     => \&es_flush,
            batch     => \&es_batch,
            save      => \&es_save,
            backlog   => \&es_backlog,
            cleanup   => \&es_cleanup,
            shutdown  => \&es_shutdown,
            #health    => \&es_health,

            # HTTP Responses
            resp_bulk          => \&resp_bulk,
            #resp_health        => \&resp_health,
        },
        heap => {
            cfg       => \%CONFIG,
            stats     => {},
            start     => {},
            batch     => {},
            health    => '',
            es_ready  => 0,
        },
    );

    # Connection Pooling
    my $num_servers  = scalar( @{ $CONFIG{Servers} } );
    $CONFIG{MaxConnsTotal} ||= $num_servers * $CONFIG{MaxConnsPerServer};
    my $pool = $CONFIG{PoolConnections} ? POE::Component::Client::Keepalive->new(
        keep_alive   => $CONFIG{KeepAliveTimeout},
        max_open     => $CONFIG{MaxConnsTotal},
        max_per_host => $CONFIG{MaxConnsPerServer},
        timeout      => $CONFIG{Timeout},
    ) : undef;

    my $http_timeout = $pool ? $CONFIG{Timeout} * $CONFIG{MaxConnsPerServer} : $CONFIG{Timeout};
    POE::Component::Client::HTTP->spawn(
        Alias   => 'http',
        Timeout => $http_timeout,
        # Are we using Connection Pooling?
        $pool ? (ConnectionManager => $pool)  : (),
    );
    DEBUG(sprintf "Spawned an HTTP %s for %d servers, %s.",
        $CONFIG{PoolConnections} ? 'pool' : 'session',
        $num_servers,
        $CONFIG{PoolConnections} ?
            sprintf("%d max connections, %d max per host", @CONFIG{qw(MaxConnsTotal MaxConnsPerServer)})
            : 'pooling disabled',
    );
    return $session;
}

#------------------------------------------------------------------------#
# ES Functions

sub _start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Set our alias
    $kernel->alias_set($heap->{cfg}{Alias});

    # Set the interval / maximum
    my $adjuster = (1 + (int(rand(10))/20));
    $heap->{cfg}{FlushSize}     *= $adjuster;
    $heap->{cfg}{FlushInterval} *= $adjuster;

    # Batch directory
    path($heap->{cfg}{BatchDir})->mkpath;

    # Run through the backlog
    $kernel->delay( backlog => 2 );
    $heap->{backlog_scheduled} = 1;

    # For now, we just state we're ready
    $heap->{es_ready} = 1;

    # Schedule Statistics Run
    $kernel->delay( stats => $heap->{cfg}{StatsInterval} );
}

sub _child {
    my ($kernel,$heap,$reason,$child) = @_[KERNEL,HEAP,ARG0,ARG1];
    DEBUG(sprintf "child(%s) event: %s", $child->ID, $reason);
}

sub _stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP,ARG0,ARG1];

    # Reschedule
    $kernel->delay( stats => $heap->{cfg}{StatsInterval} )
        unless $heap->{SHUTDOWN};

    # Extract the stats from the heap
    my $stats = delete $heap->{stats};
    $heap->{stats} = {};

    # Compute Succes/Fail Ratio
    my $success = $stats->{bulk_success} || 0;
    my $failure = $stats->{bulk_failure} || 0;

    # Fetch the pending request count from the HTTP client
    $stats->{pending_requests} = $kernel->call( http => 'pending_requests_count' );

    # We tried stuff this go around
    if( $success >= 0 && $failure == 0 ) {
        $heap->{es_ready} = 1;
    }
    else {
        # Calculate how much we failed
        my $ratio  = sprintf "%0.3f", $failure / ($success + $failure);
        # Check and set readiness
        $heap->{es_ready} =  $stats->{pending_requests} < $heap->{cfg}{MaxPendingRequests}
                          && $ratio < $heap->{cfg}{MaxFailedRatio};
    }



    # Display our stats
    if( is_coderef($heap->{cfg}{StatsHandler}) ) {
        # Run in an eval and remove the handler if the code dies
        eval {
            $heap->{cfg}{StatsHandler}->($stats);
            1;
        } or do {
            my $err = $@;
            ERROR("Disabling the StatsHandler due to fatal error: $!");
            $heap->{stats}{StatsHandler} = undef;
        };
    }
    # Also output at TRACE level
    TRACE( "STATS - " .
        scalar(keys %$stats) ? join(', ', map { "$_=$stats->{$_}" } sort keys %$stats )
                             : 'Nothing to report.'
    );
}


sub es_queue {
    my ($kernel,$heap,$data) = @_[KERNEL,HEAP,ARG0];

    return unless $data;

    my $events = is_arrayref($data) ? $data : [$data];
    $heap->{queue} ||= [];
    DOC: foreach my $doc ( @{ $events } ) {
        my $record;
        if( is_blessed_ref($doc) ) {
            eval {
                $record = $doc->as_bulk();
                1;
            } or do {
                $heap->{stats}{queue_blessed_fail} ||= 0;
                $heap->{stats}{queue_blessed_fail}++;
                next DOC;
            };
        }
        elsif( is_hashref($doc) ) {
            # Assemble Metadata
            my $epoch = $doc->{_epoch} ? delete $doc->{_epoch} : time;
            my $index = $doc->{_index} ? delete $doc->{_index} : $heap->{cfg}{DefaultIndex};
            my %meta = (
                _index => index($index,'%') >= 0 ? strftime($index,localtime($epoch)) : $index,
                _type  => $doc->{_type}  ? delete $doc->{_type}  : $heap->{cfg}{DefaultType},
                $doc->{_id} ? ( _id => delete $doc->{_id} ) : (),
            );
            $record = sprintf("%s\n%s\n",
                encode_json({ index => \%meta }),
                encode_json($doc),
            );
        }
        elsif( !is_ref($doc) ) {
            $record = $doc;
        }
        else {
            $heap->{stats}{queue_bad_input} ||= 0;
            $heap->{stats}{queue_bad_input}++;
        }
        # Ensure we wound up with something useful
        next unless $record;
        push @{ $heap->{queue} }, $record;
    }

    my $queue_size = scalar(@{ $heap->{queue} });
    if ( exists $heap->{cfg}{FlushSize} && $heap->{cfg}{FlushSize} > 0
            && $queue_size >= $heap->{cfg}{FlushSize}
            && !exists $heap->{force_flush}
    ) {
        TRACE("Queue size target exceeded, flushing queue ". $heap->{cfg}{FlushSize} . " max, size is $queue_size" );
        $heap->{force_flush} = 1;
        $kernel->yield( 'flush' );
    }
    elsif( $queue_size ) {
        $kernel->delay_add( flush => $heap->{cfg}{FlushInterval} );
    }
}


sub es_flush {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Remove the scheduler bit for this event
    $kernel->delay('flush');

    my $count_docs = exists $heap->{queue} && is_arrayref($heap->{queue}) ? scalar(@{ $heap->{queue} }) : 0;
    my $reason     = exists $heap->{force_flush} && delete $heap->{force_flush} ? 'force' : 'schedule';

    # Record the flush
    $heap->{stats}{"es_flush_$reason"} ||= 0;
    $heap->{stats}{"es_flush_$reason"}++;

    if( $count_docs > 0 ) {
        # Build the batch
        my $to    = $heap->{es_ready} ? 'batch' : 'save';
        my $docs  = delete $heap->{queue};
        my $batch = join '', @{ $docs };
        my $id    = sha1_hex($batch);
        $heap->{batch}{$id} = $batch;

        DEBUG(sprintf "es_flush(%s) of %d documents to %s, id=%s",
            $reason,
            $count_docs,
            $to,
            $id,
        );
        $kernel->yield( $to => $id );
    }
}


sub es_backlog {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    delete $heap->{backlog_scheduled};

    my $max_batches = $heap->{cfg}{MaxRecoveryBatches};
    my $batch_dir = path($heap->{cfg}{BatchDir});

    # randomize
    my @ids = shuffle map { $_->basename('.batch') }
                $batch_dir->children( qr/\.batch$/ );
    $kernel->yield( batch => $_ ) for @ids[0..$max_batches-1];

    if(@ids > $max_batches) {
        $kernel->delay( backlog => $heap->{cfg}{BacklogInterval}) unless $heap->{SHUTDOWN};
        $heap->{backlog_scheduled} = 1;
    }
}


sub es_shutdown {
    $_[HEAP]->{SHUTDOWN} = 1;
    FATAL("es_shutdown() - Shutting down.");
}


sub es_batch {
    my  ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];

    return unless defined $id;

    # Only process if we're ready
    if( !$heap->{es_ready} ) {
        # Flush this batch to disk
        $kernel->yield( save => $id )
            if exists $heap->{batch}{$id};

        # Bail and rely on the disk backlog
        return;
    }

    # Get our content
    my $batch = '';
    if( exists $heap->{batch}{$id} ) {
        $batch = delete $heap->{batch}{$id};
    }
    else {
        # Read batch from disk
        my $batch_file = path($heap->{cfg}{BatchDir})->child($id . '.batch');
        if( $batch_file->is_file ) {
            # We need exclusive locking so we can brute force a batch
            # directory in a batch cleanup mode
            my $locked = lock_batch_file($batch_file);
            if( defined $locked && $locked == 1 ) {
                $batch = $batch_file->slurp_raw;
                my $lines = $batch =~ tr/\n//;
                if( $lines > 0 ) {
                    $heap->{stats}{consumed} ||= 0;
                    $heap->{stats}{consumed} += int($lines / 2);
                }
            }
        }
        else {
            WARN(sprintf "es_batch(%s) called for an unknown batch.", $id);
        }
    }
    return unless length $batch;

    # Build the URI
    my ($server,$port) = split /\:/, $heap->{cfg}{Servers}[int rand scalar @{$heap->{cfg}{Servers}}];
    my $uri = URI->new();
        $uri->scheme('http');
        $uri->host($server);
        $uri->port($port || 9200);
        $uri->path('/_bulk');

    # Build the request
    my $req = HTTP::Request->new(POST => $uri->as_string);
    $req->header('Content-Type', 'application/x-ndjson');
    $req->content($batch);

    TRACE(sprintf "Bulk update of %d bytes being attempted to %s as %s.",
        length($batch),
        $uri->as_string,
        $id,
    );
    $kernel->post( http => request => resp_bulk => $req => $id );
    # Record the request
    $heap->{start}{$id} = time unless exists $heap->{start}{$id};
    $heap->{stats}{http_req} ||= 0;
    $heap->{stats}{http_req}++;
}


sub resp_bulk {
    my ($kernel,$heap,$params,$resp) = @_[KERNEL,HEAP,ARG0,ARG1];

    my $req  = $params->[0];  # HTTP::Request Object
    my $id   = $params->[1];  # Batch ID
    my $r    = $resp->[0];    # HTTP::Response Object
    my $duration = exists $heap->{start}{$id} ? time - $heap->{start}{$id} : undef;

    # We might need to batch things
    my $batch_file = path($heap->{cfg}{BatchDir})->child($id . '.batch');
    TRACE(sprintf "bulk_resp(%s) %s", $id, $r->status_line);

    # Record the responses we receive
    my $resp_key = "bulk_" . ($r->is_success ? 'success' : 'failure');
    $heap->{stats}{$resp_key} ||= 0;
    $heap->{stats}{$resp_key}++;

    if( $r->is_success ) {
        my $details;
        eval {
            $details = decode_json($r->content);
        };
        if( defined $details && ref $details eq 'HASH' ) {
            DEBUG(sprintf "bulk_resp(%s) size was %d bytes for %d items, took %d ms (elapsed:%0.3fs)%s",
                $id,
                length($req->content),
                scalar(@{$details->{items}}),
                $details->{took},
                $duration,
                $details->{errors} ? ' with errors' : '',
            );
            $heap->{stats}{indexed} ||= 0;
            $heap->{stats}{indexed} += scalar@{ $details->{items} };
            if( exists $details->{errors} && $details->{errors} ) {
                $heap->{stats}{errors} ||= 0;
                $heap->{stats}{errors} += scalar grep { exists $_->{create} && exists $_->{create}{error} } @{ $details->{items} };
            }
        }
        else {
            WARN(sprintf "bulk_resp(%s) size was %d bytes, (elapsed:%0.3fs) but not valid JSON: %s",
                $id,
                length($req->content),
                $duration,
                $@,
            );
        }
        # Remove the batch file
        $batch_file->remove if $batch_file->is_file;
        # Clear the start time
        delete $heap->{start}{$id};
        # This should never happen, but if it does, protect us from memory leaks
        delete $heap->{batch}{$id} if exists $heap->{batch}{$id};
    }
    elsif( !$batch_file->is_file ) {
        # Reload the batch into the heap
        $heap->{batch}{$id} = $req->content;
        # Write batch to disk
        $kernel->yield( save => $id );
    }
    else {
        # Make sure we consider running the cleanup
        $kernel->yield( 'cleanup' ) unless $heap->{cleanup_scheduled};
    }
    # Remove the lock
    unlock_batch_file($batch_file);
}


sub es_save {
    my ($kernel,$heap,$id) = @_[KERNEL,HEAP,ARG0];

    return unless exists $heap->{batch}{$id};

    my $content    = delete $heap->{batch}{$id};
    my $batch_file = path($heap->{cfg}{BatchDir})->child($id . '.batch');
    my $duration   = exists $heap->{start}{$id} ? time - $heap->{start}{$id} : 0;

    # Write batch to disk, unless it exists.
    unless( $batch_file->is_file ) {
        my $lines = $content =~ tr/\n//;
        my $items = int( $lines / 2 );
        DEBUG(sprintf "Storing to File Batch[%s] as %d bytes, %d items. (elapsed:%0.3fs)",
                $id, length($content), $items, $duration
        );
        $batch_file->spew_raw($content);
        $heap->{stats}{batches} ||= 0;
        $heap->{stats}{batches}++;
        $heap->{stats}{backlogged} ||= 0;
        $heap->{stats}{backlogged} += $items;
    }
    unless( $heap->{backlog_scheduled} ) {
        $kernel->delay( backlog => $heap->{cfg}{BacklogInterval} ) unless $heap->{SHUTDOWN};
        $heap->{backlog_scheduled} = 1;
    }
}


sub es_cleanup {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Only run if we need to run
    return unless $heap->{cfg}{BatchDiskSpace};
    # Rerun the cleanup
    delete $heap->{cleanup_scheduled};

    my $total = 0;
    my $batch_dir = path($heap->{cfg}{BatchDir});
    my @files = ();

    # Check our total size
    $batch_dir->visit(sub {
        my $p = shift;

        # Skip unless it's a batch file
        return unless $p->basename =~ /\.batch$/;

        # Figure out the size of our batches
        # We eval() in case another worker deletes the file
        eval {
            my $size = $p->stat->size;
            my $ctime = $p->stat->ctime;
            die "Invalid size: $size" unless $size > 0;
            $total += $size;
            push @files, {
                path  => $p,
                size  => $size,
                ctime => $ctime,
            };
            1;
        } or do {
            my $err = $@;
            # Yes this is an error, but we don't want it spamming the logs because it's
            # not that important.  We log at DEBUG.
            DEBUG(sprintf "Error checking status of %s: %s", $p->basename, $err)
                if $err =~ /Invalid size/;
        };
    });

    # Report words
    DEBUG("es_cleanup(): BatchDiskSpace is '$heap->{cfg}{BatchDiskSpace}', currently $total bytes");

    # Delete some stuff
    if( $total > $heap->{cfg}{BatchDiskSpace} ) {
        # Sort oldest to newest
        foreach my $batch ( sort { $a->{ctime} <=> $b->{ctime} } @files ) {
            # Leave early, leave often
            last if $total < $heap->{cfg}{BatchDiskSpace};
            # Handle "we can't get lock"
            if( ! lock_batch_file($batch->{path}) ) {
                # If we're not the only worker, maybe someone else removed this
                $total -= $batch->{size} unless $batch->{path}->is_file;
                next;
            }
            # Otherwise, mop up
            my $state = 'success';
            eval {
                # If we fail, it's because something else delete this file
                $batch->{path}->remove;
                1;
            } or do {
                my $err = $@;
                WARN(sprintf "es_cleanup() failed removing %s: %s",
                    $batch->{path}->absolute->stringify,
                    $err,
                );
                $state = 'fail';
            };
            $heap->{stats}{"cleanup_$state"} ||= 0;
            $heap->{stats}{"cleanup_$state"}++;

            unlock_batch_file($batch->{path});
            $total -= $batch->{size};
        }
    }
    if( $total > 0 ) {
        $kernel->delay( cleanup => $heap->{cfg}{CleanupInterval} ) unless $heap->{SHUTDOWN};
        $heap->{cleanup_scheduled} = 1;
    }
}

# Closure for Locks
{
    my %_lock = ();


    sub lock_batch_file {
        my $batch_file = shift;
        my $lock_file = path($batch_file->absolute . '.lock');
        my $id = $lock_file->absolute;

        my $locked = 0;
        # We need to try to lock, but Path::Tiny doesn't support exclusive locks on
        # read operations, so we'll handle that with a lock file.
        if( !exists $_lock{$id} ) {
            $locked = eval {
                open $_lock{$id}, '>', $id or die "Cannot create lock file: $!\n";
                flock($_lock{$id}, LOCK_EX|LOCK_NB) or die "Unable to attain exclusive lock.";
                1;
            };
            if(!defined $locked) {
                TRACE(sprintf "lock_batch_file(%s) failed: %s", $id, $@);
            }
        }
        return $locked;
    }


    sub unlock_batch_file {
        my $batch_file = shift;
        my $lock_file = path($batch_file->absolute . '.lock');
        my $id = $lock_file->absolute;

        if(exists $_lock{$id}) {
            eval {
                flock($_lock{$id}, LOCK_UN);
                1;
            } or do {
                WARN(sprintf "unlock_batch_file(%s) failed: %s, removing file anyways.", $id, $@);
            };
            close( delete $_lock{$id} );
            $lock_file->remove if $lock_file->is_file;
        }
    }
}

# Return True
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

POE::Component::ElasticSearch::Indexer - POE session to index data to ElasticSearch

=head1 VERSION

version 0.011

=head1 SYNOPSIS

This POE Session is used to index data to an ElasticSearch cluster.

    use POE qw{ Component::ElasticSearch::Indexer };

    my $es_session = POE::Component::ElasticSearch::Indexer->spawn(
        Alias            => 'es',                    # Default
        Servers          => [qw(localhost)],         # Default
        Timeout          => 5,                       # Default
        FlushInterval    => 30,                      # Default
        FlushSize        => 1_000,                   # Default
        LoggingConfig    => undef,                   # Default
        DefaultIndex     => 'logs-%Y.%m.%d',         # Default
        DefaultType      => 'log',                   # Default
        BatchDir         => '/tmp/es_index_backlog', # Default
        BatchDiskSpace   => undef,                   # Default
        StatsHandler     => undef,                   # Default
        StatsInterval    => 60,                      # Default
    );

    # Index the document using the queue for better performance
    $poe_kernel->post( es => queue => $json_data );

=head1 DESCRIPTION

This module exists to provide event-based Perl programs with a simple way to
index documents into an ElasticSearch cluster.

=head2 spawn()

This method spawns the ElasticSearch indexing L<POE::Session>. It accepts the
following parameters.

=over 4

=item B<Alias>

The alias this session is available to other sessions as.  The default is
B<es>.

=item B<Servers>

A list of Elasticsearch hosts for connections.  Maybe in the form of
C<hostname> or C<hostname:port>.

=item B<PoolConnections>

Boolean, default true.  Enable connection pooling with
L<POE::Component::Client::Keepalive>.  This is desirable in most cases, but can
result in timeouts piling up.  You may wish to disable this if you notice that
indexing takes a while to recover after timeout events.

=item B<KeepAliveTimeout>

Requires C<PoolConnections>.

Set the keep_alive timeout in seconds for the creation of a
L<POE::Component::Client::Keepalive> connection pool.

Defaults to B<2>.

=item B<MaxConnsPerServer>

Requires C<PoolConnections>.

Maximum number of simultaneous connections to an Elasticsearch node.  Used in
the creation of a L<POE::Component::Client::Keepalive> connection pool.

Defaults to B<3>.

=item B<MaxConnsTotal>

Requires C<PoolConnections>.

Maximum number of simultaneous connections to all servers.  Used in
the creation of a L<POE::Component::Client::Keepalive> connection pool.

Defaults to B<MaxConnsPerServer * number of Servers>.

=item B<MaxPendingRequests>

Requires C<PoolConnections>.

Maximum number of requests backlogged in the connection pool.  Defaults to B<5>.

=item B<MaxFailedRatio>

A number between 0 and 1 representing a percentage of bulk requests that can
fail before we back off the cluster for the B<StatsInterval>.  This is
calculated every B<StatsInterval>.  The default is B<0.8> or 80%.

=item B<LoggingConfig>

The L<Log::Log4perl> configuration file for the indexer to use.  Defaults to
writing logs to the current directory into the file C<es_indexing.log>.

=item B<Timeout>

Number of seconds for the HTTP transport connect and transport timeouts.
Defaults to B<5> seconds.  The total request timeout, waiting for an open
connection slot and then completing the request, will be this multiplied by 2.

=item B<FlushInterval>

Maximum number of seconds which can pass before a flush of the queue is
attempted.  Defaults to B<30> seconds.

=item B<FlushSize>

Once this number of documents is reached, flush the queue regardless of time
since the last flush.  Defaults to B<1,000>.

=item B<DefaultIndex>

A C<strftime> aware index pattern to use if the document is missing an
C<_index> element.  Defaults to B<logs-%Y.%m.%d>.

=item B<DefaultType>

Use this C<_type> attribute if the document is missing one.  Defaults to
B<log>.

=item B<BatchDir>

If the cluster responds with an HTTP failure code, the batch is written to disk
in this directory to be indexed when the cluster is available again.  Defaults
to C</tmp/es_index_backlog>.

=item B<BatchDiskSpace>

Defaults to undef, which means disk space isn't checked.  If set, if the batch
size goes over this limit, every new batch saved will delete the oldest batch.
Checked every ten batches.

You may specify either as absolute bytes or using shortcuts:

    BatchDiskSpace => 500kb,
    BatchDiskSpace => 100mb,
    BatchDiskSpace => 10gb,
    BatchDiskSpace => 1tb,

=item B<MaxRecoveryBatches>

The number of batches to process per backlog event.  This will only come into
play if there are batches on disk to flush.  Defaults to B<10>.

=item B<StatsHandler>

A code reference that will be passed a hash reference containing the keys and
values of counters tracked by this component.  Defaults to C<undef>, meaning no
code is run.

=item B<StatsInterval>

Run the C<StatsHandler> every C<StatsInterval> seconds.  Default to B<60>.

=item B<BacklogInterval>

Run the backlog processing event  every C<BacklogInterval> seconds.  Default to B<60>.
Will process up to C<MaxRecoveryBatches> batches per C<BacklogInterval>.

This event only fires when there are batches on disk.  When it's done
processing them, it will then stop firing.

=item B<CleanupInterval>

Run the cleanup event  every C<CleanupInterval> seconds.  Default to B<60>.
This will check to ensure the C<BatchDiskSpace> is honored and delete the
oldest batches if that is exceeded.

This event only fires when there are batches on disk.

=back

=head2 EVENTS

The events provided by this component.

=over 2

=item B<queue>

Takes an array reference of hash references to be transformed into JSON
documents and submitted to the cluster's C<_bulk> API.

Each hash reference may pass in the following special keys, which will be used
to index the event.  These keys will be deleted from the document being indexed
as they have special meaning to the C<bulk> API.

=over 2

=item B<_id>

Will be submitted as the document id in the bulk operation, if not specified,
Elasticsearch will generate a UUID for each document automatically.

=item B<_type>

Will be submitted as the document type in the bulk operation, if not specified,
we'll use the C<DefaultType> specified in the C<spawn()> method.

=item B<_index>

Will cause the document to be indexed into that index, if not specified, the
C<DefaultIndex> will be used.

=item B<_epoch>

If the C<DefaultIndex> uses a C<strftime> compatible string, you may specify an
C<_epoch> in every document.  If not specified, we'll assume the epoch to use
for C<strftime> calculations is the current time.

=back

For more information, see the L<Elasticsearch Bulk API Docs|https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-bulk.html>.

Alternatively, you can provide an array reference containing blessed objects that
provide an C<as_bulk()> method.  The result of that method will be added to the
bulk queue.

If you've decided to construct the requisite newline delimited JSON yourself,
you may pass in an array reference containing scalars.  If you do, the module
assumes you know what you're doing and will append that text to the existing
bulk queue unchanged.

Example use case:

    sub syslog_handle_line {
        my ($kernel,$heap,$session,$line) = @_[KERNEL,HEAP,SESSION,ARG0];

        # Create a document from syslog data
        local $Parse::Syslog::Line::PruneRaw = 1;
        local $Parse::Syslog::Line::PruneEmpty = 1;
        my $evt = parse_syslog_line($line);

        # Override the type
        $evt->{_type} = 'syslog';

        # If we want to collect this event into an auth index:
        if( exists $Authentication{$evt->{program}} ) {
            $evt->{_index} = strftime('authentication-%Y.%m.%d',
                    localtime($evt->{epoch} || time)
            );
        }
        else {
            # Set an _epoch for the es queue DefaultIndex
            $evt->{_epoch} = $evt->{epoch} ? delete $evt->{epoch} : time;
        }
        # You'll want to batch these in your processor to avoid excess
        # overhead creating so many events in the POE loop
        push @{ $heap->{batch} }, $evt;

        # Once we hit 10 messages, force the flush
        $kernel->call( $session->ID => 'submit_batch') if @{ $heap->{batch} } > 10;
    }

    sub submit_batch {
        my ($kernel,$heap) = @_[KERNEL,HEAP];

        # Reset the batch scheduler
        $kernel->delay( 'submit_batch' => 10 );

        $kernel->post( es => queue => delete $heap->{batch} );
        $heap->{batch} = [];
    }

=for Pod::Coverage es_queue

=item B<flush>

Schedule a flush of the existing bulk updates to the cluster.  It should never
be necessary to call this event unless you'd like to shutdown the event loop
faster.

=for Pod::Coverage es_flush

=item B<backlog>

Request the disk-based backlog be processed.  You should never need to call
this event as the session will run it once it starts and if there's  data to
process, it will continue rescheduling as needed.  When a bulk operation fails
resulting in a batch file, this event is scheduled to run again.

=for Pod::Coverage es_backlog

=item B<shutdown>

Inform this session that you'd like to wrap up operations.  This prevents recurring events from being scheduled.

=for Pod::Coverage es_shutdown

=for Pod::Coverage es_batch

=back

=for Pod::Coverage resp_bulk

=for Pod::Coverage es_save

=for Pod::Coverage es_cleanup

=for Pod::Coverage lock_batch_file

=for Pod::Coverage unlock_batch_file

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/POE-Component-ElasticSearch-Indexer>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=POE-Component-ElasticSearch-Indexer>

=back

=head2 Source Code

This module's source code is available by visiting:
L<https://github.com/reyjrar/POE-Component-ElasticSearch-Indexer>

=cut
