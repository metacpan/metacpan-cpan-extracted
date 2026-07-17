use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $dist = "$FindBin::Bin/..";
my $version = '0.001001';

my $module = do {
    open my $fh, '<', "$dist/lib/Net/Blossom/Server/Backend/Filesystem.pm"
        or die "Unable to read Filesystem.pm: $!";
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
like($makefile,
    qr/^\s*VERSION_FROM\s*=>\s*'lib\/Net\/Blossom\/Server\/Backend\/Filesystem\.pm',/m,
    'Makefile.PL uses VERSION_FROM');
my ($runtime_requires) = $makefile =~ /PREREQ_PM\s*=>\s*\{(.*?)^\s*\},/ms;
unlike($runtime_requires,
    qr/'Net::Blossom::Server::Backend::(?:SQLite|Postgres)'\s*=>/,
    'runtime dependencies do not select a metadata backend');

my $changes = do {
    open my $fh, '<', "$dist/Changes" or die "Unable to read Changes: $!";
    local $/;
    <$fh>;
};
like($changes, qr/^$version\s+\d{4}-\d{2}-\d{2}$/m,
    'Changes records release version and date');
like($changes, qr/Initial CPAN release/, 'Changes records the initial release');
unlike($changes, qr/C<[^>]+>/, 'Changes uses plain text');

my $manifest = do {
    open my $fh, '<', "$dist/MANIFEST" or die "Unable to read MANIFEST: $!";
    local $/;
    <$fh>;
};
unlike($manifest, qr/\.tar\.gz(?:\s|\z)/, 'MANIFEST excludes release archives');
unlike($manifest, qr/^Net-Blossom.*-\d/m,
    'MANIFEST excludes distribution directories');

done_testing;
