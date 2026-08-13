#!perl

# Nothing may spend a reference it does not own on one of perl's immortal
# SVs. Handing &PL_sv_undef to av_store, or letting it become an SV * RETVAL
# (which xsubpp mortalises), buys a SvREFCNT_dec that nobody paid for.
#
# From perl 5.20 the immortals are immune to that - sv_free resets their
# refcount - so the damage is invisible and the tests pass. Before 5.20 the
# refcount really does reach zero, PL_sv_undef is freed, and the process
# segfaults the next time anything touches undef: Punk 0.04 crashed exactly
# that way on 5.14 and 5.18 while passing everywhere newer.
#
# So assert the invariant rather than the symptom. The refcount of the
# immortal must not move across any number of these calls, on every perl.

use 5.010;
use strict;
use warnings;
use FindBin ();
use Test::More;

BEGIN {
    plan skip_all => 'Devel::Peek required to read an immortal refcount'
        unless eval { require Devel::Peek; 1 };
}

require Punk;

# Devel::Peek dumps to STDERR; \undef is PL_sv_undef itself, so the last
# REFCNT in the dump is the immortal's.
sub immortal_refcount {
    my $out = '';
    open my $save, '>&', \*STDERR or return;
    close STDERR;
    open STDERR, '>', \$out       or do { open STDERR, '>&', $save; return };
    Devel::Peek::Dump(\undef);
    open STDERR, '>&', $save      or return;
    my @n = $out =~ /REFCNT = (\d+)/g;
    return $n[-1];
}

plan skip_all => 'cannot read the immortal refcount on this perl'
    unless defined immortal_refcount() && immortal_refcount() =~ /^\d+$/;

# $n runs of $code must leave the immortal exactly where it started.
sub holds_steady {
    my ($name, $code, $n) = @_;
    $n ||= 50;
    $code->() for 1 .. 3;              # warm up: one-off setup is not a leak
    my $before = immortal_refcount();
    $code->() for 1 .. $n;
    my $spent = $before - immortal_refcount();
    is $spent, 0, $name
        or diag "spent $spent immortal references over $n calls"
              . " - fatal on perl before 5.20";
}

my $DOCS = "$FindBin::Bin/test/docs";

SKIP: {
    skip 'markdown mount needs Markdown::Simple and Template::Stencil', 2
        unless eval { require Markdown::Simple; require Template::Stencil; 1 };

    # The one the smokers found: with no index to store, the capture slot was
    # given &PL_sv_undef to own.
    holds_steady 'markdown mount with search => 0 owns no immortal', sub {
        my $app = Punk::Mount::Markdown->app($DOCS, { search => 0 }, '/docs');
        undef $app;
    }, 20;

    holds_steady 'markdown mount with search on owns no immortal', sub {
        my $app = Punk::Mount::Markdown->app($DOCS, {}, '/docs');
        undef $app;
    }, 20;
}

# The accessors that returned an immortal as an SV * RETVAL, each on the
# branch that has nothing to return.
holds_steady 'Punk::Future->failure on a pending future', sub {
    my $f = Punk::Future->new;
    my $e = $f->failure;
};

holds_steady 'Punk::Request->upload for a name that is not there', sub {
    my $r = Punk::Request->new({ REQUEST_METHOD => 'GET', PATH_INFO => '/' });
    my $u = eval { $r->upload('no-such-field') };
};

done_testing;
