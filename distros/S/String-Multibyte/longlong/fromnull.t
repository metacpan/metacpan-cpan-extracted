#!perl

BEGIN { $| = 1; print "1..33\n"; }
END {print "not ok 1\n" unless $loaded;}
use String::Multibyte;
$^W = 1;
$loaded = 1;
print "ok 1\n";

# this is a very long test.
# start from NULL till gets undef...

my $time = time;

%MBCS = (
    Big5     => {
	"last" => "\xFE\xFE", count => 0x80 + 0x7E * 0x9D },
    Big5Plus => {
	"last" => "\xFE\xFE", count => 0x80 + 0x7E * 0xBE },
    Bytes    => {
	"last" => "\xFF",     count => 0x100 },
    EUC      => {
	"last" => "\xFE\xFE", count => 0x80 + 0x5E * 0x5E },
    EUC_JP   => {
	"last" => "\x8F\xFE\xFE", count => 0x80 + 0xBD * 0x5E },
    EUC_TW   => {
	"last" => "\x8E\xB0\xFE\xFE", count => 0x80 + 0x11 * 0x5E * 0x5E },
    GB18030  => {
	"last" => "\xFE\x39\xFE\x39",
	count => 0x81 + 0x7E * 0xBE + 0x7E * 0x7E * 100 },
    GBK      => {
	"last" => "\xFE\xFE", count => 0x81 + 0x7E * 0xBE  },
    Johab    => {
	"last" => "\xF9\xFE", count => 0x80 + 0x21 * 0xBC + 11172 + 51 },
    ShiftJIS => {
	"last" => "\xFC\xFC", count => 0x80 + 0x3F + 0x5E * 120 },
    UHC      => {
	"last" => "\xFE\xFE", count => 0x80 + 0x45 * 0x5E + 11172 },
    UTF16BE => {
	"last" => "\xDB\xFF\xDF\xFF", count => 0x110000 - 0x800 },
    UTF16LE => {
	"last" => "\xFF\xDB\xFF\xDF", count => 0x110000 - 0x800 },
    UTF32BE => {
	"last" => "\x00\x10\xFF\xFF", count => 0x110000 - 0x800 },
    UTF32LE => {
	"last" => "\xFF\xFF\x10\x00", count => 0x110000 - 0x800 },
    UTF8     => {
	"last" => "\xF4\x8F\xBF\xBF", count => 0x110000 - 0x800 },
);

for $name (sort keys %MBCS) {
    my $mb = String::Multibyte->new($name);
    my $last  = $MBCS{$name}{last};
    my $count = $MBCS{$name}{count};
    my $c = 0;
    my $NG = 0;
    my $ch =
	$name =~ /UTF32/ ? "\x00\x00\x00\x00" :
	$name =~ /UTF16/ ? "\x00\x00" : "\x00";

    use vars qw($re);
    $] < 5.005
	? $re = '^'.$mb->{regexp}.'(?!\n)$'
	: eval q{ $re = qr/^$mb->{regexp}\z/ };

    my $nextchar = $mb->{nextchar};
    my $cmpchar  = $mb->{cmpchar};
    while (1) {
	$c++;
	# printdeb($name, $ch, "\r") if $c % 256 == 0;

        $NG++ unless $ch =~ /$re/;

        my $next = &$nextchar($ch);
	$NG++ unless $ch eq $last
			? !defined($next)
			: 0 > &$cmpchar($ch, $next);
	last if ! defined($next);
	$ch = $next;
    }
    print !$NG ? "ok" : "not ok", " ", ++$loaded, "\n";
    print $c == $count ? "ok" : "not ok"  , " ", ++$loaded, "\n";
}

print "time: ", time - $time, " sec.\n";


sub printdeb {
#    return;
    print "$_[0] ".unpack('H*', $_[1]).$_[2];
}

__END__
