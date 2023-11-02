# even the old version is guaranteed not to work
# with anything earlier than 5.008.

use v5.34.1;
use ExtUtils::MakeMaker;

my $version    = v0.1.0;

WriteMakefile
(
    qw
    (
        NAME            Object::Lvalue
        LICENSE         perl
    ),
  , VERSION				=> v0.1.0
  , AUTHOR				=> 'Steven Lembark <lembark@wrkhors.com>',
  , PREREQ_PM =>
    {
    	qw
    	(
    		Carp				0
    		List::Util			0
    		Scalar::Util		0
    		Sub::Name			0
    		Storable			0
    		Symbol				0
    	)
    }
  , CONFIGURE_REQUIRES =>
    {
    	qw
    	(
    		FindBin::libs		0
    		List::Util			0
    		Test::More			0
    	)
    }
);

__END__
