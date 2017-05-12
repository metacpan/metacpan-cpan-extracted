use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'Net::Whois::Proxy',
    'VERSION_FROM' => 'lib/Net/Whois/Proxy.pm', # finds $VERSION 
    'dist' => { COMPRESS => "gzip", SUFFIX=>"gz" },
    ($] ge '5.005')
        ? (
            'AUTHOR' => 'Colin Faber <cfaber@fpsn.net>',
            'ABSTRACT' => 'Recursive whois library',
           )
         : (),
    
);

sub MY::test {
  package MY;
  my $make = shift->SUPER::test();
  $make =~ s/(PERL_DL_NONLAZY)=1/$1=0/g;
  return $make;
}
