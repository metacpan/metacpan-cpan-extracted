#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;
use Cwd qw(abs_path);
use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use FindBin ();

# A second extension, written as a stranger would write one, that knows
# State::Store only through the header ExtUtils::Depends points it at: built
# here, loaded beside State::Store, and made to drive stores through the
# table, stores Perl made and stores it made, side by side with Perl.

plan skip_all => 'Author tests not required for installation' unless $ENV{RELEASE_TESTING};
plan skip_all => 'no compiler recorded in Config' unless $Config{cc} && $Config{make};

my $xt_dir       = abs_path($FindBin::Bin);
my $consumer_src = File::Spec->catdir($xt_dir, 'abi-consumer');
my $dist_root    = abs_path(File::Spec->catdir($xt_dir, File::Spec->updir));
my $blib_arch    = File::Spec->catdir($dist_root, 'blib', 'arch');
my $blib_lib     = File::Spec->catdir($dist_root, 'blib', 'lib');

plan skip_all => "no consumer source at $consumer_src" unless -f File::Spec->catfile($consumer_src, 'Consumer.xs');
plan skip_all => 'State::Store is not built: run make first'
    unless -f File::Spec->catfile($blib_arch, 'State', 'Store', 'Install', 'Files.pm');

my $build = tempdir(CLEANUP => 1);
make_path(File::Spec->catdir($build, 'lib', 'State', 'Store', 'ABI'));
copy(File::Spec->catfile($consumer_src, $_), File::Spec->catfile($build, $_)) or die "copy $_: $!"
    for 'Makefile.PL', 'Consumer.xs';
copy(File::Spec->catfile($consumer_src, qw(lib State Store ABI Consumer.pm)),
     File::Spec->catfile($build, qw(lib State Store ABI Consumer.pm))) or die "copy: $!";

local $ENV{PERL5LIB} = join $Config{path_sep}, $blib_arch, $blib_lib, grep { defined && length } $ENV{PERL5LIB};

my $log = `cd "$build" && "$^X" Makefile.PL 2>&1 && "$Config{make}" 2>&1`;
is($?, 0, 'a consumer that knows only state_store_abi.h configures and builds') or do {
    diag($log);
    done_testing;
    exit;
};
unlike($log, qr/warning:/, 'without a compiler warning') or diag($log);

unshift @INC, File::Spec->catdir($build, 'blib', 'arch'), File::Spec->catdir($build, 'blib', 'lib');
require State::Store;
ok(eval { require State::Store::ABI::Consumer; 1 }, 'and loads beside State::Store') or do { diag($@); done_testing; exit };

my $C = 'State::Store::ABI::Consumer';
no strict 'refs';
my %c = map { ($_ => \&{"${C}::$_"}) } qw(abi_version make is_store get set set_temp swap_add undo counts
    watch unwatch seen seen_store forget_seen cap txn in_txn checkpoint restore drop named limit clear);
use strict 'refs';

my $blocks = State::Store::_live_blocks();
is($c{abi_version}->(), State::Store::_abi_version(), 'it resolved the table, at the version State::Store reports');

# ---- a store made in C, used from Perl, and the other way --------------------
{
    my $st = $c{make}->(5);
    isa_ok($st, 'State::Store', 'a store made in C');
    is($st->current, 5, 'holds what C gave it');
    $st->set(6);
    is($c{get}->($st), 6, 'and C reads what Perl set');
    is($c{set}->($st, 7), 1, 'C sets it: 1, a change');
    is($c{set}->($st, '7'), 0, 'the same value again: 0, no change');
    is($st->current, 7, 'Perl reads what C set');
    is($st->undo_count, 2, 'with a step for each change, whoever made it');
    ok($c{is_store}->($st), 'is_store says yes to it');
    ok(!$c{is_store}->({}), 'and no to a hash');
    ok(!$c{is_store}->(bless \(my $n = 1), 'State::Store'), 'and to a forged store');
    is($c{set}->({}, 1), -2, 'set on something that is not a store is NOTSTORE');
    is($c{get}->([]), undef, 'and get on one is NULL');

    my $p = State::Store->new('perl');
    is($c{get}->($p), 'perl', 'C reads a store Perl made');
    is($c{swap_add}->(State::Store->new(10), 5), 1, 'and swaps one');
}

# ---- the caller's scalar is not changed -------------------------------------
{
    my $st = State::Store->new(0);
    is($c{set_temp}->($st, 'a long enough string to be worth stealing'), 'a long enough string to be worth stealing',
       'a mortal C stores is still whole afterwards');
    is($st->current, 'a long enough string to be worth stealing', 'and the store holds it too');
}

# ---- swap, undo -----------------------------------------------------------------
{
    my $st = State::Store->new(1);
    is($c{swap_add}->($st, 10), 1, 'a swap through the table');
    is($st->current, 11, 'adds');
    is_deeply([$c{undo}->($st, 5)], [0, 1], 'undo(5) with one step: OK, one taken');
    is($st->current, 1, 'back');
    is($c{counts}->($st), 1, 'none to undo, one to redo');
}

# ---- watchers: C and Perl together -----------------------------------------------
{
    my $st = State::Store->new(0);
    my @perl;
    $st->watch(sub { push @perl, "$_[0]>$_[1]" });
    my $id = $c{watch}->($st);
    ok($id, 'a C watcher has an id');
    is($st->watchers, 2, 'and is counted with the Perl one');
    $st->set(1);
    $c{set}->($st, 2);
    $st->undo;
    is($c{seen}->(), '0>1 1>2 2>1', 'the C watcher is told of changes from Perl and from C, and undos');
    is("@perl", '0>1 1>2 2>1', 'as the Perl watcher is');
    is($c{seen_store}->(), $st, 'and is handed the store');
    ok($st->unwatch($id), 'Perl removes the C watcher by its id');
    $c{forget_seen}->();
    $st->set(3);
    is($c{seen}->(), '', 'and it is told nothing more');
    is($c{unwatch}->($st, $id), 0, 'removing it again from C finds nothing');
}

# ---- the validator ---------------------------------------------------------------
{
    my $st = State::Store->new(1);
    is($c{cap}->($st, 10), 0, 'C sets a validator');
    is($st->validator, undef, 'which Perl reads as no sub');
    is($c{set}->($st, 50), -4, 'a value it refuses: REFUSED');
    ok(!eval { $st->set(50); 1 }, 'and Perl is refused by it too');
    like($@, qr/^State::Store::set: the validator refused the value/, 'with the usual words');
    is($st->current, 1, 'and nothing changed');
    $st->validator(sub { 1 });
    is($c{set}->($st, 50), 1, 'a Perl validator replaces it');
    is($c{cap}->($st, 0), 0, 'and C can remove whatever is there');
    is($st->validator, undef, 'leaving none');
}

# ---- transactions ---------------------------------------------------------------
{
    my $st = State::Store->new(0);
    my @told;
    $st->watch(sub { push @told, "$_[0]>$_[1]" });
    is_deeply([$c{txn}->($st, 0, 0, 1, 2, 3)], [0, 0], 'a transaction from C, committed');
    is($st->current, 3, 'keeps what it did');
    is("@told", '0>3', 'as one change');
    is($st->undo_count, 1, 'and one step');
    @told = ();
    is_deeply([$c{txn}->($st, 1, 0, 7, 8)], [0, 0], 'one aborted');
    is($st->current, 3, 'puts everything back');
    is("@told", '', 'and tells nobody');
    my ($rc, $order) = $c{txn}->($st, 0, 1, 9);
    is($order, -6, 'closing the outer one while an inner one is open is ORDER');
    is($rc, 0, 'and both close afterwards, innermost first');
    is($st->current, 9, 'with what they did kept');
    ok(!$st->in_txn, 'and nothing left open');
    my $inside;
    $st->txn(sub { $inside = $c{in_txn}->($st); is(( $c{undo}->($st, 1) )[0], -3, 'undo from C inside a Perl transaction is BUSY') });
    is($inside, 1, 'C sees a Perl transaction as open');
}

# ---- checkpoints ----------------------------------------------------------------
{
    my $st = State::Store->new('a');
    is($c{checkpoint}->($st, 'one'), 0, 'C names a checkpoint');
    ok($st->has_checkpoint('one'), 'Perl sees it');
    $st->set('b')->checkpoint("sm\x{263a}le");
    is_deeply($c{named}->($st), { one => 'a', "sm\x{263a}le" => 'b' }, 'C walks them, a wide name and all');
    is($c{restore}->($st, 'one'), 1, 'C restores one: a change');
    is($st->current, 'a', 'to its value');
    is($c{restore}->($st, 'none'), -5, 'one not there: NOTFOUND');
    is($c{drop}->($st, 'one'), 0, 'C drops one');
    ok(!$st->has_checkpoint('one'), 'and Perl sees it gone');
    is($c{drop}->($st, 'one'), -5, 'twice: NOTFOUND');
}

# ---- history limit, clear ----------------------------------------------------------
{
    my $st = State::Store->new(0);
    $st->set($_) for 1 .. 10;
    is($c{limit}->($st, 4), 4, 'C sets a limit and reads it back');
    is($st->history_limit, 4, 'Perl sees it');
    is($st->undo_count, 4, 'and the past is cut');
    is($c{limit}->($st, -1), -100, 'C removes it');
    is($st->history_limit, undef, 'and Perl sees none');
    is($c{clear}->($st), 0, 'C clears the history');
    is($st->undo_count, 0, 'and it is gone');
}

$c{forget_seen}->();
is(State::Store::_live_blocks(), $blocks, 'when everything it made is gone, nothing is left allocated');

done_testing;
