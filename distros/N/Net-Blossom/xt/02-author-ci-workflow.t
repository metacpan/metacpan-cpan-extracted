use strictures 2;

use FindBin;
use Test::More;

plan skip_all => 'AUTHOR_TESTING is not set'
    unless $ENV{AUTHOR_TESTING};

my $root = _repo_root();
ok(-d "$root/dist/Net-Blossom", 'Net-Blossom distribution lives under dist');
ok(-d "$root/dist/Net-Blossom-Server", 'Net-Blossom-Server distribution lives under dist');
ok(-d "$root/dist/Net-Blossom-Server-Backend-SQLite", 'Net-Blossom-Server-Backend-SQLite distribution lives under dist');
ok(-d "$root/dist/Net-Blossom-Server-Backend-Postgres", 'Net-Blossom-Server-Backend-Postgres distribution lives under dist');

my $workflow = "$root/.github/workflows/ci.yml";
ok(-f $workflow, 'GitHub Actions CI workflow exists');
done_testing and exit unless -f $workflow;

open my $fh, '<', $workflow
    or die "Unable to read $workflow: $!";
my $yaml = do { local $/; <$fh> };

like($yaml, qr/perl-version:\s*\[\s*["']?5\.16["']?\s*,\s*["']?latest["']?\s*\]/,
    'CI tests Perl 5.16 and latest');
like($yaml, qr/actions\/checkout\@v7/,
    'CI uses current checkout action');
like($yaml, qr/shogo82148\/actions-setup-perl\@v1/,
    'CI sets up Perl with actions-setup-perl');
unlike($yaml, qr/(?:p5-CBOR-Free|reviewed CBOR::Free|\.deps\/p5-CBOR-Free)/,
    'CI installs the released CBOR::Free dependency');
like($yaml, qr/cpanm\s+-llocal\b[^\n]*--notest\b[^\n]*--with-develop\b[^\n]*--installdeps\s+\.\/dist\/Net-Blossom(?:\s|$)/,
    'CI installs Net-Blossom dependencies into local');
like($yaml, qr/cpanm\s+-llocal\b[^\n]*--notest\b[^\n]*--with-develop\b[^\n]*--installdeps\s+\.\/dist\/Net-Blossom-Server(?:\s|$)/,
    'CI installs Net-Blossom-Server dependencies into local');
like($yaml, qr/cpanm\s+-llocal\b[^\n]*--notest\s+\.\/dist\/Net-Blossom-Server(?:\s|$)/,
    'CI installs Net-Blossom-Server into local');
like($yaml, qr/cpanm\s+-llocal\b[^\n]*--notest\b[^\n]*--with-develop\b[^\n]*--installdeps\s+\.\/dist\/Net-Blossom-Server-Backend-SQLite(?:\s|$)/,
    'CI installs Net-Blossom-Server-Backend-SQLite dependencies into local');
like($yaml, qr/cpanm\s+-llocal\b[^\n]*--notest\b[^\n]*--with-develop\b[^\n]*--installdeps\s+\.\/dist\/Net-Blossom-Server-Backend-Postgres(?:\s|$)/,
    'CI installs Net-Blossom-Server-Backend-Postgres dependencies into local');
like($yaml, qr/postgres:16/,
    'CI provisions Postgres for backend tests');
like($yaml, qr/NET_BLOSSOM_POSTGRES_DSN/,
    'CI configures Postgres backend test DSN');
like($yaml, qr/prove\s+dist\/Net-Blossom\/t\s+dist\/Net-Blossom\/t\/bud\s+dist\/Net-Blossom-Server\/t/,
    'CI runs regular tests');
like($yaml, qr/prove\s+dist\/Net-Blossom\/t\s+dist\/Net-Blossom\/t\/bud\s+dist\/Net-Blossom-Server\/t\s+dist\/Net-Blossom-Server-Backend-SQLite\/t/,
    'CI runs SQLite backend regular tests');
like($yaml, qr/prove\s+dist\/Net-Blossom\/t\s+dist\/Net-Blossom\/t\/bud\s+dist\/Net-Blossom-Server\/t\s+dist\/Net-Blossom-Server-Backend-SQLite\/t\s+dist\/Net-Blossom-Server-Backend-Postgres\/t/,
    'CI runs Postgres backend regular tests');
like($yaml, qr/AUTHOR_TESTING=1\s+prove\s+dist\/Net-Blossom\/xt\s+dist\/Net-Blossom-Server\/xt\s+dist\/Net-Blossom-Server-Backend-SQLite\/xt\s+dist\/Net-Blossom-Server-Backend-Postgres\/xt/,
    'CI runs author tests');
like($yaml, qr/if:\s+matrix\.perl-version\s+==\s+'latest'/,
    'CI gates coverage to latest Perl');
like($yaml, qr/cpanm\s+-llocal\b[^\n]*--notest\b[^\n]*Devel::Cover\b/,
    'CI installs Devel::Cover separately');
like($yaml, qr/COVERAGE_TESTING=1\s+AUTHOR_TESTING=1\s+prove\s+dist\/Net-Blossom\/xt\/06-author-coverage\.t\s+dist\/Net-Blossom-Server\/xt\/05-author-coverage\.t\s+dist\/Net-Blossom-Server-Backend-SQLite\/xt\/04-author-coverage\.t\s+dist\/Net-Blossom-Server-Backend-Postgres\/xt\/04-author-coverage\.t/,
    'CI runs opt-in coverage author tests');

done_testing;

sub _repo_root {
    my $dir = $FindBin::Bin;
    while (1) {
        return $dir if -d "$dir/.git";

        my $parent = "$dir/..";
        last if $parent eq $dir;
        $dir = $parent;
    }

    die "Unable to find repository root from $FindBin::Bin";
}
