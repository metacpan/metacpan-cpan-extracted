package Net::FullAuto::ISets::Local::PHP_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Powerful Network Process Automation Software
#    Copyright © 2000-2021  Brian M. Kelly
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
our $DISPLAY='PHP';
our $CONNECT='secure';

use 5.005;

use strict;
use warnings;

my $service_and_cert_password='Full@ut0O1';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_php_setup);

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
# how-to-add-a-loginlogout-link-to-your-php-menu/
# http://vanweerd.com/enhancing-your-php-3-menus/#add_login

# wp plugin list --path=/var/www/html/php --status=active --allow-root

# https://www.digitalocean.com/community/tutorials/
# how-to-set-up-a-firewall-using-firewalld-on-centos-7
# sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
# sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
# sudo firewall-cmd --zone=public --permanent --list-ports

# https://chrisjean.com/change-timezone-in-centos/

# https://www.cartoonify.de/

my $configure_php=sub {

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
   my $prompt=$handle->prompt();
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
      if ($stdout=~/php-fpm: master process/s) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'service php-fpm stop','__display__');
      }
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
   }
#cleanup;
   ($stdout,$stderr)=$handle->cmd("wget -qO- https://icanhazip.com");
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
   ($stdout,$stderr)=$handle->cwd("/opt/source");
   # https://shaunfreeman.name/compiling-php-7-on-centos/
   # https://www.vultr.com/docs/how-to-install-php-7-x-on-centos-7
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
      ($stdout,$stderr)=$handle->cmd($sudo.'make -j2','__display__');
cleanup;
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


   Copyright (C) 2000-2021  Brian M. Kelly  Brian.Kelly@FullAuto.com

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

my $standup_php=sub {

   my $catalyst="]T[{select_php_setup}";
   my $password="]I[{'enter_password',1}";
   my $email_address="]I[{'email_address',1}";
   my $stripe_pub="]I[{'stripe_keys',1}";
   my $stripe_sec="]I[{'stripe_keys',2}";
   my $recaptcha_pub="]I[{'recaptcha_keys',1}";
   my $recaptcha_sec="]I[{'recaptcha_keys',2}";
   my $domain_url="]I[{'domain_url',1}";
   my $cnt=0;
   $configure_php->($catalyst,$domain_url,$password,$email_address,$stripe_pub,
                          $stripe_sec,$recaptcha_pub,$recaptcha_sec);
   return '{choose_demo_setup}<';

};

our $select_php_setup=sub {

   my @options=('PHP on This Host');
   my $php_setup_banner=<<'END';

    ____  _   _ ____
   |  _ \| | | |  _ \
   | |_) | |_| | |_) |
   |  __/|  _  |  __/
   |_|   |_| |_|_|


   Choose the PHP setup you wish to install on this localhost:

END
   my %select_php_setup=(

      Name => 'select_php_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
	 Result => $standup_php,

      },
      Scroll => 1,
      Banner => $php_setup_banner,
   );
   return \%select_php_setup

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

