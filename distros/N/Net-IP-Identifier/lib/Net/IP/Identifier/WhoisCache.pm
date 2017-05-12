#!/usr/bin/perl
#===============================================================================
#      PODNAME:  Net::IP::Identifier::WhoisCache
#     ABSTRACT:  Run whois, cache result in a database
#
#       AUTHOR:  Reid Augustin (REID)
#        EMAIL:  reid@hellosix.com
#      CREATED:  Sat May  2 15:51:45 PDT 2015
#===============================================================================

use 5.002;
use strict;
use warnings;

{
    package Local::DBRecord;    # a single database record
    use Moo;
    use namespace::clean;
    use overload '""' => \&print;

    has id         => ( is => 'rw' );   # index (INTEGER PRIMARY KEY)
    has range_str  => ( is => 'rw' );   # range as string
    has entity     => ( is => 'rw' );   # name associated with this WHOIS record
    has result     => ( is => 'rw' );   # command result to STDOUT
    has fetch_time => ( is => 'rw' );   # when WHOIS was last run
    has first_high => ( is => 'rw' );   # upper 64 its of first IP
    has first_low  => ( is => 'rw' );   # lower 64 its of first IP
    has last_high  => ( is => 'rw' );   # upper 64 its of last IP
    has last_low   => ( is => 'rw' );   # lower 64 its of last IP

    sub print {
        my ($self) = @_;

        return $self->result;
    }
}

package Net::IP::Identifier::WhoisCache;
use File::Spec;
use Getopt::Long qw(:config pass_through);
use Try::Tiny;
use Carp;
use DBI;
use IPC::Run qw( new_chunker );
use Math::BigInt;
use Net::IP;   # for IP_IDENTICAL, OVERLAP, etc
use Net::IP::Identifier::Net;
use Net::IP::Identifier::Regex;
use Net::IP::Identifier::WhoisParser;
use Moo;
use namespace::clean;

our $VERSION = '0.111'; # VERSION

our @request_columns = (
    {request_str => 'TEXT NOT NULL PRIMARY KEY',},
    {whois_id    => 'INTEGER NOT NULL',         },
);
my @whois_columns = (
    {id          => 'INTEGER PRIMARY KEY', },
    {range_str   => 'TEXT NOT NULL',       },
    {entity      => 'TEXT NOT NULL',       },
    {result      => 'TEXT NOT NULL',       },
    {fetch_time  => 'UNSIGNED BIG INT',    },
    {first_high  => 'UNSIGNED BIG INT',    },
    {first_low   => 'UNSIGNED BIG INT',    },
    {last_high   => 'UNSIGNED BIG INT',    },
    {last_low    => 'UNSIGNED BIG INT',    },
);


# DB field indices:
for my $ii (0 .. $#request_columns) {
    my ($sub_name) = keys %{$request_columns[$ii]};
    eval "sub $sub_name { $ii };";  ## no critic qw(BuiltinFunctions::ProhibitStringyEval)
}
for my $ii (0 .. $#whois_columns) {
    my ($sub_name) = keys %{$whois_columns[$ii]};
    eval "sub $sub_name { $ii };";  ## no critic qw(BuiltinFunctions::ProhibitStringyEval)
}

has verbose => (    # verbose mode
    is => 'rw',
);
has db_filename => (    # default sqlite database file name
    is => 'rw',
    default => "$ENV{HOME}/.whois_cache.sqlite",
);
has db      => (    # database object
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        my $db = DBI->connect(        # connect to your database, create if needed
            'dbi:SQLite:dbname=' . $self->db_filename, # DSN: dbi, driver, database file
            '',                     # no user
            '',                     # no password
            {
                AutoCommit => 1,
                RaiseError => 1,    # complain if something goes wrong
            },
        );
        $self->_db_schema($db);   # make sure table exists
        return $db;
    },
);
has request_table_name => (
    is => 'lazy',
    default => sub { 'request_cache' },
);
has whois_table_name => (
    is => 'lazy',
    default => sub { 'whois_cache' },
);
has parse_failed => (       # error message when parsing WHOIS result fails
    is => 'rw',
);
has timeout => (            # seconds before command timeout
    is => 'rw',
    default => sub { 30 },  # seconds
);
has stale_timeout   => (    # time until cached record is considered stale
    is => 'rw',
    default => sub { 60 * 60 * 24 * 30 },   # 30 days
);
has _try_ripe => (          # sigh, jwhois might not do this for IPv6, do it by hand
    is => 'rw',
);
has force_cache_miss => (
    is => 'rw',
);
has sth_select_request => ( # SQL handle for finding requests
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'SELECT * FROM',
                $self->request_table_name,
                'WHERE request_str = ?',
            ),
        );
    },
);
has sth_insert_request => ( # SQL handle for adding request to database
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'INSERT OR REPLACE INTO',
                $self->request_table_name,
                '(',
                    scalar $self->request_sql_columns,
                ')',
                'VALUES (',
                    join(', ',
                        map({ '?' }     # one question mark per column
                            @request_columns,
                        ),
                    ),
                ')',
            ),
        );
    },
);
has sth_select_whois_by_id => (   # SQL handle for finding WHOIS record by ID
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'SELECT * FROM',
                $self->whois_table_name,
                'WHERE id = ?',
            ),
        );
    },
);
has sth_select_whois_by_range_str => (   # SQL handle for finding WHOIS record by range_str
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'SELECT * FROM',
                $self->whois_table_name,
                'WHERE range_str = ?',
            ),
        );
    },
);
has sth_delete_ranges => (   # SQL handle for deleting IPs in the database
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'DELETE FROM',
                $self->whois_table_name,
                # SQL to find an IP or range falling inside a record's range:
                # match ($db_first <= $ip_first AND $db_last >= $ip_last),
                #    but since first/last are split into two 64 bit ints, we need:
                #   (($db_first_high <  $ip_first_high) OR
                #    ($db_first_high == $ip_first_high AND $db_first_low <= $ip_first_low)) AND
                #   (($db_last_high  >  $ip_last_high ) OR
                #    ($db_last_high  == $ip_last_high  AND $db_last_low >= $ip_last_low))
                'WHERE ( first_high < ? OR',
                '       (first_high == ? AND first_low <= ?)) AND',
                '      ( last_high > ? OR',
                '       (last_high == ? AND last_low >= ?))',
            ),
        );
    },
);
has sth_delete_pattern => (   # SQL handle for deleting IPs based on pattern match
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'DELETE FROM',
                $self->whois_table_name,
                'WHERE result LIKE ?',
            ),
        );
    },
);
has sth_insert_whois => (   # SQL handle for adding to the WHOIS database
    is => 'lazy',
    default => sub {
        my ($self) = @_;

        $self->db->prepare(
            join(' ',
                'INSERT OR REPLACE INTO',
                $self->whois_table_name,
                '(',
                    scalar $self->whois_sql_columns,
                ')',
                'VALUES (',
                    join(', ',
                        map({ '?' }     # one question mark per column
                            @whois_columns,
                        ),
                    ),
                ')',
            ),
        );
    },
);
has sth_max_id => (   # SQL handle get the max ID value in WHOIS database
    is => 'lazy',
    default => sub {
        my ($self) = @_;
        $self->db->prepare(
            join(' ',
                'SELECT MAX(id) from',
                $self->whois_table_name,
            ),
        );
    },
);

# some class variables:

my (undef, undef, $myName) = File::Spec->splitpath($0);

my $help_msg = <<EO_HELP

$myName [ options ] IP [ IP... ]

Print WHOIS information, and cache it in a database.  If the IP is within a
netblock that has already been cached, and the cache is younger than the
'stale' time, print the cached information instead of running WHOIS again.

IP may be dotted decimal format: N.N.N.N, range format: N.N.N.N - N.N.N.N,
CIDR format: N.N.N.N/W, or a filename from which IPs will be extracted.  If
no IP or filename is found on the command line, STDIN is opened.

Options (may be abbreviated):
    filename    => SQLite database file name
    db_filename => a file containing IP addresses and/or ranges
                        parse this file instead of using the
                        command line arguments
    miss        => force a cache miss and update
    delete      => delete by IP or matching WHOIS content
    entity      => an optional string or regular expression to
                        help determine the netblock represented
                        by the WHOIS result
    verbose     => verbose messages
    help        => this message

EO_HELP
;

# set low 64 bits of a Math::BigInt
my $mask_64 = (Math::BigInt->new(1) << 64) - 1;     # for masking off bits above 64

my $Re = Net::IP::Identifier::Regex->new;
my $re_any      = $Re->IP_any;

# make this package a modulino
__PACKAGE__->run unless caller;     # modulino

sub run {
    my ($class) = @_;

    my %opts;
    my $filename;
    my $delete;
    my $help;

    exit 0 if (not
        GetOptions(
            'db_filename=s' => \$opts{db_filename},
            'miss'          => \$opts{force_cache_miss},  # force a cache miss/update
            'delete=s'      => \$delete,    # delete record(s) from database
            'filename=s'    => \$filename,
            'verbose'       => \$opts{verbose},
            'help'          => \$help,
        )
    );

    if ($help) {
        print $help_msg;
        exit;
    }

    map { delete $opts{$_} if not defined $opts{$_} } keys %opts;

    my $whois_cache = __PACKAGE__->new(%opts);

    unshift @ARGV, $filename if ($filename);

    if ($delete) {
        $whois_cache->delete($delete);
        return if (not @ARGV);
    }

    if (not @ARGV) { # use STDIN?
        $whois_cache->parse_fh(\*STDIN);
    }

    while (@ARGV) {
        my $arg = shift @ARGV;
        if (-f $arg) {
            open my $fh, '<', $arg;
            croak "Can't open $arg for reading\n" if not $fh;
            $whois_cache->parse_fh($fh);
            close $fh;
            next
        }
        elsif ($ARGV[0]        and  # accept N.N.N.N - N.N.N.N for network blocks too
               $ARGV[0] eq '-' and
               $ARGV[1]) {
            $arg .= (shift @ARGV) . shift @ARGV;
        }

        print $whois_cache->get_whois($arg);
        print "# ", $whois_cache->parse_failed, "\n" if ($whois_cache->parse_failed);
    }
}

sub parse_fh {
    my ($self, $fh) = @_;

    my $ip_any = $Re->IP_any;   # IPv4/6 range, plus, cidr or individual IP
    while(<$fh>) {
        my (@ips) = m/($ip_any)/;
        for my $ip (@ips) {
            print $self->get_whois($ip), "\n";
            print "# ", $self->parse_failed, "\n" if ($self->parse_failed);
        }
    }
}

sub ip_str_to_net {
    my ($self, $req_str) = @_;

    my ($net, $error);
    try {
        $net = Net::IP::Identifier::Net->new($req_str);
    } catch {
        $error = $_;
    };
    if ($error) {
        print "# Error converting $req_str to Net object:\n$error";
        return '';
    }
    return $net;
}

sub get_whois {
    my ($self, $req_str) = @_;

    $self->parse_failed(undef); # clear error
    my $req_net = $self->ip_str_to_net($req_str);
    if ($req_net->ip ne $req_net->last_ip and
        not defined $req_net->prefixlen) {
        # $req_net is a range, but it requires more than a single CIDR to
        #   represent it.  this is not legitimate input for jwhois and we
        #   can't really return multiple whois results.
        my @cidrs = map { sprintf("#    %s\n", $_->src_str) } $req_net->range_to_cidrs;
        die ('# ', $req_net->src_str, " is a non-CIDR range - please split into:\n", @cidrs);
    }
    my $record = $self->find_in_cache($req_net);
    if (not defined $record or
        $self->force_cache_miss or
        (time - $record->fetch_time > $self->stale_timeout)) {
        $record = $self->cache_miss($req_net);  # fetch and cache it
    }

    return $record;
}

sub delete {
    my ($self, $pattern) = @_;

    my @net_strs = $pattern =~ m/($re_any)/o;
    if (@net_strs) { # by IP
        for my $net_str (@net_strs) {
            my $net = $self->ip_str_to_net($net_str);
            my ($ip_first_high, $ip_first_low) = $self->split_ip($net->intip);
            my ($ip_last_high,  $ip_last_low ) = $self->split_ip($net->last_int);
            $self->sth_delete_ranges->execute(
                "$ip_first_high", "$ip_first_high", "$ip_first_low",
                "$ip_last_high",  "$ip_last_high",  "$ip_last_low",
            );
        }
    }
    else { # by matching WHOIS result to pattern
        $self->sth_delete_pattern->execute("%$pattern%");
    }
}

sub find_in_cache { # try to find $req_net in database
    my ($self, $req_net) = @_;

    $self->sth_select_request->execute($req_net->print);
    my $matches = $self->sth_select_request->fetchall_arrayref;
    # might be no matches
    if (not @{$matches}) {
        print "# Not Found in cache($req_net)\n" if ($self->verbose);
        return;
    }
    my $id = $matches->[0][$self->whois_id];    # get ID of WHOIS record

    $self->sth_select_whois_by_id->execute($id);
    $matches = $self->sth_select_whois_by_id->fetchall_arrayref;
    # might be no matches
    if (not @{$matches}) {
        print "# ERROR: $req_net found but no cached WHOIS record with id=$id\n";
        return;
    }

    my $match = $matches->[0];  # should be only one
    if (not $match) {    # shouldn't happen
        print "# ERROR: $req_net points to empty cache with id=$id\n";
        return;
    }

    my $rec = Local::DBRecord->new();
    for my $key ($self->whois_sql_columns) {
        $rec->$key($match->[$self->$key()]);  # set DBRecord from DB field
    }
    for my $key (qw(first_high first_low last_high last_low)) {
        # weird, but large ints (with MSB set?) get wrong result if
        #    we just pass the value directly, so convert to hex:
        $rec->$key(Math::BigInt->new(sprintf("0x%x", $rec->$key)));
    }
    print "# Found in cache($req_net)\n" if ($self->verbose);

    return $rec;
}

sub cache_miss {   # run WHOIS and cache result
    my ($self, $req_net) = @_;

    my $whois_rec = $self->fetch_whois_rec($req_net);
    if ($self->parse_failed and
        $req_net->version == 6) {
        print "# Parsing WHOIS result failed, try RIPE\n" if ($self->verbose);
        $self->_try_ripe(1);
        $whois_rec = $self->fetch_whois_rec($req_net);
    }
    if ($self->parse_failed) {  # sigh, we did what we could
        print "# ", $self->parse_failed, "\n" if ($self->verbose);
        return $whois_rec;  # don't try to cache it
    }

    # see if there is already a WHOIS record matching the returned result.
    #    This can happen if cache is stale of if a new (uncached) request
    #    produces WHOIS that's already cached.
    $self->sth_select_whois_by_range_str->execute($whois_rec->range_str);
    my ($already) = $self->sth_select_whois_by_range_str->fetchall_arrayref;
    if ($already and @{$already}) {
        # 'id' col is PRIMARY KEY.  If we set it to existing record, the
        # insert sth replaces that record instead of inserting a new record 
        $whois_rec->id($already->[0][$self->id]);
    }

    my @vals = map { $whois_rec->$_ } $self->whois_sql_columns;
    # cache (or update) WHOIS record in the whois table
    $self->sth_insert_whois->execute(@vals);
    # and insert this request into the request table
    # if it's already in, it gets updated
    $self->sth_insert_request->execute(
        $req_net->print,    # request_str
        $whois_rec->id,     # whois_id
    );
    # since WHOIS result may not match requested net, add it too,
    # since it's obviously a valid response were that to be requested
    # if it's already in, it gets updated
    $self->sth_insert_request->execute(
        $whois_rec->range_str,  # whois netblock string
        $whois_rec->id,         # whois_id
    );

    return $whois_rec;
}

sub fetch_whois_rec {
    my ($self, $req_net) = @_;

    my @cmd = ('jwhois');
    push @cmd, '-h', 'whois.ripe.net' if ($self->_try_ripe);
    push @cmd, $req_net->print;
    print "# Cache miss: running ", join(' ', @cmd), "\n" if ($self->verbose);
    my $ii = 0;
    my $whois_result;
    for (my $ii = 0; $ii < 3; ) {
        my ($timeout_err, $err);
        try {
# print "run ", join(' ', @cmd), "\n";
            IPC::Run::run(
                \@cmd, # run jwhois
                '>',
                \$whois_result,
                '2>',
                \$err,
                IPC::Run::timeout( $self->timeout ),
            ) or $timeout_err = $?;
# print "done\n";
        }
        catch {
            $timeout_err = "# Caught: $_";
# print "catch error\n";
        };
        print "# $err" if ($err);

        last if not $timeout_err;
        print "# Timeout: $timeout_err\n";

        last if ($ii++ >= 2);
        print "#   retry $ii...\n";
    }
    if (not defined $whois_result) {
        die "# No WHOIS result for $req_net\n";
    }

    my $rec = Local::DBRecord->new(
        id         => $self->max_id + 1,
        result     => $whois_result,
        fetch_time => time,
    );

    my $parser = Net::IP::Identifier::WhoisParser->new(text => $whois_result);

    if (defined $parser->range) {
        $rec->range_str($parser->range->print);    # normalized range
        my ($first_high, $first_low) = $self->split_ip($parser->range->intip);
        my ($last_high,  $last_low ) = $self->split_ip($parser->range->last_int);
        $rec->first_high($first_high);  # upper 64 its of first IP
        $rec->first_low ($first_low);   # lower 64 its of first IP
        $rec->last_high ($last_high);   # upper 64 its of last IP
        $rec->last_low  ($last_low);    # lower 64 its of last IP
    }
    else {
        $self->parse_failed("Failed to parse netblock range from WHOIS result");
    }
    if ($parser->entity) {
        $rec->entity($parser->entity);
    }
    else {
        $self->parse_failed("Failed to parse entity from WHOIS result");
    }
    return $rec;
}

sub _db_schema {
    my ($self, $db) = @_;

    $db->do(
        join(' ',
            'CREATE TABLE IF NOT EXISTS',
            $self->request_table_name,
            '(',
              join(', ',
                map({join ' ', each %{$_}}
                    @request_columns,
                ),
              ),
            ')',
        ),
    );
    $db->do(
        join(' ',
            'CREATE TABLE IF NOT EXISTS',
            $self->whois_table_name,
            '(',
              join(', ',
                map({join ' ', each %{$_}}
                    @whois_columns,
                ),
              ),
            ')',
        ),
    );
}

# return max value in WHOIS ID rows
sub max_id {
    my ($self) = @_;

    $self->sth_max_id->execute;
    my ($max) = $self->sth_max_id->fetchall_arrayref;
    return $max->[0][0];
}

# SQL maxes out at 64 bit integers, so split 128 bit IPv6 addresses
sub split_ip {
    my ($self, $int_128) = @_;

    return ($int_128 >> 64, $int_128 & $mask_64);
}

# inverse of split_ip, but also converts to IPv4/6
sub combine_ip {
    my ($self, $high, $low, $ipv6) = @_;

    my @parts;
    if (not $ipv6) {
        # IPv4
        while (@parts < 4) {
            unshift @parts, $low & 0xff;
            $low /= 0x100;
        }
        return join '.', @parts;
    }
    # IPv6
    my $ip = $high->copy;
    $ip <<= 64;
    $ip += $low;
    while (@parts < 8) {
        unshift @parts, sprintf("%x", $ip & 0xffff);
        $ip /= 0x10000;
    }
    return join ':', @parts;
}

# sql columns (without column types)
sub request_sql_columns {
    my ($self) = @_;

    my @cols = map { keys %{$_} } @request_columns;
    return wantarray
      ? @cols
      : join ', ', @cols;
}

# sql columns (without column types)
sub whois_sql_columns {
    my ($self) = @_;

    my @cols = map { keys %{$_} } @whois_columns;
    return wantarray
      ? @cols
      : join ', ', @cols;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::IP::Identifier::WhoisCache - Run whois, cache result in a database

=head1 VERSION

version 0.111

=head1 SYNOPSIS

 use Net::IP::Identifier::WhoisCache;

=head1 DESCRIPTION

Net::IP::Identifier::WhoisCache runs WHOIS on an IP or netblock.  The
result is cached in an SQLite database file.  If the same IP or netblock is
requested later, the cached information is returned (unless it's 'stale').
Note that different requests must fetch WHOIS again even if the new request
falls within a block covered by a previous request because the block may be
subdivided such that the new request returns a different WHOIS result.

=head2 Methods

=over

=item run

This module is a modulino, meaning it may be used as a module or as a
script.  The B<run> method is called when there is no caller and it is used
as a script.  B<run> parses the command line arguments and calls B<new()>
to create the object.  If a filename is specified on the command line, that
file is read as the input, otherwise the command line is used.  If no arguments
are provided on the command line, STDIN is used.

Input (from a file, the command line, or STDIN) is scanned for things that
look like IP (v4 or v6) addresses or blocks.  For each matching item, the
B<Net::IP::Identifier::WhoisCache> object's B<get_whois> method (see below)
is called on it, and the result is printed to STDOUT.

Example:

    Net::IP::Identifier::WhoisCache.pm 8.8.8.8

or

    echo 8.8.8.8 | Net::IP::Identifier::WhoisCache.pm

prints WHOIS information about this Google-owned netblock.

For command line help, run:

    WhoisCache.pm --help

=item new( [ options ] )

Creates a new Net::IP::Identifier::WhoisCache object.  The following options are available,
and are also available as accessors:

=over

=item verbose

Get/set a flag to produce diagnosics.

=item db_filename

SQLite database file name.  If it doesn't exist, it is created and
initialized.

When run as a script, this can be changed on the command line with:

    --db_filename new_name.sqlite

Default: '$ENV{HOME}/.whois_cache.sqlite'.

=item db

The database object (see perldoc DBI).

=item request_table_name

The table name for the request cache within the database.  Requests must map
exactly to a previous request (netblocks must match).

=item whois_table_name

The table name for the WHOIS data cache within the database.

Default: 'whois_cache'.

=item timeout

Get/set the timeout (in seconds) for running the whois command.

Default: 30 seconds.

=item stale_timeout

Get/set the number of seconds until a cached record is considered stale.

Default: 30 days worth of seconds.

=item force_cache_miss

Set/get a flag to force B<get_whois> to suffer a cache miss.

When used from the command line, --miss (or -m) sets this flag.

=back

=item sth_select_request

Returns an SQL handle for finding requests.

=item sth_insert_request

Returns an SQL handle for adding request to database.

=item sth_select_whois_by_id

Returns an SQL handle for finding WHOIS record by ID.

=item sth_select_whois_by_range_str

Returns an SQL handle for finding WHOIS record by range_str.

=item sth_delete_ranges

Returns an SQL handle for deleting IPs in the database.

=item sth_delete_pattern

Returns an SQL handle for deleting IPs based on pattern match.

=item sth_insert_whois

Returns an SQL handle for adding to the WHOIS database.

=item sth_max_id

Returns an SQL handle get the max ID value in WHOIS database.

=item parse_fh ( $file_handle );

Parse input from B<$file_handle>, looking for things that look like IP
(v4 or v6) addresses or ranges.  Call B<get_whois> on each found item,
and print the result to STDOUT.

=item ip_str_to_net ( $req_str )

Creates and returns a Net::IP::Identifier::Net object from $req_str.  If
creation dies, prints the error to STDOUT and returns ''.

=item get_whois ( $ip)

B<$ip> is a string representing a netblock (individual IP, CIDR, or net
range), or it can be a Net::IP or a Net::IP::Identifier::Net object.  If
B<$ip> is already in the cache, and the cached information is not stale,
returns a B<Local::DBRecord> object which includes the cached WHOIS result.
Otherwise, runs WHOIS and update the cache.

The B<Local::DBRecord> object contains the following methods for retrieving
the database information

Can die if B<$ip> is a netblock that cannot be represented by a CIDR (meaning
it's boundaries are not on a binary power block).

=over

=item id

The integer ID for this record.  This is an INTEGER PRIMARY KEY
(autoincrementing) column.

=item range_str

The IP range represented by this record.

=item result

The WHOIS information as a single string

=item fetch_time

When WHOIS information was fetched (seconds since the epoch)

=item first_high

High 64 bits of starting IP in range

=item first_low

Low 64 bits of starting IP in range

=item last_high

High 64 bits of last IP in range

=item last_low

Low 64 bits of last IP in range

=back

The same method names, when called on the Net::IP::Identifier::WhoisCache
object, return the database column index.

=item split_ip ( $ip_as_Math::BigInt )

Splits a Math::BigInt.  Returns the high 64 bits and the low 64 bits (as
Math::BigInts).

=item combine_ip ( $high, $low, $ipv6 )

The inverse of B<split_ip>, it recombines B<$high> and B<$low> back into an
IP address.  If B<$ipv6> is false B<$high> is zero and B<$low> is less than
0x1_0000_0000 it is recombined into an IPv4 address (N.N.N.N), otherwise it
will be an IPv6 address (N:N:N:N:N:N:N:N - not condensed).

=item delete ( $pattern )

Removes one or more cache entries from the database.  if B<$pattern> looks
like an IP or IP range, then all entries that contain the IP or range
are deleted.  Otherwise, the WHOIS information of all entries is scanned
and if B<$pattern> matches, the entry is deleted.  B<$pattern> is an SQL
matching expression, so '%' deletes all cache entries (same effect as
deleting the database file).

=item find_in_cache ( $req_net )

Search the database for B<$req_net>. If found, it will point to a particular
WHOIS record (unless it's been deleted), and that record is returned (unless
it's stale).  If the WHOIS record isn't found for any reason, it calls
B<cache_miss>.

Returns a Local::DBRecord object (see B<get_whois> above).

=item fetch_whois_rec( $net )

Runs 'jwhois' attempting to fetch WHOIS information about $net.  If no
information can be retrieved (after several retries), throws and exception.
Otherwise, the returned information is parsed and a Local::DBRecord is
created and returned.

=item parse_failed ( [ 'reason' ] )

Set/get a reason why parsing of the WHOIS information failed.  Can be either
that no netblock representing the original request was extracted, or because
no specific entity could be determined for the netblock.

=item cache_miss ( $req_net );

Run WHOIS on B<$req_net> (a Net::IP::Identifier::Net object) and cache result.
Add a new WHOIS record, or update if there is an old (stale) one.

Returns a Local::DBRecord object (see B<get_whois> above).

=item request_sql_columns

=item whois_sql_columns

Return the column names used in the request_cache or whois_cache tables.
In array context, return an array of the names.  In scalar context, return
the names joined by commas (suitable for use in SQL statements).

=item max_id

Returns the maximum ID field in the whois_cache table.

=back

=head1 SEE ALSO

=over

=item Net::IP

=item Net::IP::Identifier::Net

=item Net::IP::Identifier::Plugins::Google (and other plugins in this directory)

=item Module::Pluggable

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
