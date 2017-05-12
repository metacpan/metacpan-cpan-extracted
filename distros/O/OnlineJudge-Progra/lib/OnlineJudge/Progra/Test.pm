package OnlineJudge::Progra::Test;

use Cwd;
use warnings;
use strict;

our $VERSION = '0.023';

# Simple get subroutine
sub get {
	my @foo;
	my $path = getcwd;
	
	# We create some dummy requests
	
	# accepted
	my $r1 = {
		'rid'			=> 1,
		'timelimit'		=> 1,
		'testcases'		=> 1,
		'maxscore'		=> 100,
		'lang'			=> 'pl',
		'sourcecode'	=> $path.'/t/03_judge01.pl',
		'compile'		=> 0,
		'userpath'		=> $path.'/t/usr/',
		'taskpath'		=> $path.'/t/task/',
	};
	
	# compilation error
	my $r2 = {
		'rid'			=> 1,
		'timelimit'		=> 1,
		'testcases'		=> 1,
		'maxscore'		=> 100,
		'lang'			=> 'c',
		'sourcecode'	=> $path.'/t/03_judge02.c',
		'compile'		=> 1,
		'userpath'		=> $path.'/t/usr/',
		'taskpath'		=> $path.'/t/task/',
	};
	
	# time limit
	my $r3 = {
		'rid'			=> 1,
		'timelimit'		=> 1,
		'testcases'		=> 1,
		'maxscore'		=> 100,
		'lang'			=> 'pl',
		'sourcecode'	=> $path.'/t/03_judge03.pl',
		'compile'		=> 0,
		'userpath'		=> $path.'/t/usr/',
		'taskpath'		=> $path.'/t/task/',
	};
	
	# wrong answer
	my $r4 = {
		'rid'			=> 1,
		'timelimit'		=> 1,
		'testcases'		=> 1,
		'maxscore'		=> 100,
		'lang'			=> 'pl',
		'sourcecode'	=> $path.'/t/03_judge04.pl',
		'compile'		=> 0,
		'userpath'		=> $path.'/t/usr/',
		'taskpath'		=> $path.'/t/task/',
	};
	
	# badword
	my $r5 = {
		'rid'			=> 1,
		'timelimit'		=> 1,
		'testcases'		=> 1,
		'maxscore'		=> 100,
		'lang'			=> 'pl',
		'sourcecode'	=> $path.'/t/03_judge05.pl',
		'compile'		=> 0,
		'userpath'		=> $path.'/t/usr/',
		'taskpath'		=> $path.'/t/task/',
	};
	
	
	push(@foo, $r1);
	push(@foo, $r2);
	push(@foo, $r3);
	push(@foo, $r4);
	push(@foo, $r5);
	
	return @foo;
}

# Simple update subroutine
sub update {
	my $r = shift;
		
	return $r->{'comment'};
}

1;
