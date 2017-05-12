#!/usr/bin/perl
use strict;
use warnings;

use Data::Dumper;
use Test::More;
use Test::NoWarnings;
use File::Temp qw(tempdir);

use Pipe;

plan tests => 29+1;

my $dir = tempdir( CLEANUP => 1);

#$Pipe::DEBUG = 1;


{
    eval {Pipe->no_such();};
    like $@, qr{^Could not load 'Pipe::Tube::No_such'}, "exception on missing tube";
}


{
    my $p = Pipe->cat();
    isa_ok($p, 'Pipe');
    my @input = $p->run;
    is_deeply \@input, [], "empty array";
}

{
    unlink "pipe.log";
    $Pipe::DEBUG = 1;
    Pipe->cat();
    ok -e "pipe.log", "log was created";
    $Pipe::DEBUG = 0;
}


{
    my $p = Pipe->cat("t/data/file1");
    my @input = $p->run;
    @ARGV = ("t/data/file1");
    my @expected = <>;
    is_deeply \@input, \@expected, "reading one file";
}

{
    my @input = Pipe->cat("t/data/file1", "t/data/file2")->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    is_deeply \@input, \@expected, "reading two files";
}

# with a non-existing file, (give error message but go on processing)
{
    my $warn = '';
    local $SIG{__WARN__} = sub {$warn = shift;};
    my @input = Pipe->cat("t/data/file1", "t/data/file_not_there", "t/data/file2")->run;
    like $warn, qr{^\QCould not open 't/data/file_not_there'.}, "warn about a missing file";
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    is_deeply \@input, \@expected, "reading two files";
}


{
    my @input = Pipe->cat("t/data/file1", "t/data/file2")->chomp->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    chomp @expected;
    is_deeply \@input, \@expected, "reading two files and piping through chomp";
}

{
    my @input = Pipe->cat("t/data/numbers1")->uniq->chomp->run;
    my @expected = (23, 17, 2, 43, 23);
    is_deeply \@input, \@expected, "reading a file and piping through uniq and chomp";
}

{
    my @input = Pipe->cat("t/data/numbers1")->chomp->uniq->run;
    my @expected = (23, 17, 2, 43, 23);
    is_deeply \@input, \@expected, "reading a file and piping through chomp and uniq";
}



{
    my @input = Pipe->cat("t/data/file1", "t/data/file2")->grep(qr/test/)->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = grep /test/, <>;
    is_deeply \@input, \@expected, "reading two files and piping through grep with regex";
}

{
    #my @input = Pipe->cat("t/data/file1", "t/data/file2")->grep( sub { index($_[0], "testing") > -1 } )->run;
    my @input = Pipe->cat("t/data/file1", "t/data/file2")->grep( sub { index($_, "testing") > -1 } )->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = grep { index($_, "testing") > -1 } <>;
    is_deeply \@input, \@expected, "reading two files and piping through grep with block";
}

{
    my @input = Pipe->cat("t/data/numbers1")->chomp->sort->run;
    @ARGV = ("t/data/numbers1");
    my @expected = sort <>;
    chomp @expected;
    is_deeply \@input, \@expected, "reading file sorting";
}

{
    my @input = Pipe->cat("t/data/numbers1")->chomp->sort( sub { $_[0] <=> $_[1] } )->run;
    @ARGV = ("t/data/numbers1");
    my @expected = sort {$a <=> $b} <>;
    chomp @expected;
    is_deeply \@input, \@expected, "reading file sorting numerically";
}

{
    my @files = Pipe->glob("t/data/file*")->run;
    my @expected = glob "t/data/file*";
    is_deeply \@files, \@expected, "glob on two files";
}

{
    my @input = Pipe->glob("t/data/file[12]")
        ->cat
        ->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    is_deeply \@input, \@expected, "reading two files and piping through another cat";
}

{
    my @input = Pipe->cat("t/data/file1", "t/data/file2")
                    ->map(  sub {{str => $_[0], long => length $_[0]}} )
                    ->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = map {{ str => $_, long => length $_}} <>;
    is_deeply \@input, \@expected, "reading two files and maping the lines";
}

{
    my @input = Pipe->cat("t/data/file1", "t/data/file2")
                    ->map(  sub {{str => $_[0], long => length $_[0]}} )
                    ->sort( sub {$_[0]->{long} <=> $_[1]->{long}} )
                    ->map(  sub { $_[0]->{str} } )
                    ->run;
    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = sort {length $a <=> length $b} <>;
    is_deeply \@input, \@expected, "reading two files and piping through Schwartzian transformation";
}

{
    my @array_names   = qw(one two three);
    my @array_numbers = (1, 2, 3);

    my @out = Pipe->for(@array_names)->run;
    is_deeply \@array_names, \@out, "for elements of array";

    #my @all = Pipe->pairs(\@array_names, \@array_numbers);
    #my @expected =
}

{
    my @files = Pipe->find("t")->run;
    #diag Dumper \@files;
    #BEGIN { $tests += 1; }
}

{
    @ARGV = ("t/data/file1", "t/data/file2");
    Pipe->cat(@ARGV)->print("$dir/out")->run;

    my @expected = <>;
    @ARGV = ("$dir/out");
    my @received = <>;
    is_deeply \@received, \@expected, "reading two files and piping through print to filename";
}

# TODO: the following test passes when using prove but fails when running
# ./Build test
#
#{
#    @ARGV = ("t/data/file1", "t/data/file2");
#    my @received = `$^X t/print_stdout.pl @ARGV`;
#    my @expected = <>;
#
#    is_deeply \@received, \@expected, "reading two files and piping through print() ";
#}

{
    open my $out, ">", "$dir/out" or die $!;
    Pipe->cat("t/data/file1", "t/data/file2")->print($out)->run;
    close $out;

    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    @ARGV = ("$dir/out");
    my @received = <>;
    is_deeply \@received, \@expected, "reading two files and piping through print to filehandle";
}

#Pipe->cat("t/data/file1", "t/data/file2")->chomp->say->run;
{
    Pipe->cat("t/data/file1", "t/data/file2")->chomp->say("$dir/out3")->run;

    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    @ARGV = ("$dir/out3");
    my @received = <>;
    is_deeply \@received, \@expected, "reading two files and piping through print to filename";
}

{
    open my $out, ">", "$dir/out4" or die $!;
    Pipe->cat("t/data/file1", "t/data/file2")->chomp->say($out)->run;
    close $out;

    @ARGV = ("t/data/file1", "t/data/file2");
    my @expected = <>;
    @ARGV = ("$dir/out4");
    my @received = <>;
    is_deeply \@received, \@expected, "reading two files and piping through print to filehandle";
}


{
    my @a = qw(foo bar baz moo);
    my @b = qw(23  37  77  42);

    my @one_tuple = Pipe->tuple(\@a)->run;
    is_deeply \@one_tuple, [['foo'], ['bar'], ['baz'], ['moo']], "1-tuple";

    my @two_tuple = Pipe->tuple(\@a, \@b)->run;
    is_deeply \@two_tuple, [['foo', 23], ['bar', 37], ['baz', 77], ['moo', 42]], "2-tuple";

    # catch die in case array was passed insted of arrayref ?
}


{
    my @input = (
        "abc =   def",
        "a=b",
    );
    my @result = Pipe->for(@input)->split(qr/\s*=\s*/)->run;
    is_deeply \@result, [ ["abc", "def"], ["a", "b"] ], "split with regex";

    my @result_2 = Pipe->for(@input)->split("=")->run;
    is_deeply \@result_2, [ ["abc ", "   def"], ["a", "b"] ], "split with string";
}

{
    my @input = (
        "abc|bcd",
        "a|b",
    );
    my @result = Pipe->for(@input)->split("|")->run;
    is_deeply \@result, [ ["abc", "bcd"], ["a", "b"] ], "split with | as string";
}



