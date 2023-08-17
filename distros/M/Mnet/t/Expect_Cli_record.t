
# purpose: tests Mnet::Expect::Cli record and replay functionality

# required modules
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 4;

# create temp record/replay/test file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

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
    if ($ENV{EXPECT}) {
        DEBUG("spawn script: $_") foreach (split/\n/, `cat $ENV{EXPECT} 2>&1`);
    }
    my $expect = Mnet::Expect::Cli->new({ spawn => $ENV{EXPECT} });
perl-eof

my $filter = <<'filter-eof';
    grep -v "Mnet::Log - started" | \
    grep -v "Mnet::Opts::Cli new parsed opt cli" | \
    grep -v "Mnet::Log finished"
filter-eof

# command method record
Mnet::T::test_perl({
    name    => 'command method record',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            echo output
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
    ',
    args    => "--record $file",
    filter  => $filter,
    expect  => "output",
    debug   => '--debug',
});

# command method replay
Mnet::T::test_perl({
    name    => 'command method replay',
    perl    => $perl . '
        print $expect->command("test") . "\n";
    ',
    args    => "--replay $file",
    filter  => $filter,
    expect  => "output",
    debug   => '--debug',
});

# command method record with cache clear
Mnet::T::test_perl({
    name    => 'command method record with cache clear',
    pre     => <<'    pre-eof',
        export EXPECT=$(mktemp); chmod 700 $EXPECT; echo '
            printf "prompt%%"; read INPUT
            printf "prompt%%"; read INPUT
            echo output one
            printf "prompt%%"; read INPUT
            echo output two
            printf "prompt%%"; read INPUT
        ' >$EXPECT
    pre-eof
    perl    => $perl . '
        print $expect->command("test") . "\n";
        $expect->command_cache_clear;
        print $expect->command("test") . "\n";
    ',
    args    => "--record $file",
    filter  => $filter,
    expect  => "output one\noutput two",
    debug   => '--debug',
});

# command method replay with cache clear
Mnet::T::test_perl({
    name    => 'command method replay with cache clear',
    perl    => $perl . '
        print $expect->command("test") . "\n";
        $expect->command_cache_clear;
        print $expect->command("test") . "\n";
    ',
    args    => "--replay $file",
    filter  => $filter,
    expect  => "output one\noutput two",
    debug   => '--debug',
});

# finished
exit;

