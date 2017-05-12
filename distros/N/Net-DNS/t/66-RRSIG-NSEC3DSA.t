# $Id: 66-RRSIG-NSEC3DSA.t 1360 2015-06-15 09:58:53Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my @prerequisite = qw(
		MIME::Base64
		Time::Local
		Net::DNS::RR::RRSIG
		Net::DNS::SEC
		Net::DNS::SEC::DSA
		Crypt::OpenSSL::DSA
		Digest::SHA
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 7;

use_ok('Net::DNS::SEC');


my $ksk = new Net::DNS::RR <<'END';
NSEC3DSA.example.	IN	DNSKEY	257 3 6 (
	CJKE0tUKX4bcWPMHxXgbj6TA8kXXliaWQvjf/bdx2gYSilEjBb6i7bg5nz54Z1qLg/KHhgdxyalZ
	u5gXonPMwIPixVa6Q8cIIkDfnHG5YQdyA4CjUC5sa50rGrxn2Z1cdXs2451WMGENU1M/sWBO8+LO
	ReC+a9J69p3vjtGCDl4q16bQ1Fw3PhFdcu7gc8pqFbkDzRVDCydRKUxSGosuQ09WfNX+PmF8C6a7
	4FOtD+q2FYamKVNN7Aq2unT32bitAbNQq6bulg366paCufYrCzYbnTGIsMC97SkKPNKuoHrW3uUA
	62TraF+LAvKkm9A7Rns/21ReGKHUjiu6ngSd/vfo3poPWhygjcW0E678q7mJQKEfNg8IoCW6gj4F
	wQw6FIH3gTgBDjRYksqL/YdkJ05scRYc9WeRum5vEdxl/yKOJS26zoNtz3HxgwyQnhm4P+zVOM07
	PznOpG3be7c6CTta/KQX5ldhvUdVUHqg93ZFr+R4TTPIVTIxI01jP8oMex8+GBg4rK3AmppWdADf
	9BEPY7KS ; Key ID = 7777
	)
END

ok( $ksk, 'set up DSA public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
Private-key-format: v1.2
Algorithm: 6 (NSEC3DSA)
Prime(p): liaWQvjf/bdx2gYSilEjBb6i7bg5nz54Z1qLg/KHhgdxyalZu5gXonPMwIPixVa6Q8cIIkDfnHG5YQdyA4CjUC5sa50rGrxn2Z1cdXs2451WMGENU1M/sWBO8+LOReC+a9J69p3vjtGCDl4q16bQ1Fw3PhFdcu7gc8pqFbkDzRU=
Subprime(q): koTS1QpfhtxY8wfFeBuPpMDyRdc=
Base(g): QwsnUSlMUhqLLkNPVnzV/j5hfAumu+BTrQ/qthWGpilTTewKtrp099m4rQGzUKum7pYN+uqWgrn2Kws2G50xiLDAve0pCjzSrqB61t7lAOtk62hfiwLypJvQO0Z7P9tUXhih1I4rup4Enf736N6aD1ocoI3FtBOu/Ku5iUChHzY=
Private_value(x): T/W3QlYjZFFRbWzpmqL40K/EGKs=
Public_value(y): DwigJbqCPgXBDDoUgfeBOAEONFiSyov9h2QnTmxxFhz1Z5G6bm8R3GX/Io4lLbrOg23PcfGDDJCeGbg/7NU4zTs/Oc6kbdt7tzoJO1r8pBfmV2G9R1VQeqD3dkWv5HhNM8hVMjEjTWM/ygx7Hz4YGDisrcCamlZ0AN/0EQ9jspI=
END
close(KSK);


my $key = new Net::DNS::RR <<'END';
NSEC3DSA.example.	IN	DNSKEY	256 3 6 (
	CIZJBhYteVknIchSnSCb0OXo0Lm7+6WMUjTn/stjMJZow+DoQ3wQ5m8HqWULYzwRO6OMkDs5wulZ
	6lH+2rIr9P4T3N37C1qh0bowV7dnNqRh+DgPQzQU9hst+3+T9A1RaCecq71x+mWkK0YEp99fQiOW
	+wszImAp9kaKTBGutZ7FxWnlBe1ogQCzjn/BKVudb6KiFMF2tMLT2RL/3tWY37ZJY9D/Vbk850ym
	OAeZHl2cu8LVVO+XQ8/sWbCMM0mdfxwUVq56ygANI/NhJN5DU6D/Gpn9N/5ZJU+KYs+2NvuPNyHu
	g2yhEauYOzHX4YQJRTC5ZL1hRJWyDMK2+FQHBXaVB/PDHlkxtRAXQDHjMT4aGV3HhdkF/3m5c0ls
	EXK5r3oQPCxKILLInh7pw1dgNuGYoUpzaIUAgvwmx7d+3bPpG5PgRyLYPmVCZ8A46gUj2eBkFRCL
	3vcX24e8haSo4c4v1bXnC1AX+uTf8/6ZnNGEcnAjUJ66AoTy5+9KPFMKcpkUjVBUFOZS+VlL921S
	eYKQ98nF ; Key ID = 16883
	)
END

ok( $key, 'set up DSA public key' );


my @rrset = ( $key, $ksk );
my $rrsig = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );
ok( $rrsig->sig(), 'create RRSIG over rrset using private ksk' );

my $verify = $rrsig->verify( \@rrset, $ksk );
ok( $verify, 'verify RRSIG over rrset using public ksk' ) || diag $rrsig->vrfyerrstr;

ok( !$rrsig->verify( \@rrset, $key ), 'verify fails using wrong key' );

my @badrrset = ($key);
ok( !$rrsig->verify( \@badrrset, $ksk ), 'verify fails using wrong rrset' );


exit;

__END__

