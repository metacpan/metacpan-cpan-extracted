use strict;
use warnings;
use PDL::Core::Dev;
use ExtUtils::MakeMaker;

my $fpackage = [qw(func.pd Func PDL::Fit::Levmar::Func), undef, 1];
my %hash = pdlpp_stdargs($fpackage);
$hash{OBJECT} .= '  getsymbol$(OBJ_EXT)  ';
$hash{LIBS}[0] .= ' -lm';
$hash{LIBS}[0] .= ' -ldl' if $^O !~ /mswin32/i;
$hash{clean}{FILES} .= " $hash{OBJECT} *.o *.so";

undef &MY::postamble;
*MY::postamble = sub { pdlpp_postamble($fpackage) };
WriteMakefile( %hash );
