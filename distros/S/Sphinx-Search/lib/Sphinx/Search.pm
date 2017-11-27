package Sphinx::Search;

use warnings;
use strict;

use base 'Exporter';

use Carp;
use Socket;
use Config;
use Math::BigInt;
use IO::Socket::INET;
use IO::Socket::UNIX;
use Encode qw/encode_utf8 decode_utf8/;
use List::MoreUtils qw/any/;

my $is_native64 = $Config{longsize} == 8 || defined $Config{use64bitint} || defined $Config{use64bitall};
    

=head1 NAME

Sphinx::Search - Sphinx search engine API Perl client

=head1 VERSION

Please note that you *MUST* install a version which is compatible with your version of Sphinx.

Use version 0.30 for Sphinx-2.2.8-release or later (or use DBI instead)

Use version 0.28 for Sphinx-2.0.8-release or later

Use version 0.27.2 for Sphinx-2.0.3-release (svn-r3043)

Use version 0.26.1 for Sphinx-2.0.1-beta (svn-r2792)

Use version 0.25_03 for Sphinx svn-r2575

Use version 0.24.1 for Sphinx-1.10-beta (svn-r2420)

Use version 0.23_02 for Sphinx svn-r2269 (experimental)

Use version 0.22 for Sphinx 0.9.9-rc2 and later (Please read the Compatibility Note under L<SetEncoders> regarding encoding changes)

Use version 0.15 for Sphinx 0.9.9-svn-r1674

Use version 0.12 for Sphinx 0.9.8

Use version 0.11 for Sphinx 0.9.8-rc1

Use version 0.10 for Sphinx 0.9.8-svn-r1112

Use version 0.09 for Sphinx 0.9.8-svn-r985

Use version 0.08 for Sphinx 0.9.8-svn-r871

Use version 0.06 for Sphinx 0.9.8-svn-r820

Use version 0.05 for Sphinx 0.9.8-cvs-20070907

Use version 0.02 for Sphinx 0.9.8-cvs-20070818

=cut

our $VERSION = '0.30';

=head1 SYNOPSIS

    use Sphinx::Search;

    $sph = Sphinx::Search->new();

    # Standard API query
    $results = $sph->SetSortMode(SPH_SORT_RELEVANCE)
                   ->Query("search terms");

    # SphinxQL query
    $results = $sph->SphinxQL("SELECT * FROM myindex WHERE MATCH('search terms')");

=head1 DESCRIPTION

This is the Perl API client for the Sphinx open-source SQL full-text indexing
search engine, L<http://www.sphinxsearch.com>.

Since 0.9.9, Sphinx supports a native MySQL-protocol client, i.e. DBI with DBD::mysql. That is, you can configure the server to have a mysql41 listening port and then simply do

  my $dbh = DBI->connect('dbi:mysql:host=127.0.0.1;port=9306;mysql_enable_utf8=1') or die "Failed to connect via DBI";
  my $sth = $dbh->prepare_cached("SELECT * FROM myindex WHERE MATCH('search terms')");
  $sth->execute();
  while (my $row = $sth->fetchrow_arrayref) {
      ... # Collect results
  }

The DBI client turns out to be significantly (about 5x) faster than this pure-Perl API. You should probably be using that instead.

This module also supports SphinxQL queries, with the small advantage that you can use either the standard API or the SphinxQL API over the one port (i.e. the searchd server does not need to be configured with a mysql41 listening port).

Given that the DBI client has several advantages over this API, future updates of this module are unlikely.

  
=cut

# Constants to export.
our @EXPORT = qw(       
                SPH_MATCH_ALL SPH_MATCH_ANY SPH_MATCH_PHRASE SPH_MATCH_BOOLEAN SPH_MATCH_EXTENDED
                SPH_MATCH_FULLSCAN SPH_MATCH_EXTENDED2
                SPH_RANK_PROXIMITY_BM25 SPH_RANK_BM25 SPH_RANK_NONE SPH_RANK_WORDCOUNT
                SPH_RANK_PROXIMITY SPH_RANK_MATCHANY SPH_RANK_FIELDMASK SPH_RANK_SPH04 SPH_RANK_EXPR
                SPH_RANK_TOTAL
                SPH_SORT_RELEVANCE SPH_SORT_ATTR_DESC SPH_SORT_ATTR_ASC SPH_SORT_TIME_SEGMENTS
                SPH_SORT_EXTENDED SPH_SORT_EXPR
                SPH_GROUPBY_DAY SPH_GROUPBY_WEEK SPH_GROUPBY_MONTH SPH_GROUPBY_YEAR SPH_GROUPBY_ATTR
                SPH_GROUPBY_ATTRPAIR
                SPH_ATTR_INTEGER SPH_ATTR_TIMESTAMP SPH_ATTR_ORDINAL SPH_ATTR_BOOL
                SPH_ATTR_FLOAT SPH_ATTR_BIGINT SPH_ATTR_STRING SPH_ATTR_MULTI SPH_ATTR_MULTI64
                SPH_QF_REVERSE_SCAN SPH_QF_SORT_METHOD SPH_QF_MAX_PREDICTED_TIME 
                SPH_QF_BOOLEAN_SIMPLIFY SPH_QF_IDF SPH_QF_GLOBAL_IDF
                );

# known searchd commands
use constant SEARCHD_COMMAND_SEARCH     => 0;
use constant SEARCHD_COMMAND_EXCERPT    => 1;
use constant SEARCHD_COMMAND_UPDATE     => 2;
use constant SEARCHD_COMMAND_KEYWORDS   => 3;
use constant SEARCHD_COMMAND_PERSIST    => 4;
use constant SEARCHD_COMMAND_STATUS     => 5;
use constant SEARCHD_COMMAND_FLUSHATTRS => 7;
use constant SEARCHD_COMMAND_SPHINXQL   => 8;

# current client-side command implementation versions
use constant VER_COMMAND_SEARCH                 => 0x11E;
use constant VER_COMMAND_EXCERPT        => 0x104;
use constant VER_COMMAND_UPDATE                 => 0x103;
use constant VER_COMMAND_KEYWORDS       => 0x100;
use constant VER_COMMAND_STATUS         => 0x101;
use constant VER_COMMAND_FLUSHATTRS     => 0x100;
use constant VER_COMMAND_SPHINXQL       => 0x100;

# known searchd status codes
use constant SEARCHD_OK                         => 0;
use constant SEARCHD_ERROR              => 1;
use constant SEARCHD_RETRY              => 2;
use constant SEARCHD_WARNING            => 3;

# known match modes
use constant SPH_MATCH_ALL              => 0;
use constant SPH_MATCH_ANY              => 1;
use constant SPH_MATCH_PHRASE           => 2;
use constant SPH_MATCH_BOOLEAN          => 3;
use constant SPH_MATCH_EXTENDED                 => 4;
use constant SPH_MATCH_FULLSCAN                 => 5;
use constant SPH_MATCH_EXTENDED2        => 6; # extended engine V2 (TEMPORARY, WILL BE REMOVED

# known ranking modes (ext2 only)
use constant SPH_RANK_PROXIMITY_BM25    => 0; # default mode, phrase proximity major factor and BM25 minor one
use constant SPH_RANK_BM25              => 1; # statistical mode, BM25 ranking only (faster but worse quality)
use constant SPH_RANK_NONE              => 2; # no ranking, all matches get a weight of 1
use constant SPH_RANK_WORDCOUNT         => 3; # simple word-count weighting, rank is a weighted sum of per-field keyword occurence counts
use constant SPH_RANK_PROXIMITY         => 4;
use constant SPH_RANK_MATCHANY          => 5;
use constant SPH_RANK_FIELDMASK         => 6;
use constant SPH_RANK_SPH04             => 7;
use constant SPH_RANK_EXPR              => 8;
use constant SPH_RANK_TOTAL             => 9;

# known sort modes
use constant SPH_SORT_RELEVANCE                 => 0;
use constant SPH_SORT_ATTR_DESC                 => 1;
use constant SPH_SORT_ATTR_ASC          => 2;
use constant SPH_SORT_TIME_SEGMENTS     => 3;
use constant SPH_SORT_EXTENDED          => 4;
use constant SPH_SORT_EXPR              => 5;

# known filter types
use constant SPH_FILTER_VALUES          => 0;
use constant SPH_FILTER_RANGE           => 1;
use constant SPH_FILTER_FLOATRANGE      => 2;
use constant SPH_FILTER_STRING          => 3;

# known attribute types
use constant SPH_ATTR_INTEGER           => 1;
use constant SPH_ATTR_TIMESTAMP                 => 2;
use constant SPH_ATTR_ORDINAL           => 3;
use constant SPH_ATTR_BOOL              => 4;
use constant SPH_ATTR_FLOAT             => 5;
use constant SPH_ATTR_BIGINT            => 6;
use constant SPH_ATTR_STRING            => 7;
use constant SPH_ATTR_FACTORS           => 1001;
use constant SPH_ATTR_MULTI             => 0x40000001;
use constant SPH_ATTR_MULTI64           => 0x40000002;

# known grouping functions
use constant SPH_GROUPBY_DAY            => 0;
use constant SPH_GROUPBY_WEEK           => 1;
use constant SPH_GROUPBY_MONTH          => 2;
use constant SPH_GROUPBY_YEAR           => 3;
use constant SPH_GROUPBY_ATTR           => 4;
use constant SPH_GROUPBY_ATTRPAIR       => 5;

use constant {
    SPH_QF_REVERSE_SCAN => 'reverse_scan',
    SPH_QF_SORT_METHOD => 'sort_method',
    SPH_QF_MAX_PREDICTED_TIME => 'max_predicted_time',
    SPH_QF_BOOLEAN_SIMPLIFY => 'boolean_simplify',
    SPH_QF_IDF => 'idf',
    SPH_QF_GLOBAL_IDF => 'global_idf',
};

my %query_flags = ( SPH_QF_REVERSE_SCAN() => [ 0, 1 ],
                    SPH_QF_SORT_METHOD() => [ qw/pq kbuffer/ ],
                    SPH_QF_MAX_PREDICTED_TIME() => [ 0 ],
                    SPH_QF_BOOLEAN_SIMPLIFY() => [1, 0],
                    SPH_QF_IDF() => [ qw/normalized plain tfidf_normalized tfidf_unnormalized/ ],
                    SPH_QF_GLOBAL_IDF() => [1, 0],
                );

use constant MYSQL_COL_STRING => 254;

# Floating point number matching expression
my $num_re = qr/^-?\d*\.?\d*(?:[eE][+-]?\d+)?$/;

# portably pack numeric to 64 signed bits, network order
sub _sphPackI64 {
    my $self = shift;
    my $v = shift;

    # x64 route
    my $i = $is_native64 ? int($v) : Math::BigInt->new("$v");
    return pack ( "NN", $i>>32, $i & 4294967295 );
}

# portably pack numeric to 64 unsigned bits, network order
sub _sphPackU64 {
    my $self = shift;
    my $v = shift;

    my $i = $is_native64 ? int($v) : Math::BigInt->new("$v");
    return pack ( "NN", $i>>32, $i & 4294967295 );
}

sub _sphPackI64array {
    my $self = shift;
    my $values = shift || [];

    my $s = pack("N", scalar @$values);
    $s .= $self->_sphPackI64($_) for @$values;
    return $s;
}

# portably unpack 64 unsigned bits, network order to numeric
sub _sphUnpackU64 
{
    my $self = shift;
    my $v = shift;

    my ($h,$l) = unpack ( "N*N*", $v );

    # x64 route
    return ($h<<32) + $l if $is_native64;

    # x32 route, BigInt
    $h = Math::BigInt->new($h);
    $h->blsft(32)->badd($l);
    
    return $h->bstr;
}

# portably unpack 64 signed bits, network order to numeric
sub _sphUnpackI64 
{
    my $self = shift;
    my $v = shift;

    my ($h,$l) = unpack ( "N*N*", $v );

    my $neg = ($h & 0x80000000) ? 1 : 0;

    # x64 route
    if ( $is_native64 ) {
        return -(~(($h<<32) + $l) + 1) if $neg;
        return ($h<<32) + $l;
    }

    # x32 route, BigInt
    if ($neg) {
        $h = ~$h;
        $l = ~$l;
    }

    my $x = Math::BigInt->new($h);
    $x->blsft(32)->badd($l);
    $x->binc()->bneg() if $neg;

    return $x->bstr;
}

sub _sphSetBit {
    my ($self, $flag, $bit, $on) = @_;

    if ($on) {
        $flag |= (1 << $bit);
    }
    else {
        $flag &= ~(1 << $bit);
    }
    return $flag;
}





=head1 CONSTRUCTOR

=head2 new

    $sph = Sphinx::Search->new;
    $sph = Sphinx::Search->new(\%options);

Create a new Sphinx::Search instance.

OPTIONS

=over 4

=item log

Specify an optional logger instance.  This can be any class that provides error,
warn, info, and debug methods (e.g. see L<Log::Log4perl>).  Logging is disabled
if no logger instance is provided.

=item debug

Debug flag.  If set (and a logger instance is specified), debugging messages
will be generated.

=back

=cut

# create a new client object and fill defaults
sub new {
    my ($class, $options) = @_;
    my $self = {
        # per=client-object settings
        _host           => 'localhost',
        _port           => 9312,
        _path           => undef,
        _socket         => undef,

        _persistent     => undef,
        _connectretries => 1,

        # per-query settings
        _offset                 => 0,
        _limit          => 20,
        _mode           => SPH_MATCH_EXTENDED2,
        _weights        => [],
        _sort           => SPH_SORT_RELEVANCE,
        _sortby                 => "",
        _min_id                 => 0,
        _max_id                 => 0,
        _filters        => [],
        _groupby        => "",
        _groupdistinct  => "",
        _groupfunc      => SPH_GROUPBY_DAY,
        _groupsort      => '@group desc',
        _maxmatches     => 1000,
        _cutoff         => 0,
        _retrycount     => 0,
        _retrydelay     => 0,
        _anchor         => undef,
        _indexweights   => undef,
        _ranker         => SPH_RANK_PROXIMITY_BM25,
        _rankexpr       => "",
        _maxquerytime   => 0,
        _fieldweights   => {},
        _overrides      => {},
        _select         => q{*},

        # per-reply fields (for single-query case)
        _error          => '',
        _warning        => '',
        _connerror      => '',
        
        # request storage (for multi-query case)
        _reqs           => [],
        _timeout        => 0,

        _string_encoder => \&encode_utf8,
        _string_decoder => \&decode_utf8,
    };
    bless $self, ref($class) || $class;

    $self->ResetQueryFlag;
    $self->ResetOuterSelect;

    # These options are supported in the constructor, but not recommended 
    # since there is no validation.  Use the Set* methods instead.
    my %legal_opts = map { $_ => 1 } qw/host port offset limit mode weights sort sortby groupby groupbyfunc maxmatches cutoff retrycount retrydelay log debug string_encoder string_decoder/;
    for my $opt (keys %$options) {
        $self->{'_' . $opt} = $options->{$opt} if $legal_opts{$opt};
    }
    # Disable debug unless we have something to log to
    $self->{_debug} = 0 unless $self->{_log};

    return $self;
}


=head1 METHODS

=cut

sub _Error {
    my ($self, $msg) = @_;

    $self->{_error} = $msg;
    $self->{_log}->error($msg) if $self->{_log};
    return;
}

sub _Throw {
    my ($self, $msg) = @_;

    die $msg;
}

=head2 GetLastError

    $error = $sph->GetLastError;

Get last error message (string)

=cut

sub GetLastError {
        my $self = shift;
        return $self->{_error};
}

sub _Warning {
    my ($self, $msg) = @_;

    $self->{_warning} = $msg;
    $self->{_log}->warn($msg) if $self->{_log};
    return;
}

=head2 GetLastWarning

    $warning = $sph->GetLastWarning;

Get last warning message (string)

=cut

sub GetLastWarning {
        my $self = shift;
        return $self->{_warning};
}


=head2 IsConnectError 

Check connection error flag (to differentiate between network connection errors
and bad responses).  Returns true value on connection error.

=cut

sub IsConnectError {
    return shift->{_connerror};
}

=head2 SetEncoders

    $sph->SetEncoders(\&encode_function, \&decode_function)

COMPATIBILITY NOTE: SetEncoders() was introduced in version 0.17.
Prior to that, all strings were considered to be sequences of bytes
which may have led to issues with multi-byte characters.  If you were
previously encoding/decoding strings external to Sphinx::Search, you
will need to disable encoding/decoding by setting Sphinx::Search to
use raw values as explained below (or modify your code and let
Sphinx::Search do the recoding).

Set the string encoder/decoder functions for transferring strings
between perl and Sphinx.  The encoder should take the perl internal
representation and convert to the bytestream that searchd expects, and
the decoder should take the bytestream returned by searchd and convert to
perl format.

The searchd format will depend on the 'charset_type' index setting in
the Sphinx configuration file.

The coders default to encode_utf8 and decode_utf8 respectively, which
are compatible with the 'utf8' charset_type.

If either the encoder or decoder functions are left undefined in the
call to SetEncoders, they return to their default values.  

If you wish to send raw values (no encoding/decoding), supply a
function that simply returns its argument, e.g. 

    $sph->SetEncoders( sub { shift }, sub { shift });

Returns $sph.

=cut

sub SetEncoders {
    my $self = shift;
    my $encoder = shift;
    my $decoder = shift;

    $self->{_string_encoder} = $encoder ? $encoder : \&encode_utf8;
    $self->{_string_decoder} = $decoder ? $decoder : \&decode_utf8;
        
    return $self;
}

=head2 SetServer

    $sph->SetServer($host, $port);
    $sph->SetServer($path, $port);

In the first form, sets the host (string) and port (integer) details for the
searchd server using a network (INET) socket (default is localhost:9312).

In the second form, where $path is a local filesystem path (optionally prefixed
by 'unix://'), sets the client to access the searchd server via a local (UNIX
domain) socket at the specified path.

Returns $sph.

=cut

sub SetServer {
    my $self = shift;
    my $host = shift;
    my $port = shift;

    croak("host is not defined") unless defined($host);
    if (substr($host, 0, 1) eq '/') {
        $self->{_path} = $host;
        return;
    }
    elsif (substr($host, 0, 7) eq 'unix://') {
        $self->{_path} = substr($host, 7);
        return;
    }
        
    $port ||= 0;
    croak("port is not an number") unless $port =~ m/^\d+/o;
    $port = int($port);
    croak("port $port out of range 0 to 65536") if $port <0 || $port >= 65536;

    $self->{_host} = $host;
    $self->{_port} = $port == 0 ? 9312 : $port;
    $self->{_path} = undef;

    return $self;
}

=head2 SetConnectTimeout

    $sph->SetConnectTimeout($timeout)

Set server connection timeout (in seconds).

Returns $sph.

=cut

sub SetConnectTimeout {
    my $self = shift;
    my $timeout = shift;

    croak("timeout is not numeric") unless ($timeout =~  m/$num_re/);
    $self->{_timeout} = $timeout;
    return $self;
}

=head2 SetConnectRetries

    $sph->SetConnectRetries($retries)

Set server connection retries (in case of connection fail).

Returns $sph.

=cut

sub SetConnectRetries {
    my $self = shift;
    my $retries = shift;
    croak("connect retries is not numeric") unless ($retries =~  m/$num_re/);
    $self->{_connectretries} = $retries;
    return $self;
}


sub _Send {
    my $self = shift;
    my $fp = shift;
    my $data = shift;

    $self->{_log}->debug("Writing to socket") if $self->{_debug};
    unless ( send($fp,$data,0)){
        $self->_Error("connection unexpectedly closed (timed out?): $!");
        $self->{_connerror} = 1;
        if ($self->{_socket}) {
            close($self->{_socket});
            undef $self->{_socket};
        }
        return 0;
    }
    return 1;
}

# connect to searchd server

sub _Connect {
    my $self = shift;
    
    $self->_Error(); #reset old errors in new connection 
    
    if ($self->{_socket}) {
        # persistent connection, check it
        return $self->{_socket} if $self->{_socket}->connected;
        # force reopen
        undef $self->{_socket};
    }

    my $debug = $self->{_debug};
    my $str_dest = $self->{_path} ? 'unix://' . $self->{_path} : "$self->{_host}:$self->{_port}";
    $self->{_log}->debug("Connecting to $str_dest") if $debug;

    # connect socket
    $self->{_connerror} = q{};

    my $fp;
    my %params = (); # ( Blocking => 0 );
    $params{Timeout} = $self->{_timeout} if $self->{_timeout};
    if ($self->{_path}) {
        $fp = IO::Socket::UNIX->new( Peer => $self->{_path},
                                     %params,
            );
    }
    else {
        $fp = IO::Socket::INET->new( PeerPort => $self->{_port},
                                     PeerAddr => $self->{_host},
                                     Proto => 'tcp',
                                     %params,
            );
    }
    if (! $fp) {
        $self->_Error("Failed to open connection to $str_dest: $!");
        $self->{_connerror} = 1;
        return 0;
    }
    binmode($fp, ':bytes');

    # check version
    my $buf = '';
    $fp->read($buf, 4) or do {
        $self->_Error("Failed on initial read from $str_dest: $!");
        $self->{_connerror} = 1;
        return 0;
    };
    my $v = unpack("N*", $buf);
    $v = int($v);
    $self->{_log}->debug("Got version $v from searchd") if $debug;
    if ($v < 1) {
        close($fp);
        $self->_Error("expected searchd protocol version 1+, got version '$v'");
        return 0;
    }

    $self->{_log}->debug("Sending version") if $debug;

    # All ok, send my version
    unless ($self->_Send($fp, pack("N", 1))) {
        $self->{_connerror} = 1;
        $self->_Error("error on sending version");
                return 0;
    }
    $self->{_log}->debug("Connection complete") if $debug;
    
    if ($self->{_persistent}) {
        my $req = pack("nnNN", SEARCHD_COMMAND_PERSIST, 0, 4, 1);
        unless ($self->_Send($fp, $req)) {
            $self->{_connerror} = 1;
            $self->_Error("error on setting persistent connection");
            return 0;
        }
        $self->{_socket} = $fp;        
    }

    return $fp;

}

#-------------------------------------------------------------

# get and check response packet from searchd server
sub _GetResponse {
    my $self = shift;
    my $fp = shift;
    my $client_ver = shift;

    my $header;
    my $resp = $fp->read($header, 8, 0);

    if (!defined($resp) || $resp==0) {
        close $self->{_socket};
        undef $self->{_socket};
        $self->_Error("read failed: $!");
        return 0;
    }

    my ($status, $ver, $len ) = unpack("n2N", $header);
    if ( ! defined($len) ) {
        $self->_Error("read failed: $!");
        return 0;
    }

    my $response = q{};
    my $lasterror = q{};
    my $lentotal = 0;
    while (my $rlen = $fp->read(my $chunk, $len)) {
        if ($rlen < 0) {
            $lasterror = $!;
            last;
        }
        $response .= $chunk;
        $lentotal += $rlen;
        last if $lentotal >= $len;
    }
    close($fp) unless $self->{_socket};

    # check response
    if ( length($response) != $len ) {
        $self->_Error( $len 
                       ? "failed to read searchd response (status=$status, ver=$ver, len=$len, read=". length($response) . ", last error=$lasterror)"
                       : "received zero-sized searchd response");
        return 0;
    }

    # check status
    if ( $status==SEARCHD_WARNING ) {
        my ($wlen) = unpack ( "N*", substr ( $response, 0, 4 ) );
        $self->_Warning(substr ( $response, 4, $wlen ));
        return substr ( $response, 4+$wlen );
    }
    if ( $status==SEARCHD_ERROR ) {
        $self->_Error("searchd error: " . substr ( $response, 4 ));
        return 0;
    }
    if ( $status==SEARCHD_RETRY ) {
        $self->_Error("temporary searchd error: " . substr ( $response, 4 ));
        return 0;
    }
    if ( $status!=SEARCHD_OK ) {
        $self->_Error("unknown status code '$status'");
        return 0;
    }

    # check version
    if ( $ver<$client_ver ) {
        $self->_Warning(sprintf ( "searchd command v.%d.%d older than client's v.%d.%d, some options might not work",
                                  $ver>>8, $ver&0xff, $client_ver>>8, $client_ver&0xff ));
    }
    return $response;
}

#-----------------------------------------------
# connect to searchd, send request and get data 

sub _ProcessRequest {
    my ($self, $req, $response_command_version) = @_;
    return unless $req;
    my $tries = $self->{_connectretries} + 1;
    while( $tries-- ) {
        my $fp = $self->_Connect;
        if (! $fp) {
            next if $self->IsConnectError;
            last;
        }
        $self->_Send($fp, $req) or next;
        my $response = $self->_GetResponse ($fp, $response_command_version);
        return $response if $response;
    }
    $self->_Error($self->GetLastError . "... ConnectRetries exceed...") if $self->IsConnectError;
    return 0;
}


=head2 SetLimits

    $sph->SetLimits($offset, $limit);
    $sph->SetLimits($offset, $limit, $max);

Set match offset/limits, and optionally the max number of matches to return.

Returns $sph.

=cut

sub SetLimits {
    my $self = shift;
    my $offset = shift;
    my $limit = shift;
    my $max = shift || 0;
    croak("offset should be an integer >= 0") unless ($offset =~ /^\d+$/ && $offset >= 0) ;
    croak("limit should be an integer >= 0") unless ($limit =~ /^\d+$/ && $limit >= 0);
    $self->{_offset} = $offset;
    $self->{_limit}  = $limit;
    if($max > 0) {
        $self->{_maxmatches} = $max;
    }
    return $self;
}

=head2 SetMaxQueryTime

    $sph->SetMaxQueryTime($millisec);

Set maximum query time, in milliseconds, per index.

The value may not be negative; 0 means "do not limit".

Returns $sph.

=cut

sub SetMaxQueryTime {
    my $self = shift;
    my $max = shift;

    croak("max value should be an integer >= 0") unless ($max =~ /^\d+$/ && $max >= 0) ;
    $self->{_maxquerytime} = $max;
    return $self;
}


=head2 SetMatchMode

** DEPRECATED **

    $sph->SetMatchMode($mode);

Set match mode, which may be one of:

=over 4

=item * SPH_MATCH_ALL

Match all words

=item * SPH_MATCH_ANY           

Match any words

=item * SPH_MATCH_PHRASE        

Exact phrase match

=item * SPH_MATCH_BOOLEAN       

Boolean match, using AND (&), OR (|), NOT (!,-) and parenthetic grouping.

=item * SPH_MATCH_EXTENDED      

Extended match, which includes the Boolean syntax plus field, phrase and
proximity operators.

=back

Returns $sph.

=cut

sub SetMatchMode {
    my $self = shift;
    my $mode = shift;
    warn "SetMatchMode is DEPRECATED. Do not call this method - use extended query syntax instead.";

    croak("Match mode not defined") unless defined($mode);
    croak("Unknown matchmode: $mode") unless ( $mode==SPH_MATCH_ALL 
                                               || $mode==SPH_MATCH_ANY 
                                               || $mode==SPH_MATCH_PHRASE 
                                               || $mode==SPH_MATCH_BOOLEAN 
                                               || $mode==SPH_MATCH_EXTENDED 
                                               || $mode==SPH_MATCH_FULLSCAN 
                                               || $mode==SPH_MATCH_EXTENDED2 );
    $self->{_mode} = $mode;
    return $self;
}


=head2 SetRankingMode

    $sph->SetRankingMode(SPH_RANK_BM25, $rank_exp);

Set ranking mode, which may be one of:

=over 4

=item * SPH_RANK_PROXIMITY_BM25 

Default mode, phrase proximity major factor and BM25 minor one

=item * SPH_RANK_BM25 

Statistical mode, BM25 ranking only (faster but worse quality)

=item * SPH_RANK_NONE 

No ranking, all matches get a weight of 1

=item * SPH_RANK_WORDCOUNT 

Simple word-count weighting, rank is a weighted sum of per-field keyword
occurence counts

=item * SPH_RANK_MATCHANY

Returns rank as it was computed in SPH_MATCH_ANY mode earlier, and is internally used to emulate SPH_MATCH_ANY queries.

=item * SPH_RANK_FIELDMASK

Returns a 32-bit mask with N-th bit corresponding to N-th fulltext field, numbering from 0. The bit will only be set when the respective field has any keyword occurences satisfiying the query.

=item * SPH_RANK_SPH04

SPH_RANK_SPH04 is generally based on the default SPH_RANK_PROXIMITY_BM25 ranker, but additionally boosts the matches when they occur in the very beginning or the very end of a text field. 

=item * SPH_RANK_EXPR

Allows the ranking formula to be specified at run time. It exposes a number of internal text factors and lets you define how the final weight should be computed from those factors.  $rank_exp should be set to the ranking expression string, e.g. to emulate SPH_RANK_PROXIMITY_BM25, use "sum(lcs*user_weight)*1000+bm25".

=back

Returns $sph.

=cut

sub SetRankingMode {
    my $self = shift;
    my $ranker = shift;
    my $rankexp = shift;

    croak("Unknown ranking mode: $ranker") unless ( $ranker == 0
						    || ( $ranker >= 1
							 && $ranker < SPH_RANK_TOTAL ));

    $self->{_ranker} = $ranker;
    $self->{_rankexpr} = $rankexp || "";

    return $self;
}


=head2 SetSortMode

    $sph->SetSortMode(SPH_SORT_RELEVANCE);
    $sph->SetSortMode($mode, $sortby);

Set sort mode, which may be any of:

=over 4

=item SPH_SORT_RELEVANCE - sort by relevance

=item SPH_SORT_ATTR_DESC, SPH_SORT_ATTR_ASC

Sort by attribute descending/ascending.  $sortby specifies the sorting attribute.

=item SPH_SORT_TIME_SEGMENTS

Sort by time segments (last hour/day/week/month) in descending order, and then
by relevance in descending order.  $sortby specifies the time attribute.

=item SPH_SORT_EXTENDED

Sort by SQL-like syntax.  $sortby is the sorting specification.

=item SPH_SORT_EXPR


=back

Returns $sph.

=cut

sub SetSortMode {
    my $self = shift;
    my $mode = shift;
    my $sortby = shift || "";
    croak("Sort mode not defined") unless defined($mode);
    croak("Unknown sort mode: $mode") unless ( $mode == SPH_SORT_RELEVANCE
                                               || $mode == SPH_SORT_ATTR_DESC
                                               || $mode == SPH_SORT_ATTR_ASC 
                                               || $mode == SPH_SORT_TIME_SEGMENTS
                                               || $mode == SPH_SORT_EXTENDED
                                               || $mode == SPH_SORT_EXPR
        );
    croak("Sortby must be defined") unless ($mode==SPH_SORT_RELEVANCE || length($sortby));
    $self->{_sort} = $mode;
    $self->{_sortby} = $sortby;
    return $self;
}

=head2 SetWeights
    
** DEPRECATED **

    $sph->SetWeights([ 1, 2, 3, 4]);

This method is deprecated.  Use L<SetFieldWeights> instead.

Set per-field (integer) weights.  The ordering of the weights correspond to the
ordering of fields as indexed.

Returns $sph.

=cut

sub SetWeights {
    my $self = shift;
    my $weights = shift;
    warn "SetWeights is DEPRECATED, Do not call this method; use SetFieldWeights instead";

    croak("Weights is not an array reference") unless (ref($weights) eq 'ARRAY');
    foreach my $weight (@$weights) {
        croak("Weight: $weight is not an integer") unless ($weight =~ /^\d+$/);
    }
    $self->{_weights} = $weights;
    return $self;
}

=head2 SetFieldWeights
    
    $sph->SetFieldWeights(\%weights);

Set per-field (integer) weights by field name.  The weights hash provides field
name to weight mappings.

Takes precedence over L<SetWeights>.

Unknown names will be silently ignored.  Missing fields will be given a weight of 1.

Returns $sph.

=cut

sub SetFieldWeights {
    my $self = shift;
    my $weights = shift;
    croak("Weights is not a hash reference") unless (ref($weights) eq 'HASH');
    foreach my $field (keys %$weights) {
        croak("Weight: $weights->{$field} is not an integer >= 0") unless ($weights->{$field} =~ /^\d+$/);
    }
    $self->{_fieldweights} = $weights;
    return $self;
}

=head2 SetIndexWeights
    
    $sph->SetIndexWeights(\%weights);

Set per-index (integer) weights.  The weights hash is a mapping of index name to integer weight.

Returns $sph.

=cut

sub SetIndexWeights {
    my $self = shift;
    my $weights = shift;
    croak("Weights is not a hash reference") unless (ref($weights) eq 'HASH');
    foreach (keys %$weights) {
        croak("IndexWeight $_: $weights->{$_} is not an integer") unless ($weights->{$_} =~ /^\d+$/);
    }
    $self->{_indexweights} = $weights;
    return $self;
}



=head2 SetIDRange

    $sph->SetIDRange($min, $max);

Set IDs range only match those records where document ID
is between $min and $max (including $min and $max)

Returns $sph.

=cut

sub SetIDRange {
    my $self = shift;
    my $min = shift;
    my $max = shift;
    croak("min_id is not numeric") unless ($min =~  m/$num_re/);
    croak("max_id is not numeric") unless ($max =~  m/$num_re/);
    croak("min_id is larger than or equal to max_id") unless ($min < $max);
    $self->{_min_id} = $min;
    $self->{_max_id} = $max;
    return $self;
}

=head2 SetFilter

    $sph->SetFilter($attr, \@values);
    $sph->SetFilter($attr, \@values, $exclude);

Sets the results to be filtered on the given attribute.  Only results which have
attributes matching the given values will be returned.  (Attribute values must be integers).

This may be called multiple times with different attributes to select on
multiple attributes.

If 'exclude' is set, excludes results that match the filter.

Returns $sph.

=cut

sub SetFilter {
    my ($self, $attribute, $values, $exclude) = @_;

    croak("attribute is not defined") unless (defined $attribute);
    croak("values is not an array reference") unless (ref($values) eq 'ARRAY');
    croak("values reference is empty") unless (scalar(@$values));

    push(@{$self->{_filters}}, {
        type => SPH_FILTER_VALUES,
        attr => $attribute,
        values => $values,
        exclude => $exclude ? 1 : 0,
         });

    return $self;
}

=head2 SetFilterString

    $sph->SetFilterString($attr, $value)
    $sph->SetFilterString($attr, $value, $exclude)

Adds new string value filter.  Only those documents where $attr column value matches the string value from $value will be matched (or rejected, if $exclude is true).

=cut

sub SetFilterString {
    my ($self, $attribute, $value, $exclude) = @_;

    croak("attribute is not defined") unless (defined $attribute);
    croak("value is not a string") unless ($value && ! ref($value));

    push(@{$self->{_filters}}, {
        type => SPH_FILTER_STRING,
        attr => $attribute,
        value => $value,
        exclude => $exclude ? 1 : 0,
         });

    return $self;
}

=head2 SetFilterRange

    $sph->SetFilterRange($attr, $min, $max);
    $sph->SetFilterRange($attr, $min, $max, $exclude);

Sets the results to be filtered on a range of values for the given
attribute. Only those records where $attr column value is between $min and $max
(including $min and $max) will be returned.

If 'exclude' is set, excludes results that fall within the given range.

Returns $sph.

=cut

sub SetFilterRange {
    my ($self, $attribute, $min, $max, $exclude) = @_;
    croak("attribute is not defined") unless (defined $attribute);
    croak("min: $min is not an integer") unless ($min =~ m/$num_re/);
    croak("max: $max is not an integer") unless ($max =~ m/$num_re/);
    croak("min value should be <= max") unless ($min <= $max);

    push(@{$self->{_filters}}, {
        type => SPH_FILTER_RANGE,
        attr => $attribute,
        min => $min,
        max => $max,
        exclude => $exclude ? 1 : 0,
    });

    return $self;
}

=head2 SetFilterFloatRange 

    $sph->SetFilterFloatRange($attr, $min, $max, $exclude);

Same as L<SetFilterRange>, but allows floating point values.

Returns $sph.

=cut

sub SetFilterFloatRange {
    my ($self, $attribute, $min, $max, $exclude) = @_;
    croak("attribute is not defined") unless (defined $attribute);
    croak("min: $min is not numeric") unless ($min =~ m/$num_re/);
    croak("max: $max is not numeric") unless ($max =~ m/$num_re/);
    croak("min value should be <= max") unless ($min <= $max);

    push(@{$self->{_filters}}, {
        type => SPH_FILTER_FLOATRANGE,
        attr => $attribute,
        min => $min,
        max => $max,
        exclude => $exclude ? 1 : 0,
    });

    return $self;

}

=head2 SetGeoAnchor

    $sph->SetGeoAnchor($attrlat, $attrlong, $lat, $long);

Setup anchor point for using geosphere distance calculations in filters and sorting.
Distance will be computed with respect to this point

=over 4

=item $attrlat is the name of latitude attribute

=item $attrlong is the name of longitude attribute

=item $lat is anchor point latitude, in radians

=item $long is anchor point longitude, in radians

=back

Returns $sph.

=cut

sub SetGeoAnchor {
    my ($self, $attrlat, $attrlong, $lat, $long) = @_;

    croak("attrlat is not defined") unless defined $attrlat;
    croak("attrlong is not defined") unless defined $attrlong;
    croak("lat: $lat is not numeric") unless ($lat =~ m/$num_re/);
    croak("long: $long is not numeric") unless ($long =~ m/$num_re/);

    $self->{_anchor} = { 
                         attrlat => $attrlat, 
                         attrlong => $attrlong, 
                         lat => $lat,
                         long => $long,
                     };
    return $self;
}

=head2 SetGroupBy

    $sph->SetGroupBy($attr, $func);
    $sph->SetGroupBy($attr, $func, $groupsort);

Sets attribute and function of results grouping.

In grouping mode, all matches are assigned to different groups based on grouping
function value. Each group keeps track of the total match count, and the best
match (in this group) according to current sorting function. The final result
set contains one best match per group, with grouping function value and matches
count attached.

$attr is any valid attribute.  Use L<ResetGroupBy> to disable grouping.

$func is one of:

=over 4

=item * SPH_GROUPBY_DAY

Group by day (assumes timestamp type attribute of form YYYYMMDD)

=item * SPH_GROUPBY_WEEK

Group by week (assumes timestamp type attribute of form YYYYNNN)

=item * SPH_GROUPBY_MONTH

Group by month (assumes timestamp type attribute of form YYYYMM)

=item * SPH_GROUPBY_YEAR

Group by year (assumes timestamp type attribute of form YYYY)

=item * SPH_GROUPBY_ATTR

Group by attribute value

=item * SPH_GROUPBY_ATTRPAIR

Group by two attributes, being the given attribute and the attribute that
immediately follows it in the sequence of indexed attributes.  The specified
attribute may therefore not be the last of the indexed attributes.

=back

Groups in the set of results can be sorted by any SQL-like sorting clause,
including both document attributes and the following special internal Sphinx
attributes:

=over 4

=item @id - document ID;

=item @weight, @rank, @relevance -  match weight;

=item @group - group by function value;

=item @count - number of matches in group.

=back

The default mode is to sort by groupby value in descending order,
ie. by "@group desc".

In the results set, "total_found" contains the total amount of matching groups
over the whole index.

WARNING: grouping is done in fixed memory and thus its results
are only approximate; so there might be more groups reported
in total_found than actually present. @count might also
be underestimated. 

For example, if sorting by relevance and grouping by a "published"
attribute with SPH_GROUPBY_DAY function, then the result set will
contain only the most relevant match for each day when there were any
matches published, with day number and per-day match count attached,
and sorted by day number in descending order (ie. recent days first).

=cut

sub SetGroupBy {
    my $self = shift;
    my $attribute = shift;
    my $func = shift;
    my $groupsort = shift || '@group desc';
    croak("attribute is not defined") unless (defined $attribute);
    croak("Unknown grouping function: $func") unless ($func==SPH_GROUPBY_DAY
                                                      || $func==SPH_GROUPBY_WEEK
                                                      || $func==SPH_GROUPBY_MONTH
                                                      || $func==SPH_GROUPBY_YEAR
                                                      || $func==SPH_GROUPBY_ATTR
                                                      || $func==SPH_GROUPBY_ATTRPAIR
        );

    $self->{_groupby} = $attribute;
    $self->{_groupfunc} = $func;
    $self->{_groupsort} = $groupsort;
    return $self;
}

=head2 SetGroupDistinct

    $sph->SetGroupDistinct($attr);

Set count-distinct attribute for group-by queries

=cut

sub SetGroupDistinct {
    my $self = shift;
    my $attribute = shift;
    croak("attribute is not defined") unless (defined $attribute);
    $self->{_groupdistinct} = $attribute;
    return $self;
}

=head2 SetRetries

    $sph->SetRetries($count, $delay);

Set distributed retries count and delay

=cut

sub SetRetries {
    my $self = shift;
    my $count = shift;
    my $delay = shift || 0;

    croak("count: $count is not an integer >= 0") unless ($count =~ /^\d+$/o && $count >= 0);
    croak("delay: $delay is not an integer >= 0") unless ($delay =~ /^\d+$/o && $delay >= 0);
    $self->{_retrycount} = $count;
    $self->{_retrydelay} = $delay;
    return $self;
}

=head2 SetOverride

 ** DEPRECATED **

    $sph->SetOverride($attrname, $attrtype, $values);

 Set attribute values override. There can be only one override per attribute.
 $values must be a hash that maps document IDs to attribute values

=cut

sub SetOverride {
    my $self = shift;
    my $attrname = shift;
    my $attrtype = shift;
    my $values = shift;

    die "SetOverride is DEPRECATED. Do not call this method.";

    croak("attribute name is not defined") unless defined $attrname;
    croak("Uknown attribute type: $attrtype") unless ($attrtype == SPH_ATTR_INTEGER
                                                      || $attrtype == SPH_ATTR_TIMESTAMP
                                                      || $attrtype == SPH_ATTR_BOOL
                                                      || $attrtype == SPH_ATTR_FLOAT
                                                      || $attrtype == SPH_ATTR_BIGINT);
    $self->{_overrides}->{$attrname} = { attr => $attrname,
                                         type => $attrtype,
                                         values => $values,
                                     };
    
    return $self;
}


=head2 SetSelect 

    $sph->SetSelect($select)

Set select list (attributes or expressions).  SQL-like syntax.

=cut

sub SetSelect {
    my $self = shift;
    $self->{_select} = shift;
    return $self;
}

=head2 SetQueryFlag 

    $sph->SetQueryFlag($flag_name, $flag_value);


=cut

sub SetQueryFlag {
    my ($self, $flag_name, $flag_value) = @_;

    croak("Unknown flag $flag_name") unless exists $query_flags{$flag_name};
    croak("Unknown or illegal flag value ($flag_value) for '$flag_name'") unless 
        (any { $_ eq $flag_value } @{$query_flags{$flag_name}})
            || ($flag_name eq 'max_predicted_time' && $flag_value =~ m/^\d+$/);

    if ($flag_name eq SPH_QF_REVERSE_SCAN) {
        $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 0, $flag_value == 1);
    }
    elsif ($flag_name eq SPH_QF_SORT_METHOD) {
        $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 1, $flag_value == "kbuffer");
    }
    elsif ($flag_name eq SPH_QF_MAX_PREDICTED_TIME) {
        $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 2, $flag_value > 0);
        $self->{_predictedtime} = $flag_value;
    }
    elsif ($flag_name eq SPH_QF_BOOLEAN_SIMPLIFY) {
        $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 3, $flag_value);
    }
    elsif ($flag_name eq SPH_QF_IDF) {
        if ($flag_value eq 'normalized' || $flag_value eq 'plain') {
            $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 4, $flag_value eq 'normalized');
        }
        else { # must be tfidf_normalized or tfidf_unnormalized
            $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 6, $flag_value eq 'tfidf_normalized');
        }
    }
    elsif ($flag_name eq SPH_QF_GLOBAL_IDF) {
        $self->{_query_flags} = $self->_sphSetBit( $self->{_query_flags}, 5, $flag_value);
    }

    return $self;
}

=head2 SetOuterSelect

  $sph->SetOuterSelect($orderby, $offset, $limit)

=cut

sub SetOuterSelect {
    my ($self, $orderby, $offset, $limit) = @_;

    croak("orderby must be a string") unless $orderby && ! ref($orderby);
    croak("offset and limit must be integers > 0") unless $offset =~ m/^\d+$/ && $limit =~ m/^\d+$/;

    $self->{_outerorderby} = $orderby;
    $self->{_outeroffsetlimit} = $offset;
    $self->{_outerlimit} = $limit;
    $self->{_hasouter} = 1;

    return $self;
}

=head2 ResetFilters

    $sph->ResetFilters;

Clear all filters.

=cut

sub ResetFilters {
    my $self = shift;

    $self->{_filters} = [];
    $self->{_anchor} = undef;

    return $self;
}

=head2 ResetGroupBy

    $sph->ResetGroupBy;

Clear all group-by settings (for multi-queries)

=cut

sub ResetGroupBy {
    my $self = shift;

    $self->{_groupby} = "";
    $self->{_groupfunc} = SPH_GROUPBY_DAY;
    $self->{_groupsort} = '@group desc';
    $self->{_groupdistinct} = "";

    return $self;
}

=head2 ResetOverrides

Clear all attribute value overrides (for multi-queries)

=cut

sub ResetOverrides {
    my $self = shift;

    $self->{_select} = undef;
    return $self;
}

=head2 ResetQueryFlag

Clear all query flags.

=cut

sub ResetQueryFlag {
    my $self = shift;

    $self->{_query_flags} = $self->_sphSetBit(0, 6, 1);
    $self->{_predictedtime} = 0;
    return $self;
}

=head2 ResetOuterSelect

Clear all outer select settings.

=cut

sub ResetOuterSelect {
    my $self = shift;

    $self->{_outerorderby} = '';
    $self->{_outeroffset} = 0;
    $self->{_outerlimit} = 0;
    $self->{_hasouter} = 0;

    return $self;
}


=head2 Query

    $results = $sph->Query($query, $index);

Connect to searchd server and run given search query.

=over 4

=item query is query string

=item index is index name to query, default is "*" which means to query all indexes.  Use a space or comma separated list to search multiple indexes.

=back

Returns undef on failure

Returns hash which has the following keys on success:

=over 4

=item matches
    
Array containing hashes with found documents ( "doc", "weight", "group", "stamp" )
 
=item total

Total amount of matches retrieved (upto SPH_MAX_MATCHES, see sphinx.h)

=item total_found
                    
Total amount of matching documents in index
 
=item time
          
Search time

=item words
           
Hash which maps query terms (stemmed!) to ( "docs", "hits" ) hash

=back

Returns the results array on success, undef on error.

=cut

sub Query {
    my $self = shift;
    my $query = shift;
    my $index = shift || '*';
    my $comment = shift || '';

    croak("_reqs is not empty") unless @{$self->{_reqs}} == 0;

    $self->AddQuery($query, $index, $comment);
    my $results = $self->RunQueries or return;
    $self->_Error($results->[0]->{error}) if $results->[0]->{error};
    $self->_Warning($results->[0]->{warning}) if $results->[0]->{warning};
    return if $results->[0]->{status} && $results->[0]->{status} == SEARCHD_ERROR;

    return $results->[0];
}

# helper to pack floats in network byte order
sub _PackFloat {
    my $f = shift;
    my $t1 = pack ( "f", $f ); # machine order
    my $t2 = unpack ( "L*", $t1 ); # int in machine order
    return pack ( "N", $t2 );
}


=head2 AddQuery

   $sph->AddQuery($query, $index);

Add a query to a batch request.

Batch queries enable searchd to perform internal optimizations,
if possible; and reduce network connection overheads in all cases.

For instance, running exactly the same query with different
groupby settings will enable searched to perform expensive
full-text search and ranking operation only once, but compute
multiple groupby results from its output.

Parameters are exactly the same as in Query() call.

Returns corresponding index to the results array returned by RunQueries() call.

=cut

sub AddQuery {
    my $self = shift;
    my $query = shift;
    my $index = shift || '*';
    my $comment = shift || '';

    ##################
    # build request
    ##################

    my $req;
    $req = pack ( "NNNNN", $self->{_query_flags}, $self->{_offset}, $self->{_limit}, $self->{_mode}, $self->{_ranker}); # mode and limits

    if ($self->{_ranker} == SPH_RANK_EXPR) {
        $req .= pack ( "N/a*", $self->{_rankexpr});
    }
    $req .= pack ( "N", $self->{_sort} ); # (deprecated) sort mode
    $req .= pack ( "N/a*", $self->{_sortby});
    $req .= pack ( "N/a*", $self->{_string_encoder}->($query) ); # query itself
    $req .= pack ( "N*", scalar(@{$self->{_weights}}), @{$self->{_weights}});
    $req .= pack ( "N/a*", $index); # indexes
    $req .= pack ( "N", 1) 
        . $self->_sphPackU64($self->{_min_id})
        . $self->_sphPackU64($self->{_max_id}); # id64 range

    # filters
    $req .= pack ( "N", scalar @{$self->{_filters}} );
    foreach my $filter (@{$self->{_filters}}) {
        $req .= pack ( "N/a*", $filter->{attr});
        $req .= pack ( "N", $filter->{type});

        my $t = $filter->{type};
        if ($t == SPH_FILTER_VALUES) {
            $req .= $self->_sphPackI64array($filter->{values});
        }
        elsif ($t == SPH_FILTER_RANGE) {
            $req .= $self->_sphPackI64($filter->{min}) . $self->_sphPackI64($filter->{max});
        }
        elsif ($t == SPH_FILTER_FLOATRANGE) {
            $req .= _PackFloat ( $filter->{"min"} ) . _PackFloat ( $filter->{"max"} );
        }
        elsif ($t == SPH_FILTER_STRING) {
            $req .= pack ( "N/a*", $filter->{value});
        }
        else {
            croak("Unhandled filter type $t");
        }
        $req .= pack ( "N",  $filter->{exclude});
    }

    # group-by clause, max-matches count, group-sort clause, cutoff count
    $req .= pack ( "NN/a*", $self->{_groupfunc}, $self->{_groupby} );
    $req .= pack ( "N", $self->{_maxmatches} );
    $req .= pack ( "N/a*", $self->{_groupsort});
    $req .= pack ( "NNN", $self->{_cutoff}, $self->{_retrycount}, $self->{_retrydelay} );
    $req .= pack ( "N/a*", $self->{_groupdistinct});

    if (!defined $self->{_anchor}) {
        $req .= pack ( "N", 0);
    }
    else {
        my $a = $self->{_anchor};
        $req .= pack ( "N", 1);
        $req .= pack ( "N/a*", $a->{attrlat});
        $req .= pack ( "N/a*", $a->{attrlong});
        $req .= _PackFloat($a->{lat}) . _PackFloat($a->{long});
    }

    # per-index weights
    $req .= pack( "N", scalar keys %{$self->{_indexweights}});
    $req .= pack ( "N/a*N", $_, $self->{_indexweights}->{$_} ) for keys %{$self->{_indexweights}};

    # max query time
    $req .= pack ( "N", $self->{_maxquerytime} );

    # per-field weights
    $req .= pack ( "N", scalar keys %{$self->{_fieldweights}} );
    $req .= pack ( "N/a*N", $_, $self->{_fieldweights}->{$_}) for keys %{$self->{_fieldweights}};
    # comment
    $req .= pack ( "N/a*", $comment);

    # attribute overrides
    $req .= pack ( "N", scalar keys %{$self->{_overrides}} );
    for my $entry (values %{$self->{_overrides}}) {
        $req .= pack ("N/a*", $entry->{attr})
            . pack ("NN", $entry->{type}, scalar keys %{$entry->{values}});
        for my $id (keys %{$entry->{values}}) {
            croak "Attribute value key is not numeric" unless $id =~ m/$num_re/;
            my $v = $entry->{values}->{$id};
            croak "Attribute value key is not numeric" unless $v =~ m/$num_re/;
            $req .= $self->_sphPackU64($id);
            if ($entry->{type} == SPH_ATTR_FLOAT) {
                $req .= $self->_packfloat($v);
            }
            elsif ($entry->{type} == SPH_ATTR_BIGINT) {
                $req .= $self->_sphPackI64($v);
            }
            else {
                $req .= pack("N", $v);
            }
        }
    }
    
    # select list
    $req .= pack("N/a*", $self->{_select} || '');

    # max_predicted_time
    if ($self->{_predictedtime} > 0) {
        $req .= pack ( "N", $self->{_predictedtime} );
    }

    $req .= pack ( "N/a*", $self->{_outerorderby});
    $req .= pack ( "NN", $self->{_outeroffset}, $self->{_outerlimit} );
    $req .= pack ("N", $self->{_hasouter} ? 1 : 0 );

    push(@{$self->{_reqs}}, $req);

    return scalar $#{$self->{_reqs}};
}

=head2 RunQueries

    $sph->RunQueries

Run batch of queries, as added by AddQuery.

Returns undef on network IO failure.

Returns an array of result sets on success.

Each result set in the returned array is a hash which contains
the same keys as the hash returned by L<Query>, plus:

=over 4 

=item * error 

Errors, if any, for this query.

=item * warning
        
Any warnings associated with the query.

=back

=cut

sub RunQueries {
    my $self = shift;

    unless (@{$self->{_reqs}}) {
        $self->_Error("no queries defined, issue AddQuery() first");
        return;
    }

    ##################
    # send query, get response
    ##################
    my $nreqs = @{$self->{_reqs}};
    my $req = pack("NNa*", 0, $nreqs, join("", @{$self->{_reqs}}));
    $req = pack ( "nnN/a*", SEARCHD_COMMAND_SEARCH, VER_COMMAND_SEARCH, $req); # add header
    my $response = $self->_ProcessRequest($req, VER_COMMAND_SEARCH);
    $self->{_reqs} = [];
    return unless $response;

    ##################
    # parse response
    ##################

    my $p = 0;
    my $max = length($response); # Protection from broken response

    my @results;
    for (my $ires = 0; $ires < $nreqs; $ires++) {
        my $result = {};        # Empty hash ref
        push(@results, $result);
        $result->{matches} = []; # Empty array ref
        $result->{error} = "";
        $result->{warning} = "";

        # extract status
        my $status = unpack("N", substr ( $response, $p, 4 ) ); $p += 4;
        if ($status != SEARCHD_OK) {
            my $len = unpack("N", substr ( $response, $p, 4 ) ); $p += 4;
            my $message = substr ( $response, $p, $len ); $p += $len;
            if ($status == SEARCHD_WARNING) {
                $result->{warning} = $message;
            }
            else {
                $result->{error} = $message;
                next;
            }       
        }

        # read schema
        my @fields;
        my (%attrs, @attr_list);

        my $nfields = unpack ( "N", substr ( $response, $p, 4 ) ); $p += 4;
        while ( $nfields-->0 && $p<$max ) {
            my $len = unpack ( "N", substr ( $response, $p, 4 ) ); $p += 4;
            push(@fields, substr ( $response, $p, $len )); $p += $len;
        }
        $result->{"fields"} = \@fields;

        my $nattrs = unpack ( "N*", substr ( $response, $p, 4 ) ); $p += 4;
        while ( $nattrs-->0 && $p<$max  ) {
            my $len = unpack ( "N*", substr ( $response, $p, 4 ) ); $p += 4;
            my $attr = substr ( $response, $p, $len ); $p += $len;
            my $type = unpack ( "N*", substr ( $response, $p, 4 ) ); $p += 4;
            $attrs{$attr} = $type;
            push(@attr_list, $attr);
        }
        $result->{"attrs"} = \%attrs;

        # read match count
        my $count = unpack ( "N*", substr ( $response, $p, 4 ) ); $p += 4;
        my $id64 = unpack ( "N*", substr ( $response, $p, 4 ) ); $p += 4;

        # read matches
        while ( $count-->0 && $p<$max ) {
            my $data = {};
            if ($id64) {
                $data->{doc} = $self->_sphUnpackU64(substr($response, $p, 8)); $p += 8;
                $data->{weight} = unpack("N*", substr($response, $p, 4)); $p += 4;
            }
            else {
                ( $data->{doc}, $data->{weight} ) = unpack("N*N*", substr($response,$p,8));
                $p += 8;
            }
            foreach my $attr (@attr_list) {
                if ($attrs{$attr} == SPH_ATTR_BIGINT) {
                    $data->{$attr} = $self->_sphUnpackI64(substr($response, $p, 8)); $p += 8;
                    next;
                }
                if ($attrs{$attr} == SPH_ATTR_FLOAT) {
                    my $uval = unpack( "N*", substr ( $response, $p, 4 ) ); $p += 4;
                    $data->{$attr} = [ unpack("f*", pack("L", $uval)) ];
                    next;
                }
                my $val = unpack ( "N*", substr ( $response, $p, 4 ) ); $p += 4;
                if ($attrs{$attr} == SPH_ATTR_MULTI) {
                    my $nvalues = $val;
                    $data->{$attr} = [];
                    while ($nvalues-- > 0 && $p < $max) {
                        $val = unpack( "N*", substr ( $response, $p, 4 ) ); $p += 4;
                        push(@{$data->{$attr}}, $val);
                    }
                }
                elsif ($attrs{$attr} == SPH_ATTR_MULTI64) {
                    my $nvalues = $val;
                    $data->{$attr} = [];
                    while ($nvalues > 0 && $p < $max) {
                        $val = unpack( "q*", substr ( $response, $p, 8 ) ); $p += 8;
                        push(@{$data->{$attr}}, $val);
                        $nvalues -= 2;
                    }
                }
                elsif ($attrs{$attr} == SPH_ATTR_STRING) {
                    $data->{$attr} = $self->{_string_decoder}->(substr ($response, $p, $val));
                    $p += $val;
                }
                elsif ($attrs{$attr} == SPH_ATTR_FACTORS) {
                    $data->{$attr} = $self->{_string_decoder}->(substr ($response, $p, $val - 4));
                    $p += $val - 4;
                }
                else {
                    $data->{$attr} = $val;
                }
            }
            push(@{$result->{matches}}, $data);
        }
        my $words;
        ($result->{total}, $result->{total_found}, $result->{time}, $words) = unpack("N*N*N*N*", substr($response, $p, 16));
        $result->{time} = sprintf ( "%.3f", $result->{"time"}/1000 );
        $p += 16;

        while ( $words-->0 && $p < $max) {
            my $len = unpack ( "N*", substr ( $response, $p, 4 ) ); 
            $p += 4;
            my $word = $self->{_string_decoder}->( substr ( $response, $p, $len ) ); 
            $p += $len;
            my ($docs, $hits) = unpack ("N*N*", substr($response, $p, 8));
            $p += 8;
            $result->{words}{$word} = {
                "docs" => $docs,
                "hits" => $hits
                };
        }
    }

    return \@results;
}

=head2 SphinxQL

  my $results = $sph->SphinxQL($sphinxql_query);

This is an alternative implementation of the SphinxQL API to the DBI option. Frankly, it was an experiment, and the DBI driver proved to have much better performance. Whilst this may be useful to some, in general if you are considering using this method then you should probably look at connecting directly via DBI instead.

Results are return in a hash containing an array of 'columns' and 'rows' and possibly a warning count. If a server-side error occurs, the hash contains the 'error' field. If a communication error occurs, the return value will be undefined. In either error case, GetLastError will return the error.

=cut

sub SphinxQL {
    my ($self, $ql) = @_;

    my $req = pack ("N/a*", $self->{_string_encoder}->($ql));
    $req = pack ( "nnN/a*", SEARCHD_COMMAND_SPHINXQL, VER_COMMAND_SPHINXQL, $req); # add header
    my $response = $self->_ProcessRequest($req, VER_COMMAND_SPHINXQL);

    return if ! $response;

    my ($result) = $self->_mysql_unpack_table($response, 0, length($response));

    return $result;
}

sub _mysql_unpack_header {
    my ($self, $response, $p) = @_;

    my $max = length($response);
    return (undef, undef, $p, 1, undef, undef) if $p == $max;
    $self->_Throw("Decode pointer ($p) beyond end of buffer ($max)") if $p > $max;

    my $header = unpack ( "L<", substr( $response, $p, 4 ) ); $p += 4; # packet ID << 24 | packet length
    my $packet_id = $header >> 24;
    my $packet_len = $header & 0x00FFFFFF;
    return ($packet_id, $packet_len, $p, 1, undef, undef) if $packet_len == 0;

    # Peek for EOF or error
    my ($is_eof, $warns, $more_results);
    my $peek_byte = unpack("C", substr($response, $p, 1));
    if ($packet_len == 5 && $peek_byte == 0xfe) { # EOF
        $is_eof = 1;
        $p += 1;                # 0xFE
        my $warns = unpack ( "L<", substr( $response, $p, 4 ) ); $p += 4;
        my $more_results = (($warns >> 16) & 8) != 0; # SPH_MYSQL_FLAG_MORE_RESULTS = 8
        $warns &= 0xFFFF;
    }
    elsif ($peek_byte == 0xff) {
        $p += 1;                # 0xFF
        my $error_code = unpack ( "S<", substr( $response, $p, 2 ) ); $p += 2;
        my $error_code2 = unpack("a*", substr($response, $p, 6)); $p += 6;
        my $len = $packet_len - 9;
        my $err_msg = $self->{_string_decoder}->(unpack("a*", substr($response, $p, $len))); $p += $len;
        $self->_Throw("Error Code $error_code: $error_code2 $err_msg");
    }
    return ($packet_id, $packet_len, $p, $is_eof, $warns, $more_results);
}

sub _mysql_unpack_table {
    my ($self, $response, $p, $max) = @_;

    my ($columns, $warns, $more_results, $rows);

    eval {
        ($columns, $warns, $more_results, $p) = $self->_mysql_unpack_table_header($response, $p);
        ($rows, $p, $warns, $more_results) = $self->_mysql_unpack_table_rows($response, $p, $max, $columns);
    };
    if (my $e = $@) {
        $self->_Error($e);
        return ({ error => $e }, $p);
    }

    my %result = (columns => $columns,
                  rows => $rows,
                  warnings => $warns,
              );
    return (\%result, $p);
}

sub _mysql_unpack_table_header {
    my ($self, $response, $p) = @_;

    my @columns;

    # table header begin
    my ($packet_id, $packet_len, $is_eof, $warns, $more_results);
    ($packet_id, $packet_len, $p, $is_eof, $warns, $more_results) = $self->_mysql_unpack_header($response, $p);

    if (! $is_eof) {
        my $ncols;
        ($ncols, $p) = $self->_mysql_unpack_varint($response, $p);

        # column info
        for my $i (0 .. $ncols - 1) {
            ($columns[$i], $p) = $self->_mysql_unpack_field_packet($response, $p);
        }

        # table header end
        ($packet_id, $packet_len, $p, $is_eof, $warns, $more_results) = $self->_mysql_unpack_header($response, $p);
    }
    return (\@columns, $warns, $more_results, $p);
}

sub _mysql_unpack_table_rows {
    my ($self, $response, $p, $max, $columns) = @_;

    my @rows;
    my ($warns, $more_results);
    while ($p < $max) {
        my $row;
        ($row, $p, $warns, $more_results) = $self->_mysql_unpack_table_row($response, $p, $columns);
        if ($row) {
            push(@rows, $row);
        }
        else {
            last;
        }
    }
    return (\@rows, $p, $warns, $more_results);
}

sub _mysql_unpack_table_row {
    my ($self, $response, $p, $columns) = @_;

    my ($packet_id, $packet_len, $is_eof, $warns, $more_results);
    ($packet_id, $packet_len, $p, $is_eof, $warns, $more_results) = $self->_mysql_unpack_header($response, $p);
    if ($is_eof) {
        return(undef, $p, $warns, $more_results);
    }

    my @row;
    for my $col (@$columns) {
        my $val;
        if ($col->{column_type} == MYSQL_COL_STRING) {
            ($val, $p) = $self->_mysql_unpack_string($response, $p, 1);
        }
        else {
            ($val, $p) = $self->_mysql_unpack_string($response, $p);
        }
        push(@row, $val);
    }
    return (\@row, $p);
}


sub _mysql_unpack_varint {
    my ($self, $response, $p) = @_;

    my $prefix = unpack("C", substr($response, $p, 1)); $p += 1;
    if ($prefix < 251) {
        return ($prefix, $p);
    }
    if ($prefix == 0xFC) {
        $prefix = unpack("S<", substr($response, $p, 2)); $p += 2;
        return ($prefix, $p);
    }
    if ($prefix == 0xFC) {
        $prefix = unpack("S<", substr($response, $p, 2)); $p += 2;
        $prefix += unpack("C", substr($response, $p, 1)) << 16; $p += 1;
        return ($prefix, $p);
    }
    if ($prefix == 0xFE) {
        $prefix = unpack("L<", substr($response, $p, 4)); $p += 4;
    }
    $p += 4; # discard 4 null bytes
    return ($prefix, $p);
}

sub _mysql_unpack_string {
    my ($self, $response, $p, $decode) = @_;

    my $len;
    ($len, $p) = $self->_mysql_unpack_varint($response, $p);
    my $s = substr($response, $p, $len); $p += $len;
    $s = $self->{_string_decoder}->($s) if $decode;

    return ($s, $p);
}

sub _mysql_unpack_field_packet {
    my ($self, $response, $p) = @_;

    my ($packet_id, $packet_len, $is_eof, $warns, $more_results);
    ($packet_id, $packet_len, $p, $is_eof, $warns, $more_results) = $self->_mysql_unpack_header($response, $p);

    my %field;
    ($field{catalog}, $p) = $self->_mysql_unpack_string($response, $p);
    ($field{db}, $p) = $self->_mysql_unpack_string($response, $p);
    ($field{table}, $p) = $self->_mysql_unpack_string($response, $p);
    ($field{org_table}, $p) = $self->_mysql_unpack_string($response, $p);
    ($field{name}, $p) = $self->_mysql_unpack_string($response, $p);
    ($field{org_name}, $p) = $self->_mysql_unpack_string($response, $p);

    $p += 3; # filler=12, charset_nr=0x21 (utf8)
    $field{column_length} = unpack ( "L<", substr( $response, $p, 4 ) ); $p += 4;
    $field{column_type} = unpack("C", substr($response, $p, 1)); $p += 1;
    $p += 5; # flags, decimals, filler

    return (\%field, $p);
}

=head2 BuildExcerpts

    $excerpts = $sph->BuildExcerpts($docs, $index, $words, $opts)

Generate document excerpts for the specified documents.

=over 4

=item docs 

An array reference of strings which represent the document
contents

=item index 

A string specifiying the index whose settings will be used
for stemming, lexing and case folding

=item words 

A string which contains the words to highlight

=item opts 

A hash which contains additional optional highlighting parameters:

=over 4

=item before_match - a string to insert before a set of matching words, default is "<b>"

=item after_match - a string to insert after a set of matching words, default is "<b>"

=item chunk_separator - a string to insert between excerpts chunks, default is " ... "

=item limit - max excerpt size in symbols (codepoints), default is 256

=item limit_passages - Limits the maximum number of passages that can be included into the snippet. Integer, default is 0 (no limit).

=item limit_words - Limits the maximum number of keywords that can be included into the snippet. Integer, default is 0 (no limit). 

=item around - how many words to highlight around each match, default is 5

=item exact_phrase - whether to highlight exact phrase matches only, default is false

=item single_passage - whether to extract single best passage only, default is false

=item use_boundaries

=item weight_order - Whether to sort the extracted passages in order of relevance (decreasing weight), or in order of appearance in the document (increasing position). Boolean, default is false.

=item query_mode - Whether to handle $words as a query in extended syntax, or as a bag of words (default behavior). For instance, in query mode ("one two" | "three four") will only highlight and include those occurrences "one two" or "three four" when the two words from each pair are adjacent to each other. In default mode, any single occurrence of "one", "two", "three", or "four" would be highlighted. Boolean, default is false. 

=item force_all_words - Ignores the snippet length limit until it includes all the keywords. Boolean, default is false. 

=item start_passage_id - Specifies the starting value of %PASSAGE_ID% macro (that gets detected and expanded in before_match, after_match strings). Integer, default is 1. 

=item load_files - Whether to handle $docs as data to extract snippets from (default behavior), or to treat it as file names, and load data from specified files on the server side. Boolean, default is false. 

=item html_strip_mode - HTML stripping mode setting. Defaults to "index", which means that index settings will be used. The other values are "none" and "strip", that forcibly skip or apply stripping irregardless of index settings; and "retain", that retains HTML markup and protects it from highlighting. The "retain" mode can only be used when highlighting full documents and thus requires that no snippet size limits are set. String, allowed values are "none", "strip", "index", and "retain".

=item allow_empty - Allows empty string to be returned as highlighting result when a snippet could not be generated (no keywords match, or no passages fit the limit). By default, the beginning of original text would be returned instead of an empty string. Boolean, default is false. 

=item passage_boundary

=item emit_zones

=item load_files_scattered

=back

=back

Returns undef on failure.

Returns an array ref of string excerpts on success.

=cut

sub BuildExcerpts {
        my ($self, $docs, $index, $words, $opts) = @_;
        $opts ||= {};
        croak("BuildExcepts() called with incorrect parameters") 
            unless (ref($docs) eq 'ARRAY' 
                    && defined($index) 
                    && defined($words) 
                    && ref($opts) eq 'HASH');

        ##################
        # fixup options
        ##################
        $opts->{"before_match"} ||= "<b>";
        $opts->{"after_match"} ||= "</b>";
        $opts->{"chunk_separator"} ||= " ... ";
        $opts->{"limit"} ||= 256;
        $opts->{"limit_passages"} ||= 0;
        $opts->{"limit_words"} ||= 0;
        $opts->{"around"} ||= 5;
        $opts->{"exact_phrase"} ||= 0;
        $opts->{"single_passage"} ||= 0;
        $opts->{"use_boundaries"} ||= 0;
        $opts->{"weight_order"} ||= 0;
        $opts->{"query_mode"} ||= 0;
        $opts->{"force_all_words"} ||= 0;
        $opts->{"start_passage_id"} ||= 1;
        $opts->{"load_files"} ||= 0;
        $opts->{"html_strip_mode"} ||= "index";
        $opts->{"allow_empty"} ||= 0;
        $opts->{"passage_boundary"} ||= "none";
        $opts->{"emit_zones"} ||= 0;
        $opts->{"load_files_scattered"} ||= 0;

        ##################
        # build request
        ##################

        # v.1.2 req
        my $req;
        my $flags = 1; # remove spaces
        $flags |= 2 if ( $opts->{"exact_phrase"} );
        $flags |= 4 if ( $opts->{"single_passage"} );
        $flags |= 8 if ( $opts->{"use_boundaries"} );
        $flags |= 16 if ( $opts->{"weight_order"} );
        $flags |= 32 if ( $opts->{"query_mode"} );
        $flags |= 64 if ( $opts->{"force_all_words"} );
        $flags |= 128 if ( $opts->{"load_files"} );
        $flags |= 256 if ( $opts->{"allow_empty"} );
        $flags |= 512 if ( $opts->{"emit_zones"} );
        $flags |= 1024 if ( $opts->{"load_files_scattered"} );
        $req = pack ( "NN", 0, $flags ); # mode=0, flags=$flags

        $req .= pack ( "N/a*", $index ); # req index
        $req .= pack ( "N/a*", $self->{_string_encoder}->($words)); # req words

        # options
        $req .= pack ( "N/a*", $opts->{"before_match"});
        $req .= pack ( "N/a*", $opts->{"after_match"});
        $req .= pack ( "N/a*", $opts->{"chunk_separator"});
        $req .= pack ( "NN", int($opts->{"limit"}), int($opts->{"around"}) );
        $req .= pack ( "NNN", int($opts->{"limit_passages"}), 
                       int($opts->{"limit_words"}), 
                       int($opts->{"start_passage_id"}) ); # v1.2
        $req .= pack ( "N/a*", $opts->{"html_strip_mode"});
        $req .= pack ( "N/a*", $opts->{"passage_boundary"});

        # documents
        $req .= pack ( "N", scalar(@$docs) );
        foreach my $doc (@$docs) {
                croak('BuildExcerpts: Found empty document in $docs') unless ($doc);
                $req .= pack("N/a*", $self->{_string_encoder}->($doc));
        }

        ##########################
        # send query, get response
        ##########################

        $req = pack ( "nnN/a*", SEARCHD_COMMAND_EXCERPT, VER_COMMAND_EXCERPT, $req); # add header
        my $response = $self->_ProcessRequest($req, VER_COMMAND_EXCERPT);
        return unless $response;
        my ($pos, $i) = 0;
        my $res = [];   # Empty hash ref
        my $rlen = length($response);
        for ( $i=0; $i< scalar(@$docs); $i++ ) {
                my $len = unpack ( "N*", substr ( $response, $pos, 4 ) );
                $pos += 4;

                if ( $pos+$len > $rlen ) {
                        $self->_Error("incomplete reply");
                        return;
                }
                push(@$res, $self->{_string_decoder}->( substr ( $response, $pos, $len ) ));
                $pos += $len;
        }
        return $res;
}


=head2 BuildKeywords

    $results = $sph->BuildKeywords($query, $index, $hits)

Generate keyword list for a given query
Returns undef on failure,
Returns an array of hashes, where each hash describes a word in the query with the following keys:

=over 4

=item * tokenized 

Tokenised term from query

=item * normalized 

Normalised term from query

=item * docs 

Number of docs in which word was found (if $hits is true)

=item * hits 

Number of occurrences of word (if $hits is true)

=back

=cut

sub BuildKeywords {
    my ( $self, $query, $index, $hits ) = @_;


    # v.1.0 req
    my $req = pack("N/a*", $self->{_string_encoder}->($query) );
    $req .= pack("N/a*", $index);
    $req .= pack("N", $self->{_string_encoder}->($hits) );

    ##################
    # send query, get response
    ##################

    $req = pack ( "nnN/a*", SEARCHD_COMMAND_KEYWORDS, VER_COMMAND_KEYWORDS, $req);
    my $response = $self->_ProcessRequest($req, VER_COMMAND_KEYWORDS);
    return unless $response;

    ##################
    # parse response
    ##################

    my $p = 0;
    my @res;
    my $rlen = length($response);

    my $nwords = unpack("N", substr ( $response, $p, 4 ) ); $p += 4;

    for (my $i=0; $i < $nwords; $i++ ) {
        my $len = unpack("N", substr ( $response, $p, 4 ) ); $p += 4;

        my $tokenized = $len ? $self->{_string_decoder}->( substr ( $response, $p, $len ) ) : ""; $p += $len;
        $len = unpack("N", substr ( $response, $p, 4 ) ); $p += 4;

        my $normalized = $len ? $self->{_string_decoder}->( substr ( $response, $p, $len ) ) : ""; $p += $len;
        my %data = ( tokenized => $tokenized, normalized => $normalized );
        
        if ($hits) {
            ( $data{docs}, $data{hits} ) = unpack("N*N*", substr($response,$p,8));
            $p += 8;
            
        }
        push(@res, \%data);
    }
    if ( $p > $rlen ) {
        $self->_Error("incomplete reply");
        return;
    }

    return \@res;
}

=head2 EscapeString

    $escaped = $sph->EscapeString('abcde!@#$%')

Inserts backslash before all non-word characters in the given string.

=cut

sub EscapeString {
    my $self = shift;
    return quotemeta(shift);
}


=head2 UpdateAttributes

    $sph->UpdateAttributes($index, \@attrs, \%values);
    $sph->UpdateAttributes($index, \@attrs, \%values, $mva);
    $sph->UpdateAttributes($index, \@attrs, \%values, $mva, $ignorenonexistent);

Update specified attributes on specified documents

=over 4

=item index 

Name of the index to be updated

=item attrs 

Array of attribute name strings

=item values 

A hash with key as document id, value as an array of new attribute values

=item mva

If set, indicates that there is update of MVA attributes

=item ignorenonexistent

If set, the update will silently ignore any warnings about trying to update a column which is not exists in current index schema.

=back

Returns number of actually updated documents (0 or more) on success

Returns undef on failure

Usage example:

 $sph->UpdateAttributes("test1", [ qw/group_id/ ], { 1 => [ 456] }) );

=cut

sub UpdateAttributes  {
    my ($self, $index, $attrs, $values, $mva, $ignorenonexistent ) = @_;

    croak("index is not defined") unless (defined $index);
    croak("attrs must be an array") unless ref($attrs) eq "ARRAY";
    for my $attr (@$attrs) {
        croak("attribute is not defined") unless (defined $attr);
    }
    croak("values must be a hashref") unless ref($values) eq "HASH";

    for my $id (keys %$values) {
        my $entry = $values->{$id};
        croak("value id $id is not numeric") unless ($id =~ /$num_re/);
        croak("value entry must be an array") unless ref($entry) eq "ARRAY";
        croak("size of values must match size of attrs") unless @$entry == @$attrs;
        for my $v (@$entry) {
            if ($mva) {
                croak("multi-valued entry $v is not an array") unless ref($v) eq 'ARRAY';
                for my $vv (@$v) {
                    croak("array entry value $vv is not an integer") unless ($vv =~ /^(\d+)$/o);
                }
            }
            else { 
                croak("entry value $v is not an integer") unless ($v =~ /^(\d+)$/o);
            }
        }
    }

    ## build request
    my $req = pack ( "N/a*", $index);

    $req .= pack ( "N", scalar @$attrs );
    $req .= pack ( "N", $ignorenonexistent ? 1 : 0 );
    for my $attr (@$attrs) {
        $req .= pack ( "N/a*", $attr)
            . pack("N", $mva ? 1 : 0);
    }
    $req .= pack ( "N", scalar keys %$values );
    foreach my $id (keys %$values) {
        my $entry = $values->{$id};
        $req .= $self->_sphPackU64($id);
        if ($mva) {
            for my $v ( @$entry ) {
                $req .= pack ( "N", @$v );
                for my $vv (@$v) {
                    $req .= pack ("N", $vv);
                }
            }
        }
        else {
            for my $v ( @$entry ) {
                $req .= pack ( "N", $v );
            }
        }
    }

    ## connect, send query, get response

    $req = pack ( "nnN/a*", SEARCHD_COMMAND_UPDATE, VER_COMMAND_UPDATE, $req); ## add header
    my $response = $self->_ProcessRequest($req, VER_COMMAND_UPDATE);

    return unless $response;

    ## parse response
    my ($updated) = unpack ( "N*", substr ( $response, 0, 4 ) );
    return $updated;
}

=head2 Open

    $sph->Open()

Opens a persistent connection for subsequent queries.  

To reduce the network connection overhead of making Sphinx queries, you can call
$sph->Open(), then run any number of queries, and call $sph->Close() when
finished.

Returns 1 on success, 0 on failure.

=cut 

sub Open {
    my $self = shift;
    $self->{_persistent} = 1;
    if ($self->{_socket}) {
    $self->_Error("already connected");
    return 0;
    }
    my $fp = $self->_Connect() or return 0;
    return 1;
}

=head2 Close

    $sph->Close()

Closes a persistent connection.

Returns 1 on success, 0 on failure.

=cut 

sub Close {
    my $self = shift;
    $self->{_persistent} = 0;

    if (! $self->{_socket}) {
        $self->_Error("not connected");
        return 0;
    }
    
    close($self->{_socket});
    $self->{_socket} = undef;

    return 1;
}

=head2 Status

    $status = $sph->Status()
    $status = $sph->Status($session)

Queries searchd status, and returns a hash of status variable name and value pairs. 

Returns undef on failure.

=cut

sub Status {
    
    my ($self, $session) = @_;

    my $req = pack("nnNN", SEARCHD_COMMAND_STATUS, VER_COMMAND_STATUS, 4, $session ? 0 : 1 ); # len=4, body=1

    my $response = $self->_ProcessRequest($req, VER_COMMAND_STATUS);
    return unless $response;

    my $p = 0;
    my ($rows, $cols) = unpack("N*N*", substr ( $response, $p, 8 ) ); $p += 8;

    return {} unless $rows && $cols;
    my %res;
    for (1 .. $rows ) {
        my @entry;
        for ( 1 .. $cols) {
            my $len = unpack("N*", substr ( $response, $p, 4 ) ); $p += 4;
            push(@entry, $len ? substr ( $response, $p, $len ) : ""); $p += $len;
        }
        if ($cols <= 2) {
            $res{$entry[0]} = $entry[1];
        }
        else {
            my $name = shift @entry;
            $res{$name} = \@entry;
        }
    }
    return \%res;
}
    
=head2 FlushAttributes

=cut

sub FlushAttributes {
    my $self = shift;
    
    my $req = pack("nnN", SEARCHD_COMMAND_FLUSHATTRS, VER_COMMAND_FLUSHATTRS, 0 ); # len=0
    my $response = $self->_ProcessRequest($req, VER_COMMAND_FLUSHATTRS);
    return unless $response;
    
    my $tag = -1;
    if (length($response) == 4) {
        $tag = unpack ( "N*", substr ( $response, 0, 4 ) );
    }
    else {
        $self->_Error("unexpected response length");
    }
    return $tag;
}    

=head1 SEE ALSO

L<http://www.sphinxsearch.com>

=head1 NOTES

There is (or was) a bundled Sphinx.pm in the contrib area of the Sphinx source
distribution, which was used as the starting point of Sphinx::Search.
Maintenance of that version appears to have lapsed at sphinx-0.9.7, so many of
the newer API calls are not available there.  Sphinx::Search is mostly
compatible with the old Sphinx.pm except:

=over 4

=item On failure, Sphinx::Search returns undef rather than 0 or -1.

=item Sphinx::Search 'Set' functions are cascadable, e.g. you can do
      Sphinx::Search->new
        ->SetMatchMode(SPH_MATCH_ALL)
        ->SetSortMode(SPH_SORT_RELEVANCE)
        ->Query("search terms")

=back

Sphinx::Search also provides documentation and unit tests, which were the main
motivations for branching from the earlier work.

=head1 AUTHOR

Jon Schutz

L<http://notes.jschutz.net>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-sphinx-search at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sphinx-Search>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sphinx::Search

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sphinx-Search>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Sphinx-Search>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Sphinx-Search>

=item * Search CPAN

L<http://search.cpan.org/dist/Sphinx-Search>

=back

=head1 ACKNOWLEDGEMENTS

This module is based on Sphinx.pm (not deployed to CPAN) for Sphinx version
0.9.7-rc1, by Len Kranendonk, which was in turn based on the Sphinx PHP API.

Thanks to Alexey Kholodkov for contributing a significant patch for handling persistent connections.

=head1 COPYRIGHT & LICENSE

Copyright 2015 Jon Schutz, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License.

=cut


1;
