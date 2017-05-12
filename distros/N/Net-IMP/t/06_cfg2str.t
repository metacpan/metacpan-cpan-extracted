use strict;
use warnings;
use Test::More tests => 6;
use Data::Dumper;

$Data::Dumper::Sortkeys = 1;

rt(
    'Net::IMP::Pattern',
    [
	# different perl versions use different rx stringifications
	'action=deny&adata=matched%20regex&rx=(?^:foo%25bar%20foot)&rxlen=12',
	'action=deny&adata=matched%20regex&rx=(?-xism:foo%25bar%20foot)&rxlen=12',
	'action=deny&adata=matched%20regex&rx=foo%25bar%20foot&rxlen=12',
    ],
    {
	action => 'deny',
	adata  => 'matched regex',
	rx => qr/foo%bar foot/,
	rxlen => '12',
    }
);

rt(
    'Net::IMP::ProtocolPinning',
    [
	# different perl versions use different rx stringifications
	'dir0=0&dir1=1&ignore_order=1&max_unbound0=0&max_unbound1=0&rx0=(?^:\d{4})&rx1=(?^:%20\r?\n\r?\n)&rxlen0=4&rxlen1=5',
	'dir0=0&dir1=1&ignore_order=1&max_unbound0=0&max_unbound1=0&rx0=(?-xism:\d{4})&rx1=(?-xism:%20\r?\n\r?\n)&rxlen0=4&rxlen1=5',
	'dir0=0&dir1=1&ignore_order=1&max_unbound0=0&max_unbound1=0&rx0=\d{4}&rx1=%20\r?\n\r?\n&rxlen0=4&rxlen1=5',
    ],
    {
	rules => [
	    { dir => '0', rxlen => '4', rx => qr/\d{4}/ },
	    { dir => '1', rxlen => '5', rx => qr/ \r?\n\r?\n/ },
	],
	max_unbound => ['0','0'],
	ignore_order => '1',
    }
);

rt(
    'Net::IMP::ProtocolPinning',
    [
	# different perl versions use different rx stringifications
	'dir0=0&ignore_order=1&max_unbound0&max_unbound1=0&rx0=(?^:\d{4})&rxlen0=4',
	'dir0=0&ignore_order=1&max_unbound0&max_unbound1=0&rx0=(?-xism:\d{4})&rxlen0=4',
	'dir0=0&ignore_order=1&max_unbound0&max_unbound1=0&rx0=\d{4}&rxlen0=4',
    ],
    {
	rules => [ { dir => '0', rxlen => '4', rx => qr/\d{4}/ }, ],
	max_unbound => [undef,'0'],
	ignore_order => '1',
    }
);

sub rt {
    my ($class,$str,$cfg) = @_;
    eval "require $class" or BAIL_OUT("cannot load $class");
    my @str = ref($str) ? (@$str):($str);

    my $str2 = $class->cfg2str(%$cfg);
    if ( grep { $_ eq $str2 } @str ) {
	pass("$class cfg2str");
    } else {
	diag("$str2 does not match any of @str");
	fail("$class cfg2str");
    }

    my $ok = 0;
    my @bad;
    for my $str ( @str ) {
	my %cfg2;
	eval { %cfg2 = $class->str2cfg($str) }
	    # maybe unsupported regex syntax for this perl version
	    or next;
	my $dp2 = Dumper(\%cfg2);
	# $rx = qr/$rx/; $rx = qr/$rx/ will put twice into (?^:...
	my $prefix = qr{\?(?:\^|-xism):};
	$dp2 =~s{qr/\($prefix(\($prefix.*?\))\)/}{qr/$1/}g;
	if ( $dp2 eq Dumper($cfg) ) {
	    pass("$class str2cfg");
	    $ok = 1;
	    last;
	} else {
	    push @bad, $dp2;
	}
    }
    if ( ! $ok ) {
	diag( Dumper($cfg). " does not match any of:\n".join("---\n",@bad));
	fail("$class str2cfg");
    }
}
