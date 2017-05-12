#!perl -T
use strict;
use Test::More;


my @oid_list = qw<
    .1.3.6.1.4.1.32272.1.1.1.42
    .1.3.6.1.4.1.32272.1.1.1.56
    .1.3.6.1.4.1.32272.1.1.2.42
    .1.3.6.1.4.1.32272.1.1.2.56
    .1.3.6.1.4.1.32272.1.1.3.42
    .1.3.6.1.4.1.32272.1.1.3.56

    .1.3.6.1.4.1.32272.2.1.1.42
    .1.3.6.1.4.1.32272.2.1.1.56
    .1.3.6.1.4.1.32272.2.1.2.42
    .1.3.6.1.4.1.32272.2.1.2.56

    .1.3.6.1.4.1.32272.3.1.1.42
    .1.3.6.1.4.1.32272.3.1.1.56
    .1.3.6.1.4.1.32272.3.1.2.42
    .1.3.6.1.4.1.32272.3.1.2.56
    .1.3.6.1.4.1.32272.3.1.3.42
    .1.3.6.1.4.1.32272.3.1.3.56
>;

my $base_oid  = ".1.3.6.1.4.1.32272";
my $walk_base = "$base_oid.2";
my @context   = grep /^$walk_base/, @oid_list;

my @cases = (
    [ "called with no request and no context",
        [], $oid_list[0] ],

    [ "called with no request, but with a context",
        [ "", $walk_base ], $oid_list[6] ],

    [ "called with a request within the list, with no context",
        [ "$base_oid.3" ], $oid_list[10] ],

    [ "called with a request within the list, with no context",
        [ $oid_list[4] ], $oid_list[5] ],

    [ "called with a request just before the end of the list, with no context",
        [ $oid_list[-2] ], $oid_list[-1] ],

    [ "called with a request outside the list, with no context",
        [ "$base_oid.5" ], "NONE" ],

    [ "called with a request within the list, before the context",
        [ "$base_oid.1", $walk_base ], "NONE" ],

    [ "called with a request within the list, within the context",
        [ "$base_oid.2", $walk_base ], $oid_list[6] ],

    [ "called with a request outside the list, after the context",
        [ "$base_oid.5", $walk_base ], "NONE" ],
);


plan tests => 1 + 1 + 2 * @cases + 2 * (@context+1);

# load the module
use_ok("SNMP::ToolBox");

# check diagnostics
eval { find_next_oid() };
like($@, '/^error: first argument must be an arrayref/',
    "called with no arguments");

# check the different cases
for my $case (@cases) {
    my ($descr, $args, $rval) = @$case;
    my $next_oid = eval { find_next_oid(\@oid_list, @$args) };
    is($@, "", $descr);
    is($next_oid, $rval, " - find_next_oid(\@oid_list, @$args)");
}

# walk the MIB
my %next_of;
@next_of{$walk_base, @context} = (@context, "NONE");

my $curr_oid = $walk_base;

while ($curr_oid ne "NONE") {
    my $next_oid = eval { find_next_oid(\@oid_list, $curr_oid, $walk_base) };
    is($@, "", "walking $curr_oid -> $next_oid");
    is($next_oid, $next_of{$curr_oid},
        " - find_next_oid(\@oid_list, '$curr_oid', '$walk_base')");
    $curr_oid = $next_oid;
}

