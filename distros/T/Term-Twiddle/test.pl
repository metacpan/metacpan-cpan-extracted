use Test;
use vars qw( $tests );
BEGIN { $tests = 13; plan tests => $tests };
use Term::Twiddle;
ok(1);

my $sp;
$sp = new Term::Twiddle;

unless( _is_interactive() and
        get_ans("Do you want to run the (brief but interactive) tests?", 'y') ) {
    for (1..$tests-1) { ok(1) }
    exit;
}

## basic spin
printw("going to spin for 1 second or so ==> ");
$sp = new Term::Twiddle;
$sp->start();
system('sleep', '1');
$sp->stop();
ok( get_ans("Did it work?", "y") );

## random spin
printw("going to spin a varying speeds for a few seconds ==> ");
$sp->random;
$sp->start;
system('sleep', '3');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## new thingy
printw("going to show a pair of eyes blinking ==> ");
$sp->random(0);
$sp->rate(0.175);
$sp->thingy( ["00", "--"] );
$sp->start;
system('sleep', '2');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## new thingy
printw("going to show a rolling ball ==> ");
$sp->rate(0.075);
$sp->thingy( [
        '|o_____|', 
        '|_o____|', 
        '|__o___|', 
        '|___o__|', 
        '|____o_|', 
        '|_____o|', 
        '|____o_|',
        '|___o__|',
        '|__o___|',
        '|_o____|',
        '|o_____|',
        ] );
$sp->start;
system('sleep', '2');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## slow constructor
printw("trying a new constructor (spinner should be slow) ==> ");
$sp = new Term::Twiddle({rate => 0.275});
$sp->start;
system('sleep', '3');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## moderate constructor
printw("trying a new constructor (spinner should be moderate) ==> ");
$sp = new Term::Twiddle({rate => 0.075});
$sp->start;
system('sleep', '3');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## fast constructor
printw("trying a new constructor (spinner should be fast) ==> ");
$sp = new Term::Twiddle({rate => 0.015});
$sp->start;
system('sleep', '3');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## random constructor
printw("trying a new constructor (spinner should be pretty random) ==> ");
$sp = new Term::Twiddle({probability => 70, rate => 0.075});
$sp->start;
system('sleep', '3');
$sp->stop;
ok( get_ans("Did it work?", "y") );

## swishing object
printw("trying a new constructor (should be a swishing object) ==>\n");
$sp = new Term::Twiddle({type => 'swish'});
$sp->start;
system('sleep', '4');
$sp->stop;
ok( get_ans("\nDid it work?", "y") );

## bouncy ball
printw("trying a new constructor (should be a bouncing ball) ==>\n");
$sp = new Term::Twiddle({type => 'bounce'});
$sp->start;
system('sleep', '5');
$sp->stop;
ok( get_ans("\nDid it work?", "y") );

printw("trying a new constructor (should be another, shorter bouncing ball) ==>\n");
$sp = new Term::Twiddle();
$sp->type('bounce');
$sp->width($sp->width()/2);
$sp->start;
system('sleep', '5');
$sp->stop;
ok( get_ans("\nDid it work?", "y") );

## out of scope
{
    printw("testing destructor (spinner should stop after 2 sec) ==> ");
    my $tw = new Term::Twiddle({rate => 0.1});
    $tw->start;
    system('sleep', '2');
}
ok( get_ans("Did it work?", "y") );

exit;

## print and wait a sec
sub printw {
    my $msg = shift;
    print STDERR $msg;
    select(undef, undef, undef, 0.5);
}

sub get_ans {
    my $query   = shift;
    my $default = shift || 'y';
    my $ans     = shift || $default;

    print STDERR "$query [$ans]: ";
    chomp( $ans = <STDIN> );
    $ans = ( $ans ? $ans : $default );

    return $ans =~ /^$default/i;
}

# scottw: copied (also without comments) from IO::Prompt::Tiny
# Copied (without comments) from IO::Interactive::Tiny by Daniel Muey,
# based on IO::Interactive by Damian Conway and brian d foy
sub _is_interactive {
  my ($out_handle) = (@_, select);
  return 0 if not -t $out_handle;
  if ( tied(*ARGV) or defined(fileno(ARGV)) ) {
    return -t *STDIN if defined $ARGV && $ARGV eq '-';
    return @ARGV>0 && $ARGV[0] eq '-' && -t *STDIN if eof *ARGV;
    return -t *ARGV;
}
  else {
    return -t *STDIN;
}
}
