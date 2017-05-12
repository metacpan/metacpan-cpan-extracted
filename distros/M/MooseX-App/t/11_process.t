# -*- perl -*-

# t/11_process.t - Test via subprocesses

use Test::Most tests => 1+1;
use Test::NoWarnings;

use FindBin qw();
use IPC::Open3 qw(open3);
use Symbol qw(gensym);

my $BASE = "$^X $FindBin::Bin/example";

subtest 'Test basic exit codes' => sub {
    SKIP: {
        skip "Cannot test on MSWin",7
            if $^O =~ /^MSWin/;

        test_subprocess(
            bin     => 'test02.pl',
            exit    => 127,
            out     => '',
            err     => qr/Missing command/,
        );

        test_subprocess(
            bin     => 'test02.pl error',
            exit    => 25,
            err     => qr/XXX/,
        );

        test_subprocess(
            bin     => 'test02.pl version',
            exit    => 0,
            out     => qr/VERSION/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test02.pl version',
            exit    => 0,
            out     => qr/VERSION/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test02.pl record --help',
            exit    => 0,
            out     => qr/usage:/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test02.pl record',
            exit    => 0,
            out     => qr/RAN/,
            err     => '',
        );

        test_subprocess(
            bin     => 'test02.pl record --notthere',
            exit    => 1,
            out     => '',
            err     => qr/Unknown option 'notthere'/,
        );
    }
};



sub test_subprocess {
    my (%params) = @_;
    $params{args} ||= [];

    my($in_fh, $out_fh, $err_fh, $out, $err, $pid, $exit);
    $err_fh = gensym;
    eval {
        $pid = open3(
            $in_fh, $out_fh, $err_fh,
            $BASE.'/'.$params{bin},
        );
    };
    if ($@) {
        fail('Error running '.$params{bin}.' :'.$@);
        return;
    }

    if (defined $pid) {
        waitpid($pid,0);
        $exit = $? >> 8;

        $out = '';
        while(<$out_fh>) {
            $out .= $_;
        }

        $err = '';
        while(<$err_fh>) {
            $err .= $_;
        }
    }

    if (exists $params{exit}) {
        is($exit,$params{exit},'Exitcode '.$params{bin}.' ok');
    }
    if (exists $params{out}) {
        if (ref $params{out} eq 'Regexp') {
            like($out,$params{out},'Output '.$params{bin}.' ok');
        } else {
            is($out,$params{out},'Output '.$params{bin}.' ok');
        }
    }
    if (exists $params{err}) {
        if (ref $params{err} eq 'Regexp') {
            like($err,$params{err},'Error '.$params{bin}.' ok');
        } else {
            is($err,$params{err},'Error '.$params{bin}.' ok');
        }
    }

    return;
}