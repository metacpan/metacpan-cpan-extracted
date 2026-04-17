use strict;
use warnings;
use Test::More;
use Ragnetto::Console qw(:colors :states :shapes clear forecolor backcolor cursor caret position write reset title width height);

# 1. Verify constants
subtest 'Constants' => sub {
    is(RED(), 1, 'RED is 1');
    is(LIGHT_RED(), 9, 'LIGHT_RED is 9');
    is(ON(), 1, 'ON is 1');
    is(BLOCK_BLINK(), 1, 'BLOCK_BLINK is 1');
};

# 2. Helper output
sub capture_stdout {
    my $code = shift;
    my $out;
    {
        local *STDOUT;
        open STDOUT, '>', \$out or die $!;
        $code->();
    }
    return $out;
}

# 3. Test ANSI Sequence
subtest 'ANSI Sequences' => sub {
    is(capture_stdout(sub { clear() }), "\e[2J\e[H", 'clear()');
    is(capture_stdout(sub { forecolor('RED') }), "\e[31m", 'forecolor string');
    is(capture_stdout(sub { backcolor(1) }), "\e[41m", 'backcolor numeric');
    is(capture_stdout(sub { cursor('OFF') }), "\e[?25l", 'cursor off');
    is(capture_stdout(sub { position(10, 5) }), "\e[5;10H", 'position');
};

# 4. Test Dimension
subtest 'Metrics' => sub {
    ok(width() > 0, 'width returns positive');
    ok(height() > 0, 'height returns positive');
};

done_testing();
