#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Term::Chess::Game;
use Term::Chess::Error;
use Term::Chess::Bot;
use Term::Chess::Watcher;
use Term::Chess::Test::Handle;

# THE PURITY TEST. STDOUT, STDERR and STDIN are replaced by a handle that DIES
# on every operation, and a whole game is played through the facade and the
# bot. If anything in Term::Chess::Game, ::Error, ::Bot or ::Watcher reaches
# for a filehandle, or Plisco does underneath them, the die names this file.
# Term::Chess itself is not in the list: printing is its job.

my $deaf = Term::Chess::Test::Handle->deaf;

{
    my $ok = do {
        local *STDOUT = $deaf->fh;                   ## no critic
        local *STDERR = $deaf->fh;                   ## no critic
        eval { pass('Test::More still reports with STDOUT replaced'); 1 };
    };
    ok($ok, '  and did not die doing it')
        or diag("  if this failed the whole file proves nothing: $@");
}

sub silently (&) {
    my ($code) = @_;
    my @r;
    my $ok = eval {
        local *STDOUT = $deaf->fh;                   ## no critic
        local *STDERR = $deaf->fh;                   ## no critic
        local *STDIN  = $deaf->fh;                   ## no critic
        local $SIG{__WARN__} = sub { die "something WARNED: $_[0]" };
        @r = $code->();
        1;
    };
    return ($ok, $@, @r);
}

subtest 'a whole game, played with every handle deaf' => sub {
    my ($ok, $err, $plies, $status) = silently {
        local $Term::Chess::Bot::LEVEL = 2_000;
        my $g = Term::Chess::Game->new(seed => substr('no-io' . ('.' x 32), 0, 32), white => 'p1');
        my $bot = $g->bot;
        my $n = 0;
        while ($g->status eq 'active' && $n < 60) {
            my $mv = $bot->choose($g, $g->turn);
            last unless defined $mv;
            my $refusal = $g->play($mv);
            die "the bot offered $mv and it was refused: " . $refusal->code if $refusal;
            $n++;
        }
        return ($n, $g->status);
    };
    ok($ok, 'sixty plies of bot against bot, and nothing printed or read')
        or diag("  $err");
    cmp_ok($plies, '>', 0, "  ($plies plies played, game $status)");
};

subtest 'the noisy paths are silent too' => sub {
    my ($ok, $err) = silently {
        my $g = Term::Chess::Game->new(seed => 'q' x 32, white => 'p1');
        $g->play($_) for qw(zz99 a8 a7a8 e7e5 e3e4 e2e5 e2-e4), '', 'O-O-O';
        $g->play('e2e4');
        $g->replay([ qw(e2e4 e7e5 g1f3) ]);
        Term::Chess::Game->replay(seed => 'q' x 32, moves => [ qw(e2e4 e7e5) ]);
        Term::Chess::Game->replay('an', 'odd', 'list');
        $g->result;
        $g->signatures;
        $g->legal;
        $g->san_log;
        $g->resign('p1');
        $g->play('e7e5');
        eval { Term::Chess::Game->new(seed => 'q' x 32, position => 'rubbish') };
        eval { Term::Chess::Game->new(seed => 'short') };
        my $b = Term::Chess::Game->new(seed => 'b' x 32, position => '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1');
        Term::Chess::Bot->level_for('b' x 32);
        { local $Term::Chess::Bot::LEVEL = 2_000; Term::Chess::Bot->choose($b, 'p1') }
        Term::Chess::Bot->hint($b, 'p1');
        Term::Chess::Bot->choose($b, 'p2');
        Term::Chess::Watcher->new(5)->check({ nodes => 10 });
        Term::Chess::Error->message_for('in_check');
        Term::Chess::Error->known('nonsense');
        Term::Chess::Error->throw('in_check')->message;
        return 1;
    };
    ok($ok, 'refusals, replay, resign, a bad FEN, the bot at the top rung, the watcher') or diag("  $err");
};

subtest 'and the deaf handle is not vacuous' => sub {
    my ($ok, $err) = silently { print "this must die\n"; 1 };
    ok(!$ok, 'a print dies');
    like($err, qr/something PRINTED/, '  and says so');

    my ($ok2, $err2) = silently { my $x = <STDIN>; 1 };
    ok(!$ok2, 'a read dies');
    like($err2, qr/READ A LINE/, '  and says so');

    my ($ok3, $err3) = silently { warn "noisy\n"; 1 };
    ok(!$ok3, 'a warn dies');
    like($err3, qr/something WARNED/, '  and says so');

    my ($ok4, $err4) = silently { printf "%s\n", 'x'; 1 };
    ok(!$ok4, 'a printf dies');
    like($err4, qr/PRINTF/, '  and says so');
};

done_testing();
