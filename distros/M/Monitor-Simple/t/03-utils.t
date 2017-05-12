#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 17;

#-----------------------------------------------------------------
# Return a fully qualified name of the given file in the test
# directory "t/data" - if such file really exists. With no arguments,
# it returns the path of the test directory itself.
# -----------------------------------------------------------------
use FindBin qw( $Bin );
use File::Spec;
sub test_file {
    my $file = File::Spec->catfile ('t', 'data', @_);
    return $file if -e $file;
    $file = File::Spec->catfile ($Bin, 'data', @_);
    return $file if -e $file;
    return File::Spec->catfile (@_);
}

# -----------------------------------------------------------------
# Tests start here...
# -----------------------------------------------------------------
ok(1);
use Monitor::Simple;
use Monitor::Simple::Utils;
diag( "Testing utilities" );

# parse plugin's args
{
    my $config_file = File::Spec->catfile (test_file(), 'config.xml');
    my @result = Monitor::Simple::Utils->parse_plugin_args ('default', '-cfg', $config_file, '-service', 's1');
    is_deeply (\@result, [ $config_file, 's1' ], "Parse plugin arguments 1");
    @result = Monitor::Simple::Utils->parse_plugin_args (undef, '-cfg', $config_file, '-service', 's1');
    is_deeply (\@result, [ $config_file, 's1' ], "Parse plugin arguments 2");
    @result = Monitor::Simple::Utils->parse_plugin_args ('s1', '-cfg', $config_file);
    is_deeply (\@result, [ $config_file, 's1' ], "Parse plugin arguments 3");
    @result = Monitor::Simple::Utils->parse_plugin_args (undef, '-cfg', $config_file);
    is_deeply (\@result, [ $config_file, undef ], "Parse plugin arguments 4");
}

# parse notifier's args
{
    my @result = Monitor::Simple::Utils->parse_notifier_args (['-service', 's1', '-msg', 'file', '-emails', 'address']);
    is_deeply (\@result, [ 's1', 'file', [ 'address' ] ], "Parse notifier arguments 1");
    @result = Monitor::Simple::Utils->parse_notifier_args (['-service', 's1', '-msg', 'file']);
    is_deeply (\@result, [ 's1',        'file', [] ], "Parse notifier arguments 2");
}

# process exit
{
    my @result;
    @result = Monitor::Simple::Utils->process_exit ('dummy', 0, 'msg');
    is_deeply (\@result, [ 0, 'msg' ], "Process exit code 0");
    @result = Monitor::Simple::Utils->process_exit ('dummy', 256, 'msg');
    is_deeply (\@result, [ 1, 'msg' ], "Process exit code 256");
    @result = Monitor::Simple::Utils->process_exit ('dummy', -1, 'msg');
    is ($result[0], -1, "Process exit code -1");
}

# is integer
my $integer_tests = {
    2 => 1, 0 => 1, '-0' => 1, '-2' => 1,
    a => '', '1.2' => '', '0.5' => '',
};
foreach my $str (keys %$integer_tests) {
    is (Monitor::Simple::Utils->is_integer ($str), $integer_tests->{$str}, "Integer: '$str'");
}

__END__
