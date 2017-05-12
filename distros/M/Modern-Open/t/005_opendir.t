use 5.00503;
use strict;
use Test::Simply tests => 2;
use Modern::Open;

my $rc = 0;

$rc = opendir(DIR,'.');
ok($rc, q{opendir(DIR,'.')});
if ($rc) {
    local $_ = fileno(DIR);
    closedir(DIR);
}

$rc = opendir(my $dir,'.');
ok($rc, q{opendir(my $dir,'.')});
if ($rc) {
    closedir($dir);
}

__END__
