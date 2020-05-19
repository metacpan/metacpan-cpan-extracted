
# purpose: tests Mnet::Expect functionality

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 5;

# init perl code for these tests
my $perl = <<'perl-eof';
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    use Mnet::Log qw( DEBUG );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Opts::Set::Quiet;
    Mnet::Opts::Cli::define({ getopt => "spawn=s" });
    Mnet::Opts::Cli::define({ getopt => "log-expect=s" });
    my $opts = Mnet::Opts::Cli->new;
    delete $opts->{log_expect} if not defined $opts->{log_expect};
    $opts->{timeout} = 2;
    my $expect = Mnet::Expect->new($opts) or die "expect undef";
    $expect->expect->expect(1, "-re", ".-test");
    $expect->close;
perl-eof

# spawn error
Mnet::T::test_perl({
    name    => 'spawn error',
    perl    => $perl,
    args    => '--spawn error_nonexistant_jhsfdoucsmslju',
    filter  => 'sed "s/spawn error.*/spawn error/"',
    expect  => <<'    expect-eof',
        DIE - Mnet::Expect spawn error
    expect-eof
    debug   => '--debug --noquiet',
});

# spawn and close
#   some cpan testers needed to grep out expect 'log hex' entries  to pass
#       meybe the session close took effect before last eol received?
Mnet::T::test_perl({
    name    => 'spawn and close',
    perl    => $perl,
    args    => '--noquiet --debug --spawn "echo x-test"',
    filter  => 'grep -e "--- - Mnet::Log" -e "log txt" -e confirmed',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - Mnet::Expect log txt: x-test
        dbg - Mnet::Expect close finished, hard_close confirmed
        --- - Mnet::Log finished, no errors
    expect-eof
});

# log_expect debug
Mnet::T::test_perl({
    name    => 'log_expect debug',
    perl    => $perl,
    args    => '--noquiet --debug --spawn "echo x-test" --log-expect debug',
    filter  => 'grep -e "--- - Mnet::Log" -e "log txt" -e confirmed',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        dbg - Mnet::Expect log txt: x-test
        dbg - Mnet::Expect close finished, hard_close confirmed
        --- - Mnet::Log finished, no errors
    expect-eof
});

# log_expect info
Mnet::T::test_perl({
    name    => 'log_expect info',
    perl    => $perl,
    args    => '--noquiet --debug --spawn "echo x-test" --log-expect info',
    filter  => 'grep -e "--- - Mnet::Log" -e ^inf | grep -v Mnet::Opts::Cli',
    expect  => <<'    expect-eof',
        --- - Mnet::Log - started
        inf - Mnet::Expect log txt: x-test
        --- - Mnet::Log finished, no errors
    expect-eof
});


# log_expect invalid
#   notice level logging is reserved for internal use
Mnet::T::test_perl({
    name    => 'log_expect info',
    perl    => $perl,
    args    => '--noquiet --debug --spawn "echo x-test" --log-expect notice',
    filter  => 'grep ERR | sed "s/invalid.*/invalid/"',
    expect  => <<'    expect-eof',
        ERR - Carp perl die, log_expect invalid
    expect-eof
});

# finished
exit;

