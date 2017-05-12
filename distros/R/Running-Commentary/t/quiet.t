use 5.014;

use Running::Commentary;
use Test::Effects;

#plan $] >= 5.018 ? (skip_all => 'An apparent bug in Perl 5.18 makes this test always fail')
#                 : (tests    => 8);
plan tests => 8;

my $run_sub             = sub { say "loudly ok" };
my $expected_no_message = "loudly ok\n";
my $message             = '# Loudly';
my $expected_message    = qr/${message}[.]+${expected_no_message}${message}[.]+done/;

# Disable colour to simplify testing output...
run_with -nocolour;

# Should run normally, will see comments fore and aft...
effects_ok { run $message => $run_sub; }
           {
                stdout => $expected_message,
                WITHOUT => 'Term::ANSIColor',
           } => 'With message';

{
    # Now disable descriptions...
    run_with -nomessage;

    effects_ok { my $result = run $message => $run_sub; }
               {
                    stdout => $expected_no_message,
                    WITHOUT => 'Term::ANSIColor',
               } => 'run_with -nomessage';
}

# Should not be -nomessage back out in this scope...
effects_ok { run $message => $run_sub; }
           {
                stdout => $expected_message,
                WITHOUT => 'Term::ANSIColor',
           } => 'Back to message';

# Flag for conditional nomessageness...
my $opt_nomessage = 1;

{
    # Set nomessageness via conditional...
    run_with -nomessage if $opt_nomessage;

    # Will only work if nomessageness set...
    effects_ok { run $message => $run_sub }
               {
                    stdout => $expected_no_message,
                    WITHOUT => 'Term::ANSIColor',
               } => 'Optional run_with -nomessage';
}

# Should not be -nomessage back out in this scope...
effects_ok { run $message => sub { say "loudly ok" } }
           {
                stdout => $expected_message,
                WITHOUT => 'Term::ANSIColor',
           } => 'Back to message again';

{
    # Fail to set nomessageness, via conditional...
    run_with -nomessage if !$opt_nomessage;

    # Will only work if nomessageness not set...
    effects_ok { run $message => sub { say "loudly ok" } }
            {
                    stdout => $expected_message,
                    WITHOUT => 'Term::ANSIColor',
            } => 'Not with optional -nomessage';

    # Explicit -nomessage overrides...
    effects_ok { run -nomessage, $message => sub { say "loudly ok" } }
            {
                    stdout => "loudly ok\n",
                    WITHOUT => 'Term::ANSIColor',
            } => 'Explicit override';

    # But explicit -nomessage not permanent...
    effects_ok { run $message => sub { say "loudly ok" } }
            {
                    stdout => $expected_message,
                    WITHOUT => 'Term::ANSIColor',
            } => 'Back to not with optional -nomessage';
}


