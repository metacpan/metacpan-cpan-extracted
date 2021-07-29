package Net::FullAuto::ISets::Local::EmailServer_is;

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
use Net::FullAuto::FA_Core qw[cleanup fetch clean_filehandle];
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
   my $handle=connect_shell();my $connect_error='';
   my $build_php=0;
   my $sudo=($^O eq 'cygwin')?'':
         'sudo env "LD_LIBRARY_PATH='.
         '/usr/local/lib64:$LD_LIBRARY_PATH" '.
         '"PATH=/usr/local/mysql/scripts:$PATH" ';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "hostnamectl set-hostname mail.$domain_url");
   ($stdout,$stderr)=setup_aws_security(
      'EmailServerSecurityGroup','EmailServer.com Security Group');
   ($stdout,$stderr)=$handle->cmd($sudo.'id www-data');
   if ($stdout=~/no such user/ || $stderr=~/no such user/) {
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
         "rm -rf /opt/source/* ~/fa\* /var/www/html/roundcube",
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
         'yum -y install icu cyrus-sasl openssl-devel'.
         ' cyrus-sasl-devel libtool-ltdl-devel libjpeg-turbo-devel'.
         ' freetype-devel libpng-devel java-1.7.0-openjdk-devel'.
         ' unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel'.
         ' ncurses-devel xmlto autoconf libmcrypt libmcrypt-devel'.
         ' libcurl libcurl-devel libicu libicu-devel re2c'.
         ' libpng-devel.x86_64 freetype-devel.x86_64 expat-devel'.
         ' oniguruma oniguruma-devel tcl tcl-devel git-all'.
         ' lzip libffi-devel libc-client-devel texinfo cmake'.
         ' systemd-devel bind-utils mailx',
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
   ($stdout,$stderr)=$handle->cmd($sudo.
      "dig -x $public_ip +short");
   my $ptr=$stdout;
   
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd($sudo.'yum install -y '.
         'https://dl.fedoraproject.org/pub/epel/'.
         'epel-release-latest-7.noarch.rpm','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'yum -y install uuid-devel '.
         'pkgconfig libtool gmp-devel '.
         'mpfr-devel libmpc-devel','__display__');
   }

   if (ref $main::aws eq 'HASH') {
      my $n=$main::aws->{fullauto}->
            {SecurityGroups}->[0]->{GroupName}||'';
      my $c='aws ec2 describe-security-groups '.
            "--group-names $n";
      my ($hash,$output,$error)=('','','');
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error;
      my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
              ->[0]->{IpRanges}->[0]->{CidrIp};
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 22 --cidr '.$cidr." 2>&1"; # SSH
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 80 --cidr '.$cidr." 2>&1"; # HTTP
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 443 --cidr '.$cidr." 2>&1"; # HTTPS
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 25 --cidr '.$cidr." 2>&1"; # SMTP
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 465 --cidr '.$cidr." 2>&1"; # SMTPS
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 587 --cidr '.$cidr." 2>&1"; # AMAZON SES
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 110 --cidr '.$cidr." 2>&1"; # POP3
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 995 --cidr '.$cidr." 2>&1"; # POP3S
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 143 --cidr '.$cidr." 2>&1"; # IMAP
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 993 --cidr '.$cidr." 2>&1"; # IMAPS
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 6379 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 11332 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 11333 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name EmailServerSecurityGroup --protocol '.
         'tcp --port 11334 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=25/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=465/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=587/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=110/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=995/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=143/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=80/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=443/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=6379/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=11332/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=11333/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --zone=public --permanent --add-port=11334/tcp',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'firewall-cmd --reload',
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.'mkdir -vp /opt/source',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://ftp.gnu.org/gnu/make/');
   $stdout=~s/^.*href=["]([^"]+)["].*$/$1/s;
   $stdout=~s/.sig$//;
   my $mktarfil=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      "https://ftp.gnu.org/gnu/make/$stdout",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xvf $mktarfil",'__display__');
   $mktarfil=~s/.tar.lz$//;
   ($stdout,$stderr)=$handle->cwd($mktarfil);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "./configure",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make install",'__display__');
   ($stdout,$stderr)=$handle->cwd('/usr/local/bin');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ln -s /usr/local/bin/make gmake");
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://www.sourceware.org/bzip2/');
   $stdout=~s/^.*?stable version is bzip2 ([\d\.]*\d)\..*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ls -1 /usr/local/lib | grep libbz2.so.$stdout");
   unless ($stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 | grep bzip2');
      if ($stdout=~/^\s*bzip2\s*$/s) {
         ($stdout,$stderr)=$handle->cmd($sudo.
             'rm -rvf bzip2-old','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
             'mv -v bzip2 bzip-old','__display__');
      }
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone git://sourceware.org/git/bzip2.git',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s;
         last if $done;
         sleep 30;
      }
      ($stdout,$stderr)=$handle->cwd('bzip2');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make -f Makefile-libbz2_so','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v libbz2.so* /usr/local/lib','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      $build_php=1;
   } else {
      print "bzip2 is up to date.\n";
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   # https://bipulkkuri.medium.com/install-latest-gcc-on-centos-linux-release-7-6-a704a11d943d
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- http://mirrors.concertpass.com/gcc/releases/');
   $stdout=~s/^.*href=["]([^"]+?)["].*$/$1/s;
   chop $stdout;
   $stdout=~s/gcc-//;
   my $verss=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.'gcc --version');
   $stdout=~s/^.*?GCC[)]\s+?([^\s]+)\s+Copyright.*$/$1/s;
   if ($stdout ne $verss) {
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
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget -qO- https://git.savannah.gnu.org/cgit/automake.git');
      $stdout=~s#^.*?Download.*?href.*?href=['](.*?snapshot.*?)['].*$#$1#s;
      my $atarfile=$stdout;
      $atarfile=~s/^.*\/(.*)$/$1/;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         'https://git.savannah.gnu.org'.$stdout,
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf $atarfile",'__display__');
      $atarfile=~s/.tar.gz$//;
      ($stdout,$stderr)=$handle->cwd($atarfile);
      ($stdout,$stderr)=$handle->cmd($sudo.
          './bootstrap','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
          './configure','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
          'make install','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         "http://mirrors.concertpass.com/gcc/releases/gcc-$verss/gcc-$verss.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf gcc-$verss.tar.xz",'__display__');
      ($stdout,$stderr)=$handle->cwd("gcc-$verss");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp build','__display__');
      ($stdout,$stderr)=$handle->cwd('build');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '../configure --enable-languages=c,c++ --disable-multilib',
         '3600','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make bootstrap','3600','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','3600','__display__');
      ($stdout,$stderr)=$handle->cwd('..');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rfv build','__display__');
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   my $done=0;my $gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --recursive https://github.com/madler/zlib.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('zlib');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://zlib.net');
   $stdout=~s/^.*?Current release:.*?zlib (.*?)[<].*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "git checkout v$stdout",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      './configure','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- http://xmlsoft.org/news.html');
   $stdout=~s/^.*?public releases.*?v(.*?):.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ls -1 /usr/local/lib | grep libxml2.so.$stdout");
   unless ($stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 | grep libxml2');
      if ($stdout=~/^\s*libxml2\s*$/s) {
         ($stdout,$stderr)=$handle->cmd($sudo.
             'rm -rvf libxml2-old','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
             'mv -v libxml2 libxml2-old','__display__');
      }
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git https://gitlab.gnome.org/GNOME/libxml2.git',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s;
         last if $done;
         sleep 30;
      }
      ($stdout,$stderr)=$handle->cwd('libxml2');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './autogen.sh','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v libxml-2.0.pc /usr/lib64/pkgconfig','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ldconfig -v','__display__');
      $build_php=1;
   } else {
      print "libxml2 is up to date.\n";
   }
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
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ldconfig -v','__display__');
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
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://en.wikipedia.org/wiki/OpenSSL');
   $stdout=~s/^.*?Stable release.*?-data["][>](.*?) *[(].*$/$1/s;
   my $osslv=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'strings /usr/local/lib64/libssl.so | grep OpenSSL');
   unless ($stdout=~/$osslv/s) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 | grep openssl');
      if ($stdout=~/^\s*openssl\s*$/s) {
         ($stdout,$stderr)=$handle->cmd($sudo.
             'rm -rvf openssl-old','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
             'mv -v openssl openssl-old','__display__');
      }
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone --recursive https://github.com/openssl/openssl.git',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s;
         last if $done;
         sleep 30;
      }
      ($stdout,$stderr)=$handle->cwd('openssl');
      # https://www.thegeekstuff.com/2015/02/rpm-build-package-example/
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         'https://git.sailfishos.org/mer-core/'.
         'openssl/raw/master/rpm/openssl.spec',
         '__display__');
      $osslv=~s/\./_/g;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout OpenSSL_$osslv",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './config LDFLAGS="-Wl,-rpath /usr/local/lib -Wl,'.
         '-rpath /usr/local/lib64"','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -Pv /etc/ssl/certs/* /usr/local/ssl/certs',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v *.pc /usr/local/lib/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ldconfig -v','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/lib64/libssl.so.1.1 '.
         '/usr/lib64/libssl.so.1.1');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/lib64/libcrypto.so.1.1 '.
         '/usr/lib64/libcrypto.so.1.1');
      $build_php=1;
   } else {
      print "libssl is up to date.\n";
   }
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
         '--sysconfdir=/etc --with-ssl=openssl '.
         '--with-libssl-prefix=/usr/local ',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      $ad='ca-certificate = /usr/local/ssl/certs/ca-bundle.crt';
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'/remoteencoding/a$ad\' /etc/wgetrc");
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
         "https://python.org/ftp/python/$version/Python-$version.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "tar xvf Python-$version.tar.xz",
         '__display__');
      ($stdout,$stderr)=$handle->cwd("Python-$version");
      # sudo is cleared of env vars to use system gcc
      # gcc-10 built python hangs during testing 2/20/2021
      # https://stackoverflow.com/questions/53543477/building-python-3-7-1-ssl-module-failed
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s/#SSL=/SSL=/" Modules/Setup');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s/\/ssl//" Modules/Setup');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s/#_ssl/_ssl/" Modules/Setup');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s/#[ \t]*-DUSE_SSL/$(printf \'\t\')-DUSE_SSL/" Modules/Setup');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s/#[ \t]*-L\$/$(printf \'\t\')-L\$/" Modules/Setup');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s/lib -lssl/lib64 -lssl/" Modules/Setup');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --prefix=/usr/local --exec-prefix=/usr/local '.
         '--enable-optimizations LDFLAGS="-Wl,-rpath /usr/local/lib" '.
         '--with-openssl=/usr/local','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','7200','__display__');
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
      ($stdout,$stderr)=$handle->cmd($sudo.
         'python --version','__display__');
   }
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
   ($stdout,$stderr)=$handle->cmd(
      "wget --no-check-certificate -qO- https://ftp.pcre.org/pub/pcre/");
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
                  "--with-zlib=/opt/source/zlib ".
                  '--with-http_gzip_static_module '.
                  '--with-http_ssl_module '.
                  '--with-file-aio '.
                  '--with-http_realip_module '.
                  '--without-http_scgi_module '. 
                  '--without-http_uwsgi_module '.
                  '--with-http_v2_module '.
                  '--with-openssl=/opt/source/openssl';
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
   $ad="            root /var/www/html/roundcube;%NL%".
       '            index  index.php  index.html index.htm;%NL%'.
       '            try_files $uri $uri/ /index.php?$args;';
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' $nginx_path/nginx/nginx.conf
END
   $handle->cmd_raw($sudo.$ad);
   $ad='%NL%        location ~ .php$ {'.
       '%NL%            root /var/www/html/roundcube;'.
       '%NL%            fastcgi_pass unix:/run/php-fpm/www.sock;'.
       '%NL%            fastcgi_index index.php;'.
       '%NL%            fastcgi_param SCRIPT_FILENAME '.
       '$document_root$fastcgi_script_name;'.
       '%NL%            include fastcgi_params;'.
       '%NL%        }'.
       '%NL%'.
       '%NL%        location /rspamd {'.
       '%NL%            proxy_pass http://127.0.0.1:11334/;'.
       '%NL%            proxy_set_header Host $host;'.
       '%NL%            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;'.
       '%NL%        }'.
       '%NL%'.
       '%NL%        location ~ ^/(README.md|INSTALL|LICENSE|CHANGELOG|UPGRADING)$ {'.
       '%NL%            deny all;'.
       '%NL%        }'.
       '%NL%'.
       '%NL%        location ~ ^/(bin|SQL|config|temp|logs)/ {'.
       '%NL%            deny all;'.
       '%NL%        }'.
       '%NL%'.
       '%NL%        location ~ /\. {'.
       '%NL%            deny all;'.
       '%NL%            access_log off;'.
       '%NL%            log_not_found off;'.
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
   $handle->cmd_raw($sudo.
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
         "sed -i \'s/server_name  localhost/".
         "server_name mail.$domain_url/\' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/#user  nobody;/user  www-data;/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/#error_page  404              /404.html;/".
         "error_page  404              /404.html;/' ".
         "$nginx_path/nginx/nginx.conf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl enable nginx.service','__display__');
      sleep 2;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service nginx start','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service nginx status -l','__display__');
      ($stdout,$stderr)=$handle->cwd("$nginx_path/nginx");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install certbot-nginx','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'certbot -n --nginx --debug --agree-tos --email '.
         "$email_address -d mail.$domain_url",
         '__display__');
      # https://ssldecoder.org
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl enable nginx.service','__display__');
      sleep 2;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service nginx restart','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service nginx status -l','__display__');
   }
}

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



   my $install_mysql=<<'END';

          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          :::::::::::::::::::::::::::::::::'        ':::::::::::::
          (MariaDB Foundation is **NOT** a    (`*..,
          sponsor of the FullAuto© Project.)   \  , `.
                                                \     \
          https://mariadb.org/                   \     \
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
   if ($stdout=~/libmariadb/) {
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
         'service mysql status -l','__display__');
   }
   if ($mysql_version<15.1 || $mysql_status!~/SUCCESS/) {
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
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 /opt','__display__');
      if ($stdout!~/mariadb/i) {
         my $done=0;my $gittry=0;
         while ($done==0) {
            ($stdout,$stderr)=$handle->cmd($sudo.
               'git clone https://github.com/MariaDB/server.git '.
               'mariadb','__display__');
            if (++$gittry>5) {
               print "\n\n   FATAL ERROR: $stderr\n\n";
               cleanup();
            }
            my $gittest='Connection reset by peer|'.
                        'Could not read from remote repository';
            $done=1 if $stderr!~/$gittest/s;
            last if $done;
            sleep 30;
         }
         ($stdout,$stderr)=$handle->cwd('mariadb');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'yum-builddep -y mariadb-server',
            '__display__');
         # https://www.linuxfromscratch.org/blfs/view/cvs/server/mariadb.html
         ($stdout,$stderr)=$handle->cmd($sudo.
            '/bin/cmake -DWITH_SSL=yes '.
            '-DSKIP_TESTS=ON '.
            '-DMYSQL_DATADIR=/var/lib/mysql '.
            '-DCMAKE_INSTALL_PREFIX=/usr/local/mysql '.
            '-DMYSQL_UNIX_ADDR=/run/mysqld/mysqld.sock '.
            '-DWITH_EXTRA_CHARSETS=complex '.
            '-DINSTALL_SYSTEMD_UNITDIR=/etc/systemd/system '.
            '-DOPENSSL_INCLUDE_DIR=/usr/local/include/openssl '.
            '-DOPENSSL_SSL_LIBRARY=/usr/local/lib64/libssl.so '.
            '-DOPENSSL_CRYPTO_LIBRARY='.
            '/usr/local/lib64/libcrypto.so',
            '3600','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'make install','3600','__display__');
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
         'mkdir -vp /run/mysqld','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chown -Rv mysql:root /var/run/mysqld',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install galera perl-DBI','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql stop','__display__');
      #($stdout,$stderr)=$handle->cmd($sudo.
      #   'chmod -v 1777 /tmp','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rvf /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chown -v mysql:root /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 700 /var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'scripts/mysql_install_db --user=mysql '.
         '--datadir=/var/lib/mysql','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/mysql/bin/mariadb /bin/mysql');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /etc/mysql/my.cnf.d','__display__');
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
      my $my_cnf=<<END;
# Begin /etc/mysql/my.cnf

# The following options will be passed to all MySQL clients
[client]
#password       = your_password
port            = 3306
socket          = /run/mysqld/mysqld.sock

# The MySQL server
[mysqld]
port            = 3306
socket          = /run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
skip-external-locking
key_buffer_size = 16M
max_allowed_packet = 1M
sort_buffer_size = 512K
net_buffer_length = 16K
myisam_sort_buffer_size = 8M

# Don't listen on a TCP/IP port at all.
skip-networking

# required unique id between 1 and 2^32 - 1
server-id       = 1

# Uncomment the following if you are using BDB tables
#bdb_cache_size = 4M
#bdb_max_lock = 10000

# InnoDB tables are now used by default
innodb_data_home_dir = /var/lib/mysql
innodb_log_group_home_dir = /var/lib/mysql
# All the innodb_xxx values below are the default ones:
innodb_data_file_path = ibdata1:12M:autoextend
# You can set .._buffer_pool_size up to 50 - 80 %
# of RAM but beware of setting memory usage too high
innodb_buffer_pool_size = 128M
innodb_log_file_size = 48M
innodb_log_buffer_size = 16M
innodb_flush_log_at_trx_commit = 1
innodb_lock_wait_timeout = 50

[mysqldump]
quick
max_allowed_packet = 16M

[mysql]
no-auto-rehash
# Remove the next comment character if you are not familiar with SQL
#safe-updates

[isamchk]
key_buffer = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[myisamchk]
key_buffer_size = 20M
sort_buffer_size = 20M
read_buffer = 2M
write_buffer = 2M

[mysqlhotcopy]
interactive-timeout

\\x21includedir /etc/mysql/my.cnf.d

# End /etc/mysql/my.cnf
END
      ($stdout,$stderr)=$handle->cmd(
         "echo -e \"$my_cnf\" > ~/my.cnf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -v ~/my.cnf /etc/mysql/my.cnf',
         '__display__');
      # https://github.com/arslancb/clipbucket/issues/429
      my $sql_mode_cnf=<<END;
[mysqld]
sql_mode=IGNORE_SPACE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION
END
      ($stdout,$stderr)=$handle->cmd(
         "echo -e \"$sql_mode_cnf\" > ~/sql_mode.cnf");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -v ~/sql_mode.cnf /etc/mysql/my.cnf.d/sql_mode.cnf',
         '__display__');
      sleep 2;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql start','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service mysql status -l','__display__');
      print "MYSQL START STDOUT=$stdout and STDERR=$stderr<==\n";sleep 5;
      print "\n\n\n\n\n\n\nWE SHOULD HAVE INSTALLED MARIADB=$stdout<==\n\n\n\n\n\n\n";
      sleep 5;
   }
   $handle->print($sudo.'/usr/local/mysql/bin/mariadb-secure-installation');
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
   # https://www.debiantutorials.com/installing-postfix-with-mysql-backend-and-sasl-for-smtp-authentication/
   # https://workaround.org/ispmail/buster/big-picture/  =>  Email Process
   # https://www.digitalocean.com/community/tutorials/how-to-install-your-own-webmail-client-with-roundcube-on-ubuntu-16-04
   # https://www.tecmint.com/install-roundcube-webmail-on-centos-7/  => ClamAV
   # https://www.linuxbabe.com/redhat/run-your-own-email-server-centos-postfix-smtp-server
   # https://www.linode.com/docs/guides/email-with-postfix-dovecot-and-mariadb-on-centos-7/

   # https://linuxize.com/series/setting-up-and-configuring-a-mail-server/

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
         my $cmd='DROP DATABASE roundcube;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==1 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP DATABASE mail;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==2 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE DATABASE roundcube CHARACTER SET '.
                 'utf8 COLLATE utf8_general_ci;';
         print "$cmd\n";
         $handle->print($cmd);
         $handle->print(';');
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==3 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP USER roundcube@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==4 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE USER roundcube@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==5 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='GRANT ALL PRIVILEGES ON roundcube.*'.
                 ' TO roundcube@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==6 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==7 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="CREATE DATABASE mail;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==8 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP USER mailuser@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==9 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE USER mailuser@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==10 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='GRANT SELECT ON mail.* TO mailuser@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==11 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==12 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="use mail;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==13 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="CREATE TABLE domains ( domain varchar(255) NOT NULL, ".
                 "PRIMARY KEY (domain)) ENGINE=MyISAM;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==14 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="CREATE TABLE forwardings ( source varchar(255) NOT NULL, ".
                 "destination varchar(255) NOT NULL, PRIMARY KEY (source)) ".
                 "ENGINE=MyISAM;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==15 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="CREATE TABLE users ( email varchar(255) NOT NULL, ".
                 "password varchar(255) NOT NULL, quota int(10) DEFAULT ".
                 "'104857600', PRIMARY KEY (email)) ENGINE=MyISAM;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==16 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="CREATE TABLE transport ( domain varchar(255) NOT NULL, ".
                 "transport varchar(255) NOT NULL, UNIQUE KEY domain ".
                 "(domain)) ENGINE=MyISAM;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==17 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE DATABASE postfixadmin CHARACTER SET '.
                 'utf8 COLLATE utf8_general_ci;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==18 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP USER postfixadmin@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==19 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE USER postfixadmin@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==20 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='GRANT ALL ON postfixadmin.* TO postfixadmin@localhost '.
                 'IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==21 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent>=22 && $output=~/MariaDB.*?>\s*$/) {
         print "quit\n";
         $handle->print('quit');
         sleep 1;
         next;
      }
      sleep 1;
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
   #
   #  Set PHP 7 or 8 here
   #
   #  roundcube does not work with php 8 as of 7/8/2021
   my $vn=7;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'strings /usr/local/lib/libmcrypt.so | grep libmcrypt-2.5.8');
   unless ($stdout) {
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
      $build_php=1;
   } else {
      print "libmcrypt is up to date\n";
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cmake --version','__display__');
   $stdout=~s/^.*?\s(\d+\.\d+).*$/$1/;
   if (!(-e '/usr/local/bin/cmake') && $stdout<3.02) {
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/Kitware/CMake.git',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s;
         last if $done;
         sleep 30;
      }
      ($stdout,$stderr)=$handle->cwd('CMake');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './bootstrap --system-curl -- '.
         '-DCMAKE_INSTALL_RPATH="/usr/local/lib64"',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','3600','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      $build_php=1;
   } else {
      print "cmake is up to date.\n";
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://libzip.org/');
   $stdout=~s/^.*?Current version is (.*?)[<].*$/$1/s;
   $stdout='1.6.1';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "strings /usr/local/lib64/libzip.so | grep $stdout");
   unless ($stdout) {
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/nih-at/libzip.git',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s;
         last if $done;
         sleep 30;
      }
      ($stdout,$stderr)=$handle->cwd('libzip');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git -P tag -l','__display__');
      $stdout=~s/^.*\n(rel-\d-\d-\d).*$/$1/s;
$stdout='rel-1-6-1';
#$stdout='v1.8.0';
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout $stdout",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp build','__display__');
      ($stdout,$stderr)=$handle->cwd('build');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/usr/local/bin/cmake .. '.
         '-DCMAKE_SHARED_LINKER_FLAGS="-L/usr/local/lib64" '.
         '-DCMAKE_INSTALL_RPATH="/usr/local/lib64" '.
         '-DOPENSSL_INCLUDE_DIR=/usr/local/include/openssl '.
         '-DOPENSSL_SSL_LIBRARY=/usr/local/lib64/libssl.so '.
         '-DOPENSSL_CRYPTO_LIBRARY='.
         '/usr/local/lib64/libcrypto.so',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v libzip.pc /usr/lib64/pkgconfig',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ldconfig -v','__display__');
      $build_php=1;
   } else {
      print "libzip is up to date\n";
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://doc.libsodium.org/#downloading-libsodium');
   $stdout=~s/^.*?libsodium (.*?)-stable.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "strings /usr/local/lib/libsodium.so | grep $stdout");
   unless ($stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ls -1 | grep libsodium');
      if ($stdout=~/^\s*libsodium\s*$/s) {
         ($stdout,$stderr)=$handle->cmd($sudo.
             'rm -rvf libsodium-old','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
             'mv -v libsodium libsodium-old','__display__');
      }
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/jedisct1/libsodium 2>&1',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s && $stdout!~/$gittest/s;
         last if $done;
         sleep 30;
      }
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
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ldconfig -v','__display__');
      $build_php=1;
   } else {
      print "libsodium is up to date.\n";
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://www.php.net/releases/index.php');
   $stdout=~s/^.*?php-($vn.*?)\.tar\.gz.*$/$1/s;
   my $phpv=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ls -1 | grep php-src$');
   my $php_build=0;
   if ($stdout=~/^\s*php-src\s*$/s) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'head -n5 php-src/NEWS');
      $stdout=~s/^.*, PHP (.*?)\n.*$/$1/s;
      unless ($phpv eq $stdout) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'rm -rvf php-src-old','__display__');
         ($stdout,$stderr)=$handle->cmd($sudo.
            'mv -v php-src php-src-old','__display__');
         $php_build=1;
      }
   } else { $php_build=1 }
   if ($php_build || $build_php) {
      my $done=0;my $gittry=0;
      while ($done==0) {
         ($stdout,$stderr)=$handle->cmd($sudo.
            'git clone https://github.com/php/php-src.git',
            '__display__');
         if (++$gittry>5) {
            print "\n\n   FATAL ERROR: $stderr\n\n";
            cleanup();
         }
         my $gittest='Connection reset by peer|'.
                     'Could not read from remote repository';
         $done=1 if $stderr!~/$gittest/s;
         last if $done;
         sleep 30;
      }
      ($stdout,$stderr)=$handle->cwd('php-src');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout php-$phpv",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './buildconf --force','__display__');
      my $pear=($vn eq 8)?'--with-pear ':'';
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --prefix=/usr/local/php'.$vn.' '.
         '--with-config-file-path=/usr/local/php'.$vn.'/etc '.
         '--with-config-file-scan-dir=/usr/local/php'.$vn.'/etc/conf.d '.
         '--enable-bcmath '.
         '--with-bz2 '.
         '--with-curl '.
         $pear.
         '--enable-filter '.
         '--enable-fpm '.
         '--with-fpm-systemd '.
         '--enable-gd '.
         '--with-freetype '.
         '--with-imap '.
         '--with-imap-ssl '.
         '--with-jpeg '.
         '--enable-intl '.
         '--enable-exif '.
         '--enable-mbstring '.
         '--with-gmp '.
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
         '--with-zlib '.
         '--with-libdir=lib64 '.
         '--with-kerberos','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make -j2',300,'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'make install','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php'.$vn.'/bin/php /usr/local/bin/php');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php'.$vn.'/bin/php /usr/bin/php');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./php.ini-production /usr/local/php'.$vn.'/etc/php.ini',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/post_max_size = 8M/post_max_size = 500M/\' ".
         "/usr/local/php$vn/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s#^.*pdo_mysql.default_socket.*\$#".
         "pdo_mysql.default_socket = /var/run/mysqld/mysqld.sock#\' ".
         "/usr/local/php$vn/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s#;date.timezone =#date.timezone = \"America/Chicago\"#\' ".
         "/usr/local/php$vn/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/upload_max_filesize = 2M/upload_max_filesize = 500M/\' ".
         "/usr/local/php$vn/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i \'s/max_execution_time = 30/max_execution_time = 7500/\' ".
         "/usr/local/php$vn/etc/php.ini");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i \'s/memory_limit = 128M/memory_limit = 256M/\' '.
         '/usr/local/php'.$vn.'/etc/php.ini');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i \'s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/\' '.
         '/usr/local/php'.$vn.'/etc/php.ini');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php'.$vn.'/etc/conf.d','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /usr/local/php'.$vn.'/etc/php-fpm.d','__display__');
      # https://myshell.co.uk/blog/2012/07/adjusting-child-processes-for-php-fpm-nginx/
      # find DNS server for domain:  dig ns getwisdom.com
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/www.conf /usr/local/php'.$vn.
         '/etc/php-fpm.d/www.conf','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v ./sapi/fpm/php-fpm.conf /usr/local/php'.$vn.'/etc',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s#;pid = run/php-fpm.pid#pid = /var/run/php-fpm.pid#" '.
         '/usr/local/php'.$vn.'/etc/php-fpm.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /var/run/php-fpm','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mkdir -vp /var/log/php-fpm','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s#;error_log = log/php-fpm.log#'.
         'error_log = /var/log/php-fpm/php-fpm.log#" '.
         '/usr/local/php'.$vn.'/etc/php-fpm.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s#;catch_workers_output = yes#'.
         'catch_workers_output = yes#" '.
         '/usr/local/php'.$vn.'/etc/php-fpm.d/www.conf');
      my $zend=<<END;
; Zend OPcache
extension=opcache.so
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$zend\" > ".
         '/usr/local/php'.$vn.'/etc/conf.d/modules.ini');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's#listen = 127.0.0.1:9000#".
         "listen = /var/run/php-fpm/www.sock#' ".
         '/usr/local/php'.$vn.'/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/^user = nobody/user = www-data/' ".
         '/usr/local/php'.$vn.'/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/^group = nobody/group = www-data/' ".
         '/usr/local/php'.$vn.'/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/\;env.PATH./env[PATH]/' ".
         '/usr/local/php'.$vn.'/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "sed -i 's/;listen.mode = 0660/listen.mode = 0666/' ".
         '/usr/local/php'.$vn.'/etc/php-fpm.d/www.conf');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ln -s /usr/local/php'.$vn.'/sbin/php-fpm /usr/sbin/php-fpm');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v /opt/source/php-src/sapi/fpm/php-fpm.service '.
         '/etc/systemd/system','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'sed -i "s#PIDFile=/usr/local/php'.$vn.'#PIDFile=#" '.
         '/etc/systemd/system/php-fpm.service');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl daemon-reload');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'systemctl enable php-fpm.service','__display__');
      sleep 2;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service php-fpm start','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'service php-fpm status -l','__display__');
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
         'wget --random-wait --progress=dot '.
         'http://curl.haxx.se/ca/cacert.pem '.
         '--output-document /usr/local/ssl/cert.pem',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/usr/local/php'.$vn.'/bin/pecl channel-update pecl.php.net',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget -qO- https://pecl.php.net/package/mailparse');
      $stdout=~s/^.*?get\/(mailparse-.*?).tgz.*$/$1/s;
      my $version=$stdout;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "/usr/local/php$vn/bin/pecl install $version",
         '__display__');
      $version='';
      ($stdout,$stderr)=$handle->cmd($sudo.
         'bash -c "echo extension=mailparse.so > '.
         '/usr/local/php'.$vn.'/etc/conf.d/mailparse.ini"');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget --random-wait --progress=dot '.
         'https://download.imagemagick.org/'.
         'ImageMagick/download/ImageMagick.zip',
         '__display__');
      sleep 2;
      ($stdout,$stderr)=$handle->cmd($sudo.
         'unzip -o ImageMagick.zip','__display__');
      ($stdout,$stderr)=$handle->cwd('ImageMag*');
      ($stdout,$stderr)=$handle->cmd($sudo.
         './configure --with-modules','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'make install','3600','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'ldconfig -v /usr/local/lib','__display__');
      ($stdout,$stderr)=$handle->cwd('/opt/source');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'wget -qO- https://pecl.php.net/package/imagick','300');
      $stdout=~s/^.*?get\/(imagick-.*?).tgz.*$/$1/s;
      $version=$stdout;
      $handle->print($sudo.
         "/usr/local/php$vn/bin/pecl install $version");
      $prompt=$handle->prompt();
      while (1) {
         my $output.=fetch($handle);
         last if $output=~/$prompt/;
         print $output;
         if (-1<index $output,'autodetect') {
            $handle->print('');
            $output='';
         } sleep 1;
      }
      sleep 2;
      ($stdout,$stderr)=$handle->cmd($sudo.'service php-fpm start',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.'service php-fpm status -l',
         '__display__');
   } elsif (-e '/opt/cpanel/ea-php70') {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'cp -v /opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf.default '.
         '/opt/cpanel/ea-php70/root/etc/php-fpm.d/www.conf','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '/etc/init.d/ea-php70-php-fpm start','__display__');
   } else {
      print "php is up to date.\n";
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
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd postfix --system --uid 4098 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'groupadd postdrop','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_postfix;
   sleep 5;
   # https://www.linuxbabe.com/redhat/run-your-own-email-server-centos-postfix-smtp-server
   # https://www.christianroessler.net/tech/2014/howto-server-debian-with-apache-phpfpm-virtual-postfix-dovecot-flatfiles-ssl-tls.html#9
   # https://astroman.org/blog/2017/04/e-mail-server-hosting-on-amazon-ec2/
   # https://noknow.info/it/os/install_dovecot_from_source?lang=en
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- http://ftp.porcupine.org/mirrors/postfix-release/index.html',
      '3600');
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
      'make makefiles CCARGS="-DUSE_TLS -DHAS_MYSQL -DUSE_SASL_AUTH '.
      '-DUSE_CYRUS_SASL -I/usr/include/sasl -I/usr/local/mysql/include/mysql" '.
      'AUXLIBS="-L/usr/lib -lsasl2 -lssl -lcrypto -Wl,-rpath /usr/local/mysql/lib" '.
      'AUXLIBS_MYSQL="-L/usr/local/mysql/lib -lmysqlclient -lz -lm"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','__display__');
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
      'mkdir -vp /etc/postfix/sql','__display__');
   my $mysql_virtual_domains_maps=<<END;
user = postfixadmin
password = $service_and_cert_password
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = postfixadmin
query = SELECT domain FROM domain WHERE domain='\\x25s' AND active = '1'
#query = SELECT domain FROM domain WHERE domain='\\x25s'
#optional query to use when relaying for backup MX
#query = SELECT domain FROM domain WHERE domain='\\x25s' AND backupmx = '0' AND active = '1'
#expansion_limit = 100
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$mysql_virtual_domains_maps\" > ".
      "${home_dir}mysql_virtual_domains_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_domains_maps.cf /etc/postfix/sql",
      '__display__');
   my $mysql_virtual_mailbox_maps=<<END;
user = postfixadmin
password = $service_and_cert_password
hosts = unix:/var/run/mysqld/mysqld.sock
dbname = postfixadmin
query = SELECT maildir FROM mailbox WHERE username='\\x25s' AND active = '1'
#expansion_limit = 100
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$mysql_virtual_mailbox_maps\" > ".
      "${home_dir}mysql_virtual_mailbox_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_mailbox_maps.cf /etc/postfix/sql",
      '__display__');
   my $mysql_virtual_alias_mailbox_maps=<<END;
user = postfixadmin
password = $service_and_cert_password
dbname = postfixadmin
query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '\\x25d' and mailbox.username = CONCAT('\\x25u', '\@', alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
hosts = unix:/var/run/mysqld/mysqld.sock
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$mysql_virtual_alias_mailbox_maps\" > ".
      "${home_dir}mysql_virtual_alias_mailbox_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_alias_mailbox_maps.cf /etc/postfix/sql",
      '__display__');
   my $mysql_virtual_alias_maps=<<END;
user = postfixadmin
password = $service_and_cert_password
dbname = postfixadmin
query = SELECT goto FROM alias WHERE address='\\x25s' AND active = '1'
#expansion_limit = 100
hosts = unix:/var/run/mysqld/mysqld.sock
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$mysql_virtual_alias_maps\" > ".
      "${home_dir}mysql_virtual_alias_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_alias_maps.cf /etc/postfix/sql",
      '__display__');
   my $mysql_virtual_alias_domain_maps=<<END;
user = postfixadmin
password = $service_and_cert_password
dbname = postfixadmin
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '\\x25d' and alias.address = CONCAT('\\x25u', '\@', alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
hosts = unix:/var/run/mysqld/mysqld.sock
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$mysql_virtual_alias_domain_maps\" > ".
      "${home_dir}mysql_virtual_alias_domain_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_alias_domain_maps.cf /etc/postfix/sql",
      '__display__');
   my $mysql_virtual_alias_domain_mailbox_maps=<<END;
user = postfixadmin
password = $service_and_cert_password
dbname = postfixadmin
query = SELECT maildir FROM mailbox,alias_domain WHERE alias_domain.alias_domain = '\\x25d' and mailbox.username = CONCAT('\\x25u', '\@', alias_domain.target_domain) AND mailbox.active = 1 AND alias_domain.active='1'
hosts = unix:/var/run/mysqld/mysqld.sock
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$mysql_virtual_alias_domain_mailbox_maps\" > ".
      "${home_dir}mysql_virtual_alias_domain_mailbox_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_alias_domain_mailbox_maps.cf ".
      "/etc/postfix/sql",'__display__');
   my $mysql_virtual_alias_domain_catchall_maps=<<END;
# handles catch-all settings of target-domain
user = postfixadmin
password = $service_and_cert_password
dbname = postfixadmin
query = SELECT goto FROM alias,alias_domain WHERE alias_domain.alias_domain = '\\x25d' and alias.address = CONCAT('\@', alias_domain.target_domain) AND alias.active = 1 AND alias_domain.active='1'
hosts = unix:/var/run/mysqld/mysqld.sock
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$mysql_virtual_alias_domain_catchall_maps\" > ".
      "${home_dir}mysql_virtual_alias_domain_catchall_maps.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v ${home_dir}mysql_virtual_alias_domain_catchall_maps.cf ".
      "/etc/postfix/sql",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 0640 /etc/postfix/sql/*','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v root:root /etc/postfix/sql/*','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'setfacl -R -m u:postfix:rx /etc/postfix/sql/','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd dovenull --system --uid 4099 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd dovecot --system --uid 5000 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'gpasswd -a dovecot mail','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd vmail --system --uid 2000 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -v /var/mail/vmail','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv vmail:vmail /var/mail/vmail/','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chcon -Rv -t mail_spool_t /var/mail/vmail/','__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'openssl req -new -outform PEM -out /etc/postfix/smtpd.cert '.
   #   '-newkey rsa:2048 -nodes -keyout /etc/postfix/smtpd.key '.
   #   '-keyform PEM -days 3650 -x509','__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'chmod -v 640 /etc/postfix/smtpd.key','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postfix start','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postfix reload','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postfix status','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "inet_interfaces = all"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "mydestination = mail.'.$domain_url.', \$myhostname, '.
      'localhost.\$mydomain, localhost"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "myhostname = mail.'.$domain_url.'"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "mydomain = mail.'.$domain_url.'"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "myorigin = mail.'.$domain_url.'"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "virtual_mailbox_base = /var/mail/vmail"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "virtual_minimum_uid = 2000"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "virtual_uid_maps = static:2000"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "virtual_gid_maps = static:2000"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'smtpd_sasl_auth_enable = yes\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'smtpd_helo_required = yes\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'broken_sasl_auth_clients = yes\'',
      '__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'postconf -e \'smtpd_sender_restrictions '.
   #   '= permit_mynetworks, permit_sasl_authenticated, '.
   #   'reject_unknown_sender_domain, '.
   #   'reject_unknown_reverse_client_hostname, '.
   #   'reject_unknown_client_hostname\'',
   #   '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'smtpd_recipient_restrictions '.
      '= permit_mynetworks, permit_sasl_authenticated, '.
      'reject_unauth_destination\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'smtpd_relay_restrictions '.
      '= permit_mynetworks, permit_sasl_authenticated, '.
      'defer_unauth_destination\'',
      '__display__');
   # https://serverfault.com/questions/803920/postfix-configure-to-use-tlsv1-2
   # https://www.howtoforge.com/howto_postfix_smtp_auth_tls_howto
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'smtpd_use_tls = yes\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "postconf -e \'smtpd_tls_cert_file = ".
      "/etc/letsencrypt/live/mail.$domain_url/fullchain.pem\'",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "postconf -e \'smtpd_tls_key_file = ".
      "/etc/letsencrypt/live/mail.$domain_url/privkey.pem\'",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'strict_rfc821_envelopes = yes\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'disable_vrfy_command = yes\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'mailbox_size_limit = 0\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'message_size_limit = 0\'',
      '__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'postconf -e \'proxy_read_maps = $local_recipient_maps '.
   #   '$mydestination $virtual_alias_maps $virtual_alias_domains '.
   #   '$virtual_mailbox_maps $virtual_mailbox_domains '.
   #   '$relay_recipient_maps $relay_domains $canonical_maps '.
   #   '$sender_canonical_maps $recipient_canonical_maps '.
   #   '$relocated_maps $transport_maps $mynetworks '.
   #   '$virtual_mailbox_limit_maps\'',
   #   '__display__');
   $ad=<<END;
mailbox_transport = lmtp:unix:private/dovecot-lmtp
smtputf8_enable = no
virtual_mailbox_domains = proxy:mysql:/etc/postfix/sql/mysql_virtual_domains_maps.cf
virtual_mailbox_maps =
   proxy:mysql:/etc/postfix/sql/mysql_virtual_mailbox_maps.cf,
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_mailbox_maps.cf
virtual_alias_maps =
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_maps.cf,
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_maps.cf,
   proxy:mysql:/etc/postfix/sql/mysql_virtual_alias_domain_catchall_maps.cf
virtual_transport = lmtp:unix:private/dovecot-lmtp
END
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v /etc/postfix/main.cf ~',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 777 ~/main.cf','__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" >> ".
      "~/main.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'$d\' ~/main.cf');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv ~/main.cf /etc/postfix/main.cf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v root:root /etc/postfix/main.cf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 644 /etc/postfix/main.cf',
      '__display__');
   if (ref $main::aws eq 'HASH') {
      ($stdout,$stderr)=$handle->cmd($sudo.
          'postconf -e '.
          '\'relayhost = [email-smtp.us-west-2.amazonaws.com]:587\' ',
          '\'smtp_sasl_auth_enable = yes\' '.
          '\'smtp_sasl_security_options = noanonymous\' '.
          '\'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd\' '.
          '\'smtp_use_tls = yes\' '.
          '\'smtp_tls_security_level = encrypt\' '.
          '\'smtp_tls_note_starttls_offer = yes\' '.
          '\'smtpd_tls_received_header = yes\'',
          '__display__');
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
      my ($hash,$output,$error)=('','','');
      my $c="aws iam list-access-keys --user-name ses_postfix_email";
      ($hash,$output,$error)=run_aws_cmd($c);
      $hash||={};
      foreach my $hash (@{$hash->{AccessKeyMetadata}}) {
         my $c="aws iam delete-access-key ".
               "--access-key-id $hash->{AccessKeyId} ".
               "--user-name ses_postfix_email";
         ($hash,$output,$error)=run_aws_cmd($c);
      }
      sleep 1;
      $c="aws iam delete-user --user-name ses_postfix_email";
      ($hash,$output,$error)=run_aws_cmd($c);
      $c="aws iam create-user --user-name ses_postfix_email";
      ($hash,$output,$error)=run_aws_cmd($c);
      $c="aws iam create-access-key --user-name ses_postfix_email";
      ($hash,$output,$error)=run_aws_cmd($c);
      $hash||={};
      my $access_id=$hash->{AccessKey}{AccessKeyId};
      my $secret_access_key=$hash->{AccessKey}{SecretAccessKey};
      my $python_smtp_generator=<<END;
#\\x21/usr/bin/env python3

import hmac
import hashlib
import base64
import argparse

SMTP_REGIONS = [
    'us-east-2',       # US East (Ohio)
    'us-east-1',       # US East (N. Virginia)
    'us-west-2',       # US West (Oregon)
    'ap-south-1',      # Asia Pacific (Mumbai)
    'ap-northeast-2',  # Asia Pacific (Seoul)
    'ap-southeast-1',  # Asia Pacific (Singapore)
    'ap-southeast-2',  # Asia Pacific (Sydney)
    'ap-northeast-1',  # Asia Pacific (Tokyo)
    'ca-central-1',    # Canada (Central)
    'eu-central-1',    # Europe (Frankfurt)
    'eu-west-1',       # Europe (Ireland)
    'eu-west-2',       # Europe (London)
    'sa-east-1',       # South America (Sao Paulo)
    'us-gov-west-1',   # AWS GovCloud (US)
]

# These values are required to calculate the signature. Do not change them.
DATE = \\x2211111111\\x22
SERVICE = \\x22ses\\x22
MESSAGE = \\x22SendRawEmail\\x22
TERMINAL = \\x22aws4_request\\x22
VERSION = 0x04


def sign(key, msg):
    return hmac.new(key, msg.encode('utf-8'), hashlib.sha256).digest()


def calculate_key(secret_access_key, region):
    if region not in SMTP_REGIONS:
        raise ValueError(f\\x22The {region} Region doesn't have an SMTP endpoint.\\x22)

    signature = sign((\\x22AWS4\\x22 + secret_access_key).encode('utf-8'), DATE)
    signature = sign(signature, region)
    signature = sign(signature, SERVICE)
    signature = sign(signature, TERMINAL)
    signature = sign(signature, MESSAGE)
    signature_and_version = bytes([VERSION]) + signature
    smtp_password = base64.b64encode(signature_and_version)
    return smtp_password.decode('utf-8')


def main():
    parser = argparse.ArgumentParser(
        description='Convert a Secret Access Key for an IAM user to an SMTP password.')
    parser.add_argument(
        'secret', help='The Secret Access Key to convert.')
    parser.add_argument(
        'region',
        help='The AWS Region where the SMTP password will be used.',
        choices=SMTP_REGIONS)
    args = parser.parse_args()
    print(calculate_key(args.secret, args.region))


if __name__ == '__main__':
    main()
END
      ($stdout,$stderr)=$handle->cmd(
         "echo -e \"$python_smtp_generator\" > ~/smtp_credentials_generate.py");
      ($stdout,$stderr)=$handle->cwd('~');
      my $smtppass='';
      ($smtppass,$stderr)=$handle->cmd(
         "python smtp_credentials_generate.py $secret_access_key us-west-2");
      my $sasl_password=<<"END";
[email-smtp.us-west-2.amazonaws.com]:587 $access_id:$smtppass
END
      ($stdout,$stderr)=$handle->cmd("echo -e \"$sasl_password\" > ".
         "sasl_passwd");
      ($stdout,$stderr)=$handle->cmd($sudo.
         'mv -v sasl_passwd /etc/postfix','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chown -v root:root /etc/postfix/sasl_passwd','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -vf ~/smtp_credentials_generate.py','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'postmap hash:/etc/postfix/sasl_passwd');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chown -v root:root /etc/postfix/sasl_passwd.db','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 0600 /etc/postfix/sasl_passwd '.
         '/etc/postfix/sasl_passwd.db','__display__');
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
         if ($policy->{PolicyName} eq 'sespolicy') {
            $c="aws iam detach-user-policy --user-name ses_postfix_email ".
               "--policy-arn $policy->{Arn}";
            ($hash,$output,$error)=run_aws_cmd($c);
            $c="aws iam delete-policy --policy-arn $policy->{Arn}";
            ($hash,$output,$error)=run_aws_cmd($c);
            last;
         }
      }
      $c="aws iam create-policy --policy-name sespolicy --policy-document ".
         "file://sespolicy";
      ($hash,$output,$error)=run_aws_cmd($c);
      my $policy_arn=$hash->{Policy}->{Arn};
      $c="aws iam attach-user-policy --user-name ses_postfix_email ".
         "--policy-arn $policy_arn";
      ($hash,$output,$error)=run_aws_cmd($c);
      ($stdout,$stderr)=$handle->cmd($sudo.
         'rm -rfv ./sespolicy','__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'smtp_tls_CAfile = /etc/ssl/certs/ca-bundle.crt\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'postscreen_access_list = '.
      'permit_mynetworks cidr:/etc/postfix/postscreen_access.cidr\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e \'postscreen_blacklist_action = drop\'',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'ifconfig');
   $stdout=~s/^.*?inet (.*?) .*$/$1/s;
   $ad=<<END;
#permit my own IP addresses.
$public_ip/32             permit
$stdout/32             permit
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" > ".
      "~/postscreen_access.cidr");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv ~/postscreen_access.cidr /etc/postfix',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v root:root /etc/postfix/postscreen_access.cidr',
      '__display__');
   $ad='submission inet n       -       -       -       -       smtpd%NL%'.
          '  -o syslog_name=postfix/submission%NL%'.
          '  -o smtpd_tls_security_level=encrypt%NL%'.
          '  -o smtpd_sasl_auth_enable=yes%NL%'.
          '  -o smtpd_sasl_type=dovecot%NL%'.
          '  -o smtpd_sasl_path=private/auth%NL%'.
          '  -o smtpd_reject_unlisted_recipient=no%NL%'.
          '  -o smtpd_client_restrictions=permit_sasl_authenticated,reject%NL%'.
          '  -o milter_macro_daemon_name=ORIGINATING%NL%'.
          'smtps     inet  n       -       -       -       -       smtpd%NL%'.
          '  -o syslog_name=postfix/smtps%NL%'.
          '  -o smtpd_tls_wrappermode=yes%NL%'.
          '  -o smtpd_sasl_auth_enable=yes%NL%'.
          '  -o smtpd_sasl_type=dovecot%NL%'.
          '  -o smtpd_sasl_path=private/auth%NL%'.
          '  -o smtpd_client_restrictions=permit_sasl_authenticated,reject%NL%'.
          '  -o milter_macro_daemon_name=ORIGINATING';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/tlsproxy/a$ad\' /etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/^smtp      inet/Xsmtp      inet/\' ".
       "/etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/#smtp      inet/smtp      inet/\' ".
       "/etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/#smtpd/smtpd/\' /etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/#dnsblog/dnsblog/\' /etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/#tlsproxy/tlsproxy/\' /etc/postfix/master.cf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/Xsmtp/#smtp/\' /etc/postfix/master.cf");
   # https://www.linode.com/community/questions/11498/postfix-does-not-start-correctly-on-linode-reboot-not-always
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
   $ad=<<'END';
[Unit]
Description=Postfix Mail Transport Agent
After=syslog.target network-online.target
Wants=network-online.target
Conflicts=sendmail.service exim.service

[Service]
Type=forking
PIDFile=/var/spool/postfix/pid/master.pid
EnvironmentFile=-/etc/sysconfig/network
#ExecStartPre=-/usr/libexec/postfix/aliasesdb
#ExecStartPre=-/usr/libexec/postfix/chroot-update
ExecStart=/usr/sbin/postfix start
ExecReload=/usr/sbin/postfix reload
ExecStop=/usr/sbin/postfix stop

[Install]
WantedBy=multi-user.target
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" > ".
      "~/postfix.service");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv ~/postfix.service /etc/systemd/system',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl daemon-reload');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable postfix.service','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postfix stop','__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service postfix start','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service postfix status -l','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install nmap','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install telnet','__display__');

#https://github.com/postfixadmin/postfixadmin/releases/latest

   my $install_postfixadmin=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


                        _    __ _                 _           _
        _ __   ___  ___| |_ / _(_)_  __  __ _  __| |_ __ ___ (_)_ __
       | '_ \ / _ \/ __| __| |_| \ \/ / / _` |/ _` | '_ ` _ \| | '_ \
       | |_) | (_) \__ \ |_|  _| |>  < | (_| | (_| | | | | | | | | | |
       | .__/ \___/|___/\__|_| |_/_/\_(_)__,_|\__,_|_| |_| |_|_|_| |_|
       |_|




       (postfix.admin is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_postfixadmin;
   sleep 5;

   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://github.com/postfixadmin/'.
      'postfixadmin/releases/latest');
   $stdout=~s/^.*?return_to.*?(postfixadmin-.*?)["].*$/$1/s;
   my $pfix=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://github.com/postfixadmin/postfixadmin'.
      "/archive/$pfix.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xvf $pfix.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -v *$pfix /var/www/html/postfixadmin",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/www/html/postfixadmin/templates_c',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -R www-data:www-data /var/www','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'find /var/www -type f');
   foreach my $file (split /\n/, $stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 644 '.$file,'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'find /var/www -type d');
   foreach my $dir (split /\n/, $stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 755 '.$dir,'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'setfacl -R -m u:www-data:rwx /var/www/html/postfixadmin/templates_c/',
      '__display__');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'chcon -t httpd_sys_rw_content_t '.
   #   '/var/www/html/postfixadmin/templates_c/ -R',
   #   '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'setsebool -P httpd_can_network_connect 1',
      '__display__');
   # sudo setfacl -R -m u:nginx:rwx /var/lib/php/opcache/
   # /var/lib/php/session/ /var/lib/php/wsdlcache/
   ($stdout,$stderr)=$handle->cmd($sudo.
      'setfacl -R -m u:www-data:rx /etc/letsencrypt/live/ '.
      '/etc/letsencrypt/archive/','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'php -r \'echo password_hash("'.$service_and_cert_password.
      '", PASSWORD_DEFAULT);\'');
   my $pfapassword=$stdout;
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
   $ad=<<END;
<?php
\\x24CONF['configured'] = true;
\\x24CONF['database_type'] = 'mysqli';
\\x24CONF['database_host'] = 'localhost';
\\x24CONF['database_port'] = '3306';
\\x24CONF['database_user'] = 'postfixadmin';
\\x24CONF['database_password'] = \'$service_and_cert_password\';
\\x24CONF['database_socket'] = '/var/run/mysqld/mysqld.sock';
\\x24CONF['database_name'] = 'postfixadmin';
\\x24CONF['encrypt'] = 'dovecot:SHA512';
\\x24CONF['dovecotpw'] = \\x22/usr/local/bin/doveadm pw -r 12\\x22;
\\x24CONF['setup_password'] = \'$pfapassword\';

\\x24CONF['default_aliases'] = array (
  'abuse'      => \'abuse\@$domain_url\',
  'hostmaster' => \'hostmaster\@$domain_url\',
  'postmaster' => \'postmaster\@$domain_url\',
  'webmaster'  => \'webmaster\@$domain_url\'
);

\\x24CONF['fetchmail'] = 'NO';
\\x24CONF['show_footer_text'] = 'NO';

\\x24CONF['quota'] = 'YES';
\\x24CONF['domain_quota'] = 'YES';
\\x24CONF['quota_multiplier'] = '1024000';
\\x24CONF['used_quotas'] = 'YES';
\\x24CONF['new_quota_table'] = 'YES';

\\x24CONF['aliases'] = '0';
\\x24CONF['mailboxes'] = '0';
\\x24CONF['maxquota'] = '0';
\\x24CONF['domain_quota_default'] = '0';
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" > ".
      "~/pfa_config");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv ~/pfa_config '.
      '/var/www/html/postfixadmin/config.local.php',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -R www-data:www-data /var/www/html/postfixadmin',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'bash /var/www/postfixadmin/scripts/postfixadmin-cli '.
      'admin add superadmin@'.$domain_url.' --superadmin 1 '.
      '--active 1 --password '.$service_and_cert_password.' --password2 '.
      $service_and_cert_password,'__display__');
   $ad=<<END;
    server {
        listen 80;
        listen [::]:80;
        server_name postfixadmin.$domain_url;

        root /var/www/html/postfixadmin/public/;
        index index.php index.html;

        access_log /var/log/nginx/postfixadmin_access.log;
        error_log /var/log/nginx/postfixadmin_error.log;

        location / {
            try_files \\x24uri \\x24uri/ /index.php;
        }

        location ~ ^/(.+\\x5C.php)\\x24 {
            try_files \\x24uri =404;
            fastcgi_pass unix:/run/php-fpm/www.sock;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME \\x24document_root\\x24fastcgi_script_name;
            include /etc/nginx/fastcgi_params;
        }
    }
}
END
   ($stdout,$stderr)=$handle->cmd(
      "cp -v /etc/nginx/nginx.conf ~/nginx.conf",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'sed -i "s/^}}/}/" ~/nginx.conf');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" >> ".
      "~/nginx.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/nginx.conf /etc/nginx/nginx.conf',
      '__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service nginx restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service nginx status -l','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'certbot -n --nginx --debug --agree-tos --email '.
      "$email_address -d postfixadmin.$domain_url",
      '__display__');

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
   $stdout=~s/^.*?Stable releases.*?[<]a href=["]([^"]+)?["]\s.*$/$1/s;
   $gtarfile=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".$stdout,
      '__display__');
   $gtarfile=~s/^.*\///;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar zxvf $gtarfile",'__display__');
   $gtarfile=~s/.tar.gz$//;
   ($stdout,$stderr)=$handle->cwd($gtarfile);
   ($stdout,$stderr)=$handle->cmd($sudo.
      '"LDFLAGS=-L/usr/local/lib64 -Wl,'.
      '-rpath /usr/local/lib64 -Wl,'.
      '-rpath /usr/local/mysql/lib" '.
      '"CFLAGS=-I/usr/local/openssl/include" '.
      './configure --localstatedir=/var '.
      '--with-mysql --with-ssl=openssl','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('doc/example-config');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v dovecot.conf /usr/local/etc/dovecot','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#protocols/protocols/\' ".
      "/usr/local/etc/dovecot/dovecot.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/lmtp submission/lmtp submission sieve/\' ".
      "/usr/local/etc/dovecot/dovecot.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#base_dir/base_dir/\' ".
      "/usr/local/etc/dovecot/dovecot.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mkdir -vp /usr/local/etc/dovecot/conf.d",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v conf.d/10-mail.conf /usr/local/etc/dovecot/conf.d",
      '__display__');
   $ad='mail_location = maildir:/var/mail/vmail/%d/%n/';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s*#mail_location =*$ad*\' ".
      "/usr/local/etc/dovecot/conf.d/10-mail.conf");
   $ad='mail_privileged_group = mail';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#mail_privileged_group =/$ad/\' ".
      "/usr/local/etc/dovecot/conf.d/10-mail.conf");
   $ad='mail_plugins = quota';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#mail_plugins =/$ad/\' ".
      "/usr/local/etc/dovecot/conf.d/10-mail.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v conf.d/10-auth.conf /usr/local/etc/dovecot/conf.d",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#disable_/disable_/\' ".
      "/usr/local/etc/dovecot/conf.d/10-auth.conf");
   $ad='auth_mechanisms = plain login';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/auth_mechanisms = plain/$ad/\' ".
      "/usr/local/etc/dovecot/conf.d/10-auth.conf");
   $ad='auth_username_format = %u';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#auth_username_format = %Lu/$ad\' ".
      "/usr/local/etc/dovecot/conf.d/10-auth.conf");
   $ad='!include auth-sql.conf.ext';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/#!include auth-sql.conf.ext/$ad/\' ".
      "/usr/local/etc/dovecot/conf.d/10-auth.conf");
   $ad='#!include auth-system.conf.ext';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s/!include auth-system.conf.ext/$ad/\' ".
      "/usr/local/etc/dovecot/conf.d/10-auth.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v /usr/local/etc/dovecot/conf.d/10-auth.conf ~',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 777 ~/10-auth.conf','__display__');
   $ad=<<END;
auth_debug = yes
auth_debug_passwords = yes
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/10-auth.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/10-auth.conf /usr/local/etc/dovecot/conf.d/10-auth.conf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v conf.d/auth-sql.conf.ext '.
      '/usr/local/etc/dovecot/conf.d',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i \'s#args = /etc#args = /usr/local/etc#\' ".
      "/usr/local/etc/dovecot/conf.d/auth-sql.conf.ext");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v dovecot-sql.conf.ext /usr/local/etc/dovecot',
      '__display__');
   $ad='%NL%'.
       'driver = mysql%NL%'.
       'connect = host=/var/run/mysqld/mysqld.sock dbname=postfixadmin '.
       "user=postfixadmin password=$service_and_cert_password%NL%".
       'default_pass_scheme = SHA512-CRYPT%NL%'.
       'password_query = SELECT username as user, '.
       'password FROM mailbox WHERE username=%SQ%%u%SQ% AND '.
       'active=%SQ%1%SQ%%NL%'.
       'user_query = SELECT maildir, 2000 AS uid, 2000 AS gid '.
       'FROM mailbox WHERE username = %SQ%%u%SQ% and '.
       'active=%SQ%1%SQ%%NL%'.
       'iterate_query = SELECT username AS user FROM mailbox';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/iterate_query/a$ad\' ".
       "/usr/local/etc/dovecot/dovecot-sql.conf.ext");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/usr/local/etc/dovecot/dovecot-sql.conf.ext");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SQ%/\'/g\" ".
       "/usr/local/etc/dovecot/dovecot-sql.conf.ext");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "chown -Rv vmail:dovecot /usr/local/etc/dovecot",
       '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "chmod -R o-rwx /usr/local/etc/dovecot",
       '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -v conf.d/10-master.conf ".
      "/usr/local/etc/dovecot/conf.d",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#ssl =/ssl =/g\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#port = 143/port = 0/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#port = 993/port = 993/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#port = 995/port = 995/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#port = 110/port = 0/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   $ad='unix_listener /var/spool/postfix/private/dovecot-lmtp';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s*unix_listener lmtp*$ad*\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"0,/#mode = 0666/{s/#mode = 0666/mode = 0600X/}\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"0,/#mode = 0666/{s/#mode = 0666/mode = 0660/}\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"0,/#user = /{s/#user =/user = postfix/}\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"0,/#group = /{s/#group =/group = postfix/}\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"/mode = 0600/a%SP%%SP%%SP%%SP%group = postfix\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SP%/ /g\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"/mode = 0600/a%SP%%SP%%SP%%SP%user = postfix\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#  mode = 0666/  mode = 0600X/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"0,/#}/ s/#}/X}/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"0,/#}/ s/#}/}/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/X}/#}/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   #($stdout,$stderr)=$handle->cmd($sudo.
   #    "sed -i \"/mode = 0600X/a%SP%%SP%%SP%%SP%user = vmail\" ".
   #    "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/0600X/0600/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#user = .default_internal_user/user = dovecot/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SP%/ /g\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   $ad='unix_listener /var/spool/postfix/private/auth';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s*unix_listener auth-userdb*$ad*\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   $ad='unix_listener auth-userdb';
   my $bd='#unix_listener /var/spool/postfix/private/auth';
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s*$bd*$ad*\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#user = root/user = vmail/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#port = 587/port = 8587/\" ".
       "/usr/local/etc/dovecot/conf.d/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "cp -v conf.d/auth-system.conf.ext ".
       "/usr/local/etc/dovecot/conf.d",
       '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "cp -v conf.d/10-ssl.conf ".
       "/usr/local/etc/dovecot/conf.d",
       '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/#ssl = yes/ssl = required/\" ".
       "/usr/local/etc/dovecot/conf.d/10-ssl.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s*ssl/certs/dovecot.pem*".
       "letsencrypt/live/mail.$domain_url/fullchain.pem*\" ".
       "/usr/local/etc/dovecot/conf.d/10-ssl.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s*ssl/private/dovecot.pem*".
       "letsencrypt/live/mail.$domain_url/privkey.pem*\" ".
       "/usr/local/etc/dovecot/conf.d/10-ssl.conf");
   $ad=<<END;

service stats {
    unix_listener stats-reader {
    user = www-data
    group = www-data
    mode = 0660
}

unix_listener stats-writer {
    user = www-data
    group = www-data
    mode = 0660
  }
}
END
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v /usr/local/etc/dovecot/conf.d/10-master.conf ~',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 777 ~/10-master.conf','__display__');
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/10-master.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/10-master.conf /usr/local/etc/dovecot/conf.d/10-master.conf',
      '__display__');
   my $name=getpwuid($<);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "gpasswd -a $name dovecot",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ls -1 /usr/local/etc/dovecot/conf.d");
   foreach my $file (split /\n/, $stdout) {
      next if $file=~/\.+$/;
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chmod -v 660 /usr/local/etc/dovecot/conf.d/$file",
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         "chown -v vmail:dovecot /usr/local/etc/dovecot/conf.d/$file",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      "gpasswd -d $name dovecot",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'gpasswd -a www-data dovecot','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'gpasswd -a www-data vmail','__display__');
   ($stdout,$stderr)=$handle->cwd("/opt/source/$gtarfile");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/run/dovecot','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v dovecot.service.in /etc/systemd/system/dovecot.service',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#PIDFile=/usr/local#PIDFile=#" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s*.sbindir.*/usr/local/sbin*" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s/#ProtectSystem/ProtectSystem/" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s*.bindir.*/usr/local/bin*" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s*.rundir.*/var/run/dovecot*" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s*@systemdservicetype@*simple*" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "/ExecStop/iKillMode=none" '.
      '/etc/systemd/system/dovecot.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl daemon-reload');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable saslauthd.service','__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service saslauthd restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service saslauthd status -l','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable dovecot.service'.'__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service dovecot restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service dovecot status -l','__display__');
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
     88d888 .d88b. 888  88888888b.  .d88888 .d8888b888  88888888b.  .d88b.
    888P"  d88""88b888  888888 "88bd88" 888d88P"   888  888888 "88bd8P  Y8b
    888    888  888888  888888  888888  888888     888  888888  88888888888
    888    Y88..88PY88b 888888  888Y88b 888Y88b.   Y88b 888888 d88PY8b.
    888     "Y88P"  "Y88888888  888 "Y88888 "Y8888P "Y8888888888P"  "Y8888


          (roundcube is **NOT** a sponsor of the FullAuto© Project.)


END
   # http://charmingwebdesign.com/setup-roundcube-use-amazon-ses-send-email/
   # https://astroman.org/blog/2017/04/e-mail-server-hosting-on-amazon-ec2/
   # https://speedkills.io/email-server-aws/
   # https://www.linode.com/community/questions/10148/postfix-dovecot-mysql-amazon-ses
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_roundcube;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://roundcube.net/download/');
   $stdout=~s/^.*?Stable version.*?href=["](https[^"]+)?["].*$/$1/s;
   $gtarfile=$stdout;
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
      'cp -v composer.json-dist composer.json','__display__');
   $handle->print($sudo.'php composer-stable.phar install --no-dev');
   $prompt=$handle->prompt();
   while (1) {
      my $output.=fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'user') {
         $handle->print('yes');
         $output='';
      } sleep 1;
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'bin/install-jsdeps.sh','__display__');
   my $rcfile='./SQL/mysql.initial.sql';
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mysql --verbose --force -u roundcube -p'.
      "'".$service_and_cert_password."' roundcube < $rcfile",
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/www/html/roundcube','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cp -Rv $gtarfile/* /var/www/html/roundcube",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -R www-data:www-data /var/www/html/roundcube',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'find /var/www/html/roundcube -type f');
   foreach my $file (split /\n/, $stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 644 '.$file,'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'find /var/www -type d');
   foreach my $dir (split /\n/, $stdout) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'chmod -v 755 '.$dir,'__display__');
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      'gpasswd -a www-data mysql','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "setfacl -R -m u:www-data:rwx /var/www/html/roundcube/temp/ ".
      "/var/www/html/roundcube/logs/",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -vp /var/www/html/roundcube/config/config.inc.php.sample '.
      '/var/www/html/roundcube/config/config.inc.php','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -vp /var/www/html/roundcube/plugins/managesieve/config.inc.php.dist '.
      '/var/www/html/roundcube/plugins/managesieve/config.inc.php',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s/_vacation\'\] = 0/_vacation\'\] = 1/" '.
      '/var/www/html/roundcube/plugins/managesieve/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s/_forward\'\] = 0/_forward\'\] = 1/" '.
      '/var/www/html/roundcube/plugins/managesieve/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/mail/vmail/pgp-keys','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v vmail:vmail /var/mail/vmail/pgp-keys',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 775 /var/mail/vmail/pgp-keys',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -vp /var/www/html/roundcube/plugins/enigma/config.inc.php.dist '.
      '/var/www/html/roundcube/plugins/enigma/config.inc.php',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -vp /var/www/html/roundcube/plugins/markasjunk/config.inc.php.dist '.
      '/var/www/html/roundcube/plugins/markasjunk/config.inc.php',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#_pgp_homedir\'\] = null;#_pgp_homedir\'\]'.
      ' = \'/var/mail/vmail/pgp-keys\';#" '.
      '/var/www/html/roundcube/plugins/enigma/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "/zipdownload/a%SP%%SP%%SP%%SP%\'managesieve\'," '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "/managesieve/a%SP%%SP%%SP%%SP%\'enigma\'," '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "/enigma/a%SP%%SP%%SP%%SP%\'markasjunk\'," '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SP%/ /g\" ".
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#roundcube:pass#roundcube:'.$service_and_cert_password.
      '#" /var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#roundcubemail#roundcube#" '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#localhost\'#ssl://mail.'.$domain_url.'\'#" '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#= 587# = 465#" '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#Roundcube Webmail#GetWisdom Webmail#" '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#\'\'#\'https://www.getwisdom.com/contact-us\'#" '.
      '/var/www/html/roundcube/config/config.inc.php');
   my $p_wrd=
      $Net::FullAuto::ISets::Local::EmailServer_is::create_strong_password->(24);
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i "s#rcmail-\!24ByteDESkey\*Str#'.$p_wrd.'#" '.
      '/var/www/html/roundcube/config/config.inc.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear channel-update pear.php.net',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install Mail_Mime',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install Net_SMTP',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php7/bin/pear install '.
      'channel://pear.php.net/Net_IDNA2-0.2.0',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install Auth_SASL',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install '.
      'channel://pear.php.net/Auth_SASL2-0.2.0',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install Net_Sieve',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install '.
      'channel://pear.horde.org/Horde_ManageSieve',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/php'.$vn.'/bin/pear install Crypt_GPG',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service php-fpm stop','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service nginx restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service nginx status -l','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service php-fpm restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service php-fpm status -l','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'crontab -u www-data -l | { cat; echo "18 11 * * * '.
      '/var/www/html/roundcube/bin/cleandb.sh"; } | '.
      'sudo crontab -u www-data -','__display__');

   my $install_redis=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


                                        ###  ###
                    ######    ####      ###       ####
                    ####### ###  ##  ######  ### ### ##
                    ###  ## ### ### #######  ###  ###
                    ###     ###     ##  ###  ###   ###
                    ###     ####### #######  ### ## ###
                    ###       ####   ###### ####  ####


          (redis is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_redis;
   sleep 5;
   my $done=0;my $gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --recursive https://github.com/redis/redis.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('redis');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git tag --list');
   $stdout=~s/^.*[^v](\d+\.\d+\.\d+)\s.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "git checkout $stdout");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "git status",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make CFLAGS="-I/usr/local/include/openssl" '.
      'LDFLAGS="-L/usr/local/lib64" '.
      'BUILD_TLS=yes USE_SYSTEMD=yes','__display__');
   ($stdout,$stderr)=$handle->cwd('src');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cc -pedantic -DREDIS_STATIC= -std=c11 -Wall -W '.
      '-Wno-missing-field-initializers -O2 -g -ggdb '.
      '-I../deps/lua/src -I../deps/hiredis '.
      '-I/usr/local/include/openssl -MMD -o '.
      'sentinel.o -c sentinel.c',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/redis');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make CFLAGS="-I/usr/local/include/openssl" '.
      'LDFLAGS="-L/usr/local/lib64" '.
      'BUILD_TLS=yes USE_SYSTEMD=yes','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make install",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '/information/avm.overcommit_memory = 1' /etc/sysctl.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sysctl vm.overcommit_memory=1');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "sed -i '/overcommit/anet.core.somaxconn=65535' /etc/sysctl.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sysctl net.core.somaxconn=65535');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd redis --system --uid 5002 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /usr/local/var/lib/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v redis:redis /usr/local/var/lib/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /usr/local/var/log/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v redis:redis /usr/local/var/log/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /usr/local/var/run/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v redis:redis /usr/local/var/run/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /usr/local/etc/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v redis:redis /usr/local/etc/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v redis.conf /usr/local/etc/redis','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/run/redis','__display__');
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

   my $redis_service=<<'END';
# example systemd service unit file for redis-server
#
# In order to use this as a template for providing a redis service in your
# environment, _at the very least_ make sure to adapt the redis configuration
# file you intend to use as needed (make sure to set \\x22supervised systemd\\x22), and
# to set sane TimeoutStartSec and TimeoutStopSec property values in the unit's
# \\x22[Service]\\x22 section to fit your needs.
#
# Some properties, such as User= and Group=, are highly desirable for virtually
# all deployments of redis, but cannot be provided in a manner that fits all
# expectable environments. Some of these properties have been commented out in
# this example service unit file, but you are highly encouraged to set them to
# fit your needs.
#
# Please refer to systemd.unit(5), systemd.service(5), and systemd.exec(5) for
# more information.

[Unit]
Description=Redis data structure server
Wants=network-online.target
After=network-online.target
Documentation=http://redis.io/documentation, man:redis-server(1)

[Service]
Type=notify
ExecStart=/usr/local/bin/redis-server /usr/local/etc/redis/redis.conf --supervised systemd --daemonize no
ExecStop=/bin/kill -s TERM \\x24MAINPID
PIDFile=/var/run/redis/redis.pid
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=2755
TimeoutStopSec=90
TimeoutStartSec=90
UMask=0077
PrivateTmp=yes
NoNewPrivileges=yes
LimitNOFILE=65535
PrivateDevices=yes
ProtectHome=yes
ReadOnlyDirectories=/
WorkingDirectory=/usr/local/var/lib/redis
ReadWriteDirectories=-/usr/local/var/lib/redis
ReadWriteDirectories=-/usr/local/var/log/redis
ReadWriteDirectories=-/usr/local/var/run/redis

NoNewPrivileges=true
CapabilityBoundingSet=CAP_SETGID CAP_SETUID CAP_SYS_RESOURCE

#MemoryDenyWriteExecute=true
#ProtectKernelModules=true
#ProtectKernelTunables=true
#ProtectControlGroups=true
#RestrictRealtime=true
#RestrictNamespaces=true

RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

ProtectSystem=true
ReadWriteDirectories=-/usr/local/etc/redis

[Install]
WantedBy=multi-user.target
Alias=redis.service
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$redis_service\" > ".
      "~/redis.service");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv ~/redis.service /etc/systemd/system',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl daemon-reload');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable redis.service','__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service redis start','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service redis status -l','__display__');

   ($stdout,$stderr)=$handle->cwd('/opt/source');
   my $install_unbound=<<'END';


          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


     ##     ## ##    ## ########   #######  ##     ## ##    ## ########
     ##     ## ###   ## ##     ## ##     ## ##     ## ###   ## ##     ##
     ##     ## ####  ## ##     ## ##     ## ##     ## ####  ## ##     ##
     ##     ## ## ## ## ########  ##     ## ##     ## ## ## ## ##     ##
     ##     ## ##  #### ##     ## ##     ## ##     ## ##  #### ##     ##
     ##     ## ##   ### ##     ## ##     ## ##     ## ##   ### ##     ##
      #######  ##    ## ########   #######   #######  ##    ## ########


          (unbound is **NOT** a sponsor of the FullAuto© Project.)


END
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_unbound;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://nlnetlabs.nl/projects/unbound/about/');
   $stdout=~s/^.*most-recent-version.*?href=["]([^"]+)["].*$/$1/s;
   my $utarfile=$stdout;
   $utarfile=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      "https://nlnetlabs.nl/$stdout",
      '__display__');
   $utarfile=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xvf $utarfile",'__display__');
   $utarfile=~s/\.tar\.gz$//;
   ($stdout,$stderr)=$handle->cwd($utarfile);
   ($stdout,$stderr)=$handle->cmd($sudo.'pwd','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -v unbound.build','__display__');
   ($stdout,$stderr)=$handle->cwd('unbound.build');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '../configure  LDFLAGS="-Wl,-rpath /usr/local/lib -Wl,'.
      '-rpath /usr/local/lib64"','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','3600','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v ./contrib/libunbound.pc /usr/local/lib/pkgconfig',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ldconfig -v','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v ./contrib/unbound.service /etc/systemd/system',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'1,/NotifyAccess=/!d\' '.
      '/etc/systemd/system/unbound.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'s/=+/=/\' '.
      '/etc/systemd/system/unbound.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl daemon-reload');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd unbound --system --uid 5003 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'s/nameserver/#nameserver/\' '.
      '/etc/resolv.conf');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'/nameserver/anameserver 127.0.0.1\' '.
      '/etc/resolv.conf');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable unbound.service','__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service unbound restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service unbound status -l','__display__');

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
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --recursive https://github.com/vstakhov/rspamd.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   # https://ninja-build.org/
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone git://github.com/ninja-build/ninja.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('ninja');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'git checkout release','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/cmake -Bbuild-cmake -H.','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/cmake --build build-cmake','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v ./build-cmake/ninja /usr/local/bin','__display__');
   # https://developer.gnome.org/glib/stable/glib-building.html
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --recursive https://gitlab.gnome.org/GNOME/glib.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('glib');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'PATH=/usr/local/bin:$PATH /usr/local/bin/meson _build',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'PATH=/usr/local/bin:$PATH /usr/local/bin/ninja -C _build install',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp ./_build/glib/glibconfig.h /usr/local/include/glib-2.0/',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- http://www.colm.net/open-source/ragel/');
   $stdout=~s/^.*?Stable.*?href=["](.*?)["].*$/$1/s;
   $gtarfile=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot http://www.colm.net".$stdout,
      '__display__');
   $gtarfile=~s/^.*\///;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xvf $gtarfile",'__display__');
   $gtarfile=~s/^(.*)[.]tar.*$/$1/;
   ($stdout,$stderr)=$handle->cwd($gtarfile);
   ($stdout,$stderr)=$handle->cmd($sudo.
      "./configure",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "make install",'__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://luajit.org/git/luajit-2.0.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('luajit-2.0');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone --recursive https://github.com/boostorg/boost.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('boost');
   my $boost_tag='';
   foreach my $tag (reverse split /\n/, $stdout) {
      $boost_tag=$tag;
      last unless $tag=~/beta/;
   }
   ($stdout,$stderr)=$handle->cmd($sudo.
      "git checkout $boost_tag",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      './bootstrap.sh','3600','__display__');
   ($stdout,$stderr)=clean_filehandle($handle);
   ($stdout,$stderr)=$handle->cmd($sudo.
      './b2 install','3600','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/intel/hyperscan.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('hyperscan');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/cmake -DCMAKE_POSITION_INDEPENDENT_CODE=ON .',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','3600','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/file/file.git '.
         'libmagic','__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('libmagic');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'aclocal -I .','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'libtoolize --copy --force');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'autoreconf -ifv','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      './configure','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','3600','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   #($stdout,$stderr)=$handle->cwd('/opt/source');
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'wget -qO- http://site.icu-project.org/download');
   #$stdout=~s/^.*[<]i[>]ICU (.*?) is now available.*$/$1/s;
   #$stdout=~s/\./-/g;
   #($stdout,$stderr)=$handle->cmd($sudo.
   #   'git clone https://github.com/unicode-org/icu.git '.
   #   "--depth=1 --branch=release-$stdout",'__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cwd('rspamd');
   ($stdout,$stderr)=$handle->cmd($sudo.'git -P tag -l');
   $stdout=~s/^.*\n(.*)$/$1/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "git checkout $stdout",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -v rspamd.build','__display__');
   ($stdout,$stderr)=$handle->cwd('rspamd.build');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/cmake .. -DENABLE_HYPERSCAN=ON -DENABLE_LUAJIT=ON '.
      '-DCMAKE_BUILD_TYPE=RelWithDebuginfo '.
      '-DCMAKE_CXX_COMPILER=/usr/local/bin/g++ '.
      '-DCMAKE_C_COMPILER=/usr/local/bin/gcc '.
      '-DCMAKE_INSTALL_RPATH=/usr/local/lib64 '.
      '-DOPENSSL_ROOT_DIR=/usr/local/include/openssl',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','3600','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   # https://linuxize.com/post/install-and-integrate-rspamd/
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'/include/a\/usr/local/lib64\' /etc/ld.so.conf');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ldconfig -v','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /usr/local/etc/rspamd/local.d','__display__');
   $ad='use = ["x-spamd-bar", "x-spam-level", "authentication-results"];';
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" > ".
      "~/milter_headers.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv ~/milter_headers.conf /usr/local/etc/rspamd/local.d',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v ../rspamd.service /etc/systemd/system','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'s#/usr/bin#/usr/local/bin#\' '.
      '/etc/systemd/system/rspamd.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sed -i \'s#/etc#/usr/local/etc#\' '.
      '/etc/systemd/system/rspamd.service');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'useradd _rspamd --system --uid 5004 -s /usr/bin/nologin '.
      '--user-group --no-create-home');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/log/rspamd','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v _rspamd:_rspamd /var/log/rspamd','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/lib/rspamd','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -v _rspamd:_rspamd /var/lib/rspamd','__display__');
   ($stdout,$stderr)=$handle->cmd(
      'echo -e "bind_socket = \\x22127.0.0.1:11333\\x22;" > ~/wn.inc');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/wn.inc /usr/local/etc/rspamd/local.d/worker-normal.inc',
      '__display__');
   my $wp_inc=<<END;
bind_socket = \\x22127.0.0.1:11332\\x22;
milter = yes;
timeout = 120s;
upstream \\x22local\\x22 {
  default = yes;
  self_scan = yes;
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$wp_inc\" > ~/wp.inc");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/wp.inc /usr/local/etc/rspamd/local.d/worker-proxy.inc',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "/usr/local/bin/rspamadm pw --encrypt -p ".
      $service_and_cert_password);
   $stdout=~s#\$#\\\\x24#g;
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"password = \\x22$stdout\\x22;\" > ~/wc.inc");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/wc.inc /usr/local/etc/rspamd/local.d/worker-controller.inc',
      '__display__');
   my $cb_conf=<<END;
servers = \\x22127.0.0.1\\x22;
backend = \\x22redis\\x22;
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$cb_conf\" > ~/cb.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/cb.conf /usr/local/etc/rspamd/local.d/classifier-bayes.conf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "milter_protocol = 6"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "milter_mail_macros = i {mail_addr} '.
      '{client_addr} {client_name} {auth_authen}"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "milter_default_action = accept"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "smtpd_milters = inet:127.0.0.1:11332"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'postconf -e "non_smtpd_milters = inet:127.0.0.1:11332"',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service postfix restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service postfix status -l','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget -qO- https://pigeonhole.dovecot.org/download.html');
   $stdout=~s/^.*?Stable releases.*?href=["]([^"]+)["].*$/$1/s;
   my $pg_rl=$stdout;
   $pg_rl=~s/^.*\///;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      $stdout,'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xvf $pg_rl",'__display__');
   $pg_rl=~s/.tar.gz$//;
   ($stdout,$stderr)=$handle->cwd($pg_rl);
   ($stdout,$stderr)=$handle->cmd($sudo.
      './configure','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make install','__display__');
   $ad=<<END;
protocol lmtp {
  postmaster_address = postmaster\@$domain_url
  mail_plugins = \\x24mail_plugins quota sieve
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/20-lmtp.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/20-lmtp.conf /usr/local/etc/dovecot/conf.d/20-lmtp.conf',
      '__display__');
   $ad=<<END;
namespace inbox {
  inbox = yes
  location =
  mailbox Archive {
    auto = subscribe
    special_use = \\x5CArchive
  }
  mailbox Drafts {
    auto = subscribe
    special_use = \\x5CDrafts
  }
  mailbox Spam {
    special_use = \\x5CJunk
    auto = subscribe
  }
  mailbox Junk {
    auto = subscribe
    special_use = \\x5CJunk
  }
  mailbox Sent {
    auto = subscribe
    special_use = \\x5CSent
  }
  mailbox Trash {
    auto = subscribe
    special_use = \\x5CTrash
  }
  prefix =
  separator = /
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/15-mailboxes.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/15-mailboxes.conf '.
      '/usr/local/etc/dovecot/conf.d/15-mailboxes.conf',
      '__display__');
   $ad=<<END;
plugin {
  quota = dict:User quota::proxy::sqlquota
  quota_rule = \\x2A:storage=5GB
  quota_rule2 = Trash:storage=+100M
  quota_grace = 10\\x25\\x25
  quota_exceeded_message = Quota exceeded, please contact your system administrator.
  quota_warning = storage=100\\x25\\x25 quota-warning 100 \\x25u
  quota_warning2 = storage=95\\x25\\x25 quota-warning 95 \\x25u
  quota_warning3 = storage=90\\x25\\x25 quota-warning 90 \\x25u
  quota_warning4 = storage=85\\x25\\x25 quota-warning 85 \\x25u
}

service quota-warning {
  executable = script /usr/local/bin/quota-warning.sh
  user = vmail

  unix_listener quota-warning {
    group = vmail
    mode = 0660
    user = vmail
  }
}

dict {
  sqlquota = mysql:/usr/local/etc/dovecot/dovecot-dict-sql.conf.ext
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/90-quota.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/90-quota.conf '.
      '/usr/local/etc/dovecot/conf.d/90-quota.conf',
      '__display__');
   $ad=<<END;
#\\x21/bin/sh
PERCENT=\\x241
USER=\\x242
cat << EOF | /usr/lib/dovecot/dovecot-lda -d \\x24USER -o \\x22plugin/quota=dict:User quota::noenforcing:proxy::sqlquota\\x22
From: postmaster\@$domain_url
Subject: Quota warning

Your mailbox is now \\x24PERCENT\\x25 full.
EOF
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/quota-warning.sh");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/quota-warning.sh /usr/local/bin/quota-warning.sh',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v +x /usr/local/bin/quota-warning.sh',
      '__display__');
   $ad=<<END;
connect = host=/var/run/mysqld/mysqld.sock dbname=postfixadmin user=postfixadmin password=$service_and_cert_password
map {
  pattern = priv/quota/storage
  table = quota2
  username_field = username
  value_field = bytes
}
map {
  pattern = priv/quota/messages
  table = quota2
  username_field = username
  value_field = messages
}
# map {
#   pattern = shared/expire/\\x24user/\\x24mailbox
#   table = expires
#   value_field = expire_stamp
#
#   fields {
#     username = \\x24user
#     mailbox = \\x24mailbox
#   }
# }
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/dovecot-dict-sql.conf.ext");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/dovecot-dict-sql.conf.ext '.
      '/usr/local/etc/dovecot/conf.d/dovecot-dict-sql.conf.ext',
      '__display__');
   $ad=<<END;
protocol imap {
  mail_plugins = \\x24mail_plugins imap_quota imap_sieve
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/20-imap.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/20-imap.conf '.
      '/usr/local/etc/dovecot/conf.d/20-imap.conf',
      '__display__');
   $ad=<<END;
service managesieve-login {
  inet_listener sieve {
    port = 4190
  }
}
service managesieve {
  process_limit = 1024
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/20-managesieve.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/20-managesieve.conf '.
      '/usr/local/etc/dovecot/conf.d/20-managesieve.conf',
      '__display__');
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
   $ad=<<END;
plugin {
    sieve = file:~/sieve;active=~/.dovecot.sieve
    sieve_plugins = sieve_imapsieve sieve_extprograms
    sieve_before = /var/mail/vmail/sieve/global/spam-global.sieve
    sieve = file:/var/mail/vmail/sieve/\\x25d/\\x25n/scripts;active=/var/mail/vmail/sieve/\\x25d/\\x25n/active-script.sieve

    imapsieve_mailbox1_name = Spam
    imapsieve_mailbox1_causes = COPY
    imapsieve_mailbox1_before = file:/var/mail/vmail/sieve/global/report-spam.sieve

    imapsieve_mailbox2_name = \\x2A
    imapsieve_mailbox2_from = Spam
    imapsieve_mailbox2_causes = COPY
    imapsieve_mailbox2_before = file:/var/mail/vmail/sieve/global/report-ham.sieve

    sieve_pipe_bin_dir = /usr/bin
    sieve_global_extensions = +vnd.dovecot.pipe
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/90-sieve.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/90-sieve.conf '.
      '/usr/local/etc/dovecot/conf.d/90-sieve.conf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/mail/vmail/sieve/global','__display__');
   $ad=<<END;
require [\\x22fileinto\\x22,\\x22mailbox\\x22];

if anyof(
    header :contains [\\x22X-Spam-Flag\\x22] \\x22YES\\x22,
    header :contains [\\x22X-Spam\\x22] \\x22Yes\\x22,
    header :contains [\\x22Subject\\x22] \\x22\\x2A\\x2A\\x2A SPAM \\x2A\\x2A\\x2A\\x22
    )
{
    fileinto :create \\x22Spam\\x22;
    stop;
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/spam-global.sieve");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/spam-global.sieve '.
      '/var/mail/vmail/sieve/global/spam-global.sieve',
      '__display__');
   $ad=<<END;
require [\\x22vnd.dovecot.pipe\\x22, \\x22copy\\x22, \\x22imapsieve\\x22];
pipe :copy \\x22rspamc\\x22 [\\x22learn_spam\\x22];
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/report-spam.sieve");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/report-spam.sieve '.
      '/var/mail/vmail/sieve/global/report-spam.sieve',
      '__display__');
   $ad=<<END;
require [\\x22vnd.dovecot.pipe\\x22, \\x22copy\\x22, \\x22imapsieve\\x22];
pipe :copy \\x22rspamc\\x22 [\\x22learn_ham\\x22];
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/report-ham.sieve");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/report-ham.sieve '.
      '/var/mail/vmail/sieve/global/report-ham.sieve',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service dovecot restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service dovecot status -l','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/sievec '.
      '/var/mail/vmail/sieve/global/spam-global.sieve',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/sievec '.
      '/var/mail/vmail/sieve/global/report-spam.sieve',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/sievec '.
      '/var/mail/vmail/sieve/global/report-ham.sieve',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv vmail: /var/mail/vmail/sieve/',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mkdir -vp /var/lib/rspamd/dkim/','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      '/usr/local/bin/rspamadm dkim_keygen -b 2048 -s mail -k '.
      '/var/lib/rspamd/dkim/mail.key | sudo tee -a '.
      '/var/lib/rspamd/dkim/mail.pub','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chown -Rv _rspamd: /var/lib/rspamd/dkim',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 440 /var/lib/rspamd/dkim/*','__display__');
   $ad=<<END;
selector = \\x22mail\\x22;
path = \\x22/var/lib/rspamd/dkim/\\x24selector.key\\x22;
allow_username_mismatch = true;
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" >> ~/dkim_signing.conf");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v ~/dkim_signing.conf '.
      '/usr/local/etc/rspamd/local.d/dkim_signing.conf',
      '__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v /usr/local/etc/rspamd/local.d/dkim_signing.conf '.
      '/usr/local/etc/rspamd/local.d/arc.conf',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable rspamd.service','__display__');
   sleep 2;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service rspamd restart','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'service rspamd status -l','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $done=0;$gittry=0;
   while ($done==0) {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'git clone https://github.com/YJesus/Unhide.git',
         '__display__');
      if (++$gittry>5) {
         print "\n\n   FATAL ERROR: $stderr\n\n";
         cleanup();
      }
      my $gittest='Connection reset by peer|'.
                  'Could not read from remote repository';
      $done=1 if $stderr!~/$gittest/s;
      last if $done;
      sleep 30;
   }
   ($stdout,$stderr)=$handle->cwd('Unhide');
   ($stdout,$stderr)=$handle->cmd(
      'sudo /usr/local/bin/gcc -Wall -O2 -l:libpthread.so '.
      'unhide-linux*.c unhide-output.c -o unhide-linux',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'sudo /usr/local/bin/gcc -Wall -O2 unhide_rb.c -o unhide_rb',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'sudo /usr/local/bin/gcc -Wall -O2 unhide-tcp.c '.
      'unhide-tcp-fast.c unhide-output.c  -o unhide-tcp',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'sudo /usr/local/bin/gcc -Wall -O2 unhide-posix.c -o unhide-posix',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v unhide-linux unhide_rb unhide-tcp unhide-posix /usr/bin',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/usr/bin');
   ($stdout,$stderr)=$handle->cmd($sudo.'ln -s unhide-linux unhide');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   # https://salsa.debian.org/pkg-security-team/rkhunter/blob/debian/master/debian/README.Debian#L108
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://dvgevers.home.xs4all.nl/skdet/skdet-1.0.tar.bz2",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'tar xvf skdet-1.0.tar.bz2','__display__');
   ($stdout,$stderr)=$handle->cwd('skdet-1.0/src');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://dvgevers.home.xs4all.nl/skdet/skdet-fix-includes.diff');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'patch --verbose --force skdet.c <skdet-fix-includes.diff',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'patch --verbose --force usage.c <skdet-fix-includes.diff',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('..');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make clean','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'make','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cp -v skdet /usr/bin','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "-O rkhunter.tar.gz https://sourceforge.net/".
      "projects/rkhunter/files/latest/download",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'tar xvf rkhunter.tar.gz','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.'ls -1');
   $stdout=~s/^.*(rkhunter-.*?)\n.*$/$1/s;
   ($stdout,$stderr)=$handle->cwd($stdout);
   ($stdout,$stderr)=$handle->cmd($sudo.
      './installer.sh --install','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rkhunter --propupd','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "cat /var/lib/rspamd/dkim/mail.pub");
   $stdout=~s/^.*?["](.*)["].*$/$1/s;
   $stdout=~s/\n//g;
   $stdout=~s/"\s+"//g;
   my $txt_r=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "dig -x $public_ip");
   my $dkim=<<END;

   In DNS, create a new TXT record with  mail._domainkey  as a name
   while the value/content of the TXT record should look like this:

   $txt_r

   Also, create a DMARC policy with  _dmarc  as a name while the
   value/content of the TXT record should look like this:

   v=DMARC1; p=none; adkim=r; aspf=r;

   It may take a while for the DNS changes to propagate.
   You can check whether the records have propagated using the dig command:

      dig mail._domainkey.$domain_url TXT +short

      dig _dmarc.$domain_url TXT +short

   You can also inspect DMARC here:  https://dmarcian.com/dmarc-inspector/

   Create these accounts with PostFixAdmin:

      abuse\@$domain_url           hostmaster\@$domain_url
      postmaster\@$domain_url      webmaster\@$domain_url

   Finally, ask your hosting provider to create a PTR record:

   $stdout 
   
END
   print $dkim;
   sleep 60;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "dig mail._domainkey.$domain_url TXT +short",
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "dig _dmarc.$domain_url TXT +short",
      '__display__');

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
      Result => $standup_emailserver,
      #Result => $stripe_keys,
      #Result =>
   #$Net::FullAuto::ISets::Local::EmailServer_is::select_emailserver_setup,
      Banner => $email_banner,

   };
   return $email_address;

};

our $create_strong_password=sub {

   package create_strong_password;
   use Crypt::GeneratePassword qw(chars);
   my $length=$_[0]||15;
   my $minlen=$length;
   my $maxlen=$length;
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
         die if -1<index $word,'#';
         die if $word!~/\d/;
         die if $word!~/[A-Z]/;
         die if $word!~/[a-z]/;
         die if $word!~/[@%=]/;
         return $word;
      };
      alarm 0;
      last if $word;
   }
   return $word;

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

   my $word=$create_strong_password->(15);
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

our $test_letsencrypt=sub {

   package test_letsencrypt;
   use Net::FullAuto;
   my $domain_url="]I[{'domain_url',1}";
   my $handle=connect_shell();
   my ($stdout,$stderr)=$handle->cmd(
      "wget -qO- https://crt.sh/?Identity=mail.$domain_url");
   my $tr=0;my $certid='';
   unless ($stdout=~/None found/s) {
      my $nextline=0;my $tr=0;
      foreach my $line (split /\n/, $stdout) {
         if ($line=~/TR/) {
            $nextline=1;
         } elsif ($nextline==1 and $line=~/id=/) {
            $tr++;
            $line=~s/^.*id=(.*)["].*$/$1/;
            $nextline=0;
         }
         if ($tr==5) {
            $certid=$line;last;
         }
      }
   }
   unless ($certid) {
      $choose_strong_password->();
   } else {
      ($stdout,$stderr)=$handle->cmd(
         "wget -qO- https://crt.sh/?id=$certid");
      $stdout=~/^.*?Log URL.*?TD[>](.*?)[&].*?[>]([^ ]+) UTC.*$/s;
      my $date=$1;my $time=$2;
      my ($yr,$mn,$dy,$hr,$mt,$sc)=(0,0,0,0,0,0);
      ($yr,$mn,$dy)=split /-/, $date;
      ($hr,$mt,$sc)=split /:/, $time;
      my $timestamp=&Net::FullAuto::FA_Core::timelocal(
         $sc,$mt,$hr,$dy,$mn-1,$yr);
      $timestamp-=21600;
      my $diff=time()-$timestamp;
      $diff=int($diff/3600);
      if ($diff<169) {
         $Net::FullAuto::ISets::Local::EmailServer_is::domain_url->($diff,$domain_url);
      } else {
         $choose_strong_password->();
      }
   }
};

our $domain_url=sub {

   package domain_url;
   my $diff=$_[0]||'';
   my $tried=$_[1]||'';
   my $days=0;my $hours=0;
   if ($diff) {
      my $remain=168-$diff;
      $days=int($remain/24);
      $hours=$remain%24;
   }
   $tried="\n   ERROR! => Letsencrypt Cert for  $tried  is\n".
          "             not available for $days days $hours hours!\n"
          if $diff;
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
   $tried
   Create the DNS A/AAAA record(s) for this domain:

   A      @                       $public_ip
   A      mail.domain_url         $public_ip
   CNAME  mail                    @
   CNAME  postfixadmin            @
   MX     @                10     mail.domain_url   3600
   TXT                            v=spf1 mx ~all    3600

   Domain URL
                ]I[{1,'fullauto.com',46}

END

   my $domain_url={

      Name => 'domain_url',
      Input => 1,
      #Result => $choose_strong_password,
      Result => $test_letsencrypt,
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

1

