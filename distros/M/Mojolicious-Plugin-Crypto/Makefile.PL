use 5.016002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mojolicious::Plugin::Crypto',
    VERSION_FROM      => 'lib/Mojolicious/Plugin/Crypto.pm', # finds $VERSION
    PREREQ_PM         => {
	'Mojolicious' => '4.99',
	'Crypt::CBC'  => '2.33', 
	'CryptX'      => '0.021'
    }, 
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (ABSTRACT        => 'Provide interface to various cipher algorithms', 
       AUTHOR         => 'Marco Romano <nemux@cpan.org>') : ()),
);
