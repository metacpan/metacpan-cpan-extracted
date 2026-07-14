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
    open my $fh, '<', "$dist/lib/Net/Blossom/Server/Backend/Postgres.pm"
        or die "Unable to read lib/Net/Blossom/Server/Backend/Postgres.pm: $!";
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

like($makefile, qr/^\s*VERSION_FROM\s*=>\s*'lib\/Net\/Blossom\/Server\/Backend\/Postgres\.pm',/m, 'Makefile.PL uses VERSION_FROM');
like($makefile, qr/^\s*'Net::Blossom'\s*=>\s*'\Q$net_blossom_version\E',/m, 'Makefile.PL depends on the released Net::Blossom version');
like($makefile, qr/^\s*'Net::Blossom::Server'\s*=>\s*'\Q$server_version\E',/m, 'Makefile.PL depends on the component-contract server version');
like($makefile, qr/^\s*'DBD::Pg'\s*=>\s*'2\.12\.0',/m, 'Makefile.PL requires pg_lo method support');

my $changes_path = "$dist/Changes";
ok(-f $changes_path, 'Changes exists');
if (-f $changes_path) {
    my $changes = do {
        open my $fh, '<', $changes_path or die "Unable to read Changes: $!";
        local $/;
        <$fh>;
    };

    like($changes, qr/^$version\s+\d{4}-\d{2}-\d{2}$/m, 'Changes records release version and date');

    my ($release_changes) = $changes =~ /^\Q$version\E\s+\d{4}-\d{2}-\d{2}\n(.*?)(?=^\S|\z)/ms;
    like($release_changes, qr/metadata and large-object storage/, 'release records the component split');
    like($release_changes, qr/Migrate the 0\.001001 large-object schema/, 'release records the schema migration');
    unlike($release_changes, qr/C<[^>]+>/, 'release changes use plain text');

    my ($previous_changes) = $changes =~ /^0\.001001\s+2026-07-13\n(.*?)(?=^\S|\z)/ms;
    like($previous_changes, qr/streamed PostgreSQL large objects/, 'previous release records the large-object migration');
    like($previous_changes, qr/schema.*AutoCommit/s, 'previous release records schema and transaction requirements');
    like($previous_changes, qr/Class::Tiny/, 'previous release records the constructor migration');

    my ($initial_changes) = $changes =~ /^0\.001000\s+2026-07-10\n(.*?)(?=^\S|\z)/ms;
    is($initial_changes, "    - Initial CPAN release.\n", 'published release history is unchanged');
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
