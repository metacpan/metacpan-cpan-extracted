package Net::FullAuto::ISets::Local::Ampache_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2025  Brian M. Kelly
#
#    This program is free software: you can redistribute it and/or
#    modify it under the terms of the GNU Affero General Public License
#    as published by the Free Software Foundation, either version 3 of
#    the License, or any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but **WITHOUT ANY WARRANTY**; without even the implied warranty
#    of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public
#    License along with this program.  If not, see:
#    <http://www.gnu.org/licenses/agpl.html>.
#
#######################################################################

our $VERSION='0.01';
our $DISPLAY='AMPACHE';
our $CONNECT='secure';
our $defaultInstanceType='t2.micro';

my $service_and_cert_password='Full@ut0O1';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_ampache_setup);

use File::HomeDir;
use JSON::XS;
use POSIX qw(strftime);
my $home_dir=File::HomeDir->my_home.'/';

use Net::FullAuto::Cloud::fa_amazon;
use Net::FullAuto::FA_Core qw[$localhost];

# https://thechamberlands.net/video-streaming/
# https://github.com/jwplayer/jwplayer

my $configure_ampache=sub {

   my $server_type=$_[0];
   my $selection=$_[1]||'';
   my $region=$_[2]||'';
   my $verified_email=$_[3]||'';
   my $permanent_ip=$_[4]||'';
   my $site_name=$_[5]||'';
   my $site_profile=$_[6]||'';
   my $site_build=$_[7]||'';
   $service_and_cert_password=$_[8]||'';
   my $sudo='sudo ';
   if ($site_profile=~/Commmunity/) {
      $site_profile='community';
   } elsif ($site_profile=~/Public/) {
      $site_profile='public';
   } elsif ($site_profile=~/Single/) {
      $site_profile='singleuser';
   } elsif ($site_profile=~/Private/) {
      $site_profile='private';
   }
   $permanent_ip='' if $permanent_ip=~/Stay|Reason/;
   if (exists $main::aws->{permanent_ip}) {
      $permanent_ip=$main::aws->{permanent_ip}; 
   }
   my $test_aws='wget --timeout=5 --tries=1 -qO- '.
                'http://169.254.169.254/latest/dynamic/instance-identity/';
   $test_aws=`$test_aws`;
   if (-1<index $test_aws,'signature') {
      my $n=$main::aws->{fullauto}->
            {SecurityGroups}->[0]->{GroupName}||'';
      my $c='aws ec2 describe-security-groups '.
            "--group-names $n";
      my ($hash,$output,$error)=('','','');
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error;
      my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
              ->[0]->{IpRanges}->[0]->{CidrIp};
      $c='aws ec2 create-security-group --group-name '.
         'AmpacheSecurityGroup --description '.
         '"AMPACHE.com Security Group" 2>&1';
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name AmpacheSecurityGroup --protocol '.
         'tcp --port 22 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name AmpacheSecurityGroup --protocol '.
         'tcp --port 80 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name AmpacheSecurityGroup --protocol '.
         'tcp --port 443 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      my $g=get_aws_security_id('AmpacheSecurityGroup');
      my $fullauto_inst=
            Net::FullAuto::Cloud::fa_amazon::get_fullauto_instance();
      my $i=$fullauto_inst->{InstanceId};
      $c="aws ec2 modify-instance-attribute --instance-id $i ".
         "--groups $g";
      ($hash,$output,$error)=run_aws_cmd($c);
      $c='aws ec2 describe-security-groups '.
         "--group-names $n";
      ($hash,$output,$error)=run_aws_cmd($c);
      my $sg=$hash->{SecurityGroups}->[0]->{GroupName};
      print "\n   NEW SECURITY GROUP -> $sg\n\n";
   }
#&Net::FullAuto::FA_Core::cleanup;

   my $local=$localhost;
   my $handle=$local;
   my ($stdout,$stderr)=('','');
   my $c='';
   ($stdout,$stderr)=$handle->cmd($sudo.'groupadd www-data');
   ($stdout,$stderr)=$handle->cmd($sudo.'adduser -r -m -g www-data www-data');
   $handle->{_cmd_handle}->print($sudo.'passwd www-data');
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   $prompt=~s/\$$//;
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'New password:') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         $output='';
         next;
      } elsif (-1<index $output,'Retype new password:') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf /var/cache/yum',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'yum -y update','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'yum clean all','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'yum grouplist hidden',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'yum groups mark convert',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install cyrus-sasl-plain sendmail-cf m4 java java-devel',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'yum -y install yum-utils --enablerepo=extras','__display__');
   # https://www.unixmen.com/setup-your-own-youtube-clone-website-using-ampache/
   # http://opensourceeducation.net/clip-bucket-2-8-on-ubuntu-14-04-with-nginx-php5-fpm-on-digitalocean-vps/
   # https://mtlynch.io/ansible-role-ampache/
   # https://www.vultr.com/docs/install-ampache-and-nginx-on-centos-7  posted Apr 13, 2018
   my $install_ampache=<<'END';

           o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
           8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
           8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
           8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
           8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
           8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
           ........................................................
           ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                             https://ampache.org/

                       __  __ _____        _____ _    _ ______
                 /\   |  \/  |  __ \ /\   / ____| |  | |  ____|
                /  \  | \  / | |__) /  \ | |    | |__| | |__
               / /\ \ | |\/| |  ___/ /\ \| |    |  __  |  __|
              / ____ \| |  | | |  / ____ \ |____| |  | | |____
             /_/    \_\_|  |_|_| /_/    \_\_____|_|  |_|______|


          (AMPACHE is **NOT** a sponsor of the FullAuto© Project.)

END
   print $install_ampache;sleep 10;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install openssl-devel libcurl-devel libpng-devel '.
      'icu libicu-devel rubygems-devel libxml2-devel libevent-devel '.
      'ImageMagick ImageMagick-devel ImageMagick-perl',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "yum -y groupinstall 'Development tools'",'__display__');
   # https://shaunfreeman.name/compiling-php-7-on-centos/
   # https://www.vultr.com/docs/how-to-install-php-7-x-on-centos-7
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ls -1 /opt/source/mariadb','__display__');
   if ($stdout=~/[Mm]aria[Dd][Bb].*rpm/) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /opt/mariadb','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/mariadb');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -fv *rpm /opt/mariadb','__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf /opt/source',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /opt/source',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod -Rv 777 /opt/source',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
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
my $b=1;
if ($b==1) {
   #if ($b==1) {
   if (-1==index `php -v`,'PHP') {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cmake --version','__display__');
      $stdout=~s/^.*?\s(\d+\.\d+).*$/$1/;
      $stdout||=0;
      if (!(-e '/usr/local/bin/cmake') && $stdout<3.02) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/Kitware/CMake.git',
            '__display__');
         ($stdout,$stderr)=$handle->cwd('cmake');
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
         'cp -v libzip.pc /usr/lib64/pkgconfig','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ../xcode/zipconf.h /usr/local/include','__display__');
      ($stdout,$stderr)=$handle->cmd(
         "echo -e /usr/local/lib64 | ${sudo}tee -a /etc/ld.so.conf",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ldconfig -v','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/jedisct1/libsodium',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('libsodium');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git checkout -b remotes/origin/stable',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './autogen.sh','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/php/php-src.git',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('php-src');
      # https://ampache.com/cb-install-requirements/
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git checkout php-7.0.27','__display__');
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
         #'--with-sodium '.
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
         #'--with-libzip=/opt/source/libzip '.
         '--with-zlib','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make -j2','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php7/etc/conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./php.ini-production /usr/local/php7/etc/php.ini',
         '__display__');
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
         '/usr/local/php7/etc/php-fpm.d/www.conf',
         '__display__');
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
         "sed -i 's/\;clear_env/clear_env/' ".
         '/usr/local/php7/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/\;env.PATH./env[PATH]/' ".
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
ExecStart=/usr/local/php7/sbin/php-fpm --nodaemonize --fpm-config /usr/local/php7/etc/php-fpm.conf
ExecReload=/bin/kill -USR2 \\x24MAINPID

[Install]
WantedBy=multi-user.target
END
      ($stdout,$stderr)=$handle->cwd("~");
      ($stdout,$stderr)=$handle->cmd("echo -e \"$fpmsrv\" > ".
         'php-fpm.service');
      ($stdout,$stderr)=$handle->cmd($sudo.'mv -fv php-fpm.service '.
         '/usr/lib/systemd/system');
      ($stdout,$stderr)=$handle->cwd("/opt/source");
      ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /run/php-fpm',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chkconfig --levels 235 php-fpm on');
      ($stdout,$stderr)=$handle->cmd($sudo.'service php-fpm start',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/usr/local/php7/bin/pecl channel-update pecl.php.net',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/usr/local/php7/bin/pecl install mailparse-3.0.2',
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://dl.fedoraproject.org/pub/epel/'.
      'epel-release-latest-7.noarch.rpm','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum install -y epel-release-latest-7.noarch.rpm',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rm -rf epel-release-latest-7.noarch.rpm','__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'yum -y install epel-release',
   #   '__display__');
   ($stdout,$stderr)=$handle->cwd('/etc/yum.repos.d');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://www.nasm.us/nasm.repo','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y --disablerepo=amzn2-core '.
      'install nasm','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install autoconf automake gcc gcc-c++ '.
      'git libtool make pkgconfig wget opencv zlib-devel dbus-devel '.
      'lua-devel zvbi libdvdread-devel libdc1394-devel libxcb-devel '.
      'xcb-util-devel libxml2-devel mesa-libGLU-devel pulseaudio-libs-devel '.
      'alsa-lib-devel libgcrypt-devel qt-devel re2c lshw','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'yum -y --skip-broken --enablerepo=epel '.
      'install yasm libva-devel libass-devel libkate-devel libbluray-devel '.
      'libdvdnav-devel libcddb-devel libmodplug-devel','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'yum -y install '.
      'a52dec-devel libmpeg2-devel','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'export PATH=/usr/local/bin/:$PATH;which ffmpeg');
   if ($stdout!~/\/ffmpeg/) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -pv /opt/source/ffmpeg','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone git://git.videolan.org/x264','__display__');
      ($stdout,$stderr)=$handle->cwd('x264');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'cp -v x264.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('fdk-aac');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'autoreconf -fiv','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v fdk-aac.pc /usr/lib64/pkgconfig','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      my $lame_tar='lame-3.100.tar.gz';
      my $lame_md5='83e260acbe4389b54fe08e0bdbf7cddb';
      foreach my $count (1..3) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'wget --random-wait --progress=dot '.
            'https://downloads.sourceforge.net/project/lame/lame/3.100/'.
            $lame_tar,'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "md5sum -c - <<<\"$lame_md5 $lame_tar\"",
            '__display__');
         unless ($stderr) {
            print(qq{ + CHECKSUM Test for $lame_tar *PASSED* \n});
            last
         } elsif ($count>=3) {
            print "FATAL ERROR! : CHECKSUM Test for $lame_tar *FAILED* ",
                  "after $count attempts\n";
            &Net::FullAuto::FA_Core::cleanup;
         }
         ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf $lame_tar",'__display__');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xzvf $lame_tar",'__display__');
      $lame_tar=~s/\.tar\.gz$//;
      ($stdout,$stderr)=$handle->cwd($lame_tar);
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared --enable-nasm');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      my $libogg_tar='libogg-1.3.3.tar.gz';
      my $libogg_md5='1eda7efc22a97d08af98265107d65f95';
      foreach my $count (1..3) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'wget --random-wait --progress=dot '.
            'http://downloads.xiph.org/releases/ogg/'.
            $libogg_tar,'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "md5sum -c - <<<\"$libogg_md5 $libogg_tar\"",
            '__display__');
         unless ($stderr) {
            print(qq{ + CHECKSUM Test for $libogg_tar *PASSED* \n});
            last
         } elsif ($count>=3) {
            print "FATAL ERROR! : CHECKSUM Test for $libogg_tar *FAILED* ",
                  "after $count attempts\n";
            &Net::FullAuto::FA_Core::cleanup;
         }
         ($stdout,$stderr)=$handle->cmd($sudo.'rm -rvf '.$libogg_tar,'__display__');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xzvf $libogg_tar",'__display__');
      $libogg_tar=~s/\.tar\.gz$//;
      ($stdout,$stderr)=$handle->cwd($libogg_tar);
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'cp -v ogg.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      my $libtheora_tar='libtheora-1.1.1.tar.gz';
      my $libtheora_md5='bb4dc37f0dc97db98333e7160bfbb52b';
      foreach my $count (1..3) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'wget --random-wait --progress=dot '.
            'http://downloads.xiph.org/releases/theora/'.
            $libtheora_tar,'__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "md5sum -c - <<<\"$libtheora_md5 $libtheora_tar\"",
            '__display__');
         unless ($stderr) {
            print(qq{ + CHECKSUM Test for $libtheora_tar *PASSED* \n});
            last
         } elsif ($count>=3) {
            print "FATAL ERROR! : CHECKSUM Test for $libtheora_tar *FAILED* ",
                  "after $count attempts\n";
            &Net::FullAuto::FA_Core::cleanup;
         }
         ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf $libtheora_tar",
            '__display__');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xzvf $libtheora_tar",'__display__');
      $libtheora_tar=~s/\.tar\.gz$//;
      ($stdout,$stderr)=$handle->cwd($libtheora_tar);
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget -qO- https://www.libsdl.org/download-2.0.php');
      $stdout=~s/^.*href=["](.*?[.]tar[.]gz[.]sig)["].*$/$1/s;
      my $sdl_tar=$stdout;
      $sdl_tar=~s/^(.*)[.]sig$/$1/;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "mkdir -pv release",'__display__');
      my $goodsig=0;
      foreach my $count (1..3) {
         ($stdout,$stderr)=$handle->cwd('release');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'wget --random-wait --progress=dot '.
            "https://www.libsdl.org/$sdl_tar",
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'wget --random-wait --progress=dot '.
            "https://www.libsdl.org/$sdl_tar.sig",
            '__display__');
         ($stdout,$stderr)=$handle->cwd("-");
         ($stdout,$stderr)=$handle->cmd(
            "gpg --verify-files ./$sdl_tar.sig",
            '__display__');
         if ($stderr=~/No public key/) {
            $stderr=~s/^.*DSA key ID ([A-Z0-9]+)\s+.*$/$1/s;
            ($stdout,$stderr)=$handle->cmd(
               "gpg --keyserver keys.gnupg.net --recv-keys $stderr",
               '__display__');
            ($stdout,$stderr)=$handle->cmd(
               "gpg --verify-files ./$sdl_tar.sig",
               '__display__');
         }
         if (-1<index $stderr, 'Good signature') {
            ($stdout,$stderr)=$handle->cmd($sudo.
               "rm -rvf $sdl_tar.sig",'__display__');
            $goodsig=1;
            last;
         }
      }
      exit_on_error($stderr." in package ".__PACKAGE__.
         " line ".__LINE__."\n")
         if !$goodsig;
      ($stdout,$stderr)=$handle->cwd('release');
      ($stdout,$stderr)=$handle->cmd($sudo.'tar zxvf *','__display__');
      ($stdout,$stderr)=$handle->cwd('SDL2*');
      ($stdout,$stderr)=$handle->cmd($sudo.'./configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'cp -v sdl2.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      my $libvorbis_tar='libvorbis-1.3.6.tar.gz';
      my $libvorbis_md5='d3190649b26572d44cd1e4f553943b31';
      foreach my $count (1..3) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'wget --random-wait --progress=dot '.
            'http://downloads.xiph.org/releases/vorbis/'.
            $libvorbis_tar,'__display__');
         ($stdout,$stderr)=$handle->cmd(
            "sudo md5sum -c - <<<\"$libvorbis_md5 $libvorbis_tar\"",
            '__display__');
         unless ($stderr) {
            print(qq{ + CHECKSUM Test for $libvorbis_tar *PASSED* \n});
            last
         } elsif ($count>=3) {
            print "FATAL ERROR! : CHECKSUM Test for $libvorbis_tar *FAILED* ",
                  "after $count attempts\n";
            &Net::FullAuto::FA_Core::cleanup;
         }
         ($stdout,$stderr)=$handle->cmd($sudo.
            "rm -rvf $libvorbis_tar",
            '__display__');
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xzvf $libvorbis_tar",'__display__');
      $libvorbis_tar=~s/\.tar\.gz$//;
      ($stdout,$stderr)=$handle->cwd($libvorbis_tar);
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'cp -v vorbis.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'cp -v vorbisenc.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'cp -v vorbisfile.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://chromium.googlesource.com/webm/libvpx',
         '__display__');
      ($stdout,$stderr)=$handle->cwd('libvpx');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-shared','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      my $libmad_tar='libmad-0.15.1b.tar.gz';
      $goodsig=0;
      foreach my $count (1..3) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            "wget --random-wait --progress=dot ".
            "ftp://ftp.mars.org/pub/mpeg/".$libmad_tar,
            '__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            "wget --random-wait --progress=dot ".
            "ftp://ftp.mars.org/pub/mpeg/$libmad_tar.sign",
            '__display__');
         ($stdout,$stderr)=$handle->cwd("-");
         ($stdout,$stderr)=$handle->cmd(
            "gpg --verify-files ./$libmad_tar.sign",
            '__display__');
         if ($stderr=~/No public key/) {
            $stderr=~s/^.*DSA key ID ([A-Z0-9]+)\s+.*$/$1/s;
            ($stdout,$stderr)=$handle->cmd(
               "gpg --keyserver keys.gnupg.net --recv-keys $stderr",
               '__display__');
            ($stdout,$stderr)=$handle->cmd(
               "gpg --verify-files ./$libmad_tar.sign",
               '__display__');
         }
         if (-1<index $stderr, 'Good signature') {
            ($stdout,$stderr)=$handle->cmd(
               "sudo rm -rvf $libmad_tar.sign",'__display__');
            $goodsig=1;
            last;
         }
      }
      exit_on_error($stderr." in package ".__PACKAGE__.
         " line ".__LINE__."\n")
         if !$goodsig;
      ($stdout,$stderr)=$handle->cmd($sudo.'tar zxvf '.$libmad_tar,'__display__');
      ($stdout,$stderr)=$handle->cwd("libmad-0.15.1b");
      ($stdout,$stderr)=$handle->cmd($sudo.'./configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo."sed -i 's/-fforce-mem //' ".
         "Makefile");
      ($stdout,$stderr)=$handle->cmd($sudo.'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone git://source.ffmpeg.org/ffmpeg','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git checkout remotes/origin/release/2.8','__display__');
      ($stdout,$stderr)=$handle->cwd('ffmpeg');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --enable-gpl --enable-libfdk_aac --enable-libmp3lame '.
         '--enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 '.
         '--enable-nonfree --disable-static --enable-shared','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make',300,'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install',300,'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "/\/usr\/local\/lib$/d" /etc/ld.so.conf');
      ($stdout,$stderr)=$handle->cmd_raw($sudo.
         'sed -i "\\$a/usr/local/lib" /etc/ld.so.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.'ldconfig');
   } 
   ($stdout,$stderr)=$handle->cwd('/opt/source/');
   # svn checkout svn://svn.mplayerhq.hu/mplayer/trunk mplayer  open port 3690
   ($stdout,$stderr)=$handle->cmd($sudo.
      'export PATH=/usr/local/bin/:$PATH;which flvtool2');
   if ($stdout!~/\/FLV/) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         "gem install flvtool2",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install freetype-devel freeglut-devel',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'export PATH=/usr/local/bin/:$PATH;which mediainfo');
   if ($stdout!~/\/mediainfo/) {
      my $mediainfo_tar='MediaInfo_CLI_18.08.1_GNU_FromSource.tar.xz';
      ($stdout,$stderr)=$handle->cmd($sudo.
         "wget --random-wait --progress=dot ".
         "https://mediaarea.net/download/binary/mediainfo/18.08.1/".
         $mediainfo_tar,300,
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf $mediainfo_tar",'__display__');
      ($stdout,$stderr)=$handle->cwd('MediaInfo_CLI_GNU_FromSource');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './CLI_Compile.sh','__display__');
      ($stdout,$stderr)=$handle->cwd('MediaInfo/Project/GNU/CLI');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/bin/mediainfo /usr/bin/mediainfo');
      ($stdout,$stderr)=$handle->cwd('/opt/source/');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'export PATH=/usr/local/bin/:$PATH;which MP4Box');
   if ($stdout!~/\/MP4Box/) {
      my $c='wget -qO- https://api.github.com/users/gpac/repos';
      ($stdout,$stderr)=$local->cmd($c);
      my @repos=();
      @repos=decode_json($stdout);
      my $default_branch=$repos[0]->[1]->{'default_branch'};
      my $updated=$repos[0]->[1]->{'updated_at'};
      my @branches=();
      $c='wget -qO- https://api.github.com/repos/gpac/gpac/branches';
      ($stdout,$stderr)=$local->cmd($c);
      @branches=decode_json($stdout);
      my @builds=();
      $updated=~s/^(.*)T.*$/$1/;
      my $scrollnum=0;my $count=0;
      foreach my $branch (@{$branches[0]}) {
         $count++;
         #print "BRANCH NAME=",$branch->{name},"\n";
         push @builds,$branch->{name};
         if ($default_branch eq $branch->{name}) {
            $scrollnum=$count;
         }
      }
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git clone -v -b $default_branch git://github.com/gpac/gpac",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git ls-remote --tags git://github.com/gpac/gpac",
         '__display__');
      my %tags=();
      foreach my $line (split /\n/, $stdout) {
         my ($string,$tag)=('','');
         ($string,$tag)=split /refs\/tags\//, $line;
         $tags{$tag}=$string;
      }
      ($stdout,$stderr)=$handle->cwd('gpac');
      my $tag=(reverse sort keys %tags)[0];
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout tags/$tag",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -l','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i \'s#-lgpac$#-lgpac -Wl,-rpath=/usr/local/lib#\' '.
         'applications/mp4box/Makefile');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v gpac.pc /usr/lib64/pkgconfig','__display__');
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php7/bin/pecl config-set php_ini '.
      '/usr/local/php7/etc/php.ini',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php7/bin/pear config-set php_ini '.
      '/usr/local/php7/etc/php.ini',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      '-O imagick.tgz https://pecl.php.net/get/imagick'
      ,300,'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'tar -xvf imagick.tgz','__display__');
   ($stdout,$stderr)=$handle->cwd('imagick-*');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php7/bin/phpize','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      './configure --with-php-config=/usr/local/php7/bin/php-config',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   $stdout=~s/^.*extensions:\s+(.*?)\s.*$/$1/s;
   my $img_ext=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 755 $img_ext/*','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd(
      "yes '' | sudo /usr/local/php7/bin/pear install mail",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "yes '' | sudo /usr/local/php7/bin/pear install Net_SMTP",
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   my $im=<<END;
; Enable imagick extension module
extension=${img_ext}imagick.so
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$im\" > imagick.ini");
   # use  php -i | grep ini  to check location of ini files
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv imagick.ini /usr/local/php7/etc/conf.d','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp phpshield','__display__');
   ($stdout,$stderr)=$handle->cwd('phpshield');
   # https://linuxflow.blogspot.com/2017/05/ampache-installation.html
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://www.sourceguardian.com/loaders/download/'.
      'loaders.linux-x86_64.zip',300,'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'unzip loaders.linux-x86_64.zip','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v ixed.7.0.lin $img_ext",'__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   # https://forum.likg.org.ua/server-side-actions/
   # install-phpshield-sourceguardian-php-encoders-t306.html
   my $zd=<<END;
; Enable phpshield extension module
extension=${img_ext}ixed.7.0.lin
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$zd\" > phpshield.ini");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -fv phpshield.ini /usr/local/php7/etc/conf.d",'__display__');
}
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.'which mysql');
   my $msstatus='';my $msversion='';
   if ($stdout=~/\/mysql/) {
      ($msversion,$stderr)=$handle->cmd($sudo.
         'mysql --version','__display__');
      $msversion=~s/^mysql\s+Ver\s+(.*?)\s+Distrib.*$/$1/;
      ($msstatus,$stderr)=$handle->cmd($sudo.
         'sudo service mysql status','__display__');
   }
   if ($msversion<15.1 || $msstatus!~/SUCCESS/) {
   #my $u=1;
   #if ($u==1) {
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
      ($stdout,$stderr)=$handle->cwd('..');
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
         'chmod -v 755 /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chgrp -v mysql /var/lib/mysql','__display__');
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
      ($stdout,$stderr)=$handle->cmd($sudo.
         "echo -e \"$toku_cnf\" > /opt/source/tokudb.cnf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v /opt/source/tokudb.cnf /etc/my.cnf.d/tokudb.cnf',
         '__display__');
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   'rm -rvf /opt/source/tokudb.cnf','__display__');
      # https://github.com/ampache/ampache/issues/429
      my $sql_mode_cnf=<<END;
[mysqld]
sql_mode=IGNORE_SPACE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
END
      ($stdout,$stderr)=$handle->cmd($sudo.
         "echo -e \"$sql_mode_cnf\" > /opt/source/sql_mode.cnf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v /opt/source/sql_mode.cnf /etc/my.cnf.d/sql_mode.cnf',
         '__display__');
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   'rm -rvf /opt/source/sql_mode.cnf','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql start','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 711 /var/lib/mysql/mysql','__display__');
      print "MYSQL START STDOUT=$stdout and STDERR=$stderr<==\n";sleep 5;
      print "\n\n\n\n\n\n\nWE SHOULD HAVE INSTALLED MARIADB=$stdout<==\n\n\n\n\n\n\n";
      sleep 5;
   }
   ($stdout,$stderr)=$handle->cmd("uname -a");
   if ($stdout=~/Ubuntu/i) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'apt-get -y install git-all','__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y -v install git-all','__display__');
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source/');
   #https://community.letsencrypt.org/t/help-with-certbot-on-the-new-amazon-linux-2/49399/7
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
      'git clone https://github.com/ampache/ampache.git','__display__');
   ($stdout,$stderr)=$handle->cwd("ampache");
   ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /var/www/html',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'chmod 777 /var','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -Rv . /var/www/html/ampache','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -Rv 775 /var/www','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv www-data:www-data /var/www','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://getcomposer.org/composer.phar','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v composer.phar /usr/local/bin/composer','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/composer '.
      'install --prefer-source --no-interaction','__display__');
   my $fa_builddir=fullauto_builddir($local,$sudo);
   my $ignore='';
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.'wget -qO- https://icanhazip.com');
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
   if ($public_ip && $permanent_ip) {
      my $c="aws ec2 describe-instances";
      my ($hash,$output,$error)=run_aws_cmd($c);
      $hash||={};
      $c="aws ec2 describe-addresses";
      my ($hasha,$outputa,$errora)=run_aws_cmd($c);
      $hasha||={};$hasha->{Addresses}||=[];
      my $a_id='';
      foreach my $address (@{$hasha->{Addresses}}) {
         if ($permanent_ip eq $address->{PublicIp}) {
            $a_id=$address->{AllocationId};
            last;
         }
      }
      my %pubip=();my $instance_id='';
      foreach my $res (@{$hash->{Reservations}}) {
         foreach my $inst (@{$res->{Instances}}) {
            my $pip=$inst->{PublicIpAddress}||'';
            my $iid=$inst->{InstanceId}||'';
            next if exists $inst->{State}->{Name} &&
               $inst->{State}->{Name} eq 'terminated';
            if ($public_ip eq $pip) {
               my $c="aws ec2 associate-address --instance-id ".
                     $inst->{InstanceId}." --allocation-id $a_id ".
                     "--allow-reassociation";
               my ($hasha,$outputa,$errora)=run_aws_cmd($c);
               $public_ip=$permanent_ip;
               last;
            }
         }
      } 
   }
   $public_ip='localhost' unless $public_ip;
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # https://www.sitepoint.com/setting-up-php-behind-nginx-with-fastcgi/
   # http://codingsteps.com/install-php-fpm-nginx-mysql-on-ec2-with-amazon-linux-ami/
   # http://code.tutsplus.com/tutorials/revisiting-open-source-social-networking-installing-gnu-social--cms-22456
   # https://wiki.loadaverage.org/ampache/installation_guides/install_like_loadaverage
   # https://karp.id.au/social/index.html
   # http://jeffreifman.com/how-to-install-your-own-private-e-mail-server-in-the-amazon-cloud-aws/
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rm -rvf /usr/local/nginx','__display__');
   my $nginx='nginx-1.14.0'; # updated from 1.10.0
   $nginx='nginx-1.9.13' if $^O eq 'cygwin';
   ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
      "http://nginx.org/download/$nginx.tar.gz",300,'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo tar xvf $nginx.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd($nginx);
   ($stdout,$stderr)=$handle->cmd("sudo mkdir -vp objs/lib",'__display__');
   ($stdout,$stderr)=$handle->cwd("objs/lib");
   my $pcre='pcre-8.40';
   my $checksum='';
   foreach my $cnt (1..3) {
      ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
         "ftp://ftp.csx.cam.ac.uk/pub/software/".
         "programming/pcre/$pcre.tar.gz",'__display__');
      ($stdout,$stderr)=$handle->cmd("sudo tar xvf $pcre.tar.gz",'__display__');
      last unless $stderr;
      ($stdout,$stderr)=$handle->cmd("sudo rm -rfv $pcre.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo wget -qO- http://zlib.net/index.html");
   my $zlib_ver=$stdout;
   my $sha__256=$stdout;
   $zlib_ver=~s/^.*? source code, version (\d+\.\d+\.\d+).*$/$1/s;
   $sha__256=~s/^.*?SHA-256 hash [<]tt[>](.*?)[<][\/]tt[>].*$/$1/s;
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
         "http://zlib.net/zlib-$zlib_ver.tar.gz",'__display__');
      $checksum=$sha__256;
      ($stdout,$stderr)=$handle->cmd(
         "sudo sha256sum -c - <<<\"$checksum zlib-$zlib_ver.tar.gz\"",
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
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf zlib-$zlib_ver.tar.gz",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo tar xvf zlib-$zlib_ver.tar.gz",
      '__display__');
   my $ossl='openssl-1.0.2h';
   foreach my $count (1..3) {
      $checksum='577585f5f5d299c44dd3c993d3c0ac7a219e4949';
      ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
         "https://www.openssl.org/source/$ossl.tar.gz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo sha1sum -c - <<<\"$checksum $ossl.tar.gz\"",'__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $ossl *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $ossl.tar.gz *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $ossl.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo tar xvf $ossl.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd("../..");
   my $make_nginx=$sudo.'./configure --sbin-path=/usr/local/nginx/nginx '.
                  '--conf-path=/usr/local/nginx/nginx.conf '.
                  '--pid-path=/usr/local/nginx/nginx.pid '.
                  "--with-http_ssl_module --with-pcre=objs/lib/$pcre ".
                  "--with-zlib=objs/lib/zlib-$zlib_ver";
   ($stdout,$stderr)=$handle->cmd($make_nginx,'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i 's/-Werror //' ./objs/Makefile");
   ($stdout,$stderr)=$handle->cmd("${sudo}make install",'__display__');

   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/

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

   my $nginx_conf=<<END;
user www-data;
worker_processes auto;
pid /var/run/nginx.pid;
include /etc/nginx/modules-enabled/\\x2A.conf;

events {
        worker_connections 1024;
        # multi_accept on;
}

http {

        ##
        # Basic Settings
        ##

        sendfile on;
        tcp_nopush on;
        tcp_nodelay on;
        keepalive_timeout 65;
        types_hash_max_size 2048;
        # server_tokens off;

        # server_names_hash_bucket_size 64;
        # server_name_in_redirect off;

        include /usr/local/nginx/mime.types;
        default_type application/octet-stream;

        ##
        # SSL Settings
        ##

        #ssl_protocols TLSv1 TLSv1.1 TLSv1.2; # Dropping SSLv3, ref: POODLE
        #ssl_prefer_server_ciphers on;

        ##
        # Logging Settings
        ##

        #access_log /var/log/nginx/access.log;
        #error_log /var/log/nginx/error.log;

        ##
        # Gzip Settings
        ##

        gzip on;
        gzip_disable \\x22msie6\\x22;

        # gzip_vary on;
        # gzip_proxied any;
        # gzip_comp_level 6;
        # gzip_buffers 16 8k;
        # gzip_http_version 1.1;
        # gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;


        server {

            # listen to
            # listen  [::]:used_port; #ssl; ipv6 optional with ssl enabled
            listen       80; #ssl; ipv4 optional with ssl enabled

            server_name $public_ip;
            charset utf-8;

            # Logging, error_log mode [notice] is necessary for rewrite_log on,
            # (very usefull if rewrite rules do not work as expected)

                error_log       /var/log/ampache/error.log; # notice;
              # access_log      /var/log/ampache/access.log;
              # rewrite_log     on;

            # Use secure SSL/TLS settings, see https://mozilla.github.io/server-side-tls/ssl-config-generator/
            # ssl_protocols TLSv1.2;
            # ssl_ciphers 'ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-E    CDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA256';
            # ssl_prefer_server_ciphers on;
            # add_header Strict-Transport-Security max-age=15768000;
            # etc.

            # Use secure headers to avoid XSS and many other things
            add_header X-Content-Type-Options nosniff;
            add_header X-XSS-Protection \\x221; mode=block\\x22;
            add_header X-Robots-Tag none;
            add_header X-Download-Options noopen;
            add_header X-Permitted-Cross-Domain-Policies none;
            add_header X-Frame-Options \\x22SAMEORIGIN\\x22 always;
            add_header Referrer-Policy \\x22no-referrer\\x22;
            add_header Content-Security-Policy \\x22script-src 'self' 'unsafe-inline' 'unsafe-eval'; frame-src 'self'; object-src 'self'\\x22;

            # Avoid information leak
            server_tokens off;
            fastcgi_hide_header X-Powered-By;

            root /var/www/html/ampache;
            index index.php;

            # Somebody said this helps, in my setup it doesn't prevent temporary saving in files
            proxy_max_temp_file_size 0;

            # Rewrite rule for Subsonic backend
            if ( \\x21-d \\x24request_filename ) {
               rewrite ^/rest/(.\\x2A).view\\x24 /rest/index.php?action=\\x241 last;
               rewrite ^/rest/fake/(.+)\\x24 /play/\\x241 last;
            }

            # Rewrite rule for Channels
            if (\\x21-d \\x24request_filename){
               rewrite ^/channel/([0-9]+)/(.\\x2A)\\x24 /channel/index.php?channel=\\x241&target=\\x242 last;
            }

            # Beautiful URL Rewriting
               rewrite ^/play/ssid/(\\w+)/type/(\\w+)/oid/([0-9]+)/uid/([0-9]+)/name/(.\\x2A)\\x24 /play/index.php?ssid=\\x241&type=\\x242&oid=\\x243&uid=\\x244&name=\\x245 last;
               rewrite ^/play/ssid/(\\w+)/type/(\\w+)/oid/([0-9]+)/uid/([0-9]+)/client/(.\\x2A)/noscrobble/([0-1])/name/(.\\x2A)\\x24 /play/index.php?ssid=\\x241&type=\\x242&oid=\\x243&uid=\\x244&client=\\x245&noscrobble=\\x246&name=\\x247 last;
               rewrite ^/play/ssid/(.\\x2A)/type/(.\\x2A)/oid/([0-9]+)/uid/([0-9]+)/client/(.\\x2A)/noscrobble/([0-1])/player/(.\\x2A)/name/(.\\x2A)\\x24 /play/index.php?ssid=\\x241&type=\\x242&oid=\\x243&uid=\\x244&client=\\x245&noscrobble=\\x246&player=\\x247&name=\\x248 last;
               rewrite ^/play/ssid/(.\\x2A)/type/(.\\x2A)/oid/([0-9]+)/uid/([0-9]+)/client/(.\\x2A)/noscrobble/([0-1])/bitrate/([0-9]+)/player/(.\\x2A)/name/(.\\x2A)\\x24 /play/index.php?ssid=\\x241&type=\\x242&oid=\\x243&uid=\\x244&client=\\x245&noscrobble=\\x246&bitrate=\\x247player=\\x248&name=\\x249 last;
               rewrite ^/play/ssid/(.\\x2A)/type/(.\\x2A)/oid/([0-9]+)/uid/([0-9]+)/client/(.\\x2A)/noscrobble/([0-1])/transcode_to/(w+)/bitrate/([0-9]+)/player/(.\\x2A)/name/(.\\x2A)\\x24 /play/index.php?ssid=\\x241&type=\\x242&oid=\\x243&uid=\\x244&client=\\x245&noscrobble=\\x246&transcode_to=\\x247&bitrate=\\x248&player=\\x249&name=\\x2410 last;

            # the following line was needed for me to get downloads of single songs to work
               rewrite ^/play/ssid/(.\\x2A)/type/(.\\x2A)/oid/([0-9]+)/uid/([0-9]+)/action/(.\\x2A)/name/(.\\x2A)\\x24 /play/index.php?ssid=\\x241&type=\\x242&oid=\\x243&uid=\\x244action=\\x245&name=\\x246 last;
            location /play {
                if (\\x21-e \\x24request_filename) {
                   rewrite ^/play/art/([^/]+)/([^/]+)/([0-9]+)/thumb([0-9]\\x2A)\.([a-z]+)\\x24 /image.php?object_type=\\x242&object_id=\\x243&auth=\\x241 last;
                }

                rewrite ^/([^/]+)/([^/]+)(/.\\x2A)?\\x24 /play/\\x243?\\x241=\\x242;
                rewrite ^/(/[^/]+|[^/]+/|/?)\\x24 /play/index.php last;
                break;
            }

            location /rest {
                limit_except GET POST {
                   deny all;
                }
            }

            location ^~ /bin/ {
                deny all;
                return 403;
            }

            location ^~ /config/ {
                deny all;
                return 403;
            }

            location / {
                limit_except GET POST HEAD{
                   deny all;
                }
            }

            location ~ ^/.\\x2A.php {
                fastcgi_index index.php;

                # sets the timeout for requests in [s] , 60s are normally enough
                   fastcgi_read_timeout 600s;

                include fastcgi_params;
                fastcgi_param SCRIPT_FILENAME \\x24document_root\\x24fastcgi_script_name;

                # Mitigate HTTPOXY https://httpoxy.org/
                   fastcgi_param HTTP_PROXY \\x22\\x22;

                # has to be set to on if encryption (https) is used:
                   # fastcgi_param HTTPS on;

                fastcgi_split_path_info ^(.+?\\x5C.php)(/.\\x2A)\\x24;

                # chose as your php-fpm is configured to listen on
                   fastcgi_pass unix:/var/run/php-fpm/php7.0-fpm.sock;
                   # fastcgi_pass 127.0.0.1:8000/;
            }

            # Rewrite rule for WebSocket
            location /ws {
                rewrite ^/ws/(.\\x2A) /\\x241 break;
                proxy_http_version 1.1;
                proxy_set_header Upgrade \\x24http_upgrade;
                proxy_set_header Connection \\x22upgrade\\x22;
                proxy_set_header Host \\x24host;
                proxy_pass http://127.0.0.1:8100/;
            }
        }

}
END

   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$nginx_conf\" > /usr/local/nginx/nginx.conf");

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
   my $nginx_start_stop=<<END;
#\\x21/bin/sh
#
# nginx - this script starts and stops the nginx daemin
#
# chkconfig:   - 85 15
# description:  Nginx is an HTTP(S) server, HTTP(S) reverse #               proxy and IMAP/POP3 proxy server
# processname: nginx
# config:      /usr/local/nginx/nginx.conf
# pidfile:     /var/run/nginx.pid
# user:        www-data

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

# Check that networking is up.
[ \\x22\\x24NETWORKING\\x22 = \\x22no\\x22 ] && exit 0

nginx=\\x22/usr/local/nginx/nginx\\x22
prog=\\x24(basename \\x24nginx)

NGINX_CONF_FILE=\\x22/usr/local/nginx/nginx.conf\\x22

lockfile=/usr/local/nginx/nginx.lock

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
    \\x2A)
        echo \\x24\\x22Usage: \\x240 {start|stop|status|restart|condrestart|try-restart|reload|force-reload|configtest}\\x22
        exit 2
esac
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$nginx_start_stop\" > /opt/source/nginx");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v /opt/source/nginx /etc/init.d','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 755 /etc/init.d/nginx','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl daemon-reload','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service nginx start','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i 's|^plugin-load-add=auth_gssapi.so|".
      "#plugin-load-add=auth_gssapi.so|' ".
      '/etc/my.cnf.d/auth_gssapi.cnf');
   # HOW TO CHECK MYSQL FOR ERRORS
   # mkdir /var/run/mysqld/
   # chown mysql: /var/run/mysqld/
   # mysqld --basedir=/usr --datadir=/var/lib/mysql
   # --user=mysql --socket=/var/run/mysqld/mysqld.sock
   $handle->{_cmd_handle}->print($sudo.'mysql_secure_installation');
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'root (enter for none):') {
         $handle->{_cmd_handle}->print();
         next;
      } elsif (-1<index $output,'so you can safely answer \'n\'') {
         $handle->{_cmd_handle}->print('n');
         next;
      } elsif (-1<index $output,'Set root password? [Y/n]') {
         $handle->{_cmd_handle}->print('n');
         next;
      } elsif (-1<index $output,'Switch to unix_socket authentication [Y/n]') {
         $handle->{_cmd_handle}->print('n');
         next;
      } elsif (-1<index $output,'Change the root password? [Y/n]') {
         $handle->{_cmd_handle}->print('n');
         next;
      } elsif (-1<index $output,'Remove anonymous users? [Y/n]') {
         $handle->{_cmd_handle}->print('Y');
         next;
      } elsif (-1<index $output,'Disallow root login remotely? [Y/n]') {
         $handle->{_cmd_handle}->print('Y');
         next;
      } elsif (-1<index $output,
            'Remove test database and access to it? [Y/n]') {
         $handle->{_cmd_handle}->print('Y');
         next;
      } elsif (-1<index $output,'Reload privilege tables now? [Y/n]') {
         $handle->{_cmd_handle}->print('Y');
         next;
      }
   }
   $handle->cmd("echo");
   $handle->{_cmd_handle}->print($sudo.'mysql 2>&1');
   my $first_pass=0;
   my $second_pass=0;
   my $third_pass=0;
   my $fourth_pass=0;
   my $fifth_pass=0;
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/ && $first_pass;
      print $output;
      if (-1<index $output,'[(none)]>') {
         if (!$first_pass) {
            $handle->{_cmd_handle}->print(
               "ALTER USER \'root\'@\'localhost\' ".
               "IDENTIFIED BY \'$service_and_cert_password\';");
            $first_pass=1;
         } elsif (!$second_pass) {
            $handle->{_cmd_handle}->print('CREATE DATABASE ampache;');
            $second_pass=1;
         } elsif (!$third_pass) {
            $handle->{_cmd_handle}->print(
               'GRANT USAGE ON ampache.* TO ampache@localhost'.
               " IDENTIFIED BY \'$service_and_cert_password\';");
            $third_pass=1;
         } elsif (!$fourth_pass) {
            $handle->{_cmd_handle}->print(
               'GRANT ALL PRIVILEGES ON ampache.* TO ampache@localhost;');
            $fourth_pass=1;
         } elsif (!$fifth_pass) {
            $handle->{_cmd_handle}->print('flush privileges;');
            $fifth_pass=1;
         } else {
            $handle->{_cmd_handle}->print('exit;');
         }
      }
   }
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s#127.0.0.1:9000#/var/run/php-fpm/php7.0-fpm.sock#\' ".
      '/usr/local/php7/etc/php-fpm.d/www.conf');
   # https://serversforhackers.com/c/php-fpm-configuration-the-listen-directive
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/;listen.owner = nobody/listen.owner = www-data/\' ".
      '/usr/local/php7/etc/php-fpm.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/user = apache/user = www-data/\' ".
      '/usr/local/php7/etc/php-fpm.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/group = apache/group = www-data/\' ".
      '/usr/local/php7/etc/php-fpm.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/;listen.mode = 0660/listen.mode = 0664/\' ".
      '/usr/local/php7/etc/php-fpm.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chgrp -Rv www-data /usr/local/php7/include/php/ext/session",
      '__display__');
   #   '/var/lib/php/5.5/wsdlcache','__display__');
   ($stdout,$stderr)=$handle->cwd("/var/www/html/ampache");
   ($stdout,$stderr)=$handle->cmd("${sudo}chgrp -v www-data .");
   ($stdout,$stderr)=$handle->cmd("${sudo}chmod -v g+w .");
   ($stdout,$stderr)=$handle->cwd("/opt/source");
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
   my ($hash,$output,$error)=('','','');
   $c="aws iam list-access-keys --user-name ampache_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   foreach my $hash (@{$hash->{AccessKeyMetadata}}) {
      my $c="aws iam delete-access-key --access-key-id $hash->{AccessKeyId} ".
            "--user-name ampache_email";
      ($hash,$output,$error)=run_aws_cmd($c);
   }
   sleep 1;
   $c="aws iam delete-user --user-name ampache_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c="aws iam create-user --user-name ampache_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c="aws iam create-access-key --user-name ampache_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   my $access_id=$hash->{AccessKey}->{AccessKeyId};
   my $secret_access_key=$hash->{AccessKey}->{SecretAccessKey};
   my $java_smtp_generator=<<END;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.bind.DatatypeConverter;

public class SesSmtpCredentialGenerator {

       // From http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html

       private static final String KEY_ENV_VARIABLE = \\x22AWS_SECRET_ACCESS_KEY\\x22; // Put your AWS secret access key in this environment variable.
       private static final String MESSAGE = \\x22SendRawEmail\\x22; // Used to generate the HMAC signature. Do not modify.
       private static final byte VERSION =  0x02; // Version number. Do not modify.

       public static void main(String[] args) {
    	       	   	
              // Get the AWS secret access key from environment variable AWS_SECRET_ACCESS_KEY.
              String key = System.getenv(KEY_ENV_VARIABLE);         	  
              if (key == null)
              {
                 System.out.println(\\x22Error: Cannot find environment variable AWS_SECRET_ACCESS_KEY.\\x22);  
                 System.exit(0);
              }
   	    	       	   
              // Create an HMAC-SHA256 key from the raw bytes of the AWS secret access key.
              SecretKeySpec secretKey = new SecretKeySpec(key.getBytes(), \\x22HmacSHA256\\x22);

              try {         	  
                     // Get an HMAC-SHA256 Mac instance and initialize it with the AWS secret access key.
                     Mac mac = Mac.getInstance(\\x22HmacSHA256\\x22);
                     mac.init(secretKey);

                     // Compute the HMAC signature on the input data bytes.
                     byte[] rawSignature = mac.doFinal(MESSAGE.getBytes());

                     // Prepend the version number to the signature.
                     byte[] rawSignatureWithVersion = new byte[rawSignature.length + 1];               
                     byte[] versionArray = {VERSION};                
                     System.arraycopy(versionArray, 0, rawSignatureWithVersion, 0, 1);
                     System.arraycopy(rawSignature, 0, rawSignatureWithVersion, 1, rawSignature.length);

                     // To get the final SMTP password, convert the HMAC signature to base 64.
                     String smtpPassword = DatatypeConverter.printBase64Binary(rawSignatureWithVersion);       
                     System.out.println(smtpPassword);
              } 
              catch (Exception ex) {
                     System.out.println(\\x22Error generating SMTP password: \\x22 + ex.getMessage());
              }             
       }
}
END
   ($stdout,$stderr)=$handle->cwd("~");
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$java_smtp_generator\" > SesSmtpCredentialGenerator.java");
   ($stdout,$stderr)=$handle->cmd('javac SesSmtpCredentialGenerator.java');
   $handle->cmd_raw(
      "export AWS_SECRET_ACCESS_KEY=$secret_access_key");
   my $smtppass='';
   ($smtppass,$stderr)=$handle->cmd('java SesSmtpCredentialGenerator','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -fv SesSmtpCredentialGenerator.* /opt/source",'__display__');
   my $sespolicy=<<END;
{
   \\x22Version\\x22:\\x222012-10-17\\x22,
   \\x22Statement\\x22: [{
        \\x22Effect\\x22:\\x22Allow\\x22,
        \\x22Action\\x22:\\x22ses:SendRawEmail\\x22,
        \\x22Resource\\x22:\\x22*\\x22
}]}
END
   chop $sespolicy;
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$sespolicy\" > ./sespolicy");
   $c="aws iam list-policies";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   foreach my $policy (@{$hash->{Policies}}) {
      if ($policy->{PolicyName} eq 'sespolicy_ampache') {
         $c="aws iam detach-user-policy --user-name ampache_email ".
            "--policy-arn $policy->{Arn}";
         ($hash,$output,$error)=run_aws_cmd($c);
         $c="aws iam delete-policy --policy-arn $policy->{Arn}";
         ($hash,$output,$error)=run_aws_cmd($c);
         chomp($output);
         warn($output." in package ".__PACKAGE__.
            " line ".__LINE__."\n")
            if $output=~/error occurred/;
         next if $output=~/error occurred/;
         last;
      }
   }
   $c="aws iam create-policy --policy-name sespolicy_ampache ".
      "--policy-document file://sespolicy";
   ($hash,$output,$error)=run_aws_cmd($c);
   chomp $output;
   exit_on_error($output." in package ".__PACKAGE__.
      " line ".__LINE__."\n")
      if $output=~/error occurred/;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rm -rvf ~/sespolicy','__display__');
   ($stdout,$stderr)=$handle->cwd("/opt/source"); 
   my $policy_arn=$hash->{Policy}->{Arn};
   $c="aws iam attach-user-policy --user-name ampache_email ".
      "--policy-arn $policy_arn";
   ($hash,$output,$error)=run_aws_cmd($c);
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
   # https://www.toptal.com/php/getting-the-most-out-of-your-log-files-a-practical-guide
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'s|;error_log = syslog|error_log = '.
      '/usr/local/php7/var/log/php_error.log|\' '.
      '/usr/local/php7/etc/php.ini');
   ($stdout,$stderr)=$handle->cmd($sudo.'service php-fpm restart');
   # https://aaronsadler.uk/2016/june/26/mount-google-drive-on-headless-centos-7-server/
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install ocaml ocaml-camlp4-devel ocaml-ocamldoc',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install gmp-devel.x86_64',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install m4 fuse fuse-devel libcurl-devel libsqlite3x-devel zlib-devel',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install bubblewrap',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd(
      'git clone https://github.com/OCamlPro/opam.git','__display__');
   ($stdout,$stderr)=$handle->cwd('opam');
   ($stdout,$stderr)=$handle->cmd('make lib-ext','__display__');
   ($stdout,$stderr)=$handle->cmd('./configure','__display__');
   ($stdout,$stderr)=$handle->cmd('make lib-ext','__display__');
   ($stdout,$stderr)=$handle->cmd('make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('..');
   $handle->{_cmd_handle}->print('opam init');
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   $prompt=~s/\$$//;
   my $m=1;
   while ($m==1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'bash_profile? [N/y/f]') {
         $handle->{_cmd_handle}->print('y');
         $output='';
         next;
      } elsif (-1<index $output,'choose a different)') {
         $handle->{_cmd_handle}->print('y');
         $output='';
         next;
      } elsif (-1<index $output,' Set that up? [y/N]') {
         $handle->{_cmd_handle}->print('y');
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd(
      'opam update','__display__');
   print "\n\n   EXPECT *** LONG **** DELAY - up to 10 minutes ...\n\n";
   ($stdout,$stderr)=$handle->cmd(
      'opam switch create ocaml-base-compiler',600,'__display__');
   $handle->{_cmd_handle}->print('opam install google-drive-ocamlfuse');
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   $prompt=~s/\$$//;
   my $n=1;
   while ($n==1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'want to continue') {
         $handle->{_cmd_handle}->print('Y');
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /google-drive','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v ec2-user:ec2-user /google-drive','__display__');
   my $substitute_email_module='%NL%'.
'#####################################################%NL%'.
'# Inserted by FullAuto to handle Amazon SES passwords%NL%'.
'#####################################################%NL%%NL%'.
'require_once %SQ%Mail.php%SQ%;%NL%'.
'%NL%'.
'$headers = array (%NL%'.
'  %SQ%From%SQ% => $from,%NL%'.
'  %SQ%To%SQ% => $to,%NL%'.
'  %SQ%Subject%SQ% => $subject,%NL%'.
'  %SQ%MIME-Version%SQ% => "1.0",%NL%'.
'  %SQ%Content-Type%SQ% => "text/html; charset=iso-8859-1"%NL%'.
');%NL%'.
'%NL%'.
'$smtpParams = array (%NL%'.
'  %SQ%host%SQ% => $mail->Host,%NL%'.
'  %SQ%port%SQ% => $mail->Port,%NL%'.
'  %SQ%auth%SQ% => true,%NL%'.
'  %SQ%username%SQ% => $mail->Username,%NL%'.
'  %SQ%password%SQ% => $mail->Password%NL%'.
');%NL%'.
'%NL%'.
' // Create an SMTP client.%NL%'.
'$mail = Mail::factory(%SQ%smtp%SQ%, $smtpParams);%NL%'.
'%NL%'.
'// Send the email.%NL%'.
'$result = $mail->send($to, $headers, $message);%NL%'.
'%NL%'.
'#if (PEAR::isError($result)) {%NL%'.
'#  echo("Email not sent. " .$result->getMessage() ."\\n");%NL%'.
'#} else {%NL%'.
'#   echo("Email sent!"."\\n");%NL%'.
'#}%NL%%NL%'.
'####################################################%NL%'.
'# Commented Out by FullAuto so above sends all email%NL%'.
'####################################################%NL%';
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   use LWP::UserAgent;
   use HTTP::Request::Common;
   use IO::Socket::SSL qw();
   my $Browser = LWP::UserAgent->new(
      ssl_opts => {
         SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
         verify_hostname => 0,
      }
   );
   my $starting_ampache=<<'END';



     .oPYo. ooooo    .oo  .oPYo. ooooo o o    o .oPYo.      o    o  .oPYo.
     8        8     .P 8  8   `8   8   8 8b   8 8    8      8    8  8    8
     `Yooo.   8    .P  8  8YooP'   8   8 8`b  8 8           8    8  8YooP'
         `8   8   oPooo8  8   `b   8   8 8 `b 8 8   oo      8    8  8
          8   8  .P    8  8    8   8   8 8  `b8 8    8      8    8  8
     `YooP'   8 .P     8  8    8   8   8 8   `8 `YooP8      `YooP'  8
     ....................................................................
     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                             https://ampache.org/

                       __  __ _____        _____ _    _ ______
                 /\   |  \/  |  __ \ /\   / ____| |  | |  ____|
                /  \  | \  / | |__) /  \ | |    | |__| | |__
               / /\ \ | |\/| |  ___/ /\ \| |    |  __  |  __|
              / ____ \| |  | | |  / ____ \ |____| |  | | |____
             /_/    \_\_|  |_|_| /_/    \_\_____|_|  |_|______|


          (AMPACHE is **NOT** a sponsor of the FullAuto© Project.)
END
   print $starting_ampache;sleep 10;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv www-data:www-data /var/www','__display__');
   $region=~s/^.*['](.*)[']$/$1/;
   ($stdout,$stderr)=$handle->cmd($sudo.'wget -qO- '.
      'http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-connect.html'
      );
   my @smtp_servers=();my $smtp_server='us-east-1';
   foreach my $line (split /\n/,$stdout) {
      if (-1<index $line,'email-smtp.') {
         $line=~s/^.*(email-smtp\.[^Hh].*?com).*$/$1/;
         next unless $line=~/^email-smtp/;
         push @smtp_servers,$line;
         if (-1<index $line,$region) {
            $smtp_server=$line;
            last;
         }
      }
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'touch /etc/mail/authinfo');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod 666 /etc/mail/authinfo');
   my $authinfo=<<END;
AuthInfo:$smtp_server \\x22U:root\\x22 \\x22I:$access_id\\x22 \\x22P:$smtppass\\x22 \\x22M:PLAIN\\x22
END
   chop $authinfo;   
   ($stdout,$stderr)=$handle->cmd($sudo.
      "echo -e \"$authinfo\" > /etc/mail/authinfo");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'makemap -v hash /etc/mail/authinfo.db < /etc/mail/authinfo',
      '__display__');
   my $access="Connect:$smtp_server RELAY";
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 666 /etc/mail/access');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "echo -e \"$access\" >> /etc/mail/access");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 644 /etc/mail/access');
   my $email_domain=$verified_email;
   $email_domain=~s/^.*\@(.*)$/$1/;
   $ad="define(`SMART_HOST%SQ%, `$smtp_server%SQ%)dnl%NL%".
       "define(`RELAY_MAILER_ARGS%SQ%, `TCP \$h 25%SQ%)dnl%NL%".
       "define(`confAUTH_MECHANISMS%SQ%, `LOGIN PLAIN%SQ%)dnl%NL%".
       "FEATURE(`authinfo%SQ%, `hash -o /etc/mail/authinfo.db%SQ%)dnl%NL%".
       "MASQUERADE_AS(`$email_domain%SQ%)dnl%NL%".
       "FEATURE(masquerade_envelope)dnl%NL%".
       "FEATURE(masquerade_entire_domain)dnl";
   ($stdout,$stderr)=$handle->cmd($sudo."sed -i ".
      "\'/MAILER(smtp)dnl/i$ad\' /etc/mail/sendmail.mc");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       '/etc/mail/sendmail.mc');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SQ%/\'/g\" ".'/etc/mail/sendmail.mc');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "${sudo}chmod -v 666 /etc/mail/sendmail.cf",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "${sudo}m4 -d /etc/mail/sendmail.mc > /etc/mail/sendmail.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "${sudo}chmod -v 644 /etc/mail/sendmail.cf",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service sendmail restart','__display__');
   print "\n   ACCESS AMPACHE UI AT:\n\n",
         " http://$public_ip\n";
   my $thanks=<<'END';

     ______                  _    ,
       / /              /   ' )  /        /
    --/ /_  __.  ____  /_    /  / __ . . /
   (_/ / /_(_/|_/ / <_/ <_  (__/_(_)(_/_'   For Using
                             //

           _   _      _         _____      _ _    _         _
          | \ | | ___| |_      |  ___|   _| | |  / \  _   _| |_  |
          |  \| |/ _ \ __| o o | |_ | | | | | | / _ \| | | | __/ | \
          | |\  |  __/ |_  o o |  _|| |_| | | |/ ___ \ |_| | ||     |
          |_| \_|\___|\__|     |_|   \__,_|_|_/_/   \_\__,_|\__\___/ ©


   Copyright © 2000-2017  Brian M. Kelly  Brian.Kelly@FullAuto.com

END
   if (defined $Net::FullAuto::FA_Core::dashboard) {
      eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 15;
         print $thanks;
         print "   \n   Press Any Key to EXIT ... ";
         <STDIN>;
      };alarm(0);
      print "\n\n\n   Please wait at least a minute for the Default Browser\n",
            "   to start with your new AMPACHE installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_ampache=sub {

   my $type="]T[{select_type}";
   $type=0 if -1<index $type,'select_type';
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $region="]T[{awsregions}";
   $region='' if -1<index $region,']T[';
   $region=~s/^"//;
   $region=~s/"$//;
   my $verified_email="]P[{pick_email}";
   if (-1<index $verified_email,'Enter ') {
      $verified_email="]I[{'ampache_enter_email_address',1}";
   }
   my $ampache="]P[{select_ampache_setup}";
   my $permanent_ip="]P[{permanent_ip}";
   my $site_name="]I[{'ampache_enter_site_name',1}";
   my $site_profile="]P[{choose_site_profile}";
   my $site_build="]P[{choose_build}";
   my $strong_password="]I[{'ampache_enter_password',1}";
   my $i=$main::aws->{fullauto}->{ImageId}||'';
   my $s=$main::aws->{fullauto}->
         {NetworkInterfaces}->[0]->{SubnetId}||'';
   my $g=$main::aws->{fullauto}->
         {SecurityGroups}->[0]->{GroupId}||'';
   my $n=$main::aws->{fullauto}->
         {SecurityGroups}->[0]->{GroupName}||'';
   my $c='aws ec2 describe-security-groups '.
         "--group-names $n";
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error;
   my $cidr='';
   if (exists $hash->{SecurityGroups}->[0]->{IpPermission}
         ->[0]->{IpRanges}->[0]->{CidrIp}) {
      $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
            ->[0]->{IpRanges}->[0]->{CidrIp};
   } else {
      $cidr=$hash->{SecurityGroups}->[0]->{IpPermissionsEgress}
            ->[0]->{IpRanges}->[0]->{CidrIp};
   }
   $c='aws ec2 create-security-group --group-name '.
      'AmpacheSecurityGroup --description '.
      '"AMPACHE.com Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name AmpacheSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name AmpacheSecurityGroup --protocol '.
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name AmpacheSecurityGroup --protocol '.
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $configure_ampache->('AMPACHE.com',$ampache,
         $region,$verified_email,
         $permanent_ip,$site_name,$site_profile,$site_build,
         $strong_password);
   return '{choose_is_setup}<';

};

our $ampache_setup_summary=sub {

   package ampache_setup_summary;
   #my $site_name="]I[{'ampache_enter_site_name',1}";
   #unless ($site_name) {
   #   STDOUT->autoflush(1);
   #   print "\n   ERROR: Site Name cannot be blank!";sleep 5;
   #   STDOUT->autoflush(0);
   #   return '<';
   #}
   my $permanent_ip="]P[{permanent_ip}";
   my $remember="]I[{'ampache_enter_site_name',1}";
   $remember='' if -1<index $remember,'ampache_enter_site_name';
   if ($permanent_ip=~/^["]Release.* (\d+\.\d+\.\d+\.\d+).*$/s) {
      my $ip_to_release=$1;
      my $c="aws ec2 describe-addresses";
      my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};$hash->{Addresses}||=[];
      foreach my $address (@{$hash->{Addresses}}) {
         if ($address->{PublicIp} eq $ip_to_release) {
            my $c="aws ec2 release-address ".
                  "--allocation-id $address->{AllocationId}";
            my ($hash,$output,$error)=
               &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
            last;
         }
      }
      print "\n   $ip_to_release HAS BEEN RELEASED . . .\n";
      sleep 5;
      return $Net::FullAuto::ISets::Local::Ampache_is::check_elastic_ip->();
   } elsif ($permanent_ip=~/(\d+\.\d+\.\d+\.\d+)/s) {
      $main::aws->{permanent_ip}=$1;
   } elsif ($permanent_ip=~/Allocate|Elastic \(Permanent\)/) {
      my $c="aws ec2 allocate-address --domain vpc";
      my ($hash,$output,$error)=
            &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};
      $main::aws->{permanent_ip}=$hash->{PublicIp};
   }
   use JSON::XS;
   my $region="]T[{awsregions}";
   $region='' if -1<index $region,']T[';
   $region=~s/^"//;
   $region=~s/"$//;
   my $type="]T[{select_type}";
   $type=0 if -1<index $type,'select_type';
   $type=~s/^"//;
   $type=~s/"$//;
   my $money=$type;
   $money=~s/^.*-> \$(.*?) +(?:[(].+[)] )*\s*per hour$/$1/;
   $type=substr($type,0,(index $type,' ->')-3);
   my $ampache="]P[{select_ampache_setup}";
   $ampache=~s/^"//;
   $ampache=~s/"$//;
   my $num_of_servers=0;
   my $ol=$ampache;
   $ol=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ol==1) {
      $main::aws->{'AMPACHE.com'}->[0]=[];
   } elsif ($ol=~/^\d+$/ && $ol) {
      foreach my $n (0..$ol) {
         $main::aws->{'AMPACHE.com'}=[] unless exists
            $main::aws->{'AMPACHE.com'};
         $main::aws->{'AMPACHE.com'}->[$n]=[];
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

    ___           _        ___      _ _    _ ___
   | _ ) ___ __ _(_)_ _   | _ )_  _(_) |__| |__ \
   | _ \/ -_) _` | | ' \  | _ \ || | | / _` | /_/
   |___/\___\__, |_|_||_| |___/\_,_|_|_\__,_|(_)
            |___/

END
   $show_cost_banner.=<<END;

         $ampache


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "Begin Ampache Build",
         Result => $standup_ampache,

      },
      Item_2 => {

         Text => "Return to Choose Instruction Set Menu",
         Result => sub { return '{choose_is_setup}<' },

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

our $check_elastic_ip=sub {

   package check_elastic_ip;
   my $password="]I[{'ampache_enter_password',1}";
   my $confirm="]I[{'ampache_enter_password',2}";
   if ($password ne $confirm &&
         (-1==index $password,'ampache_enter_password')) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Password entries do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   my $c="aws ec2 describe-addresses";
   my ($hash,$output,$error)=
      &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   $hash||={};$hash->{Addresses}||=[];
   if (-1==$#{$hash->{Addresses}}) {
      my $permanent_ip_banner=<<'END';
    ___                                 _     ___ ___ ___
   | _ \___ _ _ _ __  __ _ _ _  ___ _ _| |_  |_ _| _ \__ \
   |  _/ -_) '_| '  \/ _` | ' \/ -_) ' \  _|  | ||  _/ /_/
   |_| \___|_| |_|_|_\__,_|_||_\___|_||_\__| |___|_|  (_)
END
      $permanent_ip_banner.=<<END;

   If you plan on using this AMPACHE server for an extended
   period, you will need a non-temporary IP Address. In Amazon
   Web Services, one Elastic IP (Amazon's way of allocating long 
   term IP addresses) is free so long as it is associated to
   a running server. If you stop or terminate the server, you
   need to manually release the address, or you will incur charges.

   Note also, that a Permanent IP Address will substantially
   increase the likelihood of email being sent from the AMPACHE
   server surviving spam filters and actually arriving at the
   intended destination.

END
      my $permanent_ip={

         Name => 'permanent_ip',
         Item_1 => {

            Text => 'Stay with Temporary Public IP Address',
            Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

         },
         Item_2 => {

            Text => 'Use Elastic (Permanent) IP Address',
            Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

         },
         Scroll => 1,
         Banner => $permanent_ip_banner,

      };
      return $permanent_ip;
   } else {
      my $c="aws ec2 describe-instances";
      my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};$hash->{Addresses}||=[];
      my %pubip=();
      foreach my $res (@{$hash->{Reservations}}) {
         foreach my $inst (@{$res->{Instances}}) {
            my $pip=$inst->{PublicIpAddress}||'';
            next unless $pip;
            next if exists $inst->{State}->{Name} &&
               $inst->{State}->{Name} eq 'terminated';
            $pubip{$pip}='';
         }
      }
      $c="aws ec2 describe-addresses";
      ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      my @available=();my @available_remove=();
      foreach my $address (@{$hash->{Addresses}}) {
         unless (exists $pubip{$address->{PublicIp}}) {
            push @available, $address->{PublicIp};
            push @available_remove,"Release IP Address $address->{PublicIp}"; 
         }
      }
      if (-1<$#available) {
         my $use_elastic_banner=<<'END';
    _   _           ___ _         _   _      ___ ___ ___ 
   | | | |___ ___  | __| |__ _ __| |_(_)__  |_ _| _ \__ \ 
   | |_| (_-</ -_) | _|| / _` (_-<  _| / _|  | ||  _/ /_/
    \___//__/\___| |___|_\__,_/__/\__|_\__| |___|_|  (_)
END
         $use_elastic_banner.=<<END;

   An allocated but not associated Elastic IP has been identified.
   Using this IP Address for AMPACHE may avoid charges from
   Amazon that are levied against allocated but not associated
   Elastic IPs. Please make a selection.

END
         my $permanent_ip={

            Name => 'permanent_ip',
            Item_1 => {

               Text => 'Stay with Temporary Public IP Address',
               Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

            },
            Item_2 => {

               Text => "]C[ (to avoid cost)",
               Convey => \@available_remove,
               Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

            },
            Item_3 => {

               Text => "Use Elastic (Permanent) IP Address ]C[",
               Convey => \@available,
               Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

            },
            Scroll => 1,
            Banner => $use_elastic_banner,

         };
         return $permanent_ip;
      } else {
         my $new_elastic_banner=<<'END';
    _  _              ___ _         _   _      ___ ___ ___
   | \| |_____ __ __ | __| |__ _ __| |_(_)__  |_ _| _ \__ \
   | .` / -_) V  V / | _|| / _` (_-<  _| / _|  | ||  _/ /_/
   |_|\_\___|\_/\_/  |___|_\__,_/__/\__|_\__| |___|_|  (_)
END
         $new_elastic_banner.=<<END;

   Allocated Elastic IP Addresses have been identified, but
   all are currently associated with server instances. A new
   one can be allocated and associated with your new AMPACHE
   server, but an additional cost of \$0.005 (half cent)
   per hour will be incurred. Please make a selection.

END
         my $permanent_ip={

            Name => 'permanent_ip',
            Item_1 => {

               Text => 'Stay with Temporary Public IP Address',
               Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

            },
            Item_2 => {

               Text => 'Allocate Additional Elastic (Permanent) IP Address',
               Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_site_name,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,

            },
            Scroll => 1,
            Banner => $new_elastic_banner,

         };
         return $permanent_ip;
      }
   }

};

our $ampache_lift_restrictions=sub {

   my $inform_banner=<<'END';

    _    _  __ _     ___        _       _    _   _
   | |  (_)/ _| |_  | _ \___ __| |_ _ _(_)__| |_(_)___ _ _  ___
   | |__| |  _|  _| |   / -_|_-<  _| '_| / _|  _| / _ \ ' \(_-<
   |____|_|_|  \__| |_|_\___/__/\__|_| |_\__|\__|_\___/_||_/__/

END
   $inform_banner.=<<END;
   New Amazon email users are confined to the Amazon SES (Simple Email
   Service) "sandbox". Within the sandbox there is a limit of 200 emails
   every 24 hours. More importantly, *ALL* recipients have to be "Amazon
   verified" - which is burdensome. To lift these restrictions, you have
   to apply for a "limit increase". A limit increase will also remove the
   requirement that recipients be Amazon verified. Note - there is *NO*
   guarantee that Amazon will lift email restrictions for any particular
   user. Use the link below to apply for a limit increase.

   NOTE: If using the FullAuto Windows App, you will have to expand this box
         to fullscreen and hit enter, and then re-enter this screen in order
         to see the entire URL listed below. Link is clickable if underlined.

   http://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html
END
   my $lift_restrictions={

      Name => 'lift_restrictions',
      Result => sub { return '{ampache_ses_sandbox}<' },
      Banner => $inform_banner,
   };
   return $lift_restrictions;   

};

our $ampache_use_limited=sub {

   my $inform_banner=<<'END';

    _   _           _    _       _ _          _   ___            _ _
   | | | |___ ___  | |  (_)_ __ (_) |_ ___ __| | | __|_ __  __ _(_) |
   | |_| (_-</ -_) | |__| | '  \| |  _/ -_) _` | | _|| '  \/ _` | | |
    \___//__/\___| |____|_|_|_|_|_|\__\___\__,_| |___|_|_|_\__,_|_|_|

END
   $inform_banner.=<<END;
   Since there is no guarantee that Amazon will lift email restrictions for
   any particular user, it is helpful to know how to make the most of the
   access there actually is. Users who have not requested, or been granted a
   limit increase, must verify thier recipients with Amazon. Once verified,
   AMPACHE features like notifications will work for that recipient. To
   verify a recipient, use the form in the link below to enter the recipient's
   email address. Amazon will automatically send a verification email that
   they must respond to. You are highly encouraged to communicate with your
   recipient through some other medium (other email, text message, Facebook,
   Twitter, etc.) Be aware that recipients of these verification emails have
   a link to inform Amazon if the email was "unwanted". Once they are verified,
   you can successfully send an invite to them from your AMPACHE server.

http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html
END
   my $use_limited_email={

      Name => 'use_limited_email',
      Result => sub { return '{ampache_ses_sandbox}<' },
      Banner => $inform_banner,
   };
   return $use_limited_email;


};

our $ampache_ses_sandbox=sub {

   package ampache_ses_sandbox;
   my $inform_banner=<<'END';

    ___                     _            _     _____        _ 
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_  |_   _|_ _ __| |__ __
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _|   | |/ _` (_-< / /(_-<
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__|   |_|\__,_/__/_\_\/__/ 
     __      |_|    _                            ___            _ _
    / _|___ _ _    /_\  _ __  __ _ ______ _ _   | __|_ __  __ _(_) |
   |  _/ _ \ '_|  / _ \| '  \/ _` |_ / _ \ ' \  | _|| '  \/ _` | | |
   |_| \___/_|   /_/ \_\_|_|_\__,_/__\___/_||_| |___|_|_|_\__,_|_|_|

END
   $inform_banner.=<<END;
   In order to use email invites and notifications from your AMPACHE
   server, there is an important and necessary task you will have to do
   outside of this FullAuto installation. New Amazon users are allowed very
   limited and precise access to email functionality. Given the ever present
   problem of "spam", and other forms of email abuse, this policy is quite
   reasonable. Unfortunately, email dependent features of AMPACHE are
   limited until these restrictions are lifted. Please make a selection:

END

   my $ampache_ses_sandbox={

      Name => 'ampache_ses_sandbox',
      Item_1 => {
      
         Text => 'Continue Installation of AMPACHE.',
         Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_choose_strong_password,
      },
      Item_2 => {

         Text => 'Learn how to use limited email with Amazon restrictions.',
         Result =>
      $Net::FullAuto::ISets::Local::Ampache_is::ampache_use_limited,

      },
      Item_3 => {

         Text => 'Learn how to apply for removal of Amazon email restrictions.',
         Result =>
      $Net::FullAuto::ISets::Local::Ampache_is::ampache_lift_restrictions,

      },
      Scroll => 1,
      Banner => $inform_banner,

   };
   return $ampache_ses_sandbox;


};

our $ampache_validate_email=sub {

   package ampache_validate_email;
   my $email="]I[{'ampache_enter_email_address',1}";
   my $confirm="]I[{'ampache_enter_email_address',2}";
   unless ($email eq $confirm) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Addresses do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($email=~/^\s*$/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: You failed to enter an Email Address!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($email!~/\@/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Address must contain \'\@\' character!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   my $c="aws ses verify-email-identity --email-address $email";
   my ($hash,$output,$error)=&Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   my $inform_banner=<<'END';

    ___                     _            _   _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_| |
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _|_|
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__(_)
             |_|

END
   $inform_banner.=<<END;
   The email address you just entered: $email

   has been submitted to Amazon Web Services for verification. Amazon
   will be sending an email to this address that you must respond to
   in order for this address to work with your AMPACHE installation.
   You can take a few minutes to do this now, or after you complete this
   installation. Just note, that email in your AMPACHE server will
   not work until you have responded to Amazon's email.

END
   my $email_message={

      Name => 'email_message',
      Result =>
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_choose_strong_password,
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_ses_sandbox,
      Banner => $inform_banner,

   };
   return $email_message;

};

our $ampache_choose_strong_password=sub {

   package choose_strong_password;
   my $ampache_password_banner=<<'END';

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
         die if -1<index $word,'/';
         die if -1<index $word,'&';
         die if -1<index $word,'%';
         die if -1<index $word,'!';
         return $word;
      };
      alarm 0;
      $word||='';
      last if $word;
   }
   $ampache_password_banner.=<<END;
   Database (MariaDB), Web Server (NGINX) and SSL Certificate and "admin"
   AMPACHE account all need a strong password. Use the one supplied here,
   or create your own. To create your own, use the [DEL] key to clear the
   highlighted input box first.

   *** BE SURE TO WRITE IT DOWN AND KEEP IT SOMEWHERE SAFE! ***

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.

   Password
                    ]I[{1,\'$word\',50}

   Confirm
                    ]I[{2,\'$word\',50}


END
   my $ampache_enter_password={

      Name => 'ampache_enter_password',
      Input => 1,
      Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::check_elastic_ip,
      #Result => $ampache_setup_summary,
      Banner => $ampache_password_banner,

   };
   return $ampache_enter_password;

};

our $ampache_enter_email_address=sub {

   my $ampache_email_banner=<<'END';

    ___     _             ___            _ _     _      _    _
   | __|_ _| |_ ___ _ _  | __|_ __  __ _(_) |   /_\  __| |__| |_ _ ___ ______
   | _|| ' \  _/ -_) '_| | _|| '  \/ _` | | |  / _ \/ _` / _` | '_/ -_|_-<_-<
   |___|_||_\__\___|_|   |___|_|_|_\__,_|_|_| /_/ \_\__,_\__,_|_| \___/__/__/

END
   $ampache_email_banner.=<<END;

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.
   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the main contact email for AMPACHE here:


   Email Address
                    ]I[{1,'',50}

   Confirm Address
                    ]I[{2,'',50}


END

   my $ampache_enter_email_address={

      Name => 'ampache_enter_email_address',
      Input => 1,
      Result => $ampache_validate_email,
      #Result => $ampache_setup_summary,
      Banner => $ampache_email_banner,

   };
   return $ampache_enter_email_address;

};

our $ampache_pick_email_address=sub {

   package ampache_pick_email_address;
   use Net::FullAuto::Cloud::fa_amazon;
   my $c="aws ses list-identities";
   my ($hash,$output,$error)=run_aws_cmd($c);
   my @identities=grep { /\@/ } @{$hash->{Identities}};
   if (-1<$#identities) {

      my $pick_banner=<<'END';

    ___ _    _     ___            _ _     _      _    _
   | _ (_)__| |__ | __|_ __  __ _(_) |   /_\  __| |__| |_ _ ___ ______
   |  _/ / _| / / | _|| '  \/ _` | | |  / _ \/ _` / _` | '_/ -_|_-<_-<
   |_| |_\__|_\_\ |___|_|_|_\__,_|_|_| /_/ \_\__,_\__,_|_| \___/__/__/
END
      $pick_banner.=<<'END';

   In order for email functionality to work with AMPACHE, you need to
   associate an Amazon Web Services verified email address. The following
   email addresses have been identified as verifed Amazon addresses. Please
   select one, or choose to create a new one. Note that if you choose to
   create a new one, it will have to be verified before email functionality
   in AMPACHE will work properly. This setup wizard will notify Amazon,
   and Amazon will send an email to the entered address. You must respond to
   that email in order to complete verification. You can also verify
   addresses manually at this Amazon URL:

http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html

END
      my $pick_email={
      
         Name => 'pick_email',
         Item_1 => {

            Text => "Enter and verify a different address\n\n",
            Result =>
 $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_email_address->(),

         },
         Item_2 => {

            Text => "]C[",
            Convey => \@identities,
            Result =>
         $Net::FullAuto::ISets::Local::Ampache_is::ampache_ses_sandbox,

         },
         Scroll => 2,
         Banner => $pick_banner,
      };
      return $pick_email;
   } else {
 $Net::FullAuto::ISets::Local::Ampache_is::ampache_enter_email_address->();
   }

};

our $ampache_choose_build=sub {

   package ampache_choose_build;
   use JSON::XS;
   my $c='wget -qO- https://api.github.com/users/ampache/repos';
   my $local=Net::FullAuto::FA_Core::connect_shell();
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$local->cmd($c);
   my @repos=();
   @repos=decode_json($stdout);
   my $default_branch=$repos[0]->[1]->{'default_branch'};
   my $updated=$repos[0]->[1]->{'updated_at'};
   my @branches=();
   # git ls-remote --tags git://github.com/ampache/ampache
   $c='wget -qO- https://api.github.com/repos/ampache/ampache/branches';
   ($stdout,$stderr)=$local->cmd($c);
   @branches=decode_json($stdout);
   my @builds=();
   $updated=~s/^(.*)T.*$/$1/;
   my $scrollnum=0;my $count=0;
   foreach my $branch (@{$branches[0]}) {
      $count++;
      push @builds,$branch->{name};
      if ($default_branch eq $branch->{name}) {
         $scrollnum=$count;
      }
   }
   my $ampache_build_banner=<<'END';
     ___ _                       ___      _ _    _  __   __          _
    / __| |_  ___  ___ ___ ___  | _ )_  _(_) |__| | \ \ / /__ _ _ __(_)___ _ _
   | (__| ' \/ _ \/ _ (_-</ -_) | _ \ || | | / _` |  \ V / -_) '_(_-< / _ \ ' \
    \___|_||_\___/\___/__/\___| |___/\_,_|_|_\__,_|   \_/\___|_| /__/_\___/_||_|

END
   $ampache_build_banner.=<<END;
   There are different versions of AMPACHE available. If you are *NOT* a
   developer, it is highly recommended that you choose the \"$default_branch\"
   branch. It is set as the default (with the arrow >).

   For more information:  https://github.com/ampache/ampache/branches

   The AMPACHE project was last updated:  $updated

END
   my %choose_build=(

      Name => 'choose_build',
      Item_1 => {

         Text => ']C[',
         Convey => \@builds,
         Result =>
      $Net::FullAuto::ISets::Local::Ampache_is::ampache_license_agreement_one,

      },
      Scroll => $scrollnum,
      Banner => $ampache_build_banner,
   );
   return \%choose_build

};

our $ampache_choose_site_profile=sub {

   package ampache_choose_site_profile;
   my $site_name="]I[{'ampache_enter_site_name',1}";
   unless ($site_name) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Site Name cannot be blank!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }

   my $ampache_profile_banner=<<'END';

     ___ _                       ___ _ _         ___          __ _ _
    / __| |_  ___  ___ ___ ___  / __(_) |_ ___  | _ \_ _ ___ / _(_) |___
   | (__| ' \/ _ \/ _ (_-</ -_) \__ \ |  _/ -_) |  _/ '_/ _ \  _| | / -_)
    \___|_||_\___/\___/__/\___| |___/_|\__\___| |_| |_| \___/_| |_|_\___|

   Please choose the kind of AMPACHE site you'd like to set up.

END
   my %choose_site_profile=(

      Name => 'choose_site_profile',
      Item_1 => {

         Text => ']C[',
         Convey => [
                      'Community',
                      'Public (open registration)',
                      'Single User',
                      'Private (no federation)'
                   ],
         #Result => $ampache_setup_summary
         Result =>
      $Net::FullAuto::ISets::Local::Ampache_is::ampache_choose_build,

      },
      Scroll => 2,
      Banner => $ampache_profile_banner,
   );
   return \%choose_site_profile

};

our $ampache_enter_site_name=sub {

   package ampache_enter_site_name;
   my $permanent_ip="]P[{permanent_ip}";
   my $remember="]I[{'ampache_enter_site_name',1}";
   $remember='prayerswag.com'
   #$remember='video.get-wisdom.com'
      if -1<index $remember,'ampache_enter_site_name';
   if ($permanent_ip=~/^["]Release.* (\d+\.\d+\.\d+\.\d+).*$/s) {
      my $ip_to_release=$1;
      my $c="aws ec2 describe-addresses";
      my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};$hash->{Addresses}||=[];
      foreach my $address (@{$hash->{Addresses}}) {
         if ($address->{PublicIp} eq $ip_to_release) {
            my $c="aws ec2 release-address ".
                  "--allocation-id $address->{AllocationId}";
            my ($hash,$output,$error)=
               &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
            last;
         }
      }
      print "\n   $ip_to_release HAS BEEN RELEASED . . .\n";
      sleep 5;
      return $Net::FullAuto::ISets::Local::Ampache_is::check_elastic_ip->();
   } elsif ($permanent_ip=~/(\d+\.\d+\.\d+\.\d+)/s) {
      $main::aws->{permanent_ip}=$1;
   } elsif ($permanent_ip=~/Allocate|Elastic \(Permanent\)/) { 
      my $c="aws ec2 allocate-address --domain vpc";
      my ($hash,$output,$error)=
            &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};
      $main::aws->{permanent_ip}=$hash->{PublicIp};
   }
   my $ampache_site_banner=<<'END';

    ___     _             ___ _ _         _  _
   | __|_ _| |_ ___ _ _  / __(_) |_ ___  | \| |__ _ _ __  ___
   | _|| ' \  _/ -_) '_| \__ \ |  _/ -_) | .` / _` | '  \/ -_)
   |___|_||_\__\___|_|   |___/_|\__\___| |_|\_\__,_|_|_|_\___|

   The Site Name will appear within AMPACHE as the name of your
   AMPACHE site. It may or may not be the same as a Domain Name
   that you might setup or associate with your site. Setting up a
   Domain Name for your site is outside the scope of this installer.
END
   $ampache_site_banner.=<<END;

   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the Site Name for AMPACHE here:


   Site Name
                    ]I[{1,\'$remember\',50}

END

   my $ampache_enter_site_name={

      Name => 'ampache_enter_site_name',
      Input => 1,
      Result =>
         $Net::FullAuto::ISets::Local::Ampache_is::ampache_setup_summary,
      Banner => $ampache_site_banner,

   };
   return $ampache_enter_site_name;

};

our $ampache_validate_domain=sub {

   package ampache_validate_domain;
   my $domain="]I[{'ampache_enter_domain_name',1}";
   my $c="aws ec2 allocate-address --domain vpc";
   my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   $hash||={};
   $main::aws->{permanent_ip}=$hash->{PublicIp};

   my $confirm='';
   unless ($domain eq $confirm) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Addresses do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($domain=~/^\s*$/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: You failed to enter an Email Address!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($domain!~/\@/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Address must contain \'\@\' character!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   $c="aws ses verify-email-identity --email-address $domain";
   ($hash,$output,$error)=&Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   my $inform_banner=<<'END';

    ___                     _            _   _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_| |
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _|_|
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__(_)
             |_|

END
   $inform_banner.=<<END;
   The domain name you just entered: $domain

   has been submitted to Amazon Web Services for verification. Amazon
   will be sending an email to this address that you must respond to
   in order for this address to work with your AMPACHE installation.
   You can take a few minutes to do this now, or after you complete this
   installation. Just note, that email in your AMPACHE server will
   not work until you have responded to Amazon's email.

END
   my $email_message={

      Name => 'email_message',
      Result => $ampache_setup_summary,
      Banner => $inform_banner,

   };
   return $email_message;

};

our $ampache_enter_domain_name=sub {

   my $ampache_domain_banner=<<'END';

    ___     _             ___                 _        _  _
   | __|_ _| |_ ___ _ _  |   \ ___ _ __  __ _(_)_ _   | \| |__ _ _ __  ___
   | _|| ' \  _/ -_) '_| | |) / _ \ '  \/ _` | | ' \  | .` / _` | '  \/ -_)
   |___|_||_\__\___|_|   |___/\___/_|_|_\__,_|_|_||_| |_|\_\__,_|_|_|_\___|

   The Domain Name is the friendly address of your site - like fullauto.com
   This setup will test the validity of your domain name, and coach you
   through the steps you need to take to activate it successfully.

END
   $ampache_domain_banner.=<<END;

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.
   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the Domain Name for AMPACHE here:


   Domain Name
                    ]I[{1,'',50}

END

   my $ampache_enter_domain_name={

      Name => 'ampache_enter_domain_name',
      Input => 1,
      Result => $ampache_validate_domain,
      #Result => $ampache_setup_summary,
      Banner => $ampache_domain_banner,

   };
   return $ampache_enter_domain_name;

};

our $ampache_caution=sub {

   my $inform_banner=<<'END';

     ___   _  _   _ _____ ___ ___  _  _ _
    / __| /_\| | | |_   _|_ _/ _ \| \| | |
   | (__ / _ \ |_| | | |  | | (_) | .` |_|
    \___/_/ \_\___/  |_| |___\___/|_|\_(_)

END
   $inform_banner.=<<END;
   This setup is intended to be a demonstration both of FullAuto‘s automation
   capabilities, as well as AMPACHE’s video streaming capabilities. For
   this purpose, Amazon was chosen because of the fast ZERO to full AMPACHE
   setup in one sitting. With other Cloud and host environments, there can be
   significant delays, and it is not as easy to setup an account, have it
   fully accessible, run the automation to completion, play with AMPACHE
   and destroy it all easily after the evaluation is complete with minimal
   if any charges. With Amazon you can do this very easily. You even get an
   entire Gigabyte of free outbound bandwidth. Beyond uploading and evaluating
   one or two modest videos on AMPACHE, you would **NOT** want to stream a
   lot of video from Amazon – the bandwidth costs are simply too prohibitive
   for anything beyond evaluation and demonstration. **PLEASE DONATE**
   http://FullAuto.com/donate.html and help us to build a full featured
   self-service dashboard that will work just as easily for other more
   affordable hosting environments.
END
   my $ampache_caution={

      Name => 'ampache_caution',
      Result => 
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_choose_site_profile,
   #$Net::FullAuto::ISets::Local::Ampache_is::ampache_license_agreement_one,
      Banner => $inform_banner,
   };
   return $ampache_caution;


};

our $ampache_license_agreement_three=sub {

   package ampache_license_agreement_three;
   my $ampache_license_banner_three=<<'END';

   THIS FREE SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
   EVENT SHALL THE AUTHOR OR ANY CONTRIBUTOR BE LIABLE FOR
   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   EFFECTS OF UNAUTHORIZED OR MALICIOUS NETWORK ACCESS;
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
   AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

END
   my %ampache_license_three=(

      Name => 'ampache_license_three',
      Item_1 => {

         Text => "I accept the AMPACHE License Agreement",
         Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_pick_email_address,

      },
      Item_2 => {

         Text => "I DO NOT accept the AMPACHE License Agreement\n".
                 '              - The installation will be cancelled',
         Result => sub { return '{choose_is_setup}<' },

      },
      Scroll => 2,
      Banner => $ampache_license_banner_three,

   );
   return \%ampache_license_three;

};

our $ampache_license_agreement_two=sub {

   package ampache_license_agreement_two;
   my $ampache_license_banner_two=<<'END';

   1. Redistributions of source code, in whole or part and with or without
   modification (the "Code"), must prominently display this GPG-signed
   text in verifiable form.
   2. Redistributions of the Code in binary form must be accompanied by
   this GPG-signed text in any documentation and, each time the resulting
   executable program or a program dependent thereon is launched, a
   prominent display (e.g., splash screen or banner text) of the Author's
   attribution information, which includes:
   (a) Name ("Arslan Hassan"),
   (b) Professional identification ("Ampache"), and
   (c) URL ("https://ampache.org").
   3. Neither the name nor any trademark of the Author may be used to
   endorse or promote products derived from this software without specific
   prior written permission.
   4. Users are entirely responsible, to the exclusion of the Author and
   any other persons, for compliance with (1) regulations set by owners or
   administrators of employed equipment, (2) licensing terms of any other
   software, and (3) local regulations regarding use, including those
   regarding import, export, and use of encryption software.
END
   my %ampache_license_two=(

      Name => 'ampache_license_one',
      Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_license_agreement_three,
      Banner => $ampache_license_banner_two,

   );
   return \%ampache_license_two;

};

our $ampache_license_agreement_one=sub {

   package ampache_license_agreement_one;
   my $ampache_license_banner_one=<<'END';

    __   _ _  _     __   ____
   /  |  ||_)|_)| |/  |/|_ |  | o _ _ ._  _ _   /\  _ ._ _  _ ._ _  _ .__|_
   \__|__||  |_)|_|\__|\|_ |  |_|(_(/_| |_>(/_ /--\(_|| (/_(/_| | |(/_| ||_
                                                    _|  
   ON FEBRAURY 14, 2010, AMPACHE LICENSE AGREEMENT TURNED TO OSI
   Attribution Assurance License, OFFICIALLY

   Copyright (c) 2010 by Arslan Hassan
   AMPACHE * https://ampache.org
   "A way to broadcast yourself - free and opensource video sharing website
    script"

   All Rights Reserved
   ATTRIBUTION ASSURANCE LICENSE (adapted from the original BSD license)
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the conditions below are met.
   These conditions require a modest attribution to <AUTHOR> (the
   "Arslan Hassan"), who hopes that its promotional value may help justify the
   thousands of dollars in otherwise billable time invested in writing
   this and other freely available, open-source software.
END
   my %ampache_license_one=(

      Name => 'ampache_license_one',
      Result =>
   $Net::FullAuto::ISets::Local::Ampache_is::ampache_license_agreement_two,
      Banner => $ampache_license_banner_one,

   );
   return \%ampache_license_one;

};

our $select_ampache_setup=sub {

   package select_ampache_setup;
   my @options=('AMPACHE & MySQL & NGINX on 1 Server');
   my $ampache_setup_banner=<<'END';

                           http://ampache.com/

                       __  __ _____        _____ _    _ ______
                 /\   |  \/  |  __ \ /\   / ____| |  | |  ____|
                /  \  | \  / | |__) /  \ | |    | |__| | |__
               / /\ \ | |\/| |  ___/ /\ \| |    |  __  |  __|
              / ____ \| |  | | |  / ____ \ |____| |  | | |____
             /_/    \_\_|  |_|_| /_/    \_\_____|_|  |_|______|


   Choose the AMPACHE setup you wish to set up. Note that more or larger
   capactiy servers means more expense. Consider a medium or large instance
   type (previous screens) if you foresee a lot of traffic on the server. You
   can navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_ampache_setup=(

      Name => 'select_ampache_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result =>
      $Net::FullAuto::ISets::Local::Ampache_is::ampache_caution,
      #$Net::FullAuto::ISets::Local::Ampache_is::ampache_choose_build,

      },
      Scroll => 1,
      Banner => $ampache_setup_banner,
   );
   return \%select_ampache_setup

};

1

__DATA__

Mount Google Drive on headless CentOS 7 server
26 June, 2016

I have been using google-drive-ocamlfuse for quite some time to backup my Virtualmin Virtual Servers, but finding any help setting this up for CentOS 7 in one place as far as i can see doesn't exist.

So I have taken information from 2 seperate blogs (i have linked to these below) and examples from what i had to do to get it up and running.

First thing is first... We need to install it from source.

You need OPAM to be installed this is pretty easy to do, just type the following commands:

$ sudo yum install ocaml ocaml-camlp4-devel ocaml-ocamldoc
$ git clone https://github.com/OCamlPro/opam.git 
$ cd opam 
$ ./configure 
$ make 
$ sudo make install
$ sudo yum install m4 fuse fuse-devel libcurl-devel libsqlite3x-devel zlib-devel
$ opam init 
$ opam update 
$ opam install google-drive-ocamlfuse
After successful build, the google-drive-ocamlfuse binary will be found in ~/.opam/system/bin. Add this to the end of your PATH environment as below:

$ nano ~/.bashrc
PATH=$PATH:$HOME/.opam/system/bin
export PATH
$ source ~/.bashrc
Once installed you need to authorise it with your account, you do this as follows:

Head over to https://console.developers.google.com/project and create a new project for access to Google Drive.

First click on Create Project and then enter a Project Name anything will do here.

Once it's created you should be able to manage it, if not just click on the name you created.

Then click on the three lines in the top right and select API Manager, on this page select Drive API and then Enable

You will then get an error saying you need to create credentials, this is fine just click the Go to Credentials button.

On the next page, it's hard to spot at first but click where it says client ID (it's the 3rd line down), then click Configure consent screen.

On this page just fill the form in how ever you want, it doesn't affect what we are doing here (Minimum you need to fill in is Product name shown to users).

Next select Web application, and again give it any name then click Create.

You will now see your client ID and client secret, keep these handy for the next step.

Head back over to your SSH window and type the following, using the clientID and client secret you generated previously:

$ google-drive-ocamlfuse -headless -id YOUR_CLIENT_ID -secret YOUR_SECRET
An url will appear in the window, just copy and paste the link into your web browser follow the prompts and then copy and paste the code shown back into the console.

Once entered it should give the following response:

Access token retrieved correctly.

After that your Google Drive access should be ok!

The next quick step is to mount the folder, choose where you want it and create the folder as follows:

mkdir YOUR FOLDER PATH
then mount it:

google-drive-ocamlfuse YOUR FOLDER PATH
if you need to unmount it for any reason just use the following:

fusermount -u YOUR FOLDER PATH
If you want to use a folder which is not empty just add the -o nonempty mount option as follows:

$ google-drive-ocamlfuse YOUR FOLDER PATH -o nonempty
I used the sites below to help with this.

http://xmodulo.com/mount-google-drive-linux.html

https://www.devops.zone/ubuntu-howtos/mount-google-drive-on-your-server-using-ocamlfuse/ 
