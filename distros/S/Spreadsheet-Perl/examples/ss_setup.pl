
sub AddOne
{
my $ss = shift ;
my $address = shift ;

return($ss->Get($address) + 1) ;
}

#~ use Data::Dumper ;
#~ $Data::Dumper::Deparse = 1 ;
#~ print Dumper(\&AddOne) ;

DefineSpreadsheetFunction('AddOne', \&AddOne) ;

sub OneMillion
{
return(1_000_000) ;
}

#-----------------------------------------------------------------
# the spreadsheet data
#-----------------------------------------------------------------

A1 => 120, 
A3 => PerlFormula('$ss->AddOne("A1") + $ss->Sum("A1:A2")'),
A4 => sub{1},

B1 => 3,

c2 => "hi there",

D1 => OneMillion()
