use Test::Most;
use Shell::Carapace;

my $basic_test = sub {
    my ($cat, $msg, $host) = @_;

    is $msg, "hi there", $cat       if $cat eq 'local-output';
    is $msg, "echo hi there", $cat  if $cat eq 'command';
    is $host, "localhost", $cat;
    fail "should not have an error" if $cat eq 'error';
};

my $shell = Shell::Carapace->shell(callback => $basic_test);

subtest 'list' => sub {
    $shell->callback($basic_test);
    $shell->run(qw/echo hi there/);
};

subtest 'string' => sub {
    $shell->callback($basic_test);
    $shell->run('echo hi there');
};

subtest 'dies ok' => sub {
    my $test = sub {
        my ($cat, $msg, $host) = @_;

        is $host, "localhost", $cat;
        is $msg,  "ls sdfljfskfsupercalifragilistic", $cat 
            if $cat eq any(qw/error command/);
    };

    $shell->callback($test);
    dies_ok { $shell->run(qw/ls sdfljfskfsupercalifragilistic/) } 'dead';
};

done_testing;
