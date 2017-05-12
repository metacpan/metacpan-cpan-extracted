use strict;
use warnings;

use Test::More;
my $fail;
BEGIN {
	eval "use Devel::LeakGuard::Object qw(leakguard)";
	$fail = $@;
}

plan skip_all => 'Need Devel::LeakGuard::Object' if $fail;

plan tests => 3;

use Net::XMPP;


check_leak(
    sub {
        my $x = bless {}, 'abc';
    },
    'nothing',
);

TODO: {
   local $TODO = 'fix leak';
check_leak(
    sub {
        my $conn   = Net::XMPP::Client->new;
        $conn = undef;
    },
    'new',
);

check_leak(
    sub {
        my $conn   = Net::XMPP::Client->new;
        my $status = $conn->Connect(
            hostname       => 'talk.google.com',
            port           => 5222,
            componentname  => 'gmail.com',
            connectiontype => 'tcpip',
            tls            => 1,
            ssl_verify     => 0,
        );
    },
    'connect',
);
}


sub check_leak{
    my ($sub) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for my $c (1..10) {
        $sub->();
    }

    my $warn;
    local $SIG{__WARN__} = sub { $warn = shift };
    leakguard {
        for my $c (1..10) {
            $sub->();
            #diag "Called $c";
        }
    };

    ok(!$warn, 'leaking') or diag $warn;
}

