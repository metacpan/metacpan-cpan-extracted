print "starting...";

use Perl6::Placeholders;

my $add = { $^a + $^b };

@data{0..10} = ('A'..'Z');

print $add->(1,2), "\n";

print join ",", sort { $^y <=> $^x } 1..10;            print "\n=======\n";
print join "\n", map { $^value**2 } 1..10;             print "\n=======\n";
print join "\n", map { $data{$_-1}.$^value**2 } 1..10; print "\n=======\n";
print join "\n", map { $data{$^value} } 1..10;         print "\n=======\n";
