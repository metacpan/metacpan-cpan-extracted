use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $modules = {};  my $man3page = {};
foreach my $module ( 
   	qw( News::Archive News::Active News::Active::Entry 
	    News::GroupInfo News::GroupInfo::Entry News::Article::Mbox ) ) {
  my $file = $module;
     $file =~ s/::/\//g;  
     $file =~ s/$/.pm/;
  my $shortfile = $file;  $shortfile =~ s%^News/%%;
  my $libdir = join('/', '$(INST_LIBDIR)', $shortfile);
  my $man3 = join('/', '$(INST_MAN3DIR)', "$module.3");
  $$modules{$file} = $libdir; $$man3page{$file} = $man3;
}
$$man3page{'kibozerc.pod'} = join('/', '$(INST_MAN3DIR)', "kibozerc.3");

my $man1page = {};
foreach my $script ( qw( kiboze.pl mbox2news.pl ) ) {
  my $man1 = join('/', '$(INST_MAN1DIR)', "$script.1");
  $$man1page{$script} = $man1;
}

WriteMakefile(
    'NAME'	   => 'News::Archive',
    'DISTNAME'     => 'News-Archive',
    'MAN3PODS'     => $man3page,
    'MAN1PODS'	   => $man1page,
    'VERSION_FROM' => 'Version.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Net::NNTP::Functions' => 0.21,
			'News::Article' => 1.27, 'Net::NNTP' => 2.19,
			'Mail::Mbox::MessageParser' => 1.14, 
			'News::Newsrc' => 1.08,
			'News::Overview' => 0.11, 'News::Web' => 0.51,
		  	'Date::Parse' => 0 },
    'PM'	   => $modules,
    'EXE_FILES'    => [ qw( nnparse mbox2news.pl kiboze.pl newsrecurse.pl ) ],
    'dist' => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);
