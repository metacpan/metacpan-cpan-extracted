use ExtUtils::MakeMaker;
use 5.004;

my @ppd;

if ($] >= 5.00503) {
  @ppd = (
    AUTHOR    => 'Arun Kumar U <u_arunkumar@yahoo.com>',
    ABSTRACT  => 'A global registry for objects',
  );
}

WriteMakefile
(
	'NAME'	       => 'Object::Registrar',
	'VERSION_FROM' => 'lib/Object/Registrar.pm', # finds $VERSION
	'PREREQ_PM'    => { 'Error' => 0 },
	@ppd
);

sub MY::postamble {

  return '' unless $] >= 5.00503;

<<'ESQ';

dist : ppd

ESQ
}

