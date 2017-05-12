use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);

use_ok 'Parallel::MapReduce::Testing';

#use constant SERVERS => ['127.0.0.1:11211'];
#use constant WORKERS => ['127.0.0.1', '127.0.0.1'];

{
    my $mri = new Parallel::MapReduce::Testing ();

    my $string2lines = $mri->mapreducer (
				    sub {
					my ($k, $v) = (shift, shift);
					my $c = 0;
					map { ++$c => $_ } split /\n/, $v
					},
				    sub {
					my ($k, $v) = (shift, shift);
					return join '', @$v;
				    }
					);
    my $A = {1 => 'this is something
this is something else
something else completely'};
    my $B = &$string2lines ($A);
#    warn Dumper $B;
    is_deeply ($B, {
	             '1' => 'this is something',
		     '3' => 'something else completely',
		     '2' => 'this is something else'
                   }, 'singular mapreducer');
}

{
    my $mri = new Parallel::MapReduce::Testing ();
    my $string2lines = $mri->mapreducer (
				    sub {
					my ($k, $v) = (shift, shift);
					my $c = 0;
					map { ++$c => $_ } split /\n/, $v
					},
				    sub {
					my ($k, $v) = (shift, shift);
					return join '', @$v;
				    }
					);
    my $lines2wordcounts = $mri->mapreducer (
				    sub {
					my ($k, $v) = (shift, shift);
					return map { $_ => 1 } split /\s+/, $v;
				    },
				    sub {
					my ($k, $v) = (shift, shift);
					my $sum = 0;
					map { $sum += $_ } @$v;
					return $sum;
				    }
					    );
    my $string2wordcounts = $mri->pipeline (
					    $string2lines,
					    $lines2wordcounts
					    );
    my $A = {1 => 'this is something
this is something else
something else completely'};
    my $B = &$string2wordcounts ($A);
#    warn Dumper $B;
    is_deeply( $B, {
	             'completely' => 1,
		     'else' => 2,
		     'is' => 2,
		     'this' => 2,
		     'something' => 3
		     }, 'multiple mapreducer pipeline');
}
