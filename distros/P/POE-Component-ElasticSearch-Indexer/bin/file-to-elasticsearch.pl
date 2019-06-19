#!perl
# PODNAME: file-to-elasticsearch.pl
# ABSTRACT: A simple utility to tail a file and index each line as a document in ElasticSearch
use strict;
use warnings;

use Getopt::Long::Descriptive qw(describe_options);
use Hash::Merge::Simple qw(merge);
use JSON::MaybeXS qw(decode_json encode_json);
use Log::Log4perl qw(:easy);
use Module::Load qw(load);
use Module::Loaded qw(is_loaded);
use Pod::Usage;
use Ref::Util qw(is_arrayref is_hashref);
use YAML ();

sub POE::Kernel::ASSERT_DEFAULT { 1 }
use POE qw(
    Component::ElasticSearch::Indexer
    Wheel::FollowTail
);

my %DEFAULT = (
    config => '/etc/file-to-elasticsearch.yaml',
    stats_interval => 60,
);

my ($opt,$usage) = describe_options('%c %o',
    ['config|c:s', "Config file, default: $DEFAULT{config}",
        { default => $DEFAULT{config}, callbacks => { "must be a readable file" => sub { -r $_[0] } } }
    ],
    ['log4perl-config|L:s', "Log4perl Configuration to use, defaults to STDERR",
        { callbacks => { "must be a readable file" => sub { -r $_[0] } } }
    ],
    ['stats-interval|s:i', "Seconds between displaying statistics, default: $DEFAULT{stats_interval}",
        { default => $DEFAULT{stats_interval} },
    ],
    ['debug',       "Enable most verbose output" ],
    [],
    ['help',       "Display this help.", { shortcircuit => 1 }],
    ['manual|pod', "Display the user manaul.", { shortcircuit => 1 }],
);

if( $opt->help ) {
    print $usage->text;
    exit 0;
}
pod2usage( -verbose => 2, -exitval => 0 ) if $opt->manual;

my $config = YAML::LoadFile( $opt->config );

# Initialize Logging
my $level = $opt->debug ? 'TRACE' : 'DEBUG';
my $loggingConfig = $opt->log4perl_config || \qq{
    log4perl.logger = $level, Screen
    log4perl.appender.Screen = Log::Log4perl::Appender::ScreenColoredLevels
    log4perl.appender.Screen.layout   = PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d [%P] %p - %m%n
};
Log::Log4perl->init($loggingConfig);

my $main = POE::Session->create(
    inline_states => {
       _start => \&main_start,
       _stop  => \&main_stop,
       _child => \&main_child,
       stats  => \&main_stats,

       got_new_line     => \&got_new_line,
       get_error        => \&got_error,
       log4perl_refresh => \&log4perl_refresh,
    },
    heap => {
        config => $config,
        stats  => {},
    },
);

POE::Kernel->run();
exit 0;

sub main_start {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    my $config = $heap->{config};
    my %defaults = (
        interval => 5,
        index    => 'files-%Y.%m.%d',
        type     => 'log',
    );

    my $files = 0;
    foreach my $tail ( @{ $config->{tail} } ) {
        if( -r $tail->{file} ) {
            my $wheel = POE::Wheel::FollowTail->new(
                Filename     => $tail->{file},
                InputEvent   => 'got_new_line',
                ErrorEvent   => 'got_error',
                PollInterval => $tail->{interval} || $defaults{interval},
            );
            $heap->{wheels}{$wheel->ID} = $wheel;
            $heap->{instructions}{$wheel->ID} = {
                %defaults,
                %{ $tail },
            };
            $files++;
            DEBUG(sprintf "Wheel %d tailing %s", $wheel->ID, $tail->{file});
        }
    }

    die sprintf("No files found to tail in %s", $opt->config) unless $files > 0;

    my $es = $config->{elasticsearch} || {};
    $heap->{elasticsearch} = POE::Component::ElasticSearch::Indexer->spawn(
        Alias         => 'es',
        Servers       => $es->{servers} || [qw( localhost:9200 )],
        Timeout       => $es->{timeout} || 5,
        FlushInterval => $es->{flush_interval} || 10,
        FlushSize     => $es->{flush_size} || 100,
        LoggingConfig => $loggingConfig,
        StatsInterval => $opt->stats_interval,
        StatsHandler  => sub {
            my ($stats) = @_;
            foreach my $k (keys %{ $stats }) {
                $heap->{stats}{$k} ||= 0;
                $heap->{stats}{$k}++;
            }
        },
        exists $es->{index} ? ( DefaultIndex => $es->{index} ) : (),
        exists $es->{type}  ? ( DefaultType  => $es->{type}  ) : (),
    );

    # Watch the Log4perl Config
    $kernel->delay( log4perl_refresh => 60 ) if $opt->log4perl_config;
    $kernel->delay( stats => $opt->stats_interval );

    INFO("Started $0 watching $files files.");
}

sub main_stop {
    $poe_kernel->post( es => 'shutdown' );
    FATAL("Shutting down $0");
}

sub main_child {
    my ($kernel,$heap,$reason,$child) = @_[KERNEL,HEAP,ARG0,ARG1];
    INFO(sprintf "Child [%d] %s event.", $child->ID, $reason);
}

sub main_stats {
    my ($kernel,$heap) = @_[KERNEL,HEAP];

    # Reschedule
    $kernel->delay( stats => $opt->stats_interval );

    # Collect our stats
    my $stats = delete $heap->{stats};
    $heap->{stats} = {};

    # Display them
    my $message = keys %{ $stats } ? join(", ", map {"$_=$stats->{$_}"} sort keys %{ $stats })
                : "Nothing to report.";
    INFO("STATS - $message");
}

sub got_error {
    my ($kernel,$heap,$op,$errnum,$errstr,$wheel_id) = @_[KERNEL,HEAP,ARG0..ARG3];

    ERROR("Wheel $wheel_id during $op got $errnum : $errstr");

    # Remove the Wheel from the polling
    if( exists $heap->{wheels}{$wheel_id} ) {
        delete $heap->{wheels}{$wheel_id};
        $heap->{stats}{wheel_error} ||= 0;
        $heap->{stats}{wheel_error}++;
    }

    # Close the ElasticSearch session if this is the last wheel
    if( !keys %{ $heap->{wheels} } ) {
        $kernel->post( es => 'shutdown' );
    }
}

sub log4perl_refresh {
    my $kernel = $_[KERNEL];
    TRACE("Rescanning Log4perl configuration at" . $opt->log4perl_config);
    # Reschedule
    $kernel->delay( log4perl_refresh => 60 );
    # Rescan the Log4perl configuration
    Log::Log4perl::Config->watcher->force_next_check();
    return;
}

sub got_new_line {
    my ($kernel,$heap,$line,$wheel_id) = @_[KERNEL,HEAP,ARG0,ARG1];

    $heap->{stats}{received} ||= 0;
    $heap->{stats}{received}++;

    my $instr = $heap->{instructions}{$wheel_id};

    my $doc;
    if( $instr->{decode} ) {
        my $decoders = is_arrayref($instr->{decode}) ? $instr->{decode} : [ $instr->{decode} ];
        foreach my $decoder ( @{ $decoders } ) {
            if( $decoder eq 'json' ) {
                my $start = index('{', $line);
                my $blob  = $start > 0 ? substr($line,$start) : $line;
                my $new;
                eval {
                    $new = decode_json($blob);
                    1;
                } or do {
                    my $err = $@;
                    TRACE("Bad JSON, error: $err\n$blob");
                    next;
                };
                $doc = merge( $doc, $new );
            }
            elsif( $decoder eq 'syslog' ) {
                unless( is_loaded('Parse::Syslog::Line') ) {
                    eval {
                        load "Parse::Syslog::Line";
                        1;
                    } or do {
                        my $err = $@;
                        die "To use the 'syslog' decoder, please install Parse::Syslog::Line: $err";
                    };
                    no warnings qw(once);
                    $Parse::Syslog::Line::PruneRaw = 1;
                }
                # If we make it here, we're ready to parse
                $doc = Parse::Syslog::Line::parse_syslog_line($line);
            }
        }
    }

    # Extractors
    if( my $extracters = $instr->{extract} ) {
        foreach my $extract( @{ $extracters } ) {
            # Only process items with a "by"
            if( $extract->{by} ) {
                my $from = $extract->{from} ? ( is_hashref($doc) && exists $doc->{$extract->{from}} ? $doc->{$extract->{from}} : undef )
                         : $line;
                next unless $from;
                if( $extract->{when} ) {
                    next unless $from =~ /$extract->{when}/;
                }
                if( $extract->{by} eq 'split' ) {
                    next unless $extract->{split_on};
                    my @parts = split /$extract->{split_on}/, $from;
                    if( my $keys = $extract->{split_parts} ) {
                        # Name parts
                        for( my $i = 0; $i < @parts; $i++ ) {
                            next unless $keys->[$i] and length $keys->[$i] and $parts[$i];
                            next if lc $keys->[$i] eq 'null' or lc $keys->[$i] eq 'undef';
                            if( my $into = $extract->{into} ) {
                                # Make sure we have a hash reference
                                $doc ||=  {};
                                $doc->{$into} = {} unless is_hashref($doc->{$into});
                                $doc->{$into}{$keys->[$i]} = $parts[$i];
                            }
                            else {
                                $doc ||=  {};
                                $doc->{$keys->[$i]} = $parts[$i];
                            }
                        }
                    }
                    else {
                        # This is an array, so it's simple
                        my $target = $extract->{into} ? $extract->{into} : $extract->{from};
                        $doc->{$target} = @parts > 1  ? [ grep { defined and length } @parts ] : $parts[0];
                    }
                }
                elsif( $extract->{by} eq 'regex' ) {
                    # Skip unless it's valid
                    next unless $extract->{regex} and $extract->{regex_parts};

                    if( my @parts = ($from =~ /$extract->{regex}/) ) {
                        # Name parts
                        my $keys = $extract->{regex_parts};
                        for( my $i = 0; $i < @parts; $i++ ) {
                            next unless $keys->[$i] and length $keys->[$i] and $parts[$i];
                            next if lc $keys->[$i] eq 'null' or lc $keys->[$i] eq 'undef';
                            if( my $into = $extract->{into} ) {
                                # Make sure we have a hash reference
                                $doc ||=  {};
                                $doc->{$into} = {} unless is_hashref($doc->{$into});
                                $doc->{$into}{$keys->[$i]} = $parts[$i];
                            }
                            else {
                                $doc ||=  {};
                                $doc->{$keys->[$i]} = $parts[$i];
                            }
                        }
                    }
                }
            }
        }
    }

    # Skip if the document isn't put together yet
    return unless $doc;

    $heap->{stats}{docs} ||= 0;
    $heap->{stats}{docs}++;

    # Store Line in _raw now
    $doc->{_raw}  = $line;
    $doc->{_path} = $instr->{file};

    # Mutators
    if( my $mutate = $instr->{mutate} ) {
        # Copy
        if( my $copy = $mutate->{copy} ) {
            foreach my $k ( keys %{ $copy } ) {
                my $destinations = is_arrayref($copy->{$k}) ? $copy->{$k} : [ $copy->{$k} ];
                foreach my $dst ( @{ $destinations } ) {
                    $doc->{$dst} = $doc->{$k};
                }
            }
        }
        # Rename Keys
        if( my $rename = $mutate->{rename} ) {
            foreach my $k ( keys %{ $rename } ) {
                next unless exists $doc->{$k};
                $doc->{$rename->{$k}} = delete $doc->{$k};
            }
        }
        # Remove unwanted keys
        if( $mutate->{remove} ) {
            foreach my $k ( @{ $mutate->{remove} } ) {
                delete $doc->{$k} if exists $doc->{$k};
            }
        }
        # Append
        if( my $append = $mutate->{append} ) {
            foreach my $k ( keys %{ $append } ) {
                $doc ||=  {};
                $doc->{$k} = $append->{$k};
            }
        }
        # Prune empty or undefined keys
        if( $mutate->{prune} ) {
            foreach my $k (keys %{ $doc }) {
                delete $doc->{$k} unless defined $doc->{$k} and length $doc->{$k};
            }
        }
    }

    foreach my $meta (qw(index type)) {
        $doc->{"_$meta"} = $instr->{$meta} if exists $instr->{$meta};
    }

    if( $opt->debug ) {
        TRACE("Indexing: " . encode_json($doc));
    }

    # Send the document to ElasticSearch
    $kernel->post( es => queue => $doc );
}

__END__

=pod

=encoding UTF-8

=head1 NAME

file-to-elasticsearch.pl - A simple utility to tail a file and index each line as a document in ElasticSearch

=head1 VERSION

version 0.011

=head1 SYNOPSIS

To see available options, run:

    file-to-elasticsearch.pl --help

Create a config file and run the utility:

    file-to-elasticsearch.pl --config config.yaml --log4perl logging.conf --debug

This will run a single threaded POE instance that will tail the log files
you've requested, performing the requested transformations and sending them to
the elasticsearch cluster and index you've specified.

=head1 CONFIGURATION

=head1 Configuration

=head2 ElasticSearch Settings

The C<elasticsearch> section of the config controls the settings passed to the
L<POE::Component::ElasticSearch::Indexer>.

    ---
    elasticsearch:
      servers: [ "localhost:9200" ]
      flush_interval: 30
      flush_size: 1_000
      index: logstash-%Y.%m.%d
      type: log

The settings available are:

=over 4

=item B<servers>

An array of servers used to send bulk data to ElasticSearch.  The default is
just localhost on port 9200.

=item B<flush_interval>

Every C<flush_interval> seconds, the queued documents are send to the Bulk API
of the cluster.

=item B<flush_size>

If this many documents is received, regardless of the time since the last
flush, force a flush of the queued documents to the Bulk API.

=item B<index>

A C<strftime> compatible string to use as the C<DefaultIndex> parameter if a
file doesn't pass one along.

=item B<type>

Mostly useless as Elastic is abandoning "types", but this will be set as the
C<DefaultType> for documents being indexed.

=back

=head2 Tail Section

The C<files> section contains the list of files to tail and the rules to use to
index them.

    ---
    tail:
      - file: '/var/log/osquery/result.log'
        index: "osquery-result-%Y.%m.%d"
        decode: json
        extract:
          - by: split
            from: name
            when: '^pack'
            into: 'pack'
            split_on: '/'
            split_parts: [ null, "name", "report" ]
        mutate:
          prune: true
          remove: [ "calendarTime", "epoch", "counter", "_raw" ]
          rename:
            unixTime: _epoch

Each element is a hash containing the following information.

=over 4

=item B<file>

B<Required>: The path to the file on the filesystem.

=item B<decode>

This may be a single element, or an array, containing one or more of the implemented decoders.

=over 4

=item json

Decode the discovered JSON in the document to a hash reference.  This finds the
first occurrence of an C<{> in the string and assumes everything to the end of
the string is JSON.

Decoding is done by L<JSON::MaybeXS>.

=item syslog

Parses each line as a standard UNIX syslog message.  Parsing is provided via
L<Parse::Syslog::Line> which isn't a hard requirement of the this package, but
will be loaded if available.

=back

=item B<index>

A C<strftime> compatible string to use as the index to put documents created
from this file.  If not specified, the defaults from the ElasticSearch section
will be used, and failing that, the default as specified in
L<POE::Component::ElasticSearch::Index>.

=item B<type>

The type to use for documents sourced from this file.

=item B<extract>

Extraction of fields from the document by one of the supported methods.

=over 4

=item by

Can be 'split' or 'regex'.

B<split> supports:

=over 4

=item split_on

Regex or string to split the string on.

=item split_parts

Name for each part of the split, C<undef> positions in the split string will be discarded.

=back

B<regex> supports:

=over 4

=item regex

The regex to use to extract, using capture groups to designate:

=item regex_parts

Name for reach captured group, C<undef> positions in the list will be discarded.

=back

=item from

Name of the field to apply the extraction to.

=item when

Limits applying the extraction to values matching the regex.

=item into

Top level namespace for the collected keys to wind up inside of, ie:

    extract:
      - by: split
        from: name
        when: '^pack'
        into: 'pack'
        split_on: '/'
        split_parts: [ null, "name", "report"  ]

Will look at the field B<name> and when it matches C<^pack> it will split the
name on C</> and index the second element to C<name> and the third to C<report>, so:

    name: pack/os/cpu_info

Becomes:

    pack:
      name: os
      report: cpu_info

=back

=back

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut
