
use Carp ;
use strict ;
use warnings ;
use Data::TreeDumper ;

use Spreadsheet::Perl ;

tie my %ss, "Spreadsheet::Perl", NAME => 'TEST' ;
my $ss = tied %ss ;

my $variable = 25 ;
my $struct = {something => 'hello world'} ;

# test 1
#~ $ss{A1} = Ref('', \$variable) ;
#~ $ss{A2} = PerlFormula('$ss{A1}') ;

#~ print "$ss{A1} $ss{A2}\n" ;

#~ $ss{A1} = 52 ;

#~ print "\$variable = $variable\n" ;

# test 2
#~ $ss{A1} = Ref('', \($struct->{something})) ;

#~ print $ss->Dump() ;
#~ print "$ss{A1} $ss{A1}\n" ;

#~ $ss{A1} = 52 ;

#~ print DumpTree($struct, 'Struct') ;

#~ print "$ss{A1} $ss{A1}\n" ;

#~ print $ss->Dump() ;

# test 3
#~ $ss{A1} = Ref('', \($struct->{something})) ;

#~ print "$ss{A1}\n" ;
#~ print $ss->Dump() ;

# test 4
$ss->Ref
	(
	  'Testing Ref for more than one value'
	, A1 => \($struct->{something})
	, A2 => \$variable
	, 'A3:A5' => \$variable
	) ;

$ss{A2} = "123" ;
delete $ss{A2} ;

$ss{A3} = "125" ;

print $ss->Dump(undef, 0, {DISPLAY_ADDRESS => 1}) ;

print "$ss{A2} $ss{A3}\n" ;
print "\$variable = $variable\n" ;

print $ss->Dump(undef, 0, {DISPLAY_ADDRESS => 1}) ;

# test X, should generates an error as of 0.04
#~ $ss{A1} = Ref($struct) ;
