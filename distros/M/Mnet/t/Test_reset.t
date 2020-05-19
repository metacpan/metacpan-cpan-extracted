
# purpose: tests Mnet::Test with Mnet::Opts::Cli --test-reset option

# required modules
use warnings;
use strict;
use File::Temp;
use Mnet::T;
use Test::More tests => 4;

# create temp test/record/replay file
my ($fh, $file) = File::Temp::tempfile( UNLINK => 1 );

# init script used to test --test-reset option
my $perl = '
    use warnings;
    use strict;
    use Mnet::Log;
    use Mnet::Log::Test;
    use Mnet::Opts::Cli;
    use Mnet::Test;
    Mnet::Opts::Cli::define({
        getopt      => "test-opt=i",
        default     => 1,
        record      => 1,
    });
    my ($cli, @extras) = Mnet::Opts::Cli->new;
    syswrite STDOUT, "test-opt = $cli->{test_opt}\n";
    syswrite STDOUT, "extras = @extras\n" if @extras;
';

# record with test-opt and extra cli arg
Mnet::T::test_perl({
    name    => 'record with test-opt and extra cli arg',
    perl    => $perl,
    args    => "--record $file --test-opt 2 extra",
    filter  => 'grep -v ^--- | grep -v ^inf',
    expect  => <<'    expect-eof',
        test-opt = 2
        extras = extra
    expect-eof
    debug   => "--debug",
});

# replay with test-opt and extra arg
Mnet::T::test_perl({
    name    => 'replay with test-opt and extra arg',
    perl    => $perl,
    args    => "--replay $file",
    filter  => 'grep -v ^--- | grep -v ^inf',
    expect  => <<'    expect-eof',
        test-opt = 2
        extras = extra
    expect-eof
    debug   => "--debug",
});

# replay with reset of cli test-opt
Mnet::T::test_perl({
    name    => 'replay with reset of cli test-opt',
    perl    => $perl,
    args    => "--replay $file --test-reset test-opt",
    filter  => 'grep -v ^--- | grep -v ^inf',
    expect  => <<'    expect-eof',
        test-opt = 1
        extras = extra
    expect-eof
    debug   => "--debug",
});

# replay with reset of extra cli args
Mnet::T::test_perl({
    name    => 'replay with reset of extra cli args',
    perl    => $perl,
    args    => "--replay $file --test-reset",
    filter  => 'grep -v ^--- | grep -v ^inf',
    expect  => <<'    expect-eof',
        test-opt = 2
    expect-eof
    debug   => "--debug",
});

# finished
exit;

