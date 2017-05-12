#!/usr/bin/perl -w
use strict;

use Test::More tests => 90;
use Regexp::Log::Common;
use IO::File;

my %lists = (
    'all'           => [ qw(A B D F F F H I O P T V X a authuser b bytes connection date filename h host k keepalive localip logname method p pid port protocol q qs queryatring r ref referer remotehost remoteip req request rfc s seconds servername status t time ts u ua useragent v) ],
    'basic'         => [ qw(host rfc authuser) ],
    'common'        => [ qw(host rfc authuser date request status bytes) ],
    'common2'       => [ qw(host rfc authuser date ts request req status bytes) ],
    'extended'      => [ qw(host rfc authuser date request status bytes referer useragent) ],
    'extended2'     => [ qw(host rfc authuser date ts request req status bytes referer ref useragent ua) ],
    'longhand'      => [ qw(host rfc authuser date request status bytes referer useragent time servername) ],
    'longhand2'     => [ qw(host rfc authuser date ts request req status bytes referer ref useragent ua time servername) ],
    'shorthand'     => [ qw(h logname u t r s b referer useragent D v) ],
    'shorthand2'    => [ qw(h logname u t r s b referer ref useragent ua D v) ],
);

my %forms;
for my $key (keys %lists) {
    $forms{$key} = join(' ',map { '%'.$_ } @{$lists{$key}});
}

my $foo = Regexp::Log::Common->new();
isa_ok($foo, 'Regexp::Log::Common');

# check defaults
is( $foo->format , $forms{extended}, "Default format" );
my @capture = $foo->capture;
is( @capture , 13, "Default capture" );
is( $capture[6] , 'req', "Default captured field" );
is( $foo->comments , 0, "Default comments" );

# check the format method
is( $foo->format($forms{basic}) , $forms{basic}, "Format return new value" );
is( $foo->format , $forms{basic}, "new format value is set" );

# check other formats
$foo = Regexp::Log::Common->new(format => ':default');
is( $foo->format , $forms{common}, "Default format" );
$foo = Regexp::Log::Common->new(format => ':common');
is( $foo->format , $forms{common}, "Common format" );
$foo = Regexp::Log::Common->new(format => ':extended');
is( $foo->format , $forms{extended}, "Extended format" );

# check the fields method
my @fields = sort $foo->fields;
my $i      = 0;
for (sort @{$lists{all}}) {
    is( $fields[ $i++ ] , $_, "Found field $_" );
}

# set the captures
@fields = $foo->capture(':none');
is( @fields , 0, "Capture :none" );
@fields = $foo->capture(':all');
is( @fields , @{$lists{extended2}}, "Capture :all" );

@fields = sort $foo->capture(qw( :none date request ));
is( @fields , 2, "Capture only two fields" );
$i = 0;
for (qw( date request )) {
    is( $fields[ $i++ ] , $_, "Field $_ is captured" );
}

$foo = Regexp::Log::Common->new(format => '%date %authuser %rfc');
@fields = sort $foo->capture;
$i      = 0;
for (qw(authuser date rfc )) {
    is( $fields[ $i++ ] , $_, "Field $_ is captured by :default" );
}

# the comments method
is( $foo->comments(1) , 1, "comments old value" );
is( $foo->comments , 1, "comments new value" );

# the regexp method
is( $foo->regex , $foo->regexp, "regexp() is aliased to regex()" );

$foo->comments(0);
my $regexp = $foo->regexp;
ok( $regexp !~ /\(\?\#.*?\)/, "No comment in regexp" );
$foo->comments(1);

$foo->format('%date');
is( @{ [ $foo->regexp =~ /(\(\?\#.*?\))/g ] } , 4,
    "4 comments for %date in regexp" );
$foo->format('%authuser');
is( @{ [ $foo->regexp =~ /(\(\?\#.*?\))/g ] } , 2,
    "2 comments for %authuser in regexp" );
$foo->comments(0);


### Common 

# test the regex on real CLF log lines
$foo = Regexp::Log::Common->new(format => ':common');
@fields = $foo->capture(":common");
is( @fields , @{$lists{common2}}, "Capture :common" );
$regexp = $foo->regexp;

my %data;
my @data = (
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:42:43 +0000]',
		ts => '19/Jan/2005:21:42:43 +0000',
		request => '"POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1"',
		req => 'POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1',
		status => 200,
		bytes => 11435
    },
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:43:29 +0000]',
		ts => '19/Jan/2005:21:43:29 +0000',
		request => '"GET /images/perl_id_313c.gif HTTP/1.1"',
		req => 'GET /images/perl_id_313c.gif HTTP/1.1',
		status => 304,
		bytes => 0
    },
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:47:11 +0000]',
		ts => '19/Jan/2005:21:47:11 +0000',
		request => '"GET /brum.css HTTP/1.1"',
		req => 'GET /brum.css HTTP/1.1',
		status => 304,
		bytes => 0
    },
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:47:11 +0000]',
		ts => '19/Jan/2005:21:47:11 +0000',
		request => '"GET /brum.css HTTP/1.1"',
		req => 'GET /brum.css HTTP/1.1',
		status => 304,
		bytes => '-'
    },
);

my $fh = IO::File->new('t/data/common.log');
$i = 0;
while (<$fh>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "common.log line " . ( $i + 1 ) );
}
$fh->close;

### Extended

# test the regex on real ECLF log lines
$foo = Regexp::Log::Common->new(format => ':extended');
@fields = $foo->capture(":extended");
is( @fields , @{$lists{extended2}}, "Capture :extended" );
$regexp = $foo->regexp;

%data = ();
@data = (
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:42:43 +0000]',
		ts => '19/Jan/2005:21:42:43 +0000',
		request => '"POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1"',
		req => 'POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1',
		status => 200,
		bytes => 11435,
		referer => '"http://birmingham.pm.org/"',
		ref => 'http://birmingham.pm.org/',
		useragent => '"Mozilla/2.0GoldB1 (Win95; I)"',
		ua => 'Mozilla/2.0GoldB1 (Win95; I)',
    },
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:43:29 +0000]',
		ts => '19/Jan/2005:21:43:29 +0000',
		request => '"GET /images/perl_id_313c.gif HTTP/1.1"',
		req => 'GET /images/perl_id_313c.gif HTTP/1.1',
		status => 304,
		bytes => 0,
		referer => '"http://birmingham.pm.org/"',
		ref => 'http://birmingham.pm.org/',
		useragent => '"Mozilla/2.0GoldB1 (Win95; I)"',
		ua => 'Mozilla/2.0GoldB1 (Win95; I)',
    },
    {
		host => '127.0.0.1',
		rfc => '-',
		authuser => '-',
		date => '[19/Jan/2005:21:47:11 +0000]',
		ts => '19/Jan/2005:21:47:11 +0000',
		request => '"GET /brum.css HTTP/1.1"',
		req => 'GET /brum.css HTTP/1.1',
		status => 304,
		bytes => 0,
		referer => '"http://birmingham.pm.org/"',
		ref => 'http://birmingham.pm.org/',
		useragent => '"Mozilla/2.0GoldB1 (Win95; I)"',
		ua => 'Mozilla/2.0GoldB1 (Win95; I)',
    },
);

$fh = IO::File->new('t/data/extended.log');
$i = 0;
while (<$fh>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "extended.log line " . ( $i + 1 ) );
}
$fh->close;


### Custom - longhand

# test the regex on real custom CLF log lines
$foo = Regexp::Log::Common->new(
    format  => $forms{longhand},
    capture => $lists{longhand2}
);
@fields = $foo->capture();
#diag("longhand form: $forms{longhand}");
#diag("longhand fields: @fields");
is( @fields , @{$lists{longhand2}}, "Capture custom longhand" );
$regexp = $foo->regexp;
#diag("longhand regexp: $regexp");

%data = ();
@data = (
    {
		host => '103.245.44.14',
		rfc => '-',
		authuser => '-',
		date => '[23/May/2014:21:38:01 +0100]',
		ts => '23/May/2014:21:38:01 +0100',
		request => '"GET /volume/201109 HTTP/1.0"',
		req => 'GET /volume/201109 HTTP/1.0',
		status => 200,
		bytes => 37748,
		referer => '"-"',
		ref => '-',
		useragent => '"binlar_2.6.3 test@mgmt.mic"',
		ua => 'binlar_2.6.3 test@mgmt.mic',
        time => 2259292,
        servername => 'blog.cpantesters.org'
    }
);

$fh = IO::File->new('t/data/custom.log');
$i = 0;
while (<$fh>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "custom.log line " . ( $i + 1 ) );
}
$fh->close;


### Custom - shorthand

# test the regex on real custom CLF log lines
$foo = Regexp::Log::Common->new(
    format  => $forms{shorthand},
    capture => $lists{shorthand}
);
@fields = $foo->capture();
#diag("shorthand form: $forms{shorthand}");
#diag("shorthand fields: @fields");
is( @fields , @{$lists{shorthand}}, "Capture custom shorthand" );
$regexp = $foo->regexp;
#diag("shorthand regexp: $regexp");

%data = ();
@data = (
    {
		h => '103.245.44.14',
		logname => '-',
		u => '-',
		t => '[23/May/2014:21:38:01 +0100]',
		r => '"GET /volume/201109 HTTP/1.0"',
		s => 200,
		b => 37748,
		referer => '"-"',
		useragent => '"binlar_2.6.3 test@mgmt.mic"',
        D => 2259292,
        v => 'blog.cpantesters.org'
    }
);

$fh = IO::File->new('t/data/custom.log');
$i = 0;
while (<$fh>) {
    @data{@fields} = /$regexp/;
    is_deeply( \%data, $data[ $i++ ], "custom.log line " . ( $i + 1 ) );
}
$fh->close;

