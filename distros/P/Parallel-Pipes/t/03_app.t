use strict;
use warnings;
use File::Temp ();
use Parallel::Pipes::App;
use Test::More;
use Time::HiRes ();

my $subtest = sub {
    my $number_of_pipes = shift;
    my $tempdir = File::Temp::tempdir(CLEANUP => 1);
    my $work = sub {
        my $num = shift;
        Time::HiRes::sleep(0.01);
        open my $fh, ">>", "$tempdir/file.$$" or die;
        print {$fh} "$num\n";
        $num;
    };
    my @back = Parallel::Pipes::App->run(
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
    @back = sort { $a <=> $b } @back;

    is @file, $number_of_pipes;
    is_deeply \@num, [0..30];
    is_deeply \@back, [0..30];

    if ($number_of_pipes == 1) {
        is $file[0], "$tempdir/file.$$";
    }
};

subtest number_of_pipes1 => sub { $subtest->(1) };
subtest number_of_pipes5 => sub { $subtest->(5) } unless $^O eq 'MSWin32';

done_testing;
