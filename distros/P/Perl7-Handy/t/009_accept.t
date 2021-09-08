print "1..1\n";
print "ok - 1 SKIP on CPAN\n";

__END__
use 5.00503;
use strict;
BEGIN { $|=1; print "1..6\n"; my $testno=1; sub ok { print $_[0]?'ok ':'not ok ',$testno++,$_[1]?" - $_[1]\n":"\n" }}

use FindBin;
use lib "$FindBin::Bin/../lib";
use Perl7::Handy;
use Socket;

close(STDERR);

my $rc = 0;

eval q{
    $rc = socket(PROTOSOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
};
ok($@, q{socket(PROTOSOCKET,PF_INET,SOCK_STREAM,getprotobyname('tcp'))});

if ($^O =~ /cygwin/) {
    for (2..6) {
        ok(1, "SKIP \$^O=$^O");
    }
    exit;
}
else {
    eval q{
        if (not CORE::accept(SOCKET,PROTOSOCKET)) {
            for (2..6) {
                ok(1, "SKIP \$^O=$^O");
            }
            exit;
        }
    };
}

eval q{
    $rc = accept(SOCKET,PROTOSOCKET);
};
ok($@, q{accept(SOCKET,PROTOSOCKET)});
eval q{
    if ($rc) {
        close(SOCKET);
    }
};

eval q{
    $rc = accept(my $socket1,PROTOSOCKET);
    ok($rc, q{accept(my $socket1,PROTOSOCKET)});
    if ($rc) {
        close($socket1);
    }
};

eval q{
    local $_ = fileno(PROTOSOCKET);
    close(PROTOSOCKET);
};

$rc = socket(my $protosocket,PF_INET,SOCK_STREAM,getprotobyname('tcp'));
ok($rc, q{socket(my $protosocket,PF_INET,SOCK_STREAM,getprotobyname('tcp'))});

eval q{
    $rc = accept(SOCKET,$protosocket);
};
ok($rc, q{accept(SOCKET,$protosocket)});
eval q{
    if ($rc) {
        close(SOCKET);
    }
};

$rc = accept(my $socket2,$protosocket);
ok($rc, q{accept(my $socket2,$protosocket)});
if ($rc) {
    close($socket2);
}

close($protosocket);

__END__
