use strict;
use Net::Radius::Client;

my $servers = {
    '127.0.0.1' => { 
        1812 => { 
            'secret' => 'perl4sins',
            'timeout' => 1,
            'retries' => 1
            }
    }
};

my $req = { 
    0 => {
        'User-Name' => ['anus'],
        'User-Password' => ['vulgaris'],
        'NAS-IP-Address' => [ '10.42.0.202' ]
        },
    9 => {
        'cisco-avpair' => ['some cisco stuff'] 
        } 
};

my $req2 = { 
    0 => {
        'User-Name' => ['anus'],
        'Acct-Status-Type' => ['Stop'],
        'NAS-IP-Address' => [ '10.42.0.202' ]
        },
    9 => {
        'cisco-avpair' => ['some cisco stuff'] 
        }
};
                   
my ($code, $rsp) = query($servers, "Access-Request", $req);

if ($code) {
    print $code . "\n";
    foreach my $vendor (keys %$rsp) {
        foreach my $attr (keys %{$rsp->{$vendor}}) {
            foreach my $val (@{$rsp->{$vendor}->{$attr}}) {
                print $attr . ' = ' . $val . "\n";
            }
        }
    }
} else {
    print "Error\n";
}

my ($code, $rsp) = query($servers, "Accounting-Request", $req2);

if ($code) {
    print $code . "\n";
    foreach my $vendor (keys %$rsp) {
        foreach my $attr (keys %{$rsp->{$vendor}}) {
            foreach my $val (@{$rsp->{$vendor}->{$attr}}) {
                print $attr . ' = ' . $val . "\n";
            }
        }
    }
} else {
    print "Error\n";
}
