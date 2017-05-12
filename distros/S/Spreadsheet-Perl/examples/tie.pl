
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

%ss = 
	(
	  A1 => 1
	, A2 => FetchFunction('always 1', sub{1})
	, A3 => PerlFormula('$ss->Sum("A1:A2")') 
	
	, B1 => 3
	, c2 => "hi there"
	) ;

print $ss->Dump() ;
print "\$ss{A3} = $ss{A3}\n" ;


%ss = do "ss_setup.pl" or confess("Couldn't evaluate setup file 'ss_setup.pl'\n");
print "From Do:\n" ;
print $ss->Dump() ;

print "\$ss{A3} = $ss{A3}\n" ;

print "keys:" . join(', ', keys %ss) . "\n" ;

print "A5 exists\n" if exists $ss{A5} ;
print "B5 doesn't exists\n" unless exists $ss{B5} ;
$ss{B5}++ ;
print "B5 exists\n" if exists $ss{B5} ;

%ss = () ;
print "keys:" . join(', ', keys %ss) . "\n" ;

@ss{'A1', 'B1:C2', 'A8'} = ('A', 'B', 'C');
print $ss->Dump() ;

# range fetching
#~ print $ss->Dump(undef, 1) ;
#~ $ss->{DEBUG}{FETCH}++ ;
#~ $ss->{DEBUG}{ADDRESS_LIST}++ ;

#~ # data is encapsulated in an array as Fetch forces scalar context
#~ my $array_with_values =$ss{'A1:A3'} ;
#~ my ($a, $b, $c) = @$array_with_values ;
#~ print "$a, $b, $c \n" ;

#~ #slice access
#~ $ss->{DEBUG}{FETCH}++ ;
#~ print Dumper(@ss{'C1:C2', 'A1:A3'}) . "\n" ; 
#~ print $ss->Dump(undef, 1) ;

#~ #slice access
#~ $ss->{DEBUG}{STORE}++ ;
#~ @ss{'C1:C2', 'A1:A3'} = (5, 10) ;
#~ print $ss->Dump(undef, 1) ;

#~ @ss{$ss->GetAddressList('A1:A3')} = (1 .. 3) ;
#~ print $ss->Dump(undef, 1) ;


