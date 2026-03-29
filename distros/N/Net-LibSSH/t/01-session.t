use strict;
use warnings;
use Test::More;
use Net::LibSSH;

# new() returns a blessed Net::LibSSH object
my $ssh = Net::LibSSH->new;
isa_ok $ssh, 'Net::LibSSH', 'new() returns Net::LibSSH object';

# error() on a fresh session is empty
my $err = $ssh->error;
ok !defined($err) || $err eq '', 'error() empty on fresh session';

# option() runs without dying for all supported keys
for my $pair (
    [ host         => 'localhost'   ],
    [ user         => 'root'        ],
    [ port         => 22            ],
    [ timeout      => 10            ],
    [ knownhosts   => '/dev/null'   ],
    [ compression  => 'no'          ],
    [ log_verbosity => 0            ],
) {
    my ($key, $val) = @$pair;
    eval { $ssh->option($key => $val) };
    is $@, '', "option($key => ...) does not die";
}

# unknown option croaks
eval { $ssh->option(bogus => 1) };
like $@, qr/unknown option/i, 'option() croaks on unknown key';

# connect to a port that immediately refuses — must return 0, not die
{
    my $s = Net::LibSSH->new;
    $s->option(host => '127.0.0.1');
    $s->option(port => 1);          # port 1 is always refused
    $s->option(timeout => 3);
    my $rc = eval { $s->connect };
    is $@, '', 'connect() does not die on refused port';
    is $rc, 0, 'connect() returns 0 on refused port';
    my $msg = $s->error;
    ok defined($msg) && length($msg), 'error() set after failed connect';
}

done_testing;
