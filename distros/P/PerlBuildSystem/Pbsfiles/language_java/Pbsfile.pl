
use Inline Java => <<'END_OF_JAVA_CODE' ;
class Pbsfile
{

public Pbsfile() {}

public void AddPbsConstructs()
	{
	}
}   
END_OF_JAVA_CODE

my $pbs = (__PACKAGE__ . "::Pbsfile")->new ;

$pbs->AddPbsConstructs() ;
