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
my $home_dir=File::HomeDir->my_home;
$home_dir||=$ENV{'HOME'}||'';
$home_dir.='/';
my $username=getlogin || getpwuid($<);
my $do;my $ad;my $prompt;my $public_ip='';
my $builddir='';my @ls_tmp=();

my $configure_wordpress=sub {

   my $selection=$_[0]||'';
   my $service_and_cert_password=$_[1]||'';
   my ($stdout,$stderr)=('','');
   my $handle=$localhost;my $connect_error='';
   $handle->cwd('~');
   my $userhome=$handle->cmd('pwd');
   my $sudo=($^O eq 'cygwin')?'':'sudo ';
   ($stdout,$stderr)=$handle->cmd("${sudo}perl -e \'use CPAN;".
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
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chmod -v 755 ~",'__display__');
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
         ' libmcrypt-devel libcurl-devel','__display__');
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
   ($stdout,$stderr)=$handle->cmd($sudo.
      "python --version",'__display__');
   if ($stderr=~/Python /) {
      $stderr=~s/^Python\s+(\d.\d).*$/$1/;
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
   ($stdout,$stderr)=$handle->cmd('/usr/local/bin/python2.7 ez_setup.py',
      '__display__');
   ($stdout,$stderr)=$handle->cmd('easy_install pip','__display__');
   ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
   ($stdout,$stderr)=$handle->cmd(
      'git clone https://github.com/google/oauth2client.git','__display__');
   ($stdout,$stderr)=$handle->cwd('oauth2client');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/python2.7 setup.py install',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('~/WordPress/deps');
   unless ($^O eq 'cygwin') {
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
   ($stdout,$stderr)=$handle->cwd("~/WordPress/deps/$nginx");
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
            } elsif (-1<index $test,'State or Province Name (full name) []') {
               $handle->{_cmd_handle}->print('.');
               $output='';
               $test='';
               next;
            } elsif (
                  -1<index $test,'Locality Name (eg, city) [Default City]:') {
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
                 'Common Name (eg, your name or your server\'s hostname) []') {
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
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/1024/64/' ".
      "/usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/root   html/{//d;}' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '0,/index  index.html/{//d;}' /usr/local/nginx/nginx.conf");
   $ad="            root ${home_dir}WordPress/wordpress;%NL%".
       "            index  index.php  index.html index.htm;";
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' /usr/local/nginx/nginx.conf
END
   $handle->cmd_raw($sudo.$ad);
   $ad='%NL%        location ~ .php$ {'.
       "%NL%            root ${home_dir}WordPress/wordpress;".
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
       "sed -i \'/404/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/usr/local/nginx/nginx.conf");
   my $avail_port='';
   foreach my $port (443,444,445,443) {
      $avail_port=
      `true &>/dev/null </dev/tcp/127.0.0.1/$port && echo open || echo closed`;
      my $status=$avail_port;
      $avail_port=$port;
      chomp($status);
      last if $status eq 'closed';
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/^        listen       80/        listen       ".
       "\*:$avail_port ssl default_server/\' /usr/local/nginx/nginx.conf");
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
\\x24handle->{_cmd_handle}->print('/usr/local/nginx/nginx -g \\x22daemon on;\\x22');
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
      ($stdout,$stderr)=$handle->cmd("chmod -v o+r /usr/local/nginx/*",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("chmod -v 755 /usr/local/nginx/nginx.exe",
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
      $handle->{_cmd_handle}->print($sudo."/usr/local/nginx/nginx");
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
}
   # https://shaunfreeman.name/compiling-php-7-on-centos/
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
   $handle->{_cmd_handle}->print('mysql -u root');
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
   $do=0;
   if ($do==1) {
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -v /usr/local/php7','__display__');
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
      'cp -v /opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf.default '.
      '/opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf','__display__');
   }
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "chmod -Rv 777 WordPress",'__display__');

   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "sudo rsync -avP ~/wordpress/ /var/www/html/",'__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   "mkdir -v wp-content/uploads",'__display__');

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
