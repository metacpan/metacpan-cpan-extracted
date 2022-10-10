#!/usr/bin/perl

use Test::More tests => 6;
use Schedule::Cron;
use strict;
#!/usr/bin/perl

use Schedule::Cron;
use Data::Dumper;

my $CALLED = {};

# Create new object with default dispatcher
my $scheduler = Schedule::Cron->new( sub { 
                                         warn "unknown action"; 
                                     });

my $other = sub { $CALLED->{OTHER}++ };

my $sec = (localtime)[0];

my $e = entry(2,3,4);

my $tasknum = 0;
my $do = sub {  
    $CALLED->{DO}++;
    if ($tasknum < 2) {
#        print "adding something\n";
        my $string = "task" . $tasknum ."\n";
        $scheduler->add_entry($e, { subroutine => &task($tasknum + 1)}); 
        $tasknum++; 
    } 
};
	

sub task {
    my $num = shift;
    return sub {
        $CALLED->{"T" . $num}++;
    };
}
#print $e,"\n";;
$scheduler->add_entry($e, { subroutine => $do });
$scheduler->add_entry($e, { subroutine => $other });
$scheduler->add_entry(entry(5), { subroutine => sub { die "E1\n" }});

eval {
    $scheduler->run({ nofork => 1 });
};
is($@,"E1\n","Finished by last action");
ok($CALLED->{DO} > 0,'$do called ' . $CALLED->{DO});
ok($CALLED->{OTHER} > 0,'$other called ' . $CALLED->{OTHER});
ok($CALLED->{T1} > 0,"T1 called");
ok($CALLED->{T2} > 0,"T2 called");
is($CALLED->{DO},$CALLED->{OTHER}, '$do and $other are the same');
#print Dumper($CALLED);

sub entry {
    return "* * * * * " . join (",",map { ($sec + $_) % 60 } @_);
}
