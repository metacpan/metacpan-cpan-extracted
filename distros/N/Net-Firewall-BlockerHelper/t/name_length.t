#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

BEGIN {
	use_ok('Net::Firewall::BlockerHelper')                     || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::ipfw')     || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::pf')       || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::iptables') || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::firewalld') || print "Bail out!\n";
	use_ok('Net::Firewall::BlockerHelper::backends::openwrt')   || print "Bail out!\n";
}

# The kernels cap firewall object name lengths (iptables chains at 28,
# ipset/pf tables at 31, ipfw tables at 63, nftables identifiers at 255).
# Over-long prefix+name combos must fail clearly at new rather than as a
# confusing command error at init. The prefix used below is 'kur' so the
# object base name is 'kur_<name>'.

my %backend_max_name = (
	iptables  => 24,     # kur_ + 24 = 28, max chain length
	firewalld => 25,     # kur_ + 25 = 29, leaving room for _4/_6 within 31
	pf        => 27,     # kur_ + 27 = 31, max table length
	ipfw      => 59,     # kur_ + 59 = 63, max table length
	openwrt   => 246,    # kur_ + 246 = 250, leaving room for _4/_6 and _r<N>
);

foreach my $backend ( sort( keys(%backend_max_name) ) ) {
	my $class = 'Net::Firewall::BlockerHelper::backends::' . $backend;
	my $max   = $backend_max_name{$backend};

	local $@;
	eval { $class->new( name => 'a' x $max, prefix => 'kur' ); };
	ok( !$@, $backend . ': a name of ' . $max . ' characters is accepted' ) or diag($@);

	eval { $class->new( name => 'a' x ( $max + 1 ), prefix => 'kur' ); };
	ok( $@, $backend . ': a name of ' . ( $max + 1 ) . ' characters errors' );
	is( $Error::Helper::errorFlag, 'nameTooLong', $backend . ': the flag raised is nameTooLong' );
}

done_testing();
