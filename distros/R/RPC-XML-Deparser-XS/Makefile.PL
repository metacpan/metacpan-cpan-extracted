	use 5.008003;
use ExtUtils::MakeMaker;
use inc::ExtUtils::MY_Metafile qw(my_metafile);

require 'glib2_config.pl';
my $GLIB2 = glib2_config();

my %requires = (
  'RPC::XML'        => 0,
);
my %build_requires = (
  'IPC::Run'        => 0,
  'Test::Exception' => 0,
  'Test::More'      => 0,
);
my_metafile('RPC::XML::Deparser::XS' => {
  requires       => \%requires,
  build_requires => \%build_requires,
  license        => 'Perl',
});

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'RPC::XML::Deparser::XS',
    VERSION_FROM      => 'lib/RPC/XML/Deparser/XS.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
        %requires,
        %build_requires,
       },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/RPC/XML/Deparser/XS.pm', # retrieve abstract from module
       AUTHOR         => 'Hidden <hidden@example.net>') : ()),
    LIBS              => $GLIB2->{LIBS}, # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. $GLIB2->{CFLAGS}",
    OBJECT            => '$(O_FILES)', # link all the C files too
);
