# check class derived from Net::HTTP::Request
# - if used native with IMP_DATA_HTTPRQ interface
# - TODO once Adaptor is ready: if used with IMP_DATA_STREAM so that it needs 
#   Net::IMP::Adaptor::STREAM2HTTPReq

use strict;
use warnings;
use Net::IMP;
use Net::IMP::HTTP;
use Net::IMP::Debug;
use Data::Dumper;

use Test::More tests => 1;
$Data::Dumper::Sortkeys = 1;
# $DEBUG = 1;

my @typed_data = (
    [ 0,IMP_DATA_HTTPRQ_HEADER, "GET / HTTP/1.1\r\nHost: foo\r\n\r\n"],
    [ 0,IMP_DATA_HTTPRQ_CONTENT, ""],
    [ 1,IMP_DATA_HTTPRQ_HEADER, "HTTP/1.1 200 Ok\r\nContent-length: 10\r\n\r\n" ],
    [ 1,IMP_DATA_HTTPRQ_CONTENT, "0123456789" ],
    [ 0,IMP_DATA_HTTPRQ_HEADER, "POST /foo HTTP/1.1\r\nHost: bar\r\nContent-length: 20\r\n\r\n"],
    [ 0,IMP_DATA_HTTPRQ_CONTENT, "0123456789ABCDEFGHIJ"],
    [ 0,IMP_DATA_HTTPRQ_CONTENT, ""],
    [ 1,IMP_DATA_HTTPRQ_HEADER, "HTTP/1.1 200 Ok\r\nContent-length: 5\r\n\r\n" ],
    [ 1,IMP_DATA_HTTPRQ_CONTENT, "012345" ],
);

my @stream_data;
for (@typed_data) {
    my ($dir,$type,$data) = @$_;
    if (@stream_data and $stream_data[-1][0] == $dir) {
	$stream_data[-1][2] .= $data
    } else {
	push @stream_data, [ $dir,IMP_DATA_STREAM,$data ]
    }
}

# chunkify streaming data
for ( @typed_data, @stream_data ) {
    my ($dir,$type,$data) = @$_;
    $type < 0 or next; # typed packet
    my @chunks = $data =~m{(.{1,9})}sg;
    @chunks = '' if ! @chunks and $type != IMP_DATA_STREAM; # preserve typed ''
    @$_ = ( $dir,$type,@chunks );
}
# add FIN to stream
push @stream_data,[ 0,IMP_DATA_STREAM,'' ];
push @stream_data,[ 1,IMP_DATA_STREAM,'' ];


# offsets are relative to request start
my @typed_rv_expect = (
    # first request
    [ 'pass', 1, -1 ],
    [ 'replace', 0, 29, "GET / HTTP/1.1\r\nHost: foo\r\nX-Header: test\r\n\r\n" ],
    [ 'pass', 0, 29 ],
    # second request
    [ 'pass', 1, -1 ],
    [ 'replace', 0, 53, "POST /foo HTTP/1.1\r\nHost: bar\r\nContent-length: 20\r\nX-Header: test\r\n\r\n" ],
    [ 'pass', 0, 62 ],
    [ 'pass', 0, 71 ],
    [ 'pass', 0, 73 ],
    [ 'pass', 0, 73 ],
);

# for stream offsets are relative to connection start
my @stream_rv_expect = (
    [ 'pass', 1, -1 ],
    [ 'replace', 0, 29, "GET / HTTP/1.1\r\nHost: foo\r\nX-Header: test\r\n" ],
    [ 'pass', 0, 29 ],
    [ 'replace', 0, 82, "POST /foo HTTP/1.1\r\nHost: bar\r\nContent-length: 20\r\nX-Header: test\r\n" ],
    [ 'pass', 0, 83 ],
    [ 'pass', 0, 92 ],
    [ 'pass', 0, 101 ],
    [ 'pass', 0, 102 ],
    [ 'pass', 0, 102 ],
);

for my $test (
    [ IMP_DATA_HTTPRQ, \@typed_data, \@typed_rv_expect ],
    #[ IMP_DATA_STREAM, \@stream_data, \@stream_rv_expect ],
) {

    my ($itype,$data,$expect) = @$test;

    my $factory = XHdr->new_factory;
    $factory = $factory->set_interface([
	$itype,
	[ IMP_PASS,IMP_REPLACE,IMP_DENY,IMP_FATAL ]
    ]) or die "unsupported interface for $itype";

    my @rv;
    my $analyzer;
    for(@$data) {
	my ($dir,$dtype,@chunks) = @$_;
	if ( ! $analyzer or 
	    $dtype == IMP_DATA_HTTPRQ_HEADER && $dir == 0 ) {
	    $analyzer = $factory->new_analyzer;
	    $analyzer->set_callback( sub { 
		push @rv,@_;
	    });
	}

	for (@chunks) {
	    # warn "IN=".Dumper([$dir,$dtype,$_]);
	    $analyzer->data($dir,$_,0,$dtype);
	}
    }

    my $want = Dumper($expect);
    my $have   = Dumper(\@rv);
    diag("-- want ---\n$want\n -- have ---\n$have") if $want ne $have;
    ok($want eq $have,$itype);
}


package XHdr;
use base 'Net::IMP::HTTP::Request';
use Net::IMP::HTTP;
use Net::IMP;
use fields qw(pos0);

sub RTYPES { ( IMP_PASS, IMP_REPLACE, IMP_DENY ) }
sub new_analyzer {
    my ($factory,%args) = @_;
    my $self = $factory->SUPER::new_analyzer(%args);
    $self->{pos0} = 0;
    $self->add_results([ IMP_PASS, 1, IMP_MAXOFFSET ]);
    return $self;
}

sub data {
    my ($self,$dir,$data,$offset,$type) = @_;
    if ( $dir == 1 ) {
	# we issued already a PASS for responses
	return;
    }

    $self->{pos0} = ( $offset||$self->{pos0} ) + length($data);
    if ( $type == IMP_DATA_HTTPRQ_HEADER and $dir == 0 ) {
	# add X-Header: test to request header
	$data =~s{(\r?\n)\Z}{X-Header: test$1$1};
	$self->run_callback([
	    IMP_REPLACE,
	    0,
	    $self->{pos0},
	    $data,
	]);
    } else {
	# allow
	$self->run_callback([
	    IMP_PASS,
	    0,
	    $self->{pos0},
	]);
    }
}

