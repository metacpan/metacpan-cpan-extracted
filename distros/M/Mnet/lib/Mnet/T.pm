package Mnet::T;

# purpose: functions for use in Mnet distribution .t test scripts

# required modules
use warnings;
use strict;
use Carp;
use Test::More;



sub test_perl {

# $result = Mnet::T::test_perl(\%specs)
# purpose: test w/pre/perl/post/filter/expect/debug, for mnet .t scripts
# \%specs: input test specification hash reference, see below
# $result: true if test passed
#
#   $specs {
#       name    => $test_name,   # test name used in Test::More::is call
#       pre     => $sh_code,     # shell code to execute before perl code
#       perl    => $perl_code,   # perl code piped to perl interpretor
#       args    => $perl_args,   # passed to perl code
#       post    => $sh_code',    # shell code to execute after perl code
#       filter  => $sh_command,  # shell code perl output is piped through
#       expect  => $text,        # match with filtered output for pass/fail
#       debug   => $debug_args,  # perl args to re-run test after failure
#   }
#
# note that leading spaces are removed lines of text stored in exect key
# note that debug re-run exports MNET_TEST_PERL_DEBUG=1, even if null
#
#   use Mnet::T qw( test_perl );
#   test_perl({
#       name    => 'test',
#       perl    => <<'    perl-eof',
#           use warnings;
#           use strict;
#           use Mnet::Log;
#           use Mnet::Log::Test;
#           syswrite STDOUT, "extra\n";
#           syswrite STDOUT, "stdout\n";
#       perl-eof
#       filter  => <<'    filter-eof'
#           grep -v Mnet::Opts::Cli \
#           | grep -v extra
#       filter-eof
#       expect  => <<'    expect-eof',
#           --- - Mnet::Log - started
#           stdout
#           --- - Mnet::Log finished with no errors
#       expect-eof
#       debug   => '--debug',
#   });
#
# troubleshoot a single test with: INIT { our $mnet_test_perl = $name_re }

    # read input specs
    my $specs = shift;

    # note test name and caller info
    my $name = $specs->{name};
    my @caller = caller();

    # skip if global mnet_test_perl var is set and test doesn't match
    #   makes it easy to troubleshoot one test in a .t script full of tests
    if ($main::mnet_test_perl and $name !~ /\Q$main::mnet_test_perl\E/) {
        SKIP: { skip("$name (main::mnet_test_perl)", 1); };
        return 1;
    }

    # check for requried input keys
    foreach my $key (qw/ name perl expect /) {
        croak("missing $key key") if not defined $specs->{$key};
    }

    # prepare command for test
    my $command = _test_perl_command($specs);

    # append filter to test command, if one was specified
    #   remove leading and trailing blank lines before shell piping
    if ($specs->{filter}) {
        $specs->{filter} =~ s/(^\s+|\s+$)//mg;
        $command .= "| $specs->{filter}";
    }

    # trim expect text, allows for indents
    #   remove leading spaces on each line, to allow for indents when calling
    #   also remove leading/trailing blank lines
    $specs->{expect} =~ s/^\s+//mg;
    $specs->{expect} =~ s/(^\n+|\n+$)//g;

    # get output from command, remove leading/trailing blank lines
    ( my $output = `$command` ) =~ s/(^\n+|\n+$)//g;

    # compare command output to expected output
    #   added leading cr makes for cleaner Test::More::is output
    my $result = Test::More::is( "\n$output", "\n$specs->{expect}", $name);

    # re-run test with debug args if test failed and debug key was set
    if (not $result) {
        if ($specs->{debug} or $specs->{filter}) {
            my $output = "\npre/perl/post debug for failed '$name'\n";
            $output .= "   called from $caller[1] line $caller[2]\n\n";
            my $command = _test_perl_command($specs, "debug");
            $output .= "COMMAND STARTING\n$command\nCOMMAND FINISHED\n";
            $output .= "UNFILTERED OUTPUT STARTING";
            $output .= `( export MNET_TEST_PERL_DEBUG=1; $command ) 2>&1`;
            $output .= "UNFILTERED OUTPUT FINISHED\n";
            $output .= "FILTER STARTING\n$specs->{filter}\nFILTER FINISHED\n"
                if $specs->{filter};
            syswrite STDERR, "## $_\n" foreach split(/\n/, $output);
            syswrite STDERR, "##\n";
        } else {
            syswrite STDERR, "##    called from $caller[1] line $caller[2]\n\n";
        }
    }

    # finished test_perl function, return result
    return $result;
}



sub _test_perl_command {

# $command = _test_perl_command(\%specs, $debug)
# purpose: prepare pre, perl, and post test command string
# \%specs: hash ref of test specifications, refer to test_perl function
# $debug: optional debug arguments, set when test needs to be re-run after fail
# $command: output command string ready to run with Test::More::is

    # read input specs hash ref and debug flag
    my ($specs, $debug) = (shift, shift);

    # init output command
    my $command = undef;

    # append pre shell code, if specified
    if ($specs->{pre}) {
        $specs->{pre} =~ s/(^\s+|\s+$)//g;
        $command .= "echo 'PRE STARTING';" if $debug;
        $command .= "$specs->{pre};";
        $command .= "echo 'PRE FINISHED'; echo;" if $debug;
    }

    # append perl shell code, if specified
    croak("missing perl key") if not $specs->{perl};
    ( my $perl = $specs->{perl} ) =~ s/'/'"'"'/g;
    $command .= "echo '$perl' | $^X - ";
    $command .= $specs->{args} if defined $specs->{args};
    $command .= " " . $specs->{debug} if $debug and defined $specs->{debug};
    $command .= ";";

    # append post shell code, if specified
    if ($specs->{post}) {
        $specs->{post} =~ s/(^\s+|\s+$)//g;
        $command .= "echo; echo 'POST STARTING';" if $debug;
        $command .= "$specs->{post};";
        $command .= "echo 'POST FINISHED';" if $debug;
    }

    # use subshell and redirection to capture all command output
    $command = "( echo; $command ) 2>&1" if $command;

    # finished _test_per_command, return command
    return $command;
}



# normal end of package
1;

