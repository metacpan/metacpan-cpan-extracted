
use File::Find;

my $filter =$ARGV[0] || '.' ;

my $deepest_path = '' ;
my $deepest = -1 ;

finddepth(\&wanted, '.');

print "$deepest_path\n" ;

sub wanted 
{
my $depth = $File::Find::name =~ tr[/][/] ;

if($File::Find::name =~ /$filter/o  && $depth > $deepest)
	{
	$deepest = $depth ;
	$deepest_path = $File::Find::name ;
	}
}
	    
