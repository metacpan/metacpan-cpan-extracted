#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 56;

use Template::Preprocessor::TTML::CmdLineProc;

sub get_res
{
    my $obj = Template::Preprocessor::TTML::CmdLineProc->new(@_);
    return $obj->get_result();
}

# Test for no specified filename
{
    my $r;
    eval {
        $r = get_res(argv => [qw()]);
    };
    # TEST
    ok($@, "Testing for thrown exception");
}

# Test for one filename
{
    my $r = get_res(argv => ["hello.ttml"]);
    # TEST
    ok($r, "Result is OK");
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    ok($r->output_to_stdout(), "Outputting to stdout");
    # TEST
    is_deeply($r->include_path(), [], "Include Path is empty");
    # TEST
    is_deeply($r->defines(), +{}, "Defines are empty");
    # TEST
    is_deeply($r->include_files(), [], "Include Files are empty");
    # TEST
    is ($r->run_mode(), "regular", "Run mode is OK");
}

# Test for last filename is an option
{
    my $r;
    eval {
        $r = get_res(argv => [qw(--hello.ttml)]);
    };
    # TEST
    ok($@, "Testing for thrown exception");
}

# Test for one filename starting with minus
{
    my $r = get_res(argv => ["--", "--hello.ttml"]);
    # TEST
    ok($r, "Result is OK");
    # TEST
    is($r->input_filename(), "--hello.ttml", "Input filename is OK");
    # TEST
    ok($r->output_to_stdout(), "Outputting to stdout");
}

# Test for junk after one filename
{
    my $r;

    eval {
         $r = get_res(argv => ["hello.ttml", "YOWZA!"]);
    };
    # TEST
    ok ($@, "Junk after input filename");
}

# Test for -o
{
    my $r = get_res(argv => ["-o", "myout.html", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    ok(!$r->output_to_stdout(), "Not outting to stdout");
    # TEST
    is ($r->output_filename(), "myout.html", "Output filename is OK");
}

# Test for includes
{
    my $r = get_res(argv => ["-I", "mydir/", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->include_path(), ["mydir/"], "Include Path is OK");
}

# Test for includes
{
    my $r = get_res(argv => ["-Imydir/", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->include_path(), ["mydir/"], "Include Path is OK");
}

# Test for includes
{
    my $r = get_res(argv => ["--include=mydir/", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->include_path(), ["mydir/"], "Include Path is OK");
}

# Test for includes
{
    my $r = get_res(argv => ["--include", "mydir/", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->include_path(), ["mydir/"], "Include Path is OK");
}

# Several includes
{
    my $r = get_res(argv => ["--include", "mydir/", "-I/hello/home", "--include=/yes/no", "-I", "./you-say/", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply(
        $r->include_path(),
        ["mydir/", "/hello/home", "/yes/no", "./you-say/",],
        "Include Path is OK"
    );
}

# Test for defines
{
    my $r = get_res(argv => ["-Dmyarg=myval", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->defines(), {'myarg' => "myval"}, "Defines are OK");
}

# Test for defines
{
    my $r = get_res(argv => ["-D", "myarg=myval", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->defines(), {'myarg' => "myval"}, "Defines are OK");
}

# Test for defines
{
    my $r = get_res(argv => ["--define=myarg=myval", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->defines(), {'myarg' => "myval"}, "Defines are OK");
}

# Test for defines
{
    my $r = get_res(argv => ["--define", "myarg=myval", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->defines(), {'myarg' => "myval"}, "Defines are OK");
}

# Test for multiple defines
{
    my $r = get_res(argv => ["-Dmyarg=myval", "-Dsuper=par", "-D", "write=1", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->defines(),
        {'myarg' => "myval", "super" => "par", "write" => "1"},
        "Multiple Defines are OK");
}

# Test for multiple defines
{
    my $r = get_res(argv => ["-Dmyarg=myval", "-Dsuper=par", "-D", "write=1", "--define=hi=there", "--define", "ext=.txt", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->defines(),
        {'myarg' => "myval", "super" => "par", "write" => "1",
         "hi" => "there", "ext" => ".txt",
        },
        "Multiple Defines are OK");
}

# Test for include files
{
    my $r = get_res(argv => ["--includefile=myfile.ttml", "--includefile", "turn.txt", "hello.ttml"]);
    # TEST
    is($r->input_filename(), "hello.ttml", "Input filename is OK");
    # TEST
    is_deeply($r->include_files(),
        [qw(myfile.ttml turn.txt)],
        "Include files are ok"
    );
}

# Test for --version
{
    my $r = get_res(argv => ["--version"]);
    # TEST
    is ($r->run_mode(), "version", "Testing for --version");
}

# Test for -V
{
    my $r = get_res(argv => ["-V"]);
    # TEST
    is ($r->run_mode(), "version", "Testing for -V");
}

# Test for --help
{
    my $r = get_res(argv => ["--help"]);
    # TEST
    is ($r->run_mode(), "help", "Testing --help");
}

# Test for -h
{
    my $r = get_res(argv => ["-h"]);
    # TEST
    is ($r->run_mode(), "help", "-h");
}

# Test the --help and --version flags inside other command lines.
{
    eval {
        my $r = get_res(argv => ["-o", "hello", "--version", "test.ttml"]);
    };
    # TEST
    ok($@, "An exception was thrown because --version is specified as well as other args");
}

{
    eval {
        my $r = get_res(argv => ["-o", "hello", "--help", "test.ttml"]);
    };
    # TEST
    ok($@, "An exception was thrown because --help is specified as well as other args");
}

{
    eval {
        my $r = get_res(argv => ["-o", "hello", "-V", "test.ttml"]);
    };
    # TEST
    ok($@, "An exception was thrown because -V is specified as well as other args");
}

{
    eval {
        my $r = get_res(argv => ["-o", "hello", "-h", "test.ttml"]);
    };
    # TEST
    ok($@, "An exception was thrown because -h is specified as well as other args");
}

# Some grand finale testing schemes
# Test for one filename
{
    my $r = get_res(argv => ["-DFILENAME=hoola", "-o", "shlomif200.html", "-I", "/home/tt2/", "--include=./mydir/", "Goola.ttml"]);
    # TEST
    ok($r, "Result is OK");
    # TEST
    is($r->input_filename(), "Goola.ttml", "Input filename is OK");
    # TEST
    ok(!$r->output_to_stdout(), "Not outputting to stdout");
    # TEST
    is($r->output_filename(), "shlomif200.html", "Output file is OK.");
    # TEST
    is_deeply($r->include_path(), ["/home/tt2/", "./mydir/"], "Include Path is OK");
    # TEST
    is_deeply($r->defines(), +{'FILENAME' => "hoola",}, "Defines are OK");
    # TEST
    is_deeply($r->include_files(), [], "Include Files are empty");
    # TEST
    is ($r->run_mode(), "regular", "Run mode is OK");
}

