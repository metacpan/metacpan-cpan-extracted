use strict;
use warnings;
use Net::Inspect::L7::HTTP;
use Test::More;

# $Net::Inspect::Debug::DEBUG = 1;

my $debug_pcap = 0;  # write test as pcap for debugging
require Net::PcapWriter if $debug_pcap;

my @result;
{
    # collect called hooks
    package myRequest;
    use base 'Net::Inspect::Flow';
    use base 'Net::Inspect::L7::HTTP::WebSocket';  # upgrade_websocket etc
    sub new_request        { return bless {},ref(shift) }
    sub in_request_header  { push @result, [ 'request_header',  $_[1] ] }
    sub in_request_body    { push @result, [ 'request_body',    $_[1] ] }
    sub in_response_header { push @result, [ 'response_header', $_[1] ] }
    sub in_response_body   { push @result, [ 'response_body',   $_[1] ] }
    sub in_chunk_header    { push @result, [ 'chunk_header',  @_[1,2] ] }
    sub in_chunk_trailer   { push @result, [ 'chunk_trailer', @_[1,2] ] }
    sub in_data            { push @result, [ 'data',          @_[1,2] ] }
    sub in_wsdata {
	my ($self,$dir,$data,$eom,$time,$frameinfo) = @_;
	$data = $frameinfo->unmask($data) if $data ne '' and ! ref $data;
	push @result, ['wsdata',$dir,$data,$eom,{ %$frameinfo }];
    }
    sub in_wsctl {
	my ($self,$dir,$data,$time,$frameinfo) = @_;
	$data = $frameinfo->unmask($data) if $data ne '' and ! ref $data;
	push @result, ['wsctl',$dir,$data,$frameinfo ? { %$frameinfo }: undef];
    }
    sub fatal              { push @result, [ 'fatal',         @_[1,2] ] }
}

my @tests = (
    [ "Simple GET with response body",
	0 => "GET / HTTP/1.0\r\n\r\n",
	request_header => "GET / HTTP/1.0\r\n\r\n",
	request_body => '',
	1 => "HTTP/1.0 200 Ok\r\n\r\n",
	response_header => "HTTP/1.0 200 Ok\r\n\r\n",
	gap_offset => [ 0,-1 ],
	gap_diff   => [ 0,-1 ],
	1 => 'This ends with EOF',
	response_body => 'This ends with EOF',
	1 => '',
	response_body => '',
    ],

    [ "HTTP header in multiple parts",
	0 => "GET / HTTP/1.",
	0 => "0\r\n\r\n",
	request_header => "GET / HTTP/1.0\r\n\r\n",
	request_body => '',
	1 => "HTTP/1.0 2",
	1 => "00 Ok\r\n\r\n",
	response_header => "HTTP/1.0 200 Ok\r\n\r\n",
	gap_offset => [ 0,-1 ],
	gap_diff   => [ 0,-1 ],
	1 => 'This ends with EOF',
	response_body => 'This ends with EOF',
	1 => '',
	response_body => '',
    ],

    [ "HTTP header in multiple parts (2)",
	0 => "GET http://foo",
	0 => "/bar HTTP/1.0\r\n",
	0 => "\r\n",
	request_header => "GET http://foo/bar HTTP/1.0\r\n\r\n",
	request_body => '',
    ],

    [ "chunked response",
	0 => "GET / HTTP/1.1\r\n\r\n",
	request_header => "GET / HTTP/1.1\r\n\r\n",
	request_body => '',
	1 => "HTTP/1.1 200 Ok\r\nTransfer-Encoding: chunked\r\n\r\n",
	response_header => "HTTP/1.1 200 Ok\r\nTransfer-Encoding: chunked\r\n\r\n",
	1 => "a\r\n",
	gap_offset => [ 0,60 ],  # 60 = header(47)+chunkhead(3)+chunklen(10)
	gap_diff   => [ 0,10 ],  # next 10 bytes are gapable
	chunk_header => "1|a\r\n",
	1 => "1234567890\r\n",
	response_body => "1234567890",
	1 => "8\r\n",
	gap_offset => [ 0,73 ],  # 73 = last(60)+crlf(2)+chunkhead(3)+chunklen(8)
	gap_diff   => [ 0,8 ],   # next 8 bytes are gapable
	chunk_header => "1|8\r\n",
	1 => "12345678\r\n",
	response_body => "12345678",
	1 => "0\r\n\r\n",
	chunk_header  => "1|0\r\n",
	response_body => "",
	chunk_trailer  => "1|\r\n",
    ],

    [ "chunked request",
	0 => "POST / HTTP/1.1\r\nTransfer-Encoding: chUNkeD\r\n\r\n",
	request_header => "POST / HTTP/1.1\r\nTransfer-Encoding: chUNkeD\r\n\r\n",
	0 => "a\r\n",
	gap_offset => [ 60,0 ],   # 60 = header(47)+chunkhead(3)+chunklen(10)
	gap_diff   => [ 10,0 ],   # next 10 bytes
	chunk_header => "0|a\r\n",
	0 => "1234567890\r\n",
	request_body => "1234567890",
	0 => "8\r\n",
	gap_offset => [ 73,0 ],   # 73 = last(60)+crlf(2)+chunkhead(3)+chunklen(8)
	gap_diff   => [ 8,0 ],    # next 8 bytes
	chunk_header => "0|8\r\n",
	0 => "12345678\r\n",
	request_body => "12345678",
	0 => "0\r\n\r\n",
	chunk_header  => "0|0\r\n",
	request_body => "",
	chunk_trailer  => "0|\r\n",
    ],

    [ "chunked request with chunk boundary != packet boundary",
	0 => "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n",
	request_header => "POST / HTTP/1.1\r\nTransfer-Encoding: chunked\r\n\r\n",
	0 => "a\r\n1234567890\r\n1",
	chunk_header => "0|a\r\n",
	request_body => "1234567890",
	0 => "0\r\n0123456789ABCDE",
	chunk_header => "0|10\r\n",
	request_body => "0123456789ABCDE",
	0 => "F\r\n0\r\n\r\n",
	request_body => "F",
	chunk_header  => "0|0\r\n",
	request_body => "",
	chunk_trailer  => "0|\r\n",
    ],

    [ "chunked POST followed by simple GET pipelined",
	0 => "POST / HTTP/1.1\r\nTransfer-Encoding: chUNkeD\r\n\r\n",
	request_header => "POST / HTTP/1.1\r\nTransfer-Encoding: chUNkeD\r\n\r\n",
	0 => "a\r\n",
	chunk_header => "0|a\r\n",
	0 => "0123456789\r\n",
	request_body => "0123456789",
	0 => "0\r\n\r\n",
	chunk_header  => "0|0\r\n",
	request_body => "",
	chunk_trailer  => "0|\r\n",
	0 => "GET / HTTP/1.1\r\n\r\n",
	request_header => "GET / HTTP/1.1\r\n\r\n",
	request_body => "",
	1 => "HTTP/1.1 204 no content\r\n\r\n",
	response_header => "HTTP/1.1 204 no content\r\n\r\n",
	response_body => '',
	1 => "HTTP/1.1 200 ok\r\nContent-length: 0\r\n\r\n",
	response_header => "HTTP/1.1 200 ok\r\nContent-length: 0\r\n\r\n",
	response_body => '',
    ],

    [ "1xx continue response", 
	0 => "POST / HTTP/1.1\r\nExpect: 100-continue\r\nContent-length: 0\r\n\r\n",
	request_header => "POST / HTTP/1.1\r\nExpect: 100-continue\r\nContent-length: 0\r\n\r\n",
	request_body => '',
	1 => "HTTP/1.1 100 Continue\r\n\r\n",
	response_header => "HTTP/1.1 100 Continue\r\n\r\n",
	1 => "HTTP/1.1 204 no content\r\n\r\n",
	response_header => "HTTP/1.1 204 no content\r\n\r\n",
	response_body => '',
    ],

    [ "CONNECT request",
	0 => "CONNECT foo:12345 HTTP/1.1\r\n\r\n",
	request_header => "CONNECT foo:12345 HTTP/1.1\r\n\r\n",
	gap_diff   => [ 0,0 ], # no more bytes allowed for now
	1 => "HTTP/1.0 200 Connection established\r\n\r\n",
	response_header => "HTTP/1.0 200 Connection established\r\n\r\n",
	gap_diff   => [ -1,-1 ], # now anything is allowed
	0 => "foo",
	data => [ 0,"foo" ],
	1 => "bar",
	data => [ 1,"bar" ],
	gap_diff   => [ -1,-1 ], # still anything is allowed
    ],

    [ "invalid content-length request", 
	0 => "POST / HTTP/1.1\r\nContent-length: -10\r\n\r\n",
	fatal => "invalid content-length '-10' in request|0",
    ],

    [ "invalid content-length response", 
	0 => "GET / HTTP/1.1\r\n\r\n",
	request_header => "GET / HTTP/1.1\r\n\r\n",
	request_body => '',
	1 => "HTTP/1.1 200 ok\r\nContent-length: 0xab\r\n\r\n",
	fatal => "invalid content-length '0xab' in response|1",
    ],

    [ "content-length followed by chunked request",
	# ------ request with content-length
	0 => "POST / HTTP/1.1\r\nContent-length: 15\r\n\r\n",
	request_header => "POST / HTTP/1.1\r\nContent-length: 15\r\n\r\n",
	gap_offset => [ 54,0 ], # 54 = header(39)+body(15)
	gap_diff   => [ 15,0 ], # next 15 bytes
	0 => "123456789012345",
	request_body => '123456789012345',
	# ------ response with content-length
	1 => "HTTP/1.1 200 ok\r\nContent-length: 13\r\n\r\n",
	gap_offset => [ 0,52 ], # 52 = header(39)+body(13)
	gap_diff   => [ 0,13 ], # next 13 bytes
	response_header => "HTTP/1.1 200 ok\r\nContent-length: 13\r\n\r\n",
	1 => '1234567890123',
	response_body => '1234567890123',
	# ------ chunked request
	0 => "POST / HTTP/1.1\r\nTransfer-Encoding: chUNkeD\r\n\r\n",
	request_header => "POST / HTTP/1.1\r\nTransfer-Encoding: chUNkeD\r\n\r\n",
	0 => "a\r\n",
	gap_offset => [ 114,0 ],   # 114 = last(54)+header(47)+chunkhead(3)+chunklen(10)
	gap_diff   => [ 10,0 ],    # next 10 bytes
	chunk_header => "0|a\r\n",
	0 => "1234567890\r\n",
	request_body => "1234567890",
	0 => "8\r\n",
	gap_offset => [ 127,0 ],   # 127 = last(114)+crlf(2)+chunkhead(3)+chunklen(8)
	gap_diff   => [ 8,0 ],     # next 8 bytes
	chunk_header => "0|8\r\n",
	0 => "12345678\r\n",
	request_body => "12345678",
	0 => "0\r\n\r\n",
	chunk_header  => "0|0\r\n",
	request_body => "",
	chunk_trailer  => "0|\r\n",
	# ------ chunked response
	1 => "HTTP/1.1 200 Ok\r\nTransfer-Encoding: chunked\r\n\r\n",
	response_header => "HTTP/1.1 200 Ok\r\nTransfer-Encoding: chunked\r\n\r\n",
	1 => "a\r\n",
	gap_offset => [ 0,112 ],  # 112 = last(52)+header(47)+chunkhead(3)+chunklen(10)
	gap_diff   => [ 0,10 ],   # next 10 bytes
	chunk_header => "1|a\r\n",
	1 => "1234567890\r\n",
	response_body => "1234567890",
	1 => "8\r\n",
	gap_offset => [ 0,125 ],  # 125 = last(112)+crlf(2)+chunkhead(3)+chunklen(8)
	gap_diff   => [ 0,8 ],    # next 8 bytes
	chunk_header => "1|8\r\n",
	1 => "12345678\r\n",
	response_body => "12345678",
	1 => "0\r\n\r\n",
	chunk_header  => "1|0\r\n",
	response_body => "",
	chunk_trailer  => "1|\r\n",
    ],

    [ "multiple POSTs after each other with gaps",
	0 => "POST / HTTP/1.0\r\nContent-length: 10\r\n\r\n",
	request_header => "POST / HTTP/1.0\r\nContent-length: 10\r\n\r\n",
	gap_offset => [ 49,0 ],
	gap_diff   => [ 10,0 ],
	0 => [ gap => 10 ],
	request_body => "[gap,10]",
	1 => "HTTP/1.0 200 Ok\r\nContent-length: 5\r\n\r\n",
	response_header => "HTTP/1.0 200 Ok\r\nContent-length: 5\r\n\r\n",
	gap_diff   => [ 0,5 ],
	gap_offset => [ 0,43 ],
	1 => [ gap => 5 ],
	response_body => "[gap,5]",

	0 => "POST / HTTP/1.0\r\nContent-length: 8\r\n\r\n",
	request_header => "POST / HTTP/1.0\r\nContent-length: 8\r\n\r\n",
	gap_offset => [ 95,0 ],
	gap_diff   => [ 8,0 ],
	0 => "1234",
	request_body => '1234',
	0 => [ gap => 4 ],
	request_body => "[gap,4]",
	1 => "HTTP/1.0 200 Ok\r\nContent-length: 4\r\n\r\n43",
	response_header => "HTTP/1.0 200 Ok\r\nContent-length: 4\r\n\r\n",
	response_body => '43',
	gap_offset => [ 0,85 ],
	gap_diff   => [ 0,2 ],
	1 => [ gap => 2 ],
	response_body => "[gap,2]",

	gap_diff   => [ 0,0 ],
    ],
);

{
    my $wsreq = "GET / HTTP/1.1\r\n".
	"Connection: Upgrade,Keep-Alive\r\n".
	"Upgrade: websocket\r\n".
	"Sec-WebSocket-Key: VnZ9oyUU18BVohuELlSkQA==\r\n".
	"Sec-WebSocket-Version: 13\r\n".
	"\r\n";
    my $wsrsp = "HTTP/1.1 101 Switching Protocols\r\n".
	"Upgrade: Websocket\r\n".
	"Sec-WebSocket-Accept: V2bG3i/4rNoOe4ODcYE1Ya7I9cQ=\r\n".
	"Connection: Upgrade\r\n".
	"\r\n";
    my $wsframe = sub {
	my ($opcode,$fin,$mask,$payload) = @_;
	my $hdr = pack("C", ( $fin ? 0x80:0 ) | $opcode & 0x0f);
	my $len = length($payload);
	if ($len>= 2**16) {
	    $hdr .= pack("CNN", 127|(defined $mask?0x80:0),
		int($len/2**32), $len % 2**32);
	} elsif ($len>=126) {
	    $hdr .= pack("Cn",126|(defined $mask?0x80:0),$len);
	} else {
	    $hdr .= pack("C",$len|(defined $mask?0x80:0));
	}
	if (defined $mask) {
	    $mask = pack("N",$mask);
	    $hdr .= $mask;
	    $payload ^= substr($mask x int($len/4+1),0,$len);
	}
	return $hdr . $payload;
    };
    my $ws_data0  = $wsframe->(0x2,0,0x12345678,"first" x 1_000);
    my $ws_data0c = $wsframe->(0x0,0,0x23456789,"second" x 22_000);
    my $ws_data0l = $wsframe->(0x0,1,0x34567890,"last" x 2);
    my $ws_data1  = $wsframe->(0x1,1,undef,"fnord");
    my $ws_close0 = $wsframe->(0x8,1,0x567890ab,pack("na*",4321,"foobar"));
    my $ws_close1 = $wsframe->(0x8,1,undef,pack("na*",1234,"barfoot"));
    my $ws_ping0  = $wsframe->(0x9,1,0x7890abcd,"foo");
    my $ws_pong1  = $wsframe->(0xa,1,0x890abcde,"bar");

    push @tests, [ 'websocket',
	0 => $wsreq, request_header => $wsreq,
	1 => $wsrsp, response_header => $wsrsp,
	gap_diff => [ 0,0 ],

	# first frame of data
	0 => $ws_data0, wsdata => "0|".('first' x 1_000)."|0|{header=\x02\xfe\x13\x88\x12\x34\x56\x78,init=1,mask=\x12\x34\x56\x78,opcode=2}",

	# in between ping+pong
	0 => $ws_ping0, wsctl => "0|foo|{header=\x89\x83x\x90\xab\xcd,mask=\x78\x90\xab\xcd,opcode=9}",
	1 => $ws_pong1, wsctl => "1|bar|{header=\x8a\x83\x89\n\xbc\xde,mask=\x89\x0a\xbc\xde,opcode=10}",

	# second frame has header of 14 byte (8 byte for length)
	0 => substr($ws_data0c,0,13), # no output should be after 13 bytes
	0 => substr($ws_data0c,13,1), # add another one for full header
	wsdata => "0||0|{bytes_left=[0,132000],header=\x00\xff\x00\x00\x00\x00\x00\x02\x03\xa0\x23\x45\x67\x89,mask=\x23\x45\x67\x89,opcode=2}",
	gap_diff => [ 132_000,0 ],     # full payload can be gapped

	# forward first 10 bytes of payload and now expect wsdata
	0 => substr($ws_data0c,14,10),
	wsdata => "0|secondseco|0|{bytes_left=[0,131990],mask=\x23\x45\x67\x89,mask_offset=0,opcode=2}",
	gap_diff => [ 131_990,0 ],

	# forward slowly up to the 32-bit boundary
	0 => [ gap => 65_524 ],  # payload: 65534
	wsdata => "0|[gap,65524]|0|{bytes_left=[0,66466],mask=\x23\x45\x67\x89,mask_offset=2,opcode=2}",
	gap_diff => [ 66_466,0 ],
	0 => [ gap => 1 ],       # payload: 65535 -> 0xffffffff
	wsdata => "0|[gap,1]|0|{bytes_left=[0,66465],mask=\x23\x45\x67\x89,mask_offset=3,opcode=2}",
	gap_diff => [ 66_465,0 ],
	0 => [ gap => 1 ],       # payload: 65536 -> 1 << 32
	wsdata => "0|[gap,1]|0|{bytes_left=[0,66464],mask=\x23\x45\x67\x89,mask_offset=0,opcode=2}",
	gap_diff => [ 66_464,0 ],
	0 => [ gap => 1 ],       # payload: 65537
	wsdata => "0|[gap,1]|0|{bytes_left=[0,66463],mask=\x23\x45\x67\x89,mask_offset=1,opcode=2}",
	gap_diff => [ 66_463,0 ],

	# more of frame as gap
	0 => [ gap => 66_460 ],
	wsdata => "0|[gap,66460]|0|{bytes_left=[0,3],mask=\x23\x45\x67\x89,mask_offset=1,opcode=2}",
	gap_diff => [ 3,0 ],

	# The last 3 octets of frame not gapped to check that the mask gets
	# used correctly if not on mask boundary after gaps.
	0 => substr($ws_data0c,-3),
	wsdata => "0|ond|0|{mask=\x23\x45\x67\x89,mask_offset=1,opcode=2}",
	gap_diff => [ 0,0 ],

	# now we get some data from the server
	1 => $ws_data1, wsdata => "1|fnord|1|{fin=1,header=\x81\x05,init=1,opcode=1}",

	# client closes
	1 => $ws_close1, wsctl => '1|\x04\xd2barfoot|{header=\x88\x09,opcode=8,reason=barfoot,status=1234}',

	# server closes
	0 => $ws_close0, wsctl => '0|\x10\xe1foobar|{header=\x88\x88\x56\x78\x90\xab,mask=\x56\x78\x90\xab,opcode=8,reason=foobar,status=4321}',

	# third frame from client is final frame
	0 => $ws_data0l, wsdata => "0|lastlast|1|{fin=1,header=\x80\x88\x34\x56\x78\x90,mask=\x34\x56\x78\x90,opcode=2}",

	# EOF
	0 => '', wsctl => '0||',
	1 => '', wsctl => '1||',
    ];
}

plan tests => 0+@tests;

my $req = myRequest->new;
my $http = Net::Inspect::L7::HTTP->new($req);
for( my $ti = 0;$ti<@tests;$ti++ ) {
    my $t = $tests[$ti];
    my $conn = $http->new_connection({});
    my $desc = shift(@$t);
    my @buf;
    @result = ();
    my $pw = $debug_pcap && Net::PcapWriter->new("test$ti.pcap")
	->tcp_conn('1.1.1.1',11111,'2.2.2.2',80);

    if ( eval {
	while (@$t) {
	    my ($what,$data) = splice(@$t,0,2);
	    if ( $what eq '0' or $what eq '1' ) {
		die "expected no hooks, got @{$result[0]}" if @result;
		# put into $conn
		if (ref($data)) {
		    $pw && $pw->write(0+$what,"#" x $data->[1]);
		    die "unhandled data in buf before gap" if $buf[$what] ne '';
		    $conn->in(0+$what,$data,$data->[1]==0,0);
		} else {
		    $pw && $pw->write(0+$what,$data);
		    $buf[$what] .= $data;
		    my $n = $conn->in(0+$what,$buf[$what],$data eq '' ? 1:0,0);
		    substr( $buf[$what],0,$n,'' );
		}
	    } elsif ( $what eq "gap_offset") {
		my @off = $conn->gap_offset(0,1);
		for(0,1) {
		    defined($data->[$_]) or next;
		    $off[$_] == $data->[$_] or
			die "expected gap_offset[$_]=$data->[$_], got $off[$_]";
		}
	    } elsif ( $what eq "gap_diff") {
		my @diff = $conn->gap_diff(0,1);
		for(0,1) {
		    defined($data->[$_]) or next;
		    $diff[$_] == $data->[$_] or
			die "expected gap_diff[$_]=$data->[$_], got $diff[$_]";
		}
	    } elsif ( $what eq 'sub' ) {
		$data->($conn);
	    } elsif ( ! @result ) {
		die "expected $what, got no results"
	    } else {
		my $have = do {
		    my @r = map { _flatten($_) } @{shift(@result)};
		    join('|',@r);
		};
		my $want = join('|',$what, ref($data)? @$data:$data);
		die sprintf "expected '$want', got '$have'" if
		    $want ne $have and _unescape($want) ne _unescape($have);
	    }
	}
	die "expected no more hooks, got @{$result[0]}" if @result;
	1;
    }) {
	pass($desc)
    } else {
	diag($@);
	fail($desc);
	last;
    }
}

sub _flatten {
    my ($r,$level) = @_;
    $level //= 0;
    $r = "$r" if $level>3;
    return '{'.join(",", map { "$_="._flatten($r->{$_},$level+1) } sort keys %$r ).'}'
	if UNIVERSAL::isa($r,'HASH');
    return '['.join(",",map { _flatten($_,$level+1) } @$r).']'
	if UNIVERSAL::isa($r,'ARRAY');
    return _escape($r);
}

sub _escape {
    my $r = shift // return '';
    $r =~ s{
	(\\)
	| (\r)
	| (\n)
	| (\t)
	| ([\x00-\x1f\x7f-\xff])
    }{
	$1 ? "\\\\" :
	$2 ? "\\r" :
	$3 ? "\\n" :
	$4 ? "\\t" :
	sprintf("\\x%02x",ord($5))
    }xesg;
    return $r;
}

sub _unescape {
    my $r = shift // return '';
    $r =~ s{(?<!\\)(?:
	(\\\\)
	| (\\r)
	| (\\n)
	| (\\t)
	| \\x([\da-fA-F]{2})
    )}{
	$1 ? "\\" :
	$2 ? "\r" :
	$3 ? "\n" :
	$4 ? "\t" :
	chr(hex($5))
    }xesg;
    return $r;
}
