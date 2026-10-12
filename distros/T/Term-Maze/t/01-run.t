use strict;
use warnings;
use Test::More;

use Term::Maze;

can_ok('Term::Maze', 'run');

my @modes;
local $Term::Maze::READMODE = sub { push @modes, $_[0] };

sub run {
    my ($keys, @argv) = @_;
    my @keys = @$keys;
    local $Term::Maze::READER = sub { shift @keys };
    my ($out, $err) = ('', '');
    open my $o, '>', \$out or die $!;
    open my $e, '>', \$err or die $!;
    @modes = ();
    my $status = do {
        local *STDOUT = $o;
        local *STDERR = $e;
        Term::Maze->run(@argv);
    };
    close $o;
    close $e;
    return { status => $status, out => $out, err => $err };
}

subtest '--help is status 0 with the usage on stdout' => sub {
    my $r = run([], '--help');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/usage: maze/, 'usage on stdout');
    like($r->{out}, qr/--width/, '  naming --width');
    like($r->{out}, qr/--height/, '  and --height');
    is($r->{err}, '', '  and nothing on stderr');
    is(scalar @modes, 0, '  and the terminal mode was never touched');
};

subtest 'a bad option is status 2 with the usage on stderr' => sub {
    for my $bad (['--bogus'], ['--width', 'ten'], ['extra'], ['5', '5', '5'],
                 ['--width', '1'], ['1', '5'], ['5', '0']) {
        my $r = run([], @$bad);
        is($r->{status}, 2, "@$bad is status 2");
        like($r->{err}, qr/usage: maze/, '  usage on stderr');
        is($r->{out}, '', '  nothing on stdout');
    }
    is(scalar @modes, 0, 'and the terminal mode was never touched');
};

subtest 'two integers are width and height, and q quits with the mode restored' => sub {
    my $r = run(['q'], 5, 5);
    is($r->{status}, 0, 'run(5, 5) then q is status 0');
    is($modes[0], 'cbreak', 'cbreak on entry');
    is($Term::Maze::MODE, 0, 'and 0 is the last mode set');
    is($modes[-1], 0, '  which is what the mode seam saw last');
    like($r->{out}, qr/Use WASD or HJKL/, 'the maze was drawn');
    unlike($r->{out}, qr/You win/, '  and quitting is not winning');
};

subtest 'escape quits too, and --width --height are taken' => sub {
    my $r = run(["\e"], '--width', '7', '--height', '5');
    is($r->{status}, 0, 'escape is status 0');
    is($Term::Maze::MODE, 0, 'mode restored');
    (my $plain = $r->{out}) =~ s/\e\[[0-9;]*[A-Za-z]//g;
    my @rows = grep { /^#/ } split /\n/, $plain;
    is(scalar @rows, 5, 'five rows drawn');
    is(length $rows[0], 7, '  of seven columns');
};

subtest 'an arrow key is swallowed and does not quit' => sub {
    my $r = run(["\e", '[', 'C', 'q'], 5, 5);
    is($r->{status}, 0, 'status 0');
    my $draws = () = $r->{out} =~ /Use WASD or HJKL/g;
    is($draws, 1, 'the arrow neither moved nor redrew, and q quit afterwards');
};

subtest 'reaching the exit prints You win! and is status 0' => sub {
    my $r = run(['d', 's', 'x'], 2, 2);
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/You win!/, 'You win!');
    is($Term::Maze::MODE, 0, 'mode restored');
};

subtest 'a die inside the loop still restores the mode' => sub {
    local $Term::Maze::READER = sub { die "boom\n" };
    my ($out, $err) = ('', '');
    open my $o, '>', \$out or die $!;
    @modes = ();
    my $died = do {
        local *STDOUT = $o;
        eval { Term::Maze->run(5, 5) };
        $@;
    };
    is($died, "boom\n", 'the die came through');
    is($Term::Maze::MODE, 0, '  and the mode was restored first');
    is_deeply(\@modes, ['cbreak', 0], '  cbreak then 0');
};

done_testing();
