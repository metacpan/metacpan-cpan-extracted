use strict;
use warnings;

use Test::More;
use Params::Lazy;

sub stress_test {
    my @orig = @_;
    my %returns;

    local $_ = "set in stress_test";
    
    # These calls to force() don't use parens, which triggers
    # the custom op, if available.
    my $x = force $_[0];
    $returns{scalar} = $x;
    my @x = force $_[0];
    $returns{list} = \@x;
    my $j = join "", "<", force($_[0]), ">";
    $returns{join} = $j;

    my $tmp = "";
    open my $fh, ">", \$tmp;
    print $fh "<", force($_[0]), ">";
    close $fh;
    $returns{print} = $tmp;
    
    {
        my $w = "";
        local $SIG{__WARN__} = sub { $w .= shift };
        warn force $_[0];
        my $file = (caller(0))[1];
        ($returns{warn}) = $w =~ m/(\A.+?) at $file/s;
        $w = "";
        warn "<", force $_[0], ">";
        ($returns{warn_list}) = $w =~ m/(\A.+?) at $file/s;
    }
    
    $returns{eval} = eval 'force($_[0])';
    
    is_deeply(
        \@orig,
        \@_,
        "force() doesn't touch \@_"
    );
    
    return \%returns;
}

sub run {
    my ($code, %args) = @_;
    my $times = defined($args{times}) ? $args{times} : 1;
    my @ret;
    push @ret, force($code) while $times-- > 0;
    return @ret;
}

use Params::Lazy run => '^;@', stress_test => '^;@';

my @range = run("a".."z");
is_deeply(\@range, ["a".."z"], "can delay a range");

my @a = 1..10;
my $x;
@range = ();
my $count = 0;
my @against;
while ($_ = shift(@a)) {
    my $times = int(rand(9)) || 1;
    push @range, [run($x = /1/../10/, times => $times)];
    if ( @a ) {
        push @against, [ ($count+1)...($count+$times) ];
        $count += $times;
        is($x, $count, "the flip-flop is keeping state");
    }
    else {
        my $last = $times == 1 ? ($count + 1) : 1;
        like($x, qr/\A${last}E0\Z/, "Got the right end marker");
        
        my $last_batch = [ ($count + 1) . "E0" ];
        if ( $times > 1 ) {
            push @$last_batch, map { "1E0" } 1...$times-1;
        }
        push @against, $last_batch;
        
        is_deeply(
            [run($x = /1/../10/, times => 5)],
            [ map { "1E0" } 1..5 ],
            "running the delayed flipflop again after it gets to the end keeps returning 1E0"
        );
    }
}

is_deeply(
    \@range,
    \@against,
    "can delay a flip flop (scalar /foo/../bar/)"
);

() = @::empty;
my @result = run(@::empty);
is_deeply(\@result, [], "delaying an empty array doesn't return a glob");

TODO: {
    local $TODO = "delay wantarray should return true";
    my ($wantarray) = run wantarray;
    ok($wantarray, "delayed wantarray is run in list context");
}

sub wantfunc { wantarray }
my ($wantarray) = run wantfunc();
ok($wantarray, "delayed subs are run in list context");

{
    my $w = "";
    local $SIG{__WARN__} = sub { $w .= shift };
    run(warn("From warn"), times => 5);
    my @matched = $w =~ /(From warn)/g;
    is(@matched, 5, "warned five times");
}
{
    my $x = 0;
    my $t = 0;
    my @ret = run($x += ++$t, times => 3);
    is($x, 6);
    is($t, 3);
    is_deeply(\@ret, [1,3,6]);
}

sub contextual_return { return wantarray ? (@_, "one", "two") : "scalar: @_" }

my $ret = stress_test(rand(111), 1);

#^TODO

$ret = stress_test(scalar contextual_return("argument one", "argument two"));

is_deeply($ret, {
    list => ['scalar: argument one argument two'],
    map({ $_ => 'scalar: argument one argument two' } qw(scalar warn eval)),
    map({ $_ => '<scalar: argument one argument two>' } qw(join print warn_list))
}, "delay scalar sub(...)");

$ret = stress_test(contextual_return(1234, 12345, 123456));
my @expect = (1234, 12345, 123456, "one", "two");
is_deeply($ret, {
    scalar => 'two',
    eval   => 'two',
    list   => [@expect],
    warn   => join("", @expect),
    map({ $_ => join "", "<", @expect, ">" } qw(join print warn_list))
}, "delay sub(...)");


$ret = stress_test(scalar map("scalar map: $_", 1..5), 2);
is_deeply($ret, {
    map({ $_ => 5 } qw(scalar warn eval)),
    list   => [5],
    map({ $_ => join "", "<", 5, ">" } qw(join print warn_list))
}, "delay scalar map");

$ret = stress_test(map("map: $_", 1..5), 2);
@expect = map("map: $_", 1..5);
is_deeply($ret, {
    scalar => 'map: 5',
    eval   => 'map: 5',
    list   => [@expect],
    warn   => join("", @expect),
    map({ $_ => join "", "<", @expect, ">" } qw(join print warn_list))
}, "delay map");

$ret = stress_test("dollar under: <$_>");
my $expect = "dollar under: <set in stress_test>";
is_deeply($ret, {
    map({ $_ => $expect } qw(scalar warn eval)),
    list   => [$expect],
    map({ $_ => join "", "<", $expect, ">" } qw(join print warn_list))
}, "delay qq{\$_}");

$ret = stress_test(do { my $x = sub { shift }->("from do"); $x }, 4);
is_deeply($ret, {
    map({ $_ => 'from do' } qw(scalar warn eval)),
    list   => ['from do'],
    map({ $_ => join "", "<", 'from do', ">" } qw(join print warn_list))
}, "delay do {...}");

sub return_a_list { qw(a 1 b 2) }
my @ret = run({ return_a_list });
is_deeply(\@ret, [{qw(a 1 b 2)}] );

our $where;
sub passover {
    my $delay = shift;
    $where .= 1;
    return takes_delayed($delay);
}
sub takes_delayed {
    my $d = shift;
    $where .= 2;
    force($d);
    sub { force($d) }->();
    if ( $] >= 5.010 ) {
        no if $] >= 5.018, warnings => "experimental::lexical_topic";
        eval q{ my    $_ = 4; force($d) };
        eval q{ use feature 'state'; state $_ = 5; force($d) };
    }
    else {
        $where .= 33;
    }
    sub { our   $_ = 6; force($d) }->();
    sub { our $_; local $_ = 7; force($d) }->();
    $where .= 8;
};
use Params::Lazy passover => '^';

{
    $_ = 3;
    passover($where .= $_);
}
is($where, 123333678, "can pass delayed arguments to other subs and use them");

sub return_delayed { return shift }
use Params::Lazy return_delayed => '^;@';

my $delay = "";
my $d = do {
    my $foo = "_1_";
    my $f = return_delayed($delay .= $foo);
    is($delay, "", "sanity test");
    force($f);
    is($delay, "_1_", "can return a delayed argument and use it");
    force($f);
    is($delay, "_1__1_", "..multiple times");

    sub { force $f }->();
    is($delay, "_1__1__1_", "can return a delayed argument and then use it inside a different sub");
    $f;
};

{
    my $w = "";
    local $SIG{__WARN__} = sub { $w .= shift };
    force($d);
    is($delay, "_1__1__1_", "Delayed arguments are not closures");
    my $re = qr/Use of uninitialized value(?: \$foo)? in concatenation/;
    like(
        $w,
        $re,
        "Warns if a delayed argument used a variable that went out of scope"
    );
    
    $w = "";
    sub { force $d }->();
    is($delay, "_1__1__1_", "");
    like($w, $re,  'Doesn\'t crash for my $f = do { return_delayed ... }; sub { force $f }->(), gives an uninit warning');
}

=begin Crashes, unsupported
my $count = 10;
my $delayed = do {
    my $lex = 1;
    my $delayed = return_delayed $count += $lex;
    $delayed;
};

sub { force $delayed }->();
=cut

use lib 't/lib';
if ($] >= 5.010) {
    require lexical_topic_tests;
}

use Params::Lazy passover_amp => q(^);
sub passover_amp {
   my @ret = (&run, &run, &run);
   return @ret;
}

my $f = 1;
@ret  = passover_amp $f++;
is_deeply(\@ret, [1, 2, 3], "can delay an argument and then pass it to another delayer by using &foo");
is($f, 4, "..and it uses the right variable");

# TODO the above but with run(0, $_[0]) instead of &run

use Params::Lazy delay => q(^);
sub delay { return force shift }

my $fus = 10;
my $fus_sub = delay sub { "fus: $fus" };
is(
    $fus_sub->(),
   "fus: 10",
   "can delay coderef creation outside of a sub"
);

my $lex_for_eval = "the eval should see me";
my $fus_eval_sub = delay sub { eval q{"<$lex_for_eval>"} };
is(
    $fus_eval_sub->(),
   "<$lex_for_eval>",
   "can delay a coderef that uses eval STRING outside of a sub"
);

    
my $fus_const_sub = delay sub () { $fus };
is(
    $fus_const_sub->(),
   10,
   "can delay a constant coderef creation outside of a sub"
);

SKIP: {
    skip("Crashes in 5.8", 3) if $] < 5.010;
sub {
    my $fus_sub = delay sub { "fus: $fus" };
    is(
        $fus_sub->(),
        "fus: 10",
        "can delay coderef creation"
    );

    my $fus_const_sub = delay sub () { $fus };
    is(
        $fus_const_sub->(),
        10,
        "can delay a constant coderef creation"
    );

    my $fus_eval_sub = delay sub { eval q{"<$lex_for_eval>"} };
    is(
        $fus_eval_sub->(),
        "<$lex_for_eval>",
        "can delay a coderef that uses eval STRING inside of a sub"
    );
    
    $fus_sub = delay do { eval {die}; sub { "fus: $fus" } };
    is(
        $fus_sub->(),
        "fus: 10",
        'do { eval {die}; sub { $lexical } } works'
    );

    $fus_sub = delay do { () = caller; sub { "fus: $fus" } };
    is(
        $fus_sub->(),
        "fus: 10",
        'do { () = caller; sub { $lexical } } works'
    );

}->();
}


my $s = 'Fus';
sub {
    delay $s .= $_[0];
}->(' Ro Dah');
is($s, "Fus Ro Dah", 'delay $s .= ... works');

{
my $w = '';
local $SIG{__WARN__} = sub { $w .= shift };
$s = 'Tiid';
sub {
    local *_ = [" Klo", " Ul"];
    delay $s .= $_[0];
    delay $s .= $_[1];
}->('');
is($s, "Tiid Klo Ul", 'local *_ = [...]; delay $s .= $_[0] works');
    is($w, '', "..with no warnings");
}

{
    my $w = '';
    local $SIG{__WARN__} = sub { $w .= shift };
    $s = 'unchanged';
    sub {
        local *_ = "test";
        delay $s .= $_[0];
    }->(' ro dah');

    is(
        $s,
       'unchanged',
       'local *_ = "scalar"; delay $s .= $_[0] works'
    );
    like(
        $w,
         qr/Use of uninitialized value in concatenation/,
         "...and it gives the right warning"
    );
    
    SKIP: {
        skip("Not implemented yet", 2);
        sub {
            local *_ = "test";
            delay push @_, 'modifying @_';
            ok(defined *_{ARRAY});
            is_deeply(\@_, ['modifying @_']);
        }->(' ro dah');
    }
}

done_testing;
