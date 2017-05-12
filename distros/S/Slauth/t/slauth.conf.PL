# slauth.conf.PL - build a slauth.conf for testing

use strict;
use Cwd;

my $dir = getcwd;
#print STDERR "slauth.conf.PL: debug dir=$dir\n";
if ( !open ( SLAUTH_CONF, ">t/slauth.conf" )) {
	die "$0: failed to generate t/slauth.conf\n";
}

print SLAUTH_CONF <<EOF
\%config = (
        "global" => {
                "name" => "config-global",
                "ssl_required" => 0,
                "storage" => "Slauth::Storage::DB",
		"dir" => "$dir/t/conf",
        },
	"localhost" => {
		"realm" => "localhost",
	}
);
EOF
;
close SLAUTH_CONF;

1;
