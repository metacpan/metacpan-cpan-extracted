use Parse::Template;

my %ancestor = 
  (
   'ANCESTOR' => q!%%"ANCESTOR/$part ->" . SUB_PART()%%!,
   'SUB_PART' => q!ANCESTOR/ %%"$part\n"%%!,
  );

my %child = 
  (
   'CHILD' => q!CHILD/ %%"$part"%% -> %%ANCESTOR()%%!,
   'SUB_PART' => q!CHILD/ %%"$part\n"%%!,
  );
my $A = new Parse::Template (%ancestor);
my $C = $A->new(%child);

#print '$A->ANCESTOR(): ', $A->ANCESTOR();
#print '$C->SUB_PART(): ', $C->SUB_PART();

print '$A->ANCESTOR(): ', 	$A->ANCESTOR();
print '$C->CHILD(): ', 		$C->CHILD();
print '$C->SUB_PART(): ', 	$C->SUB_PART();

#print '$C->ANCESTOR(): ', $C->ANCESTOR();
#print '$C->SUB_PART(): ', $C->SUB_PART();

exit;
# ???
print '$C->ANCESTOR() ', $C->ANCESTOR();
print '$C->CHILD()', $C->CHILD();
print '$C->SUB_PART()', $C->SUB_PART();
print $A->ANCESTOR();
print '$C->CHILD()', $C->CHILD();
print $C->ANCESTOR();
print $A->ANCESTOR();
print $C->ANCESTOR();
print $C->CHILD();
print $A->SUB_PART();
print $C->CHILD();

__END__
$A->ANCESTOR(): ANCESTOR/ANCESTOR ->ANCESTOR/ SUB_PART
$C->CHILD(): CHILD/ CHILD -> ANCESTOR/ANCESTOR ->CHILD/ SUB_PART


