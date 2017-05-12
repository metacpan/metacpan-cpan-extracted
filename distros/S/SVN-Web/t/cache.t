#!/usr/bin/perl

use warnings;
use strict;

use Test::More;
use POSIX ();

plan 'no_plan';

ok(1, 'stub');

__END__

use SVN::Web::Test;

BEGIN {
    plan skip_all => "Test::Differences not installed"
        unless eval { require Test::Differences; 1 };

    plan skip_all => "Cache::Cache not installed"
        unless eval { require Cache::MemoryCache; 1 };
}

my $repos = 't/repos';

my $test = SVN::Web::Test->new(repo_path => $repos,
			       repo_dump => 't/test_repo.dump');

my $repo_url = 'file://' . POSIX::getcwd() . '/t/repos';

$test->set_config({ uri_base => 'http://localhost',
		    script   => '/svnweb',
		    config   => { repos => { repos => $repo_url } },
		    });

my $url  = $test->site_root();
my $mech = $test->mech();

my %store;

# First, make sure that caching is turned off, and walk the whole tree.
# Build a hash that maps URLs to contents.  We'll check this later.
diag('First walk');
$mech->get($url);
$test->walk_site(\&store_content);

plan tests => keys(%store) * 3;

# Now, without turning caching on, do it again, to verify that the
# results are the same without caching.
diag('Second walk, no caching');
$mech->get($url);
$test->walk_site(\&check_content);

# Now turn caching on, walk the site once more to prime the cache
diag('Third walk, priming cache');

my $config = SVN::Web::get_config();
$config->{cache} = { class => 'Cache::MemoryCache' };
SVN::Web::set_config($config);

$mech->get($url);
$test->walk_site(\&check_content);

# Walk the site for a final time.  Most requests should hit the cached
# copy, and there should be no content changes
diag('Fourth walk, using cache');
$mech->get($url);
$test->walk_site(\&check_content);

sub store_content {
    my $test = shift;

    $store{$test->mech()->uri()} = $test->mech()->content();
}

sub check_content {
    my $test = shift;

    Test::Differences::eq_or_diff($test->mech()->content(), $store{$test->mech()->uri()}, "$test->mech()->uri()");
}

