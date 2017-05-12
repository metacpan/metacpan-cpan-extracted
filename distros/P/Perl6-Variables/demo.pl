use Perl6::Variables;

sub show {
	print @_[0], @_[1..$#_], "\n";
}

my %hash = (a=>1, b=>2, z=>26);

my @array = (0..10);

my $arrayref = \@array;
my $hashref = \%hash;

show %hash;
show @array;
show $hashref;
show $arrayref;

show %hash{a};
show %hash{a=>'b'};
show %hash{'a','z'};
show %hash{qw(a z)};

show @array[1];
show @array[1..3];
show @array[@array];

show $hashref{a};
show $hashref{a=>'b'};
show $hashref{'a','z'};
show $hashref.{qw(a z)};

show $arrayref[1];
show $arrayref[1..3];
show $arrayref.[@array];
