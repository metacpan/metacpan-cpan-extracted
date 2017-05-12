#!perl -w

use strict;

use Ruby -all;

$| = 1; # autoflush

use Ruby -eval => <<'.';
def make_thread_ruby(id)

Thread.new{
	5.times{|i|
		puts(" " * id + "Ruby: \##{id} #{i}");
		Thread.pass;
	}
	"Tread(#{id}) done";
}
end
.

sub make_thread_perl{
	my $id = shift;

	Thread->new(sub{
		5->times(sub{
			my $i = shift;
			puts " " x $id . " Ruby: $id $i";
		});
		return "Thread($id) done.";
	});
}

#*make_thread = \&make_thread_perl; # doesn't work
*make_thread = \&make_thread_ruby;

my $thr1 = make_thread(1);
my $thr2 = make_thread(2);
my $thr3 = make_thread(3);
my $thr4 = make_thread(4);
my $thr5 = make_thread(5);

foreach (0 .. 9){
	puts("Perl: <MAIN> $_");

	Thread->pass; # This is required!
}

puts $thr1->join->value;
puts $thr2->join->value;
puts $thr3->join->value;
puts $thr4->join->value;
puts $thr5->join->value;


