use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $dist = "$FindBin::Bin/..";
my $version = '0.001000';

my $module = do {
    open my $fh, '<', "$dist/lib/Net/Blossom.pm"
        or die "Unable to read lib/Net/Blossom.pm: $!";
    local $/;
    <$fh>;
};

my ($module_version) = $module =~ /^our \$VERSION = '([^']+)';$/m;
is($module_version, $version, 'top-level module declares release version');

my $makefile = do {
    open my $fh, '<', "$dist/Makefile.PL"
        or die "Unable to read Makefile.PL: $!";
    local $/;
    <$fh>;
};

like($makefile, qr/^\s*VERSION_FROM\s*=>\s*'lib\/Net\/Blossom\.pm',/m, 'Makefile.PL uses VERSION_FROM');

my $changes_path = "$dist/Changes";
ok(-f $changes_path, 'Changes exists');
if (-f $changes_path) {
    my $changes = do {
        open my $fh, '<', $changes_path or die "Unable to read Changes: $!";
        local $/;
        <$fh>;
    };

    like($changes, qr/^$version\s+\d{4}-\d{2}-\d{2}$/m, 'Changes records release version and date');
}

done_testing;
