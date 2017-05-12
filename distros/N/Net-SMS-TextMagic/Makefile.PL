use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Net::SMS::TextMagic',
    VERSION_FROM      => 'lib/Net/SMS/TextMagic.pm', # finds $VERSION
    BUILD_REQUIRES    => { Test::Exception => 0.27 }, # e.g., Module::Name => 1.1
    PREREQ_PM         => { JSON => 0,
                           LWP::UserAgent => 0,
                           URI::Escape => 0,
                           Encode => 0,
                           Crypt::SSLeay => 0
                         },
    MIN_PERL_VERSION  => 5.008006,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT       => 'Provides access to TextMagic SMS service API',
       AUTHOR         => 'Matti Lattu <matti@lattu.biz>') : ()),
);
