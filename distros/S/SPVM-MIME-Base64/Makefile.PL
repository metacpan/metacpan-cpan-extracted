use 5.032001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'SPVM::MIME::Base64',
    VERSION_FROM      => 'lib/SPVM/MIME/Base64.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/SPVM/MIME/Base64.pm', # retrieve abstract from module
    AUTHOR            => 'A. U. Thor <kimoto@vs.sakura.ne.jp>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #https://metacpan.org/pod/Module::Build::API
    # SPVM::Builder::Util::API is needed for Makefile.PL
    CONFIGURE_REQUIRES => {
      'SPVM'              => '0.9634_01',
  },
);
sub MY::postamble {
  
  use SPVM::Builder::Util::API;
  
  my $make_rule = "";
  
  # Native compile make rule
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native("MIME::Base64");

  # Native compile make rule
  $make_rule .= SPVM::Builder::Util::API::create_make_rule_native("MIME::QuotedPrint");

  return $make_rule;
}
