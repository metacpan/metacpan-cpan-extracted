use ExtUtils::MakeMaker;

WriteMakefile(
  ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
  license( 'perl' ),
  NAME          => 'RTF::HTML::Converter::API',
  AUTHOR        => 'Lee Goddard <lgoddard@cpan.org>',
  VERSION		=> '0.1',
  ABSTRACT_FROM => 'lib/RTF/HTML/Converter/API.pm',
  PL_FILES      => {},
  PREREQ_PM     => {
	'RTF::HTML::Converter'	=> 0,
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'RTF-HTML-Converter-API-*' },
);


sub license {
  my $lic = shift;
  local $^W = 0;    # Silence warning about non-numeric version
  return
   unless $ExtUtils::MakeMaker::VERSION >= '6.31';
  return ( LICENSE => $lic );
}




