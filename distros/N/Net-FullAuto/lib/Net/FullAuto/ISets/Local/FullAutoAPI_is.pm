package Net::FullAuto::ISets::Local::FullAutoAPI_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright © 2000-2020  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################


our $VERSION='0.01';
our $DISPLAY='FullAuto RESTful API Server';
our $CONNECT='secure';
our $defaultInstanceType='t2.small';

use 5.005;

use strict;
use warnings;

my $service_and_cert_password='Full@ut0O1';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_fullautoapi_setup);

use Net::FullAuto::Cloud::fa_amazon;
use Net::FullAuto::FA_Core qw[$localhost cleanup fetch clean_filehandle];
use Time::Local;
use File::HomeDir;
my $home_dir=File::HomeDir->my_home;
$home_dir||=$ENV{'HOME'}||'';
$home_dir.='/';
my $username=getlogin || getpwuid($<);
my $do;my $ad;my $prompt;my $public_ip='';
my $builddir='';my @ls_tmp=();

my $avail_port='';

my $configure_fullautoapi=sub {

   my $selection=$_[0]||'';
   my $service_and_cert_password=$_[1]||'';
   my $domain_url=$_[2]||'';
   my ($stdout,$stderr)=('','');
   my $handle=connect_shell();my $connect_error='';
   $handle->cwd('~');
   my $userhome=$handle->cmd('pwd');
   my $sudo=($^O eq 'cygwin')?'':'sudo ';
   my $security_group='FullAutoAPISecurityGroup';
   ($stdout,$stderr)=setup_aws_security(
      $security_group,'FullAutoAPI Security Group');
   my $c='aws ec2 describe-security-groups '.
         "--group-names $security_group";
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
           ->[0]->{IpRanges}->[0]->{CidrIp};
   $c='aws ec2 authorize-security-group-ingress '.
      "--group-name $security_group --protocol ".
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c='aws ec2 authorize-security-group-ingress '.
      "--group-name $security_group --protocol ".
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   $c='aws ec2 authorize-security-group-ingress '.
      "--group-name $security_group --protocol ".
      'tcp --port 11211 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c='aws ec2 authorize-security-group-ingress '.
      "--group-name $security_group --protocol ".
      'tcp --port 3000 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   ($stdout,$stderr)=$handle->cmd($sudo."perl -e \'use CPAN;".
      "CPAN::HandleConfig-\>load;print \$CPAN::Config-\>{build_dir}\'");
   $builddir=$stdout;
   my $fa_ver=$Net::FullAuto::VERSION;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ls -1t $builddir | grep Net-FullAuto-$fa_ver");
   my @lstmp=split /\n/,$stdout;
   foreach my $line (@lstmp) {
      unshift @ls_tmp, $line if $line!~/\.yml$/;
   }
$do=1;
if ($do==1) {
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chmod -v 755 ~",'__display__');
      ($stdout,$stderr)=$handle->cmd("sudo yum clean all");
      ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden");
      ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert");
      ($stdout,$stderr)=$handle->cmd(
         "sudo yum -y groupinstall 'Development tools'",'__display__');
      ($stdout,$stderr)=$handle->cmd(
         'sudo yum -y install openssl-devel icu cyrus-sasl'.
         ' libicu cyrus-sasl-devel libtool-ltdl-devel libxml2-devel'.
         ' freetype-devel libpng-devel java-1.7.0-openjdk-devel'.
         ' unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel'.
         ' ncurses-devel xmlto git-all autoconf','__display__');
   } else {
      my $cygcheck=`/bin/cygcheck -c` || die $!;
      my $uname=`/bin/uname` || die $!;
      my $uname_all=`/bin/uname -a` || die $!;
      $uname_all.=$uname;
      my %need_packages=();
      my $srvout='';
      ($srvout,$stderr)=$handle->cmd("cygrunsrv -L",'__display__');
      if ($srvout=~/exim/) {
         ($stdout,$stderr)=$handle->cmd("cygrunsrv --stop exim",'__display__');
         ($stdout,$stderr)=$handle->cmd("cygrunsrv -R exim");
      }
      if ($srvout=~/nginx_first_time/) {
         ($stdout,$stderr)=$handle->cmd(
            "cygrunsrv --stop nginx_first_time",'__display__');
         ($stdout,$stderr)=$handle->cmd("cygrunsrv -R nginx_first_time");
         ($stdout,$stderr)=$handle->cmd(
            "rm -rvf ${home_dir}FullAutoAPI/deps/nginx*",
            '__display__');
      }
      if ($srvout=~/fullautoapi/) {
         ($stdout,$stderr)=$handle->cmd("cygrunsrv --stop fullautoapi",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("cygrunsrv -R fullautoapi");
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/lib",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/script",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/root",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/db*",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/inc",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/full*",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("rm -rvf ${home_dir}FullAutoAPI/blib",
            '__display__');
      }
      if ($srvout=~/memcached/) {
         ($stdout,$stderr)=$handle->cmd("cygrunsrv --stop memcached",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("cygrunsrv -R memcached");
         ($stdout,$stderr)=$handle->cmd(
            "rm -rvf ${home_dir}FullAutoAPI/deps/memcached*",
            '__display__');
      }
      if ($uname_all=~/x86_64/) {
         foreach my $package ('libxml2','libxml2-devel','libtool',
               'autoconf','autobuild','automake','pkg-config',
               'libuuid-devel','wget','git','httpd',
               'httpd-mod_ssl','httpd-tools','exim','zip') {
            unless (-1<index $cygcheck, "$package ") {
               $need_packages{$package}='';
            }
         }
      } else {
         foreach my $package ('libxml2','libxml2-devel','libtool',
               'autoconf','autobuild','automake','pkg-config',
               'libuuid-devel','wget','git','httpd','httpd-mod_ssl',
               'httpd-tools','exim','zip') {
            unless (-1<index $cygcheck, "$package ") {
               $need_packages{$package}='';
            }
         }
      }
      # http://www.fjakkarin.com/2015/11/cygwin-cygserver-and-apache-httpd/
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "https://github.com/transcode-open/apt-cyg/archive/master.zip",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chown -v $username:$username master.zip','__display__')
         if $^O ne 'cygwin';
      ($stdout,$stderr)=$handle->cmd("unzip -o master.zip",'__display__');
      ($stdout,$stderr)=$handle->cmd("rm -rvf master.zip",'__display__');
      ($stdout,$stderr)=$handle->cmd("mv apt-cyg-master/apt-cyg /usr/bin");
      ($stdout,$stderr)=$handle->cmd($sudo."chmod -v 755 /usr/bin/apt-cyg",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("rm -rvf apt-cyg-master",'__display__');
      my $packs='';$|=1;
      foreach my $pack (sort keys %need_packages) {
         ($stdout,$stderr)=$handle->cmd("apt-cyg install $pack",
            '__display__');
      }
      if ($^O eq 'cygwin') {
         ($stdout,$stderr)=$handle->cwd('~');
         # http://blogostuffivelearnt.blogspot.com/2012/07/
         # smtp-mail-server-with-windows.html
         ($stdout,$stderr)=$handle->cmd(
            "chmod -v 755 /usr/bin/exim*",'__display__');
         $handle->print('/bin/exim-config');
         $prompt=$handle->prompt();
         while (1) {
            my $output=fetch($handle);
            last if $output=~/$prompt/;
            print $output;
            if (-1<index $output,'local postmaster') {
               $handle->print();
            } elsif (-1<index $output,'Is it') {
               $handle->print('yes');
            } elsif (-1<index $output,'change that setting') {
               $handle->print('no');
            } elsif (-1<index $output,'standard values') {
               $handle->print('yes');
            } elsif (-1<index $output,'be links to') {
               $handle->print('yes');
            } elsif (-1<index $output,'some CPAN') {
               $handle->print('no');
            } elsif (-1<index $output,'install the exim') {
               $handle->print('yes');
            } elsif (-1<index $output,'in minutes') {
               $handle->print();
            } elsif (-1<index $output,'CYGWIN for the daemon') {
               $handle->print('default');
            } elsif (-1<index $output,'the cygsla package') {
               $handle->print('yes');
            } elsif (-1<index $output,'another privileged account') {
               $handle->print('no');
            } elsif (-1<index $output,'enter the password') {
               $handle->print($service_and_cert_password);
            } elsif (-1<index $output,'Reenter') {
               $handle->print($service_and_cert_password);
            } elsif (-1<index $output,'start the exim') {
               $handle->print('yes');
            }
            next;
         }
      }
      #if ($packs) {
      #   print "\n\n   Fatal Error!: The following Cygwin",
      #         "\n                 packages are missing from",
      #         "\n                 your installation:",
      #         "\n\n   $packs",
      #         "\n\n   Please report any bugs and send any",
      #         "\n   questions, thoughts or feedback to:",
      #         "\n\n      Brian.Kelly\@FullAuto.com.",
      #         "\n\n";
      #   &Net::FullAuto::FA_Core::cleanup;
      #}
      #print "\nInstalling Microsoft IIS Web Server . . .\n\n";
      # http://www.iis.net/learn/install/installing-iis-85/
      #      installing-iis-85-on-windows-server-2012-r2
      # https://technet.microsoft.com/en-us/library/hh831475.aspx
      # http://twiki.org/cgi-bin/view/TWiki/TWikiOnWindowsIISCygwin
      # https://www.iis.net/configreference/system.webserver/fastcgi
      #($stdout,$stderr)=$handle->cmd("DISM.EXE /enable-feature /all ".
      #   "/online /featureName:IIS-WebServerRole /featureName:IIS-WebServer ".
      #   "/featureName:IIS-CommonHttpFeatures /featureName:IIS-StaticContent ".
      #   "/featureName:IIS-DefaultDocument /featureName:IIS-DirectoryBrowsing ".
      #   "/featureName:IIS-HttpErrors /featureName:IIS-HttpRedirect ".
      #   "/featureName:IIS-ApplicationDevelopment /featureName:IIS-ASPNET ".
      #   "/featureName:IIS-NetFxExtensibility /featureName:IIS-ASPNET45 ".
      #   "/featureName:IIS-NetFxExtensibility45 /featureName:IIS-ASP ".
      #   "/featureName:IIS-CGI /featureName:IIS-ISAPIExtensions ".
      #   "/featureName:IIS-ISAPIFilter /featureName:IIS-ServerSideIncludes ".
      #   "/featureName:IIS-HealthAndDiagnostics /featureName:IIS-HttpLogging ".
      #   "/featureName:IIS-LoggingLibraries /featureName:IIS-RequestMonitor ".
      #   "/featureName:IIS-HttpTracing /featureName:IIS-CustomLogging ".
      #   "/featureName:IIS-ODBCLogging /featureName:IIS-Security ".
      #   "/featureName:IIS-BasicAuthentication ".
      #   "/featureName:IIS-WindowsAuthentication ".
      #   "/featureName:IIS-DigestAuthentication ".
      #   "/featureName:IIS-ClientCertificateMappingAuthentication ".
      #   "/featureName:IIS-IISCertificateMappingAuthentication ".
      #   "/featureName:IIS-URLAuthorization /featureName:IIS-RequestFiltering ".
      #   "/featureName:IIS-IPSecurity /featureName:IIS-Performance ".
      #   "/featureName:IIS-HttpCompressionStatic ".
      #   "/featureName:IIS-HttpCompressionDynamic /featureName:IIS-WebDAV ".
      #   "/featureName:IIS-WebServerManagementTools ".
      #   "/featureName:IIS-ManagementScriptingTools ".
      #   "/featureName:IIS-ManagementService ".
      #   "/featureName:IIS-IIS6ManagementCompatibility ".
      #   "/featureName:IIS-Metabase /featureName:IIS-WMICompatibility ".
      #   "/featureName:IIS-LegacyScripts /featureName:NetFx4Extended-ASPNET45 ".
      #   "/featureName:IIS-ApplicationInit /featureName:IIS-WebSockets ".
      #   "/featureName:IIS-CertProvider /featureName:IIS-ManagementConsole ".
      #   "/featureName:IIS-LegacySnapIn",'__display__');
      #($stdout,$stderr)=$handle->cmd("DISM.EXE /online /enable-feature ".
      #   "/featureName:IIS-WebServerRole /featureName:IIS-WebServer ".
      #   "/featureName:IIS-CommonHttpFeatures /featureName:IIS-StaticContent ".
      #   "/featureName:IIS-DefaultDocument /featureName:IIS-DirectoryBrowsing ".
      #   "/featureName:IIS-HttpErrors /featureName:IIS-HealthAndDiagnostics ".
      #   "/featureName:IIS-HttpLogging /featureName:IIS-Performance ".
      #   "/featureName:IIS-HttpCompressionStatic /featureName:IIS-Security ".
      #   "/featureName:IIS-RequestFiltering /featureName:IIS-CGI ".
      #   "/featureName:IIS-WebServerManagementTools ".
      #   "/featureName:IIS-ManagementConsole",'__display__');
      #my $appcmd="$ENV{WINDIR}/SYSTEM32/inetsrv";
      #($appcmd,$stderr)=$handle->cmd("cygpath -u $appcmd");
      #my $cyglocb=$handle->cmd("cygpath -w /");
      #my $cyglocw=$handle->cmd("cygpath -w ~");
      #my $cyglocwf="$cyglocw\\FullAutoAPI";
      #$cyglocw=~s/\\/\\\\/g;
      #$cyglocwf=~s/\\/\\\\/g;
      #($stdout,$stderr)=$handle->cwd($appcmd);
      #($stdout,$stderr)=$handle->cmd("pwd",'__display__');
      #my $sleep=0;
      #while (1==1) {
      #  my $ls_output=$handle->cmd("ls -1");
      #  last if -1<index $ls_output,'appcmd.exe';
      #  sleep 2;
      #  last if $sleep++>300;
      #}
      #sleep 5;
      #($stdout,$stderr)=$handle->cmd("./appcmd add site /name:FullAutoAPI ".
      #   "/id:2 /physicalPath:$cyglocwf\\root /bindings:http/*:4000",
      #   '__display__');
      #sleep 2;
      #($stdout,$stderr)=$handle->cmd("./appcmd set config -section:".
      #   "system.webServer/fastCgi /+[\"fullpath=\'$cyglocb\\script\\".
      #   "CGI_script.bat\',arguments=\'$cyglocwf\\script\\".
      #   "fullautoapi_fastcgi.pl -e\',maxInstances=\'4\',".
      #   "idleTimeout=\'300\',activityTimeout=\'30\',requestTimeout='\90\',".
      #   "instanceMaxRequests=\'1000\',protocol=\'NamedPipe\',".
      #   "flushNamedPipe=\'False\']\" /commit:apphost",'__display__');
      #sleep 2;
      #($stdout,$stderr)=$handle->cmd("./appcmd set config -section:".
      #   "system.webServer/handlers /+\"[name=\'FullAutoAPI\',".
      #   "path=\'*\',verb=\'GET,HEAD,POST\',modules=".
      #   "\'FastCgiModule\',scriptProcessor=\'$cyglocb\\script\\".
      #   "CGI_Script.bat|$cyglocwf\\script\\fullautoapi_fastcgi.pl -e\',".
      #   "resourceType=\'Unspecified\',requireAccess=\'Script\']\" ".
      #   "/commit:apphost",'__display__');
      #($stdout,$stderr)=$handle->cwd("FullAutoAPI/script");
      #($stdout,$stderr)=$handle->cmd("touch CGI_Script.bat");
      #
      # echo-ing/streaming files over ssh can be tricky. Use echo -e
      #          and replace these characters with thier HEX
      #          equivalents (use an external editor for quick
      #          search and replace - and paste back results.
      #          use copy/paste or cat file and copy/paste results.):
      #
      #          !  -   \\x21     `  -  \\x60
      #          "  -   \\x22     \  -  \\x5C
      #          $  -   \\x24     %  -  \\x25
      #
      #$cyglocb=~s/\\/\\x5C/g;
      #my $content=<<END;
#$cyglocb\\x5Cbin\\x5Cbash -lc \\x22/bin/perl \\x251 \\x252\\x22
#END
      #($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > CGI_Script.bat");
      #($stdout,$stderr)=$handle->cwd("~");
      #($stdout,$stderr)=$handle->cmd("iisreset /start",'__display__');
   }
   ###############
   ## RABBITMQ
   ###############
   #($stdout,$stderr)=$handle->cmd(
   #   "wget --random-wait --progress=dot ".
   #   "https://github.com/erlang/otp/archive/maint.zip",
   #   '__display__');
   #($stdout,$stderr)=$handle->cmd("unzip -o maint.zip",'__display__');
   #($stdout,$stderr)=$handle->cmd("rm -rvf maint.zip",'__display__');
   #($stdout,$stderr)=$handle->cwd("otp-maint");
   #($stdout,$stderr)=$handle->cmd("export ERL_TOP=`pwd`",'__display__');
   #($stdout,$stderr)=$handle->cmd("./otp_build autoconf");
   #($stdout,$stderr)=$handle->cmd("./configure",'__display__');
   #($stdout,$stderr)=$handle->cmd("sudo make install",'__display__');
   #($stdout,$stderr)=$handle->cwd("..");
   #($stdout,$stderr)=$handle->cmd("sudo sed -i ".
   #   "'s#secure_path = #secure_path = /usr/local/bin:/usr/local/sbin:#'".
   #   " /etc/sudoers");
   #($stdout,$stderr)=$handle->cmd("wget -qO- ".
   #   "https://www.rabbitmq.com/download.html");
   #my $source_flag=0;
   #my $rmq='';my $rmqtar='';my $rmqdir='';
   #foreach my $line (split "\n", $stdout) {
   #   if ($line=~/Source/) {
   #      $source_flag=1;
   #   } elsif ($source_flag) {
   #      $rmq=$line;
   #      $rmq=~s/^.*href=["](.*?)["].*$/$1/;
   #      $rmq='https://www.rabbitmq.com'.$rmq;
   #      ($rmqtar=$rmq)=~s/^.*\/(.*)$/$1/;
   #      ($rmqdir=$rmqtar)=~s/^(.*).tar.gz/$1/;
   #      last;
   #   }
   #}
   #($stdout,$stderr)=$handle->cmd(
   #   "wget --random-wait --progress=dot ".$rmq,'__display__');
   #($stdout,$stderr)=$handle->cmd("tar zxvf $rmqtar",'__display__');
   #($stdout,$stderr)=$handle->cmd("rm -rvf $rmqtar",'__display__');
   #($stdout,$stderr)=$handle->cwd($rmqdir);
   #$handle->print('sudo su');
   #$prompt=$handle->prompt();
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->print('export TARGET_DIR=/usr/local');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->print('export SBIN_DIR=/usr/local');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->print('export MAN_DIR=/usr/local');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->print('make install');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->print('exit');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #($stdout,$stderr)=$handle->cwd("..");
   #($stdout,$stderr)=$handle->cmd(
   #   "wget --random-wait --progress=dot ".
   #   "https://github.com/rabbitmq/rabbitmq-tutorials/archive/master.zip",
   #   '__display__');
   #($stdout,$stderr)=$handle->cmd("unzip -o master.zip",'__display__');
   #($stdout,$stderr)=$handle->cmd("rm -rvf master.zip",'__display__');
   #($stdout,$stderr)=$handle->cmd("sudo rabbitmq-server -detached",
   #   '__display__');

   # TEST FOR AMAZON EC2 INSTANCE
   #($stdout,$stderr)=$handle->cmd('wget --timeout=5 --tries=1 -qO- '.
   #             'http://169.254.169.254/latest/dynamic/instance-identity/');
   #$public_ip=$stdout if $stdout=~/^\d+\.\d+\.\d+\.\d+\s*/s;

   #my $z=1;
   #while ($z==1) {
   #   ($stdout,$stderr)=$handle->cmd("ps -ef",'__display__');
   #   if ($stdout=~/nginx/) {
   #      my @psinfo=();
   #      foreach my $line (split /\n/, $stdout) {
   #         next unless -1<index $line, 'nginx';
   #         @psinfo=split /\s+/, $line;
   #         ($stdout,$stderr)=$handle->cmd($sudo."kill -9 $psinfo[2]");
   #      } last
   #   } else { last }
   #}
   ($stdout,$stderr)=$handle->cmd($sudo."pkill nginx");
   ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf /usr/local/nginx",'__display__');
   ($stdout,$stderr)=$handle->cmd("wget -qO- http://icanhazip.com");
   $public_ip=$stdout if $stdout=~/^\d+\.\d+\.\d+\.\d+\s*/s;
   unless ($public_ip) {
      require Sys::Hostname;
      import Sys::Hostname;
      require Socket;
      import Socket;
      my($addr)=inet_ntoa((gethostbyname(Sys::Hostname::hostname))[4]);
      $public_ip=$addr if $addr=~/^\d+\.\d+\.\d+\.\d+\s*/s;
   }
   chomp($public_ip);
   $public_ip='127.0.0.1' unless $public_ip;
   
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "http://download.fedoraproject.org".
         "/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chown -v $username:$username epel-release-6-8.noarch.rpm",
         '__display__') if $^O ne 'cygwin';
      ($stdout,$stderr)=$handle->cmd(
         "sudo rpm -ivh epel-release-6-8.noarch.rpm",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rvf epel-release-6-8.noarch.rpm',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'yum -y install uuid-devel '.
         'pkgconfig libtool gcc-c++','__display__');
   }
   ($stdout,$stderr)=$handle->cmd('mkdir -vp FullAutoAPI/deps',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'mkdir -vp FullAutoAPI/root/static/images',
      '__display__');
   #($stdout,$stderr)=$handle->cmd("${sudo}perl -e \'use CPAN;".
   #   "CPAN::HandleConfig-\>load;print \$CPAN::Config-\>{build_dir}\'");
   #$builddir=$stdout;
   #my $fa_ver=$Net::FullAuto::VERSION;
   #($stdout,$stderr)=$handle->cmd(
   #   "${sudo}ls -1t $builddir | grep Net-FullAuto-$fa_ver");
   #my @lstmp=split /\n/,$stdout;
   #foreach my $line (@lstmp) {
   #   unshift @ls_tmp, $line if $line!~/\.yml$/;
   #}
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/Docker_is.py ".
      "FullAutoAPI",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/automates_everything.jpg ".
      "FullAutoAPI/root/static/images",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/automationapi.jpg ".
      "FullAutoAPI/root/static/images",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/fullauto_com.jpg ".
      "FullAutoAPI/root/static/images",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/".
      "South-Shore-Food-Market-Ghost-sign_with_FA_1_faded_1024.jpg ".
      "FullAutoAPI/root/static/images",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/zeromq.jpg ".
      "FullAutoAPI/root/static/images",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/nginx.png ".
      "FullAutoAPI/root/static/images",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/wrapper.tt2 ".
      "FullAutoAPI/root",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/installer/FA.ico ".
      "FullAutoAPI/root/favicon.ico",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chmod -v 755 FullAutoAPI/root/static/images/*",
      '__display__');
   ($stdout,$stderr)=$handle->cwd("FullAutoAPI/deps");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username autoconf-latest.tar.gz",'__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd("tar zxvf autoconf-latest.tar.gz",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf autoconf-latest.tar.gz',
      '__display__');
   ($stdout,$stderr)=$handle->cwd("autoconf-*");
   ($stdout,$stderr)=$handle->cmd("./configure",'__display__');
   ($stdout,$stderr)=$handle->cmd("make",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."make install",'__display__');
   ($stdout,$stderr)=$handle->cwd("..");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://github.com/jedisct1/libsodium/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username master.zip",'__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd("unzip -o master.zip",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf master.zip','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -Rv $username:$username libsodium-master",'3600')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cwd('libsodium-master');
   ($stdout,$stderr)=$handle->cmd('./autogen.sh','__display__');
   ($stdout,$stderr)=$handle->cmd('./configure','__display__');
   ($stdout,$stderr)=$handle->cmd('make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');

$do=1;
if ($do==1) { # INSTALL LATEST VERSION OF PYTHON
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://www.python.org/downloads/release');
   $stdout=~s/^.*list-row-container menu.*?Python (.*?)[<].*$/$1/s;
   my $version=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "if test -f /usr/local/bin/python$version; then echo Exists; fi");
   unless ($stdout=~/Exists/) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         "http://python.org/ftp/python/$version/Python-$version.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf Python-$version.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cwd("Python-$version");
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --prefix=/usr/local --exec-prefix=/usr/local '.
         '--enable-shared --enable-optimizations '.
         'LDFLAGS="-Wl,-rpath /usr/local/lib"',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','3600','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make altinstall','__display__');
      $version=~s/^(\d+\.\d+).*$/$1/;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "ln -s /usr/local/bin/python$version /usr/local/bin/python");
      ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m ensurepip --default-pip",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m pip install ".
         "--upgrade pip setuptools wheel",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m pip install pyasn1",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m pip install pyasn1-modules",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m pip install --upgrade oauth2client",
         '__display__');
      ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m pip install oauth2",
         '__display__');
      unless ($^O eq 'cygwin') {
         ($stdout,$stderr)=$handle->cmd('echo /usr/local/lib > '.
            '~/local.conf','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v 644 ~/local.conf',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'mv -v ~/local.conf /etc/ld.so.conf.d','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.'ldconfig');
      } else {
         ($stdout,$stderr)=$handle->cmd(
            "python$version -m pip install awscli",
            '__display__');
      }
      $sudo='sudo env "PATH=$PATH" ';
      ($stdout,$stderr)=$handle->cmd($sudo.
         'python --version','__display__');
   }
}
$do=0;
if ($do==1) {
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://bootstrap.pypa.io/ez_setup.py",'__display__');
   if ($^O eq 'cygwin') {
      # ez_setup.py uses curl by default which is broken with --location
      # in Cygwin. So using wget instead by forcing return False.
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/has_curl()/areturn False' ez_setup.py");
      $handle->cmd_raw(
         "sed -i 's/\\(^return False$\\\)/    \\1/' ez_setup.py");
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chown -v $username:$username ez_setup.py",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd('python ez_setup.py','__display__');
   ($stdout,$stderr)=$handle->cmd('easy_install pip','__display__');
#   ($stdout,$stderr)=$handle->cmd(
#      'git clone https://github.com/pypa/setuptools.git','__display__');
#   ($stdout,$stderr)=$handle->cmd(
#      'chown -Rv $username:$username setuptools','__display__')
#      if $^O ne 'cygwin';
#   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps/setuptools');
#print "OK1\n";
#   ($stdout,$stderr)=$handle->cmd($sudo.'python setup.py install',
#      '__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
   ($stdout,$stderr)=$handle->cmd(
      'git clone https://github.com/google/oauth2client.git','__display__');
   ($stdout,$stderr)=$handle->cwd('oauth2client');
   ($stdout,$stderr)=$handle->cmd($sudo.'python setup.py install',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd($sudo.'pip install httplib2','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo."ls -1 ".
         "/usr/local/lib/python2.7/site-packages",'__display__');
      $stdout=~s/^.*(httplib2.*?egg).*$/$1/s;
      ($stdout,$stderr)=$handle->cmd($sudo."chmod o+r -v -R ".
         "/usr/local/lib/python2.7/site-packages/$stdout",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'pip install oauth2','__display__');
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd('echo /usr/local/lib > '.
         'local.conf','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v 644 local.conf',
         '__display__');
      ($stdout,$stderr)=$handle->cmd(
         $sudo.'mv -v local.conf /etc/ld.so.conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'ldconfig');
   } else {
      ($stdout,$stderr)=$handle->cmd('pip install awscli','__display__');
   }
}
}
$do=1;
if ($do==1) {
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git clone https://github.com/zeromq/zeromq4-x.git',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('zeromq4-x');
   my $zmq_branch='v4.0.1';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "git checkout $zmq_branch",'__display__');
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd("./autogen.sh",'__display__');
      $handle->cmd_raw('export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig');
      ($stdout,$stderr)=$handle->cmd('./configure','__display__');
      my $ad="        -no-undefined \\%NL%".
             "        -avoid-version \\";
      ($stdout,$stderr)=$handle->cmd(
         "sed -i \'/^libzmq_la_LDFLAGS = \\/a$ad\' ./Makefile");
      ($stdout,$stderr)=$handle->cmd( # bash shell specific
         "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
         "./Makefile");
   } else {
      # Following cmd shows default pkg-config locations
      # pkg-config --variable pc_path pkg-config
      $handle->cmd_raw('export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig');
      my $e='PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ';
      ($stdout,$stderr)=$handle->cmd($sudo.$e."./autogen.sh",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.$e.'./configure','__display__');
      my $ad="Defaults    env_keep += \"PKG_CONFIG_PATH\"";
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'/_XKB_CHARSET/a$ad\' /etc/sudoers")
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
}
$do=1;
if ($do==1) { # INSTALL LATEST VERSION OF NGINX
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # http://search.cpan.org/dist/Catalyst-Manual-5.9002/lib/Catalyst/
   #    Manual/Deployment/nginx/FastCGI.pod
   # https://serverfault.com/questions/171047/why-is-php-request-array-empty
   # https://codex.wordpress.org/Nginx
   # https://www.sitepoint.com/setting-up-php-behind-nginx-with-fastcgi/
   # http://codingsteps.com/install-php-fpm-nginx-mysql-on-ec2-with-amazon-linux-ami/
   # http://code.tutsplus.com/tutorials/revisiting-open-source-social-networking-installing-gnu-social--cms-22456
   # https://wiki.loadaverage.org/clipbucket/installation_guides/install_like_loadaverage
   # https://karp.id.au/social/index.html
   # http://jeffreifman.com/how-to-install-your-own-private-e-mail-server-in-the-amazon-cloud-aws/
   # https://www.wpwhitesecurity.com/creating-mysql-wordpress-database/
   #($stdout,$stderr)=$handle->cmd($sudo.'groupadd www-data');
   #($stdout,$stderr)=$handle->cmd($sudo.'adduser -r -m -g www-data www-data');
   #$handle->print($sudo.'passwd www-data');
   my $prompt=$handle->prompt();
   while (0) {
      my $output.=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'New password:') {
         $handle->print($service_and_cert_password);
         $output='';
         next;
      } elsif (-1<index $output,'Retype new password:') {
         $handle->print($service_and_cert_password);
         $output='';
         next;
      }
   }
   my $nginx_path='/etc';
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rm -rvf /etc/nginx','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget -qO- https://nginx.org/en/download.html");
   $stdout=~s/^.*Mainline.*?\/download\/(.*?)\.tar\.gz.*$/$1/s;
   my $nginx=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo."wget --random-wait --progress=dot ".
      "http://nginx.org/download/$nginx.tar.gz",300,'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."tar xvf $nginx.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd($nginx);
   ($stdout,$stderr)=$handle->cmd($sudo."mkdir -vp objs/lib",'__display__');
   ($stdout,$stderr)=$handle->cwd("objs/lib");
   ($stdout,$stderr)=$handle->cmd("wget -qO- https://ftp.pcre.org/pub/pcre/");
   my %pcre=();
   my %conv=(
      Jan => 0, Feb => 1, Mar => 2, Apr => 3, May => 4, Jun => 5, Jul => 6,
      Aug => 7, Sep => 8, Oct => 9, Nov => 10, Dec => 11
   );
   foreach my $line (split /\n/, $stdout) {
      last unless $line;
      $line=~/^.*?["](.*?)["].*(\d\d-\w\w\w-\d\d\d\d \d\d:\d\d).*(\d+\w).*$/;
      my $file=$1;my $date=$2;my $size=$3;
      next if $file=~/^pcre2|\.sig$|\.tar\.gz$|\.tar\.bz2$/;
      next if $file!~/\.zip$/;
      next unless $date;
      $date=~/^(\d\d)-(\w\w\w)-(\d\d\d\d) (\d\d):(\d\d)$/;
      my $day=$1;my $month=$2;my $year=$3;my $hour=$4,my $minute=$5;
      my $timestamp=timelocal(0,$minute,$hour,$day,$conv{$month},--$year);
      $pcre{$timestamp}=[$file,$size];
   }
   my $latest=(reverse sort keys %pcre)[0];
   my $pcre=$pcre{$latest}->[0];
   $pcre=~s/\.[^\.]+$//;
   my $checksum='';
   foreach my $cnt (1..3) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "https://ftp.pcre.org/pub/pcre/$pcre.tar.gz",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf $pcre.tar.gz",'__display__');
      last unless $stderr;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "rm -rfv $pcre.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget -qO- http://zlib.net/index.html");
   my $zlib_ver=$stdout;
   my $sha__256=$stdout;
   $zlib_ver=~s/^.*? source code, version (\d+\.\d+\.\d+).*$/$1/s;
   $sha__256=~s/^.*?SHA-256 hash [<]tt[>](.*?)[<][\/]tt[>].*$/$1/s;
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "http://zlib.net/zlib-$zlib_ver.tar.gz",'__display__');
      $checksum=$sha__256;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sha256sum -c - <<<\"$checksum zlib-$zlib_ver.tar.gz\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for zlib-$zlib_ver *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for ".
               "zlib-$zlib_ver.tar.gz *FAILED* ",
               "after $count attempts\n";
         cleanup;
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "rm -rvf zlib-$zlib_ver.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo."tar xvf zlib-$zlib_ver.tar.gz",
      '__display__');
   my $ossl='openssl-1.1.1c';
   foreach my $count (1..3) {
      $checksum='71b830a077276cbeccc994369538617a21bee808';
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "https://www.openssl.org/source/$ossl.tar.gz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sha1sum -c - <<<\"$checksum $ossl.tar.gz\"",'__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $ossl *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $ossl.tar.gz *FAILED* ",
               "after $count attempts\n";
         cleanup;
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "rm -rvf $ossl.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo."tar xvf $ossl.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/
   # https://www.hrupin.com/2017/07/how-to-automatically-restart-nginx
   ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI/deps/$nginx");
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60   * - \\x2A
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   # https://www.lisenet.com/2014/ - bash approach to conversion
   my $inet_d_script=<<'END';
#\\x21/bin/sh
#
# nginx - this script starts and stops the nginx daemin
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse \
#               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /etc/nginx/nginx.conf
# pidfile:     /var/run/nginx.pid
# user:        nginx

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ \\x22\\x24NETWORKING\\x22 = \\x22no\\x22 ] && exit 0

nginx=\\x22/usr/sbin/nginx\\x22
prog=\\x24(basename \\x24nginx)

NGINX_CONF_FILE=\\x22/etc/nginx/nginx.conf\\x22

lockfile=/var/run/nginx.lock

start() {
    [ -x \\x24nginx ] || exit 5
    [ -f \\x24NGINX_CONF_FILE ] || exit 6
    echo -n \\x24\\x22Starting \\x24prog: \\x22
    daemon \\x24nginx -c \\x24NGINX_CONF_FILE
    retval=\\x24?
    echo
    [ \\x24retval -eq 0 ] && touch \\x24lockfile
    return \\x24retval
}

stop() {
    echo -n \\x24\\x22Stopping \\x24prog: \\x22
    killproc \\x24prog -QUIT
    retval=\\x24?
    echo
    [ \\x24retval -eq 0 ] && rm -f \\x24lockfile
    return \\x24retval
}

restart() {
    configtest || return \\x24?
    stop
    start
}

reload() {
    configtest || return \\x24?
    echo -n \\x24\\x22Reloading \\x24prog: \\x22
    killproc \\x24nginx -HUP
    RETVAL=\\x24?
    echo
}

force_reload() {
    restart
}

configtest() {
  \\x24nginx -t -c \\x24NGINX_CONF_FILE
}

rh_status() {
    status \\x24prog
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case \\x22\\x241\\x22 in
    start)
        rh_status_q && exit 0
        \\x241
        ;;
    stop)
        rh_status_q || exit 0
        \\x241
        ;;
    restart|configtest)
        \\x241
        ;;
    reload)
        rh_status_q || exit 7
        \\x241
        ;;
    force-reload)
        force_reload
        ;;
    status)
        rh_status
        ;;
    condrestart|try-restart)
        rh_status_q || exit 0
            ;;
    *)
        echo \\x24\\x22Usage: \\x240 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}\\x22
        exit 2
esac
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$inet_d_script\" > ".
      "~/nginx");
   ($stdout,$stderr)=$handle->cmd($sudo.'mv -fv ~/nginx /etc/init.d',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v +x /etc/init.d/nginx',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."chkconfig --add nginx");
   ($stdout,$stderr)=$handle->cmd($sudo."chkconfig --level 345 nginx on");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install certbot-nginx','__display__');
   # https://www.digitalocean.com/community/tutorials/
   # how-to-secure-nginx-with-let-s-encrypt-on-centos-7
   my $make_nginx="./configure --user=$username ".
                  "--group=$username ".
                  "--prefix=$nginx_path/nginx ".
                  '--sbin-path=/usr/sbin/nginx '.
                  "--conf-path=$nginx_path/nginx/nginx.conf ".
                  '--pid-path=/var/run/nginx.pid '.
                  '--lock-path=/var/run/nginx.lock '.
                  '--error-log-path=/var/log/nginx/error.log '.
                  '--http-log-path=/var/log/nginx/access.log '.
                  "--with-http_ssl_module --with-pcre=objs/lib/$pcre ".
                  "--with-zlib=objs/lib/zlib-$zlib_ver ".
                  '--with-http_gzip_static_module '.
                  '--with-http_ssl_module '.
                  '--with-file-aio '.
                  '--with-http_realip_module '.
                  '--without-http_scgi_module '.
                  '--without-http_uwsgi_module '.
                  '--with-http_v2_module';
   ($stdout,$stderr)=$handle->cmd($sudo.$make_nginx,'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's/-Werror //' ./objs/Makefile");
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/
   my $ngx="$nginx_path/nginx/nginx.conf";
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/1024/64/' ".$ngx);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's/worker_processes  1;/worker_processes  2;/' ".$ngx);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/root   html/{//d;}' ".$ngx);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/index  index.html/{//d;}' ".$ngx);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'/koi8-r/a%NL%        root ${home_dir}FullAutoAPI/root;\' ".
      $ngx);
   $handle->cmd_raw($sudo.
       "sed -i 's/\\(^root.*;$\\\)/    \\1/' $ngx");
   $ad='            include        fastcgi_params;%NL%'.
       "            fastcgi_param  SCRIPT_NAME %SQ%%SQ%;%NL%".
       '            fastcgi_param  PATH_INFO  $fastcgi_script_name;%NL%'.
       '            fastcgi_pass   unix:/tmp/fullautoapi.socket;';
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' $ngx
END
   $handle->cmd_raw($sudo.$ad);
   $ad='%NL%        location /static {'.
       "%NL%            root ${home_dir}FullAutoAPI/root;".
       '%NL%        }%NL%';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/404/a$ad\' ".$ngx);
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".$ngx);
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SQ%/\'/g\" ".$ngx);
   foreach my $port (443,444,445,443) {
      $avail_port=
      `true &>/dev/null </dev/tcp/127.0.0.1/$port && echo open || echo closed`;
      my $status=$avail_port;
      $avail_port=$port;
      chomp($status);
      last if $status eq 'closed';
   }
   $ad='client_max_body_size 10M;';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/octet-stream/i$ad\' ".$ngx);
   $handle->cmd_raw($sudo.
       "sed -i 's/\\(^client_max_body_size 10M;$\\\)/    \\1/' $ngx");
   #($stdout,$stderr)=$handle->cmd($sudo.
   #    "sed -i \'s/^        listen       80/        listen       ".
   #    "\*:$avail_port ssl http2 default_server/\' ".
   #    $nginx_path."/nginx/nginx.conf");
   #($stdout,$stderr)=$handle->cmd($sudo.
   #    "sed -i 's/SCRIPT_NAME/PATH_INFO/' ".
   #    $nginx_path."/local/nginx/fastcgi_params");
   #$ad='# Catalyst requires setting PATH_INFO (instead of SCRIPT_NAME)'.
   #    ' to \$fastcgi_script_name';
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "sed -i \'/PATH_INFO/i$ad\' $nginx_path/nginx/fastcgi_params");
   #$ad='fastcgi_param  SCRIPT_NAME        /;';
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "sed -i \'/PATH_INFO/a$ad\' $nginx_path/nginx/fastcgi_params");
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
   #   "$nginx_path/nginx/fastcgi_params");
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60   * - \\x2A
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   # https://www.lisenet.com/2014/ - bash approach to conversion
   my $script=<<END;
use Net::FullAuto;
\\x24Net::FullAuto::FA_Core::debug=1;
my \\x24handle=connect_shell();
\\x24handle->print('$nginx_path/nginx/nginx -g \\x22daemon on;\\x22');
\\x24prompt=\\x24handle->prompt();
my \\x24output='';my \\x24password_not_submitted=1;
while (1) {
   eval {
      local \\x24SIG{ALRM} = sub { die \\x22alarm\\x5Cn\\x22 };# \\x5Cn required
      alarm 10;
      my \\x24output=fetch(\\x24handle);
      last if \\x24output=~/\\x24prompt/;
      print \\x24output;
      if ((-1<index \\x24output,'Enter PEM pass phrase:') &&
            \\x24password_not_submitted) {
         \\x24handle->print(\\x24ARGV[0]);
         \\x24password_not_submitted=0;
      }
   };
   if (\\x24\@) {
      \\x24handle->print();
      next;
   }
}
exit 0;
END
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cwd("~/WordPress");
      my $vimrc=<<END;
set paste
set mouse-=a
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$vimrc\" > ~/.vimrc");
      ($stdout,$stderr)=$handle->cmd("mkdir -vp script",'__display__');
      ($stdout,$stderr)=$handle->cmd("touch script/start_nginx.pl");
      ($stdout,$stderr)=$handle->cmd("chmod -v 755 script/start_nginx.pl",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("chmod o+r $nginx_path/nginx/*",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("chmod -v 755 $nginx_path/nginx/nginx.exe",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("echo -e \"$script\" > ".
         "script/start_nginx.pl");
      ($stdout,$stderr)=$handle->cmd("cygrunsrv -I nginx_first_time ".
         "-p /bin/perl -a ".
         "\'${home_dir}WordPress/script/start_nginx.pl ".
         "\"$service_and_cert_password\"'");
      ($stdout,$stderr)=$handle->cmd("cygrunsrv --start nginx_first_time",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("touch script/first_time_start.flag");
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/server_name  localhost/".
         "server_name $domain_url www.$domain_url/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/#user  nobody;/user  $username;/\' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/#error_page  404              /404.html;/".
         "error_page  404              /404.html;/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.'service nginx start',
         '__display__');
      ($stdout,$stderr)=$handle->cwd("$nginx_path/nginx");
      foreach my $num (1..3) {
         sleep 3;
         ($stdout,$stderr)=clean_filehandle($handle);
         $handle->print($sudo.
            "certbot --nginx -d $domain_url -d www.$domain_url");
         $prompt=$handle->prompt();
         my $output='';
         while (1) {
            $output.=fetch($handle);
            last if $output=~/$prompt/;
            print $output;
            if (-1<index $output,'Attempt to reinstall') {
               $handle->print('1');
               $output='';
            } elsif (-1<index $output,'No redirect') {
               $handle->print('2');
               $output='';
            } elsif (-1<index $output,'Enter email address') {
               $handle->print('brian.kelly@fullauto.com');
               $output='';
            } elsif (-1<index $output,'Terms of Service') {
               $handle->print('A');
               $output='';
            } elsif (-1<index $output,'Would you be willing') {
               $handle->print('Y');
               $output='';
            } elsif ((-1<index $output,'existing certificate')
                  && (-1==index $output,'--duplicate')) {
               $handle->print('C');
               $output='';
            }
         }
         ($stdout,$stderr)=clean_filehandle($handle);
         ($stdout,$stderr)=$handle->cmd($sudo.
            'grep Certbot /etc/nginx/nginx.conf');
         last if $stdout;
      }
      # https://ssldecoder.org
      ($stdout,$stderr)=$handle->cmd($sudo."service nginx restart",
         '__display__');
   }
}
$do=0;
if ($do==1) { # NGINX
print "DOING NGINX\n";
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # http://search.cpan.org/dist/Catalyst-Manual-5.9002/lib/Catalyst/
   #    Manual/Deployment/nginx/FastCGI.pod
   my $nginx='nginx-1.10.0';
   $nginx='nginx-1.9.13' if $^O eq 'cygwin';
   ($stdout,$stderr)=$handle->cmd($sudo."wget --random-wait --progress=dot ".
      "http://nginx.org/download/$nginx.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $nginx.tar.gz",'__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd("tar xvf $nginx.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd($nginx);
   ($stdout,$stderr)=$handle->cmd("mkdir -vp objs/lib",'__display__');
   ($stdout,$stderr)=$handle->cwd("objs/lib");
   my $pcre='pcre-8.40';
   my $checksum='';
   ($stdout,$stderr)=$handle->cmd($sudo."wget --random-wait --progress=dot ".
      "ftp://ftp.csx.cam.ac.uk/pub/software/".
      "programming/pcre/$pcre.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $pcre.tar.gz",'__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd($sudo."tar xvf $pcre.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."wget -qO- http://zlib.net/index.html");
   my $zlib_ver=$stdout;
   my $sha__256=$stdout;
   $zlib_ver=~s/^.*? source code, version (\d+\.\d+\.\d+).*$/$1/s;
   $sha__256=~s/^.*?tar.gz.*?SHA-256 hash [<]tt[>](.*?)[<][\/]tt[>].*$/$1/s;
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd($sudo."wget --random-wait --progress=dot ".
         "http://zlib.net/zlib-$zlib_ver.tar.gz",'__display__');
      $checksum=$sha__256;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sha256sum -c - <<<\"$checksum *zlib-$zlib_ver.tar.gz\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for zlib-$zlib_ver *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for ".
               "zlib-$zlib_ver.tar.gz *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf zlib-$zlib_ver.tar.gz",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo."tar xvf zlib-$zlib_ver.tar.gz",
      '__display__');
   my $ossl='openssl-1.0.2h';
   $checksum='577585f5f5d299c44dd3c993d3c0ac7a219e4949';
   ($stdout,$stderr)=$handle->cmd($sudo."wget --random-wait --progress=dot ".
      "https://www.openssl.org/source/$ossl.tar.gz",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $ossl.tar.gz",'__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd("sha1sum -c - <<<\"$checksum *$ossl.tar.gz\"",
      '__display__');
   unless ($stderr) {
      print(qq{ + CHECKSUM Test for $ossl *PASSED* \n});
   } else {
      ($stdout,$stderr)=$handle->cmd("rm -rvf $ossl.tar.gz",'__display__');
      my $dc=1;
      print "FATAL ERROR! : CHECKSUM Test for $ossl.tar.gz *FAILED* ",
            "after $dc attempts\n";
      &Net::FullAuto::FA_Core::cleanup;
   }
   ($stdout,$stderr)=$handle->cmd("tar xvf $ossl.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI/deps/$nginx");
   my $make_nginx='./configure --sbin-path=/usr/local/nginx/nginx '.
                  '--conf-path=/usr/local/nginx/nginx.conf '.
                  '--pid-path=/usr/local/nginx/nginx.pid '.
                  "--with-http_ssl_module --with-pcre=objs/lib/$pcre ".
                  "--with-zlib=objs/lib/zlib-$zlib_ver";
   ($stdout,$stderr)=$handle->cmd($make_nginx,'__display__');
   ($stdout,$stderr)=$handle->cmd(
      $sudo."sed -i 's/-Werror //' ./objs/Makefile");
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/
   ($stdout,$stderr)=$handle->cmd(
      $sudo.'mkdir -vp /etc/nginx/ssl.key');
   ($stdout,$stderr)=$handle->cmd(
      $sudo.'mkdir -vp /etc/nginx/ssl.crt');
   ($stdout,$stderr)=$handle->cmd(
      $sudo.'mkdir -vp /etc/nginx/ssl.csr');
   $handle->print(
      $sudo.'openssl genrsa -des3 -out '.
      "/etc/nginx/ssl.key/$public_ip.key 2048");
   $prompt=$handle->prompt();
   $prompt=~s/\$$//;
   while (1) {
      my $output.=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'pass phrase for') {
         $handle->print($service_and_cert_password);
         $output='';
         next;
      } elsif (-1<index $output,'Verifying - Enter') {
         $handle->print($service_and_cert_password);
         $output='';
         next;
      }
   }
   while (1) {
      my $trys=0;
      my $ereturn=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         $handle->print($sudo.
            "openssl req -new -key /etc/nginx/ssl.key/$public_ip.key ".
            "-out /etc/nginx/ssl.csr/$public_ip.csr");
         my $test='';my $output='';
         while (1) {
            $output.=Net::FullAuto::FA_Core::fetch($handle);
            $test.=$output;
            $test=~tr/\0-\11\14-\37\177-\377//d;
            return 'DONE' if $output=~/$prompt/;
            print $output;
            $test=~s/\n//gs;
            if ($test=~/Enter pass phrase.*key:/s) {
               $handle->print($service_and_cert_password);
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'[AU]:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'[Some-State]:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'city) []:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'Pty Ltd]:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'section) []:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'YOUR name) []:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'Address []:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'challenge password []:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'company name []:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'Country Name (2 letter code) [XX]') {
               $handle->print('.');
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'State or Province Name (full name) []') {
               $handle->print('.');
               $output='';
               $test='';
               next;
            } elsif (
                  -1<index $test,'Locality Name (eg, city) [Default City]:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,
                 'Organization Name (eg, company) [Default Company Ltd]:') {
               $handle->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,
                 'Common Name (eg, your name or your server\'s hostname) []') {
               $handle->print();
               $output='';
               $test='';
               next;
            }
         }
         return 'DONE';
      };
      alarm(0);
      last if $ereturn eq 'DONE' || $trys++>3;
   }
   $handle->print($sudo.
      'openssl x509 -req -days 365 -in '.
      "/etc/nginx/ssl.csr/$public_ip.csr -signkey ".
      "/etc/nginx/ssl.key/$public_ip.key -out ".
      "/etc/nginx/ssl.crt/$public_ip.crt");
   while (1) {
      my $output=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'Enter pass phrase') {
         $handle->print($service_and_cert_password);
      } 
   }
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/1024/64/' ".
      "/usr/local/nginx/nginx.conf");
   $ad="            include fastcgi_params;%NL%".
       "            fastcgi_pass localhost:3003;";
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' /usr/local/nginx/nginx.conf
END
   $handle->cmd_raw($sudo.$ad);
   $ad='%NL%        location /static {'.
       "%NL%            root ${home_dir}FullAutoAPI/root;".
       '%NL%        }%NL%'.
       '%NL%        ssl on;'.
       "%NL%        ssl_certificate /etc/nginx/ssl.crt/$public_ip.crt;".
       "%NL%        ssl_certificate_key /etc/nginx/ssl.key/$public_ip.key;".
       '%NL%        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;'.
       '%NL%        ssl_ciphers '.
       '"HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/404/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/^        listen       80/        listen       ".
       "\*:443 ssl default_server/\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i 's/SCRIPT_NAME/PATH_INFO/' ".
      "/usr/local/nginx/fastcgi_params");
   $ad='# Catalyst requires setting PATH_INFO (instead of SCRIPT_NAME)'.
       ' to \$fastcgi_script_name';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'/PATH_INFO/i$ad\' /usr/local/nginx/fastcgi_params");
   $ad='fastcgi_param  SCRIPT_NAME        /;';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'/PATH_INFO/a$ad\' /usr/local/nginx/fastcgi_params");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      "/usr/local/nginx/fastcgi_params");
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   my $script=<<END;
use Net::FullAuto;
\\x24Net::FullAuto::FA_Core::debug=1;
my \\x24handle=connect_shell();
\\x24handle->print('/usr/local/nginx/nginx -g \\x22daemon on;\\x22');
\\x24prompt=\\x24handle->prompt();
my \\x24output='';my \\x24password_not_submitted=1;
while (1) {
   eval {
      local \\x24SIG{ALRM} = sub { die \\x22alarm\\x5Cn\\x22 };# \\x5Cn required
      alarm 10;
      my \\x24output=Net::FullAuto::FA_Core::fetch(\\x24handle);
      last if \\x24output=~/\\x24prompt/;
      print \\x24output;
      if ((-1<index \\x24output,'Enter PEM pass phrase:') &&
            \\x24password_not_submitted) {
         \\x24handle->print(\\x24ARGV[0]);
         \\x24password_not_submitted=0;
      }
   };
   if (\\x24\@) {
      \\x24handle->print();
      next;
   }
}
exit 0;
END
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI");
      my $vimrc=<<END;
set paste
set mouse-=a
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$vimrc\" > ~/.vimrc");
      ($stdout,$stderr)=$handle->cmd("mkdir -vp script",'__display__');
      ($stdout,$stderr)=$handle->cmd("touch script/start_nginx.pl");
      ($stdout,$stderr)=$handle->cmd("chmod -v 755 script/start_nginx.pl",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("chmod -v o+r /usr/local/nginx/*",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("chmod -v 755 /usr/local/nginx/nginx.exe",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("echo -e \"$script\" > ".
         "script/start_nginx.pl");
      ($stdout,$stderr)=$handle->cmd("cygrunsrv -I nginx_first_time ".
         "-p /bin/perl -a ".
         "\'${home_dir}FullAutoAPI/script/start_nginx.pl ".
         "\"$service_and_cert_password\"'");
      ($stdout,$stderr)=$handle->cmd("cygrunsrv --start nginx_first_time",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("touch script/first_time_start.flag");
   } else {
      $handle->print($sudo."/usr/local/nginx/nginx");
      $prompt=$handle->prompt();
      while (1) {
         my $output=fetch($handle);
         last if $output=~/$prompt/;
         print $output;
         if (-1<index $output,'PEM pass phrase') {
            $handle->print($service_and_cert_password);
         }
      }
   }
}
$do=0;
if ($do==1) {
   ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI/deps");
   my $go=$1;my $gosha1=$2;
   ($stdout,$stderr)=$handle->cmd($sudo."wget -qO- https://golang.org/dl");
   if ($^O eq 'cygwin') {
      $stdout=~
         /^.*?href=["]([^"]+windows-amd64.zip)["].*?[<]tt[>](.*?)[<].*$/s;
      $go=$1;$gosha1=$2;
   } else {
      $stdout=~
         /^.*?href=["]([^"]+linux-amd64.tar.gz)["].*?[<]tt[>](.*?)[<].*$/s;
      $go=$1;$gosha1=$2;
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".$go,
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $go",'__display__')
      if $^O ne 'cygwin';
   $go=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd("sha1sum -c - <<<\"$gosha1 *$go\"",
      '__display__');
   unless ($stderr) {
      print(qq{ + CHECKSUM Test for $go *PASSED* \n});
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf $go",'__display__');
      print "FATAL ERROR! : CHECKSUM Test for $go *FAILED* ";
      &Net::FullAuto::FA_Core::cleanup;
   }
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd("unzip -o $go",'__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd("tar zxvf $go",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("rm -rvf $go",'__display__');
}
$do=0;
if ($do==1) {
   ($stdout,$stderr)=$handle->cmd($sudo.'wget -qO- '.
      'https://github.com/membrane/service-proxy/releases/latest');
   $stdout=~s/^.*?href=["]([^"]+zip)["].*$/$1/s;
   my $membrane_zip=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot https://github.com".$membrane_zip,
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $membrane_zip",'__display__')
      if $^O ne 'cygwin';
   $membrane_zip=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd("unzip -o $membrane_zip",'__display__');
   ($stdout,$stderr)=$handle->cmd("rm -rvf $membrane_zip",'__display__');
   #($stdout,$stderr)=$handle->cmd('git clone --depth=1 '.
   #   'https://github.com/membrane/service-proxy.git','__display__');
exit;
}
   unless (-e '/usr/bin/cpan') {
      if ($^O eq 'cygwin') {
         $handle->print('cpan');
      } else {
         ($stdout,$stderr)=$handle->cmd($sudo.'yum -y install cpan',
            '__display__');
         $handle->print($sudo.'cpan');
      } 
      $prompt=$handle->prompt();
      while (1) {
         my $output=fetch($handle);
         last if $output=~/$prompt/;
         print 'm'.$output;
         if (-1<index $output,'possible automatically') {
            $handle->print('yes');
         } elsif (-1<index $output,'by bootstrapping') {
            $handle->print('sudo');
         } elsif (-1<index $output,'some CPAN') {
            $handle->print('no');
         } elsif (-1<index $output,'pick from') {
            $handle->print('no');
         } elsif (-1<index $output,'CPAN site') {
            $handle->print('http://www.cpan.org');
         } elsif (-1<index $output,'ENTER to quit') {
            $handle->print();
         } elsif ($output=~/cpan[[]\d+[]][>]/) {
            $handle->print('bye');
         }
      }
   }
   ($stdout,$stderr)=$handle->cmd("export PERL_MM_USE_DEFAULT=1");
   if ($^O eq 'cygwin') {
      my $show=<<END;
########################################

   INSTALLING Starman

########################################
END
      print $show;
      $handle->cmd_raw($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","Starman")\'',
         '__display__');
      $show=<<END;
########################################

   INSTALLING HTTP::Server::Simple

########################################
END
      print $show;
      $handle->cmd_raw($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","HTTP::Server::Simple")\'',
         '__display__');
   }
   my $show=<<END;
########################################

   INSTALLING autodie

########################################
END
      print $show;
      ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI/deps");
      $stdout=$handle->cmd_raw($sudo.
         'perl -MCPAN -e \'CPAN::Shell->get('.
         '"install","autodie")\'',
         '__display__');
      $stdout=~s/^.*Checksum for (.*autodie.*gz) ok.*$/$1/s;
      my $gzfile=$stdout;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "cp -v $gzfile ~/FullAutoAPI/deps",'__display__');
      $stdout=~/^(.*)\/(.*gz)$/;
      my $modpath=$1;my $modfile=$2;
      ($stdout,$stderr)=$handle->cmd(
         "tar zxvf $modfile",'__display__');
      ($stdout,$stderr)=$handle->cwd("autodie*");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/\"Test::Perl/#\"Test::Perl/' Makefile.PL");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'perl Makefile.PL','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('..');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rvf autodie*','__display__');
      ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI/deps");
   $show=<<END;
########################################

   INSTALLING Perl::Critic

########################################
END
      print $show;
      $handle->cmd_raw($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","Perl::Critic")\'',
         '__display__');
   $show=<<END;
########################################

   INSTALLING IO::CaptureOutput

########################################
END
      print $show;
      $handle->cmd_raw($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","IO::CaptureOutput")\'',
         '__display__');
   $show=<<END;
########################################

   INSTALLING Devel::CheckLib

########################################
END
      print $show;
      $handle->cmd_raw($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","Devel::CheckLib")\'',
         '__display__');
   $show=<<END;
########################################

   INSTALLING ExtUtils::Embed

########################################
END
   #print $show;
   #$handle->cmd_raw(
   #   'sudo perl -MCPAN -e \'CPAN::Shell->force('.
   #   '"install","ExtUtils::Embed")\'',
   #   '__display__');
   my @cpan_modules = qw(

      Test::More
      Text::Glob
      File::Find::Rule
      Crypt::UnixCrypt_XS
      Digest::CRC
      Data::Integer
      Data::Float
      HTTP::Lite
      Authen::Passphrase
      DBICx::TestDatabase
      Class::Mix
      Crypt::MySQL
      Module::Build
      AnyEvent
      Test::Requires
      Proc::Guard
      ZMQ::LibZMQ4
      CPAN::Meta
      ExtUtils::ParseXS
      Package::Generator
      Test::Output
      Compress::Raw::Bzip2
      IO::Compress::Bzip2
      Package::Anon
      Text::Diff
      Archive::Tar
      Archive::Zip
      inc::latest
      PAR::Dist
      Regexp::Common
      Pod::Checker
      Pod::Parser
      Pod::Man
      File::Slurp
      Test::Taint
      Test::Warnings
      Test::Without::Module
      Devel::LexAlias
      BSD::Resource
      IPC::System::Simple
      Sub::Identify
      Fatal
      Sub::Name
      Role::Tiny
      Test::LeakTrace
      Test::CleanNamespaces
      Test::Pod
      Test::Pod::Coverage
      Class::Load
      Class::Load::XS
      Algorithm::C3
      SUPER
      Module::Refresh
      Declare::Constraints::Simple
      Devel::Cycle
      CGI
      Test::Memory::Cycle
      IO::String
      Mouse::Tiny
      DateTime::Format::MySQL
      Moose
      Moo
      MooseX::Role::WithOverloading
      Pod::Coverage::Moose
      MooseX::AttributeHelpers
      MooseX::ConfigFromFile
      MooseX::MarkAsMethods
      MooseX::SimpleConfig
      MooseX::StrictConstructor 
      MooseX::NonMoose
      Net::FullAuto
      Time::HiRes
      Business::ISBN
      App::FatPacker
      JSON
      JSON::XS
      Test::DistManifest
      Term::Size::Any
      Type::Tiny
      File::ReadBackwards
      Imager
      Astro::MoonPhase
      Date::Manip
      XML::LibXML
      SQL::Translator
      Template::Alloy
      URI::Amazon::APA 
      Catalyst::Runtime
      Proc::ProcessTable
      Parallel::Forker
      UUID::Tiny
      Regexp::Assemble
      Bytes::Random::Secure
      Math::Random::ISAAC::XS
      HTML::FormHandler
      Crypt::PassGen
      Catalyst::Controller::HTML::FormFu
      HTML::FormHandler::Model::DBIC
      HTML::FormHandler::Model::DBIC
      CatalystX::OAuth2
      Task::Catalyst::Tutorial
      YAML::Syck
      Catalyst::Model::Adaptor

   );

      #EXODIST/Test-Simple-1.001014.tar.gz
      #Test::Aggregate
      #Test::Aggregate::Nested

# https://metacpan.org/pod/DBIx::Class::Manual::Cookbook#Predefined-searches
# # http://ajct.info/2015/08/16/oauth-and-catalyst.html
# # http://stackoverflow.com/questions/23652166/how-to-generate-oauth-2-client-id-and-secret
# # https://bshaffer.github.io/oauth2-server-php-docs/grant-types/refresh-token/


   # http://cygwin.1069669.n5.nabble.com/where-is-my-quot-usr-dict-
   # words-quot-or-quot-usr-share-dict-words-on-cygwin-1-7-td59328.html
   ($stdout,$stderr)=$handle->cwd('deps');
   my $mirror='https://dl.fedoraproject.org/pub/fedora/linux/releases/';
   # "http://mirrors.maine.edu/Fedora/releases/";
   ($stdout,$stderr)=$handle->cmd($sudo."wget -qO- $mirror");
   my @num=();
   foreach my $line (split /\n/, $stdout) {
      next unless $line=~/DIR/;
      $line=~/^.*DIR.*href=["](\d+)\/["].*$/;
      my $num=$1;
      next unless $num;
      push @num, $num;
   }
   my $num=(reverse sort {$a<=>$b} @num)[0];
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget -qO- $mirror$num/Server/x86_64/os/Packages/w/");
   $stdout=~s/^.*(words.*?rpm).*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "$mirror$num/Server/x86_64/os/Packages/w/$stdout",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username words*.rpm",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd(
      "rpm2cpio words*.rpm | \(cd /; cpio -idmv\)");
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v 755 /usr/share/dict/',
      '__display__');
   ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI");
   my $install_fullautoapi=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                     _
                   ((_)
                    /
                   /              _        _           _
               \__/_     ___ __ _| |_ __ _| |_   _ ___| |_
               /    \   / __/ _` | __/ _` | | | | / __| __|  Perl MVC
            _- |    |  | (_| (_| | || (_| | | |_| \__ \ |    framework
       _ _-'   \____/   \___\__,_|\__\__,_|_|\__, |___/\__|c
     ((_)       ---\                         |___/
                    \
                     \\_          Web Framework
                      (_)

     (Catalyst Foundation is **NOT** a sponsor of the FullAuto© Project.)
END
   foreach my $module (@cpan_modules) {
      next if $module=~/^\s*[#]/;
      my $show=<<END;
########################################

   INSTALLING $module

########################################
END
      sleep 1;
      print $show;
      if ($module eq 'Catalyst::Runtime') {
         print $install_fullautoapi;
         sleep 10;
      }
      if ($module eq 'Regexp::Assemble' ||
            $module eq 'ZMQ::LibZMQ4' ||
            $module eq 'CatalystX::OAuth2') {
         $handle->print($sudo.
            'perl -MCPAN -e \'CPAN::Shell->force('.
            "\"install\",\"$module\")\'"
         )
      } else {
         $handle->print($sudo."cpan $module 2>&1");
      }
      my $prompt=$handle->prompt();
      my $error=0;my $force=0;my $tries=0;my $allout='';my $save='';
      while (1) {
         my $done=eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
            alarm 120;
            select(undef,undef,undef,0.02);
            # sleep for 1/50th second;
            my $output='';
            ($output,$save)=fetch($handle,$save,'__display__');
            $allout.=$output;
            if ($output=~/$prompt/) {
               if ($error) {
                  $error=0;$force=1;
                  $handle->print($sudo.
                     'perl -MCPAN -e \'CPAN::Shell->force('.
                     "\"install\",\"$module\")\'"
                  )
               } elsif ($output=~/y\s*y\s*y/s) {
                  print "\n\nCLEARING MEMORY ...\n\n";
                  sleep 3;
                  clean_filehandle($handle);
                  $handle->close();
                  $handle=connect_shell();
                  return 'done';
               } else {
                  return 'done';
               }
            } elsif ($output=~/y\s*y\s*y/s) {
               print "\n\nCLEARING MEMORY ...\n\n";
               sleep 3;
               clean_filehandle($handle);
               $handle->close();
               $handle=connect_shell();
               return 'done';
            } elsif ($output=~/build the XS Stash module/) {
               $handle->print('y');
            } elsif ($output=~/use the XS Stash by default/) {
               $handle->print('y');
            } elsif ($output=~/it permanently/) {
               $handle->print('yes');
            } elsif ($output=~/from CPAN/) {
               $handle->print('yes');
            }
            if (!$force &&
                  ((-1<index $allout,'[test_dynamic] Error 255') ||
                  (-1<index $allout,'Connection reset by peer'))) {
               $error=1;
               #$output=~s/$prompt//gs;
            }
            #print $output;
            return 'continue';
         };
         next if $done eq 'continue';
         if ($done=~/^\d$/ && $done==1) {
            my $output=fetch($handle);
            my $attempt='attempts';
            $attempt='attempt' if $tries==0;
            print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                  ":  $module\n\n",
                  "                 --> $output\n",
                  "                 after ",++$tries," $attempt\n\n";
            cleanup;
         } elsif ($@ && ++$tries<4) {
            alarm(0);$allout='';
            $handle->print("\003");
            my $done=eval {
               local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
               while (my $ln=fetch($handle)) {
                  return 'done' if $ln=~/$prompt/s;
               }
            };
            if ($@) {
               my $attempt='attempts';
               $attempt='attempt' if $tries==0;
               print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                     ":  $module\n\n",
                     "                 --> could not recover handle after \n",
                     "                 ",++$tries," $attempt\n\n";
               cleanup;
            } elsif ($done) {
               next
            } else {
               print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                     "                 $module\n",
                     "                 - Unknown Error after ",
                     --$tries," attempts\n\n";
               cleanup;
            }
         } elsif ($tries>3) {
            my $attempt='attempts';
            print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                  ":  $module\n\n",
                  "                 after ",++$tries," $attempt\n\n";
            cleanup;
         }
         last if $done;
      }
   }
   $show=<<END;

########################################

   INSTALLING Catalyst::Devel

########################################
END
   print $show;
   if ($^O eq 'cygwin') {
      $handle->print($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","Catalyst::Devel")\'');
   } else {
      $handle->print($sudo.'cpan Catalyst::Devel');
   }
   $prompt=$handle->prompt();my $save='';
   while (1) {
      my $output='';
      ($output,$save)=fetch($handle,$save,'__display__');
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'XS Stash module?') {
         $handle->print('y');
      }
      if (-1<index $output,'XS Stash by default?') {
         $handle->print('y');
      }
   }
   $show=<<END;

########################################

   INSTALLING DBIx::Class

########################################
END
   $handle->cmd_raw($sudo.
      'perl -MCPAN -e \'CPAN::Shell->notest('.
      '"install","DBIx::Class")\'',
      '__display__');
   $show=<<END;

########################################

   INSTALLING DBIx::Class::Schema::Loader

########################################
END
   $handle->cmd_raw($sudo.
      'cpan DBIx::Class::Schema::Loader',
      '__display__');
#   $show=<<END;
#
########################################
#
#   INSTALLING Net::RabbitFoot
#
########################################
#END
#   print $show;
#   $handle->print($sudo.'cpan Net::RabbitFoot');
#   $prompt=$handle->prompt();
#   while (1) {
#      my $output.=fetch($handle);
#      last if $output=~/$prompt/;
#      print $output;
#      if (-1<index $output,'Skip further questions and use') {
#         $handle->print('y');
#         $output='';
#         next;
#      }
#   }
#   $show=<<END;
#
########################################
#
#   INSTALLING YAML::Syck
#
########################################
#END
#   print $show;
#   sleep 1;
#   $handle->cmd_raw($sudo.'cpan YAML::Syck','__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Controller::REST

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Controller::REST','__display__');
#   $show=<<END;
#
########################################
#
#   INSTALLING Catalyst::Model::Adaptor
#
########################################
#END
#   print $show;
#   sleep 1;
#   $handle->cmd_raw("${sudo}cpan Catalyst::Model::Adaptor",'__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::View::JSON

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::View::JSON',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::View::TT::Alloy

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::View::TT::Alloy',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Unicode

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Plugin::Unicode',
           '__display__');
   $show=<<END;

########################################

   INSTALLING DBIx::Class::PassphraseColumn

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan DBIx::Class::PassphraseColumn',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Authen::Passphrase::BlowfishCrypt

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Authen::Passphrase::BlowfishCrypt',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Method::Signatures::Simple

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Method::Signatures::Simple',
           '__display__');
#   $show=<<END;
#
########################################
#
#   INSTALLING HTML::FormHandler
#
########################################
#END
#   print $show;
#   sleep 1;
#   $handle->cmd_raw("${sudo}cpan HTML::FormHandler",
#           '__display__');
#   $show=<<END;
#
########################################
#
#   INSTALLING HTML::FormHandler::Model::DBIC
#
########################################
#END
#   print $show;
#   sleep 1;
#   $handle->cmd_raw("${sudo}cpan HTML::FormHandler::Model::DBIC",
#           '__display__');
   $show=<<END;

########################################

   INSTALLING CatalystX::SimpleLogin

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
      'perl -MCPAN -e \'CPAN::Shell->notest('.
      '"install","CatalystX::SimpleLogin")\'',
      '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Session

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Plugin::Session',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Session::Store::Memcached

########################################
END
   print $show;
   sleep 1;
   # http://vasil9v.tumblr.com/post/31921755331/compiling-memcached-on-cygwinwindows
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Plugin::Session::Store::Memcached',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Session::State::Cookie

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Plugin::Session::State::Cookie',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Authentication

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Plugin::Authentication',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Authentication::Store::DBIx::Class

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Authentication::Store::DBIx::Class',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Authorization::Roles

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Plugin::Authorization::Roles',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Time::Warp

########################################
END
   print $show;
   sleep 1;
   $handle->print($sudo.
      'perl -MCPAN -e \'CPAN::Shell->notest('.
      '"install","Time::Warp")\'');
   $show=<<END;

########################################

   INSTALLING DBIx::Class::TimeStamp

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan DBIx::Class::TimeStamp',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Controller::ActionRole

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Controller::ActionRole',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::ActionRole::ACL

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::ActionRole::ACL',
           '__display__');
   $show=<<END;

########################################

   INSTALLING FCGI

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.'cpan FCGI',
           '__display__');
   $show=<<END;

########################################

   INSTALLING FCGI::ProcManager

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan FCGI::ProcManager',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Helper::Model::DBIC::Schema

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::Helper::Model::DBIC::Schema',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::View::Email

########################################
END
   print $show;
   sleep 1;
   $handle->cmd_raw($sudo.
           'cpan Catalyst::View::Email',
           '__display__');
   $show=<<END;

########################################

   INSTALLING Finance::Quote

########################################
END
   print $show;
   $handle->print($sudo.'cpan Finance::Quote');
   $prompt=$handle->prompt();
   while (1) {
      my $output.=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'traffic to external sites') {
         $handle->print('Y');
         $output='';
         next;
      }
      if (-1<index $output,'have network connectivity. [n]') {
         $handle->print('y');
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd('catalyst.pl FullAutoAPI','__display__');
   ($stdout,$stderr)=$handle->cwd('FullAutoAPI');
   ($stdout,$stderr)=$handle->cmd('perl Makefile.PL','__display__');
   # http://www.catalystframework.org/calendar/2011/15
   # http://search.cpan.org/~bobtfish/Catalyst-Plugin-Authentication-0.10023/
   my $pm_path="./lib/FullAutoAPI.pm";
   $ad="    Session%NL%".
       "    Session::Store::Memcached%NL%".
       "    Session::State::Cookie%NL%".
       "    Authentication%NL%".
       "    Authorization::Roles%NL%".
       "    +CatalystX::SimpleLogin";
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i '/    Static::Simple/a$ad' $pm_path");
   $ad="    use_request_uri_for_path => 1,%NL%".
       "    authentication => {%NL%".
       "       default_realm => %SQ%users%SQ%,%NL%".
       "       realms        => {%NL%".
       "          users => {%NL%".
       "             credential => {%NL%".
       "                class          => %SQ%Password%SQ%,%NL%".
       "                password_field => %SQ%password%SQ%,%NL%".
       "                password_type  => %SQ%self_check%SQ%%NL%".
       "             },%NL%".
       "             store => {%NL%".
       "                class         => %SQ%DBIx::Class%SQ%,%NL%".
       "                user_model    => %SQ%DB::Users%SQ%,%NL%".
       "                role_relation => %SQ%roles%SQ%,%NL%".
       "                role_field    => %SQ%name%SQ%,%NL%".
       "             }%NL%".
       "          }%NL%".
       "       },%NL%".
       "    },%NL%".
       "    %SQ%Controller::Login%SQ% => {%NL%".
       "        traits => [%SQ%-RenderAsTTTemplate%SQ%],%NL%".
       "        login_form_args => {%NL%".
       "            authenticate_args => { active => %SQ%Y%SQ% },%NL%".
       "        },%NL%".
       "    },";
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i '/Send X-Catalyst header/a$ad' $pm_path");
   $handle->cmd_raw($sudo.
       "sed -i 's/\\(^use_request_uri$\\\)/    \\1/' $pm_path");
   $handle->cmd_raw($sudo.
       "sed -i 's/\\(^Session$\\\)/    \\1/' $pm_path");
   $handle->cmd_raw($sudo.
       "sed -i 's/\\(^authentication =.*\\\)/    \\1/' $pm_path");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" $pm_path");
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i \"s/%SQ%/\'/g\" $pm_path");
   ($stdout,$stderr)=$handle->cmd("mkdir -vp root/login",'__display__');
   ($stdout,$stderr)=$handle->cmd("touch root/login/login.tt2",
      '__display__');
   my $content=<<'ENDD';
[% META title = 'Welcome to the FullAuto API Management Dashboard: Please Log In' %]
<div>
    [% FOR field IN login_form.error_fields %]
        [% FOR error IN field.errors %]
            <p><span style=\\x22color: red;\\x22>[% field.label _ ': ' _ error %]</span></p>
        [% END %]
    [% END %]
</div>
 
<div>
    <form id=\\x22login_form\\x22 method=\\x22post\\x22 action=\\x22[% c.req.uri %]\\x22>
        <fieldset style=\\x22border: 0;\\x22>
            <table>
                <tr>
                    <td><label class=\\x22label\\x22 for=\\x22username\\x22>Username:</label></td>
                    <td><input type=\\x22text\\x22 name=\\x22username\\x22 value=\\x22\\x22 /></td>
                </tr>
                <tr>
                    <td><label class=\\x22label\\x22 for=\\x22password\\x22>Password:</label></td>
                    <td><input type=\\x22password\\x22 name=\\x22password\\x22 value=\\x22\\x22 /></td>
                </tr>
                <tr><td><input type=\\x22submit\\x22 name=\\x22submit\\x22 value=\\x22Login\\x22 /></td></tr>
            </table>
        </fieldset>
    </form>
</div>
ENDD
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/login/login.tt2");
   ($stdout,$stderr)=$handle->cmd("mkdir -vp root/email",'__display__');
   ($stdout,$stderr)=$handle->cmd("touch root/email/welcome.tt2",
      '__display__');
   $content=<<'END';
<\\x21DOCTYPE html PUBLIC \\x22-//W3C//DTD XHTML 1.0 Transitional//EN\\x22
    \\x22http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\\x22>
<html xmlns=\\x22http://www.w3.org/1999/xhtml\\x22
      xml:lang=\\x22en\\x22
      lang=\\x22en\\x22>
<head>
</head>
<body>
<h2 align=\\x22center\\x22>Welcome to the FullAuto API Management Dashboard.</h2>
<p>Your username is: <span style=\\x22color: green;\\x22>[% username %]</span></p>
<p>Your initial password is: <span style=\\x22color: red;\\x22>[% password %]</span></p>
<p>Your client id is: <span style=\\x22color: purple;\\x22>[% client_id %]</span></p>
<p>Your client secret is: <span style=\\x22color: purple;\\x22>[% client_secret %]</span></p>
<p>You will be asked to change your password on first login.</p>
</body>
</html>
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/email/welcome.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/email/reset_password.tt2",
      '__display__');
   $content=<<'END';
<\\x21DOCTYPE html PUBLIC \\x22-//W3C//DTD XHTML 1.0 Transitional//EN\\x22
    \\x22http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\\x22>
<html xmlns=\\x22http://www.w3.org/1999/xhtml\\x22
      xml:lang=\\x22en\\x22
      lang=\\x22en\\x22>
<head>
</head>
<body>
<h2 align=\\x22center\\x22>Your FullAuto API Management Dashboard Password has been Reset</h2>
<p>Your username is: <span style=\\x22color: green;\\x22>[% username %]</span></p>
<p>Your password is: <span style=\\x22color: red;\\x22>[% password %]</span></p>
<p>You will be asked to change your password on first login.</p>
</body>
</html>
END
   ($stdout,$stderr)=$handle->cmd("mkdir -vp root/user",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/list.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/user/list.tt2",
      '__display__');
   $content=<<'END';
[% META title = 'FullAuto API: User Admin' %]
 
<br />
<a class=\\x22button\\x22 href=\\x22[% c.uri_for('/user/add') %]\\x22 onclick='this.blur();'><span>Add User</span></a>
<br />
Displaying users [% pager.first %]-[% pager.last %] of [% pager.total_entries %]
 
<table>
<tr>
    <th>Username</th>
    <th>Name</th>
    <th>Email Address</th>
    <th>Client ID</th>
    <th>Client Secret</th>
</tr>
[% WHILE (u = users.next) %]
<tr>
<td><a href=\\x22[% c.uri_for('/user', u.id, 'edit') %]\\x22>[% u.username %]</a></td>
<td>[% u.name %]</td>
<td>[% u.email_address %]</td>
<td>[% u.client_id %]</td>
<td>[% u.client_secret %]</td>
<td><a href=\\x22[% c.uri_for('/user', u.id, 'reset_password') %]\\x22>Reset Password</a></td>
<td><a href=\\x22[% c.uri_for('/user', u.id, 'inactivate') %]\\x22>Inactivate</a></td>
</tr>
[% END %]
</table>
 
&lt;&lt; 
<a href=\\x22[% c.req.uri_with({ page => pager.first_page }) %]\\x22>First</a>
<a href=\\x22[% c.req.uri_with({ page => pager.previous_page })%]\\x22>Previous</a>
|
<a href=\\x22[% c.req.uri_with({ page => pager.next_page })%]\\x22>Next</a>
<a href=\\x22[% c.req.uri_with({ page => pager.last_page }) %]\\x22>Last</a>
&gt;&gt;
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/list.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/user/add.tt2",
      '__display__');
   $content=<<'ENDD';
[% META title = 'FullAuto API: Add User' %]
 
<div>
<form name=\\x22[% form.name %]\\x22 action=\\x22[% c.req.uri %]\\x22 method=\\x22post\\x22>
 
[% FOR field IN form.error_fields %]
    [% FOR error IN field.errors %]
        <p><span style=\\x22color: red;\\x22>[% field.label _ ': ' _ error %]</span></p>
    [% END %]
[% END %]
 
<fieldset style=\\x22border: 0;\\x22>
<table>
<tr>
[% f = form.field('username') %]
<td><label for=\\x22[% f.name %]\\x22>[% f.label %]:</label></td>
<td><input type=\\x22text\\x22 size=30 name=\\x22[% f.name %]\\x22 id=\\x22[% f.name %]\\x22 value=\\x22[% f.fif %]\\x22></td>
</tr>
[% PROCESS user/edit_details.tt2 %]
<tr>
    <td><input type=\\x22submit\\x22 name=\\x22submit\\x22 id=\\x22submit\\x22 value=\\x22Add\\x22 /></td>
    <td><a href=\\x22/user/list\\x22>Users List</a></td>
</tr>
</fieldset>
</table>
</form>
</div>
ENDD
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/add.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/user/change_password.tt2",
      '__display__');
   $content=<<'ENDD';
[% META title = 'FullAuto API: Change Password' %]
 
<div>
<form name=\\x22[% form.name %]\\x22 action=\\x22[% c.req.uri %]\\x22 method=\\x22post\\x22>
 
[% FOR field IN form.error_fields %]
    [% FOR error IN field.errors %]
        <p><span style=\\x22color: red;\\x22>[% field.label _ ': ' _ error %]</span></p>
    [% END %]
[% END %]
 
<fieldset style=\\x22border: 0;\\x22>
<table>
[% FOREACH field_name = ['current_password', 'new_password', 'new_password_conf'] %]
<tr>
[% f = form.field(field_name) %]
<td><label for=\\x22[% f.name %]\\x22>[% f.label %]:</label></td>
<td><input type=\\x22password\\x22 name=\\x22[% f.name %]\\x22 id=\\x22[% f.name %]\\x22 value=\\x22[% f.fif %]\\x22></td>
</tr>
[% END %]
<tr><td><input type=\\x22submit\\x22 name=\\x22submit\\x22 value=\\x22Change\\x22 /></td></tr>
</fieldset>
</table>
</form>
</div>
ENDD
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/change_password.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/user/edit.tt2",
      '__display__');
   $content=<<'ENDD';
[% META title = 'FullAuto API: Edit User' %]
 
<div>
<form name=\\x22[% form.name %]\\x22 action=\\x22[% c.req.uri %]\\x22 method=\\x22post\\x22>
 
[% FOR field IN form.error_fields %]
    [% FOR error IN field.errors %]
        <p><span style=\\x22color: red;\\x22>[% field.label _ ': ' _ error %]</span></p>
    [% END %]
[% END %]
 
<fieldset style=\\x22border: 0;\\x22>
<table>
[% PROCESS user/edit_details.tt2 %]
<tr>
    <td><input type=\\x22submit\\x22 name=\\x22submit\\x22 id=\\x22submit\\x22 value=\\x22Update\\x22 /></td>
    <td><a href=\\x22/user/list\\x22>Users List</a></td>
</tr>
</fieldset>
</table>
</form>
</div>
ENDD
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/edit.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/user/edit_details.tt2",
      '__display__');
   $content=<<'ENDD';
[% FOREACH field_name = ['name', 'email_address',
                         'phone_number', 'mail_address'] %]
<tr>
[% f = form.field(field_name) %]
<td><label class=\\x22text.label\\x22 for=\\x22[% f.name %]\\x22>[% f.label %]:</label></td>
<td><input class=\\x22text\\x22 type=\\x22text\\x22 size=30 name=\\x22[% f.name %]\\x22 id=\\x22[% f.name %]\\x22 value=\\x22[% f.fif %]\\x22></td>
</tr>
[% END %]
<tr>
[% f = form.field('roles') %]
<td><label for=\\x22[% f.name %]\\x22>Roles:</label></td>
<td>[% f.render %]</td>
</tr>
ENDD
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/edit_details.tt2");
   ($stdout,$stderr)=$handle->cmd("touch root/user/profile.tt2",
      '__display__');
   $content=<<'ENDD';
[% META title = 'MyApp: User Profile' %]

<div>
<form name=\\x22[% form.name %]\\x22 action=\\x22[% c.req.uri %]\\x22 method=\\x22post\\x22>

[% FOR field IN form.error_fields %]
    [% FOR error IN field.errors %]
        <p><span style=\\x22color: red;\\x22>[% field.label _ ': ' _ error %]</span></p>
    [% END %]
[% END %]

<fieldset style=\\x22border: 0;\\x22>
<table>
[% FOREACH field_name = ['name', 'email_address',
                         'phone_number', 'mail_address'] %]
<tr>
[% f = form.field(field_name) %]
<td><label for=\\x22[% f.name %]\\x22>[% f.label %]:</label></td>
<td><input type=\\x22text\\x22 size=30 name=\\x22[% f.name %]\\x22 id=\\x22[% f.name %]\\x22 value=\\x22[% f.fif %]\\x22></td>
</tr>
[% END %]
<tr><td><input type=\\x22submit\\x22 name=\\x22submit\\x22 id=\\x22submit\\x22 value=\\x22Update\\x22 /></td></tr>
</fieldset>
</table>
</form>
</div>
ENDD
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > root/user/profile.tt2");
   ($stdout,$stderr)=$handle->cmd('mkdir -vp db lib/FullAutoAPI/Schema',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v 777 db');
   ($stdout,$stderr)=$handle->cwd('db');
   my $have_fadb=1; 
   unless (-e 'fullautoapi.db') {
      $have_fadb=0;
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   "wget --random-wait --progress=dot ".
      #   "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
      #   "examples/RestYUI/db/adventrest.db",
      #   '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "cp -v $builddir/$ls_tmp[0]/api/RestYUI/db/adventrest.db .",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chown -v $username:$username adventrest.db",
         '__display__')
         if $^O ne 'cygwin';
      ($stdout,$stderr)=$handle->cmd($sudo.'mv adventrest.db fullautoapi.db');
   }
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI');
   my $db_sql="db.sql";
   $content=<<'END';
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS roles;
DROP TABLE IF EXISTS user_roles;
DROP TABLE IF EXISTS client;
DROP TABLE IF EXISTS owner;
DROP TABLE IF EXISTS access_token_to_refresh_token;
DROP TABLE IF EXISTS refresh_token;
DROP TABLE IF EXISTS refresh_token_to_access_token;
DROP TABLE IF EXISTS code;
DROP TABLE IF EXISTS token;

CREATE TABLE token (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code_id INTEGER NOT NULL,
    timestamp TEXT,
    FOREIGN KEY (code_id) REFERENCES code(id)
);

CREATE TABLE code (
    client_id INTEGER NOT NULL,
    id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
    is_active INTEGER NOT NULL DEFAULT 1,
    owner_id INTEGER,
    FOREIGN KEY (client_id) REFERENCES client(id),
    FOREIGN KEY (owner_id) REFERENCES owner(id)
);

CREATE TABLE refresh_token_to_access_token (
    access_token_id INTEGER NOT NULL UNIQUE,
    code_id INTEGER NOT NULL,
    refresh_token_id INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (access_token_id, code_id, refresh_token_id),
    FOREIGN KEY (access_token_id) REFERENCES token(id),
    FOREIGN KEY (code_id) REFERENCES code(id),
    FOREIGN KEY (refresh_token_id) REFERENCES refresh_token(id)
);

CREATE TABLE refresh_token (
    id INTEGER PRIMARY KEY AUTOINCREMENT UNIQUE,
    code_id INTEGER NOT NULL,
    timestamp TEXT,
    FOREIGN KEY (code_id) REFERENCES code(id)
);

CREATE TABLE access_token_to_refresh_token (
    access_token_id INTEGER NOT NULL UNIQUE,
    code_id INTEGER NOT NULL,
    refresh_token_id INTEGER NOT NULL UNIQUE,
    PRIMARY KEY (access_token_id, code_id, refresh_token_id),
    FOREIGN KEY (access_token_id) REFERENCES token(id),
    FOREIGN KEY (code_id) REFERENCES code(id),
    FOREIGN KEY (refresh_token_id) REFERENCES refresh_token(id)
);

CREATE TABLE owner (
    id INTEGER PRIMARY KEY AUTOINCREMENT
);

CREATE TABLE client (
    id INTEGER PRIMARY KEY,
    endpoint TEXT NOT NULL,
    client_secret TEXT
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    active CHAR(1) NOT NULL,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    password_expires TIMESTAMP,
    name TEXT NOT NULL,
    email_address TEXT NOT NULL,
    phone_number TEXT,
    mail_address TEXT,
    client_id INTEGER,
    client_secret TEXT,
    FOREIGN KEY (client_id) REFERENCES client(id)
);
 
CREATE TABLE roles (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
 
CREATE TABLE user_roles (
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE,
    role_id INTEGER NOT NULL REFERENCES roles(id) ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE,
    PRIMARY KEY (user_id, role_id)
);
 
INSERT INTO users (username, active, name, email_address, password) VALUES (
    'admin', 'Y', 'Administrator', 'admin@fullauto.com', 'password'
);
INSERT INTO roles (name) VALUES ('admin');
INSERT INTO roles (name) VALUES ('can_edit');
INSERT INTO user_roles (user_id, role_id) VALUES (
    (SELECT id FROM users WHERE username = 'admin'),
    (SELECT id FROM roles WHERE name     = 'admin')
);
END
#CREATE TABLE user (
# user_id TYPE text NOT NULL PRIMARY KEY,
# fullname TYPE text NOT NULL,
# description TYPE text NOT NULL
#); 
#END
   ($stdout,$stderr)=$handle->cmd("touch $db_sql");
   ($stdout,$stderr)=$handle->cmd("chmod -v 777 $db_sql",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo \"$content\" > $db_sql");
   ($stdout,$stderr)=$handle->cmd("chmod -v 644 $db_sql",'__display__');
   ($stdout,$stderr)=$handle->cmd('sqlite3 db/fullautoapi.db < db.sql')
      unless $have_fadb;
   ($stdout,$stderr)=$handle->cmd('chmod -v 777 db/fullautoapi.db',
      '__display__');
   my $client_path="./lib/FullAutoAPI/Schema/Result/Client.pm";
   ($stdout,$stderr)=$handle->cmd("./script/fullautoapi_create.pl ".
      "model DB DBIC::Schema FullAutoAPI::Schema create=static ".
      "components=TimeStamp,PassphraseColumn ".
      "moniker_map='{ users => \"Users\" }' ".
      "on_connect_do='PRAGMA foreign_keys=ON' quote_char='\"' ".
      "dbi:SQLite:db/fullautoapi.db",
      '__display__') unless $have_fadb;
   $ad="%NL%sub find_refresh {%NL%".
       "  shift->codes->search( { is_active => 1 } )%NL%".
       "    ->related_resultset(%SQ%refresh_tokens%SQ%)->find(\@_);%NL%".
       "}";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/DO NOT MODIFY THIS/a$ad' $client_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".$client_path);
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      $client_path);
   my $refreshtoken_path="./lib/FullAutoAPI/Schema/Result/RefreshToken.pm";
   $ad="%NL%".# this is a has many but will only ever return a single record%NL%".
       "# because of the constraint on the relationship table%NL%".
       "__PACKAGE__->has_many(%NL%".
       "  from_access_token_map =>%NL%".
       "    %SQ%FullAutoAPI::Schema::Result::AccessTokenToRefreshToken%SQ% => {%NL%".
       "    %SQ%foreign.refresh_token_id%SQ% => %SQ%self.id%SQ%,%NL%".
       "    %SQ%foreign.code_id%SQ%          => %SQ%self.code_id%SQ%%NL%".
       "    }%NL%".
       ");%NL%".
       "__PACKAGE__->many_to_many(%NL%".
       "  from_access_token_map_m2m => from_access_token_map => %SQ%access_token%SQ% );%NL%".
       "%NL%".
       "# this is a has many but will only ever return a single record%NL%".
       "# because of the constraint on the relationship table%NL%".
       "__PACKAGE__->has_many(%NL%".
       "  to_access_token_map =>%NL%".
       "    %SQ%FullAutoAPI::Schema::Result::RefreshTokenToAccessToken%SQ% => {%NL%".
       "    %SQ%foreign.refresh_token_id%SQ% => %SQ%self.id%SQ%,%NL%".
       "    %SQ%foreign.code_id%SQ%          => %SQ%self.code_id%SQ%%NL%".
       "    }%NL%".
       ");%NL%".
       "__PACKAGE__->many_to_many(%NL%".
       "  to_access_token_map_m2m => to_access_token_map => %SQ%access_token%SQ% );%NL%".
       "%NL%".
       "sub from_access_token { shift->from_access_token_map_m2m->first }%NL%".
       "sub to_access_token   { shift->to_access_token_map_m2m->first }%NL%".
       "%NL%".
       "sub create_access_token {%NL%".
       "  my (\$self) = \@_;%NL%".
       "  my \$code = \$self->code;%NL%".
       "  my \$token;%NL%".
       "  \$self->result_source->storage->txn_do(%NL%".
       "    sub {%NL%".
       "      # create a new token from this refresh token%NL%".
       "      \$token = \$code->tokens->create(%NL%".
       "        { from_refresh_token_map => [ { refresh_token => \$self } ] } );%NL%".
       "%NL%".
       "      # create a new refresh token and add it to the new token%NL%".
       "      my \$refresh = \$code->refresh_tokens->create( {} );%NL%".
       "      \$token->to_refresh_token_map->create(%NL%".
       "        { code => \$code, refresh_token => \$refresh } );%NL%".
       "    }%NL%".
       "  );%NL%".
       "  return \$token;%NL%".
       "}%NL%".
       "%NL%".
       "# if we have already created a token from this refresh, de-activate it".
       "%NL%%NL%".
       "sub is_active { !shift->to_access_token_map->count }%NL%".
       "%NL%".
       "sub as_string { shift->id }";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/DO NOT MODIFY THIS/a$ad' $refreshtoken_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".$refreshtoken_path);
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      $refreshtoken_path);
   $refreshtoken_path=
      "./lib/FullAutoAPI/Schema/Result/RefreshTokenToAccessToken.pm";
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'s/\> \"refresh_token_id\" \}/\> \"refresh_token_id\"/\' ".
      $refreshtoken_path);
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'s/\> \"access_token_id\" \}/\> \"access_token_id\"/\' ".
      $refreshtoken_path);
   $ad="    code_id => \"code_id\" },";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/\> \"refresh_token_id\",/a$ad' $refreshtoken_path");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/\> \"access_token_id\",/a$ad' $refreshtoken_path");
   $handle->cmd_raw(
       "${sudo}sed -i 's/\\(^code_id.*\\\)/    \\1/' $refreshtoken_path");
   $refreshtoken_path=
      "./lib/FullAutoAPI/Schema/Result/AccessTokenToRefreshToken.pm";
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'s/\> \"refresh_token_id\" \}/\> \"refresh_token_id\"/\' ".
      $refreshtoken_path);
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'s/\> \"access_token_id\" \}/\> \"access_token_id\"/\' ".
      $refreshtoken_path);
   $ad="    code_id => \"code_id\" },";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/\> \"refresh_token_id\",/a$ad' $refreshtoken_path");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/\> \"access_token_id\",/a$ad' $refreshtoken_path");
   $handle->cmd_raw(
       "${sudo}sed -i 's/\\(^code_id.*\\\)/    \\1/' $refreshtoken_path");
   my $code_path="./lib/FullAutoAPI/Schema/Result/Code.pm";
   $ad="%NL%sub as_string { shift->id }%NL%".
       "%NL%".
       "sub activate {%NL%".
       "  my(\$self, \$owner_id) = \@_;%NL%".
       "  \$self->update( { is_active => 1, owner_id => \$owner_id } )%NL%".
       "}";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/DO NOT MODIFY THIS/a$ad' $code_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".$code_path);
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      $code_path);
   my $token_path="./lib/FullAutoAPI/Schema/Result/Token.pm";
   $ad="# this is a has many but will only ever return a single record%NL%".
       "# because of the constraint on the relationship table%NL%".
       "__PACKAGE__->has_many(%NL%".
       "  from_refresh_token_map =>%NL%".
       "    %SQ%FullAutoAPI::Schema::Result::RefreshTokenToAccessToken%SQ% => {%NL%".
       "    %SQ%foreign.access_token_id%SQ% => %SQ%self.id%SQ%,%NL%".
       "    %SQ%foreign.code_id%SQ%         => %SQ%self.code_id%SQ%%NL%".
       "    }%NL%".
       ");%NL%".
       "__PACKAGE__->many_to_many(%NL%".
       "  from_refresh_token_map_m2m => from_refresh_token_map => %SQ%refresh_token%SQ% );%NL%".
       "%NL%".
       "# this is a has many but will only ever return a single record%NL%".
       "# because of the constraint on the relationship table%NL%".
       "__PACKAGE__->has_many(%NL%".
       "  to_refresh_token_map =>%NL%".
       "    %SQ%FullAutoAPI::Schema::Result::AccessTokenToRefreshToken%SQ% => {%NL%".
       "    %SQ%foreign.access_token_id%SQ% => %SQ%self.id%SQ%,%NL%".
       "    %SQ%foreign.code_id%SQ%         => %SQ%self.code_id%SQ%%NL%".
       "    }%NL%".
       ");%NL%".
       "__PACKAGE__->many_to_many(%NL%".
       "  to_refresh_token_map_m2m => to_refresh_token_map => %SQ%refresh_token%SQ% );%NL%".
       "%NL%".
       "sub from_refresh_token { shift->from_refresh_token_map_m2m->first }%NL%".
       "sub to_refresh_token   { shift->to_refresh_token_map_m2m->first }%NL%".
       "%NL%".
       "sub as_string  { shift->id }%NL%".
       "sub type       {%SQ%bearer%SQ%}%NL%".
       "sub expires_in {3600}%NL%".
       "sub owner { shift->code->owner }";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/DO NOT MODIFY THIS/a$ad' $token_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".$token_path);
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      $token_path);
   $content=<<ENDD;
package FullAutoAPI::Schema::ResultSet::Client;
use parent 'DBIx::Class::ResultSet';

sub find_refresh {
  shift->related_resultset('codes')->search( { is_active => 1 } )
    ->related_resultset('refresh_tokens')->find(\@_);
}

1;

__END__

=pod

=head1 NAME

FUllAutoAPI::Schema::ResultSet::Client

=head1 VERSION

version 0.001004

=head1 AUTHOR

Eden Cardim <edencardim\@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Suretec Systems Ltd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
ENDD
   my $resultset_path="./lib/FullAutoAPI/Schema/ResultSet/Client.pm";
   ($stdout,$stderr)=$handle->cmd(
      "mkdir -vp ./lib/FullAutoAPI/Schema/ResultSet",'__display__');
   ($stdout,$stderr)=$handle->cmd("touch $resultset_path");
   ($stdout,$stderr)=$handle->cmd(
      $sudo."chmod -v 777 $resultset_path",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > $resultset_path");
   my $user_path="./lib/FullAutoAPI/Schema/Result/Users.pm";
   $ad="%NL%__PACKAGE__->add_columns(%NL%".
       "    %SQ%+password%SQ% => {%NL%".
       "        passphrase       => %SQ%rfc2307%SQ%,%NL%".
       "        passphrase_class => %SQ%BlowfishCrypt%SQ%,%NL%".
       "        passphrase_args  => {%NL%".
       "            cost        => 14,%NL%".
       "            salt_random => 20,%NL%".
       "        },%NL%".
       "        passphrase_check_method => %SQ%check_password%SQ%,%NL%".
       "    }%NL%".
       ");";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/DO NOT MODIFY THIS/a$ad' $user_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" $user_path");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" $user_path");
   ($stdout,$stderr)=$handle->cmd("./script/fullautoapi_create.pl ".
      "controller OAuth2::Provider",'__display__');
   ($stdout,$stderr)=$handle->cwd('deps');
   ($stdout,$stderr)=$handle->cmd($sudo."wget -qO- http://libevent.org/");
   $stdout=~/^.*Stable releases.*?href=["](.*?)["].*?href=["](.*?)["].*$/s;
   my $le_rel=$1;my $le_asc=$2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".$le_rel,'__display__');
   $le_rel=~s/^.*\/(.*)$/$1/;
   $le_asc=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $le_rel",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".$le_asc,'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username $le_asc",
      '__display__')
      if $^O ne 'cygwin';
   $le_rel=~s/^.*\/(.*.tar.gz)$/$1/;
   ($stdout,$stderr)=$handle->cmd("tar xvf $le_rel",'__display__');
   $stdout=~s/^.*\n(.*)\/.*$/$1/s;
   ($stdout,$stderr)=$handle->cwd($stdout);
   ($stdout,$stderr)=$handle->cmd('./autogen.sh','__display__');
   ($stdout,$stderr)=$handle->cmd('./configure',300,'__display__');
   ($stdout,$stderr)=$handle->cmd('make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/deps');
   ($stdout,$stderr)=$handle->cmd($sudo."wget -qO- http://memcached.org/");
   print $stderr if $stderr;
   $stdout=~/^.*?Tar.Gz Download.*?href=["](.*?)["].*$/s;
   my $mc_rel=$1;
   unless ($mc_rel) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget -qO- http://memcached.org/ -S --content-on-error",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot --no-check-certificate ".
         "https://github.com/memcached/memcached/archive/master.zip",
         '__display__');
      ($stdout,$stderr)=$handle->cmd('unzip -o master.zip','__display__');
      $mc_rel='memcached-master';
      ($stdout,$stderr)=$handle->cwd($mc_rel);
      ($stdout,$stderr)=$handle->cmd('./autogen.sh','__display__');
      #&exit_on_error("$stdout\n\n   Output from http://memcached.org/");
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".$mc_rel,'__display__');
      $mc_rel=~s/^.*\/(.*.tar.gz)$/$1/;
      ($stdout,$stderr)=$handle->cmd("tar xvf $mc_rel",'__display__');
      $stdout=~s/^.*\n(.*)\/.*$/$1/s;
      ($stdout,$stderr)=$handle->cwd($stdout);
   }
   ($stdout,$stderr)=$handle->cmd('./configure','__display__'); 
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd("sed -i 's/ -Werror//' Makefile");
      ($stdout,$stderr)=$handle->cmd("sed -i ".
         "'s#struct sigaction a#// struct sigaction a#' testapp.c");
      ($stdout,$stderr)=$handle->cmd("sed -i ".
         "'s#sigemptyset#// sigemptyset#' testapp.c");
      ($stdout,$stderr)=$handle->cmd("sed -i ".
         "'s#sigaction(#// sigaction(#' testapp.c");
      ($stdout,$stderr)=$handle->cmd("sed -i ".
         "'s#{ \"cache_redzone#// { \"cache_redzone#' testapp.c");
   }
   ($stdout,$stderr)=$handle->cmd('make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cwd('scripts');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v memcached.service /etc/systemd/system',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s#bin#local/bin#\' ".
         '/etc/systemd/system/memcached.service');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl daemon-reload');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v memcached.sysconfig /etc/sysconfig/memcached',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/nobody/$username/\' /etc/sysconfig/memcached");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 777 /var/run','__display__');
   }
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI');
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   $content=<<'END';
#\\x21/usr/bin/env perl
 
use strict;
use warnings;
use lib 'lib';
 
BEGIN { \\x24ENV{CATALYST_DEBUG} = 0 }
 
use FullAutoAPI;
use DateTime;
 
my \\x24admin = FullAutoAPI->model('DB::Users')->search({ username => 'admin' })
    ->single;
 
\\x24admin->update({ password => 'admin', password_expires => DateTime->now });
END
   ($stdout,$stderr)=$handle->cmd($sudo.'touch script/set_admin_password.pl');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 777 script/set_admin_password.pl',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$content\" > script/set_admin_password.pl");
   my $pro_path="./lib/FullAutoAPI/Controller/OAuth2/Provider.pm";
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i ".
      "\"s/Catalyst::Controller/Catalyst::Controller::ActionRole/\" ".
      $pro_path);
   $ad="%NL%".
       "with %SQ%CatalystX::OAuth2::Controller::Role::Provider%SQ%;%NL%".
       "%NL%".
       "__PACKAGE__->config(%NL%".
       "  store => {%NL%".
       "    class => %SQ%DBIC%SQ%,%NL%".
       "    client_model => %SQ%DB::Client%SQ%%NL%".
       "  }%NL%".
       ");%NL%".
       "%NL%".
       "sub request : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::RequestAuth%SQ%) {%NL%".
       "  my ( \$self, \$c ) = \@_;%NL%".
       "%NL%".
       "  my \$oauth2 = \$c->req->oauth2;%NL%".
       "%NL%".
       "  \$oauth2->{enable_client_secret}=0;%NL%".
       "}%NL%".
       "%NL%".
       "sub grant : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::GrantAuth%SQ%) {%NL%".
       "  my ( \$self, \$c ) = \@_;%NL%".
       "%NL%".
       "  my \$oauth2 = \$c->req->oauth2;%NL%".
       "%NL%".
       "  \$c->user_exists and \$oauth2->user_is_valid(1)%NL%".
       "    or \$c->detach(%SQ%/passthrulogin%SQ%);%NL%".
       "}%NL%".
       "%NL%".
       "sub token : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::AuthToken::ViaAuthGrant%SQ%) {%NL%".
       "  my ( \$self, \$c ) = \@_;%NL%".
       "%NL%".
       "  my \$oauth2 = \$c->req->oauth2;%NL%".
       "%NL%".
       "  \$oauth2->{refresh_token}=1;%NL%".
       "}%NL%".
       "%NL%".
       "sub refresh : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::AuthToken::ViaRefreshToken%SQ%) {}%NL%";
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '/ActionRole/a$ad' $pro_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      $sudo."sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" $pro_path");
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i \"s/%SQ%/\'/g\" $pro_path");
   $content=<<'END';
name: FullAutoAPI
Model::DB:
    schema_class: FullAutoAPI::Schema
    connect_info:
        - DBI:SQLite:dbname=__path_to(db/fullautoapi.db)__
        - \\x22\\x22
        - \\x22\\x22
END
   ($stdout,$stderr)=$handle->cmd($sudo."touch fullautoapi.yml");
   ($stdout,$stderr)=$handle->cmd($sudo."chmod -v 777 fullautoapi.yml",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > fullautoapi.yml");
   ($stdout,$stderr)=$handle->cmd($sudo."chmod -v 644 fullautoapi.yml",
      '__display__');
   $content=<<'END';
<View::Email::Template>
    <sender>
        mailer Sendmail
    </sender>
    template_prefix email
    <default>
        content_type text/html
        charset utf-8
        view TT
    </default>
</View::Email::Template>
 
default_view TT
END
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v 777 fullautoapi.conf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" >> fullautoapi.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod -v 644 fullautoapi.conf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "./script/fullautoapi_create.pl controller User",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rm -rvf lib/FullAutoAPI/Controller/User.pm',
      '__display__');
   my $view_path='./lib/FullAutoAPI/View/TT.pm';
   ($stdout,$stderr)=$handle->cmd(
      "./script/fullautoapi_create.pl view TT TT",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/\.tt/\.tt2/\' $view_path");
   $ad='WRAPPER => %SQ%wrapper.tt2%SQ%,';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/render_die/a$ad\' $view_path");
   $handle->cmd_raw(
       "${sudo}sed -i 's/\\(^WRAPPER =.*\\\)/    \\1/' $view_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" $view_path");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" $view_path");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp root/static/jquery','__display__');
   ($stdout,$stderr)=$handle->cwd('root/static/jquery');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://code.jquery.com/ui/1.11.3/jquery-ui.js",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username jquery-ui.js",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://code.jquery.com/jquery-1.11.3.js",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username jquery-1.11.3.js",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/root');
   # http://www.sitepoint.com/working-jquery-datatables/
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://github.com/DataTables/DataTables/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username master.zip",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd('unzip -o master.zip','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf master.zip','__display__');
   ($stdout,$stderr)=$handle->cwd('DataTables-master');
   ($stdout,$stderr)=$handle->cmd('cp -Rv media ..','__display__');
   ($stdout,$stderr)=$handle->cwd('examples');
   ($stdout,$stderr)=$handle->cmd('cp -Rv resources ../..','__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI');
   ($stdout,$stderr)=$handle->cmd("./script/fullautoapi_create.pl ".
      "view Email::Template Email::Template",'__display__');
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   $content=<<END;
package FullAutoAPI::Controller::User;
 
use strict;
use warnings;
use Moose;
use DBI;
use namespace::autoclean;
use ZMQ::LibZMQ4;
use ZMQ::Constants qw(:all);
use JSON::XS;
use YAML;
use Carp::Assert;
use Crypt::PassGen 'passgen';
use FullAutoAPI::Form::AddUser  ();
use FullAutoAPI::Form::EditUser ();
use FullAutoAPI::Form::ChangePassword ();
use FullAutoAPI::Form::UserProfile    ();
use Math::Random::ISAAC::XS;
use Bytes::Random::Secure;

use constant NBR_WORKERS    => 2;
use constant READY          => \\x22\\x5C001\\x22;

use constant FRONTEND_URL   =>
       \\x22ipc://${home_dir}FullAutoAPI/frontend.ipc\\x22;

BEGIN { extends 'Catalyst::Controller::ActionRole' }
with 'CatalystX::OAuth2::Controller::Role::WithStore';
BEGIN { extends 'Catalyst::Controller::REST' }

BEGIN {
   if (\\x24^O eq 'cygwin') {
      if (-e 'script/first_time_start.flag') {
         unlink 'script/first_time_start.flag';
      } else {
         my \\x24out=\\x60/bin/cygrunsrv -L\\x60;
         if (-1<index \\x24out,'nginx_first_time') {
            \\x60/bin/cygrunsrv -R nginx_first_time\\x60;
         }
      }
   }
}

__PACKAGE__->config(
  store => {
    class => 'DBIC',
    client_model => 'DB::Client'
  }
);

__PACKAGE__->config(
    'default' => 'application/json',
    'map'       => {
       'text/html'          => [ 'View', 'TT' ],
       'text/xml'           => [ 'View', 'TT' ],
       'text/x-yaml'        => 'YAML',
       'application/json'   => 'JSON',
       'text/x-json'        => 'JSON',
       'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
       'text/x-data-denter' => [ 'Data::Serializer', 'Data::Denter' ],
       'text/x-data-taxi'   => [ 'Data::Serializer', 'Data::Taxi'   ],
       'application/x-storable'   => [ 'Data::Serializer', 'Storable' ],
       'application/x-freezethaw' => [ 'Data::Serializer', 'FreezeThaw' ],
       'text/x-config-general'    => [ 'Data::Serializer', 'Config::General' ],
       'application/x-www-form-urlencoded' => 'JSON',
    },
);

sub cmd : Path('/cmd') : Args(0) : ActionClass('REST') { }

sub cmd_POST : Chained('/') Args(0) Does('OAuth2::ProtectedResource') {

    my ( \\x24self, \\x24c ) = \@_;

    my \\x24auth = \\x24c->req->header('Authorization')||'';
    my ( \\x24type, \\x24token ) = split ' ', \\x24auth;

    my \\x24token_obj = \\x24self->store->verify_client_token(\\x24token);

print \\x22EXPIRES_IN=\\x22,\\x24token_obj->expires_in,\\x22\\\\\\\\n\\x22;
print \\x22TOKEN=\\x22,\\x24token,\\x22\\\\\\\\n\\x22;

    my \\x24cmd_data = '';
    my \\x24cmd = '';
    my \\x24file = '';

    if ( \\x24c->req->data ) {

print \\x22REQUEST DATA=\\x22,Data::Dump::Streamer::Dump(\\x24c->req->data)->Out(),\\x22\\\\\\\\n\\x22;

       \\x24cmd_data = \\x24c->req->data;
       unless (ref \\x24cmd_data->{'cmd'} eq 'ARRAY') {
          \\x24cmd_data->{'cmd'}=[ \\x24cmd_data->{'cmd'} ];
       }
       \\x24cmd=encode_json \\x24cmd_data->{'cmd'};
    } elsif ( \\x24c->req->uploads ) {

print \\x22REQUEST UPLOADS=\\x22,Data::Dump::Streamer::Dump(\\x24c->req->uploads)->Out(),\\x22\\\\\\\\n\\x22;

       for my \\x24field ( \\x24c->req->upload ) {
           my \\x24upload   = \\x24c->req->upload(\\x24field);
           \\x24cmd = encode_json [[ 'upload', \\x24upload->filename,
                                           \\x24upload->slurp() ]];
           last;
       }
    } else {
       return \\x24self->status_bad_request(\\x24c,
           message => 'You must provide a cmd to execute\\x21' );
    }

    my \\x24id = 'Client-'.\\x24\\x24;

    my \\x24ctx     = zmq_init();
    my \\x24socket  = zmq_socket(\\x24ctx,ZMQ_REQ);

    my \\x24rv      = zmq_setsockopt(\\x24socket,ZMQ_IDENTITY,\\x24id);
    assert(\\x24rv == 0, 'setting socket options');

    \\x24rv         = zmq_connect(\\x24socket,FRONTEND_URL());

    assert(\\x24rv == 0,'connecting client ...');

    print \\x22\\x24id sending cmd\\\\\\\\n\\x22;
    \\x24rv         = zmq_msg_send(\\x24cmd,\\x24socket);

    my \\x24reply = zmq_recvmsg(\\x24socket);

    print \\x22\\x24id got a result -> \\x22,zmq_msg_data(\\x24reply),\\x22\\\\\\\\n\\x22;

    my \\x24return_entity = {
       result     => zmq_msg_data(\\x24reply),
    };

    \\x24self->status_ok( \\x24c, entity => \\x24return_entity, );

}

sub base : Chained('/base') PathPrefix CaptureArgs(0) {}
 
sub admin : Chained('base') PathPart('') CaptureArgs(0) Does('ACL') RequiresRole('admin') ACLDetachTo('denied') {}
 
sub change_password : Chained('base') PathPart('change_password') Args(0) {
    my (\\x24self, \\x24c) = \@_;
 
    my \\x24form = FullAutoAPI::Form::ChangePassword->new;
 
    \\x24c->stash(form => \\x24form);
 
    return unless \\x24form->process(
        user   => \\x24c->user,
        params => \\x24c->req->body_parameters,
    );
 
    \\x24c->user->update({
        password         => \\x24form->field('new_password')->value,
        password_expires => undef,
    });
 
    \\x24c->res->redirect(\\x24c->uri_for('/rest/demo', {
        status_msg => 'Password changed successfully'
    }));
}

sub profile : Chained('base') PathPart('profile') Args(0) {
    my (\\x24self, \\x24c) = \@_;

    my \\x24form = FullAutoAPI::Form::UserProfile->new;

    \\x24c->stash(form => \\x24form);

    return unless \\x24form->process(
        schema  => \\x24c->model('DB')->schema,
        item_id => \\x24c->user->id,
        params  => \\x24c->req->body_parameters,
    );

    \\x24c->res->redirect(\\x24c->uri_for('/user', {
        status_msg => 'Profile Updated'
    }));
}

sub user_list : Path('/user') :Args(0) : ActionClass('REST') { }

sub user_list_GET {
    my ( \\x24self, \\x24c ) = \@_;
    my \\x24draw     = \\x24c->req->params->{draw} || 0;
    my \\x24start    = \\x24c->req->params->{start} || 0;
    my \\x24per_page = \\x24c->req->params->{length} || 10;
    my \\x24page     = 1;
    if (\\x24start<\\x24per_page) {
       \\x24page=1;
    } else {
       \\x24page=int(\\x24start/\\x24per_page)+1;
    }

    my \\x24id = 'Client-'.\\x24\\x24;

    my \\x24ctx     = zmq_init();
    my \\x24socket  = zmq_socket(\\x24ctx,ZMQ_REQ);

    my \\x24rv      = zmq_setsockopt(\\x24socket,ZMQ_IDENTITY,\\x24id);
    assert(\\x24rv == 0, 'setting socket options');

    \\x24rv         = zmq_connect(\\x24socket,FRONTEND_URL());

    assert(\\x24rv == 0,'connecting client ...');

    print \\x22\\x24id sending Hello\\\\\\\\n\\x22;
    \\x24rv         = zmq_msg_send(encode_json(['Hello']),\\x24socket);

    my \\x24reply = zmq_recvmsg(\\x24socket);

    assert(\\x24reply);

    print \\x22\\x24id got a reply -> \\x22,zmq_msg_data(\\x24reply),\\x22\\\\\\\\n\\x22;

    # We'll use an array now:
    my \@user_list;
    my \\x24rs = \\x24c->model('DB::User')
        ->search(undef, { rows => \\x24per_page })->page( \\x24page );
    while ( my \\x24user_row = \\x24rs->next ) {
        push \@user_list, {
            \\x24user_row->get_columns,
            uri => \\x24c->uri_for( '/user/' . \\x24user_row->user_id )->as_string
        };
    }

    \\x24self->status_ok( \\x24c, entity => {
        draw => \\x24draw,
        recordsTotal => \\x24rs->pager->total_entries,
        recordsFiltered => \\x24rs->pager->total_entries,
        data => [ \@user_list ]
    });
};

sub single_user : Path('/user') : Args(1) : ActionClass('REST') {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    \\x24c->stash->{'user'} = \\x24c->model('DB::User')->find(\\x24user_id);
}

sub single_user_POST {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    my \\x24new_user_data = \\x24c->req->data;
    if ( \\x21defined(\\x24new_user_data) ) {
       return \\x24self->status_bad_request(\\x24c,
           message => 'You must provide a user to create or modify\\x21' );
    }

    if ( \\x24new_user_data->{'user_id'} ne \\x24user_id ) {
       return \\x24self->status_bad_request( 
              \\x24c,
              message => 
                 'Cannot create or modify user '
                 . \\x24new_user_data->{'user_id'} . ' at '
                 . \\x24c->req->uri->as_string
                 . '; the user_id does not match\\x21' );
    }

    foreach my \\x24required (qw(user_id fullname description)) {
       return \\x24self->status_bad_request( \\x24c,
          message => 'Missing required field: ' . \\x24required )
       if \\x21exists( \\x24new_user_data->{\\x24required} );
    }

    my \\x24user = \\x24c->model('DB::User')->update_or_create(
       user_id     => \\x24new_user_data->{'user_id'},
       fullname    => \\x24new_user_data->{'fullname'},
       description => \\x24new_user_data->{'description'},
    );
    my \\x24return_entity = {
       user_id     => \\x24user->user_id,
       fullname    => \\x24user->fullname,
       description => \\x24user->description,
    };

    if ( \\x24c->stash->{'user'} ) {
        \\x24self->status_ok( \\x24c, entity => \\x24return_entity, );
    } else {
        \\x24self->status_created(
            \\x24c,
            location => \\x24c->req->uri->as_string,
            entity   => \\x24return_entity,
        );
    }
}

*single_user_PUT = *single_user_POST;

sub single_user_GET {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    my \\x24user = \\x24c->stash->{'user'};
    if ( defined(\\x24user) ) {
        \\x24self->status_ok(
            \\x24c,
            entity => {
                user_id     => \\x24user->user_id,
                fullname    => \\x24user->fullname,
                description => \\x24user->description,
            }
        );
    }
    else {
        \\x24self->status_not_found( \\x24c,
            message => 'Could not find User '.\\x24user_id.'\\x21' );
    }
}

sub single_user_DELETE {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    my \\x24user = \\x24c->stash->{'user'};
    if ( defined(\\x24user) ) {
        \\x24user->delete;
        \\x24self->status_ok(
            \\x24c,
            entity => {
                user_id     => \\x24user->user_id,
                fullname    => \\x24user->fullname,
                description => \\x24user->description,
            }
        );
    } else {
        \\x24self->status_not_found( \\x24c,
        message => 'Cannot delete non-existent user '.\\x24user_id.'\\x21' );
    }
}

sub list : Chained('admin') PathPart('list') Args(0) {
    my (\\x24self, \\x24c) = \@_;
 
    my \\x24users = \\x24c->model('DB::Users')->search(
        { active => 'Y'},
        {
            order_by => ['username'],
            page     => (\\x24c->req->param('page') || 1),
            rows     => 20,
        }
    );
 
    \\x24c->stash(
        users => \\x24users,
        pager => \\x24users->pager,
    );
}
 
sub add : Chained('admin') PathPart('add') Args(0) {
    my (\\x24self, \\x24c) = \@_;
 
    my \\x24form = FullAutoAPI::Form::AddUser->new;
 
    \\x24c->stash(form => \\x24form);
 
    my \\x24user = \\x24c->model('DB::Users')->new_result({});
    my \\x24client = \\x24c->model('DB::Client')->new_result({});

    my (\\x24temp_password) = passgen(NWORDS => 1, NLETT => 8);
 
    \\x24user->password(\\x24temp_password);
    \\x24user->password_expires(DateTime->now);
    \\x24user->active('Y');
 
    return unless \\x24form->process(
        schema => \\x24c->model('DB')->schema,
        item   => \\x24user,
        params => \\x24c->req->body_parameters,
    );

    my \\x24client_id=\\x24user->id.time();
    \\x24user->client_id(\\x24client_id);
    \\x24client->id(\\x24client_id);
    \\x24client->endpoint('/cmd');
    my \\x24secret=Bytes::Random::Secure::random_bytes_base64(30);
    \\x24user->client_secret(\\x24secret);
    \\x24user->update;
    \\x24client->client_secret(\\x24secret);
    \\x24client->insert;
 
    \\x24c->stash->{email} = {
        to           => \\x24user->email_address,
        from         => 'admin\@MyOrg.com',
        subject      => 'Welcome to the FullAuto API',
        content_type => 'text/html',
        template     => 'email/welcome.tt2',
    };
 
    \\x24c->stash(
        username => \\x24user->username,
        password => \\x24temp_password,
        client_id => \\x24client->id,
        client_secret => \\x24client->client_secret,
    );
 
    \\x24c->forward(\\x24c->view('Email::Template'));
 
    \\x24c->res->redirect(\\x24c->uri_for(\\x24self->action_for('list'), {
        status_msg => 'User '
            . \\x24user->username
            . ' created successfully'
            . ', initial password emailed ' . 'to '
            . \\x24user->email_address
    }));
}
 
sub user : Chained('admin') PathPart('') CaptureArgs(1) {
    my (\\x24self, \\x24c, \\x24user_id) = \@_;
 
    \\x24c->stash(user => \\x24c->model('DB::Users')->find(\\x24user_id));
}
 
sub inactivate : Chained('user') PathPart('inactivate') Args(0) {
    my (\\x24self, \\x24c) = \@_;
 
    my \\x24user = \\x24c->stash->{user};
 
    \\x24user->update({ active => 'N' });
 
    my \\x24username = \\x24user->username;
 
    \\x24c->res->redirect(\\x24c->uri_for(\\x24self->action_for('list'), {
        status_msg => \\x22User \\x24username inactivated\\x22
    }));
}
 
sub reset_password : Chained('user') PathPart('reset_password') Args(0) {
    my (\\x24self, \\x24c) = \@_;
 
    my \\x24user = \\x24c->stash->{user};
 
    my (\\x24temp_password) = passgen(NWORDS => 1, NLETT => 8);
 
    \\x24user->password(\\x24temp_password);
    \\x24user->password_expires(DateTime->now);
    \\x24user->update;
 
    \\x24c->stash->{email} = {
        to           => \\x24user->email_address,
        from         => 'admin\@MyOrg.com',
        subject      => 'Your FullAuto API Management Dashboard Password has been Reset',
        content_type => 'text/html',
        template     => 'reset_password.tt2',
    };
 
    \\x24c->stash(
        username => \\x24user->username,
        password => \\x24temp_password,
    );
 
    \\x24c->forward(\\x24c->view('Email::Template'));
 
    \\x24c->res->redirect(\\x24c->uri_for(\\x24self->action_for('list'), {
        status_msg => 'Password reset email for '
            . \\x24user->username
            . ' sent to '
            . \\x24user->email_address
    }));
}
 
sub edit : Chained('user') PathPart('edit') Args(0) {
    my (\\x24self, \\x24c) = \@_;
 
    my \\x24form = FullAutoAPI::Form::EditUser->new;
 
    \\x24c->stash(form => \\x24form);
 
    return unless \\x24form->process(
        schema  => \\x24c->model('DB')->schema,
        item_id => \\x24c->stash->{user}->id,
        params  => \\x24c->req->body_parameters,
    );
 
    \\x24c->res->redirect(\\x24c->uri_for(\\x24self->action_for('list'), {
        status_msg => 'User '
            . \\x24c->stash->{user}->username
            . ' updated successfully'
    }));
}

sub denied : Private {
    my (\\x24self, \\x24c) = \@_;
 
    \\x24c->res->redirect(\\x24c->uri_for('/rest/demo', {
        status_msg => \\x22Access Denied\\x22
    }));
}

1;
END
   ($stdout,$stderr)=$handle->cwd('lib/FullAutoAPI/Controller');
   ($stdout,$stderr)=$handle->cmd("touch User.pm");
   ($stdout,$stderr)=$handle->cmd($sudo."chmod -v 777 User.pm",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > User.pm");
   $content=<<END;
package FullAutoAPI::Controller::Rest;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub base : Chained('/base') PathPrefix CaptureArgs(0) {}

sub rest : Chained('base') PathPart('demo') Args(0) {
    my (\\x24self, \\x24c) = \@_;

    \\x24c->stash(template => 'rest/demo.tt2');
}

sub denied : Private {
    my (\\x24self, \\x24c) = \@_;

    \\x24c->res->redirect(\\x24c->uri_for(\\x24self->action_for('rest'),
        {status_msg => \\x22Access Denied\\x22}));
}

__PACKAGE__->meta->make_immutable;

1;
END
   ($stdout,$stderr)=$handle->cmd($sudo.'touch Rest.pm');
   ($stdout,$stderr)=$handle->cmd($sudo."chmod -v 777 Rest.pm",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > Rest.pm");
   $ad='sub home : Chained(%SQ%/base%SQ%) PathPart(%SQ%%SQ%) Args(0) {'.
       '%NL%    my ($self, $c) = @_;%NL%%NL%'.
       '    $c->res->redirect($c->uri_for(%SQ%/rest/demo%SQ%));%NL%'.
       '}%NL%%NL%';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/sub index :Path/i$ad\' ./Root.pm");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/index :Path :/,+6d' ./Root.pm");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i 's/index/home/' ./Root.pm");
   $ad='%NL%sub base : Chained(%SQ%/login/required%SQ%) PathPrefix '.
       'CaptureArgs(0) {%NL%'.
       '    my ($self, $c) = @_;%NL%'.
       '%NL%'.
       '    if ($c->action ne $c->controller(%SQ%User%SQ%)->action_for('.
       '%SQ%change_password%SQ%)%NL%'.
       '        && $c->user_exists%NL%'.
       '        && $c->user->password_expires%NL%'.
       '        && $c->user->password_expires <= DateTime->now)%NL%'.
       '    {%NL%        '.
       '$c->res->redirect($c->uri_for(%SQ%/user/change_password%SQ%, {%NL%'.
       '            status_msg => %SQ%Password Expired%SQ%%NL%'.
       '        }));%NL%'.
       '        $c->detach;%NL%'.
       '    }%NL%'.
       '}%NL%';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/home : Chained/i$ad\' ./Root.pm");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i 's#default :Path#default : Chained(%SQ%/base%SQ%) ".
      "PathPart(%SQ%%SQ%) Args#' ./Root.pm");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ./Root.pm");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ./Root.pm");
   ($stdout,$stderr)=$handle->cwd("~/FullAutoAPI/lib/FullAutoAPI");
   ($stdout,$stderr)=$handle->cmd("mkdir -vp Form");
   ($stdout,$stderr)=$handle->cwd("Form");
   $content=<<END;
package FullAutoAPI::Form::AddUser;

use HTML::FormHandler::Moose;
extends 'FullAutoAPI::Form::EditUser';
use namespace::autoclean;

has_field 'username' => (
    type     => 'Text',
    label    => 'User name',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

1;
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > AddUser.pm");
   $content=<<END;
package FullAutoAPI::Form::ChangePassword;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';
use namespace::autoclean;
use Method::Signatures::Simple;

has user => (is => 'rw');

has_field 'current_password' => (
   type     => 'Password',
   label    => 'Current Password',
   required => 1,
);

method validate_current_password(\\x24field) {
    \\x24field->add_error('Incorrect password')
        if not \\x24self->user->check_password(\\x24field->value);
}

has_field 'new_password' => (
    type      => 'Password',
    label     => 'New Password',
    required  => 1,
    minlength => 5,
);

after validate => method {
    if (\\x24self->field('new_password')->value eq
            \\x24self->field('current_password')->value )
    {
        \\x24self->field('new_password')
            ->add_error('Must be different from current password');
    }
};

has_field 'new_password_conf' => (
   type           => 'PasswordConf',
   label          => 'New Password (again)',
   password_field => 'new_password',
   required       => 1,
   minlength      => 5,
);

has_field submit => (type => 'Submit', value => 'Change');

__PACKAGE__->meta->make_immutable;

1;
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > ChangePassword.pm");
   $content=<<END;
package FullAutoAPI::Form::EditUser;

use HTML::FormHandler::Moose;
extends 'FullAutoAPI::Form::UserProfile';
use namespace::autoclean;

has_field 'roles' => (
    type         => 'Multiple',
    widget       => 'checkbox_group',
    label_column => 'name',
    label        => '',
);

__PACKAGE__->meta->make_immutable;

1;
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > EditUser.pm");
   $content=<<END;
package FullAutoAPI::Form::UserProfile;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Model::DBIC';
use namespace::autoclean;

has '+item_class' => (default => 'Users');

has_field 'name'          => ( type => 'Text',  required => 1 );
has_field 'email_address' => ( type => 'Email', required => 1 );
has_field 'phone_number'  => ( type => 'Text' );
has_field 'mail_address'  => ( type => 'Text' );

has_field submit => (
   type  => 'Submit',
   value => 'Update'
);

__PACKAGE__->meta->make_immutable;

1;
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > UserProfile.pm");
   ($stdout,$stderr)=$handle->cmd($sudo."chmod -v 644 UserProfile.pm",
      '__display__');
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/root/static');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/RestYUI/root/static/json2.js .",
      '__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "wget --random-wait --progress=dot ".
   #   "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
   #   "examples/RestYUI/root/static/json2.js",
   #   '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username json2.js",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd('mkdir -vp yui','__display__');
   ($stdout,$stderr)=$handle->cwd('yui');
   my @yuifiles=('utilities.js','dom.js','connection.js','event.js',
                 'yahoo.js');
   foreach my $file (@yuifiles) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "cp -v $builddir/$ls_tmp[0]/api/RestYUI/root/static/yui/$file .",
         '__display__');
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   "wget --random-wait --progress=dot ".
      #   "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
      #   "examples/RestYUI/root/static/yui/$file",
      #   '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chown -v $username:$username $file",
         '__display__')
         if $^O ne 'cygwin';
   }
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/root');
   ($stdout,$stderr)=$handle->cmd('mkdir -vp user','__display__');
   ($stdout,$stderr)=$handle->cwd('user');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v $builddir/$ls_tmp[0]/api/RestYUI/root/user/single_user.tt .",
      '__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "wget --random-wait --progress=dot ".
   #   "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
   #   "examples/RestYUI/root/user/single_user.tt",
   #   '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username single_user.tt",
      '__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd(
      "sed -i 's/POSTT/POST/' single_user.tt");
   ($stdout,$stderr)=$handle->cmd(
      "mv single_user.tt single_user.tt2");
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI/root');
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf rest');
   ($stdout,$stderr)=$handle->cmd('mkdir -vp rest','__display__');
   ($stdout,$stderr)=$handle->cwd('rest');
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   $content=<<END;
<\\x21DOCTYPE html>
<html>
<head>
   <meta charset=\\x22utf-8\\x22>
   <meta name=\\x22viewport\\x22 content=\\x22initial-scale=1.0, maximum-scale=2.0\\x22>

   <title>Catalyst REST Example</title>

   <link rel=\\x22stylesheet\\x22 type=\\x22text/css\\x22 href=\\x22https://cdn.datatables.net/1.10.8/css/jquery.dataTables.min.css\\x22>
   <link rel=\\x22stylesheet\\x22 type=\\x22text/css\\x22 href=\\x22resources/demo.css\\x22></script>
   <script type=\\x22text/javascript\\x22 language=\\x22javascript\\x22 src=\\x22//code.jquery.com/jquery-1.11.3.min.js\\x22></script>
   <script type=\\x22text/javascript\\x22 language=\\x22javascript\\x22 src=\\x22https://cdn.datatables.net/1.10.8/js/jquery.dataTables.min.js\\x22></script>
   <script type=\\x22text/javascript\\x22 language=\\x22javascript\\x22 class=\\x22init\\x22>

   \\x24(document).ready(function() {
      \\x24(\\x22#example\\x22).dataTable({
         \\x22processing\\x22: true,
         \\x22serverSide\\x22: true,
         \\x22ajax\\x22: \\x22[%c.uri_for( c.controller('User').action_for('user_list') ) %]?page=1&content-type=application/json\\x22,
         \\x22aoColumns\\x22: [{
            \\x22mData\\x22:\\x22user_id\\x22,
         },{
            \\x22mData\\x22: \\x22fullname\\x22,
         },{
            \\x22mData\\x22: \\x22description\\x22,
         }]
     });
   } );

  </script>
</head>

<body class=\\x22dt-example\\x22>
   <div class=\\x22container\\x22>
      <section>
         <h1>Catalyst REST Example <span>Using JQuery DataTable</span></h1>

         <div class=\\x22info\\x22>
            <p>FullAuto was used to stand up this fully functional Catalyst REST installation.
               The following table is full of demo user data. To add or update a user, manually
               modify the browser URL like so:

            <br><br><code>[%c.uri_for( c.controller('User').action_for('user_list') ) %]/user_id</code></p>

            <p>Data can be accessed on the command line:
                <br><br><code>curl -X GET -k -H 'Content-Type: application/json'
                [%c.uri_for( c.controller('User').action_for('user_list') ) %]</code>
                <br><br><code>
                curl -X GET -k 
                \\x22[% c.req.base %]request?client_id=&lt;client_id&gt;&response_type=code&redirect_uri=/cmd\\x22
                </code><br><br><code>
                curl -X GET -k
                \\x22[% c.req.base %]/token?grant_type=authorization_code&client_id=&lt;client_id&gt;&redirect_uri=/cmd&code=&lt;code&gt;\\x22
                </code><br><br><code>
                curl -X POST -k -H 'Authorization: Bearer &lt;token&gt;'
                -H 'Content-Type: application/json'
                -d '{\\x22cmd\\x22:\\x22hostname\\x22}'
                [% c.req.base %]cmd
                </code></p>
         </div>
            <table id=\\x22example\\x22 class=\\x22display\\x22 cellspacing=\\x220\\x22 width=\\x22100%\\x22>
               <thead>
                  <tr>
                     <th>ID</th>
                     <th>Full Name</th>
                     <th>Description</tn>
                  </tr>
               </thead>

               <tfoot>
                  <tr>
                     <th>ID</th>
                     <th>Full Name</th>
                     <th>Description</th>
                  </tr>
               </tfoot>
            </table>
         </div>
      </section>
   </div>
</body>
</html>
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > demo.tt2");
   ($stdout,$stderr)=$handle->cwd('~/FullAutoAPI');
   $ad="use Net::FullAuto;%NL%".
       "use Net::FullAuto::Cloud::fa_amazon;%NL%".
       "use ZMQ::LibZMQ4;%NL%".
       "use ZMQ::Constants qw(:all);%NL%".
       "use JSON::XS;%NL%".
       "use YAML;%NL%".
       "use Carp::Assert;%NL%".
       "use Crypt::PassGen %SQ%passgen%SQ%;%NL%".
       "use Math::Random::ISAAC::XS;%NL%".
       "use Bytes::Random::Secure;%NL%%NL%".
       "use constant NBR_WORKERS    => 2;%NL%".
       "use constant READY          => \"\\\\001\";%NL%".
       "%NL%".
       "use constant BACKEND_URL    =>%NL%".
       "       %SQ%ipc://${home_dir}FullAutoAPI/backend.ipc%SQ%;%NL%".
       "use constant FRONTEND_URL    =>%NL%".
       "       %SQ%ipc://${home_dir}FullAutoAPI/frontend.ipc%SQ%;%NL%".
       "%NL%".
       "use Parallel::Forker;%NL%".
       "%NL%".
       "my \$fa_sub=sub {%NL%".
       "%NL%".
       "   # A bit of custom config riding/hacking to use the application".
       "%SQ%s%NL%".
       "   # config for the DB.%NL%".
       "   my \$config_file = %SQ%${home_dir}FullAutoAPI/fullautoapi.yml".
       "%SQ%;%NL%".
       "   my \$config_data = YAML::LoadFile( \$config_file );%NL%".
       "   #my \$args = \$config_data->{\"Model::ZeroMQ\"}->{args};%NL%".
       "%NL%".
       "   my \$id = %SQ%Worker-%SQ%.\$\$;%NL%%NL%".
       "   my \$ctx     = zmq_init();%NL%".
       "   my \$socket  = zmq_socket(\$ctx,ZMQ_REQ);%NL%%NL%".
       "   my \$rv      = zmq_setsockopt(\$socket,ZMQ_IDENTITY,\$id);%NL%".
       "   assert(\$rv == 0);%NL%%NL%".
       "   \$rv         = zmq_connect(\$socket,BACKEND_URL());%NL%".
       "   assert(\$rv == 0,%SQ%connecting to backend%SQ%);%NL%%NL%".
       "   print \"\$id sending READY\\n\";%NL%".
       "%NL%".
       "   \$rv = zmq_msg_send(READY(),\$socket);%NL%".
       "   assert(\$rv);%NL%".
       "%NL%".
       "   my \$buf = zmq_msg_init();%NL%".
       "%NL%".
       "   my (\$fullauto,\$stdout,\$stderr,\$exitcode,".
       "\$connect_error)=(%SQ%%SQ%,%SQ%%SQ%,%SQ%%SQ%,%SQ%%SQ%,%SQ%%SQ%);%NL%".
       "   (\$fullauto,\$connect_error)=connect_shell();%NL%".
       "%NL%".
       "   use Time::HiRes;%NL%".
       "   # http://www.unitconversion.org/unit_converter/time-ex.html%NL%".
       "   my \$msg = zmq_msg_init();%NL%".
       "   my \$handles={};%NL%".
       "   while (1) {%NL%".
       "%NL%".
       "      my \@msg=();%NL%".
       "      if (zmq_msg_recv(\$buf,\$socket,ZMQ_DONTWAIT)) {%NL%".
       "         push \@msg, zmq_msg_data(\$buf);%NL%".
       "         while (zmq_getsockopt(\$socket,ZMQ_RCVMORE)) {%NL%".
       "            zmq_msg_recv(\$buf,\$socket);%NL%".
       "            push \@msg, zmq_msg_data(\$buf);%NL%".
       "         }%NL%".
       "      }%NL%".
       "      if (getppid==1) {%NL%".
       "         `pgrep -P \$\$ | xargs kill -TERM`;%NL%".
       "         exit;%NL%".
       "      }%NL%".
       "      if (\$#msg) {%NL%".
       "         print \"\$id got: \$msg[2] from \$msg[0]\\n\";%NL%".
       "         print \"\$id sending OK to \$msg[0]\\n\";%NL%".
       "         zmq_msg_send(\$msg[0],\$socket,ZMQ_SNDMORE);%NL%".
       "         zmq_msg_send(%SQ%%SQ%,\$socket,ZMQ_SNDMORE);%NL%".
       "         my \$cmds=decode_json \$msg[2];%NL%".
       "         if (\$cmds->[0] eq %SQ%Hello%SQ%) {%NL%".
       "            zmq_msg_send(encode_json([%SQ%Hello Back%SQ%]),%NL%".
       "               \$socket);%NL%".
       "            next;%NL%".
       "         }%NL%".
       "         \$cmds=[\$cmds] unless ref \$cmds eq %SQ%ARRAY%SQ%;%NL%".
       "         my \$out=[];%NL%".
       "         foreach my \$cmd (\@{\$cmds}) {%NL%".
       "            if (ref \$cmd eq %SQ%ARRAY%SQ%) {%NL%".
       "               if (\$cmd->[0] eq %SQ%cmd%SQ%) {%NL%".
       "                  (\$stdout,\$stderr)=\$fullauto->cmd(%NL%".
       "                     \$cmd->[1],%SQ%__display__%SQ%);%NL%".
       "                  push \@{\$out},[\$stdout,\$stderr]%NL%".
       "               } elsif (\$cmd->[0] eq %SQ%cmd_raw%SQ%) {%NL%".
       "                  (\$stdout,\$stderr)=\$fullauto->cmd_raw(%NL%".
       "                     \$cmd->[1]);%NL%".
       "                  push \@{\$out},[\$stdout,\$stderr]%NL%".
       "               } elsif (\$cmd->[0] eq %SQ%cwd%SQ%) {%NL%".
       "                  (\$stdout,\$stderr)=\$fullauto->cwd(%NL%".
       "                     \$cmd->[1]);%NL%".
       "                  push \@{\$out},[\$stdout,\$stderr]%NL%".
       "               } elsif (\$cmd->[0] eq %SQ%aws_configure%SQ%) {%NL%".
       "                  my \$key=\$cmd->[1];%NL%".
       "                  my \$secret=\$cmd->[2];%NL%".
       "                  \$aws_configure->(\$key,\$secret);%NL%".
       "               } elsif (\$cmd->[0] eq %SQ%upload%SQ%) {%NL%".
       "                  open(FH,\">/tmp/\$cmd->[1]\") || warn \$!;%NL%".
       "                  print FH \$cmd->[2];%NL%".
       "                  close FH;%NL%".
       "               } elsif (\$cmd->[0] eq %SQ%label%SQ%) {%NL%".
       "                  print \"LABEL=\".\$cmd->[1]->[0];%NL%".
       "                  if (exists \$handles->{\$cmd->[1]->[0]}) {%NL%".
       "                     if (\$cmd->[1]->[1] eq %SQ%cmd%SQ%) {%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->cmd(%NL%".
       "                           \$cmd->[1]->[2]);%NL%".
       "                        push \@{\$out},[\$stdout,\$stderr]%NL%".
       "                     } elsif (\$cmd->[1]->[0] eq %SQ%close%SQ%) {%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->close();%NL%".
       "                        delete \$handles->{\$cmd->[1]->[0]};%NL%".
       "                        \$stdout=\"\$cmd->[1]->[0] CLOSED\";%NL%".
       "                        push \@{\$out},[\$stdout,\$stderr]%NL%".
       "                     } elsif (\$cmd->[1]->[1] eq 'docker_run') {%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->docker_run(%NL%".
       "                           \$cmd->[1]->[2]);%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->cmd(%NL%".
       "                           %SQ%hostname%SQ%);%NL%".
       "                        push \@{\$out},[\$stdout,\$stderr]%NL%".
       "                     } elsif (\$cmd->[1]->[1] eq %NL%".
       "                           %SQ%docker_attach%SQ%) {%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->docker_attach(%NL%".
       "                           \$cmd->[1]->[2]);%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->cmd(%NL%".
       "                           %SQ%hostname%SQ%);%NL%".
       "                        push \@{\$out},[\$stdout,\$stderr]%NL%".
       "                     }  elsif (\$cmd->[1]->[1] eq%NL%".
       "                           %SQ%docker_exit%SQ%) {%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->docker_exit();%NL%".
       "                        (\$stdout,\$stderr)=\$handles->{%NL%".
       "                           \$cmd->[1]->[0]}->cmd(%NL%".
       "                           %SQ%hostname%SQ%);%NL%".
       "                        push \@{\$out},[\$stdout,\$stderr]%NL%".
       "                     }%NL%".
       "                  }%NL%".
       "               } elsif (\$cmd->[0] eq %SQ%connect_secure%SQ%) {%NL%".
       "                  my \$identityfile=\$cmd->[1]->{%NL%".
       "                     %SQ%identityfile%SQ%};%NL%".
       "                  my \$pwd=`pwd`;%NL%".
       "                  chomp(\$pwd);%NL%".
       "                  \$identityfile=\$pwd.%SQ%/%SQ%.\$identityfile if%NL%".
       "                     -1==index(\$identityfile,%SQ%/%SQ%);%NL%".
       "                  my (\$connect_label) = passgen(NWORDS => 1,%NL%".
       "                     NLETT => 8);%NL%".
       "                  my \$server={%NL%".
       "                     Label => \$connect_label,%NL%".
       "                     IP => \$cmd->[1]->{%SQ%ip%SQ%},%NL%".
       "                     Login => \$cmd->[1]->{%SQ%login%SQ%},%NL%".
       "                     IdentityFile => \$identityfile,%NL%".
       "                     NoRetry => \$cmd->[1]->{%SQ%noretry%SQ%}||".
       "%SQ%%SQ%,%NL%".
       "                     debug => \$cmd->[1]->{%SQ%debug%SQ%}||0%NL%".
       "                  };%NL%".
       "                  my \$error=%SQ%%SQ%;my \$stdout=%SQ%%SQ%;%NL%".
       "                  my \$stderr=%SQ%%SQ%;%NL%".
       "                  (\$handles->{\$connect_label},\$error)=%NL%".
       "                     connect_ssh(\$server);%NL%".
       "                  if (\$error) {%NL%".
       "                     \$stdout=%SQ%%SQ%;%NL%".
       "                     \$stderr=\$error;%NL%".
       "                  } else {%NL%".
       "                     \$stdout=\$connect_label%NL%".
       "                  }%NL%".
       "                  push \@{\$out},[\$stdout,\$stderr];%NL%".
       "               }%NL%".
       "            } else {%NL%".
       "               (\$stdout,\$stderr)=\$fullauto->cmd(\$cmd);%NL%".
       "               push \@{\$out},[\$stdout,\$stderr]%NL%".
       "            }%NL%".
       "         }%NL%".
       "         \$stdout=encode_json \$out;%NL%".
       "         zmq_msg_send(\$stdout,\$socket);%NL%".
       "      }%NL%".
       "      Time::HiRes::sleep (.0001);%NL%".
       "%NL%".
       "   }%NL%".
       "};%NL%".
       "%NL%".
       "my \$zeromq_broker=sub {%NL%".
       "%NL%".
       "   print \"LOADING BROKER\\n\";%NL%".
       "%NL%".
       "   my \$ctx = zmq_init();%NL%".
       "   my \$frontend = zmq_socket(\$ctx, ZMQ_ROUTER);%NL%".
       "   my \$backend  = zmq_socket(\$ctx, ZMQ_ROUTER);%NL%".
       "%NL%".
       "   my \$rv  = zmq_bind(\$frontend,FRONTEND_URL());%NL%".
       "   assert(\$rv == 0);%NL%".
       "%NL%".
       "   \$rv     = zmq_bind(\$backend,BACKEND_URL());%NL%".
       "   assert(\$rv == 0);%NL%".
       "%NL%".
       "   my \@workers;%NL%".
       "%NL%".
       "   my (\$w_addr,\$delim,\$c_addr,\$data);%NL%".
       "   my \$items = [%NL%".
       "%NL%".
       "         {%NL%".
       "            events      => ZMQ_POLLIN,%NL%".
       "            socket      => \$frontend,%NL%".
       "            callback    => sub {%NL%".
       "%NL%".
       "                if (-1<\$#workers) {%NL%".
       "%NL%".
       "                    print \"frontend…\\n\";%NL%".
       "%NL%".
       "                    my \$buf = zmq_msg_init();%NL%".
       "                    my \@msg=();%NL%".
       "                    if (zmq_msg_recv(\$buf,\$frontend)) {%NL%".
       "                       push \@msg, zmq_msg_data(\$buf);%NL%".
       "                       while (zmq_getsockopt(\$frontend,ZMQ_RCVMORE)) {%NL%".
       "                          zmq_msg_recv(\$buf,\$frontend);%NL%".
       "                          push \@msg, zmq_msg_data(\$buf);%NL%".
       "                       }%NL%".
       "                    }%NL%".
       "%NL%".
       "                    assert(\$#msg);%NL%".
       "%NL%".
       "                    assert(\$#workers < NBR_WORKERS());%NL%".
       "%NL%".
       "                    zmq_msg_send(pop(\@workers),\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(%SQ%%SQ%,\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(\$msg[0],\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(%SQ%%SQ%,\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(\$msg[2],\$backend,);%NL%".
       "%NL%".
       "                }%NL%".
       "            },%NL%".
       "         },%NL%".
       "         {%NL%".
       "            events      => ZMQ_POLLIN,%NL%".
       "            socket      => \$backend,%NL%".
       "            callback    => sub {%NL%".
       "%NL%".
       "                print \"backend…\\n\";%NL%".
       "%NL%".
       "                my \$buf = zmq_msg_init();%NL%".
       "                my \@msg=();%NL%".
       "                if (zmq_msg_recv(\$buf,\$backend)) {%NL%".
       "                   push \@msg, zmq_msg_data(\$buf);%NL%".
       "                   while (zmq_getsockopt(\$backend,ZMQ_RCVMORE)) {%NL%".
       "                      zmq_msg_recv(\$buf,\$backend);%NL%".
       "                      push \@msg, zmq_msg_data(\$buf);%NL%".
       "                   }%NL%".
       "                }%NL%".
       "%NL%".
       "                assert(\$#msg);%NL%".
       "%NL%".
       "                \$w_addr = \$msg[0];%NL%".
       "                push(\@workers,\$w_addr);%NL%".
       "%NL%".
       "                \$delim = \$msg[1];%NL%".
       "                assert(\$delim eq %SQ%%SQ%);%NL%".
       "%NL%".
       "                \$c_addr = \$msg[2];%NL%".
       "%NL%".
       "                if(\$c_addr ne READY()){%NL%".
       "                    \$delim = \$msg[3];%NL%".
       "                    assert (\$delim eq %SQ%%SQ%);%NL%".
       "%NL%".
       "                    \$data = \$msg[4];%NL%".
       "%NL%".
       "                    print %SQ%sending %SQ%.\$data.%SQ% to %SQ%.\$c_addr.\"\\n\";%NL%".
       "%NL%".
       "                    zmq_msg_send(\$c_addr,\$frontend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(%SQ%%SQ%,\$frontend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(\$data,\$frontend);%NL%".
       "%NL%".
       "                } else {%NL%".
       "                    print %SQ%worker checking in: %SQ%.\$w_addr.\"\\n\";%NL%".
       "                }%NL%".
       "            },%NL%".
       "         },%NL%".
       "   ];%NL%".
       "   while(1){%NL%".
       "      zmq_poll(\$items);%NL%".
       "      select undef,undef,undef,0.025;%NL%".
       "      if (getppid==1) {%NL%".
       "         `pgrep -P \$\$ | xargs kill -TERM`;%NL%".
       "          exit;%NL%".
       "      }%NL%".
       "   }%NL%".
       "%NL%".
       "};%NL%".
       "%NL%".
       "my \$Fork = new Parallel::Forker();%NL%".
       "\$Fork->schedule(run_on_start => \$zeromq_broker)->run()%NL%".
       "   if \$Fork->in_parent;%NL%".
       "setpgrp(0,0) unless \$Fork->in_parent;%NL%".
       "%NL%".
       "for (1..NBR_WORKERS()) {%NL%".
       "%NL%".
       "   my \$Fork = new Parallel::Forker();%NL%".
       "   #\$SIG{TERM} = sub { \$Fork->kill_tree_all(%SQ%TERM%SQ%) ".
       "if \$Fork && \$Fork->in_parent; die \"Quitting...\\n\"; };%NL%".
       "   \$Fork->schedule(run_on_start => \$fa_sub)->run()%NL%".
       "      if \$Fork->in_parent;%NL%".
       "   setpgrp(0,0) unless \$Fork->in_parent;%NL%".
       "%NL%".
       "}%NL%";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/use Catalyst::ScriptRunner/i$ad\' ".
      "./script/fullautoapi_fastcgi.pl");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      "./script/fullautoapi_fastcgi.pl");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      "./script/fullautoapi_fastcgi.pl");
   ($stdout,$stderr)=$handle->cmd("${sudo}ldconfig");
   ($stdout,$stderr)=$handle->cmd('./script/set_admin_password.pl');
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd("cygrunsrv -I memcached ".
         "-p /usr/local/bin/memcached");
      ($stdout,$stderr)=$handle->cmd("cygrunsrv -I fullautoapi ".
         "-y memcached -p /cygdrive/c/cygwin64/bin/bash -a ".
         "'-lc \"/bin/perl /home/$username/FullAutoAPI/script/".
         "fullautoapi_fastcgi.pl -l localhost:3003\"'");
      ($stdout,$stderr)=$handle->cmd("cygrunsrv --start fullautoapi");
      sleep 15;
      print "\n   ACCESS FULLAUTO API MANAGEMENT DASHBOARD AT:\n\n",
            " https://$domain_url  -OR-  https://localhost\n";
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chown -Rv $username:$username .",'3600');
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   "cp -v $builddir/$ls_tmp[0]/api/memcached /etc/init.d",
      #   '__display__');
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   'chmod -v 755 /etc/init.d/memcached','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "cp -v $builddir/$ls_tmp[0]/api/fullautoapi /etc/init.d",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 755 /etc/init.d/fullautoapi','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 777 /var/log','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 777 /var/lock/subsys','__display__');
      print "\n   STARTING FULLAUTO API MANAGEMENT DASHBOARD . . .\n\n",
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service fullautoapi start','__display__');
      sleep 15;
      print "\n   ACCESS FULLAUTO API MANAGEMENT DASHBOARD AT:\n\n",
            " https://$domain_url\n";
   }
   my $thanks=<<'END';

     ______                  _    ,
       / /              /   ' )  /        /
    --/ /_  __.  ____  /_    /  / __ . . /
   (_/ / /_(_/|_/ / <_/ <_  (__/_(_)(_/_'   For Trying
                             //

           _   _      _         _____      _ _    _         _
          | \ | | ___| |_      |  ___|   _| | |  / \  _   _| |_  |
          |  \| |/ _ \ __| o o | |_ | | | | | | / _ \| | | | __/ | \
          | |\  |  __/ |_  o o |  _|| |_| | | |/ ___ \ |_| | ||     |
          |_| \_|\___|\__|     |_|   \__,_|_|_/_/   \_\__,_|\__\___/ (C)


   Copyright (C) 2000-2020  Brian M. Kelly  Brian.Kelly@FullAuto.com

END
   eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
      alarm 15;
      print $thanks;
      print "   \n   Press Any Key to EXIT ... ";
      <STDIN>;
   };alarm(0);
   print "\n\n";
   #print "\n\n\n   Please wait at least a minute for the Default Browser\n",
   #      "   to start with your new Catalyst installation!\n\n\n";
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_fullautoapi=sub {

   my $catalyst="]T[{select_fullautoapi_setup}";
   my $password="]I[{'enter_password',1}";
   my $domain_url="]I[{'domain_url',1}";
   my $cnt=0;
   $configure_fullautoapi->($catalyst,$password,$domain_url);
   return '{choose_demo_setup}<';

};

my $fullautoapi_setup_summary=sub {

   package fullautoapi_setup_summary;
   use JSON::XS;
   my $region="]T[{awsregions}";
   $region=~s/^"//;
   $region=~s/"$//;
   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   my $money=$type;
   $money=~s/^.*-> \$(.*?) +(?:[(].+[)] )*\s*per hour$/$1/;
   $type=substr($type,0,(index $type,' ->')-3);
   my $catalyst="]T[{select_fullautoapi_setup}";
   $catalyst=~s/^"//;
   $catalyst=~s/"$//;
   print "REGION=$region and TYPE=$type\n";
   print "CATALYST=$catalyst\n";
   my $num_of_servers=0;
   my $ol=$catalyst;
   $ol=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ol==1) {
      $main::aws->{'CatalystFramework.org'}->[0]=[];
   } elsif ($ol=~/^\d+$/ && $ol) {
      foreach my $n (0..$ol) {
         $main::aws->{'CatalystFramework.org'}=[] unless exists
            $main::aws->{'CatalystFramework.org'};
         $main::aws->{'CatalystFramework.org'}->[$n]=[];
      }
   }
   $num_of_servers=$ol;
   my $cost=int($num_of_servers)*$money;
   my $cents='';
   if ($cost=~/^0\./) {
      $cents=$cost;
      $cents=~s/^0\.//;
      if (length $cents>2) {
         $cents=~s/^(..)(.*)$/$1.$2/;
         $cents=~s/^0//;
         $cents=' ('.$cents.' cents)';
      } else {
         $cents=' ('.$cents.' cents)';
      }
   }
   my $show_cost_banner=<<'END';

      _                  _       ___        _  ___
     /_\  __ __ ___ _ __| |_    / __|___ __| ||__ \
    / _ \/ _/ _/ -_) '_ \  _|  | (__/ _ (_-<  _|/_/
   /_/ \_\__\__\___| .__/\__|   \___\___/__/\__(_)
                   |_|

END
   $show_cost_banner.=<<END;
   Note: There is a \$$cost per hour cost$cents to launch $num_of_servers
         AWS EC2 $type servers for the FullAuto Demo:

         $catalyst


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_fullautoapi,

      },
      Item_2 => {

         Text => "Return to Choose Demo Menu",
         Result => sub { return '{choose_demo_setup}<' },

      },
      Item_3 => {

         Text => "Exit FullAuto",
         Result => sub { Net::FullAuto::FA_Core::cleanup() },

      },
      Scroll => 1,
      Banner => $show_cost_banner,

   );
   return \%show_cost;

};

our $choose_strong_password=sub {

   package choose_strong_password;
   my $password_banner=<<'END';

    ___ _                       ___                              _
   / __| |_ _ _ ___ _ _  __ _  | _ \__ _ _______ __ _____ _ _ __| |
   \__ \  _| '_/ _ \ ' \/ _` | |  _/ _` (_-<_-< V  V / _ \ '_/ _` |
   |___/\__|_| \___/_||_\__, | |_| \__,_/__/__/\_/\_/\___/_| \__,_|
                        |___/
END
   use Crypt::GeneratePassword qw(word);
   my $word='';
   foreach my $count (1..10) {
      print "\n   Generating Password ...\n";
      $word=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         my $word=word(10,15,3,5,6);
         print "\n   Trying Password - $word ...\n";
         die if -1<index $word,'*';
         die if -1<index $word,'$';
         die if -1<index $word,'+';
         return $word;
      };
      alarm 0;
      last if $word;
   }
   $password_banner.=<<END;
   The Web Server (NGINX) and the SSL Certificate each need a strong password.
   Use the one supplied here, or create your own. To create your own, use the
   [DEL] key to clear the highlighted input box first.

   *** BE SURE TO WRITE IT DOWN AND KEEP IT SOMEWHERE SAFE! ***

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.

   Password
                    ]I[{1,\'$word\',50}

   Confirm
                    ]I[{2,\'$word\',50}


END
   my $enter_password={

      Name => 'enter_password',
      Input => 1,
      Result => $standup_fullautoapi,
      #Result =>
   #$Net::FullAuto::ISets::Local::FullAutoAPI_is::select_fullautoapi_setup,
      Banner => $password_banner,

   };
   return $enter_password;

};

our $domain_url=sub {

   package domain_url;
   use Net::FullAuto;
   my $handle=connect_shell();
   my ($stdout,$stderr)=$handle->cmd("wget -qO- http://icanhazip.com");
   my $public_ip=$stdout if $stdout=~/^\d+\.\d+\.\d+\.\d+\s*/s;
   unless ($public_ip) {
      require Sys::Hostname;
      import Sys::Hostname;
      require Socket;
      import Socket;
      my($addr)=inet_ntoa((gethostbyname(Sys::Hostname::hostname))[4]);
      $public_ip=$addr if $addr=~/^\d+\.\d+\.\d+\.\d+\s*/s;
   }
   chomp($public_ip);
   $public_ip='127.0.0.1' unless $public_ip;

   my $domain_url_banner=<<'END';

    ___                 _        _   _ ___ _
   |   \ ___ _ __  __ _(_)_ _   | | | | _ \ |
   | |) / _ \ '  \/ _` | | ' \  | |_| |   / |__
   |___/\___/_|_|_\__,_|_|_||_|  \___/|_|_\____|


END
   $domain_url_banner.=<<END;
   Type or paste the domain url for the site:

   *** A properly registered domain url is necessary! ***

   Make sure the DNS A/AAAA record(s) for this domain
   contain(s) this IP address --> $public_ip


   Domain URL
                ]I[{1,'fullautosoftware.net',46}

END

   my $domain_url={

      Name => 'domain_url',
      Input => 1,
      Result => $choose_strong_password,
      #Result =>
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
      Banner => $domain_url_banner,

   };
   return $domain_url;

};

our $select_fullautoapi_setup=sub {

   my @options=('FullAuto Automation API on This Host');
   my $fullautoapi_setup_banner=<<'END';
                     _    ___     _ _   _       _                     
                   ((_)  | __|  _| | | /_\ _  _| |_  |                   
                    /    | _| || | | |/ _ \ || |  _/ | \   Automates     _
                   /     |_| \_,_|_|_/_/ \_\_,_|\__\___/c  Everything  _| |_ 
               \__/_     ___ __ _| |_ __ _| |_   _ ___| |_            |_   _|
               /    \   / __/ _` | __/ _` | | | | / __| __|  Perl MVC   |_|
            _- |    |  | (_| (_| | || (_| | | |_| \__ \ |    framework
       _ _-'   \____/   \___\__,_|\__\__,_|_|\__, |___/\__|c
     ((_)       ---\                         |___/
                    \
                     \\_   Web Framework & Automation API via RESTful
                      (_)


   Choose the FullAutoAPI setup you wish to install on this localhost:

END
   my %select_fullautoapi_setup=(

      Name => 'select_fullautoapi_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         #Result => $standup_fullautoapi,
         Result => $domain_url,

      },
      Scroll => 1,
      Banner => $fullautoapi_setup_banner,
   );
   return \%select_fullautoapi_setup

};

sub exit_on_error {

   eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
      alarm 1800;
      print "\n   FATAL ERROR!:\n\n   ";
      print $_[0];
      print "   \n\n   Press Any Key to EXIT ... ";
      <STDIN>;
   };alarm(0);
   print "\n\n";
   &Net::FullAuto::FA_Core::cleanup;

}

1
