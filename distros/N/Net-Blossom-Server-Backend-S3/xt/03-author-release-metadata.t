use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $dist = "$FindBin::Bin/..";
my $version = '0.001000';

my $module = do {
    open my $fh, '<', "$dist/lib/Net/Blossom/Server/Backend/S3.pm"
        or die "Unable to read S3.pm: $!";
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
like($makefile, qr/^\s*VERSION_FROM\s*=>\s*'lib\/Net\/Blossom\/Server\/Backend\/S3\.pm',/m,
    'Makefile.PL uses VERSION_FROM');
like($makefile, qr/^\s*'Net::Amazon::S3'\s*=>\s*'0\.992',/m,
    'Makefile.PL requires the tested S3 client version');
like($makefile, qr/^\s*'HTTP::Message'\s*=>\s*'0',/m,
    'Makefile.PL declares the direct HTTP test dependency');
my ($runtime_requires) = $makefile =~ /PREREQ_PM\s*=>\s*\{(.*?)^\s*\},/ms;
unlike($runtime_requires, qr/'Net::Blossom::Server::Backend::(?:SQLite|Postgres)'\s*=>/,
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

_check_manifest_files($dist);

done_testing;

sub _check_manifest_files {
    my ($dist) = @_;
    my $manifest = do {
        open my $fh, '<', "$dist/MANIFEST" or die "Unable to read MANIFEST: $!";
        local $/;
        <$fh>;
    };
    unlike($manifest, qr/\.tar\.gz(?:\s|\z)/, 'MANIFEST excludes release archives');
    unlike($manifest, qr/^Net-Blossom.*-\d/m, 'MANIFEST excludes distribution directories');
}
