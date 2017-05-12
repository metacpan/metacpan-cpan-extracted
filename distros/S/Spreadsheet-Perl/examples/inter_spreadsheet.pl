
use Carp ;
use strict ;
use warnings ;

use Spreadsheet::Perl ;
use Spreadsheet::Perl::Arithmetic ;

tie my %romeo, "Spreadsheet::Perl" ;
my $romeo = tied %romeo ;
$romeo->SetName('ROMEO') ;
#~ $romeo->{DEBUG}{SUB}++ ;
$romeo->{DEBUG}{INLINE_INFORMATION}++ ;
#~ $romeo->{DEBUG}{ADDRESS_LIST}++ ;
#~ $romeo->{DEBUG}{FETCH_FROM_OTHER}++ ;
$romeo->{DEBUG}{PRINT_DEPENDENT_LIST}++ ;
$romeo->{DEBUG}{DEPENDENT_STACK_ALL}++ ;
#$romeo->{DEBUG}{DEPENDENT_STACK}{A2}++ ;
$romeo->{DEBUG}{DEPENDENT}++ ;
$romeo->{DEBUG}{MARK_ALL_DEPENDENT}++ ;

my $juliette = tie my %juliette, "Spreadsheet::Perl", NAME => 'JULIETTE' ;
#~ $juliette->{DEBUG}{SUB}++ ;
$juliette->{DEBUG}{INLINE_INFORMATION}++ ;
#$juliette->{DEBUG}{PRINT_FORMULA}++ ;
#~ $juliette->{DEBUG}{DEFINED_AT}++ ;
#~ $juliette->{DEBUG}{ADDRESS_LIST}++ ;
#~ $juliette->{DEBUG}{FETCH_FROM_OTHER}++ ;
$juliette->{DEBUG}{PRINT_DEPENDENT_LIST}++ ;
$juliette->{DEBUG}{DEPENDENT_STACK_ALL}++ ;
$juliette->{DEBUG}{DEPENDENT}++ ;
$juliette->{DEBUG}{MARK_ALL_DEPENDENT}++ ;

$romeo->AddSpreadsheet('JULIETTE', $juliette) ;
$juliette->AddSpreadsheet('ROMEO', $romeo) ;

$romeo{'B1:B2'} = 10 ;

$juliette{A1} = 5 ;
$juliette{A2} = PerlFormula('$ss->Sum("ROMEO!B1:B2") + $ss{"ROMEO!A2"} + $ss{"ROMEO!A1"}') ; 
#$juliette{A2} = PerlFormula('$ss->Sum("ROMEO!B1:B2")') ; 

$romeo{A1} = PerlFormula('$ss->Sum("JULIETTE!A1:A2", "A2")') ;
$romeo{A2} = 100 ;
$romeo{A3} = PerlFormula('$ss{A2}') ;

#use Data::TreeDumper ;
#my $dependencies = $juliette->GetAllDependencies('A5', 1) ;
#my $title = shift @{$dependencies} ;
#print DumpTree($dependencies, $title, DISPLAY_ADDRESS => 0) ;

#$romeo->Recalculate() ; #update dependents
#print $romeo->DumpTable() ;

print "Calling Recaculate()\n" ;
$romeo->Recalculate() ; #update dependents
$juliette->Recalculate() ; #update dependents
#~ # or 
#~ print <<EOP ;  # must access to update dependents
#~ \$romeo{A1} = $romeo{A1}
#~ \$romeo{A3} = $romeo{A3}

#~ EOP

# we don't want debug output generated while dumping the 
# spreadsheet to the table
delete $romeo->{DEBUG}{DEPENDENT_STACK_ALL} ;
delete $juliette->{DEBUG}{DEPENDENT_STACK_ALL} ;

#use Text::Table ;
#my $table = Text::Table->new() ;
#$table->load
#	(
#	[
print $romeo->DumpTable(undef, undef, {headingText => 'Romeo'}) ;
print $juliette->DumpTable(undef, undef, {headingText => 'Juliette'}) ;
#]
#	);
#print $table ;


#print $juliette->DumpTable(undef, undef, {headingText => 'Juliette'}) ;
#print $romeo->Dump(undef,1) ;

$romeo{A2} = 0 ; # A1 and A3 need update now
#~ $juliette{A1}++ ; # ROMEO!A1 needs update now

#print $romeo->Dump(undef,1) ;
#print $juliette->Dump(undef,1) ;

__END__

print $romeo->DumpTable(undef, undef, {headingText => 'Romeo'}) ;
print $juliette->DumpTable(undef, undef, {headingText => 'Juliette'}) ;

# inter ss cycles
#$juliette{A3} = PerlFormula('$ss->Sum("ROMEO!A1")') ;  ;

#$juliette{A3} ; # void context, generates warning

