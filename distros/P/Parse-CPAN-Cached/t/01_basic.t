#! /usr/bin/perl

use strict;
use warnings;

use Test::Most;
use FindBin;
use File::Temp qw<tempdir>;
use App::Cache;
use Cwd qw<getcwd>;

my $cache_directory = tempdir(CLEANUP => 1);
my ($local, $test_count);
my (%path_tests, %isa_tests, %key_tests);
BEGIN{
    $local      = "$FindBin::Bin/asset/";
    %path_tests = (
        absolute    => $local,
        temp        => tempdir(CLEANUP => 1),
        dotdot      => "$local/../asset/",
        relative    => './asset/',
    );
    %key_tests  = (
        unsupported => { re => qr/Unknown cpan type 'fu'/, key => 'fu' },
        empty       => { re => qr/Unknown cpan type ''/,   key => '' },
        'undef'     => { re => qr/No type/,                key => undef },
    );
    %isa_tests  = (
        authors     => 'Parse::CPAN::Whois',
        whois       => 'Parse::CPAN::Whois',
        packages    => 'Parse::CPAN::Packages',
    );
    $test_count = 10
                +   scalar(keys %path_tests)
                +   scalar(keys %key_tests)
                + 2*scalar(keys %isa_tests)
                + 2*scalar(keys %isa_tests) - 1;
}

use Test::More tests => $test_count;

require_ok('Parse::CPAN::Cached');

# This works regardless of whether you have a ~/.minicpanrc because
# we don't notice it is missing until we call cache_dir (which is a lazy
# or deferred attribute).  This test may be a bit pointless.
ok(
    Parse::CPAN::Cached->new(cache => get_app_cache()),
    'Basic construction works'
);

# Invalid/missing cpan_mini_config should return a fatal error
my $cached = Parse::CPAN::Cached->new(
    cpan_mini_config => {},
    cache            => get_app_cache(),
);

throws_ok { $cached->cache_dir } qr/Have you loaded minicpan\?/,
    'No cpan_mini_config error caught correctly';

# Absolute, tmp, path containing ../ & relative path.
my $orig_cwd = getcwd;
chdir $FindBin::Bin;  # switch dir for relative path test
is(
    get_a_cache($path_tests{$_})->cache_dir,
    $path_tests{$_},
    "cache_dir works with a $_ dir"
) for keys %path_tests;
chdir $orig_cwd;     # switch back to where we started

# Test invalid request keys fail as we expect
key_tests($local, %key_tests);

# Object returned from the cache is what we expect
isa_tests($local, %isa_tests);

# Same again, only sans optional 00whois.xml
rename "$local/authors/00whois.xml", "$local/00whois.xml";
$isa_tests{authors} = 'Parse::CPAN::Authors';
delete $isa_tests{whois};
isa_tests($local, %isa_tests);
key_tests($local,
    deleted_whois => { re => qr/00whois\.xml not found at/, key => 'whois' }
);

# Custom info sub
{
    my $info_called = 0;
    my $custom_info_sub = sub {
        my ($msg) = @_;
        if ($msg =~ /\ACaching '.*\.txt\.gz' for (packages|authors)\z/) {
            pass('Custom info was called as expected');
            $info_called++
        }
    };

    my $cached = Parse::CPAN::Cached->new(
        cpan_mini_config => { local => $local },
        cache            => get_app_cache(),
        info => $custom_info_sub,
    );
    $cached->cache->clear;
    is($info_called, 0, 'Custom info sub not called yet');
    $cached->parse_cpan('packages');
    is($info_called, 1, 'Custom info sub called once only');
    $cached->parse_cpan('packages');
    is($info_called, 1, 'Custom info sub called once only, caching working');
    $cached->parse_cpan('authors');
    is($info_called, 2, 'Custom info sub called twice');
    $cached->parse_cpan('authors');
    is($info_called, 2, 'Custom info sub called twice, caching working');
}

# Move 00whois.xml back to original location (see deleted_whois key test)
END {
    rename "$local/00whois.xml", "$local/authors/00whois.xml"
        if -e "$local/00whois.xml";
}

sub key_tests {
    my ($cpan_dir, %tests) = @_;

    for (keys %tests) {
        throws_ok {
            get_a_cache($cpan_dir)->parse_cpan($tests{$_}{key})
        } $tests{$_}{re},
        "Fails correctly on a $_ key";
    }
}

sub isa_tests {
    my ($cpan_dir, %tests) = @_;

    my $cached = get_a_cache($cpan_dir);

    # First do all with the same parser
    isa_ok($cached->parse_cpan($_), $tests{$_}, 'Shared parser returned' )
        for keys %tests;

    # Then do each with a fresh parser
    isa_ok(
        get_a_cache($cpan_dir)->parse_cpan($_),
        $tests{$_},
        'Freshly minted parser returned'
    ) for keys %tests;
}

sub get_a_cache {
    return Parse::CPAN::Cached->new(
        cpan_mini_config => { local => shift },
        cache            => get_app_cache(),
    );
}

# We supply our own App::Cache to ensure we use a different cache dir from what
# a properly/previously installed Parse::CPAN::Cached instance would.
sub get_app_cache {
    return App::Cache->new({directory => $cache_directory});
}
