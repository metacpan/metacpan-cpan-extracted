use 5.014;

use Running::Commentary;
use Test::Effects;

plan tests => 8;

my $run_sub           = sub { say "loudly ok" };
my $expected_text     = "loudly ok\n";
my $expected_message  = '# Loudly';
my $expected_output   = qr/${expected_message}[.]+${expected_text}${expected_message}[.]+done/;
my $expected_nooutput = qr/${expected_message}[.]+done/;


# Disable colour to simplify testing output...
run_with -nocolour;

# Should run normally, will see comments fore and aft...
effects_ok { run $expected_message => $run_sub; }
           { 
                stdout => $expected_output,
           };


{
    # Now disable descriptions...
    run_with -nooutput;

    effects_ok { run $expected_message => $run_sub; }
               {
                    stdout => $expected_nooutput,
               };
}

# Should not be -nooutput back out in this scope...
effects_ok { run $expected_message => $run_sub; }
           { 
                stdout => $expected_output,
           };

# Flag for conditional silent...
my $opt_silent = 1;

{
    # Set silent via conditional...
    run_with -nooutput if $opt_silent;

    # Will only work if silent set...
    effects_ok { run $expected_message => $run_sub }
               {
                    stdout => $expected_nooutput,
               };
}

# Should not be -nooutput back out in this scope...
effects_ok { run $expected_message => sub { say "loudly ok" } }
           { 
                stdout => $expected_output,
           };

{
    # Fail to set silent, via conditional...
    run_with -nooutput if !$opt_silent;

    # Will only work if silent not set...
    effects_ok { run $expected_message => sub { say "loudly ok" } }
            { 
                    stdout => $expected_output,
            };

    # Explicit -nooutput overrides...
    effects_ok { run -nooutput, $expected_message => sub { say "loudly ok" } }
            {
                    stdout => $expected_nooutput,
            };

    # But explicit -nooutput not permanent...
    effects_ok { run $expected_message => sub { say "loudly ok" } }
            { 
                    stdout => $expected_output,
            };
}


