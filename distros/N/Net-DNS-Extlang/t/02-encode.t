#!perl
use 5.016;
use strict;
use warnings;
use Test::More;

BEGIN {
  use Cwd;
  my $cwd;

  # look for RRTYPEgen in the local scripts dir
  if(cwd() =~ m{^([-a-z0-9./:]+)$}i) {
    $cwd = $1;
  } else { die "cannot untaint cwd"; }

  if($ENV{PATH} =~ m{^([-a-z0-9./:]+)$}i) {
    $ENV{PATH} = "$cwd/blib/script:" . $1;
  } else { die "cannot untaint path"; }

  delete @ENV{ 'IFS', 'CDPATH', 'ENV', 'BASH_ENV' };

  $ENV{PERL5LIB} = "$cwd/blib/lib"; # so RRTYPEgen can find this Net::DNS::Extlang
}

use Net::DNS::Extlang;

plan tests => 30;

# tell Net::DNS to use the test zone
{
 no warnings 'once';
 $Net::DNS::Parameters::DNSEXTLANG = 'services.net.';
}

# The RR descriptions at rrname.services.net include both the real RRs,
# and test ones.  The test ones start with an X, and have an rrtype
# that is 4096 greater than the real RR, so for example XA is like A
# but with rrtype 4097 rather than 1.

# The tests parse and unparse each test RR to see that it gets back the
# same text, and then compares the binary form to the corresponding
# regular RR to be sure that they differ only in the high byte of the
# type number.

while(<DATA>) {
	chomp;

	#printf "== %s\n",substr $_,1 if m{^;};
	next if m{^;} or m{^\s*$};			# comments out

SKIP: {
	my ($rrname, $rrbody) = m{(\S+)\s*(.*)}; # detaint

	# bug in Net::DNS::Parameters through 1.09 misinterprets digits
	# in rrnames
	skip "rrname $rrname contains digits", 2 if $rrname =~ /\d/;

	# make comparative RRs
	my $rr = "foo.bar 100 X$rrname $rrbody";
	my $orr = "foo.bar 100 $rrname $rrbody";

	my $s = new Net::DNS::RR($rr);
	my $os = new Net::DNS::RR($orr);

	my $sd = $s->encode(16);
	my $osd = $os->encode(16);
	my $tsd = unpack("H*", $sd);
	my $tosd = unpack("H*", $osd);

	my ($ns, $noff) = decode Net::DNS::RR( \$sd, 0 );

	is($s->string(), $ns->string, "deparsed $rrname matches");

	# 4096 rrtype bit shows up in byte 18
	ok((substr($tsd, 0, 17) eq substr($tosd, 0, 17) and substr($tsd, 19) eq substr($tosd, 19)),
			"binary $rrname matches") or
			diag($s->string ."\nnew $tsd\nold $tosd\n");
	}
}
__DATA__
; exercise all of the field types
A 1.2.3.4
AAAA 11:22::33:44
HINFO "foo" "bar"
TXT "able" "baker" pickle
; nsec with type bitmaps
NSEC _dmarc.gurus.org. NS SOA MX XMX XTXT TXT RRSIG NSEC DNSKEY
NSEC3 1 1 1 A0E613D5 4ICRVT101TFPQKEA0TI62PGRGTSM3U0P NS DS RRSIG
; rrsig with rrtype and time fields
RRSIG TXT 8 2 3600 20161128000000 20160927040112 51261 gurus.org. h7rFSoD1dnCfcFdHCrHBywZn6OU7VqtGFlo6h54iN5iCe7OYRJdX6NoFjyG1lwb3IU2hl/sj4wp/hhWxjx9wVlXTWScfcA5LzCSsQ+c86kiuyo/GyKdv0W1Nm3bGlWdxJ88vDrz2Om6OHnCdJxtIih9VamYGOooIhIUaKrGC5Bg=
; DS with hex
DS 23476 RSASHA256 SHA-256 4F1294AF6B53E817D2F630E6052112EFB18CB120AD00D5682471DB47 4790B7
; cert with named values
CERT PKIX 99 RSASHA1 ( YSBiYWQgZX hhbXBsZQ== )
TLSA 12 34 56 deadbeef c01dbeef
L64 12 22:33:44:55
EUI48 11-22-33-44-55-66
EUI64 11-22-33-44-55-66-77-88
URI 12 34 abcd
; dnskey with named value and hex
DNSKEY 12 3 RSAMD5 deadbeef c0ldbeef
