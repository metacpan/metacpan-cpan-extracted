use Data::Dumper;
use syntax qw/qwa/;

# Lookup table
my $days = qwk(Mon Tue Wed Thu Fri Sat Sun);

# The task is to sort these days into their weekly order
my @list = qw(Fri Tue Wed);

my @sorted_list = sort { $days->{$a} <=> $days->{$b} } @list;
print Dumper \@sorted_list;
