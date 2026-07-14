#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(remove_tree);

# This test verifies the command-line interface of the protobuf-starter script.

my $script = File::Spec->catfile('bin', 'protobuf-starter');

subtest 'Script Sanity Checks' => sub {
    ok(-f $script, 'Script exists at ' . $script);
    done_testing();
};

sub run_script {
    my (@args) = @_;
    
    my $stdout_file = File::Spec->catfile('tmp', 'starter-out.log');
    my $stderr_file = File::Spec->catfile('tmp', 'starter-err.log');
    
    # Ensure tmp directory exists
    unless (-d 'tmp') {
        mkdir 'tmp';
    }
    
    # Clean old logs
    unlink($stdout_file) if -f $stdout_file;
    unlink($stderr_file) if -f $stderr_file;
    
    # Construct command (inheriting PERL5LIB so it loads our uninstalled plugin!)
    my $cmd = sprintf(
        'PERL5LIB=lib:$PERL5LIB perl %s %s > %s 2> %s',
        $script,
        join(' ', @args),
        $stdout_file,
        $stderr_file
    );
    
    my $rc = system($cmd);
    my $exit_code = $rc >> 8;
    
    my $stdout = '';
    if (-f $stdout_file) {
        open my $fh, '<', $stdout_file;
        local $/;
        $stdout = <$fh> || '';
        close $fh;
        unlink($stdout_file);
    }
    
    my $stderr = '';
    if (-f $stderr_file) {
        open my $fh, '<', $stderr_file;
        local $/;
        $stderr = <$fh> || '';
        close $fh;
        unlink($stderr_file);
    }
    
    return ($exit_code, $stdout, $stderr);
}

subtest 'Usage help message on invalid flag' => sub {
    my ($exit_code, $stdout, $stderr) = run_script('--invalid-flag');
    is($exit_code, 2, 'Invalid flag exits with 2');
    like($stderr, qr/Usage:/i, 'Usage help message displayed on STDERR');
    done_testing();
};

subtest 'Error on missing module parameter' => sub {
    my ($exit_code, $stdout, $stderr) = run_script('--dir=tmp/out', '--protos=foo.proto');
    is($exit_code, 2, 'Exits with 2 on missing --module');
    like($stderr, qr/No modules specified/i, 'Correct error message displayed on STDERR');
    done_testing();
};

subtest 'Error on missing protos parameter' => sub {
    my ($exit_code, $stdout, $stderr) = run_script('--module=Foo', '--dir=tmp/out');
    is($exit_code, 2, 'Exits with 2 on missing --protos');
    like($stderr, qr/No proto files specified/i, 'Correct error message displayed on STDERR');
    done_testing();
};

subtest 'Error on missing dir parameter' => sub {
    my ($exit_code, $stdout, $stderr) = run_script('--module=Foo', '--protos=foo.proto');
    is($exit_code, 2, 'Exits with 2 on missing --dir');
    like($stderr, qr/No output directory specified/i, 'Correct error message displayed on STDERR');
    done_testing();
};

subtest 'Successful dry run generation' => sub {
    my $tmp_out = File::Spec->catdir('tmp', 'starter-acceptance-out');
    if (-d $tmp_out) {
        remove_tree($tmp_out);
    }
    
    my $proto_file = File::Spec->catfile('..', 'protobuf', 'perl', 't', 'protos', 'service.proto');
    my $import_path = File::Spec->catdir('..', 'protobuf', 'perl', 't', 'protos');
    
    my ($exit_code, $stdout, $stderr) = run_script(
        '--module=Google::Cloud::Test',
        "--protos=$proto_file",
        "--import-path=$import_path",
        '--grpc-target=test.googleapis.com',
        "--dir=$tmp_out",
        '--force'
    );
    
    is($exit_code, 0, 'Successful run exits with 0');
    like($stdout, qr/Created starter directories and files/i, 'Success message displayed on STDOUT');
    
    # Verify key files are generated
    ok(-f File::Spec->catfile($tmp_out, 'lib', 'Google', 'Cloud', 'Test.pm'), 'Generated client wrapper');
    ok(-f File::Spec->catfile($tmp_out, 'lib', 'Google', 'Cloud', 'Test', 'V1', 'Service.pm'), 'Generated compiled messages');
    
    # Clean up
    if (-d $tmp_out) {
        remove_tree($tmp_out);
    }
    done_testing();
};

done_testing();
