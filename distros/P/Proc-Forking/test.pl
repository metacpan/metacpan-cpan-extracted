# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Proc::Forking;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script
$| = 1;

print "1..4\n";

use Forking;
$new= Proc::Forking->new;
($status,$pid,$error)  = $new->fork_child(function => sub { for ( 1..2){$nbr++;sleep 1;}} );

wok($status,$error);

while(($new->pid_nbr) >1){
print "pending process=$_\n";
wait();
}


($status,$pid,$error) =$new->fork_child(function =>sub { exit $_[0] },
			home => "/tmp");

wok($status,$error);

($status,$pid,$error) =$new->fork_child(function => \&func1, name=>'test');

wok($status,$error);

($status,$pid,$error)  =$new->fork_child(function =>\&func2);

wok($status,$error);

sub func1
{
        open $tmp, ">>/tmp/test.log";
	for (1..5){
	    print $tmp "In test loop $_\n";
	}
	close $tmp;
}

sub func2
{
	open $tmp, "/tmp/test.log";
	undef $/;
        $data = <$tmp>;
        close $tmp;
        print $data;
        $data =~ s/In test loop / /g;
	$data =~ s/\n/+/g;
	$data.=0;
	print eval $data;
	print "=15\n";
        unlink "/tmp/test.log";      
}


sub wok
{
	my ($stat,$ws) = @_;
        
        wait();
      
        print($stat ? "not ok $ws\n" : "ok $ws\n");
}
