
# purpose: tests Mnet::Batch

# required modules
use warnings;
use strict;
use Mnet::T;
use Test::More tests => 3;

# batch without mnet cli
Mnet::T::test_perl({
    name    => 'batch without mnet cli',
    pre     => <<'    pre-eof',
        export BATCH=$(mktemp); echo '
            arg1
            arg2 arg3
        ' >$BATCH
    pre-eof
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Batch;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Set::Debug;
        my $line = Mnet::Batch::fork({ batch => $ENV{BATCH} });
        exit if not defined $line;
        syswrite STDOUT, "line = $1\n" if $line =~ /^\s*(.*)/;
    perl-eof
    post    => 'rm $BATCH',
    filter  => 'grep -v ^dbg | grep -v ^---',
    expect  => '
        line = arg1
        line = arg2 arg3
    ',
});

# batch with mnet cli
Mnet::T::test_perl({
    name    => 'batch with mnet cli',
    pre     => <<'    pre-eof',
        export BATCH=$(mktemp); echo '
            --opt1 1 --opt2 1
            --opt1 2
        ' >$BATCH
    pre-eof
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Batch;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Debug;
        Mnet::Opts::Cli::define({ getopt => "opt1=i", recordable  => 1 });
        Mnet::Opts::Cli::define({ getopt => "opt2=i", recordable  => 1 });
        my $cli = Mnet::Opts::Cli->new;
        $cli = Mnet::Batch::fork($cli);
        exit if not $cli;
        syswrite STDOUT, "opt1 = $cli->{opt1}, opt2 = $cli->{opt2}\n";
    perl-eof
    args    => '--batch $BATCH --opt1 3 --opt2 3',
    post    => 'rm $BATCH',
    filter  => 'grep -v ^dbg | grep -v ^---',
    expect  => '
        opt1 = 1, opt2 = 1
        opt1 = 2, opt2 = 3
    ',
});

# batch with mnet cli and extras
Mnet::T::test_perl({
    name    => 'batch with mnet cli and extras',
    pre     => <<'    pre-eof',
        export BATCH=$(mktemp); echo '
            --opt 1 child
            --opt 2
        ' >$BATCH
    pre-eof
    perl    => <<'    perl-eof',
        use warnings;
        use strict;
        use Mnet::Batch;
        use Mnet::Log;
        use Mnet::Log::Test;
        use Mnet::Opts::Cli;
        use Mnet::Opts::Set::Debug
        Mnet::Opts::Cli::define({ getopt => "opt=i" });
        my ($cli, @extras) = Mnet::Opts::Cli->new;
        ($cli, @extras) = Mnet::Batch::fork($cli);
        exit if not $cli;
        syswrite STDOUT, "opt = $cli->{opt}\n" if $cli->{opt};
        syswrite STDOUT, "extras = @extras\n" if @extras;
    perl-eof
    args    => '--batch $BATCH parent',
    post    => 'rm $BATCH',
    filter  => 'grep -v ^dbg | grep -v ^inf | grep -v ^---',
    expect  => '
        opt = 1
        extras = parent child
        opt = 2
        extras = parent
    ',
});

# finished
exit;

