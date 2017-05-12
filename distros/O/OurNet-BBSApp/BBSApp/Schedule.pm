package OurNet::BBSApp::Schedule;
use vars qw/@tasklist %taskid/;
use strict;

sub refresh {
    (@tasklist && $tasklist[0]->{time} <= time());
}

sub add {
    my $ttask = shift;
    push @tasklist, $ttask;
    resort();
}

sub resort {
    @tasklist = sort {$a->{time} cmp $b->{time}} @tasklist;
}

sub process {
    while(@tasklist && $tasklist[0]->{time} <= time()) {
	my $ttask = shift @tasklist;
	&{$ttask->{func}} unless $ttask->{remove};
    }
}

1;
