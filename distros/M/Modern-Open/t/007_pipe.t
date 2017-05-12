use 5.00503;
use strict;
use Test::Simply tests => 2;
use Modern::Open;

my $rc = 0;

$rc = pipe(README,WRITEME);
ok($rc, q{pipe(README,WRITEME)});
if ($rc) {
    local $_ = fileno(README);
    close(README);
    local $_ = fileno(WRITEME);
    close(WRITEME);
}

$rc = pipe(my $readme,my $writeme);
ok($rc, q{pipe(my $readme,my $writeme)});
if ($rc) {
    close($readme);
    close($writeme);
}

__END__
