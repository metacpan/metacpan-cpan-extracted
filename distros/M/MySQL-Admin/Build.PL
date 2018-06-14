use strict;
use utf8;
use vars qw ( $m_hrSettings $skip $cwd $prefix );
use Module::Build;
my $class = Module::Build->subclass(
                                    class => 'Module::Build::Custom',
                                    code  => <<'END');
use vars qw($m_hrSettings $cwd);
use File::Copy;
use File::Path;
use Cwd;
$cwd = cwd;
my $release = "$cwd/blib/rhtml/";
my $dir     = "$cwd/htdocs/";
my $path    = '.';

loadSettings("$cwd/cgi-bin/config/settings.pl");

sub ACTION_build
{
    my $self = shift;
    mkpath($release);
    &change($dir);
    $release = "$cwd/blib/perl/";
    $dir     = "$cwd/cgi-bin/";
    mkpath($release);
    &change($dir);
    $self->SUPER::ACTION_build;
    my $cgiBin = $m_hrSettings->{cgi}{bin}=~/\/$/ ? $m_hrSettings->{cgi}{bin} :$m_hrSettings->{cgi}{bin}.'/';
    &replace('%PATH%', $cgiBin, "$cwd/blib/perl/mysql.pl");
    &replace('%PATH%', $cgiBin, "$cwd/blib/perl/install.pl");
    &replace('%PATH%', $cgiBin, "$cwd/blib/perl/menu.pl");
    &replace('%PATH%', $cgiBin, "$cwd/blib/perl/translate.pl");
    &replace('%PATH%', $cgiBin, "$cwd/blib/perl/rss.pl");
    if($^O eq 'MSWin32'){
        &replace('#!/usr/bin/perl', '#!perl', "$cwd/blib/perl/mysql.pl");
        &replace('#!/usr/bin/perl', '#!perl', "$cwd/blib/perl/translate.pl");
        &replace('#!/usr/bin/perl', '#!perl', "$cwd/blib/perl/menu.pl");
        &replace('#!/usr/bin/perl', '#!perl', "$cwd/blib/perl/install.pl");
    }
    if(-e "$cwd/extra/startup.pl"){
        copy("$cwd/extra/startup.pl", "$cwd/blib/perl/config/startup.pl") or die "Copy failed: $cwd/extra/startup.pl $!";
    }
    if(-e "$cwd/extra/mysql-admin.conf"){
        copy("$cwd/extra/mysql-admin.conf", "$cwd/blib/perl/config/mysql-admin.conf") or die "Copy failed: $cwd/extra/mysql-admin.conf $!";
    }
    &replace('%PATH%',     "$cgiBin","$cwd/blib/perl/config/startup.pl");
    &replace('%host%',     "$m_hrSettings->{cgi}{serverName}", "$cwd/blib/perl/config/startup.pl");
    &replace('%CONFIG%',   "$cwd/t/config.pl","$cwd/blib/lib/MySQL/Admin/Config.pm");
    &replace('%CONFIG%',   "$cwd/t/translate.pl","$cwd/blib/lib/MySQL/Admin/Translate.pm");
    &replace('%CONFIG%',   "$cwd/t/settings.pl","$cwd/blib/lib/MySQL/Admin/Settings.pm");
    &replace('%CONFIG%',   "$cwd/t/session.pl","$cwd/blib/lib/MySQL/Admin/Session.pm");
    &replace('%CONFIG%',   "$cwd/t/actions.pl","$cwd/blib/lib/MySQL/Admin/Actions.pm");
    &replace('%CONFIG%',   "$cwd/t/settings.pl","$cwd/blib/lib/MySQL/Admin.pm");
    &replace('%CONFIG%',   "$cwd/t/settings.pl","$cwd/blib/lib/Template/Quick.pm");
    &replace('%DATABASE%', "$m_hrSettings->{database}{name}","$cwd/blib/lib/DBI/Library.pm");   
    &replace('%MODPERL%',  $m_hrSettings->{mod} ? 'true' :'false' , "$cwd/blib/rhtml/javascript/mysql_admin.js");
    &replace('%PATH%',  "$cgiBin","$cwd/blib/perl/config/mysql-admin.conf");
    &replace('%host%',  "$m_hrSettings->{cgi}{serverName}","$cwd/blib/perl/config/mysql-admin.conf");
    &replace('%htdocs%',"$m_hrSettings->{cgi}{DocumentRoot}","$cwd/blib/perl/config/mysql-admin.conf");
    &replace('%htdocs%',"$m_hrSettings->{cgi}{DocumentRoot}","$cwd/blib/lib/MySQL/Admin/Documentation.pm");
    &replace('%docu%',"$m_hrSettings->{cgi}{bin}./lib/MySQL/Admin/Documentatio.pm","$cwd/blib/lib/MySQL/Admin/Documentation.pm");

}

sub ACTION_realclean
{
    my $self = shift;
    cleanUp();
    saveSettings("$cwd/cgi-bin/config/settings.pl");
    $self->SUPER::ACTION_realclean;
}

sub ACTION_install
{
  my $self = shift;
  if($^O eq 'MSWin32'){
    &replace('#!/usr/bin/perl', '#!perl', "$cwd/blib/perl/mysql.pl");
    &replace('#!/usr/bin/perl', '#!perl', "$cwd/blib/perl/translate.pl");
  }
  &replace("$cwd/t/config.pl",    $m_hrSettings->{cgi}{bin}.'/config/config.pl',"$cwd/blib/lib/MySQL/Admin/Config.pm");
  &replace("$cwd/t/translate.pl", $m_hrSettings->{cgi}{bin}.'/config/translate.pl',"$cwd/blib/lib/MySQL/Admin/Translate.pm");
  &replace("$cwd/t/settings.pl",  $m_hrSettings->{cgi}{bin}.'/config/settings.pl',"$cwd/blib/lib/MySQL/Admin/Settings.pm");
  &replace("$cwd/t/session.pl",   $m_hrSettings->{cgi}{bin}.'/config/session.pl',"$cwd/blib/lib/MySQL/Admin/Session.pm");
  &replace("$cwd/t/actions.pl",   $m_hrSettings->{cgi}{bin}.'/config/actions.pl',"$cwd/blib/lib/MySQL/Admin/Actions.pm");
  &replace("$cwd/t/settings.pl",  $m_hrSettings->{cgi}{bin}.'/config/settings.pl',"$cwd/blib/lib/MySQL/Admin.pm");
  &replace("$cwd/t/settings.pl",  $m_hrSettings->{cgi}{bin}.'/config/settings.pl',"$cwd/blib/lib/Template/Quick.pm");

  if( $m_hrSettings->{mod}  && -e "$cwd/blib/perl/config/mysql-admin.conf" )
  {  
    copy("$cwd/blib/perl/config/mysql-admin.conf", "$m_hrSettings->{apacheconfig}/mysql-admin.conf") or die "$cwd/$m_hrSettings->{apacheconfig}/mysql-admin.conf $/ Copy failed: $cwd/blib/perl/config/mysql-admin.conf $!";
  }

  my %conf = (
    name => $self->{properties}{dbname},
    host => $self->{properties}{sqlhost},
    user => $self->{properties}{dbuser}
  );
  $conf{password} = $self->{properties}{dbpass} unless $self->{properties}{dbpass} =~ /^$/;

  eval 'use lib qw(lib);use DBI::Library ';
  unless( $@ ){
    my $m_oDatabase = new DBI::Library();
    $m_oDatabase->initDB(\%conf);
    open(IN, "extra/install.sql") or warn $!;
    local $/;
    my $m_sFile = <IN>;
    foreach my $sql (split /;\n/, $m_sFile){
	if(defined $sql){
	  $m_oDatabase->void($sql);
	  print "$@" if $@;
	}
    }
    close(IN);
    eval 'use MD5';
    unless ($@) {
	my $md5 = new MD5;
	$md5->add('admin');
	$md5->add($self->{'properties'}{password});
	my $fingerprint = $md5->hexdigest();
	$m_oDatabase->void(qq/insert into users (`user`,`pass`,`right`,`cats`) values(?,?,5,?)/, 'admin', $fingerprint,'news|member|draft');
    } else {
	warn $@;
	$m_oDatabase->void(qq/insert into users (`user`,`pass`,`right`,`cats`) values('admin','0008e525bc0894a780297b7f3aed6f58','5','news|member|draft')/);
    }
  }else{
    warn $@;
  }
  my $prefix = defined $inctance->{phash}{runtime_params}{disk}{prefix} ? $inctance->{phash}{runtime_params}{disk}{prefix} : '';
  $self->SUPER::ACTION_install;
    if($^O ne 'MSWin32'){
    $prefix .= '/' unless  $prefix =~/^$/; 
    system("chmod $m_hrSettings->{files}{chmod} -R  $prefix$m_hrSettings->{cgi}{DocumentRoot}");
    system("chmod $m_hrSettings->{files}{chmod} -R  $prefix$m_hrSettings->{cgi}{bin}");
    system("chmod $m_hrSettings->{files}{chmod} $prefix$m_hrSettings->{cgi}{bin}/mysql.pl");
    system("chmod $m_hrSettings->{files}{chmod} $prefix$m_hrSettings->{cgi}{bin}/translate.pl");
    mkdir "$prefix$m_hrSettings->{cgi}{DocumentRoot}/download";
    system("chown $m_hrSettings->{files}{owner}:$m_hrSettings->{files}{group} -R  $prefix$m_hrSettings->{cgi}{DocumentRoot}");
    system("chown $m_hrSettings->{files}{owner}:$m_hrSettings->{files}{group} -R  $prefix$m_hrSettings->{cgi}{bin}");
    system("chown $m_hrSettings->{files}{owner}:$m_hrSettings->{files}{group} $cwd/cgi-bin/config/settings.pl") if $^O ne 'MSWin32';

  }
}

sub ACTION_uninstall
{
    my %conf = (
      name => $self->{'properties'}{dbname},
      host => $self->{'properties'}{sqlhost},
      user => $self->{'properties'}{dbuser},
    );
    if (defined $self->{'properties'}{dbpass})
    {
        $conf{password} = $self->{'properties'}{dbpass} unless $self->{'properties'}{dbpass} =~ /^$/;
    }
    eval 'use lib qw(lib);use DBI::Library ';
    unless ($@)
    {
        my $m_oDatabase = new DBI::Library();
        $m_oDatabase->initDB(\%conf);
        open(IN, "extra/uninstall.sql") or die $!;
        local $/;
        my $m_sFile = <IN>;
        foreach my $sql (split /;\n/, $m_sFile)
        {
            $m_oDatabase->void($sql . ";");
            print $@ if $@;
        }
    }
}

sub change
{
    my $d = shift;
    chomp($d);
    opendir(IN, $d) or die "Install failed: $d $!:$/";
    my @files = readdir(IN);
    closedir(IN);
    for (my $i = 0; $i <= $#files; $i++)
    {
      unless ($files[$i] =~ /^\./)
      {
	my $c = "$d/$files[$i]";
	my $e = $c;
	$e =~ s/^$dir(.*)/$1/;
	unless (-d $c)
	{
	    copy($c, "$release/$e") or die "copy failed: $! $/ $c  $/ $release/$e";
	    chmod 0755, "$release/$e" if $e =~ /^.*.pl$/;
	}
	else
	{
	    mkpath("$release/$e") unless (-d "$release/$e");
	    &change("$d/$files[$i]") unless $files[$i] =~ /^\./;
	}
      }
    }
}

sub cleanUp
{
    $m_hrSettings->{database}{password} = '';
    saveSettings("$cwd/cgi-bin/config/settings.pl");
    unlink("t/00-DBI-Database.t") if -e "t/00-DBI-Database.t";
    unlink("t/00-DBI-OO.t") if -e "t/00-DBI-OO.t";
    unlink("t/00-DBI-FO.t") if -e "t/00-DBI-FO.t";
    unlink("t/config.pl")   if -e "t/config.pl";
}

sub replace{
    my $replace = shift;
    my $with    = shift;
    my $f       = shift;
    chmod 0644, $f;
    open(EDIT, "+<$f") or die "$! $f  $/";
    my $files = '';
    while (<EDIT>){
        $_ =~ s/$replace/$with/g;
        $files .= $_;
    }
    seek(EDIT, 0, 0);
    print EDIT $files;
    truncate ( EDIT, tell( EDIT ) );
    close( EDIT );
    chmod 0755, $f if ($f =~ /^.*.pl$/);
}

sub ACTION_testdb{
    my $self = shift;
    eval("use File::Copy;");
    unless ($@){
        copy("extra/00-DBI-Database.t", "t/00-DBI-Database.t") or die "Copy failed: $!";
        copy("extra/00-DBI-OO.t",       "t/00-DBI-OO.t")       or die "Copy failed: $!";
        copy("extra/00-DBI-FO.t",       "t/00-DBI-FO.t")       or die "Copy failed: $!";
        $self->SUPER::ACTION_test;
        cleanUp();
    }
}

sub ACTION_tarball{
    my $self = shift;
    eval("use File::Copy;");
    unless ($@ && $^O eq 'MSWin32'){
		print "tarball$/";

		mkpath("MySQL-Admin.$m_hrSettings->{version}-webinstaller");
		mkpath("MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/");

		system("cp -R $cwd/blib/rhtml/* MySQL-Admin.$m_hrSettings->{version}-webinstaller/");
		system("cp -R $cwd/blib/perl/* MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/");
		system("cp -R $cwd/blib/lib MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/");
		copy("$cwd/extra/install.sql",  "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/config/install.sql") or die "Copy failed: $!";
		copy("$cwd/extra/settings.pl",  "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/config/settings.pl") or die "Copy failed: $!";
		copy("$cwd/extra/rpc.pl",  "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/config/rpc.pl") or die "Copy failed: $!";
		copy("$cwd/extra/plaintext.pl",  "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/config/plaintext.pl") or die "Copy failed: $!";
		&replace('%PATH%', '', "$cwd/blib/perl/mysql.pl");
		copy("$cwd/extra/README",  "MySQL-Admin.$m_hrSettings->{version}-webinstaller/README") or die "Copy failed: $!";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/mysql.pl";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/install.pl";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/translate.pl";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/plaintext.pl";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/rpc.pl";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/menu.pl";
		chmod 0755, "MySQL-Admin.$m_hrSettings->{version}-webinstaller/cgi-bin/rss.pl";

		system("tar -cf MySQL-Admin.$m_hrSettings->{version}-webinstaller.tar.gz MySQL-Admin.$m_hrSettings->{version}-webinstaller/");
		system("rm -Rf MySQL-Admin.$m_hrSettings->{version}-webinstaller/");
    }else{
		warn "Cant create a tarball on Win32$/"
	}
}


sub loadSettings{
    my $do = shift;
    if (-e $do){
        do $do;
    }
}

sub saveSettings {
    my $saveAs = shift;
    use Data::Dumper;
    my $content = Dumper($m_hrSettings);
    $content .= "\$m_hrSettings =\$VAR1;";
    my $rsas = $saveAs =~ /^(\S+)$/ ? $1 : 0;
    chmod 0644, $rsas;
    if( $rsas ){
        open(OUT, ">$rsas" ) or die "$/saveSettings$/ $! $/ File: $rsas $/";
        print OUT $content;
        close $fh;
    }
}
END

my $inctance = $class->new(
  get_options => {
		  skip => {store => \$skip},
		},
  module_name => 'MySQL::Admin',
  requires    => {
	      'HTML::Menu::TreeView' => '>=1.15',
	      'Test::More'           => '>=0.7',
	      'DBI'                  => '>=1.50',
	      'CGI'                  => '>=3.48',
	      'MD5'                  => '>=2.03',
	      'URI'                  => '>=1.40',
	      'CGI::QuickForm'       => '>=1.93',
		  'JSON::XS'			 => '>=3.04',
		  'XML::Simple'			 => '>=2.25',
	      'perl'                 => '5.006000',
    	  'Search::Tools::UTF8'  => '>=1.003',
    	  'Authen::Captcha'      => '>=1.024',
          'Frontier::RPC2' => '>=0.06',
          'XML::XSLT' => '>=0.48',
		  'Mail::Sendmail'      => '>=0.79',
		  'Text::Markdown::Hoedown' => '>=1.02'
	      },
  ($] >= 5.005 ? (AUTHOR => 'Dirk Lindner <dirk.lze@gmail.com>') : ()),
  dist_abstract      => 'Just a MySQL administration Web-App and CMS System',
  license            => 'lgpl',
  create_makefile_pl => 'passthrough',
  meta_merge => { 
  resources => {
      repository => 'https://sourceforge.net/p/lindnerei/code/ci/master/tree/'
  }
  }
#   ,sign =>1
);
use Cwd;
$cwd = cwd;
$prefix =
    $inctance->{phash}{runtime_params}{disk}{prefix}
  ? $inctance->{phash}{runtime_params}{disk}{prefix}
  : '';

eval 'use lib qw(/var/www/cgi-bin/lib);' if -e '/var/www/cgi-bin/lib';
eval 'use MySQL::Admin::Settings qw(loadSettings)';

unless ($@) {
    *m_hrSettings = \$MySQL::Admin::Settings::m_hrSettings;
    loadSettings("$cwd/cgi-bin/config/settings.pl") unless -e $m_hrSettings->{cgi}{bin};
} else {
    do "$cwd/cgi-bin/config/settings.pl";
}

$inctance->{properties}{htd} =
  $m_hrSettings->{cgi}{DocumentRoot} ? $m_hrSettings->{cgi}{DocumentRoot} : '/var/www/htdocs';
$inctance->{properties}{cgi} =
  $m_hrSettings->{cgi}{bin} ? $m_hrSettings->{cgi}{bin} : '/var/www/cgi-bin';
$inctance->{properties}{server} =
  $m_hrSettings->{cgi}{serverName} ? $m_hrSettings->{cgi}{serverName} : 'http://localhost';
$inctance->{properties}{dbname} =
  $m_hrSettings->{database}{name} ? $m_hrSettings->{database}{name} : 'MySQLAdmin';
$inctance->{properties}{dbuser} =
  $m_hrSettings->{database}{user} ? $m_hrSettings->{database}{user} : 'root';
$inctance->{properties}{sqlhost} =
  $m_hrSettings->{database}{host} ? $m_hrSettings->{database}{host} : 'localhost';
$inctance->{properties}{dbpass} =
  $m_hrSettings->{database}{password} ? $m_hrSettings->{database}{password} : '';

if ($^O ne 'MSWin32') {
    open(IN, "/etc/apache2/envvars") or warn $!;
    my ($user, $group);
    while (<IN>) {
        $user  = $1 if $_ =~ /APACHE_RUN_USER=(.*)/;
        $group = $1 if $_ =~ /APACHE_RUN_GROUP=(.*)/;
    }
    $inctance->{properties}{group} =
      $m_hrSettings->{files}{group} ? $m_hrSettings->{files}{group} : $group;
    $inctance->{properties}{owner} =
      $m_hrSettings->{files}{owner} ? $m_hrSettings->{files}{owner} : $user;
    $inctance->{properties}{chmod} =
      $m_hrSettings->{files}{chmod} ? $m_hrSettings->{files}{chmod} : '0755';
}

$inctance->{properties}{password} =
  $m_hrSettings->{admin}{pass} ? $m_hrSettings->{admin}{pass} : 'testpass';

$inctance->{properties}{apacheconfig} =
  $m_hrSettings->{apacheconfig} ? $m_hrSettings->{apacheconfig} : '/etc/apache2/sites-enabled/';
$inctance->{properties}{mod} = $m_hrSettings->{mod} ? $m_hrSettings->{mod} : 'n';

$inctance->{properties}{dbname}  = $inctance->args('dbname')  if $inctance->args('dbname');
$inctance->{properties}{dbuser}  = $inctance->args('dbuser')  if $inctance->args('dbuser');
$inctance->{properties}{sqlhost} = $inctance->args('sqlhost') if $inctance->args('sqlhost');
$inctance->{properties}{dbpass}  = $inctance->args('dbpass')  if $inctance->args('dbpass');
$inctance->{properties}{cgi}     = $inctance->args('cgi')     if $inctance->args('cgi');
$inctance->{properties}{htd}     = $inctance->args('htd')     if $inctance->args('htd');

if ($^O ne 'MSWin32') {
    $inctance->{properties}{group} = $inctance->args('group') if $inctance->args('group');
    $inctance->{properties}{chmod} = $inctance->args('chmod') if $inctance->args('chmod');
    $inctance->{properties}{owner} = $inctance->args('owner') if $inctance->args('owner');
}
$inctance->{properties}{server}   = $inctance->args('server')   if $inctance->args('server');
$inctance->{properties}{password} = $inctance->args('password') if $inctance->args('password');

$inctance->{properties}{install_path}{perl}  = $prefix . $inctance->{properties}{cgi};
$inctance->{properties}{install_path}{rhtml} = $prefix . $inctance->{properties}{htd};

#uncomment this to install the lib files inside the cgi-bin directory
$inctance->{properties}{install_path}{lib} = $prefix . $inctance->{properties}{cgi} . '/lib/';

unless ($skip) {
    my $an = Module::Build->prompt(
        "Should i use settings from previous previous version 
      $/ Document root: $inctance->{properties}{htd} 
      $/ cgi-bin directory:  $inctance->{properties}{cgi} 
      $/ Server Name: $inctance->{properties}{server} 
      $/ Mysql Server host:  $inctance->{properties}{sqlhost} 
      $/ Mysql user name: $inctance->{properties}{dbuser} 
      $/ Mysql password:  $inctance->{properties}{dbpass} 
      $/ Mysql Database Name:  $inctance->{properties}{dbname} 
      $/ Files group:  $inctance->{properties}{group} 
      $/ Files owner:  $inctance->{properties}{owner}
      $/ Files chmod:  $inctance->{properties}{chmod} 
      $/ Password: $inctance->{properties}{password} 
      $/ mod_perl:$inctance->{properties}{mod}
      $/ apache_config: $inctance->{properties}{apacheconfig}$/",
        'yes'
    );
    $skip = $an eq 'yes' ? 1 : 0;
}

unless ($skip) {
    $inctance->{properties}{cgi} =
      $inctance->{properties}{cgi} ? $inctance->{properties}{cgi} : '/srv/www/cgi-bin';
    $inctance->{properties}{htd} =
      $inctance->{properties}{htd} ? $inctance->{properties}{htd} : '/srv/www/htdocs';
    $inctance->{properties}{htd} =
      Module::Build->prompt('Where is your Document root ?', $inctance->{properties}{htd});
    $inctance->{properties}{cgi} =
      Module::Build->prompt('Where is your cgi-bin directory ?', $inctance->{properties}{cgi});
    $inctance->{properties}{server} =
      $inctance->{properties}{server} ? $inctance->{properties}{server} : 'http://localhost';
    $inctance->{properties}{server} =
      Module::Build->prompt('Enter your Server Name', $inctance->{properties}{server});
    $inctance->{properties}{sqlhost} =
      $inctance->{properties}{sqlhost} ? $inctance->{properties}{sqlhost} : 'localhost';
    $inctance->{properties}{sqlhost} =
      Module::Build->prompt('Enter your Mysql Server host', $inctance->{properties}{sqlhost});
    $inctance->{properties}{dbuser} =
      $inctance->{properties}{dbuser} ? $inctance->{properties}{dbuser} : 'root';
    $inctance->{properties}{dbuser} =
      Module::Build->prompt('Enter your Mysql user name', $inctance->{properties}{dbuser});
    $inctance->{properties}{dbpass} =
      $inctance->{properties}{dbpass} ? $inctance->{properties}{dbpass} : "";
    $inctance->{properties}{dbpass} =
      Module::Build->prompt('Enter your Mysql password', $inctance->{properties}{dbpass});
    $inctance->{properties}{dbname} =
      $inctance->{properties}{dbname} ? $inctance->{properties}{dbname} : 'MYSQL_ADMIN';
    $inctance->{properties}{dbname} =
      Module::Build->prompt('Enter your Mysql Database Name', $inctance->{properties}{dbname});

    if ($^O ne 'MSWin32') {
        $inctance->{properties}{owner} =
          Module::Build->prompt('Enter your File Owner', $inctance->{properties}{owner});
        $inctance->{properties}{owner} =
          $inctance->{properties}{owner} ? $inctance->{properties}{owner} : 'www-data';
        $inctance->{properties}{group} =
          $inctance->{properties}{group} ? $inctance->{properties}{group} : 'www-data';
        $inctance->{properties}{group} =
          Module::Build->prompt('Enter your File Owner Group', $inctance->{properties}{group});
        $inctance->{properties}{chmod} =
          $inctance->{properties}{chmod} ? $inctance->{properties}{chmod} : '755';
        $inctance->{properties}{chmod} =
          Module::Build->prompt('Enter your Chmod !', $inctance->{properties}{chmod});
    }

    $inctance->{properties}{password} =
      $inctance->{properties}{password} ? $inctance->{properties}{password} : 'firststart';
    $inctance->{properties}{password} =
      Module::Build->prompt('Enter Password for login!', $inctance->{properties}{password});
    $inctance->{properties}{mod} =
      $inctance->{properties}{mod} ? $inctance->{properties}{mod} : 'n';
    $inctance->{properties}{mod} = Module::Build->y_n('Use mod_perl ?', 'n');

    if ($inctance->{properties}{mod}) {
        print qq|This script generate a virtual host config  ( mysql-admin.conf file ).$/|;
        $inctance->{properties}{apacheconfig} =
            $inctance->{properties}{apacheconfig} ? $inctance->{properties}{apacheconfig}
          : -e '/etc/apache2/sites-enabled/'      ? '/etc/apache2/sites-enabled/'
          :                                         "$inctance->{properties}{cgi}/config";
        $inctance->{properties}{apacheconfig} =
          Module::Build->prompt(qq|Please enter the path to install the Apache config:|,
                                '/etc/apache2/sites-enabled/');
    }
}

$m_hrSettings = {
    apacheconfig => $inctance->{properties}{apacheconfig},
    mod          => $inctance->{properties}{mod},
    config       => "$inctance->{properties}{cgi}/config/settings.pl",
    admin        => {
              password => $inctance->{properties}{password},
             },
    cgi => {
            expires      => '+1y',
            cookiePath   => '/',
            serverName   => $inctance->{properties}{server},
            DocumentRoot => $inctance->{properties}{htd} =~/\/$/ ? $inctance->{properties}{htd} : $inctance->{properties}{htd}.'/',
            bin          => $inctance->{properties}{cgi},
            title        => 'MySQL::Admin',
            style        => 'mysql',
           },
    language    => 'en',
    version     => '1.14',
    session     => "$inctance->{properties}{cgi}/config/session.pl",
    actions     => "$inctance->{properties}{cgi}/config/actions.pl",
    translate   => "$inctance->{properties}{cgi}/config/translate.pl",
    database    => {
                 name        => $inctance->{properties}{dbname},
                 host        => $inctance->{properties}{sqlhost},
                 user        => $inctance->{properties}{dbuser},
                 password    => $inctance->{properties}{dbpass},
                 CurrentDb   => $inctance->{properties}{dbname},
                 CurrentHost => $inctance->{properties}{sqlhost},
                 CurrentUser => $inctance->{properties}{dbuser},
                 CurrentPass => $inctance->{properties}{dbpass},
                },
    floodtime => 10,
    files     => {
              chmod => $inctance->{properties}{chmod},
              group => $inctance->{properties}{group},
              owner => $inctance->{properties}{owner},
             },
    uploads => {
                path      => "$inctance->{properties}{htd}/download",
                maxlength => 2100000000000000,
                chmod     => 0666,
                right     => 2,
                enabled   => 1
               },
    tree => {
             navigation => "$inctance->{properties}{cgi}/config/tree.pl",
             links      => "$inctance->{properties}{cgi}/config/links.pl"
            },
    news => {
             messages  => '5',
             captcha   => 3,
             right     => 5,
            },
    defaultAction => 'ShowDatabases',
    size          => '16',
    htmlright     => '2',
    saveTranslate => '0',

};

saveSettings("$cwd/cgi-bin/config/settings.pl");

$inctance->create_build_script;

sub saveSettings {
    my $saveAs = shift;
    use Data::Dumper;
    my $content = Dumper($m_hrSettings);
    $content .= "\$m_hrSettings =\$VAR1;";
    my $rsas = $saveAs =~ /^(\S+)$/ ? $1 : 0;
    chmod 0644, $rsas if $^O ne 'MSWin32';
    if ($rsas) {
        open(OUT, ">$rsas") or die "$/ saveSettings $/ $! $/ File: $rsas $/";
        print OUT $content;
        close OUT;
    }
}
