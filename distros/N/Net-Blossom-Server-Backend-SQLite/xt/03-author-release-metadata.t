use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $dist = "$FindBin::Bin/..";
my $version = '0.001002';
my $net_blossom_version = '0.001001';
my $server_version = '0.001002';

my $module = do {
    open my $fh, '<', "$dist/lib/Net/Blossom/Server/Backend/SQLite.pm"
        or die "Unable to read lib/Net/Blossom/Server/Backend/SQLite.pm: $!";
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

like($makefile, qr/^\s*VERSION_FROM\s*=>\s*'lib\/Net\/Blossom\/Server\/Backend\/SQLite\.pm',/m, 'Makefile.PL uses VERSION_FROM');
like($makefile, qr/^\s*'Net::Blossom'\s*=>\s*'\Q$net_blossom_version\E',/m, 'Makefile.PL depends on the released Net::Blossom version');
like($makefile, qr/^\s*'Net::Blossom::Server'\s*=>\s*'\Q$server_version\E',/m, 'Makefile.PL depends on the component-contract server version');

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

_check_manifest_files($dist);

done_testing;

sub _check_manifest_files {
    my ($dist) = @_;
    my $skip_path = "$dist/MANIFEST.SKIP";

    ok(-f $skip_path, 'MANIFEST.SKIP exists');
    return unless -f $skip_path;

    my $skip = do {
        open my $fh, '<', $skip_path or die "Unable to read MANIFEST.SKIP: $!";
        local $/;
        <$fh>;
    };
    like($skip, qr/^#!include_default$/m, 'MANIFEST.SKIP includes default rules');
    ok((grep { $_ eq '\.tar\.gz\z' } split /\n/, $skip), 'MANIFEST.SKIP excludes release archives');
    ok((grep { $_ eq '^Net-Blossom.*-\d' } split /\n/, $skip), 'MANIFEST.SKIP excludes distribution directories');

    my $manifest = do {
        open my $fh, '<', "$dist/MANIFEST" or die "Unable to read MANIFEST: $!";
        local $/;
        <$fh>;
    };
    unlike($manifest, qr/\.tar\.gz(?:\s|\z)/, 'MANIFEST excludes release archives');
    unlike($manifest, qr/^Net-Blossom.*-\d/m, 'MANIFEST excludes distribution directories');
}
