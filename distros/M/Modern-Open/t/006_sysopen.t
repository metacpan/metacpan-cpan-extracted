use 5.00503;
use strict;
use Test::Simply tests => 2;
use Modern::Open;
use Fcntl;

my $rc = 0;

$rc = sysopen(FILE,$0,O_RDONLY);
ok($rc, q{sysopen(FILE,$0,O_RDONLY)});
if ($rc) {
    local $_ = fileno(FILE);
    close(FILE);
}

$rc = sysopen(my $fh,$0,O_RDONLY);
ok($rc, q{sysopen(my $fh,$0,O_RDONLY)});
if ($rc) {
    close($fh);
}

__END__
