######################################################################
# 0002-router.t - unit tests for PSGI::Handy::Router
#
# ina closure-array pattern: one assertion per closure, the plan count
# is derived from scalar(@tests) and never hard-coded.
######################################################################
use strict;
BEGIN { $INC{'warnings.pm'} = '' if $] < 5.006 }; use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/../lib";
use PSGI::Handy;

# --- minimal TAP helpers (no Test::More: must run on 5.005_03) -------
my $count = 0;
sub ok {
    my ($cond, $label) = @_;
    $count++;
    print(($cond ? "ok" : "not ok") . " $count - " . (defined $label ? $label : '') . "\n");
    return $cond;
}

sub eq_hash {
    my ($a, $b) = @_;
    return 0 unless ref($a) eq 'HASH' && ref($b) eq 'HASH';
    my @ak = sort keys %$a;
    my @bk = sort keys %$b;
    return 0 unless scalar(@ak) == scalar(@bk);
    my $i;
    for ($i = 0; $i < scalar(@ak); $i++) {
        return 0 unless $ak[$i] eq $bk[$i];
    }
    my $k;
    for $k (@ak) {
        my $av = $a->{$k};
        my $bv = $b->{$k};
        return 0 if (defined($av) ? 1 : 0) != (defined($bv) ? 1 : 0);
        next unless defined $av;
        return 0 unless $av eq $bv;
    }
    return 1;
}

# handlers used as identity markers
my $h_home  = sub { 'home'  };
my $h_user  = sub { 'user'  };
my $h_post  = sub { 'post'  };
my $h_file  = sub { 'file'  };
my $h_feed  = sub { 'feed'  };
my $h_first = sub { 'first' };
my $h_secnd = sub { 'second' };

my @tests = (
    # 1: new returns a blessed object
    sub {
        my $r = PSGI::Handy::Router->new;
        ok(ref($r) && $r->isa('PSGI::Handy::Router'), 'new returns a router object');
    },

    # 2: unknown path -> undef (404)
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/', $h_home);
        ok(!defined($r->match('GET', '/nope')), 'unknown path returns undef (404)');
    },

    # 3: static route matches and returns the registered handler
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/', $h_home);
        my $m = $r->match('GET', '/');
        ok($m && $m->{handler} == $h_home, 'static "/" returns the registered handler');
    },

    # 4: static route yields an empty params hash
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/', $h_home);
        my $m = $r->match('GET', '/');
        ok($m && eq_hash($m->{params}, {}), 'static route params is empty');
    },

    # 5: :id captures a single segment
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/users/:id', $h_user);
        my $m = $r->match('GET', '/users/42');
        ok($m && eq_hash($m->{params}, { id => '42' }), ':id captures the segment');
    },

    # 6: multiple named params
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/posts/:year/:month', $h_post);
        my $m = $r->match('GET', '/posts/2026/05');
        ok($m && eq_hash($m->{params}, { year => '2026', month => '05' }),
           'two named params captured');
    },

    # 7: :id does not cross a slash boundary
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/users/:id', $h_user);
        ok(!defined($r->match('GET', '/users/42/extra')),
           ':id does not match across a slash');
    },

    # 8: method mismatch -> { allowed => [...] } (405)
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/x', $h_home);
        my $m = $r->match('POST', '/x');
        ok($m && $m->{allowed} && scalar(@{$m->{allowed}}) == 1
              && $m->{allowed}[0] eq 'GET',
           'method mismatch reports allowed methods (405)');
    },

    # 9: trailing splat captures the remainder including slashes
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/files/*', $h_file);
        my $m = $r->match('GET', '/files/a/b/c.txt');
        ok($m && eq_hash($m->{params}, { splat => 'a/b/c.txt' }),
           'trailing * captures the rest of the path');
    },

    # 10: dot in a literal segment is literal, not a wildcard
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/feed.xml', $h_feed);
        ok(!defined($r->match('GET', '/feedaxml')),
           'literal dot is not a regex wildcard');
    },

    # 11: first registered matching route wins
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('GET', '/dup', $h_first);
        $r->add('GET', '/dup', $h_secnd);
        my $m = $r->match('GET', '/dup');
        ok($m && $m->{handler} == $h_first, 'first matching route wins');
    },

    # 12: method matching is case-insensitive on input
    sub {
        my $r = PSGI::Handy::Router->new;
        $r->add('get', '/lc', $h_home);
        my $m = $r->match('GeT', '/lc');
        ok($m && $m->{handler} == $h_home, 'method comparison is case-insensitive');
    },
);

print "1.." . scalar(@tests) . "\n";
my $t;
for $t (@tests) {
    $t->();
}
