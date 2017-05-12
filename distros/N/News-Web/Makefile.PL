use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $modules = {};  my $manpage = {};
foreach my $module ( 
   	qw( News::Web News::Web::CookieAuth ) ) {
  my $file = $module;
     $file =~ s/::/\//g;  
     $file =~ s/$/.pm/;
  my $shortfile = $file;  $shortfile =~ s%^News/%%;
  my $libdir = join('/', '$(INST_LIBDIR)', $shortfile);
  my $man3 = join('/', '$(INST_MAN3DIR)', "$module.3");
  $$modules{$file} = $libdir; $$manpage{$file} = $man3;
}

WriteMakefile(
    'NAME'	   => 'News::Web',
    'DISTNAME'     => 'News-Web',
    'MAN3PODS'     => $manpage,
    'VERSION_FROM' => 'Version.pm', # finds $VERSION
    'PREREQ_PM'    => { 'News::Article' => 1.27, 'Net::NNTP' => 2.19,
			'Net::Domain' => 2, 'News::Overview' => 0.11, },
    'PM'	   => $modules,
    'EXE_FILES'    => [ qw( news.cgi setcookie.cgi ) ],
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
