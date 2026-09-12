#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Shared::Arena ();

# The C ABI: a stable address, a selftest that walks every entry, and a
# provider config that points a consumer at the installed header.

my $p = Shared::Arena::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, Shared::Arena::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer: where the loader maps the object '
                  . 'decides the sign bit');

# ---- the selftest ---------------------------------------------------------
#
# A table is a list of addresses, and nothing about compiling one proves an
# entry points where its declaration says. Two entries of the same shape can be
# swapped and the build stays clean. So the selftest drives a region, a ring and
# a cursor through every entry with every answer checked.
is(Shared::Arena::_abi_selftest(), 0,
   'every entry in the table answered as its declaration says')
    or diag('check number ' . Shared::Arena::_abi_selftest()
          . ' in sa_abi_selftest failed; the numbers are the SA_STEP comments '
          . 'in include/sa/sa_abi_impl.h');

# ---- the two ends of the version -----------------------------------------
#
# The table compiled into the .so, and the header that was INSTALLED for
# consumers to compile against. They are different files, and nothing else
# notices when an append moves one and not the other: the table would answer 1
# while the header promised 2, and every consumer built against 2 would refuse a
# provider that in fact has what it wants.
# The header's own policy (see sa_abi.h): the table only grows at the end and
# SA_ABI_VERSION bumps on every append, so a consumer that checks
# `t->abi_version >= SA_ABI_VERSION` refuses a provider that is missing entries
# it was built against. 0.03 appended map_store_ttl and the cuckoo filter,
# taking it to 2. The next `is` proves the header and the compiled table agree
# on that number, which is what actually matters.
is(Shared::Arena::_abi_version(), 2,
   'the table is at version 2, matching sa_abi.h after the 0.03 appends');

{
    require Shared::Arena::Install::Files;
    no warnings 'once';
    my $core = $Shared::Arena::Install::Files::CORE;
    ok(defined $core && -d $core, 'Install::Files records where the header went')
        or diag 'CORE: ' . ($core // 'undef');

    my $h = defined $core ? "$core/sa_abi.h" : undef;
    ok(defined $h && -f $h, 'and sa_abi.h is there for a consumer to include');

    my $header;
    if (defined $h && open my $fh, '<', $h) {
        while (<$fh>) { $header = $1, last if /^\#define\s+SA_ABI_VERSION\s+(\d+)/ }
        close $fh;
    }
    is($header, Shared::Arena::_abi_version(),
       'the installed header and the compiled table name the same ABI version');
}

# ---- what a consumer is promised ------------------------------------------
#
# Not the table's contents - a consumer resolves those in C - but the things it
# cannot check for itself from Perl: that the entries are still in the order
# they were published in, and that none of them is named something a Windows
# perl will turn into a macro. An append moves nothing above it; a REORDER
# moves everything, silently, because a function pointer has no name at runtime.
{
    my $core = do { no warnings 'once'; $Shared::Arena::Install::Files::CORE };
    SKIP: {
        skip 'no installed header to read', 2
            unless defined $core && -f "$core/sa_abi.h";
        open my $fh, '<', "$core/sa_abi.h" or skip "cannot read the header: $!", 2;
        my (@members, $in);
        while (<$fh>) {
            $in = 1 if /^typedef struct sa_abi \{/;
            next unless $in;
            last if /^\} sa_abi;/;
            push @members, $1 if /\(\s*\*(\w+)\s*\)\s*\(/;
        }
        close $fh;

        is_deeply(\@members, [qw(
            config_init create attach_named release destroy_named errstr
            region_bytes is_creator
            carve locate at
            ring_open ring_release publish max_record slot_bytes ring_slots
            ring_position
            cursor_open cursor_release drain counts
            join beat
            map_open map_release map_store map_fetch map_delete map_incr
            map_counts map_pair_max map_capacity
            bloom_open bloom_release bloom_add bloom_check bloom_reset
            bloom_bits bloom_hashes bloom_set bloom_estimate
            hist_open hist_release hist_record hist_quantile hist_reset
            hist_counts hist_bucket_low hist_bucket_high hist_bucket_count
            cache_open cache_release cache_set cache_get cache_remove
            cache_clear cache_counts cache_pair_max

            rate_open rate_release rate_allow rate_peek
            rate_reset rate_forget rate_slots rate_used

            cms_open cms_release cms_add cms_estimate cms_reset
            cms_total cms_error cms_rows cms_width

            group_open group_release group_claim
            group_position group_counts

            map_store_ttl

            cuckoo_open cuckoo_release cuckoo_add cuckoo_check
            cuckoo_remove cuckoo_reset cuckoo_counts

            lease_open lease_release_handle lease_acquire lease_renew
            lease_release lease_mine lease_holder lease_fence

            sb_open sb_release sb_take sb_field sb_begin sb_set_gauge
            sb_add_gauge sb_set_status sb_end sb_read sb_slots sb_nfields
            sb_field_name
        )], 'the entries are in the order they were published in');

        # Under PERL_IMPLICIT_SYS - every Strawberry perl - XSUB.h redefines
        # these as function-like macros, and a member with one of those names
        # breaks at every call site while its declaration compiles cleanly. A
        # sibling dist in this workspace shipped a table with a member called
        # `close` and failed on the Strawberry smoker in its own selftest.
        my %trap = map { $_ => 1 } qw(
            open close read write stat link unlink send recv socket select
            time exit abort malloc calloc realloc free getpid kill access
            chmod dup lseek rename mkdir chdir rmdir opendir readdir
        );
        my @named = grep { $trap{$_} } @members;
        is_deeply(\@named, [],
                  'and none of them is a name XSUB.h turns into a macro')
            or diag "rename these, or every call site needs parentheses: @named";
    }
}

# ---- the provider config ---------------------------------------------------
ok(eval { require Shared::Arena::Install::Files; 1 },
   'Shared::Arena::Install::Files loads') or diag $@;
{
    no warnings 'once';
    my @deps = Shared::Arena::Install::Files::deps();
    is_deeply(\@deps, ['Frozen'],
              'and it names Frozen, whose ABI the frozen tenant reads through');

    # Naming the dependency is only half of it. A consumer says
    # ExtUtils::Depends->new($me, 'Shared::Arena') and must come out with
    # Frozen's include path as well as this dist's, without ever having
    # mentioned Frozen - that is what a recorded dependency is FOR, and it is
    # resolved at the consumer's configure time rather than here.
    SKIP: {
        eval { require ExtUtils::Depends; 1 }
            or skip 'no ExtUtils::Depends', 1;
        my $inc = eval {
            my $p = ExtUtils::Depends->new('Some::Consumer', 'Shared::Arena');
            my %v = $p->get_makefile_vars;
            $v{INC} || '';
        };
        skip "cannot resolve as a consumer would: $@", 1 if $@;
        like($inc, qr/Frozen/,
             'a consumer of this dist inherits Frozen\'s include path');
    }
}

done_testing;
