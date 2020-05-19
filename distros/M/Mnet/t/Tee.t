
# purpose: tests Mnet::Tee

# required modules
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 3;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# tee to file using all function calls
Mnet::T::test_perl({
    name    => 'tee to file using all function calls',
    pre     => 'echo SCRIPT',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        my $file = $ARGV[0];
        use Mnet::Tee qw( $stdout $stderr );
        syswrite $stdout, "Mnet::Tee::stdout\n";
        syswrite $stderr, "Mnet::Tee::stderr\n";
        syswrite STDOUT, "stdout1\n";
        syswrite STDERR, "stderr1\n";
        die if Mnet::Tee::test_outputs() !~ /stdout1/;
        die if Mnet::Tee::test_outputs() !~ /stderr1/;
        Mnet::Tee::file($file);
        syswrite STDOUT, "stdout2\n";
        syswrite STDERR, "stderr2\n";
        die if Mnet::Tee::test_outputs() !~ /stdout2/;
        die if Mnet::Tee::test_outputs() !~ /stderr2/;
        Mnet::Tee::test_pause();
        die if not Mnet::Tee::test_paused();
        syswrite STDOUT, "stdout3\n";
        syswrite STDERR, "stderr3\n";
        die if Mnet::Tee::test_outputs() =~ /stdout3/;
        die if Mnet::Tee::test_outputs() =~ /stderr3/;
        Mnet::Tee::test_unpause();
        syswrite STDOUT, "stdout4\n";
        syswrite STDERR, "stderr4\n";
        die if Mnet::Tee::test_outputs() !~ /stdout4/;
        die if Mnet::Tee::test_outputs() !~ /stderr4/;
    perl-eof
    args    => $file,
    post    => "echo FILE; cat $file",
    filter  => 'grep -v ^--- | grep -v ^dbg | grep -v ^inf',
    expect  => <<'    expect-eof',
        SCRIPT
        Mnet::Tee::stdout
        Mnet::Tee::stderr
        stdout1
        stderr1
        stdout2
        stderr2
        stdout3
        stderr3
        stdout4
        stderr4
        FILE
        stdout1
        stderr1
        stdout2
        stderr2
        stdout3
        stderr3
        stdout4
        stderr4
    expect-eof
});

# tee to file using --tee cli option
Mnet::T::test_perl({
    name    => 'tee to file using --tee cli option',
    pre     => 'echo SCRIPT',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Debug;
        use Mnet::Tee;
        Mnet::Opts::Cli->new;
        syswrite STDOUT, "stdout\n";
        syswrite STDERR, "stderr\n";
    perl-eof
    args    => "--tee $file",
    post    => "echo FILE; cat $file",
    filter  => 'grep -v ^--- | grep -v ^dbg | grep -v ^inf',
    expect  => <<'    expect-eof',
        SCRIPT
        stdout
        stderr
        FILE
        stdout
        stderr
    expect-eof
});


# tee to file with log --silent option
Mnet::T::test_perl({
    name    => 'tee to file with log --silent option',
    pre     => 'echo SCRIPT',
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        # use Mnet::Opts::Set::Debug;
        use Mnet::Tee;
        Mnet::Opts::Cli->new;
        syswrite STDOUT, "stdout\n";
        syswrite STDERR, "stderr\n";
    perl-eof
    args    => "--tee $file --silent",
    post    => "echo FILE; cat $file",
    filter  => 'sed "s/tee = .*/tee = file/"',
    expect  => <<'    expect-eof',
        SCRIPT
        FILE
        --- - Mnet::Log - started
        inf - Mnet::Opts::Cli new parsed opt cli silent = 1
        inf - Mnet::Opts::Cli new parsed opt cli tee = file
        stdout
        stderr
        --- - Mnet::Log finished, no errors
    expect-eof
    debug   => '--debug',
});

# finished
exit;

