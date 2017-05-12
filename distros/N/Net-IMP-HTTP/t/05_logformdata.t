# check Net::IMP::HTTP::Example::AddXFooHeader derived from Net::HTTP::Connection
# - if used native with IMP_DATA_HTTP interface
# - if used native with IMP_DATA_HTTPRQ interface
# - if used with IMP_DATA_STREAM so that it needs Net::IMP::Adaptor::STREAM2HTTPConn

use strict;
use warnings;
use Net::IMP;
use Net::IMP::HTTP;
use Net::IMP::Debug;
use Net::Inspect::Debug var => \$DEBUG, sub => \&debug;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;
my $dump;
for (
    [ 'YAML' => sub { YAML::Dump(@_) } ],
    [ 'YAML::Tiny' => sub { YAML::Tiny::Dump(@_) } ],
    [ 'Data::Dumper' => sub { Data::Dumper->new([@_])->Terse(1)->Dump }],
) {
    (my $pkg,$dump) = @$_;
    eval "require $pkg" or do {
	$dump = undef;
	next;
    };
    last;
}

# at least Data::Dumper should be available
$dump or die "not even Data::Dumper is installed"; 

use Test::More;
#$DEBUG = 1;


eval { require Net::IMP::HTTP::Example::LogFormData } 
    or plan skip_all => "cannot load Net::IMP::HTTP::Example::LogFormData: $@";
plan tests => 3;

my $multipart_body = 
    "--abcde\r\nContent-disposition: form-data; name=oFo\r\n\r\nlari\r\n".
    "--abcde\r\nContent-disposition: form-data; name=bAr\r\n\r\nfari\r\n".
    "--abcde\r\nContent-disposition: form-data; name=FiL; filename=foo.bar\r\n\r\n".
    "content of file\r\n".
    "--abcde--\r\n";

my @http_data = (
    [ 0,IMP_DATA_HTTP_HEADER,
	"POST /foo?bar=1&foo=2 HTTP/1.1\r\n".
	"Content-type: application/x-www-form-urlencoded\r\n".
	"Content-length: 11\r\n".
	"Host: foo\r\n\r\n",
    ],
    [ 0,IMP_DATA_HTTP_BODY, "rab=3&oof=4"],
    [ 0,IMP_DATA_HTTP_BODY, ""],
    [ 1,IMP_DATA_HTTP_HEADER, "HTTP/1.1 204 no content\r\n\r\n" ],
    [ 1,IMP_DATA_HTTP_BODY, "" ],

    [ 0,IMP_DATA_HTTP_HEADER, 
	"POST /foo?bar=a&foo=b HTTP/1.1\r\n".
	"Content-type: multipart/form-data; boundary=abcde\r\n".
	"Content-length: ".length($multipart_body)."\r\n".
	"Host: foo\r\n\r\n",
    ],
    [ 0,IMP_DATA_HTTP_BODY, $multipart_body ],
    [ 0,IMP_DATA_HTTP_BODY, ""],
    [ 1,IMP_DATA_HTTP_HEADER, "HTTP/1.1 204 no content\r\n\r\n" ],
    [ 1,IMP_DATA_HTTP_BODY, "" ],

    [ 0,IMP_DATA_HTTP_HEADER, "GET /foo?bar=foot HTTP/1.1\r\n\r\n" ],
    [ 0,IMP_DATA_HTTP_BODY, ""],
    [ 1,IMP_DATA_HTTP_HEADER, "HTTP/1.1 204 no content\r\n\r\n" ],
    [ 1,IMP_DATA_HTTP_BODY, "" ],
);

my @httprq_data;
for (@http_data) {
    my ($dir,$type,$data) = @$_;
    $type = 
	( $type == IMP_DATA_HTTP_HEADER ) ? IMP_DATA_HTTPRQ_HEADER :
	( $type == IMP_DATA_HTTP_BODY ) ? IMP_DATA_HTTPRQ_CONTENT :
	undef;
    push @httprq_data, [ $dir,$type,$data ] if defined $type
}

my @stream_data;
for (@http_data) {
    my ($dir,$type,$data) = @$_;
    if (@stream_data and $stream_data[-1][0] == $dir) {
	$stream_data[-1][2] .= $data
    } else {
	push @stream_data, [ $dir,IMP_DATA_STREAM,$data ]
    }
}

# chunkify streaming data
for ( @http_data, @httprq_data, @stream_data ) {
    my ($dir,$type,$data) = @$_;
    $type < 0 or next; # typed packet
    my @chunks = $data =~m{(.{1,9})}sg;
    @chunks = '' if ! @chunks and $type != IMP_DATA_STREAM; # preserve typed ''
    @$_ = ( $dir,$type,@chunks );
}
# add FIN to stream
push @stream_data,[ 0,IMP_DATA_STREAM,'' ];
push @stream_data,[ 1,IMP_DATA_STREAM,'' ];


my @http_rv_expect = (
    [ 'prepass', 0, -1 ],
    [ 'pass', 1, -1 ],
    [ 'log', 0, 0, 0, 'info', $dump->({
	'body.urlencoded' => [
	    [ rab => '3' ],
	    [ oof => '4' ]
	],
	'header.query_string' => [
	    [ bar => '1' ],
	    [ foo => '2' ]
	],
    })],
    [ 'log', 0, 0, 0, 'info', $dump->({
	'body.multipart' => [
	    [ oFo => 'lari' ],
	    [ bAr => 'fari' ],
	    [ FiL => 'UPLOAD:foo.bar (15 bytes)' ],
	],
	'header.query_string' => [
	    [ bar => 'a' ],
	    [ foo => 'b' ]
	],
    })],
    [ 'log', 0, 0, 0, 'info', $dump->({
	'header.query_string' => [
	    [ bar => 'foot' ]
	],
    })],
    [ 'pass',0, 489 ],
);
my @httprq_rv_expect = (
    [ 'prepass', 0, -1 ],
    [ 'pass', 1, -1 ],
    [ 'log', 0, 0, 0, 'info', $dump->({
	'body.urlencoded' => [
	    [ rab => '3' ],
	    [ oof => '4' ]
	],
	'header.query_string' => [
	    [ bar => '1' ],
	    [ foo => '2' ]
	],
    })],
    [ 'prepass', 0, -1 ],
    [ 'pass', 1, -1 ],
    [ 'log', 0, 0, 0, 'info', $dump->({
	'body.multipart' => [
	    [ oFo => 'lari' ],
	    [ bAr => 'fari' ],
	    [ FiL => 'UPLOAD:foo.bar (15 bytes)' ],
	],
	'header.query_string' => [
	    [ bar => 'a' ],
	    [ foo => 'b' ]
	],
    })],
    [ 'prepass', 0, -1 ],
    [ 'pass', 1, -1 ],
    [ 'log', 0, 0, 0, 'info', $dump->({
	'header.query_string' => [
	    [ bar => 'foot' ]
	],
    })],
    [ 'pass',0, 30 ],
);
my @stream_rv_expect = @http_rv_expect;

for my $test (
    [ IMP_DATA_HTTP,   \@http_data,   \@http_rv_expect   ],
    [ IMP_DATA_HTTPRQ, \@httprq_data, \@httprq_rv_expect ],
    [ IMP_DATA_STREAM, \@stream_data, \@stream_rv_expect ],
) {

    my ($itype,$data,$expect) = @$test;

    my $factory = Net::IMP::HTTP::Example::LogFormData->new_factory;
    $factory = $factory->set_interface([
	$itype,
	[ IMP_PASS,IMP_PREPASS,IMP_LOG,IMP_DENY,IMP_FATAL ]
    ]) or die "unsupported interface for $itype";

    my @rv;
    my %pass_infinite;
    my $analyzer;

    for(@$data) {
	my ($dir,$dtype,@chunks) = @$_;
	if ( ! $analyzer or 
	    $dir == 0 && $dtype == IMP_DATA_HTTPRQ_HEADER ) {
	    %pass_infinite = ();
	    $analyzer = $factory->new_analyzer;
	    $analyzer->set_callback( sub { 
		# warn "RV=".Dumper(\@_);
		for(@_) {
		    push @rv,$_;
		    if ( $_->[0] == IMP_PASS and $_->[2] == IMP_MAXOFFSET ) {
			$pass_infinite{$_->[1]} = 1;
		    }
		}
	    });
	}
	next if $pass_infinite{$dir};
	for (@chunks) {
	    #warn "IN=".Dumper([$dir,$dtype,$_]);
	    $analyzer->data($dir,$_,0,$dtype);
	}
    }

    my $want = Dumper($expect);
    my $have   = Dumper(\@rv);
    diag("-- want ---\n$want\n -- have ---\n$have") if $want ne $have;
    ok($want eq $have,$itype);
}


