package Net::MythTV::Fuse::Recordings;

=head1 NAME

Net::MythTV::Fuse::Recordings - Manage list of MythTV recordings for MythTV Fuse filesystem

=head1 SYNOPSIS

 $recordings = Net::MythTV::Fuse::Recordings->new({backend   => 'mythbackend.domain.org',
                                                   pattern   => '%C/%T/%S',
                                                   cachetime => 120,
                                                   maxgets   => 6,
                                                   threaded  => 1,
                                                   debug     => 1}
                                                 );
 $recordings->start_update_thread();
 @paths = $recordings->entries('.');
 $recordings->valid_path('Firefly/Serenity.mpg') or die;
 $recordings->is_dir('Firefly')                  or die;
 ($status,$content) = $recordings->download_recorded_file('Firefly/Serenity.mpg',1024,0);

=head1 DESCRIPTION

This is a utility class used by Net::MythTV::Fuse which handles all
interaction with the backend. Using the MythTV 0.25 API, the module
maintains a cache of current recordings, translates them into a series
of virtual directory listings according to a template, and can
download segments of individual recordings from a local or remote
backend.

=head1 METHODS

=cut


use strict;
use POSIX 'strftime';
use LWP::UserAgent;
use JSON qw(encode_json decode_json);
use Date::Parse 'str2time';
use XML::Simple;
use threads;
use threads::shared;
use Thread::Semaphore;
use Config;
use Carp 'croak';

use constant CACHETIME => 60*5;  # 5 minutes
use constant MAXGETS   => 8;     # allow 8 simultaneous http gets 

# This single shared variable caches the recorded list from the backend as a JSONized string.
# Within each thread, the list is then unserialized and temporarily cached in each thread's memory.
my %Cache    :shared;

use constant Templates => {
    T  => '{Title}',
    S  => '{SubTitle}',
    R  => '{Description}',
    C  => '{Category}',
    ST => '{SubTitle}?{SubTitle}:{Title}',   # prefer %S?%S:%T
    TC => '{SubTitle}?{Title}:{Category}',   # prefer %S?%T:%C
    se => '{Season}',
    e  => '{Episode}',
    PI => '{ProgramId}',
    SI => '{SeriesId}',
    st => '{Stars}',
    U  => '{Recording}{RecGroup}',
    hn => '{HostName}',
    c  => '{Channel}{ChanId}',
    cc => '{Channel}{CallSign}',
    cN => '{Channel}{ChannelName}',
    cn => '{Channel}{ChanNum}',

    y  => '%y{StartTime}',
    Y  => '%Y{StartTime}',
    n  => '%m{StartTime}',  # we don't do the non-leading 0 bit
    m  => '%m{StartTime}',
    j  => '%e{StartTime}',
    d  => '%d{StartTime}',
    g  => '%I{StartTime}',
    G  => '%H{StartTime}',
    h  => '%I{StartTime}',
    H  => '%H{StartTime}',
    i  => '%M{StartTime}',
    s  => '%S{StartTime}',
    a  => '%P{StartTime}',
    A  => '%p{StartTime}',
    b  => '%b{StartTime}',
    B  => '%B{StartTime}',

    ey  => '%y{EndTime}',
    eY  => '%Y{EndTime}',
    en  => '%m{EndTime}',
    em  => '%m{EndTime}',
    ej  => '%e{EndTime}',
    ed  => '%d{EndTime}',
    eg  => '%I{EndTime}',
    eG  => '%H{EndTime}',
    eh  => '%I{EndTime}',
    eH  => '%H{EndTime}',
    ei  => '%M{EndTime}',
    es  => '%S{EndTime}',
    ea  => '%P{EndTime}',
    eA  => '%p{EndTime}',
    eb  => '%b{EndTime}',
    eB  => '%B{EndTime}',

    # the API doesn't distinguish between program start time and recording start time
    py  => '%y{StartTime}',
    pY  => '%Y{StartTime}',
    pn  => '%m{StartTime}',
    pm  => '%m{StartTime}',
    pj  => '%e{StartTime}',
    pd  => '%d{StartTime}',
    pg  => '%I{StartTime}',
    pG  => '%H{StartTime}',
    ph  => '%I{StartTime}',
    pH  => '%H{StartTime}',
    pi  => '%M{StartTime}',
    ps  => '%S{StartTime}',
    pa  => '%P{StartTime}',
    pA  => '%p{StartTime}',
    pb  => '%b{StartTime}',
    pB  => '%B{StartTime}',

    pey  => '%y{EndTime}',
    peY  => '%Y{EndTime}',
    pen  => '%m{EndTime}',
    pem  => '%m{EndTime}',
    pej  => '%e{EndTime}',
    ped  => '%d{EndTime}',
    peg  => '%I{EndTime}',
    peG  => '%H{EndTime}',
    peh  => '%I{EndTime}',
    peH  => '%H{EndTime}',
    pei  => '%M{EndTime}',
    pes  => '%S{EndTime}',
    pea  => '%P{EndTime}',
    peA  => '%p{EndTime}',
    peb  => '%b{EndTime}',
    peB  => '%B{EndTime}',

    oy   => '%y{Airdate}',
    oY   => '%Y{Airdate}',
    on   => '%m{Airdate}', # we don't do the non-leading 0 bit
    om   => '%m{Airdate}',
    oj   => '%e{Airdate}',
    od   => '%d{Airdate}',
    ob   => '%b{Airdate}',
    oB   => '%B{Airdate}',

    '%'  => '%',
    };

my $Package = __PACKAGE__;
foreach (qw(debug backend port dummy_data cache cachetime maxgets threaded
            pattern delimiter mtime localmount semaphore)) {
    eval <<END;
sub ${Package}::${_} {
    my \$self = shift;
    \$self->{$_} = shift if \@_;
    return \$self->{$_};
}
END
}

=head2 $r = Net::MythTV::Fuse::Recordings->new(\%options)

Create a new Recordings object. Options are passed as a hashref and
may contain any of the following keys:

 backend       IP address of the backend (localhost)
 port          Control port for the backend (6544)
 pattern       Template for transforming recordings into paths (%T/%S)
 delimiter     Trim this string from the pathname if it is dangling or occurs multiple times (none)
 cachetime     Maximum time to cache recorded list before refreshing from backend (300 sec)
 maxgets       Maximum number of simultaneous file fetches to perform on backend (8)
 threaded      Run the cache fill process as an ithread (true)
 debug         Turn on debugging messages (false)
 dummy_data_path  For debugging, pass path to backend recording XML listing

See the help text for mythfs.pl for more information on these arguments.

=cut

sub new {
    my $class   = shift;
    my $options = shift;
    $options->{backend} or croak "Usage: $class->new({backend=>\$backend_hostname,\@other_options})";
    
    my $self =  bless {
	backend   => 'localhost',
	port      => 6544,
	pattern   => '%T/%S',
	cachetime => CACHETIME,
	maxgets   => MAXGETS,
	threaded  => $Config{useithreads},
	delimiter => undef,
	debug     => 0,
	%$options,           # these will override
	mtime     => 0,
	cache     => undef,
    },ref $class || $class;

    $self->semaphore(Thread::Semaphore->new($self->maxgets)),
    return $self;
}

=head2 Accessors

These methods get or set the correspondingly-named values:

 debug()
 backend()
 port()
 maxgets()
 threaded()
 pattern()
 delimiter()
 mtime()
 localmount()

These methods are used internally:

 dummy_data()
 cache()
 cachetime()
 semaphore()

=cut

=head2 $r->start_update_thread

Start the thread that periodically fetches and caches the recording
data from the server. Will run as a detached thread until the process
terminates.

=cut

sub start_update_thread {
    my $self = shift;

    $self->_refresh_recorded 
	or croak "Could not contact backend at ",$self->backend,':',$self->port;
    return unless $self->threaded;
    my $thr = threads->create(
	sub {
	    while (1) {
		sleep ($self->cachetime);
		$self->_refresh_recorded;
	    }
	}
	);
    $thr->detach();
}

=head2 $recordings = $r->get_recorded

Return a data structure corresponding to the current recording
list. The data structure is a hashref with two top-level keys:
"directories", which list directory names and their contents, and
"paths" which give size and other attributes for each directory,
subdirectory and file. Here is an example:

 {
  'directories' => {
       '.' => {
               '007 Licence To Kill.mpg' => 1,
               'A Funny Thing Happened on the Way to the Forum.mpg' => 1,
               'Alfred Hitchcock Presents' => 5,
               'American Dad' => 9,
                ...
               },
       'Alfred Hitchcock Presents' => {
               'Back for Christmas.mpg' => 1,
               'Dead Weight.mpg' => 1,
               'Rose Garden.mpg' => 1,
              },
       'American Dad' => {
               'Dr. Klaustus.mpg' => 1,
               'Flirting With Disaster.mpg' => 1,
               'Gorillas in the Mist.mpg' => 1,
              },
         ...
     },
  'paths' => {
       '.' => {
               'ctime' => 1368074100,
               'length' => 240,
               'mtime' => 1368076875,
               'type' => 'directory'
              },
       '007 Licence To Kill.mpg' => {
               'basename' => '1111_20121126200000.mpg',
               'ctime' => 1353978000,
               'host' => 'myth',
               'length' => '21262807708',
               'mtime' => 1357927839,
               'storage' => 'Default',
               'type' => 'file'
              },
       'A Funny Thing Happened on the Way to the Forum.mpg' => {
               'basename' => '1191_20121230000000.mpg',
               'ctime' => 1356843600,
               'host' => 'myth',
               'length' => '12298756208',
               'mtime' => 1357927839,
               'storage' => 'Default',
               'type' => 'file'
              },
         'Alfred Hitchcock Presents' => {
               'ctime' => 1362985200,
               'length' => 5,
               'mtime' => 1362987680,
               'type' => 'directory'
              },
          'Alfred Hitchcock Presents/Back for Christmas.mpg' => {
               'basename' => '1022_20121225153000.mpg',
               'ctime' => 1356467400,
               'host' => 'myth',
               'length' => '647625408',
               'mtime' => 1357927839,
               'storage' => 'Default',
               'type' => 'file'
              },
          'Alfred Hitchcock Presents/Dead Weight.mpg' => {
                 'basename' => '1022_20121207000000.mpg',
                 'ctime' => 1354856400,
                 'host' => 'myth',
                 'length' => '647090360',
                 'mtime' => 1357927839,
                 'storage' => 'Default',
                 'type' => 'file'
               },
             ...
     }

=cut

sub get_recorded {
    my $self = shift;
    my $nocache = shift;
    
    my $cache = $self->cache;

    return $cache if $cache && $nocache;

    $self->_refresh_recorded if !$self->threaded && (time() - $Cache{mtime} >= $self->cachetime);
    return $cache            if $cache && $self->mtime >= $Cache{mtime};

    warn scalar localtime()," refreshing thread-level cache, mtime = $Cache{mtime}\n" if $self->debug;
    lock %Cache;
    $self->mtime($Cache{mtime});
    return $self->cache(decode_json($Cache{recorded}||''));
}

=head2 $path = $r->recording_to_path($metadata)

Given the metadata returned from the backend for a single recording,
transform this into a pathname using the provided template.

=cut

sub recording2path {
    my $self = shift;
    my $recording = shift;
    my $path     = $self->apply_pattern($recording);
    my @components = split '/',$path;

    # trimming operation
    if (my $delimiter = $self->delimiter) {
	foreach (@components) {
	    s/${delimiter}{2,}/$delimiter/g;
	    s/${delimiter}(\s+)/$1/g;
	    s/$delimiter$//;
	}
    }

    return grep {length} @components;
}



=head2 $message = $r->status

Returns the last status message.

=cut

sub status {
    my $self  = shift;
    my $r     = $self->get_recorded;
    my $mtime = localtime($self->mtime);
    return "$mtime: $r->{status}\n";
}

=head2 $time = $r->mtime

Return the time that the status was last updated.

=cut

=head2 @entries = $r->entries($path)

Given a path to a directory in the virtual filesystem, return all
subentries within that directory. Use '.' to indicate the top level
directory.

=cut

sub entries {
    my $self = shift;
    my $path = shift;
    my $r = $self->get_recorded;
    return keys %{$r->{directories}{$path}};
}

=head2 $name = $r->basename($path)

Given a path to a file in the virtual filesystem, returns the basename
of the physical file on the backend's storage disk.

=cut

sub basename {
    my $self = shift;
    my $path = shift;
    my $e = $self->entry($path) or return;
    return $e->{basename};
}

=head2 $entry = $r->entry($path)

Given a path to a file on the virtual filesystem, returns a hashref
that provides length, modification time and basename information about
the recording. This is simply the value of the {path}{$path} key in
the data structure described for get_recorded():

        {'Alfred Hitchcock Presents/Back for Christmas.mpg' => {
               'basename' => '1022_20121225153000.mpg',
               'ctime' => 1356467400,
               'host' => 'myth',
               'length' => '647625408',
               'mtime' => 1357927839,
               'storage' => 'Default',
               'type' => 'file'
              }
        }

=cut

sub entry {
    my $self = shift;
    my $path = shift;
    my $r = $self->get_recorded;
    return $r->{paths}{$path};
}

=head2 $boolean = $r->valid_path($path)

Returns true if the provided path is valid.

=cut

sub valid_path {
    my $self = shift;
    my $path = shift;
    my $r = $self->get_recorded;
    return $r->{paths}{$path};
}


=head2 $boolean = $r->is_dir($path)

Returns true if the provided path is a directory in the virtual filesystem.

=cut

sub is_dir {
    my $self = shift;
    my $path = shift;
    my $r    = $self->get_recorded;
    return $r->{paths}{$path}{type} eq 'directory';
}

=head2 ($status,$content) = $r->download_recorded_file($path,$size,$offset)

Attempts to download the recording corresponding to the indicated
path. $size and $offset allow you to fetch the indicated portion of
the recording.

A two-element list is returned. The first element is a status message,
one of "ok", "not found", "invalid offset", or "connection failed". If
successful, the second element will be the requested content,
otherwise undef.

=cut

sub download_recorded_file {
    my $self = shift;
    my ($path,$size,$offset) = @_;

    my $r    = $self->get_recorded('use_cached');
    my $e    = $r->{paths}{$path} or return 'not found';
    $offset <= $e->{length}       or return 'invalid offset';

    my $basename = $e->{basename};
    # I'm unsure of whether we should use the host in the XML or the designated backend
    my $host     = $e->{host} || $self->backend;  
    my $port     = $self->port;
    my $sg       = $e->{storage};
    my $byterange= $offset.'-'.($offset+$size-1);

    $self->{ua} ||= LWP::UserAgent->new(keep_alive=>20);
    $self->semaphore->down();
    my $response = $self->{ua}->get("http://$host:$port/Content/GetFile?StorageGroup=$sg&FileName=$basename",
				    'Range'       => $byterange);
    $self->semaphore->up();
    $response->is_success or return 'connection failed';
    return ('ok',$response->decoded_content);
}

=head2 $path = $r->apply_pattern($entry)

=cut

sub apply_pattern {
    my $self = shift;
    my $recording = shift;
    no warnings;

    my $pat_sub   = $self->_compile_pattern_sub();
    my $template  = $self->{pattern};

    my $Templates = Templates();
    my @codes     = sort {length($b)<=>length($a)} keys %$Templates;
    my $match     = join('|',@codes);

    $template =~ s/%($match)/$pat_sub->($recording,$1)/eg;
    return $template;
}

sub _compile_pattern_sub {
    my $self = shift;
    return $self->{pattern_sub} if $self->{pattern_sub};

    my $template = $self->{pattern};
    my $Templates= Templates();

    my $sub = "sub {\n";
    $sub   .= "my (\$recording,\$code) = \@_;\n";

    while ($template =~ /%([a-zA-Z%]{1,3})/g) {
	my $code = $1;
	my $field = $Templates->{$code} or next;
	if ($field eq '%') {
	    $sub .= "return '%' if \$code eq '$code';\n";
	    next;
	}
	if ($field =~ /(%\w+)(\{\w+\})/) { #datetime specifier
	    $sub .= "return strftime('$1',localtime(str2time(\$recording->$2)||0)) if \$code eq '$code';\n";
	    next;
	}
	if ($field =~ /(.+)\?(.+)\:(.+)/) {  # something like '{SubTitle}?{SubTitle}:{Title}'
	    $sub .= <<END;
	    if (\$code eq '$code') {
		my \$val = \$recording->$1?\$recording->$2:\$recording->$3;
		\$val  ||= '';
		\$val =~ tr!a-zA-Z0-9_.,&\@:* ^\\![]{}(),?#\$=+%-!_!c;
		return \$val;
	    }
END
    next;
	}

	$sub .= <<END;
	if (\$code eq '$code') {
	    my \$val = \$recording->$field || '';
	    \$val =~ tr!a-zA-Z0-9_.,&\@:* ^\\![]{}(),?#\$=+%-!_!c;
	    return \$val;
	}
END
    ;
    }
    $sub .= "}\n";
    my $s = eval $sub;
    die $@ if $@;
    return $self->{pattern_sub} = $s;
}

sub load_dummy_data {
    my $self = shift;
    my $dummy_data_path = shift;
    open my $fh,$dummy_data_path or croak "$dummy_data_path: $!";
    local $/;
    my $dummy_data = <$fh>;
    $self->dummy_data($dummy_data) if $dummy_data;
}

sub _refresh_recorded {
    my $self = shift;

    print  STDERR scalar(localtime())," Refreshing recording list..." if $self->debug;

    lock %Cache;
    my $var    = {};
    my $parser = XML::Simple->new(SuppressEmpty=>1);
    my ($status,$data) = $self->_fetch_recorded_data();
    $var->{status} = $status;
    if ($status eq 'ok') {
	my $rec = $parser->XMLin($data);
	$self->_build_directory_map($rec,$var);
    } else {
	print STDERR "ERROR: $status..." if $self->debug;
	$var->{paths}{'.'} = {ctime  => time(),
			      mtime  => time(),
			      length => 2,
			      type   => 'directory'};
    }
    $Cache{recorded} = encode_json($var);
    $Cache{mtime}    = time();
    print STDERR "mtime set to $Cache{mtime}\n" if $self->debug;

    return 1;
}

sub _fetch_recorded_data {
    my $self = shift;

    return ('ok',$self->dummy_data) if $self->dummy_data;

    my $host = $self->backend;
    my $port = $self->port;

    $self->{ua} ||= LWP::UserAgent->new(keep_alive=>20);
    my $response = $self->{ua}->get("http://$host:$port/Dvr/GetRecordedList");

    my $status;
    if ($response->is_success) {
	$status = 'ok';
    } else {
	$status = "Recording list request failed with ".$response->status_line;
    }

    return ($status,$response->decoded_content);
}

sub _build_directory_map {
    my $self = shift;
    my ($rec,$map) = @_;

    my $count = 0;
    my (%recordings,%paths);
    for my $r (@{$rec->{Programs}{Program}}) {
	$count++;

	my $sg = $r->{Recording}{StorageGroup};
	next if $sg eq 'LiveTV';

 	my (@path)              = $self->recording2path($r);
	my $key                 = join('-',$r->{HostName},$r->{FileName});  # we use this as our unique ID
	my $path                = join('/',@path);
	$recordings{$key}{path}{$path}++;
	$recordings{$key}{meta} = $r;
	$paths{$path}{$key}++;
    }
    
    # paths that need fixing to be unique
    for my $path (keys %paths) {
	my @keys = keys %{$paths{$path}};
	next unless @keys > 1;

	my $count = 0;
	for my $key (@keys) {
            my $start = $recordings{$key}{meta}{StartTime};
	    $start =~ s/:\d+Z$//;
            
	    my $fixed_path = sprintf("%s_%s-%s",$path,$recordings{$key}{meta}{Channel}{ChanNum},$start);
	    delete $recordings{$key}{path};
	    $recordings{$key}{path}{$fixed_path}++;
	}
    }

    # at this point, we actually build the map that is passed to FUSE
    for my $key (keys %recordings) {

	my ($path) = keys %{$recordings{$key}{path}}; # should only be one unique path at this point

	# take care of the extension
	my $meta     = $recordings{$key}{meta};
	my ($suffix) = $meta->{FileName}    =~ /\.(\w+)$/;
	$path       .= ".$suffix" unless $path =~ /\.$suffix$/;

	my @path = split('/',$path);
	my $filename = pop @path;
	unshift @path,'.';

	my $ctime = str2time($meta->{StartTime});
	my $mtime = str2time($meta->{LastModified});
	
	$map->{paths}{$path}{type}     = 'file';
	$map->{paths}{$path}{host}     = $meta->{HostName};
	$map->{paths}{$path}{length}   = $meta->{FileSize};
	$map->{paths}{$path}{basename} = $meta->{FileName};
	$map->{paths}{$path}{storage}  = $meta->{Recording}{StorageGroup};
	$map->{paths}{$path}{ctime}    = $ctime;
	$map->{paths}{$path}{mtime}    = $mtime;
	
	# take care of the directories
	my $dir = '';
	while (my $p = shift @path) {
	    $dir .= length $dir ? "/$p" : $p;
	    $dir =~ s!^\./!!;

	    $map->{paths}{$dir}{type}     = 'directory';
	    $map->{paths}{$dir}{length}++;
	    $map->{paths}{$dir}{ctime}    = $ctime if ($map->{paths}{$p}{ctime}||0) < $ctime;
	    $map->{paths}{$dir}{mtime}    = $mtime if ($map->{paths}{$p}{mtime}||0) < $mtime;

	    # subdirectory entry
	    if (defined $path[0]) {
		$map->{directories}{$dir}{$path[0]}++;
	    }
	}
	$map->{directories}{$dir}{$filename}++;
    }

    print STDERR scalar keys %recordings," recordings retrieved..." if $self->debug;
    return $map;
}

1;

=head1 AUTHOR

Copyright 2013, Lincoln D. Stein <lincoln.stein@gmail.com>

=head1 LICENSE

This package is distributed under the terms of the Perl Artistic
License 2.0. See http://www.perlfoundation.org/artistic_license_2_0.

=cut

__END__
