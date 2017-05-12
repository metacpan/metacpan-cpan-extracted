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

use Test::More tests => 4;
$Data::Dumper::Sortkeys = 1;
#$DEBUG = 1;


ok( eval { require Net::IMP::HTTP::Example::AddXFooHeader },'load');

my @http_data = (
    [ 0,IMP_DATA_HTTP_HEADER, "GET / HTTP/1.1\r\nHost: foo\r\n\r\n"],
    [ 0,IMP_DATA_HTTP_BODY, ""],
    [ 1,IMP_DATA_HTTP_HEADER, "HTTP/1.1 200 Ok\r\nContent-length: 10\r\n\r\n" ],
    [ 1,IMP_DATA_HTTP_BODY, "0123456789" ],
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
    [ 'replace', 1, 39, "HTTP/1.1 200 Ok\r\nX-Foo: bar\r\nContent-length: 10\r\n\r\n" ],
    [ 'pass', 1, 48 ],
    [ 'pass', 1, 49 ],
);
my @httprq_rv_expect = (
    [ 'prepass', 0, -1 ],
    [ 'pass', 0, -1 ],
    [ 'replace', 1, 39, "HTTP/1.1 200 Ok\r\nX-Foo: bar\r\nContent-length: 10\r\n\r\n" ],
    [ 'pass', 1, -1 ],
);
my @stream_rv_expect = (
    [ 'prepass', 0, -1 ],
    [ 'replace', 1, 39, "HTTP/1.1 200 Ok\r\nX-Foo: bar\r\nContent-length: 10\r\n\r\n" ],
    [ 'pass', 1, 45 ],
    [ 'pass', 1, 49 ],
    [ 'pass', 1, 49 ],
);

for my $test (
    [ IMP_DATA_HTTP,   \@http_data,   \@http_rv_expect   ],
    [ IMP_DATA_HTTPRQ, \@httprq_data, \@httprq_rv_expect ],
    [ IMP_DATA_STREAM, \@stream_data, \@stream_rv_expect ],
) {

    my ($itype,$data,$expect) = @$test;

    my $factory = Net::IMP::HTTP::Example::AddXFooHeader->new_factory;
    $factory = $factory->set_interface([
	$itype,
	[ IMP_PASS,IMP_PREPASS,IMP_REPLACE,IMP_DENY,IMP_FATAL ]
    ]) or die "unsupported interface for $itype";

    my @rv;
    my $analyzer = $factory->new_analyzer;
    my %pass_infinite;
    $analyzer->set_callback( sub { 
	# warn "RV=".Dumper(\@_);
	for(@_) {
	    push @rv,$_;
	    if ( $_->[0] == IMP_PASS and $_->[2] == IMP_MAXOFFSET ) {
		$pass_infinite{$_->[1]} = 1;
	    }
	}
    });

    for(@$data) {
	my ($dir,$dtype,@chunks) = @$_;
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


