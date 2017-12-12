package Net::FullAuto::ISets::Local::WordPress_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright © 2000-2017  Brian M. Kelly
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
our $DISPLAY='WordPress Server';
our $CONNECT='secure';
our $defaultInstanceType='t2.small';

use 5.005;

use strict;
use warnings;

my $service_and_cert_password='Full@ut0O1';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_wordpress_setup);

use Net::FullAuto::Cloud::fa_amazon;
use Net::FullAuto::FA_Core qw[$localhost];
use File::HomeDir;
use URI::Escape::XS qw/uri_escape/;
use JSON::XS;
use Sys::Hostname;

my $url='https://get-wisdom.com';
$url=uri_escape($url);
my $tit='Get-Wisdom.com';
my $adu='Administrator';
my $ade='Brian.Kelly@get-wisdom.com';
my $the='memberlite';
my $avail_port='';

my $hostname=Sys::Hostname::hostname;
my $home_dir=File::HomeDir->my_home;
$home_dir||=$ENV{'HOME'}||'';
$home_dir.='/';
my $username=getlogin || getpwuid($<);
my $do;my $ad;my $prompt;my $public_ip='';
my $builddir='';my @ls_tmp=();

# MENU Log-In Log-Out
# https://premium.wpmudev.org/blog/
# how-to-add-a-loginlogout-link-to-your-wordpress-menu/
# http://vanweerd.com/enhancing-your-wordpress-3-menus/#add_login

# wp plugin list --path=/var/www/html/wordpress --status=active --allow-root

# https://www.digitalocean.com/community/tutorials/
# how-to-set-up-a-firewall-using-firewalld-on-centos-7
# sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
# sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
# sudo firewall-cmd --zone=public --permanent --list-ports

my $configure_wordpress=sub {

   my $selection=$_[0]||'';
   my $service_and_cert_password=$_[1]||'';
   my ($stdout,$stderr)=('','');
   my $handle=$localhost;my $connect_error='';
   my $sudo=($^O eq 'cygwin')?'':'sudo ';
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
   ($stdout,$stderr)=$handle->cmd(
      "perl -e \'use CPAN;".
      "CPAN::HandleConfig-\>load;print \$CPAN::Config-\>{build_dir}\'");
   $builddir=$stdout;
   my $fa_ver=$Net::FullAuto::VERSION;
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}ls -1t $builddir | grep Net-FullAuto-$fa_ver");
   my @lstmp=split /\n/,$stdout;
   foreach my $line (@lstmp) {
      unshift @ls_tmp, $line if $line!~/\.yml$/;
   }
$do=1;
if ($do==1) {
   unless ($^O eq 'cygwin') {
      if ($hostname eq 'jp-01ld.get-wisdom.com') {
         ($stdout,$stderr)=$handle->cmd($sudo.
            "service nginx stop",'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "service mysqld stop",'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "service php-fpm stop",'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rm -rvf /etc/nginx/ ~/WordPress ~/fa\* /var/www/html\*",
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "mkdir -vp /var/www/html",'__display__');
      }
      ($stdout,$stderr)=$handle->cmd($sudo."chmod 755 ~");
      ($stdout,$stderr)=$handle->cmd("sudo yum clean all");
      ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden");
      ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert");
      ($stdout,$stderr)=$handle->cmd(
         "sudo yum -y groupinstall 'Development tools'",'__display__');
      ($stdout,$stderr)=$handle->cmd(
         'sudo yum -y install openssl-devel icu cyrus-sasl libicu-devel'.
         ' libicu cyrus-sasl-devel libtool-ltdl-devel libxml2-devel'.
         ' freetype-devel libpng-devel java-1.7.0-openjdk-devel'.
         ' unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel'.
         ' ncurses-devel xmlto git-all autoconf libmcrypt'.
         ' libmcrypt-devel libcurl-devel bzip2-devel.x86_64'.
         ' libjpeg-turbo-devel libpng-devel.x86_64'.
         ' freetype-devel.x86_64',
         '__display__');
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
            "rm -rvf ${home_dir}WordPress/deps/nginx*",
            '__display__');
      }
      if ($srvout=~/memcached/) {
         ($stdout,$stderr)=$handle->cmd("cygrunsrv --stop memcached",
            '__display__');
         ($stdout,$stderr)=$handle->cmd("cygrunsrv -R memcached");
         ($stdout,$stderr)=$handle->cmd(
            "rm -rvf ${home_dir}WordPress/deps/memcached*",
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
         $handle->{_cmd_handle}->print('/bin/exim-config');
         $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
         while (1) {
            my $output.=Net::FullAuto::FA_Core::fetch($handle);
            last if $output=~/$prompt/;
            print $output;
            if (-1<index $output,'local postmaster') {
               $handle->{_cmd_handle}->print();
               $output='';
               next;
            } elsif (-1<index $output,'Is it') {
               $handle->{_cmd_handle}->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'change that setting') {
               $handle->{_cmd_handle}->print('no');
               $output='';
               next;
            } elsif (-1<index $output,'standard values') {
               $handle->{_cmd_handle}->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'be links to') {
               $handle->{_cmd_handle}->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'some CPAN') {
               $handle->{_cmd_handle}->print('no');
               $output='';
               next;
            } elsif (-1<index $output,'install the exim') {
               $handle->{_cmd_handle}->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'in minutes') {
               $handle->{_cmd_handle}->print();
               $output='';
               next;
            } elsif (-1<index $output,'CYGWIN for the daemon') {
               $handle->{_cmd_handle}->print('default');
               $output='';
               next;
            } elsif (-1<index $output,'the cygsla package') {
               $handle->{_cmd_handle}->print('yes');
               $output='';
               next;
            } elsif (-1<index $output,'another privileged account') {
               $handle->{_cmd_handle}->print('no');
               $output='';
               next;
            } elsif (-1<index $output,'enter the password') {
               $handle->{_cmd_handle}->print($service_and_cert_password);
               $output='';
               next;
            } elsif (-1<index $output,'Reenter') {
               $handle->{_cmd_handle}->print($service_and_cert_password);
               $output='';
               next;
            } elsif (-1<index $output,'start the exim') {
               $handle->{_cmd_handle}->print('yes');
               $output='';
               next;
            }
            next;
         }
      }
   }
   my $z=1;
   while ($z==1) {
      ($stdout,$stderr)=$handle->cmd("ps -ef",'__display__');
      if ($stdout=~/nginx/) {
         my @psinfo=();
         foreach my $line (split /\n/, $stdout) {
            next unless -1<index $line, 'nginx';
            @psinfo=split /\s+/, $line;
            my $psinfo=$psinfo[2];
            $psinfo=$psinfo[1] if $psinfo[1]=~/^\d+$/;
            ($stdout,$stderr)=$handle->cmd($sudo."kill -9 $psinfo");
         }
      } else { last }
   }
   ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf /usr/local/nginx",
      '__display__');
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
   ($stdout,$stderr)=$handle->cmd('mkdir -vp WordPress/deps',
      '__display__');
   ($stdout,$stderr)=$handle->cwd("WordPress/deps");
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
   ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
   ($stdout,$stderr)=$handle->cmd("wget --version");
   $stdout=~s/^.*?\d[.](\d+).*$/$1/s;
   if ($stdout<18 && !(-e '/usr/local/bin/wget')) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "https://ftp.gnu.org/gnu/wget/wget-1.19.2.tar.gz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar zxvf wget-1.19.2.tar.gz",'__display__');
      ($stdout,$stderr)=$handle->cwd("wget-1.19.2");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "./configure --prefix=/usr/local ".
         "--sysconfdir=/etc --with-ssl=openssl",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "make && make install",'__display__');
   }
   ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "python --version",'__display__');
   if ($stderr=~/Python /) {
      $stderr=~s/^Python\s+(\d.\d).*$/$1/s;
      $stderr=~s/[.]//g;
   }
   if ($stderr && $stderr<27) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "http://python.org/ftp/python/2.7.14/Python-2.7.14.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf Python-2.7.14.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cwd("Python-2.7.14");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "./configure --prefix=/usr/local --enable-unicode=ucs4 ".
         "--enable-shared LDFLAGS=\"-Wl,-rpath /usr/local/lib\"",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "make && make altinstall",'__display__');
   }
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
   if ($hostname eq 'jp-01ld.get-wisdom.com') {
      ($stdout,$stderr)=$handle->cmd('/usr/local/bin/python2.7 ez_setup.py',
         '__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd('python ez_setup.py',
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd('easy_install pip','__display__');
   ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
   ($stdout,$stderr)=$handle->cmd('pip install pyasn1','__display__');
   ($stdout,$stderr)=$handle->cmd('pip install pyasn1-modules',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'git clone https://github.com/google/oauth2client.git','__display__');
   ($stdout,$stderr)=$handle->cwd('oauth2client');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/python2.7 setup.py install',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
   if ($^O ne 'cygwin' && $hostname ne 'jp-01ld.get-wisdom.com') {
      ($stdout,$stderr)=$handle->cmd($sudo.'pip install httplib2',
         '__display__');
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
$do=1;
if ($do==1) { # NGINX
print "DOING NGINX\n";
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # http://search.cpan.org/dist/Catalyst-Manual-5.9002/lib/Catalyst/
   #    Manual/Deployment/nginx/FastCGI.pod
   my $nginx='nginx-1.13.7';
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
   ($stdout,$stderr)=$handle->cwd("~/WordPress/deps/$nginx");
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
      "/etc/init.d/nginx");
   ($stdout,$stderr)=$handle->cmd("chmod -v +x /etc/init.d/nginx",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("chkconfig --add nginx");
   ($stdout,$stderr)=$handle->cmd("chkconfig --level 345 nginx on");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install certbot-nginx'.'__display__');
   # https://www.digitalocean.com/community/tutorials/
   # how-to-secure-nginx-with-let-s-encrypt-on-centos-7
   my $nginx_path='/usr/local';
   my $make_nginx='./configure --sbin-path=/usr/local/nginx/nginx '.
                  '--conf-path=/usr/local/nginx/nginx.conf '.
                  '--pid-path=/usr/local/nginx/nginx.pid '.
                  "--with-http_ssl_module --with-pcre=objs/lib/$pcre ".
                  "--with-zlib=objs/lib/zlib-$zlib_ver";
   if ($hostname eq 'jp-01ld.get-wisdom.com') {
      $nginx_path='/etc';
      $make_nginx='./configure --user=www-data '.
                  '--group=www-data '.
                  '--prefix=/etc/nginx '.
                  '--sbin-path=/usr/sbin/nginx '.
                  '--conf-path=/etc/nginx/nginx.conf '.
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
                  #'--without-http_fastcgi_module';
   }
   ($stdout,$stderr)=$handle->cmd($make_nginx,'__display__');
   ($stdout,$stderr)=$handle->cmd(
      $sudo."sed -i 's/-Werror //' ./objs/Makefile");
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/
   if ($hostname ne 'jp-01ld.get-wisdom.com') {
      ($stdout,$stderr)=$handle->cmd(
         $sudo.'mkdir -vp /etc/nginx/ssl.key');
      ($stdout,$stderr)=$handle->cmd(
         $sudo.'mkdir -vp /etc/nginx/ssl.crt');
      ($stdout,$stderr)=$handle->cmd(
         $sudo.'mkdir -vp /etc/nginx/ssl.csr');
      $handle->{_cmd_handle}->print(
         $sudo.'openssl genrsa -des3 -out '.
         "/etc/nginx/ssl.key/$public_ip.key 2048");
      $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
      $prompt=~s/\$$//;
      while (1) {
         my $output.=Net::FullAuto::FA_Core::fetch($handle);
         last if $output=~/$prompt/;
         print $output;
         if (-1<index $output,'pass phrase for') {
            $handle->{_cmd_handle}->print($service_and_cert_password);
            $output='';
            next;
         } elsif (-1<index $output,'Verifying - Enter') {
            $handle->{_cmd_handle}->print($service_and_cert_password);
            $output='';
            next;
         }
      }
      while (1) {
         my $trys=0;
         my $ereturn=eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
            alarm 7;
            $handle->{_cmd_handle}->print($sudo.
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
                  $handle->{_cmd_handle}->print($service_and_cert_password);
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'[AU]:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'[Some-State]:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'city) []:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'Pty Ltd]:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'section) []:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'YOUR name) []:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'Address []:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'challenge password []:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'company name []:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,'Country Name (2 letter code) [XX]') {
                  $handle->{_cmd_handle}->print('.');
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,
                     'State or Province Name (full name) []') {
                  $handle->{_cmd_handle}->print('.');
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,
                     'Locality Name (eg, city) [Default City]:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,
                    'Organization Name (eg, company) [Default Company Ltd]:') {
                  $handle->{_cmd_handle}->print();
                  $output='';
                  $test='';
                  next;
               } elsif (-1<index $test,
                    'Common Name (eg, your name or your '.
                    'server\'s hostname) []') {
                  $handle->{_cmd_handle}->print();
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
      $handle->{_cmd_handle}->print($sudo.
         'openssl x509 -req -days 365 -in '.
         "/etc/nginx/ssl.csr/$public_ip.csr -signkey ".
         "/etc/nginx/ssl.key/$public_ip.key -out ".
         "/etc/nginx/ssl.crt/$public_ip.crt");
      while (1) {
         my $output.=Net::FullAuto::FA_Core::fetch($handle);
         last if $output=~/$prompt/;
         print $output;
         if (-1<index $output,'Enter pass phrase') {
            $handle->{_cmd_handle}->print($service_and_cert_password);
            $output='';
            next;
         } 
      }
   } 
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/1024/64/' ".
      "$nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/root   html/{//d;}' $nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/index  index.html/{//d;}' $nginx_path/nginx/nginx.conf");
   $ad="            root /var/www/html/wordpress;%NL%".
       '            index  index.php  index.html index.htm;%NL%'.
       '            try_files $uri $uri/ /index.php;';
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' $nginx_path/nginx/nginx.conf
END
   $handle->cmd_raw($sudo.$ad);
   if ($hostname ne 'jp-01ld.get-wisdom.com') {
      $ad='%NL%        location ~ .php$ {'.
          "%NL%            root /var/www/html/wordpress;".
          "%NL%            fastcgi_pass 127.0.0.1:9000;".
          "%NL%            fastcgi_index index.php;".
          "%NL%            fastcgi_param SCRIPT_FILENAME ".
          '$document_root$fastcgi_script_name;'.
          "%NL%            include fastcgi_params;".
          '%NL%        }%NL%'.
          '%NL%        ssl on;'.
          "%NL%        ssl_certificate /etc/nginx/ssl.crt/$public_ip.crt;".
          "%NL%        ssl_certificate_key /etc/nginx/ssl.key/$public_ip.key;".
          '%NL%        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;'.
          '%NL%        ssl_ciphers '.
          '"HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";';
      ($stdout,$stderr)=$handle->cmd($sudo.
          "sed -i \'/404/a$ad\' $nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
          "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
          "$nginx_path/nginx/nginx.conf");
   } else {
      $ad='%NL%        location ~ .php$ {'.
          "%NL%            root /var/www/html/wordpress;".
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
   }
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
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/^        listen       80/        listen       ".
       "\*:$avail_port ssl http2 default_server/\' $nginx_path/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i 's/SCRIPT_NAME/PATH_INFO/' ".
      "$nginx_path/local/nginx/fastcgi_params");
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
   #          !  -   \\x21     `  -  \\x60
   #          "  -   \\x22     \  -  \\x5C
   #          $  -   \\x24     %  -  \\x25
   #
   my $script=<<END;
use Net::FullAuto;
\\x24Net::FullAuto::FA_Core::debug=1;
my \\x24handle=connect_shell();
\\x24handle->{_cmd_handle}->print('$nginx_path/nginx/nginx -g \\x22daemon on;\\x22');
\\x24prompt=substr(\\x24handle->{_cmd_handle}->prompt(),1,-1);
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
         \\x24handle->{_cmd_handle}->print(\\x24ARGV[0]);
         \\x24password_not_submitted=0;
      }
   };
   if (\\x24\@) {
      \\x24handle->{_cmd_handle}->print();
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
      ($stdout,$stderr)=$handle->cmd("chmod -v o+r $nginx_path/nginx/*",
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
      if ($hostname eq 'jp-01ld.get-wisdom.com') {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'openssl dhparam -out /etc/letsencrypt/ssl-dhparams.pem 2048',
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/server_name  localhost/".
            "server_name get-wisdom.com www.get-wisdom.com/' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd($sudo.
            "sed -i 's/#user  nobody;/user  www-data;/' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd($sudo.
            "sed -i 's/#error_page  404              /404.html;/".
            "error_page  404              /404.html;/' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd("service nginx start",
            '__display__');
         ($stdout,$stderr)=$handle->cwd("/etc/nginx");
         sleep 3;
         ($stdout,$stderr)=&Net::FullAuto::FA_Core::clean_filehandle($handle);
         $handle->{_cmd_handle}->print($sudo.
            'certbot --nginx -d get-wisdom.com '.
            '-d www.get-wisdom.com');
         $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
         $prompt=~s/\$$//;
         my $test='';
         my $output='';
         while (1) {
            $output.=Net::FullAuto::FA_Core::fetch($handle);
            last if $output=~/$prompt/;
            print $output;
            if (-1<index $output,'Attempt to reinstall') {
               $handle->{_cmd_handle}->print('1');
               $output='';
               $test='';
               next;
            } elsif (-1<index $output,'No redirect') {
               $handle->{_cmd_handle}->print('2');
               $output='';
               $test='';
               next;
            } elsif (-1<index $output,'Enter email address') {
               $handle->{_cmd_handle}->print('brian.kelly@get-wisdom.com');
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'Terms of Service') {
               $handle->{_cmd_handle}->print('A');
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'Would you be willing') {
               $handle->{_cmd_handle}->print('Y');
               $output='';
               $test='';
               next;
            }
         }
         # https://ssldecoder.org
$do=1;
if ($do==1) {
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/^ssl_certificate_key/assl_dhparam /etc/letsencrypt".
            "/ssl-dhparams.pem;' $nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/^ssl_dhparam/a# https://cipherli.st/' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/cipherli.st/assl_protocols TLSv1.2 TLSv1.3;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/^ssl_protocols/assl_prefer_server_ciphers on;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/^ssl_prefer_server_ciphers/assl_ciphers ECDHE-RSA-AES256-".
            "GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256".
            "-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/^ssl_ciphers ECDHE/assl_ecdh_curve secp384r1;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/^ssl_ecdh_curve/assl_session_timeout  10m;' ".
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
            "sed -i '/^ssl_stapling_verify/a#resolver \$DNS-IP-1 \$DNS-IP-2 valid=300s;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/DNS-IP-1/aresolver_timeout 5s;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/resolver_timeout/aadd_header Strict-Transport-Security ".
            "\"max-age=63072000; includeSubDomains;\" always;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/Strict-Transport-Security/aadd_header X-Frame-Options SAMEORIGIN;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/X-Frame-Options/aadd_header X-Content-Type-Options nosniff;' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/X-Content-Type-Options/aadd_header X-XSS-Protection \"1; ".
            "mode=block\";' ".
            "$nginx_path/nginx/nginx.conf");
         ($stdout,$stderr)=$handle->cmd(
            "sed -i '/X-XSS-Protection/aadd_header X-Robots-Tag none;' ".
            "$nginx_path/nginx/nginx.conf");
}
         ($stdout,$stderr)=$handle->cmd("service nginx restart",
            '__display__');
      } else {
         $handle->{_cmd_handle}->print($sudo."$nginx_path/nginx/nginx");
         $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
         while (1) {
            my $output.=Net::FullAuto::FA_Core::fetch($handle);
            last if $output=~/$prompt/;
            print $output;
            if (-1<index $output,'PEM pass phrase') {
               $handle->{_cmd_handle}->print($service_and_cert_password);
               $output='';
               next;
            }
         }
      }
      ($stdout,$stderr)=$handle->cwd("~/WordPress/deps")
   }
}
   my $install_wordpress=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

      
          ___   ___     (\
          \  \  \  \     /             _ ____
           \  \  \  \   / ___  _ __ __| |  _ \ _ __ ___  ___ ___
            \  \ /\  \ / / _ \| '__/ _` | |_) | '__/ _ \/ __/ __|
             \  /  \  / | (_) | | | (_| |  __/| | |  __/\__ \__ \
              \/    \/   \___/|_|  \__,_|_|   |_|  \___||___/___/



         (WordPress is **NOT** a sponsor of the FullAuto© Project.)


END

   ($stdout,$stderr)=$handle->cwd("~/WordPress");
   print $install_wordpress;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "http://wordpress.org/latest.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xzvf latest.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd("wordpress");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v wp-config-sample.php wp-config.php",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \"/get this/adefine('WP_MAX_MEMORY_LIMIT','256M');\" ".
      'wp-config.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \"/get this/adefine('WP_MEMORY_LIMIT','64M');\" ".
      'wp-config.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "curl -s https://api.wordpress.org/secret-key/1.1/salt/",
      '__display__');
   my $strs=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '/AUTH/,+6d' wp-config.php");
   chdir '/root/WordPress/wordpress';
   open(FH,"<wp-config.php");
   my @lines=<FH>;
   close FH;
   open(NW,">wp-config.php_new");
   foreach my $line (@lines) {
      if ($line=~/NONCE/) {
         print NW $strs;
      } else {
         print NW $line;
      }
   }
   close NW;
   chdir '/root';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v wp-config.php_new wp-config.php");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's/database_name_here/wordpress/' wp-config.php");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's/username_here/wordpressuser/' wp-config.php");
   my $esc_pass=$service_and_cert_password;
   $esc_pass=~s/[&]/\\&/g;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's/password_here/".
      $esc_pass."/' wp-config.php");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mkdir -vp /var/www/html/wordpress",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "rsync -avP ~/WordPress/wordpress/ /var/www/html/wordpress",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv www-data:www-data /var/www','__display__');
   ($stdout,$stderr)=$handle->cwd('/var/www/html/wordpress');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chmod -v 644 wp-config.php",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mkdir -vp wp-content/uploads/themes",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mkdir -vp wp-content/uploads/plugins",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv www-data:www-data /var/www/html',
      '__display__');
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
   ($stdout,$stderr)=$handle->cwd("~/WordPress/deps");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rpm -ivh mysql57-community-release-el7-11.noarch.rpm','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."service mysqld stop",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."rm -rf /var/log/mysqld.log",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."rm -rf /var/lib/mysql",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."yum -y erase ".
      "mysql-community-server.x86_64 ".
      "mysql-community-common.x86_64 ".
      "mysql-community-client.x86_64 ".
      "mysql-community-devel.x86_64 ".
      "mysql-connector-python.x86_64",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."yum -y install ".
      "mysql-community-server.x86_64 ".
      "mysql-community-common.x86_64 ".
      "mysql-community-client.x86_64 ".
      "mysql-community-devel.x86_64 ".
      "mysql-connector-python.x86_64",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo."service mysqld start",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "grep 'temporary password' /var/log/mysqld.log");
   my $tmppas=$stdout;
   $tmppas=~s/^.*localhost: (.*)$/$1/s;
   $handle->{_cmd_handle}->print($sudo.'mysql_secure_installation');
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'Enter password for user root:') {
         $handle->{_cmd_handle}->print($tmppas);
         next;
      } elsif (-1<index $output,'New password:') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         next;
      } elsif (-1<index $output,'Re-enter new password:') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         next;
      } elsif (-1<index $output,'password for root') {
         $handle->{_cmd_handle}->print('n');
         next;
      } elsif (-1<index $output,'Remove anonymous users?') {
         $handle->{_cmd_handle}->print('y');
         next;
      } elsif (-1<index $output,'Disallow root login remotely?') {
         $handle->{_cmd_handle}->print('y');
         next;
      } elsif (-1<index $output,
            'Remove test database and access to it?') {
         $handle->{_cmd_handle}->print('y');
         next;
      } elsif (-1<index $output,'Reload privilege tables now?') {
         $handle->{_cmd_handle}->print('y');
         next;
      }
   }
   $handle->{_cmd_handle}->print('mysql -u root --password='.$service_and_cert_password);
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   my $cmd_sent=0;
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      my $out=$output;
      $out=~s/$prompt//sg;
      print $out if $output!~/^mysql>\s*$/;
      last if $output=~/$prompt|Bye/;
      if (!$cmd_sent && $output=~/mysql>\s*$/) {
         my $cmd='DROP DATABASE wordpress;';
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==1 && $output=~/mysql>\s*$/) {
         my $cmd="CREATE DATABASE wordpress;";
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==2 && $output=~/mysql>\s*$/) {
         my $cmd='DROP USER wordpressuser@localhost;';
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==3 && $output=~/mysql>\s*$/) {
         my $cmd='CREATE USER wordpressuser@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==4 && $output=~/mysql>\s*$/) {
         my $cmd='GRANT ALL PRIVILEGES ON wordpress.*'.
                 ' TO wordpressuser@localhost;';
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==5 && $output=~/mysql>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent>=6 && $output=~/mysql>\s*$/) {
         print "quit\n";
         $handle->{_cmd_handle}->print('quit');
         sleep 1;
         next;
      } sleep 1;
      $handle->{_cmd_handle}->print();
   }
   # https://shaunfreeman.name/compiling-php-7-on-centos/
   # https://www.vultr.com/docs/how-to-install-php-7-x-on-centos-7
   #$do=1;
   #if ($do==1) {
   if ($hostname eq 'jp-01ld.get-wisdom.com') {
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   'mkdir -p /usr/local/php7');
      ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/php/php-src.git','__display__');
      ($stdout,$stderr)=$handle->cwd('php-src');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git checkout PHP-7.0.2','__display__');
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
         '--with-gd '.
         '--enable-gd-native-ttf '.
         '--with-freetype-dir '.
         '--with-jpeg-dir '.
         '--with-png-dir '.
         '--enable-intl '.
         '--enable-mbstring '.
         '--with-mcrypt '.
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
         '--enable-zip '.
         '--with-zlib','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make -j2','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php7/etc/conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./php.ini-production /usr/local/php7/lib/php.ini',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php7/etc/conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./php.ini-production /usr/local/php7/lib/php.ini',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/www.conf /usr/local/php7/etc/php-fpm.d/www.conf',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/php-fpm.conf /usr/local/php7/etc/php-fpm.conf',
         '__display__');
      my $zend=<<END;
# Zend OPcache
zend_extension=opcache.so
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
         'ln -s /usr/local/php7/sbin/php-fpm /usr/sbin/php-fpm');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php7/bin/php /usr/bin/php');
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
      my $fpmsrv=<<END;
[Unit]
Description=The PHP FastCGI Process Manager
After=syslog.target network.target

[Service]
Type=simple
PIDFile=/run/php-fpm/php-fpm.pid
ExecStart=/usr/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php7/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \\x24MAINPID

[Install]
WantedBy=multi-user.target
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$fpmsrv\" > ".
         '/usr/lib/systemd/system/php-fpm.service');
      ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /run/php-fpm');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chkconfig --levels 235 php-fpm on');
      ($stdout,$stderr)=$handle->cmd('service php-fpm start','__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v /opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf.default '.
         '/opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/etc/init.d/ea-php70-php-fpm start",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/".
      'wp-cli.phar','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chmod -v +x wp-cli.phar",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v wp-cli.phar /usr/local/bin/wp",'__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   $ade=uri_escape($ade);
   my $wppass=uri_escape($service_and_cert_password);
   $tit=uri_escape($tit);
   $adu=uri_escape($adu); 
   my $urll='';
   if ($hostname eq 'jp-01ld.get-wisdom.com') {
      $urll='www.get-wisdom.com';
   } else {
      $urll=$ip.":".$avail_port;
   }
   my $cmd="sudo wget -d -qO- --random-wait --wait=3 ".
         "--no-check-certificate --post-data='weblog_title=".
         $tit."&user_name=".$adu."&admin_password=".
         $wppass."&pass1-text=".
         $wppass."&admin_password2=".
         $wppass."&admin_email=".$ade.
         "&Submit=Install+WordPress&language=' https://".
         $urll."/wp-admin/install.php?step=2";
   ($stdout,$stderr)=$handle->cmd($cmd);
#&Net::FullAuto::FA_Core::cleanup;
   if ($hostname eq 'jp-01ld.get-wisdom.com') {
      ($stdout,$stderr)=$handle->cwd("/var/www/html/wordpress/wp-content".
         "/themes"); 
   } else {
      ($stdout,$stderr)=$handle->cwd("WordPress/wordpress");
   }
   my $the='memberlite';
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      "https://memberlitetheme.com/wp-content/uploads/themes/$the.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://memberlitetheme.com/wp-content/uploads/themes/'.
      $the.'-child.zip','__display__');
   ($stdout,$stderr)=$handle->cmd(
      "/usr/local/bin/wp theme install $the.zip --allow-root ".
      "--activate --path=/var/www/html/wordpress",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "/usr/local/bin/wp theme install $the-child.zip --allow-root ".
      "--activate --path=/var/www/html/wordpress",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mkdir -vp wp-content/themes/$the-child/fonts",'__display__');
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
   my $oc_style=<<END;
/*
 Theme Name:   Memberlite Child
 Theme URI:    http://get-wisdom.com/$the-child/
 Description:  My first child theme, based on Memberlite
 Author:       Brian Kelly
 Author URI:   http://get-wisdom.com
 Template:     $the
 Version:      1.0.0
 Tags: one-column, two-columns, left-sidebar, right-sidebar, flexible-header, custom-background, custom-colors, custom-header, custom-menu, custom-logo, editor-style, featured-images, footer-widgets, full-width-template, post-formats, theme-options, threaded-comments, translation-ready, e-commerce
 Text Domain:  $the-child
*/

.site-branding .site-title a {
   font-family: 'Montserrat';
   font-size: x-large;
   font-weight: bold;
   /*color: floralwhite;*/
}

.site-branding .site-description {
   color: orange;
}

#buddypress .comment-reply-link, #buddypress .generic-button a, #buddypress .standard-form button, #buddypress a.button, #buddypress input[type=button], #buddypress input[type=reset], #buddypress input[type=submit], #buddypress ul.button-nav li a, a.bp-title-button {
    background: #18BC9C;
}

END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$oc_style\" > ".
      "/var/www/html/wordpress/wp-content/themes/$the-child/style.css");
my $oc_func=<<END;
<?php
//* Code goes here

add_filter('wp_nav_menu_items', 'add_login_logout_link', 10, 2);
   ($stdout,$stderr)=$handle->cmd($sudo,

function add_login_logout_link(\\x24items, \\x24args) {
        ob_start();
        wp_loginout('index.php');
        \\x24loginoutlink = ob_get_contents();
        ob_end_clean();
        \\x24arr = explode('Log ',\\x24loginoutlink,2);
        \\x24enn = explode('</a',\\x24arr[1]);
        \\x24icon='fa-user';
        if (\\x24enn[0] == 'out') {
           \\x24icon='fa-user-o';
        }
        //alert(\\x24enn[0]);
        \\x24items.='<li>'.\\x24arr[0].
           '<span class=\\x22text-wrap\\x22><i class=\\x22icon before fa '.
           \\x24icon.'\\x22 aria-hidden=\\x22true\\x22></i><span class=\\x22menu-text\\x22>Log '.
           \\x24enn[0].'</span></span></a></li>';
    return \\x24items;
}

function cleanmsg(\\x24msg){
// you clean code here
    return \\x24msg;
}

function alert(\\x24msg,\\x24timeout=1,\\x24url='index.php'){
    \\x24msg=cleanmsg(\\x24msg);
    echo \\x22<script>(function(){alert('\\x24msg');})();</script>\\x22;
    echo \\x22<meta http-equiv='refresh' content='\\x24timeout;\\x24url' />\\x22;
}

function wmpudev_enqueue_icon_stylesheet() {
        wp_register_style( 'fontawesome',
           'http:////maxcdn.bootstrapcdn.com/font-awesome/4.3.0/css/font-awesome.min.css' );
        wp_enqueue_style( 'fontawesome');
}
add_action( 'wp_enqueue_scripts', 'wmpudev_enqueue_icon_stylesheet' );

?>
END
my $googlefont=<<END;

function custom_add_google_fonts() {
 wp_enqueue_style( 'custom-google-fonts', 'https://fonts.googleapis.com/css?family=Montserrat', false );
 }
 add_action( 'wp_enqueue_scripts', 'custom_add_google_fonts' );
?>
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$googlefont\" >> ".
      '/var/www/html/wordpress/wp-content/themes/memberlite-child/functions.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '\$ d' ".
      '/var/www/html/wordpress/wp-content/themes/memberlite-child/functions.php');

   #($stdout,$stderr)=$handle->cmd(
   #   "/usr/local/bin/wp theme activate $the-child --allow-root",
   #   '__display__');
   if ($hostname eq 'jp-01ld.get-wisdom.com') {
      ($stdout,$stderr)=$handle->cwd("../plugins");
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://www.paidmembershipspro.com/wp-content/uploads/plugins/'.
      'pmpro-nav-menus.zip','__display__');
   # http://www.theblogmaven.com/best-wordpress-plugins/

   my $listt=<<'END';
+-------------------------------------------------+--------+--------+---------+
| name                                            | status | update | version |
+-------------------------------------------------+--------+--------+---------+
| addons-for-elementor                            | active | none   | 1.4.1   |
| all-in-one-wp-migration                         | active | none   | 6.61    |
| bbpress                                         | active | none   | 2.5.14  |
| better-recent-comments                          | active | none   | 1.0.4   |
| black-studio-tinymce-widget                     | active | none   | 2.6.0   |
| buddypress                                      | active | none   | 2.9.2   |
| check-email                                     | active | none   | 0.5.5   |
| commentluv                                      | active | none   | 2.94.7  |
| comment-redirect                                | active | none   | 1.1.3   |
| comment-reply-email-notification                | active | none   | 1.4.1   |
| contact-form-7                                  | active | none   | 4.9.1   |
| custom-dashboard-widgets                        | active | none   | 1.3.1   |
| easy-google-fonts                               | active | none   | 1.4.3   |
| elementor                                       | active | none   | 1.8.9   |
| google-analytics-dashboard-for-wp               | active | none   | 5.1.2.3 |
| jetpack                                         | active | none   | 5.6     |
| maxbuttons                                      | active | none   | 6.24    |
| meks-easy-ads-widget                            | active | none   | 2.0.3   |
| meks-flexible-shortcodes                        | active | none   | 1.3.1   |
| meks-simple-flickr-widget                       | active | none   | 1.1.3   |
| meks-smart-author-widget                        | active | none   | 1.1.1   |
| meks-smart-social-widget                        | active | none   | 1.3.4   |
| meks-themeforest-smart-widget                   | active | none   | 1.2     |
| memberlite-shortcodes                           | active | none   | 1.1     |
| menu-icons                                      | active | none   | 0.10.2  |
| menu-icons-icomoon                              | active | none   | 0.3.0   |
| multiple-post-thumbnails                        | active | none   | 1.6.6   |
| nav-menu-roles                                  | active | none   | 1.9.1   |
| paid-memberships-pro                            | active | none   | 1.9.4.2 |
| pmpro-nav-menus                                 | active | none   | .3.2    |
| read-more-without-refresh                       | active | none   | 2.3     |
| simple-share-buttons-adder                      | active | none   | 7.3.10  |
| simple-trackback-validation-with-topsy-blocker  | active | none   | 1.2.7   |
| text-hover                                      | active | none   | 3.7.1   |
| theme-my-login                                  | active | none   | 6.4.9   |
| woocommerce                                     | active | none   | 3.2.5   |
| woocommerce-gateway-paypal-powered-by-braintree | active | none   | 2.0.4   |
| woocommerce-services                            | active | none   | 1.9.0   |
| woocommerce-gateway-stripe                      | active | none   | 3.2.3   |
| wpfront-notification-bar                        | active | none   | 1.7     |
| wp-mail-smtp                                    | active | none   | 0.11.2  |
| wp-to-twitter                                   | active | none   | 3.3.1   |
| wordpress-seo                                   | active | none   | 5.9.1   |
+-------------------------------------------------+--------+--------+---------+
END

   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/wp plugin install paid-memberships-pro '.
      '--allow-root --activate --path=/var/www/html/wordpress',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/wp plugin install pmpro-nav-menus.zip '.
      '--allow-root --activate --path=/var/www/html/wordpress',
      '__display__');

$do=1;
if ($do==1) {

   my @wp_plugins = qw(

         all-in-one-wp-migration
         bbpress
         better-recent-comments
         black-studio-tinymce-widget
         buddypress
         check-email
         commentluv
         comment-redirect
         comment-reply-email-notification
         contact-form-7
         custom-dashboard-widgets
         easy-google-fonts
         elementor
         addons-for-elementor
         google-analytics-dashboard-for-wp
         #hide-admin-bar-from-non-admins
         maxbuttons
         meks-easy-ads-widget
         meks-flexible-shortcodes
         meks-simple-flickr-widget
         meks-smart-author-widget
         meks-smart-social-widget
         meks-themeforest-smart-widget
         memberlite-shortcodes
         menu-icons
         menu-icons-icomoon
         wp-mail-smtp

   );
   foreach my $plugin (@wp_plugins) {
      next if $plugin=~/^#/;
      ($stdout,$stderr)=$handle->cmd(
         "/usr/local/bin/wp plugin install $plugin --allow-root ".
         "--activate --path=/var/www/html/wordpress",
         '__display__');
   }
}
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv www-data:www-data /var/www','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'find /var/www -type f | xargs -e chmod 644','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'find /var/www -type d | xargs -e chmod 755','__display__');

#&Net::FullAuto::FA_Core::cleanup;

my $md_='';our $thismonth='';our $thisyear='';
($md_,$thismonth,$thisyear)=(localtime)[3,4,5];
my $mo_=$thismonth;my $yr_=$thisyear;
$md_="0$md_" if $md_<10;
$mo_++;$mo_="0$mo_" if $mo_<10;
my $yr__=sprintf("%02d",$yr_%100);
my $yr____=(1900+$yr_);
my $mdy="$mo_$md_$yr__";
my $mdyyyy="$mo_$md_$yr____";
my $tm=scalar localtime($^T);
my $hms=substr($tm,11,8);
$hms=~s/^(\d\d):(\d\d):(\d\d)$/h${1}m${2}s${3}/;
my $hr=$1;my $mn=$2;my $sc=$3;
my $curyear=$thisyear + 1900;
($stdout,$stderr)=$handle->cmd($sudo.
   "mkdir -vp /var/www/html/wordpress/wp-content/uploads/$curyear/$mo_",
   '__display__');
($stdout,$stderr)=$handle->cmd($sudo.
   "/usr/local/bin/wp media import $builddir/$ls_tmp[0]/dependencies/gw/* ".
   "--path=/var/www/html/wordpress --allow-root",'__display__');
($stdout,$stderr)=$handle->cmd($sudo."/usr/local/bin/".
   "wp db query \"select post_id from wp_postmeta where meta_value like ".
   "'%angelwing75%'\" --path=/var/www/html/wordpress --allow-root");
$stdout=~s/^.*(\d+)$/$1/s;
my $post_id=$stdout;
$handle->{_cmd_handle}->print('mysql -u root --password='.$service_and_cert_password);
$prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
$cmd_sent=0;
while (1) {
   my $output=Net::FullAuto::FA_Core::fetch($handle);
   my $out=$output;
   $out=~s/$prompt//sg;
   print $out if $output!~/^mysql>\s*$/;
   last if $output=~/$prompt|Bye/;
   if (!$cmd_sent && $output=~/mysql>\s*$/) {
      my $cmd='UPDATE wordpress.wp_options SET option_value = \'a:5:{s:18:"nav_menu_locations";a:0:{}s:18:"custom_css_post_id";i:-1;s:10:"meta_login";b:1;s:15:"nav_menu_search";b:1;s:20:"columns_ratio_header";s:3:"7-5";}\' WHERE option_name = \'theme_mods_memberlite-child\';';
      print "$cmd\n";
      $handle->{_cmd_handle}->print($cmd);
      $cmd_sent++;
      sleep 1;
      next;
   } elsif ($cmd_sent==1 && $output=~/mysql>\s*$/) {
      my $cmd='UPDATE wordpress.wp_options SET option_value = \'1\' WHERE option_name = \'users_can_register\';';
      print "$cmd\n";
      $handle->{_cmd_handle}->print($cmd);
      $cmd_sent++;
      sleep 1;
      next;
   } elsif ($cmd_sent>=2 && $output=~/mysql>\s*$/) {
      print "quit\n";
      $handle->{_cmd_handle}->print('quit;');
      sleep 1;
      next;
   } sleep 1;
   $handle->{_cmd_handle}->print();
}

$do=1;
if ($do==1) {

   $service_and_cert_password=uri_escape($service_and_cert_password);
   ($stdout,$stderr)=$handle->cmd(
      "wget -d -qO- --no-check-certificate --random-wait --wait=3 ".
      "--cookies=on --keep-session-cookies --load-cookies ~/cookies.txt ".
      "--save-cookies ~/cookies.txt -d https://$urll/wp-login.php");
   ($stdout,$stderr)=$handle->cmd(
      'curl -k --cookie-jar ~/cookies.txt https://'.
      $urll.'/wp-login.php');
   ($stdout,$stderr)=$handle->cmd(
      'curl -v -k --cookie-jar ~/cookies.txt --max-redirs 0 '.
      '--data "log='.$adu.'&pwd='.$service_and_cert_password.
      '&wp-submit=Log+In&redirect_to='.$url.
      '%2Fwp-admin%2F&testcookie=1" https://'.$urll.
      '/wp-login.php');
   sleep 5;
   my $nonce_cmd="curl -k -L -b ~/cookies.txt 'https://".$urll.'/wp-admin/'.
         "customize.php?url=".$url."%2F' ".
         "-H 'Accept: text/html,".
         "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' ".
         "-H 'Accept-Encoding: gzip, deflate, br' ".
         "-H 'Accept-Language: en-US,en;q=0.5' ".
         "-H 'Connection: keep-alive' ".
         "-H 'Host: ".$urll."' ".
         "-H 'Referer: https://".$urll."/' ".
         "-H 'Upgrade-Insecure-Requests: 1' ".
         "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; ".
         "Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0'";
   my $one=1;
   foreach (1..5) {
      $handle->{_cmd_handle}->print($nonce_cmd);
      my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
      $handle->{_cmd_handle}->print($nonce_cmd);
      while (1) {
         my $output.=Net::FullAuto::FA_Core::fetch($handle);
         $stdout.=$output;
         last if $output=~/$prompt/;
         print $output;
      }
      $stdout=~s/^.*_wpCustomizeSettings = (.*?)[}][}][}].*$/$1/s;
      last if -1<index $stdout,'"nonce":{';
      ($stdout,$stderr)=&Net::FullAuto::FA_Core::clean_filehandle($handle);
      ($stdout,$stderr)=$handle->cmd(
         'curl -v -k --cookie-jar ~/cookies.txt --max-redirs 0 '.
         '--data "log='.$adu.'&pwd='.$service_and_cert_password.
         '&wp-submit=Log+In&redirect_to='.$url.
         '%2Fwp-admin%2F&testcookie=1" https://'.$urll.
         '/wp-login.php');
print "LOGIN STDOUT=$stdout and STDERR=$stderr<==LOGIN STDERR\n";sleep 10;
      sleep 4;
   }
   my $nonce=$stdout;
   my $uuid=$stdout;
   $nonce=~s/^.*nonce["]:([{].*?[}]),.*$/$1/s;
print "NONCE=$nonce\n";sleep 5;
   my $nonce_hash=decode_json($nonce);
#print "NONCE=$nonce<==NONCE and SAVE=$nonce_hash->{save} and PREVIEW=$nonce_hash->{preview}\n";<STDIN>;
   $uuid=~s/^.*uuid["]:["](.*?)["],.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.'/wp-admin/'.
      "customize.php?url=".$url."%2F&changeset_uuid=$uuid".
      "&customize_theme=memberlite-child&customize_messenger_channel=preview-0' ".
      "-H 'Accept: text/html,".
      "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/' ".
      "-H 'Upgrade-Insecure-Requests: 1' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; ".
      "Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/?customize_changeset_uuid=".$uuid."' ".
      "-H 'Accept: */*' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/?customize_changeset_uuid=".$uuid."&customize_theme=memberlite-child&customize_messenger_channel=preview-0' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'X-Requested-With: XMLHttpRequest' ".
      "--data 'wp_customize=on&nonce=".$nonce_hash->{preview}."&customize_theme=memberlite-child&customized=%7B%22blogdescription%22%3A%22Revealing+and+Healing+the+Number+One+Cause+of+Human+Difficulty%22%7D&customize_changeset_uuid=".$uuid."&partials=%7B%22blogdescription%22%3A%5B%7B%7D%5D%7D&wp_customize_render_partials=1&action=&customized=%7B%22blogdescription%22%3A%22Revealing+and+Healing+the+Number+One+Cause+of+Human+Difficulty%22%7D'");
print "CUSTOMIZED STDOUT=$stdout<== and STDERR=$stderr<==\n";
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin-ajax.php' ".
      "-H 'Accept: */*' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/wp-admin/customize.php?url=https%3A%2F%2F".$urll."%2Fchangeset_uuid=".$uuid."' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'X-Requested-With: XMLHttpRequest' ".
      "--data 'wp_customize=on&customize_theme=memberlite-child&nonce=".$nonce_hash->{save}."&customize_changeset_uuid=".$uuid."&customize_changeset_data=%7B%22blogdescription%22%3A%7B%22value%22%3A%22Revealing+and+Healing+the+Number+One+Cause+of+Human+Difficulty%22%7D%7D&action=customize_save&customize_preview_nonce=".$nonce_hash->{preview}."'");
print "CUSTOMIZE_SAVE STDOUT=$stdout<== and STDERR=$stderr<==\n";
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin-ajax.php' ".
      "-H 'Host: ".$urll."' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'Accept: */*' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'X-Requested-With: XMLHttpRequest' ".
      "-H 'Referer: https://".$urll."/wp-admin/customize.php?url=https%3A%2F%2F$urll%2F&changeset_uuid=$uuid' ".
      "-H 'Connection: keep-alive' ".
      "--data 'wp_customize=on&customize_theme=memberlite-child&nonce=".$nonce_hash->{save}."&customize_changeset_uuid=$uuid&customized=%7B%22blogdescription%22%3A%22Revealing+and+Healing+the+Number+One+Cause+of+Human+Difficulty%22%7D&customize_changeset_status=publish&action=customize_save&customize_preview_nonce=".$nonce_hash->{preview}."'");
print "WHAT IS HEALING STDOUT=$stdout\n";

##############################################################

   #($stdout,$stderr)=&Net::FullAuto::FA_Core::clean_filehandle($handle);
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.'/wp-admin/'.
      "customize.php?url=".$url."%2F' ".
      "-H 'Accept: text/html,".
      "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; ".
      "Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/' ".
      "-H 'Upgrade-Insecure-Requests: 1'");
print "WHAT IS STDOUT=$stdout<== and LOGO STDERR =$stderr<==\n";sleep 10;
   $stdout=~s/^.*_wpCustomizeSettings = (.*?)[}][}][}].*$/$1/s;
   $nonce=$stdout;
   $uuid=$stdout;
   $nonce=~s/^.*nonce["]:([{].*?[}]),.*$/$1/s;
   $nonce_hash=decode_json($nonce);
   $uuid=~s/^.*uuid["]:["](.*?)["],.*$/$1/s;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.'/wp-admin/'.
      "customize.php?url=".$url."%2F&changeset_uuid=$uuid".
      "&customize_theme=memberlite-child&customize_messenger_channel=preview-0' ".
      "-H 'Accept: text/html,".
      "application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/' ".
      "-H 'Upgrade-Insecure-Requests: 1' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; ".
      "Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0'");
   $stdout=~s/^.*_wpCustomizeSettings = (.*?)[}][}][}].*$/$1/s;
   $nonce=$stdout;
   $uuid=$stdout;
   $nonce=~s/^.*nonce["]:([{].*?[}]),.*$/$1/s;
print "NONCE=$nonce<==\n";sleep 5;
   $nonce_hash=decode_json($nonce);
   $uuid=~s/^.*uuid["]:["](.*?)["],.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/?customize_changeset_uuid=".$uuid."&customize_autosaved=on&customize_preview_nonce=".$nonce_hash->{preview}."' ".
      "-H 'Host: ".$urll."' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'Accept: */*' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'Referer: https://".$urll."/' ".
      "-H 'Upgrade-Insecure-Requests: 1' ".
      "--data 'wp_customize=on&nonce=".$nonce_hash->{preview}."&customize_theme=memberlite-child&customized=%7B%22custom_logo%22%3A".$post_id."%7D&customize_changeset_uuid=".$uuid."&partials=%7B%22custom_logo%22%3A%5B%7B%7D%5D%7D&wp_customize_render_partials=1&action=&customized=%7B%22custom_logo%22%3A".$post_id."%7D'");
print "STDOUT=$stdout<==CUSTOM LOGO\n";sleep 5;

   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin-ajax.php' ".
      "-H 'Host: ".$urll."' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'Accept: */*' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'Referer: https://".$urll."/wp-admin/customize.php?url=https%3A%2F%2Fwww.get-wisdom.com%2F' ".
      "-H 'Upgrade-Insecure-Requests: 1' ".
      "--data 'nonce=".$nonce_hash->{preview}."&id=".$post_id."&context=site-icon&cropDetails%5Bx1%5D=5&cropDetails%5By1%5D=0&cropDetails%5Bx2%5D=80&cropDetails%5By2%5D=75&cropDetails%5Bwidth%5D=75&cropDetails%5Bheight%5D=75&cropDetails%5Bdst_width%5D=512&cropDetails%5Bdst_height%5D=512&action=crop-image'");

   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin-ajax.php' ".
      "-H 'Accept: */*' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/wp-admin/customize.php?url=https%3A%2F%2F".$urll."%2Fchangeset_uuid=".$uuid."' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:56.0) Gecko/20100101 Firefox/56.0' ".
      "-H 'X-Requested-With: XMLHttpRequest' ".
      "--data 'wp_customize=on&customize_theme=memberlite-child&nonce=".$nonce_hash->{save}."&customize_changeset_uuid=".$uuid."&customize_autosaved=on&customized=%7B%22site_icon%22%3A".$post_id."%2C%22custom_logo%22%3A".$post_id."%7D&customize_changeset_status=publish&action=customize_save&customize_preview_nonce=".$nonce_hash->{preview}."'");

print "STDOUT=$stdout<==CUSTOM LOGO PUBLISH\n";

}

   my @wp_plugins=qw(

         multiple-post-thumbnails
         nav-menu-roles
         read-more-without-refresh
         simple-share-buttons-adder
         simple-trackback-validation-with-topsy-blocker
         text-hover
         theme-my-login
         wpfront-notification-bar
         wp-to-twitter
         wordpress-seo
         woocommerce
         woocommerce-gateway-paypal-powered-by-braintree
         woocommerce-services
         woocommerce-gateway-stripe

   );

   foreach my $plugin (@wp_plugins) {
      next if $plugin=~/^#/;
      ($stdout,$stderr)=$handle->cmd(
         "/usr/local/bin/wp plugin install $plugin --allow-root ".
         "--activate --path=/var/www/html/wordpress",
         '__display__');
   }

   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's#check_admin_referer#//check_admin_referer#' ".
      '/var/www/html/wordpress/wp-content/plugins/'.
      'theme-my-login/includes/class-theme-my-login.php');

   ($stdout,$stderr)=&Net::FullAuto::FA_Core::clean_filehandle($handle);

   ($stdout,$stderr)=$handle->cmd(
      '/usr/local/bin/wp post list --post_type=page,post --allow-root '.
      '--path=/var/www/html/wordpress');
   $stdout=~s/^.*\n(\d+).*?register.*?\n.*$/$1/s;
   print "register page ID=$stdout<==REGISTERID\n";
   ($stdout,$stderr)=$handle->cmd(
      "/usr/local/bin/wp post delete $stdout --force --allow-root ".
      '--path=/var/www/html/wordpress','__display__');

   ($stdout,$stderr)=$handle->cmd($sudo.
      "/usr/local/bin/wp post create --post_title='Register' --post_type=page ".
      "--allow-root --post_status=publish --post_content='".
      "[theme-my-login default_action=\"register\" show_title=\"0\"]' ".
      "--path=/var/www/html/wordpress",'__display__');

   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=wc-setup' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Upgrade-Insecure-Requests: 1' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/wp-admin/admin.php?page=".
          "wc-settings&tab=checkout&section=stripe' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=wc-setup' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Upgrade-Insecure-Requests: 1' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/wp-admin/admin.php?page=".
          "wc-settings&tab=checkout&section=stripe' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36'");
print "STDOUT=$stdout<==WC-SETUP\n";
#&Net::FullAuto::FA_Core::cleanup;
   $stdout=~s/^.*_wpnonce.*?value=["](.*?)["].*$/$1/s;
   my $nonce=$stdout;
print "NONCE=$nonce<==NONCE\n";sleep 5;
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=wc-setup' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Content-Type: application/x-www-form-urlencoded' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll."/wp-admin/admin.php?page=wc-setup' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "--data '_wpnonce=".$nonce."&_wp_http_referer=%2Fwp-admin%2Fadmin.php%3Fpage%3Dwc-setup&store_country_state=US%3AIL&store_address=714+E.+Diggins+St.&store_address_2=&store_city=Harvard&store_postcode=60033&currency_code=USD&product_type=both&save_step=Let%27s+go%21'");
print "WC-SETUPOUT=$stdout<==WC-SETUP-SENT\n";
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=wc-setup&step=payment' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=wc-setup' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=payment' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=payment' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "--data 'stripe_email=Brian.Kelly%40get-wisdom.com&wc-wizard-service-stripe-enabled=yes&wc-wizard-service-braintree_paypal-enabled=yes&paypal_email=Brian.Kelly%40get-wisdom.com&wc-wizard-service-paypal-enabled=yes&save_step=Continue&_wpnonce=".$nonce."&_wp_http_referer=%2Fwp-admin%2Fadmin.php%3Fpage%3Dwc-setup%26step%3Dpayment'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=shipping' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=payment' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=shipping' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.5' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Content-Type: application/x-www-form-urlencoded' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=shipping' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "--data 'shipping_zones%5Bdomestic%5D%5Bmethod%5D=live_rates&shipping_zones%5Bdomestic%5D%5Bflat_rate%5D%5Bcost%5D=&shipping_zones%5Bdomestic%5D%5Benabled%5D=yes&shipping_zones%5Bintl%5D%5Bmethod%5D=live_rates&shipping_zones%5Bintl%5D%5Bflat_rate%5D%5Bcost%5D=&shipping_zones%5Bintl%5D%5Benabled%5D=yes&weight_unit=oz&dimension_unit=in&save_step=Continue&_wpnonce=".$nonce."&_wp_http_referer=%2Fwp-admin%2Fadmin.php%3Fpage%3Dwc-setup%26step%3Dshipping'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=extras' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=shipping' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36'");
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=extras' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=extras' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "--data 'save_step=Continue&_wpnonce=".$nonce."&_wp_http_referer=%2Fwp-admin%2Fadmin.php%3Fpage%3Dwc-setup%26step%3Dextras'");
print "STDOUTEXTRAS=$stdout<==EXTRAS-SENT\n";
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=next_steps ' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded;' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=extras' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36'");
print "STDOUTACTIVATE=$stdout<==ACTIVATE\n";
   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=next_steps' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9' ".
      "-H 'Cache-Control: max-age=0' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Content-Type: application/x-www-form-urlencoded' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Referer: https://".$urll.
          "/wp-admin/admin.php?page=wc-setup&step=next_steps' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "--data 'save_step=activate&_wpnonce=".$nonce."&_wp_http_referer=%2Fwp-admin%2Fadmin.php%3Fpage%3Dwc-setup%26step%3Dactivate'");
print "DONE=$stdout<==ACTIVATE-SENT\n";

   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=pmpro-pagesettings' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Referer: https://".$urll."/wp-admin/' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9'");
   $stdout=~s/^.*pmpro_pagesettings_nonce=(.*?)["].*$/$1/s;
   $nonce=$stdout;
print "NONCE=$nonce<==NONCE\n";

   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=pmpro-pagesettings".
          "&createpages=1&pmpro_pagesettings_nonce=$nonce' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Referer: https://".$urll."/wp-admin/admin.php?page=pmpro-pagesettings' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9'");

   ($stdout,$stderr)=$handle->cmd(
      "curl -k -L -b ~/cookies.txt 'https://".$urll."/wp-admin/admin.php?page=pmpro-pagesettings' ".
      "-H 'Host: ".$urll."' ".
      "-H 'Connection: keep-alive' ".
      "-H 'Upgade-Insecure-Requests: 1' ".
      "-H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) ".
          "AppleWebKit/537.36 (KHTML, like Gecko) ".
          "Chrome/62.0.3202.94 Safari/537.36' ".
      "-H 'Accept: text/html,application/xhtml+xml,application/xml;".
          "q=0.9,image/webp,image/apng,*/*;q=0.8' ".
      "-H 'Referer: https://".$urll."/wp-admin/admin.php?page=pmpro-pagesettings".
          "&createpages=1&pmpro_pagesettings_nonce=$nonce' ".
      "-H 'Accept-Encoding: gzip, deflate, br' ".
      "-H 'Accept-Language: en-US,en;q=0.9'");

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


   Copyright (C) 2000-2017  Brian M. Kelly  Brian.Kelly@FullAuto.com

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

my $standup_wordpress=sub {

   my $catalyst="]T[{select_wordpress_setup}";
   my $password="]I[{'enter_password',1}";
   my $cnt=0;
   $configure_wordpress->($catalyst,$password);
   return '{choose_demo_setup}<';

};

my $wordpress_setup_summary=sub {

   package wordpress_setup_summary;
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
   my $catalyst="]T[{select_wordpress_setup}";
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
         Result => $standup_wordpress,

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
   foreach my $count (1..50) {
      print "\n   Generating Password ...\n";
      $word=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         my $word=word(10,15,3,5,6);
         print "\n   Trying Password - $word ...\n";
         die if -1<index $word,'*';
         die if -1<index $word,'$';
         die if -1<index $word,'+';
         die if -1<index $word,'&';
         die if -1<index $word,'/';
         die if -1<index $word,'!';
         die if $word!~/\d/;
         die if $word!~/[A-Z]/;
         die if $word!~/[a-z]/;
         die if $word!~/[@#%^=]/;
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
      Result => $standup_wordpress,
      #Result =>
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
      Banner => $password_banner,

   };
   return $enter_password;

};

our $select_wordpress_setup=sub {

   my @options=('WordPress on This Host');
   my $wordpress_setup_banner=<<'END';

   ___   ___     (\
   \  \  \  \     /             _ ____
    \  \  \  \   / ___  _ __ __| |  _ \ _ __ ___  ___ ___
     \  \ /\  \ / / _ \| '__/ _` | |_) | '__/ _ \/ __/ __|
      \  /  \  / | (_) | | | (_| |  __/| | |  __/\__ \__ \
       \/    \/   \___/|_|  \__,_|_|   |_|  \___||___/___/


   Choose the WordPress setup you wish to install on this localhost:

END
   my %select_wordpress_setup=(

      Name => 'select_wordpress_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         #Result => $standup_wordpress,
         Result => $choose_strong_password,

      },
      Scroll => 1,
      Banner => $wordpress_setup_banner,
   );
   return \%select_wordpress_setup

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

