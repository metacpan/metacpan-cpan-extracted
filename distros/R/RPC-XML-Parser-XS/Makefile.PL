	use 5.008003;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

require 'libxml2_config.pl';
my $LIBXML2 = libxml2_config();

my %requires = (
  'MIME::Base64'    => 0,
  'RPC::XML'        => 0,
);
my %build_requires = (
  'IPC::Run'        => 0,
  'Test::Exception' => 0,
  'Test::More'      => 0,
);
my_metafile('RPC::XML::Parser::XS' => {
  requires       => \%requires,
  build_requires => \%build_requires,
  license        => 'Perl',
});

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RPC::XML::Parser::XS',
    VERSION_FROM      => 'lib/RPC/XML/Parser/XS.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
        %requires,
        %build_requires,
       },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RPC/XML/Parser/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Hidden <hidden@example.net>') : ()),
    LIBS              => $LIBXML2->{LIBS}, # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => $LIBXML2->{CFLAGS}, # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
