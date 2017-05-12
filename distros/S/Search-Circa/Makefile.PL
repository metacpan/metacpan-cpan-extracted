use ExtUtils::MakeMaker;

my %make = 
  (
   'NAME'	  => 'Search::Circa',
   'VERSION_FROM' => 'lib/Search/Circa.pm', # finds $VERSION
   'PL_FILES'     => { 'demo/CircaConf.PL' => 
     [ '../blib/lib/CircaConf.pm',
       'demo/circa_admin',
       'demo/circa_search',
       'demo/circa_annuaire',
       'demo/cgi-bin/search.cgi',
       'demo/cgi-bin/admin.cgi',
       'demo/cgi-bin/admin_compte.cgi'
     ]
    },
   'PREREQ_PM'    =>
   {
    'Test::Simple'  => 0,
    'DBI'           => 0,
    'DBD::mysql'    => 0 ,
    'URI::URL'      => 0 ,
    'LWP::RobotUA'  => 0,
   },
   'EXE_FILES'         => [ 'demo/circa_admin',
			     'demo/circa_search',
			     'demo/circa_annuaire' ],
   'clean' => { FILES => "*~ lib/Search/Circa/*~ lib/Search/*~ ".
		"demo/circa_admin demo/circa_search demo/circa_annuaire ".
		"lib/CircaConf.pm demo/cgi-bin/*.cgi demo/*~ demo/cgi-bin/*~".
		".m .t"},
   ($] ge '5.005') ?
   (
    'AUTHOR' => 'Alain BARBET (alian@alianwebserver.com)',
    'ABSTRACT' => 'Circa - a Search Engine/Indexer running with Mysql'
   )
   : ());

print "--- Module Search-Circa - a www search engine ---
You will be prompted for his configuration:
(You need Apache & Mysql running for advanced tests)\n\n";

my $user = prompt("1/ Which Mysql user you want use ?","root"); #$ENV{USER});
my $pass = prompt("2/ Mysql password for this user ?");
my $host = prompt("3/ On which host mysql run ?","localhost");
my $db = prompt("4/ On which database on $host you want to install Circa ?",
		"circa");
my $tmp = prompt("5/ Directory where put files on import/export ?","/tmp");
my $tes = prompt("6/ Did you want to do advanced tests ? ".
		 "(others than load tests)","no");
if ($tes =~ m/^y(es)?$/i) {
  my $dbt = prompt("6b/ On which database did you want to do advanced tests ?",
                   "test");
  open(F,">.t"); print F $dbt; close(F);
}
my $root_access = prompt("7/ Did you have write access to install perl ".
			 "modules on standard directory ? \n".
			 "(else I need put use lib 'something' in [.pl|.cgi]".
			 " files)", "yes");
my $path;
if ($root_access !~ m/^y(es)?$/i) {
  $path = prompt("7b/ Where did you plan to install Circa ?", 
		 "$ENV{HOME}/circa");
 $make{PREFIX} = $path;
 $make{INSTALLSITELIB}=$path."/lib";
}
my $template = prompt("8/ Where you want put HTML templates files ?",
		      "$ENV{HOME}/circa/templates");

my $httpd_conf = &tryfind_httpd;
$httpd_conf = prompt("9/ Where I can find your httpd.conf ?", $httpd_conf);
my $cgidir= &tryfind_cgidir($httpd_conf) || $path."/cgi-bin/circa/";
my $htdocs = &tryfind_htdocsdir($httpd_conf) || $path."/html/";
if ($httpd_conf) {
  $cgidir = prompt("10/ Where I can install Circa cgi ?", $cgidir);
  $htdocs = prompt("11/ Where I can install Circa html docs ?", $htdocs);
}
open(FILE,">.m") || warn "Can't create .m for test: $!\n";
print FILE $user,"\t",$pass,"\t",$host,"\t",$db,"\t",$tmp,"\t",$template,
  "/\t",$path;
close FILE;

WriteMakefile(%make);

print "***\n*** Remember: \n*** 1/ If you want update later Circa",
       " configuration,\n",
      "*** edit $make{PREFIX}/lib/CircaConf.pm.\n",
      "*** 2/ After make install, do make cgi.\n***\n";

sub tryfind_httpd {
  my $l;
  if (!$ENV{APACHE} || !-x $ENV{APACHE}) {
    my @l = `ps ax|grep httpd >&1`;
    @l = `ps -fe|grep httpd >&1` if (!@l or $#l==1);
    @l = `locate httpd | grep 'bin/httpd' >&1` if (!@l or $#l==1);
    @l = `locate httpd | grep 'sbin/httpd' >&1` if (!@l);
    $l = join('',@l);
  }
  else { $l= $ENV{APACHE}; }
  if ($l=~m!(/.*/httpd)!) {
    my $bin = $1;
    my @l2 = `$1 -V`;
    my ($root, $conf);
    foreach (@l2) {
      $root = $1 if (/HTTPD_ROOT="(.*)"/);
      $conf = $1 if (/SERVER_CONFIG_FILE="(.*)"/);
    }
    return $root.'/'.$conf if ($root && $conf);
  }
}

sub tryfind_cgidir {
  my $httpconf = shift;
  return if (!$httpconf);
  my $s = "more $httpconf | grep 'ScriptAlias /cgi-bin/' >&1";
  my $l = `$s`;
  if ($l=~m!ScriptAlias[\s\t]*/cgi-bin/[\s\t]*"(.*)"!) {
    return $1."circa/";
  }
}


sub tryfind_htdocsdir {
  my $httpconf = shift;
  return if (!$httpconf);
  my $s = "more $httpconf | grep 'DocumentRoot' >&1";
  my $l = `$s`;
  if ($l=~m!DocumentRoot[\s\t]"(.*)"!) {
    return $1."/circa/";
  }
}

sub MY::postamble {
  "cgi:all
\t".'@echo "Install cgi in '.$cgidir.'"'."
\t\@mkdir -p $cgidir
\t\@cp demo/cgi-bin/search.cgi $cgidir
\t\@cp demo/cgi-bin/admin_compte.cgi $cgidir
\t\@cp demo/cgi-bin/admin.cgi $cgidir
\t\@chmod 755 $cgidir/*.cgi
\t\@if [ ! -e \"$template\" ] ; then \\
\t\tmkdir -p $template; \\
\tfi; \
\t\@cp demo/ecrans/*.htm $template
\t\@if [ ! -e \"$htdocs\" ] ; then \\
\t\tmkdir -p $htdocs; \\
\tfi; \
\t\@cp demo//*.html $htdocs
\t\@if [ ! -e \"$htdocs/images\" ] ; then \\
\t\tmkdir -p $htdocs/images; \\
\tfi; \
\t\@cp demo//images/*.gif $htdocs/images
\t\@if [ ! -e \"$htdocs/php3\" ] ; then \\
\t\tmkdir -p $htdocs/php3; \\
\tfi; \
\t\@cp demo//php3/*.php3 $htdocs/php3
\t\@echo \"Lauch your browser on http://localhost/cgi-bin/circa/admin.cgi\"
";
}
