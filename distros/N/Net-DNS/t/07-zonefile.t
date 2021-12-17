#!/usr/bin/perl
# $Id: 07-zonefile.t 1855 2021-11-26 11:33:48Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;

use Test::More tests => 91;

## vvv	verbatim from Domain.pm
use constant ASCII => ref eval {
	require Encode;
	Encode::find_encoding('ascii');
};

use constant UTF8 => scalar eval {	## not UTF-EBCDIC  [see UTR#16 3.6]
	Encode::encode_utf8( chr(182) ) eq pack( 'H*', 'C2B6' );
};

use constant LIBIDN2  => defined eval { require Net::LibIDN2 };
use constant IDN2FLAG => LIBIDN2 ? &Net::LibIDN2::IDN2_NFC_INPUT + &Net::LibIDN2::IDN2_NONTRANSITIONAL : 0;
use constant LIBIDN   => LIBIDN2 ? undef : defined eval { require Net::LibIDN };
## ^^^	verbatim from Domain.pm


use constant LIBIDNOK => LIBIDN && scalar eval {
	my $cn = pack( 'U*', 20013, 22269 );
	Net::LibIDN::idn_to_ascii( $cn, 'utf-8' ) eq 'xn--fiqs8s';
};

use constant LIBIDN2OK => LIBIDN2 && scalar eval {
	my $cn = pack( 'U*', 20013, 22269 );
	Net::LibIDN2::idn2_to_ascii_8( $cn, 9 ) eq 'xn--fiqs8s';
};


use_ok('Net::DNS::ZoneFile');


my @file;
my $seq;

END {
	unlink $_ foreach @file;
}

sub source {				## zone file builder
	my ( $text, @args ) = @_;

	my $tag	 = ++$seq;
	my $file = "zone$tag.txt";

	my $handle = IO::File->new( $file, '>' );		# create test file
	die "Failed to create $file" unless $handle;
	eval { binmode($handle) };				# suppress encoding layer
	push @file, $file;

	print $handle $text;
	close $handle;

	return Net::DNS::ZoneFile->new( $file, @args );
}


my $recursive = join ' ', '$INCLUDE', source('$INCLUDE zone1.txt')->name;


{
	eval { Net::DNS::ZoneFile->new(undef); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "new(): invalid argument\t[$exception]" );
}


{
	eval { Net::DNS::ZoneFile->new( [] ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "new(): not a file handle\t[$exception]" );
}


{
	eval { Net::DNS::ZoneFile->new('zone0.txt'); };		# presumed not to exist
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "new(): non-existent file\t[$exception]" );
}


{					## public methods
	my $zonefile = source('');
	ok( $zonefile->isa('Net::DNS::ZoneFile'), 'new ZoneFile object' );

	ok( defined $zonefile->name,   'zonefile->name always defined' );
	ok( defined $zonefile->line,   'zonefile->line always defined' );
	ok( defined $zonefile->origin, 'zonefile->origin always defined' );
	ok( !defined $zonefile->ttl,   'zonefile->ttl initially undefined' );
	my @rr = $zonefile->read;
	is( scalar(@rr),     0, 'zonefile->read to end of file' );
	is( $zonefile->line, 0, 'zonefile->line zero if file empty' );

	is( $zonefile->origin, '.', 'zonefile->origin defaults to DNS root' );
}


{					## initial origin
	my $tld	     = 'test';
	my $absolute = source( '', "$tld." );
	is( $absolute->origin, "$tld.", 'new ZoneFile with absolute origin' );

	my $relative = source( '', "$tld" );
	is( $relative->origin, "$tld.", 'new ZoneFile->origin always absolute' );
}


{					## line numbering
	my $lines    = 10;
	my $zonefile = source( "\n" x $lines );
	is( $zonefile->line, 0, 'zonefile->line zero before calling read()' );
	my @rr = $zonefile->read;
	is( $zonefile->line, $lines, 'zonefile->line number incremented by read()' );
}


{
	my $zonefile = source <<'EOF';
$TTL
EOF
	eval { $zonefile->read; };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception:\t[$exception]" );
}


{
	my $zonefile = source <<'EOF';
$INCLUDE
EOF
	eval { $zonefile->read; };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception:\t[$exception]" );
}


{
	my $zonefile = source <<'EOF';
$ORIGIN
EOF
	eval { $zonefile->read; };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception:\t[$exception]" );
}


{
	my $zonefile = source <<'EOF';
$GENERATE
EOF
	eval { $zonefile->read; };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception:\t[$exception]" );
}


{
	my $zonefile = source <<'EOF';
$BOGUS
EOF
	eval { $zonefile->read; };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "exception:\t[$exception]" );
}


{					## $TTL directive at start of zone file
	my $zonefile = source <<'EOF';
$TTL 54321
rr0		SOA	mname rname 99 6h 1h 1w 12345
EOF
	is( $zonefile->read->ttl, 54321, 'SOA TTL set from $TTL directive' );
}


{					## $TTL directive following implicit default
	my $zonefile = source <<'EOF';
rr0		SOA	mname rname 99 6h 1h 1w 12345
rr1		NULL
$TTL 54321
rr2		NULL
rr3	3h	NULL
EOF
	is( $zonefile->read->ttl, 12345, 'SOA TTL set from SOA minimum field' );
	is( $zonefile->read->ttl, 12345, 'implicit default from SOA record' );
	is( $zonefile->read->ttl, 54321, 'explicit default from $TTL directive' );
	is( $zonefile->read->ttl, 10800, 'explicit TTL value overrides default' );
	is( $zonefile->ttl,	  54321, '$zonefile->ttl set from $TTL directive' );
}


{					## $INCLUDE directive
	my $include = source <<'EOF';
rr2	NULL
EOF

	my $directive = join ' ', '$INCLUDE', $include->name, '.';
	my $misdirect = join ' ', '$INCLUDE zone0.txt	; presumed not to exist';
	my $zonefile  = source <<"EOF";
rr1	NULL
$directive
rr3	NULL
$recursive
$misdirect
EOF

	my $fn1 = $zonefile->name;
	my $rr1 = $zonefile->read;
	is( $rr1->name,	     'rr1', 'zonefile->read expected record' );
	is( $zonefile->name, $fn1,  'zonefile->name identifies file' );
	is( $zonefile->line, 1,	    'zonefile->line identifies record' );

	my $fn2 = $include->name;
	my $rr2 = $zonefile->read;
	my $sfx = $zonefile->origin;
	is( $rr2->name,	     'rr2', 'zonefile->read expected record' );
	is( $zonefile->name, $fn2,  'zonefile->name identifies file' );
	is( $zonefile->line, 1,	    'zonefile->line identifies record' );

	my $rr3 = $zonefile->read;
	is( $rr3->name,	     'rr3', 'zonefile->read expected record' );
	is( $zonefile->name, $fn1,  'zonefile->name identifies file' );
	is( $zonefile->line, 3,	    'zonefile->line identifies record' );

	{
		my @rr = eval { $zonefile->read };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "recursive include\t[$exception]" );
	}

	{
		my @rr = eval { $zonefile->read };
		my ($exception) = split /\n/, "$@\n";
		ok( $exception, "non-existent include\t[$exception]" );
	}
	is( $zonefile->name, $fn1, 'zonefile->name identifies file' );
	is( $zonefile->line, 5,	   'zonefile->line identifies directive' );
}


my $zonefile;
{					## $ORIGIN directive
	my $nested = source <<'EOF';
nested	NULL
EOF

	my $origin  = 'example.com';
	my $ORIGIN  = '$ORIGIN';
	my $inner   = join ' ', '$INCLUDE', $nested->name;
	my $include = source <<"EOF";
$ORIGIN $origin
@	NS	host
$inner 
@	NULL
$ORIGIN relative
@	NULL
EOF

	my $outer = join ' ', '$INCLUDE', $include->name;
	$zonefile = source <<"EOF";
$outer 
outer	NULL

$ORIGIN $origin
	NULL
EOF

	my $ns = $zonefile->read;
	is( $ns->name,	  $origin,	  '@	NS	has expected name' );
	is( $ns->nsdname, "host.$origin", '@	NS	has expected rdata' );

	my $rr	   = $zonefile->read;
	my $expect = join '.', 'nested', $origin;
	is( $rr->name, $expect, 'scope of $ORIGIN encompasses nested $INCLUDE' );

	is( $zonefile->read->name, $origin, 'scope of $ORIGIN continues after $INCLUDE' );

	is( $zonefile->read->name, "relative.$origin", '$ORIGIN can be relative to current $ORIGIN' );

	is( $zonefile->read->name, 'outer', 'scope of $ORIGIN curtailed by end of file' );
	is( $zonefile->read->name, $origin, 'implicit owner following $ORIGIN directive' );
}


{					## $GENERATE directive
	my $zonefile = source <<'EOF';
$GENERATE 10-30/10	"@	TXT	$"	; BIND expects template to be quoted
$GENERATE 30-10/10	@	TXT	$
$GENERATE 123-123	@	TXT	${,,}
$GENERATE 123-123	@	TXT	${0,0,d}
$GENERATE 123-123	@	TXT	${0,0,o}
$GENERATE 123-123	@	TXT	${0,0,x}
$GENERATE 123-123	@	TXT	${0,0,X}
$GENERATE 123-123	@	TXT	${0,4,X}
$GENERATE 123-123	@	TXT	${4096,4,X}
$GENERATE 11259375	@	TXT	${0,6,n}
$GENERATE 11259375	@	TXT	${0,16,N}
$GENERATE 0-0		@	TXT	${0,0,Z}
EOF
	is( $zonefile->read->rdstring, '10',		   'generate TXT $ with step 10' );
	is( $zonefile->read->rdstring, '20',		   'generate TXT $ with step 10' );
	is( $zonefile->read->rdstring, '30',		   'generate TXT $ with step 10' );
	is( $zonefile->read->rdstring, '30',		   'generate TXT $ with step -10' );
	is( $zonefile->read->rdstring, '20',		   'generate TXT $ with step -10' );
	is( $zonefile->read->rdstring, '10',		   'generate TXT $ with step -10' );
	is( $zonefile->read->rdstring, '123',		   'generate TXT ${,,}' );
	is( $zonefile->read->rdstring, '123',		   'generate TXT ${0,0,d}' );
	is( $zonefile->read->rdstring, '173',		   'generate TXT ${0,0,o}' );
	is( $zonefile->read->rdstring, '7b',		   'generate TXT ${0,0,x}' );
	is( $zonefile->read->rdstring, '7B',		   'generate TXT ${0,0,X}' );
	is( $zonefile->read->rdstring, '007B',		   'generate TXT ${0,4,X}' );
	is( $zonefile->read->rdstring, '107B',		   'generate TXT ${4096,4,X}' );
	is( $zonefile->read->rdstring, 'f.e.d.',	   'generate TXT ${0,6,n}' );
	is( $zonefile->read->rdstring, 'F.E.D.C.B.A.0.0.', 'generate TXT ${0,16,N}' );
	eval { $zonefile->read; };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unknown format:\t[$exception]" );
}


{
	my $zonefile = source <<'EOF';
$TTL 1234
$ORIGIN example.
hosta	A	192.0.2.1
; whole line comment
	; indented comment
; vvv empty line

; ^^^ empty line
; vvv line with white space
	     
; ^^^ line with white space
	MX	10 hosta	; end of line comment
	TXT	(string)	; redundant brackets
	TXT	\(string\)
	TXT	no\;comment
	TXT	quoted\"quote

	TXT	( multiline	; interspersed ( mischievously )
		resource	; with	( possibly confusing )
		record	)	; comments

	TXT	( contiguous
string )			; excludes line terminator

	TXT	( multiline
		"quoted
string" )			; includes line terminator

	TXT	( "multiline
quoted
string" )			; includes line terminator
EOF
	is( $zonefile->read->name,     'hosta.example',		    'name of simple RR as expected' );
	is( $zonefile->read->name,     'hosta.example',		    'name propagated from previous RR' );
	is( $zonefile->read->rdstring, 'string',		    'redundant brackets ignored' );
	is( $zonefile->read->rdstring, '"(string)"',		    'quoted brackets protected' );
	is( $zonefile->read->rdstring, '"no;comment"',		    'quoted semicolon protected' );
	is( $zonefile->read->rdstring, 'quoted\"quote',		    'quoted quote protected' );
	is( $zonefile->read->rdstring, 'multiline resource record', 'multiline RR parsed correctly' );
	is( $zonefile->read->rdstring, 'contiguousstring',	    'contiguous string reassembled' );
	like( $zonefile->read->rdstring, '/quoted.*string$/', 'multiline string reassembled' );
	like( $zonefile->read->rdstring, '/quoted.*string$/', 'quoted string reassembled' );
}


{					## CLASS coersion
	my $zonefile = source <<'EOF';
rr0	CH	NULL
rr1	CLASS1	NULL
rr2	CLASS2	NULL
rr3	CLASS3	NULL
EOF
	my $rr = $zonefile->read;
	foreach ( $zonefile->read ) {
		is( $_->class, $rr->class, 'rr->class matches initial record' );
	}
}


{					## compatibility with defunct Net::DNS::ZoneFile 1.04 distro
	my $listref = Net::DNS::ZoneFile->read( $zonefile->name );
	ok( scalar(@$listref), 'read(): entire zone file' );
}


{
	my $listref = Net::DNS::ZoneFile->read( $zonefile->name, '.' );
	ok( scalar(@$listref), 'read(): zone file via path' );
}


{
	eval {
		local $SIG{__WARN__} = sub { };			# presumed not to exist
		my $listref = Net::DNS::ZoneFile->read( '/zone0.txt', '.' );
	};
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "read(): non-existent file\t[$exception]" );
}


{
	eval {
		local $SIG{__WARN__} = sub { };			# presumed not to exist
		my $listref = Net::DNS::ZoneFile->read( 'zone0.txt', 't' );
	};
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "read(): non-existent file\t[$exception]" );
}


{
	my $listref = Net::DNS::ZoneFile::read( $zonefile->name, '.' );
	ok( scalar(@$listref), 'read(): direct subroutine call (not object-oriented)' );
}


{
	my $string  = "";
	my $listref = Net::DNS::ZoneFile::parse( \$string );
	is( scalar(@$listref), 0, 'parse(): direct subroutine call (not object-oriented)' );
}


{
	my $string = <<'EOF';
a1.example A 192.0.2.1
a2.example A 192.0.2.2
EOF
	my $listref = Net::DNS::ZoneFile->parse( \$string );	# this also tests readfh()
	is( scalar(@$listref), 2, 'parse(): RR string' );
}


{
	my $string = <<'EOF';
a1.example A 192.0.2.1
$BOGUS
a2.example A 192.0.2.2
EOF
	local $SIG{__WARN__} = sub { };
	my $listref = Net::DNS::ZoneFile->parse( \$string );
	is( $listref, undef, 'parse(): erroneous string' );
}


{
	my $string = <<'EOF';
a1.example A 192.0.2.1
a2.example A 192.0.2.2
EOF
	my @list = Net::DNS::ZoneFile->parse($string);
	is( scalar(@list), 2, 'parse(): RR string into array' );
}


{
	my $string = <<'EOF';
a1.example A 192.0.2.1
$BOGUS
a2.example A 192.0.2.2
EOF
	local $SIG{__WARN__} = sub { };
	my @list = Net::DNS::ZoneFile->parse($string);
	is( scalar(@list), 1, 'parse(): erroneous string into array' );
}


{
	my $listref = Net::DNS::ZoneFile::parse('a.example. A 192.0.2.1');
	ok( scalar(@$listref), 'parse(): called as subroutine (not object-oriented)' );
}


SKIP: {					## Non-ASCII zone content
	skip( 'Unicode/UTF-8 not supported', 4 ) unless UTF8;

	my $greek = pack 'C*', 103, 114, 9, 84, 88, 84, 9, 229, 224, 241, 231, 234, 225, 10;
	my $file1 = source($greek);
	my $fh1	  = IO::File->new( $file1->name, '<:encoding(ISO8859-7)' );    # Greek
	my $zone1 = Net::DNS::ZoneFile->new($fh1);
	my $txtgr = $zone1->read;
	my $text  = pack 'U*', 949, 944, 961, 951, 954, 945;
	is( $txtgr->txtdata, $text, 'ISO8859-7 TXT rdata' );

	eval { binmode(DATA) };					# suppress encoding layer
	my $jptxt = join "\n", <DATA>;
	my $file2 = source($jptxt);
	my $fh2	  = IO::File->new( $file2->name, '<:utf8' );	# UTF-8 character encoding
	my $zone2 = Net::DNS::ZoneFile->new($fh2);
	my $txtrr = $zone2->read;				# TXT RR with kanji RDATA
	my @rdata = $txtrr->txtdata;
	my $rdata = $txtrr->txtdata;
	is( length($rdata), 12, 'Unicode/UTF-8 TXT rdata' );
	is( scalar(@rdata), 1,	'Unicode/UTF-8 TXT contiguous' );

	skip( 'Non-ASCII domain - IDNA not supported', 1 ) unless LIBIDNOK || LIBIDN2OK;

	my $jpnull = $zone2->read;				# NULL RR with kanji owner name
	is( $jpnull->name, 'xn--wgv71a', 'Unicode/UTF-8 domain name' );
}


exit;

__END__
jp	TXT	古池や　蛙飛込む　水の音		; Unicode text string
日本	NULL						; Unicode domain name

