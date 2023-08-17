
# purpose: tests Mnet::Expect::Cli command method prompt functionality

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 6;

# init perl code for these tests
my $perl = <<'perl-eof';
    use warnings;
    use strict;
    use Mnet::Expect::Cli;
    use Mnet::Log qw( DEBUG INFO );
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    my $opts = Mnet::Opts::Cli->new;
    DEBUG("spawn script: $_") foreach (split/\n/, `cat $ENV{EXPECT} 2>&1`);
    my $expect = Mnet::Expect::Cli->new({
        paging_key  => "\n",
        paging_re   => "MORE(\\r?\\n)",
        spawn       => $ENV{EXPECT},
        timeout     => 2,
    });
perl-eof

# command method prompt response text
Mnet::T::test_perl({
    name    => 'command method prompt response text',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            printf "question"; read INPUT
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test", undef, [ question => "-\r" ]) . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "question-\noutput",
    debug   => '--debug',
});

# command method prompt response undef
Mnet::T::test_perl({
    name    => 'command method prompt response undef',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            printf "question"; read INPUT
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test", undef, [ question => undef ]) . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "question",
    debug   => '--debug',
});

# command method prompt code response text
Mnet::T::test_perl({
    name    => 'command method prompt code response text',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            echo preamble
            printf "question"; read INPUT
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test", undef, [ question => sub {
            shift; return "-\r" if shift =~ /preamble/;
        }]) . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "preamble\nquestion-\noutput",
    debug   => '--debug',
});

# command method prompt code response undef
Mnet::T::test_perl({
    name    => 'command method prompt code response undef',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            echo preamble
            printf "question"; read INPUT
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test", undef, [ question => sub {
            shift; return undef if shift =~ /preamble/;
        }]) . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "preamble\nquestion",
    debug   => '--debug',
});

# command method output with extra prompt
Mnet::T::test_perl({
    name    => 'command method output with extra prompt',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            echo prompt%
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "prompt%\noutput",
    debug   => '--debug',
});

# command method with multiple prompts
Mnet::T::test_perl({
    name    => 'command method with multiple prompts',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            printf "one";      read INPUT
            printf "two";      read INPUT
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test", undef, [ one => "1\r", two => "2\r" ]);
        print "\n";
    ',
    filter  => 'grep -v "Mnet::Log - started" | grep -v "Mnet::Log finished"',
    expect  => "one1\ntwo2\noutput",
    debug   => '--debug',
});

# finished
exit;
