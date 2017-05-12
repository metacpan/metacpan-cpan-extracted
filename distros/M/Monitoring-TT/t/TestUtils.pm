#!/usr/bin/env perl

package TestUtils;

#########################
# Test Utils
#########################

use strict;
use Data::Dumper;
use Test::More;
use File::Temp qw/ tempdir /;

#########################

=head2 test_command

  execute a test command

  needs test hash
  {
    cmd     => command line to execute
    exit    => expected exit code
    like    => (list of) regular expressions which have to match stdout
    errlike => (list of) regular expressions which have to match stderr, default: empty
    sleep   => time to wait after executing the command
  }

=cut
sub test_command {
    my $test = shift;
    my($rc, $stderr) = ( -1, '') ;
    my $return = 1;

    require Test::Cmd;
    Test::Cmd->import();

    # run the command
    isnt($test->{'cmd'}, undef, "running cmd: ".$test->{'cmd'}) or $return = 0;

    my($prg,$arg) = split(/\s+/, $test->{'cmd'}, 2);
    my $t = Test::Cmd->new(prog => $prg, workdir => '') or die($!);
    alarm(300);
    eval {
        local $SIG{ALRM} = sub { die "timeout on cmd: ".$test->{'cmd'}."\n" };
        $t->run(args => $arg, stdin => $test->{'stdin'});
        $rc = $?>>8;
    };
    if($@) {
        $stderr = $@;
    } else {
        $stderr = $t->stderr;
    }
    alarm(0);

    # exit code?
    $test->{'exit'} = 0 unless exists $test->{'exit'};
    if(defined $test->{'exit'} and $test->{'exit'} != -1) {
        ok($rc == $test->{'exit'}, "exit code: ".$rc." == ".$test->{'exit'}) or do { diag("command failed with rc: ".$rc." - ".$t->stdout); $return = 0 };
    }

    # matches on stdout?
    if(defined $test->{'like'}) {
        for my $expr (ref $test->{'like'} eq 'ARRAY' ? @{$test->{'like'}} : $test->{'like'} ) {
            like($t->stdout, $expr, "stdout like ".$expr) or do { diag("\ncmd: '".$test->{'cmd'}."' failed\n"); $return = 0 };
        }
    }
    # matches on stdout?
    if(defined $test->{'unlike'}) {
        for my $expr (ref $test->{'unlike'} eq 'ARRAY' ? @{$test->{'unlike'}} : $test->{'unlike'} ) {
            unlike($t->stdout, $expr, "stdout unlike ".$expr) or do { diag("\ncmd: '".$test->{'cmd'}."' failed\n"); $return = 0 };
        }
    }

    # matches on stderr?
    $test->{'errlike'} = '/^\s*$/' unless exists $test->{'errlike'};
    if(defined $test->{'errlike'}) {
        for my $expr (ref $test->{'errlike'} eq 'ARRAY' ? @{$test->{'errlike'}} : $test->{'errlike'} ) {
            like($stderr, $expr, "stderr like ".$expr) or do { diag("\ncmd: '".$test->{'cmd'}."' failed"); $return = 0 };
        }
    }

    # sleep after the command?
    if(defined $test->{'sleep'}) {
        ok(sleep($test->{'sleep'}), "slept $test->{'sleep'} seconds") or do { $return = 0 };
    }

    # set some values
    $test->{'stdout'} = $t->stdout;
    $test->{'stderr'} = $t->stderr;
    $test->{'exit'}   = $rc;

    return $return;
}

#########################
sub test_montt {
    my($dir, $options) = @_;

    my $BIN = $ENV{'TEST_BIN'} || './bin/montt';
    ok(-f $BIN, "montt exists: $BIN") or BAIL_OUT("no binary found");

    my $tempdir = tempdir();
    ok(($tempdir and -d $tempdir), "created tempdir: ".$tempdir);

    $options = {} unless defined $options;
    $options->{'cmd'} = $^X." ".$BIN.' -v '.$dir.'/in '.$tempdir    unless defined $options->{'cmd'};
    $options->{'like'} = [ '/\[INFO\]\ done/' ]                     unless defined $options->{'like'};
    $options->{'unlike'} = [ '/ARRAY/', '/HASH/' ]                  unless defined $options->{'unlike'};

    # create config
    my $rc = TestUtils::test_command($options);
    if($rc and !defined $options->{'exit'}) {
        BAIL_OUT('export didn\'t work'.`rm -rf $tempdir`);
    }

    # compare to expected result
    TestUtils::test_command({
        cmd  => '/usr/bin/diff -ur  '.$dir.'/out  '.$tempdir,
        like => [],
    });

    # cleanup
    `rm -rf $tempdir`;
    isnt(-d $tempdir, 1, "unlinked tempdir");

    return;
}

1;

__END__
