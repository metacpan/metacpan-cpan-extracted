#!perl -T
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

plan tests => 9;

# tell Net::DNS to use my zone
{
 no warnings 'once';
 $Net::DNS::Parameters::DNSEXTLANG = 'services.net.';
}

ok(new IO::File('RRTYPEgen |'),		'test run RRTYPEgen');

my $ff = new IO::File('RRTYPEgen "RRTYPE=1" "XA:4097 a host address" \
	"A:addr IPv4 address"|');
my $fo;
$fo .= $_ while <$ff>;
ok($fo,					'compile simple type');
ok($fo =~ /package Net::DNS::RR::XA;/,	'has right package');
ok($fo =~ /package Net::DNS::RR::TYPE4097;/,'has number package');
ok($fo =~ /sub _decode_rdata/,		'has decode routine');
ok($fo =~ /sub _encode_rdata/,		'has encode routine');
ok($fo =~ /sub _format_rdata/,		'has format routine');
ok($fo =~ /sub _parse_rdata/,		'has parse routine');
ok($fo =~ /sub addr/,			'has addr routine');

