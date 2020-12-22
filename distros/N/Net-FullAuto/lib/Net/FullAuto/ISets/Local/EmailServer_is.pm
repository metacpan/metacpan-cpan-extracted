package Net::FullAuto::ISets::Local::EmailServer_is;

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
our $DISPLAY='Email Server';
our $CONNECT='secure';

use 5.005;

use strict;
use warnings;

my $service_and_cert_password='Full@ut0O1';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_emailserver_setup);

use Net::FullAuto::Cloud::fa_amazon;
use Net::FullAuto::FA_Core qw[$localhost cleanup fetch clean_filehandle];
use Time::Local;
use File::HomeDir;
use URI::Escape::XS qw/uri_escape/;
use JSON::XS;
use Sys::Hostname;

my $tit='FullAuto.com';
my $adu='Administrator';
my $avail_port='';

my $hostname=Sys::Hostname::hostname;
my $home_dir=File::HomeDir->my_home;
$home_dir||=$ENV{'HOME'}||'';
$home_dir.='/';
my $username=getlogin || getpwuid($<);
my $do;my $ad;my $prompt;my $public_ip='';
my $builddir='';my @ls_tmp=();

# PHP Debugging
# error_log(__FILE__."\n".__LINE__."  ". $_SERVER['HTTP_HOST'] . $_SERVER['REQUEST_URI'] );
# error_log(print_r($_REQUEST,TRUE)); For Sending Array to Log
# error_log(print_r(debug_backtrace(),TRUE));
# error_log(wp_debug_backtrace_summary());

# function cleanmsg($msg){
#     return $msg;
# }
# function alert($msg,$timeout=1,$url='index.php'){
#     $msg=cleanmsg($msg);
#     echo "<script>(function(){alert('$msg');})();</script>";
# }

# MENU Log-In Log-Out
# https://premium.wpmudev.org/blog/
# how-to-add-a-loginlogout-link-to-your-emailserver-menu/
# http://vanweerd.com/enhancing-your-emailserver-3-menus/#add_login

# wp plugin list --path=/var/www/html/emailserver --status=active --allow-root

# https://www.digitalocean.com/community/tutorials/
# how-to-set-up-a-firewall-using-firewalld-on-centos-7
# sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
# sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
# sudo firewall-cmd --zone=public --permanent --list-ports

# https://chrisjean.com/change-timezone-in-centos/

# https://www.cartoonify.de/

my $configure_emailserver=sub {

   my $selection=$_[0]||'';
   my $domain_url=$_[1]||'';
   $domain_url=~s/^\s*https?:\/\/w?w?w?\.?//;
   my $service_and_cert_password=$_[2]||'';
   my $email_address=$_[3]||'';
   my $stripe_publish_key=$_[4]||'';
   my $stripe_secret_key=$_[5]||'';
   my $recaptcha_publish_key=$_[6]||'';
   my $recpatcha_secret_key=$_[7]||'';
   my ($stdout,$stderr)=('','');
   my $handle=$localhost;my $connect_error='';
   my $sudo=($^O eq 'cygwin')?'':'sudo ';
   ($stdout,$stderr)=setup_aws_security(
      'EmailServerSecurityGroup','EmailServer.com Security Group');
   ($stdout,$stderr)=$handle->cmd($sudo.'id www-data');
   if ($stdout=~/no such user/) {
      ($stdout,$stderr)=$handle->cmd($sudo.'groupadd www-data');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'adduser -r -m -g www-data www-data');
      $handle->print($sudo.'passwd www-data');
      my $prompt=$handle->prompt();
      while (1) {
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
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf /var/cache/yum',
      '__display__');
   $handle->cwd('~');
   print "\n";
   my ($ip,$iperr)='';
   ($ip,$iperr)=$handle->cmd($sudo.
         "ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*'");
   if ($iperr=~/command not found/) {
      $ip=$handle->cmd($sudo.
         "ip addr sh | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*'");
      $ip=~s/^.*inet (\d+.\d+.\d+.\d+).*$/$1/s;
   } else {
      $ip=~s/^.*?(\d+.\d+.\d+.\d+).*$/$1/s;
   }
   my $userhome=$handle->cmd('pwd');
   my $nginx_path='/etc';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "perl -e \'use CPAN;".
      "CPAN::HandleConfig-\>load;print \$CPAN::Config-\>{build_dir}\'");
   $builddir=$stdout;
   my $fa_ver=$Net::FullAuto::VERSION;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ls -1t $builddir | grep Net-FullAuto-$fa_ver");
   my @lstmp=split /\n/,$stdout;
   foreach my $line (@lstmp) {
      unshift @ls_tmp, $line if $line!~/\.yml$/;
   }
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd($sudo.'ps -ef');
      if ($stdout=~/nginx: master process/s) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'service nginx stop');
         if ($stderr) {
            ($stdout,$stderr)=$handle->cmd('ps -ef','__display__');
            if ($stdout=~/nginx/) {
               my @psinfo=();
               foreach my $line (split /\n/, $stdout) {
                  next unless -1<index $line, 'nginx';
                  @psinfo=split /\s+/, $line;
                  my $psinfo=$psinfo[2];
                  $psinfo=$psinfo[1] if $psinfo[1]=~/^\d+$/;
                  ($stdout,$stderr)=$handle->cmd(
                     $sudo."kill -9 $psinfo");
               }
            }
	 } else { print $stdout."\n" }
         if ($stdout=~/php-fpm: master process/s) {
            ($stdout,$stderr)=$handle->cmd($sudo.
               'service php-fpm stop','__display__');
         }
         if ($stdout=~/mysqld/s) {
            ($stdout,$stderr)=$handle->cmd($sudo.
               'service mysqld stop','__display__');
         }
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "rm -rf /opt/source/* ~/fa\* /var/www/html/emailserver",
         '3600','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /var/www/html','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'chmod 755 ~');
      ($stdout,$stderr)=$handle->cmd($sudo.'yum clean all');
      ($stdout,$stderr)=$handle->cmd($sudo.'yum grouplist hidden');
      ($stdout,$stderr)=$handle->cmd($sudo.'yum groups mark convert');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "yum -y groupinstall 'Development tools'",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install openssl-devel icu cyrus-sasl '.
         ' cyrus-sasl-devel libtool-ltdl-devel libjpeg-turbo-devel'.
         ' freetype-devel libpng-devel java-1.7.0-openjdk-devel'.
         ' unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel'.
         ' ncurses-devel xmlto autoconf libmcrypt libmcrypt-devel'.
         ' libcurl libcurl-devel libicu libicu-devel re2c'.
         ' libpng-devel.x86_64 freetype-devel.x86_64 cmake'.
         ' oniguruma oniguruma-devel tcl tcl-devel git-all',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y update','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install yum-utils','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "if [ -d $nginx_path/nginx ]; ".
         'then echo EXISTS;else echo NONE; fi');
      if ($stdout=~/EXISTS/) {
         ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf $nginx_path/nginx",
             '__display__');
      }
   }
#cleanup;
my $do=1;
if ($do==1) {
   unless ($^O eq 'cygwin') {
   } else {
      # https://www.digitalocean.com/community/questions/how-to-change-port-80-into-8080-on-my-emailserver
      # https://opensource.com/article/18/9/linux-iptables-firewalld
      # https://www.digitalocean.com/community/tutorials/iptables-essentials-common-firewall-rules-and-commands - for JavaPipe
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
            "rm -rvf /opt/source/nginx*",
            '__display__');
      }
      if ($srvout=~/memcached/) {
         ($stdout,$stderr)=$handle->cmd("cygrunsrv --stop memcached",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("cygrunsrv -R memcached");
         ($stdout,$stderr)=$handle->cmd(
            "/opt/source/memcached*",
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
      ($stdout,$stderr)=$handle->cmd("chmod -v 755 /usr/bin/apt-cyg",
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
            my $output.=fetch($handle);
            last if $output=~/$prompt/;
            print $output;
            if (-1<index $output,'local postmaster') {
               $handle->print();
               $output='';
               next;
            } elsif (-1<index $output,'Is it') {
               $handle->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'change that setting') {
               $handle->print('no');
               $output='';
               next;
            } elsif (-1<index $output,'standard values') {
               $handle->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'be links to') {
               $handle->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'some CPAN') {
               $handle->print('no');
               $output='';
               next;
            } elsif (-1<index $output,'install the exim') {
               $handle->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'in minutes') {
               $handle->print();
               $output='';
               next;
            } elsif (-1<index $output,'CYGWIN for the daemon') {
               $handle->print('default');
               $output='';
               next;
            } elsif (-1<index $output,'the cygsla package') {
               $handle->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'another privileged account') {
               $handle->print('no');
               $output='';
               next;
            } elsif (-1<index $output,'enter the password') {
               $handle->print($service_and_cert_password);
               $output='';
               next;
            } elsif (-1<index $output,'Reenter') {
               $handle->print($service_and_cert_password);
               $output='';
               next;
            } elsif (-1<index $output,'start the exim') {
               $handle->print('yes');
               $output='';
               next;
            }
            next;
         }
      }
   }
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
      ($stdout,$stderr)=$handle->cmd($sudo.'yum install -y '.
         'https://dl.fedoraproject.org/pub/epel/'.
         'epel-release-latest-7.noarch.rpm','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'yum -y install uuid-devel '.
         'pkgconfig libtool gcc-c++','__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /opt/source',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git clone git://sourceware.org/git/bzip2.git',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('bzip2');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make -f Makefile-libbz2_so','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v libbz2.so* /usr/local/lib','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git clone https://gitlab.gnome.org/GNOME/libxml2.git',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('libxml2');
   ($stdout,$stderr)=$handle->cmd($sudo.
      './autogen.sh','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v libxml-2.0.pc /usr/lib64/pkgconfig','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://www.sqlite.org/src/tarball/sqlite.tar.gz',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'tar zxvf sqlite.tar.gz','__display__');
   ($stdout,$stderr)=$handle->cwd('sqlite');
   ($stdout,$stderr)=$handle->cmd($sudo.
      './configure','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','3600','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v sqlite3.pc /usr/lib64/pkgconfig','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'http://ftp.gnu.org/gnu/autoconf/autoconf-latest.tar.gz',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chown -v $username:$username autoconf-latest.tar.gz",'__display__')
      if $^O ne 'cygwin';
   ($stdout,$stderr)=$handle->cmd($sudo.'tar zxvf autoconf-latest.tar.gz',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf autoconf-latest.tar.gz',
      '__display__');
   ($stdout,$stderr)=$handle->cwd("autoconf-*");
   ($stdout,$stderr)=$handle->cmd($sudo.'./configure','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd('wget --version');
   $stdout=~s/^.*?\d[.](\d+).*$/$1/s;
   if ($stdout<18 && !(-e '/usr/local/bin/wget')) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         'https://ftp.gnu.org/gnu/wget/wget-latest.tar.gz',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'tar zxvf wget-latest.tar.gz','__display__');
      ($stdout,$stderr)=$handle->cwd("wget-*");
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --prefix=/usr/local '.
         '--sysconfdir=/etc --with-ssl=openssl',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
   }
}
$do=1;
if ($do==1) { # INSTALL LATEST VERSION OF PYTHON
   ($stdout,$stderr)=$handle->cwd('/opt/source');
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
      ($stdout,$stderr)=$handle->cwd('/opt/source');
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
         "/usr/local/bin/python$version -m pip install meson",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/bin/python$version -m pip install --upgrade oauth2client",
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
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
if ($do==1) { # INSTALL LATEST VERSION OF NGINX
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # http://search.cpan.org/dist/Catalyst-Manual-5.9002/lib/Catalyst/
   #    Manual/Deployment/nginx/FastCGI.pod
   # https://serverfault.com/questions/171047/why-is-php-request-array-empty
   # https://codex.emailserver.org/Nginx
   # https://www.sitepoint.com/setting-up-php-behind-nginx-with-fastcgi/
   # http://codingsteps.com/install-php-fpm-nginx-mysql-on-ec2-with-amazon-linux-ami/
   # http://code.tutsplus.com/tutorials/revisiting-open-source-social-networking-installing-gnu-social--cms-22456
   # https://wiki.loadaverage.org/clipbucket/installation_guides/install_like_loadaverage
   # https://karp.id.au/social/index.html
   # http://jeffreifman.com/how-to-install-your-own-private-e-mail-server-in-the-amazon-cloud-aws/
   # https://www.wpwhitesecurity.com/creating-mysql-emailserver-database/
   ($stdout,$stderr)=$handle->cwd("/opt/source");
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
   ($stdout,$stderr)=$handle->cwd("/opt/source");
   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/
   # https://www.hrupin.com/2017/07/how-to-automatically-restart-nginx
   ($stdout,$stderr)=$handle->cwd("/opt/source/$nginx");
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
   my $make_nginx='./configure --user=www-data '.
                  '--group=www-data '.
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
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/1024/64/' ".
      "$nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's/worker_processes  1;/worker_processes  2;/' ".
      "$nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/root   html/{//d;}' $nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/index  index.html/{//d;}' $nginx_path/nginx/nginx.conf");
   $ad="            root /var/www/html/emailserver;%NL%".
       '            index  index.php  index.html index.htm;%NL%'.
       '            try_files $uri $uri/ /index.php?$args;';
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' $nginx_path/nginx/nginx.conf
END
   $handle->cmd_raw($sudo.$ad);
   $ad='%NL%        location ~ .php$ {'.
       "%NL%            root /var/www/html/emailserver;".
       "%NL%            fastcgi_pass 127.0.0.1:9000;".
       "%NL%            fastcgi_index index.php;".
       "%NL%            fastcgi_param SCRIPT_FILENAME ".
       '$document_root$fastcgi_script_name;'.
       "%NL%            include fastcgi_params;".
       '%NL%        }%NL%';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/404/a$ad\' $nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "$nginx_path/nginx/nginx.conf");
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
       "sed -i \'/octet-stream/i$ad\' $nginx_path/nginx/nginx.conf");
   my $ngx="$nginx_path/nginx/nginx.conf";
   $handle->cmd_raw(
       "sed -i 's/\\(^client_max_body_size 10M;$\\\)/    \\1/' $ngx");
   #($stdout,$stderr)=$handle->cmd($sudo.
   #    "sed -i \'s/^        listen       80/        listen       ".
   #    "\*:$avail_port ssl http2 default_server/\' ".
   #    $nginx_path."/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i 's/SCRIPT_NAME/PATH_INFO/' ".
       $nginx_path."/local/nginx/fastcgi_params");
   $ad='# Catalyst requires setting PATH_INFO (instead of SCRIPT_NAME)'.
       ' to \$fastcgi_script_name';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'/PATH_INFO/i$ad\' $nginx_path/nginx/fastcgi_params");
   $ad='fastcgi_param  SCRIPT_NAME        /;';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'/PATH_INFO/a$ad\' $nginx_path/nginx/fastcgi_params");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      "$nginx_path/nginx/fastcgi_params");
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
      ($stdout,$stderr)=$handle->cwd("~/EmailServer");
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
         "\'${home_dir}EmailServer/script/start_nginx.pl ".
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
         "sed -i 's/#user  nobody;/user  www-data;/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/#error_page  404              /404.html;/".
         "error_page  404              /404.html;/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.'service nginx start',
         '__display__');
      ($stdout,$stderr)=$handle->cwd("$nginx_path/nginx");
      test_for_amazon_ec2();
      if ($main::amazon) {
         ($stdout,$stderr)=$handle->cmd('wget https://dl.eff.org/certbot-auto');
         ($stdout,$stderr)=$handle->cmd('chmod -v a+x certbot-auto','__display__');
         my $ad='%SP%%SP%}%NL%'.
            '  BOOTSTRAP_VERSION="BootstrapRpmCommon $BOOTSTRAP_RPM_COMMON_VERSION"%NL%'.
            'elif grep -i "Amazon Linux" /etc/issue > /dev/null 2>&1 || \%NL%'.
            '     grep %SQ%cpe:.*:amazon_linux:2%SQ% /etc/os-release > /dev/null 2>&1; then%NL%'.
            '  Bootstrap() {%NL%'.
            '    ExperimentalBootstrap "Amazon Linux" BootstrapRpmCommon%NL%'.
            '  }%NL%'.
            '  BOOTSTRAP_VERSION="BootstrapRpmCommon $BOOTSTRAP_RPM_COMMON_VERSION"';
         ($stdout,$stderr)=$handle->cmd(
            "sed -i -e '/Amazon Linux. BootstrapRpmCommon/{n;N;d}' certbot-auto");
         ($stdout,$stderr)=$handle->cmd(
            "${sudo}sed -i \'/Amazon Linux. BootstrapRpmCommon/a$ad\' certbot-auto");
         ($stdout,$stderr)=$handle->cmd(
            "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
            'certbot-auto');
         ($stdout,$stderr)=$handle->cmd(
            "${sudo}sed -i \'s/%SP%/ /g\' ".
            'certbot-auto');
         ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
            'certbot-auto');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "certbot --debug --nginx -d $domain_url -d www.$domain_url",
            '__display__');
      } else {
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
      }
      # https://ssldecoder.org
$do=0;
if ($do==1) {

#resolver_timeout 5s;
#resolver 127.0.0.1 [::1]:5353;
#add_header Strict-Transport-Security "max-age=63072000; includeSubDomains;" always;
#add_header X-Frame-Options https://video.get-wisdom.com;

      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_certificate_key/assl_dhparam /etc/letsencrypt".
         "/ssl-dhparams.pem;' $nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_dhparam/a# https://cipherli.st/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/cipherli.st/assl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_protocols/assl_prefer_server_ciphers on;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_prefer_server_ciphers/assl_ciphers ".
         "HIGH:!aNULL:!MD5;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_ciphers ECDHE/assl_ecdh_curve secp384r1;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_ecdh_curve/assl_session_timeout  180m;' ".
         "$nginx_path/nginx/nginx.conf"); 
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_session_timeout/assl_session_cache shared:SSL:10m;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_session_cache/assl_session_tickets off;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_session_tickets/assl_stapling on;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_stapling/assl_stapling_verify on;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/^ssl_stapling_verify/a#resolver 127.0.0.1 [::1]:5353 valid=300s;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/valid=/aresolver_timeout 5s;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/resolver_timeout/aadd_header Strict-Transport-Security ".
         "\"max-age=63072000; includeSubDomains;\" always;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/Strict-Transport-Security/aadd_header ".
         "X-Frame-Options \"ALLOW-FROM https://video.$domain_url\";' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/X-Frame-Options/aadd_header X-Content-Type-Options nosniff;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/X-Content-Type-Options/aadd_header X-XSS-Protection \"1; ".
         "mode=block\" always;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/X-XSS-Protection/aadd_header X-Robots-Tag none;' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd(
         "sed -i '/X-Robots-Tag/aadd_header Content-Security-Policy ".
         "\"default-src \'self\' \'unsafe-inline\' \'unsafe-eval\' ".
         "http: https: \*.$domain_url gmpg.org; img-src http: ".
         "https: data: ws.sharethis.com s.w.org \*.gravatar.com ".
         "themes.googleusercontent.com emailserver.org; font-src ".
         "\'self\' \'unsafe-inline\' http: https: data: ".
         "fonts.googleapis.com fonts.gstatic.com\";");
}
      ($stdout,$stderr)=$handle->cmd($sudo."service nginx restart",
         '__display__');
   }
}
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   my $install_postfix=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

      
        ########   #######   ######  ######## ######## #### ##     ##
        ##     ## ##     ## ##    ##    ##    ##        ##   ##   ##
        ##     ## ##     ## ##          ##    ##        ##    ## ##
        ########  ##     ##  ######     ##    ######    ##     ###
        ##        ##     ##       ##    ##    ##        ##    ## ##
        ##        ##     ## ##    ##    ##    ##        ##   ##   ##
        ##         #######   ######     ##    ##       #### ##     ##


          (POSTFIX is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_postfix;
   sleep 5;
   # https://www.linuxbabe.com/redhat/run-your-own-email-server-centos-postfix-smtp-server
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- http://ftp.porcupine.org/mirrors/postfix-release/index.html');
   $stdout=~s/^.*?href=["]([^"]+)?["][>]Source code.*$/$1/s;
   my $gtarfile=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "http://ftp.porcupine.org/mirrors/postfix-release/$stdout",
      '__display__');
   $gtarfile=~s/^.*\///;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar zxvf $gtarfile",'__display__');
   $gtarfile=~s/.tar.gz$//;
   ($stdout,$stderr)=$handle->cwd($gtarfile);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make -f Makefile.init makefiles",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make",'__display__');
   $handle->print($sudo.'make install');
   $prompt=$handle->prompt();
   while (1) {
      my $output=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'install_root:') {
         $handle->print();
      } elsif (-1<index $output,'tempdir:') {
         $handle->print();
      } elsif (-1<index $output,'config_directory:') {
         $handle->print();
      } elsif (-1<index $output,'command_directory:') {
         $handle->print();
      } elsif (-1<index $output,'daemon_directory:') {
         $handle->print();
      } elsif (-1<index $output,'data_directory:') {
         $handle->print();
      } elsif (-1<index $output,'html_directory:') {
         $handle->print();
      } elsif (-1<index $output,'mail_owner:') {
         $handle->print();
      } elsif (-1<index $output,'mailq_path:') {
         $handle->print();
      } elsif (-1<index $output,'manpage_directory:') {
         $handle->print();
      } elsif (-1<index $output,'newaliases_path:') {
         $handle->print();
      } elsif (-1<index $output,'queue_directory:') {
         $handle->print();
      } elsif (-1<index $output,'readme_directory:') {
         $handle->print();
      } elsif (-1<index $output,'sendmail_path:') {
         $handle->print();
      } elsif (-1<index $output,'setgid_group:') {
         $handle->print();
      } elsif (-1<index $output,'shlib_directory:') {
         $handle->print();
      } elsif (-1<index $output,'meta_directory:') {
         $handle->print();
      }
      next;
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      "systemctl start postfix",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "systemctl enable postfix",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "systemctl status postfix",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "postconf -e \"inet_interfaces = all\"",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "yum -y install nmap",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "yum -y install telnet",'__display__');

   my $install_dovecot=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


       ######    ######  ######## ########  ######   ######  ########
       #    ##  ##    ## #  ##  # #      # ##    ## ##    ## #      #
       #  #  ## #  ##  # #  ##  # #  ##### #  ##  # #  ##  # ###  ###
       #  ##  # #  ##  # #  ##  # #    #   #  ##### #  ##  #   #  #
       #  ##  # #  ##  # #  ##  # #  ###   #  ##### #  ##  #   #  #
       #  #  ## #  ##  # ##    ## #  ##### #  ##  # #  ##  #   #  #
       #    ##  ##    ##  ##  ##  #      # ##    ## ##    ##   #  #
       ######    ######    ####   ########  ######   ######    ####


          (DOVECOT is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_dovecot;
   sleep 5;

   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://dovecot.org/download');
   $stdout=~s/^.*?EOL statement.*?[<]a href=["]([^"]+)?["]\s.*$/$1/s;
   $gtarfile=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".$stdout,
      '__display__');
   $gtarfile=~s/^.*\///;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar zxvf $gtarfile",'__display__');
   $gtarfile=~s/.tar.gz$//;
   ($stdout,$stderr)=$handle->cwd($gtarfile);
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'mkdir -vp /usr/local/etc','__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'cp -r doc/dovecot/example-config/* /usr/local/etc/dovecot/',
   #   '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "./configure",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make install",'__display__');

   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #         equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21     `  -  \\x60   * - \\x2A
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   # https://www.lisenet.com/2014/ - bash approach to conversion



   my $install_mysql=<<'END';

          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          :::::::::::::::::::::::::::::::::'        ':::::::::::::
          (Oracle® is **NOT** a sponsor       (`*..,
          of the FullAuto© Project.)           \  , `.
                                                \     \
          http://www.mysql.com                   \     \
                                                 /      \.
          Powered by                            ( /\      `*,
           ___    ___            ______   _____  V _      ~-~
          |   \  /   |  _    _  / _____| /  __  \ | |     \
          | |\ \/ /| | | |  | | \___  \  | |  | | | |      `
          | | \  / | | | |__| |  ___)  | | |__| | | |____
          |_|  \/  |_|  \___, | |_____/  \___\ \/ \______|®
                        ____| |               \_\
                       |_____/                            DATABASE
END
   print $install_mysql;sleep 10;
   print "\n\n";
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ls -1 /opt/source/mariadb');
   if ($stdout=~/[Mm]aria[Dd][Bb].*rpm/) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /opt/mariadb','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/mariadb');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -fv *rpm /opt/mariadb','__display__');
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.'which mysql');
   my $mysql_status='';my $mysql_version='';
   if ($stdout=~/\/mysql/) {
      ($mysql_version,$stderr)=$handle->cmd($sudo.
         'mysql --version','__display__');
      $mysql_version=~s/^mysql\s+Ver\s+(.*?)\s+Distrib.*$/$1/;
      ($mysql_status,$stderr)=$handle->cmd($sudo.
         'service mysql status','__display__');
   }
   if ($mysql_version<15.1 || $mysql_status!~/SUCCESS/) {
      # https://docs.couchbase.com/server/6.0/install/thp-disable.html
      my $do_thp=1;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cat /sys/kernel/mm/transparent_hugepage/enabled');
      if ($stdout!~/never/) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'cat /sys/kernel/mm/redhat_transparent_hugepage/enabled');
         if ($stdout!~/never/ || $stdout=~/\[never\]/) {
            $do_thp=0;
         }
      } elsif ($stdout=~/\[never\]/) {
         $do_thp=0;
      }
      if ($do_thp==1) {
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
         my $thp=<<END;
#\\x21/bin/bash
### BEGIN INIT INFO
# Provides:          disable-thp
# Required-Start:    \\x24local_fs
# Required-Stop:
# X-Start-Before:    mysql
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Disable THP
# Description:       disables Transparent Huge Pages (THP) on boot
### END INIT INFO

case \\x241 in
start)
  if [ -d /sys/kernel/mm/transparent_hugepage ]; then
    echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
    echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
  elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
    echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/enabled
    echo 'never' > /sys/kernel/mm/redhat_transparent_hugepage/defrag
  else
    return 0
  fi
;;
esac
END
         ($stdout,$stderr)=$handle->cmd($sudo.
            "echo -e \"$thp\" > disable-thp");
         ($stdout,$stderr)=$handle->cmd($sudo.
            'mv -fv disable-thp /etc/init.d/disable-thp',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'chmod -v 755 /etc/init.d/disable-thp',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'service disable-thp start','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'sudo chkconfig disable-thp on','__display__');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl stop mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl stop mariadb','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum list installed | grep "[Mm]aria\|[Mm][Yy][Ss][Qq][Ll]"',
         '__display__');
      my @pkgs=split "\n", $stdout;
      foreach my $pkg (@pkgs) {
         $pkg=~s/^(.*?)\s+.*$/$1/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "yum -y erase $pkg",'__display__');
      }
      # https://zapier.com/engineering/celery-python-jemalloc/
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --branch master '.
         'https://github.com/jemalloc/jemalloc.git',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('jemalloc');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './autogen.sh','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 /opt','__display__');
      if ($stdout!~/mariadb/i) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'mkdir -vp mariadb','__display__');
         ($stdout,$stderr)=$handle->cwd('mariadb');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/MariaDB/server.git',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'yum-builddep -y mariadb-server',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            '/bin/cmake -DRPM=centos7 server/',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'make install',600,'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'make package',600,'__display__');
      } else {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'mv -fv /opt/mariadb /opt/source/mariadb',
            '__display__');
         ($stdout,$stderr)=$handle->cwd('mariadb');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         'groupadd mysql');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'useradd -r -g mysql mysql');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 /opt/source/mariadb/_CPack_Packages/Linux/RPM/*rpm',
         '__display__');
      my @rpm_files=split "\n", $stdout;
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-common/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-client/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install galera perl-DBI','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql stop','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 1777 /tmp','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rvf /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /var/lib/mysql','__display__');
      # https://dba.stackexchange.com/questions/49446/mysql-failures-after-changing-innodb-flush-method-to-o-direct-and-innodb-log-fil
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-server/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      # To see mysql log locations:
      # mysql -se "SHOW VARIABLES" | grep -e log_error
      # -e general_log -e slow_query_log
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-backup/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-connect/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-rocksdb/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-toku/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-shared/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      foreach my $rpm (@rpm_files) {
         next if $rpm!~/64-test/;
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rpm -ivh $rpm",'__display__');
         last;
      }
      #foreach my $rpm (@rpm_files) {
      #   next if $rpm!~/-gssapi/;
      #   ($stdout,$stderr)=$handle->cmd($sudo.
      #      "rpm -ivh $rpm",'__display__');
      #   last;
      #}
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql stop','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rvf /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mysql_install_db --user=mysql --basedir=/usr '.
         '--datadir=/var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod 755 /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chgrp mysql /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chgrp -v mysql /var/lib/mysql/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /etc/my.cnf.d','__display__');
      # to make tokudb the default storage engine,
      # you have to start mysqld with: --default-storage-engine=tokudb
      my $toku_cnf=<<END;
[mariadb]
# See https://mariadb.com/kb/en/tokudb-differences/ for differences
# between TokuDB in MariaDB and TokuDB from http://www.tokutek.com/

plugin-load-add=ha_tokudb.so

[mysqld_safe]
malloc-lib=/usr/local/lib/libjemalloc.so.2
END
      ($stdout,$stderr)=$handle->cmd(
         "echo -e \"$toku_cnf\" > ~/tokudb.cnf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -v ~/tokudb.cnf /etc/my.cnf.d/tokudb.cnf',
         '__display__');
      # https://github.com/arslancb/clipbucket/issues/429
      my $sql_mode_cnf=<<END;
[mysqld]
sql_mode=IGNORE_SPACE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
END
      ($stdout,$stderr)=$handle->cmd(
         "echo -e \"$sql_mode_cnf\" > ~/sql_mode.cnf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -v ~/sql_mode.cnf /etc/my.cnf.d/sql_mode.cnf',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql start','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod 711 /var/lib/mysql/mysql','__display__');
      print "MYSQL START STDOUT=$stdout and STDERR=$stderr<==\n";sleep 5;
      print "\n\n\n\n\n\n\nWE SHOULD HAVE INSTALLED MARIADB=$stdout<==\n\n\n\n\n\n\n";
      sleep 5;
   }
   # HOW TO CHECK MYSQL FOR ERRORS
   # mkdir /var/run/mysqld/
   # chown mysql: /var/run/mysqld/
   # mysqld --basedir=/usr --datadir=/var/lib/mysql
   # --user=mysql --socket=/var/run/mysqld/mysqld.sock
   $handle->print($sudo.'mysql_secure_installation');
   $prompt=$handle->prompt();
   while (1) {
      my $output=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'root (enter for none):') {
         $handle->print();
         next;
      } elsif (-1<index $output,'so you can safely answer \'n\'') {
         $handle->print('n');
         next;
      } elsif (-1<index $output,'Set root password? [Y/n]') {
         $handle->print('n');
         next;
      } elsif (-1<index $output,'Switch to unix_socket authentication [Y/n]') {
         $handle->print('n');
         next;
      } elsif (-1<index $output,'Remove anonymous users? [Y/n]') {
         $handle->print('Y');
         next;
      } elsif (-1<index $output,'Disallow root login remotely? [Y/n]') {
         $handle->print('Y');
         next;
      } elsif (-1<index $output,
            'Remove test database and access to it? [Y/n]') {
         $handle->print('Y');
         next;
      } elsif (-1<index $output,'Reload privilege tables now? [Y/n]') {
         $handle->print('Y');
         next;
      }
   }
   $handle->cmd('echo');
   $handle->print($sudo.'mysql -u root');
   $prompt=$handle->prompt();
   my $cmd_sent=0;
   while (1) {
      my $output=fetch($handle);
      my $out=$output;
      $out=~s/$prompt//sg;
      #print $out if $output!~/^mysql>\s*$/;
      print $out if $output!~/^MariaDB.*?>\s*$/;
      last if $output=~/$prompt|Bye/;
      if (!$cmd_sent && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP DATABASE emailserver;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==1 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="CREATE DATABASE emailserver;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==2 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP USER emailserveruser@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==3 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE USER emailserveruser@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==4 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='GRANT ALL PRIVILEGES ON emailserver.*'.
                 ' TO emailserveruser@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==5 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent>=6 && $output=~/MariaDB.*?>\s*$/) {
         print "quit\n";
         $handle->print('quit');
         sleep 1;
         next;
      } sleep 1;
      $handle->print();
   }
   # https://shaunfreeman.name/compiling-php-7-on-centos/
   # https://www.vultr.com/docs/how-to-install-php-7-x-on-centos-7
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ls -1 /opt/source/mariadb');
   if ($stdout=~/[Mm]aria[Dd][Bb].*rpm/) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /opt/mariadb','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/mariadb');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -fv *rpm /opt/mariadb','__display__');
   }
   #($stdout,$stderr)=$handle->cmd($sudo.'rm -rf /opt/source',
   #   '3600','__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /opt/source',
   #   '__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.'chmod -R 777 /opt/source',
   #   '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   if (-1==index `php -v`,'PHP') {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot -O libmcrypt-2.5.8.tar.gz '.
         'https://sourceforge.net/projects/mcrypt/files/Libmcrypt/2.5.8/'.
         'libmcrypt-2.5.8.tar.gz/download','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar zxvf libmcrypt-2.5.8.tar.gz",'__display__');
      ($stdout,$stderr)=$handle->cwd('libmcrypt-2.5.8');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cmake --version','__display__');
      $stdout=~s/^.*?\s(\d+\.\d+).*$/$1/;
      if (!(-e '/usr/local/bin/cmake') && $stdout<3.02) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/Kitware/CMake.git',
            '__display__');
         ($stdout,$stderr)=$handle->cwd('CMake');
         ($stdout,$stderr)=$handle->cmd($sudo.
            './configure','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'make','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'make install','__display__');
         ($stdout,$stderr)=$handle->cwd('/opt/source');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/nih-at/libzip.git',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('libzip');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git tag -l','__display__');
      $stdout=~s/^.*\n(.*)$/$1/s;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout $stdout",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp build','__display__');
      ($stdout,$stderr)=$handle->cwd('build');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/usr/local/bin/cmake ..','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v libzip.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/jedisct1/libsodium',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('libsodium');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git checkout -b remotes/origin/stable',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './autogen.sh -s','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v libsodium.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/php/php-src.git',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('php-src');
      # https://clipbucket.com/cb-install-requirements/
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git branch -a');
      my @phpbranch=map { $_ =~ s/^.*(PHP.*)/$1/ ? $_ : () }
         split /\n/, $stdout;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout $phpbranch[$#phpbranch]",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './buildconf --force','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --prefix=/usr/local/php7 '.
         '--with-config-file-path=/usr/local/php7/etc '.
         '--with-config-file-scan-dir=/usr/local/php7/etc/conf.d '.
         '--enable-bcmath '.
         '--with-bz2 '.
         '--with-curl '.
         '--enable-filter '.
         '--enable-fpm '.
         '--enable-gd '.
         '--with-freetype '.
         '--with-jpeg '.
         '--enable-intl '.
         '--enable-exif '.
         '--enable-mbstring '.
         '--with-sodium '.
         '--enable-mysqlnd '.
         '--with-mysql-sock=/var/lib/mysql/mysql.sock '.
         '--with-mysqli=mysqlnd '.
         '--with-pdo-mysql=mysqlnd '.
         '--with-pdo-sqlite '.
         '--disable-phpdbg '.
         '--disable-phpdbg-webhelper '.
         '--enable-opcache '.
         '--with-openssl '.
         '--enable-simplexml '.
         '--with-sqlite3 '.
         '--enable-xmlreader '.
         '--enable-xmlwriter '.
         '--with-zip '.
         '--with-zlib','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make -j2',300,'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php7/bin/php /usr/local/bin/php');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php7/bin/php /usr/bin/php');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php7/etc/conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./php.ini-production /usr/local/php7/etc/php.ini',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/post_max_size = 8M/post_max_size = 500M/\' ".
         "/usr/local/php7/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/upload_max_filesize = 2M/upload_max_filesize = 500M/\' ".
         "/usr/local/php7/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/max_execution_time = 30/max_execution_time = 7500/\' ".
         "/usr/local/php7/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i \'s/memory_limit = 128M/memory_limit = 256M/\' '.
         '/usr/local/php7/etc/php.ini');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php7/etc/conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php7/etc/php-fpm.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/www.conf /usr/local/php7/etc/php-fpm.d/www.conf',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/php-fpm.conf /usr/local/php7/etc/php-fpm.conf',
         '__display__');
      my $wcnf=<<END;
catch_workers_output = yes

php_flag[display_errors] = on
php_admin_value[error_log] = /usr/local/php7/var/log/fpm-php.www.log
php_admin_flag[log_errors] = on
END
      ($stdout,$stderr)=$handle->cmd(
         "echo -e \"$wcnf\" | ${sudo}tee -a ".
         '/usr/local/php7/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'touch /var/log/fpm-php.www.log');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 777 /var/log/fpm-php.www.log','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/php-fpm.conf /usr/local/php7/etc/php-fpm.conf',
         '__display__');
      my $zend=<<END;
; Zend OPcache
extension=opcache.so
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$zend\" > ".
         '/usr/local/php7/etc/conf.d/modules.ini');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/user = nobody/user = www-data/' ".
         '/usr/local/php7/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/group = nobody/group = www-data/' ".
         '/usr/local/php7/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/\;env.PATH./env[PATH]/' ".
         '/usr/local/php7/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php7/sbin/php-fpm /usr/sbin/php-fpm');
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
      my $fpmsrv=<<END;
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=simple
PIDFile=/run/php-fpm/php-fpm.pid
ExecStart=/usr/local/php7/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php7/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \\x24MAINPID

[Install]
WantedBy=multi-user.target
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$fpmsrv\" > ".
         '~/php-fpm.service');
      ($stdout,$stderr)=$handle->cmd($sudo.'mv -fv ~/php-fpm.service '.
         '/usr/lib/systemd/system');
      ($stdout,$stderr)=$handle->cwd("/opt/source");
      ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /run/php-fpm',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chkconfig --levels 235 php-fpm on');
      ($stdout,$stderr)=$handle->cmd($sudo.'service php-fpm start',
         '__display__');
      $prompt=$handle->prompt();
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         'http://pear.php.net/go-pear.phar',
         '__display__');
      $handle->print($sudo.'/usr/local/bin/php /opt/source/go-pear.phar');
      my $outputt='';
      while (my $line=fetch($handle)) {
         last if $line=~/$prompt/s;
         $outputt.=$line;
         if ($outputt=~/Enter to continue:\s*$/s) {
            $handle->print();
            $outputt='';
         } elsif (-1<index $outputt,'/php.ini>? [Y/n] :') {
            $handle->print('n');
            $outputt='';
         }
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/usr/local/php7/bin/pecl channel-update pecl.php.net',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget -qO- https://pecl.php.net/package/mailparse');
      $stdout=~s/^.*?get\/(mailparse-.*?).tgz.*$/$1/s;
      my $version=$stdout;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/php7/bin/pecl install $version",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'bash -c "echo extension=mailparse.so > '.
         '/usr/local/php7/etc/conf.d/mailparse.ini"');
      ($stdout,$stderr)=$handle->cmd($sudo.'service php-fpm start',
         '__display__');
   } elsif (-e '/opt/cpanel/ea-php70') {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v /opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf.default '.
         '/opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/etc/init.d/ea-php70-php-fpm start",'__display__');
   }

   ($stdout,$stderr)=$handle->cwd('/opt/source');
   my $install_roundcube=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                                        888                888
                                        888                888
                                        888                888
    888d888 .d88b. 888  88888888b.  .d88888 .d8888b888  88888888b.  .d88b.
    888P"  d88""88b888  888888 "88bd88" 888d88P"   888  888888 "88bd8P  Y8b
    888    888  888888  888888  888888  888888     888  888888  88888888888
    888    Y88..88PY88b 888888  888Y88b 888Y88b.   Y88b 888888 d88PY8b.
    888     "Y88P"  "Y88888888  888 "Y88888 "Y8888P "Y8888888888P"  "Y8888


          (roundcube is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_roundcube;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://roundcube.net/download/');
   $stdout=~s/^.*?Stable version.*?href=["](https[^"]+)?["].*$/$1/s;
   my $gtarfile=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".$stdout,
      '__display__');
   $gtarfile=~s/^.*\///;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xvf $gtarfile",'__display__');
   $gtarfile=~s/.tar.gz$//;
   ($stdout,$stderr)=$handle->cwd($gtarfile);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://getcomposer.org/composer-stable.phar",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv composer.json-dist composer.json');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'php composer-stable.phar install --no-dev','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'bin/install-jsdeps.sh','__display__');

   ($stdout,$stderr)=$handle->cwd('/opt/source');
   my $install_rspamd=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


         ########   ######  ########    ###    ##     ## ########
         ##     ## ##    ## ##     ##  ## ##   ###   ### ##     ##
         ##     ## ##       ##     ## ##   ##  #### #### ##     ##
         ########   ######  ######## ##     ## ## ### ## ##     ##
         ##   ##         ## ##       ######### ##     ## ##     ##
         ##    ##  ##    ## ##       ##     ## ##     ## ##     ##
         ##     ##  ######  ##       ##     ## ##     ## ########


          (RSPAMD is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_rspamd;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git clone --recursive https://github.com/vstakhov/rspamd.git',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git clone git://github.com/ninja-build/ninja.git',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('ninja');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git checkout release','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/cmake -Bbuild-cmake -H.','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/cmake --build build-cmake','__display__');

#cleanup;

   $sudo='sudo ';
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -R www-data:www-data /var/www','__display__');
   ($stdout,$stderr)=$handle->cmd(
      "find /var/www -type f | xargs -e ${sudo}chmod 644",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "find /var/www -type d | xargs -e ${sudo}chmod 755",'__display__');

#cleanup;

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
   cleanup;

};

my $standup_emailserver=sub {

   my $catalyst="]T[{select_emailserver_setup}";
   my $password="]I[{'enter_password',1}";
   my $email_address="]I[{'email_address',1}";
   my $stripe_pub="]I[{'stripe_keys',1}";
   my $stripe_sec="]I[{'stripe_keys',2}";
   my $recaptcha_pub="]I[{'recaptcha_keys',1}";
   my $recaptcha_sec="]I[{'recaptcha_keys',2}";
   my $domain_url="]I[{'domain_url',1}";
   my $cnt=0;
   $configure_emailserver->($catalyst,$domain_url,$password,$email_address,$stripe_pub,
                          $stripe_sec,$recaptcha_pub,$recaptcha_sec);
   return '{choose_demo_setup}<';

};

my $emailserver_setup_summary=sub {

   package emailserver_setup_summary;
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
   my $catalyst="]T[{select_emailserver_setup}";
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
         Result => $standup_emailserver,

      },
      Item_2 => {

         Text => "Return to Choose Demo Menu",
         Result => sub { return '{choose_demo_setup}<' },

      },
      Item_3 => {

         Text => "Exit FullAuto",
         Result => sub { cleanup() },

      },
      Scroll => 1,
      Banner => $show_cost_banner,

   );
   return \%show_cost;

};

our $recaptcha_keys=sub {

   package recaptcha_keys;
   my $password_banner=<<'END';

             ___           _      _           _  __
    _ _ ___ / __|__ _ _ __| |_ __| |_  __ _  | |/ /___ _  _ ___
   | '_/ -_) (__/ _` | '_ \  _/ _| ' \/ _` | | ' </ -_) || (_-<
   |_| \___|\___\__,_| .__/\__\__|_||_\__,_| |_|\_\___|\_, /__/
                     |_|                               |__/

END
   $password_banner.=<<END;
   Paste the necessary reCaptcha Keys here:

   *** BE SURE TO WRITE IT DOWN AND KEEP IT SOMEWHERE SAFE! ***

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.


   Publish Key
                ]I[{1,'',46}

   Secret Key
                ]I[{2,'',46}
END

   my $recaptcha_keys={

      Name => 'recaptcha_keys',
      Input => 1,
      Result => $standup_emailserver,
      #Result =>
   #$Net::FullAuto::ISets::Local::EmailServer_is::select_emailserver_setup,
      Banner => $password_banner,

   };
   return $recaptcha_keys;

};

our $stripe_keys=sub {

   package stripe_keys;
   my $password_banner=<<'END';

    ___ _       _             _  __
   / __| |_ _ _(_)_ __  ___  | |/ /___ _  _ ___
   \__ \  _| '_| | '_ \/ -_) | ' </ -_) || (_-<
   |___/\__|_| |_| .__/\___| |_|\_\___|\_, /__/
                 |_|                   |__/

END
   $password_banner.=<<END;
   Paste the necessary Stripe Account Keys here:

   *** BE SURE TO WRITE IT DOWN AND KEEP IT SOMEWHERE SAFE! ***

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.


   Publish Key 
                ]I[{1,'',46}

   Secret Key
                ]I[{2,'',46}
END

   my $stripe_keys={

      Name => 'stripe_keys',
      Input => 1,
      Result => $recaptcha_keys,
      #Result =>
   #$Net::FullAuto::ISets::Local::EmailServer_is::select_emailserver_setup,
      Banner => $password_banner,

   };
   return $stripe_keys;

};

our $email_address=sub {

   package email_address;
   my $email_banner=<<'END';

    ___            _ _     _      _    _
   | __|_ __  __ _(_) |   /_\  __| |__| |_ _ ___ ______
   | _|| '  \/ _` | | |  / _ \/ _` / _` | '_/ -_|_-<_-<
   |___|_|_|_\__,_|_|_| /_/ \_\__,_\__,_|_| \___/__/__/

END
   $email_banner.=<<END;
   Type or Paste the necessary Email Address for EmailServer here:

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.


   Email Address
                   ]I[{1,'brian.kelly\@fullauto.com',45}

   Confirm Address
                   ]I[{2,'brian.kelly\@fullauto.com',45}
END

   my $email_address={

      Name => 'email_address',
      Input => 1,
      Result => $stripe_keys,
      #Result =>
   #$Net::FullAuto::ISets::Local::EmailServer_is::select_emailserver_setup,
      Banner => $email_banner,

   };
   return $email_address;

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

   use Crypt::GeneratePassword qw(chars);
   my $minlen=15;
   my $maxlen=15;
   my @set=("A".."Z","a".."z",0..9,"#","-","_","@","%","^","=");
   my $word='';
   foreach my $count (1..50) {
      print "\n   Generating Password ...\n";
      $word=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         my $word=chars($minlen,$maxlen,\@set);
         print "\n   Trying Password - $word ...\n";
         die if -1<index $word,'*';
         die if -1<index $word,'$';
         die if -1<index $word,'+';
         die if -1<index $word,'&';
         die if -1<index $word,'/';
         die if -1<index $word,'!';
         die if -1<index $word,'^';
         die if $word!~/\d/;
         die if $word!~/[A-Z]/;
         die if $word!~/[a-z]/;
         die if $word!~/[@#%=]/;
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
      Result => $email_address,
      #Result =>
   #$Net::FullAuto::ISets::Local::EmailServer_is::select_emailserver_setup,
      Banner => $password_banner,

   };
   return $enter_password;

};

our $domain_url=sub {

   package domain_url;
   use Net::FullAuto;
   my $handle=connect_shell();
   my ($stdout,$stderr)=$handle->cmd("wget -qO- https://icanhazip.com");
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
                ]I[{1,'fullauto.com',46}

END

   my $domain_url={

      Name => 'domain_url',
      Input => 1,
      Result => $choose_strong_password,
      #Result =>
   #$Net::FullAuto::ISets::Local::EmailServer_is::select_emailserver_setup,
      Banner => $domain_url_banner,

   };
   return $domain_url;

};

our $select_emailserver_setup=sub {

   my @options=('EmailServer on This Host');
   my $emailserver_setup_banner=<<'END';

    _____                 _ _    ____
   | ____|_ __ ___   __ _(_) |  / ___|  ___ _ ____   _____ _ __
   |  _| | '_ ` _ \ / _` | | |  \___ \ / _ \ '__\ \ / / _ \ '__|
   | |___| | | | | | (_| | | |   ___) |  __/ |   \ V /  __/ |
   |_____|_| |_| |_|\__,_|_|_|  |____/ \___|_|    \_/ \___|_|


   Choose the EmailServer setup you wish to install on this localhost:

END
   my %select_emailserver_setup=(

      Name => 'select_emailserver_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         #Result => $standup_emailserver,
	 #Result => $choose_strong_password,
	 Result => $domain_url,

      },
      Scroll => 1,
      Banner => $emailserver_setup_banner,
   );
   return \%select_emailserver_setup

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
   cleanup;

}

sub test_for_amazon_ec2 {

   if ($^O eq 'linux' || $^O eq 'freebsd') {
      if ((-e "/etc/system-release-cpe") &&
            ((-1<index `cat /etc/system-release-cpe`,'amazon:linux') ||
            (-1<index `cat /etc/system-release-cpe`,'amazon_linux'))) {
         $main::amazon{'ami'}='';
         $main::system_type='ami';
      } elsif ((-e "/etc/os-release") &&
            (-1<index `cat /etc/os-release`,'ubuntu')) {
         if (-e "/usr/bin/ec2metadata") {
            $main::amazon{'ubuntu'}='';
         }
         $main::system_type='ubuntu';
      } elsif ($^O eq 'freebsd') {
         if ((-e "/usr/local/bin/aws") &&
               (-1<index `cat /usr/local/bin/aws`,'aws.amazon')) {
            $main::amazon{'freebsd'}='';
         }
         $main::system_type='freebsd';
      } elsif (-e "/etc/SuSE-release") {
         if (-e "/etc/profile.d/amazonEC2.sh") {
            $main::amazon{'suse'}='';
         }
         $main::system_type='suse';
      } elsif ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,
            'fedoraproject')) {
         if (-e "/etc/yum/pluginconf.d/amazon-id.conf") {
            $main::amazon{'fedora'}='';
         }
         $main::system_type='fedora';
      } elsif ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,
            'redhat:enterprise_linux')) {
         if (-e "/etc/yum/pluginconf.d/amazon-id.conf") {
            $main::amazon{'rhel'}='';
         }
         $main::system_type='rhel';
      } elsif ((-e "/etc/system-release-cpe") &&
            (-1<index `cat /etc/system-release-cpe`,
            'centos:linux')) {
         if ((-e "/sys/hypervisor/compilation/compiled_by") &&
               (-1<index `cat /sys/hypervisor/compilation/compiled_by`,
               'amazon')) {
            $main::amazon{'centos'}='';
         }
         $main::system_type='centos';
      } elsif (-e "/etc/gentoo-release") {
         if ((-e "/sys/hypervisor/compilation/compiled_by") &&
               (-1<index `cat /sys/hypervisor/compilation/compiled_by`,
               'amazon')) {
            $main::amazon{'gentoo'}='';
         }
         $main::system_type='gentoo';
      }
   } else { $main::system_type=$^O }

}

1

