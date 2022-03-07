use strict;
use warnings;
use File::Temp ();
use Parallel::Pipes::App;
use Test::More;
use Time::HiRes ();

my $map_subtest = sub {
    my $number_of_pipes = shift;
    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    my $work = sub {
        my $num = shift;
        Time::HiRes::sleep(0.01);
        open my $fh, ">>", "$tempdir/file.$$" or die;
        print {$fh} "$num\n";
        $num * 2;
    };
    my @result = Parallel::Pipes::App->map(
        work => $work,
        num => $number_of_pipes,
        tasks => [0..30],
    );
    my @file = glob "$tempdir/file*";
    my @num;
    for my $f (@file) {
        open my $fh, "<", $f or die;
        chomp(my @n = <$fh>);
        push @num, @n;
    }
    @num = sort { $a <=> $b } @num;

    is @file, $number_of_pipes;
    is_deeply \@num, [0..30];
    is_deeply \@result, [map { $_ * 2 } 0..30];

    if ($number_of_pipes == 1) {
        is $file[0], "$tempdir/file.$$";
    }
};

my $run_subtest = sub {
    my $number_of_pipes = shift;
    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    my $work = sub {
        my $num = shift;
        Time::HiRes::sleep(0.01);
        open my $fh, ">>", "$tempdir/file.$$" or die;
        print {$fh} "$num\n";
        $num * 2;
    };
    my @result;
    Parallel::Pipes::App->run(
        work => $work,
        num => $number_of_pipes,
        tasks => [0..30],
        after_work => sub { push @result, $_[0] },
    );
    my @file = glob "$tempdir/file*";
    my @num;
    for my $f (@file) {
        open my $fh, "<", $f or die;
        chomp(my @n = <$fh>);
        push @num, @n;
    }
    @num = sort { $a <=> $b } @num;
    @result = sort { $a <=> $b } @result;

    is @file, $number_of_pipes;
    is_deeply \@num, [0..30];
    is_deeply \@result, [map { $_ * 2 } 0..30];

    if ($number_of_pipes == 1) {
        is $file[0], "$tempdir/file.$$";
    }
};

subtest map_number_of_pipes1 => sub { $map_subtest->(1) };
subtest map_number_of_pipes5 => sub { $map_subtest->(5) } unless $^O eq 'MSWin32';
subtest run_number_of_pipes1 => sub { $run_subtest->(1) };
subtest run_number_of_pipes5 => sub { $run_subtest->(5) } unless $^O eq 'MSWin32';

done_testing;
