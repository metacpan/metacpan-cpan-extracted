package Protocol::SOCKS::Constants;
$Protocol::SOCKS::Constants::VERSION = '0.003';
use strict;
use warnings;

use parent qw(Exporter);

my %const;
BEGIN {
	%const = (
		ATYPE_IPV4 => 1,
		ATYPE_IPV6 => 4,
		ATYPE_FQDN => 3,

		AUTH_NONE     => 0x00,
		AUTH_GSSAPI   => 0x01,
		AUTH_USERNAME => 0x02,
		AUTH_FAIL     => 0xFF,

		CMD_CONNECT   => 0x01,
		CMD_BIND      => 0x02,
		CMD_UDP       => 0x03,
	);
}
use constant +{ %const };

our @EXPORT_OK = sort keys %const;
our %EXPORT_TAGS = (
	all   => [ sort keys %const ],

	auth  => [ sort grep /^AUTH_/, keys %const ],
	atype => [ sort grep /^ATYPE_/, keys %const ],
	cmd   => [ sort grep /^CMD_/, keys %const ],
);

1;

