use Data::Dumper;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;
PDL::Core::Dev->import();

my $fpackage = ["func.pd", Func, PDL::Fit::Levmar::Func];
my %hash = pdlpp_stdargs($fpackage);

$hash{VERSION_FROM}  = '../levmar.pd';
#$hash{OBJECT} .= '  getsymbol$(OBJ_EXT) pdlperlfunc$(OBJ_EXT) ';

$hash{OBJECT} .= '  getsymbol$(OBJ_EXT)  ';

if ( $^O !~ /mswin32/i ) {
  $hash{LIBS} = [' -lm  -ldl '];
}
else {
  $hash{LIBS} = [' -lm '];
}

$hash{clean} = {FILES => $hash{clean}->{FILES} . " " . $hash{OBJECT} .
		" *.o *.so  Func.html " };
$hash{PM} = {
                    'Func.pm' => '$(INST_LIBDIR)/Func.pm'
              };	

WriteMakefile( %hash );
sub MY::postamble {
 '
# Func.xs: pdlperlfunc$(OBJ_EXT)

' .
  pdlpp_postamble($fpackage)};
