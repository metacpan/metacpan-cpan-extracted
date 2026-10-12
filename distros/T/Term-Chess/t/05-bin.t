#!perl
use 5.014;
use strict;
use warnings;
use Test::More;
use Getopt::Long ();
use lib 't/lib';

use Term::Chess;
use Term::Chess::Bot;
use Term::Chess::Test::Handle;

can_ok('Term::Chess', 'run');

sub run {
    my (@argv) = @_;
    my $stdin = ref $argv[0] eq 'ARRAY' ? shift @argv : ['quit'];
    my ($out, $err) = ('', '');
    open my $o, '>', \$out or die $!;
    open my $e, '>', \$err or die $!;
    $o->autoflush(1);
    $e->autoflush(1);
    my $in = Term::Chess::Test::Handle->reader(@$stdin);
    my $status = do {
        local *STDOUT = $o;                          ## no critic
        local *STDERR = $e;                          ## no critic
        local *STDIN  = $in->fh;                     ## no critic
        Term::Chess->run(@argv);
    };
    return { status => $status, out => $out, err => $err };
}

subtest '--help is status 0 and carries the exit legend' => sub {
    my $r = run('--help');
    is $r->{status}, 0, 'status 0';
    like $r->{out}, qr/usage: chess/, 'usage on stdout, naming chess and not $0';
    is $r->{err}, '', '  and nothing on stderr';
    like $r->{out}, qr/exit status:/, 'the legend is there';
    like $r->{out}, qr/0\s+you won, or the game drew/, '  0 is a win or a draw';
    like $r->{out}, qr/1\s+you lost/, '  1 is a loss';
    like $r->{out}, qr/2\s+a bad option/, '  2 is a bad option';
    for my $opt (qw(--level --white --seat --seed --fen --moves --size --ascii --ansi --pick --help)) {
        like $r->{out}, qr/\Q$opt\E/, "  and $opt is documented";
    }
    unlike $r->{out}, qr/\$0|usage: game/, '  and it is not named after $0 or the launcher';
};

subtest 'a bad option is status 2, on stderr, and never status 0' => sub {
    my $r = run('--no-such-option');
    is $r->{status}, 2, 'status 2';
    like $r->{err}, qr/chess: Unknown option/, 'the reason, prefixed with the program name';
    like $r->{err}, qr/usage: chess/, '  and the usage, on stderr';
    is $r->{out}, '', '  with nothing on stdout';
    my $word = run('leftover');
    is $word->{status}, 2, 'a leftover word is status 2';
    like $word->{err}, qr/not an option: leftover/, '  and is named';
    for my $bad (['--white', 'p3'], ['--seat', 'white']) {
        my $x = run(@$bad);
        is $x->{status}, 2, "@$bad is refused";
        like $x->{err}, qr/takes p1 or p2/, '  saying what it takes';
    }
};

subtest 'colour and the picker can both be turned OFF from the command line' => sub {
    for my $off (qw(--no-ansi --noansi --no-pick --nopick)) {
        my $r = run($off);
        is $r->{status}, 0, "$off is taken";
        is $r->{err}, '', '  and says nothing on stderr';
    }
    my $plain = run('--no-ansi');
    unlike $plain->{out}, qr/\e\[/, '--no-ansi draws no escapes';
    {
        local %ENV = %ENV;
        delete $ENV{NO_COLOR};
        my $painted = run('--ansi');
        like $painted->{out}, qr/\e\[/, '--ansi draws them';
        local $ENV{NO_COLOR} = '0';
        my $forbidden = run('--ansi');
        unlike $forbidden->{out}, qr/\e\[/, '  but NO_COLOR, by presence, beats --ansi';
    }
    my $typed = run('--no-pick');
    like $typed->{out}, qr/a move is coordinates like e2e4/, '--no-pick offers the typed prompt';
};

subtest '--ascii draws no wide characters at all' => sub {
    my $r = run('--ascii', '--no-ansi');
    is $r->{status}, 0, 'status 0';
    unlike $r->{out}, qr/[^\x00-\x7F]/, 'every byte is ASCII';
    like $r->{out}, qr/R\s+N\s+B\s+Q\s+K\s+B\s+N\s+R/, '  and rank 1 is the FEN letters';
};

subtest '--white, --seat and --seed shape the game' => sub {
    my $black = run(['quit'], '--seat', 'p2', '--no-ansi', '--level', '0');
    is $black->{status}, 0, 'playing Black and quitting is 0';
    like $black->{out}, qr/the bot plays/, '  the bot, as White, moved first';
    like $black->{out}, qr/^1 /m, '  and the board is drawn from Black\'s side, rank 1 at the top';
    my $white_is_p2 = run(['quit'], '--white', 'p2', '--no-ansi', '--level', '0');
    like $white_is_p2->{out}, qr/the bot plays/, '--white p2 with seat p1 also means the bot moves first';
    my $a = run(['e2e4', 'quit'], '--seed', 'alpha', '--level', '0', '--no-ansi');
    my $b = run(['e2e4', 'quit'], '--seed', 'alpha', '--level', '0', '--no-ansi');
    is $a->{out}, $b->{out}, 'the same seed and level is the same game';
};

subtest 'a refused --fen and a refused --moves are both status 2' => sub {
    my $fen = run('--fen', 'not a fen');
    is $fen->{status}, 2, 'a FEN Plisco refuses is 2';
    like $fen->{err}, qr/could not start a game: Plisco refused the position/, '  naming Plisco';
    my $mv = run('--moves', 'e2e4 e7e5 Nf3 zz');
    is $mv->{status}, 2, 'a move the game refuses is 2';
    like $mv->{err}, qr/--moves refused at 'zz': bad_move/, '  naming the move and the code';
    my $ok = run(['quit'], '--moves', 'e4, e5, Nf3, Nc6', '--no-ansi');
    is $ok->{status}, 0, 'and four legal ones, SAN with commas, are played';
    like $ok->{out}, qr/white to move/, '  leaving white to move';
    my $pos = run(['quit'], '--fen', '4k3/8/8/8/8/8/8/4K3 w - - 0 1');
    is $pos->{status}, 0, 'a FEN already drawn returns 0 at once';
    like $pos->{out}, qr/drawn: neither side can mate/, '  with its verdict';
};

subtest 'a game already lost is status 1, a win 0' => sub {
    my $lost = run('--fen', 'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3', '--seat', 'p1');
    is $lost->{status}, 1, 'the seat that is mated exits 1';
    like $lost->{out}, qr/you lost: checkmate/, '  and is told so';
    my $won = run(['a1a8'], '--fen', '6k1/5ppp/8/8/8/8/5PPP/R5K1 w - - 0 1', '--no-ansi');
    is $won->{status}, 0, 'mating exits 0';
    like $won->{out}, qr/you won: checkmate/, '  and says so';
    my $resign = run(['resign'], '--no-ansi');
    is $resign->{status}, 1, 'resigning exits 1';
};

subtest '--level takes a rung index or a budget outright' => sub {
    my @ladder = Term::Chess::Bot->ladder;
    is run('--level', '0')->{status}, 0, 'rung 0 starts';
    is run('--level', '2500')->{status}, 0, 'and so does a raw budget';
    my $neg = run('--level', '-1');
    is $neg->{status}, 2, 'a negative level is refused';
    cmp_ok scalar @ladder, '<', $ladder[0], 'there really is a gap between the last rung and the first budget';
    for my $dead (scalar @ladder, $ladder[0] - 1) {
        my $r = run('--level', $dead);
        is $r->{status}, 2, "--level $dead is refused rather than guessed at";
        like $r->{err}, qr/neither a rung nor a budget/, '  and said which it needs';
        like $r->{err}, qr/\b0 to @{[ $#ladder ]}\b/, '  naming the rung range';
        like $r->{err}, qr/\b$ladder[0] nodes or more\b/, '  and the budget floor';
    }
    is run('--level', $#ladder)->{status}, 0, 'the last rung is still a rung';
    is run('--level', $ladder[0])->{status}, 0, 'and the floor is still a budget';
    my $seen;
    {
        no warnings 'redefine';
        local *Term::Chess::Bot::choose = sub { $seen = $Term::Chess::Bot::LEVEL; 'e7e5' };
        run(['e2e4', 'quit'], '--level', '3', '--no-ansi');
    }
    is $seen, $ladder[3], 'rung 3 reaches the bot as the top budget';
};

subtest '--size draws the board at 1, 2 or 3, and refuses the rest' => sub {
    for my $size (1, 2, 3) {
        my $r = run('--size', $size, '--no-ansi', '--ascii');
        is $r->{status}, 0, "--size $size is taken";
        my ($rank8) = grep { /\A8 / } split /\n/, $r->{out};
        is length($rank8), 16 * $size + 11, "  and rank 8 is @{[ 16 * $size + 11 ]} columns";
    }
    my $plain = run('--no-ansi', '--ascii');
    my ($rank8) = grep { /\A8 / } split /\n/, $plain->{out};
    is length($rank8), 43, 'the default is 2';
    for my $bad (4, 0, 'big') {
        my $r = run('--size', $bad);
        is $r->{status}, 2, "--size $bad is refused";
        like $r->{err}, qr/--size takes 1, 2 or 3|invalid for option size/, '  saying what it takes';
    }
};

subtest 'run leaves the process as it found it' => sub {
    my $getopt = Getopt::Long::Configure('default');
    Getopt::Long::Configure($getopt);
    my @layers = PerlIO::get_layers(\*STDOUT);
    my @sig = @SIG{qw(INT TERM HUP)};
    run('--help');
    run('--no-such-option');
    run(['e2e4', 'quit'], '--level', '0', '--no-ansi');
    my $after = Getopt::Long::Configure('default');
    Getopt::Long::Configure($after);
    is_deeply [ @{$after}[1 .. $#{$after}] ], [ @{$getopt}[1 .. $#{$getopt}] ], 'the Getopt configuration is as it was';
    is_deeply [ PerlIO::get_layers(\*STDOUT) ], \@layers, 'STDOUT has the layers it had';
    is_deeply [ @SIG{qw(INT TERM HUP)} ], \@sig, 'and the handlers are as they were';
    is $Term::Chess::Bot::LEVEL, undef, 'and LEVEL is unset';
};

subtest 'a signal re-raises itself after leaving raw mode, and never exits' => sub {
    plan skip_all => 'no fork on this perl' if $^O eq 'MSWin32';
    my $handler;
    {
        no warnings 'redefine';
        local *Term::Chess::start = sub { $handler = $SIG{INT}; 0 };
        run('--no-ansi');
    }
    is ref $handler, 'CODE', 'run installed a handler for INT while it played';
    my $pid = fork();
    die "fork: $!" unless defined $pid;
    if (!$pid) {
        $handler->('INT');
        exit 99;
    }
    waitpid $pid, 0;
    my ($signal, $code) = ($? & 127, $? >> 8);
    is $signal, 2, 'calling it killed the child with SIGINT: the handler re-raised';
    isnt $code, 130, '  and did not exit 130 in its place';
    isnt $code, 99, '  nor return to its caller';
};

subtest 'the script is two lines and the POD names the exit statuses' => sub {
    open my $fh, '<', 'bin/chess' or die $!;
    my $src = do { local $/; <$fh> };
    close $fh;
    my ($code) = split /^__END__$/m, $src;
    my @lines = grep { /\S/ && !/^\s*#/ && !/^\s*(?:use|our)\b/ } split /\n/, $code;
    is_deeply \@lines, ['exit Term::Chess->run(@ARGV);'], 'the only statement is the exit';
    like $src, qr/=head1 EXIT STATUS/, 'the POD has the legend';
};

done_testing;
