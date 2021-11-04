package Net::FullAuto::ISets::Local::WordPress_is;

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
our $DISPLAY='WordPress';
our $CONNECT='secure';

use 5.005;

use strict;
use warnings;

my $service_and_cert_password='Full@ut0O1';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_wordpress_setup);

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
# how-to-add-a-loginlogout-link-to-your-wordpress-menu/
# http://vanweerd.com/enhancing-your-wordpress-3-menus/#add_login

# wp plugin list --path=/var/www/html/wordpress --status=active --allow-root

# https://www.digitalocean.com/community/tutorials/
# how-to-set-up-a-firewall-using-firewalld-on-centos-7
# sudo firewall-cmd --zone=public --permanent --add-port=80/tcp
# sudo firewall-cmd --zone=public --permanent --add-port=443/tcp
# sudo firewall-cmd --zone=public --permanent --list-ports

# https://chrisjean.com/change-timezone-in-centos/

# https://www.cartoonify.de/

my $configure_wordpress=sub {

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
      'WordPressSecurityGroup','WordPress.com Security Group');
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
         "rm -rf /opt/source/* ~/fa\* /var/www/html/wordpress",
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
      if ($stdout=~/EXISTS/s) {
         ($stdout,$stderr)=$handle->cmd($sudo."rm -rvf $nginx_path/nginx",
             '__display__');
      }
   }
#cleanup;
my $do=1;
if ($do==1) {
   unless ($^O eq 'cygwin') {
   } else {
      # https://www.digitalocean.com/community/questions/how-to-change-port-80-into-8080-on-my-wordpress
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
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 22 --cidr '.$cidr." 2>&1"; # SSH
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 80 --cidr '.$cidr." 2>&1"; # HTTP
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 443 --cidr '.$cidr." 2>&1"; # HTTPS
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 25 --cidr '.$cidr." 2>&1"; # SMTP
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 465 --cidr '.$cidr." 2>&1"; # SMTPS
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 587 --cidr '.$cidr." 2>&1"; # AMAZON SES
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 110 --cidr '.$cidr." 2>&1"; # POP3
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 995 --cidr '.$cidr." 2>&1"; # POP3S
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 143 --cidr '.$cidr." 2>&1"; # IMAP
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 993 --cidr '.$cidr." 2>&1"; # IMAPS
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 6379 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 11332 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 11333 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
      $c='aws ec2 authorize-security-group-ingress '.
         '--group-name WordPressSecurityGroup --protocol '.
         'tcp --port 11334 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      Net::FullAuto::FA_Core::handle_error($error) if $error
         && $error!~/already exists/;
   } else {
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y remove git','__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install https://packages.endpoint.com/rhel/7/'.
         'os/x86_64/endpoint-repo-1.7-1.x86_64.rpm',
         '__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         'yum -y install git','__display__');
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
   my $lxmlver=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "ls -1 /usr/local/lib | grep libxml2.so.$lxmlver");
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
            'git clone https://gitlab.gnome.org/GNOME/libxml2.git',
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
         "git checkout v$lxmlver",'__display__');
      ($stdout,$stderr)=$handle->cmd($sudo.
         '"ACLOCAL_PATH=/usr/share/aclocal" '.
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
      'CFLAGS="-DSQLITE_ENABLE_COLUMN_METADATA=1" '.
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
   my $sslv=$stdout;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'ls -1 | grep openssl');
   my $ssldir=0;
   $ssldir=1 if $stdout=~/^\s*openssl\s*$/s;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'strings /usr/local/lib64/libssl.so | grep OpenSSL');
   my $ssllib=$stdout;
   if ($ssllib!~/$sslv/s  || !$ssldir) {
      if ($ssldir) {
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
      my $sslr=$sslv;
      $sslr=~s/\./_/g;
$sslr='1_1_1l';
      ($stdout,$stderr)=$handle->cmd($sudo.
         "git checkout OpenSSL_$sslr",'__display__');
      if ($ssllib!~/$sslv/s) {
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
   $stdout=~s/\.[0-9]$//;
   ($stdout,$stderr)=$handle->cmd(
      "if test -f /usr/local/bin/python$stdout; then echo Exists; fi");
   unless ($stdout=~/Exists/s) {
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
   # https://codex.wordpress.org/Nginx
   # https://www.sitepoint.com/setting-up-php-behind-nginx-with-fastcgi/
   # http://codingsteps.com/install-php-fpm-nginx-mysql-on-ec2-with-amazon-linux-ami/
   # http://code.tutsplus.com/tutorials/revisiting-open-source-social-networking-installing-gnu-social--cms-22456
   # https://wiki.loadaverage.org/clipbucket/installation_guides/install_like_loadaverage
   # https://karp.id.au/social/index.html
   # http://jeffreifman.com/how-to-install-your-own-private-e-mail-server-in-the-amazon-cloud-aws/
   # https://www.wpwhitesecurity.com/creating-mysql-wordpress-database/
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
   $ad="            root /var/www/html/wordpress;%NL%".
       '            index  index.php  index.html index.htm;%NL%'.
       '            try_files $uri $uri/ /index.php?$args;';
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' $nginx_path/nginx/nginx.conf
END
   $handle->cmd_raw($sudo.$ad);
   $ad='%NL%        location ~ .php$ {'.
       '%NL%            root /var/www/html/wordpress;'.
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
   if ($mysql_version<15.1 || $mysql_status!~/Taking your SQL requests/) {
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
            '/usr/local/bin/cmake -DWITH_SSL=yes '.
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
         my $cmd='DROP DATABASE wordpress;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==1 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE DATABASE wordpress CHARACTER SET '.
                 'utf8 COLLATE utf8_general_ci;';
         print "$cmd\n";
         $handle->print($cmd);
         $handle->print(';');
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==2 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='DROP USER wordpress@localhost;';
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==3 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='CREATE USER wordpress@localhost IDENTIFIED BY '.
                 "'".$service_and_cert_password."';";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==4 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd='GRANT ALL PRIVILEGES ON wordpress.*'.
                 ' TO wordpress@localhost;';
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
      } elsif ($cmd_sent==6 && $output=~/MariaDB.*?>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent>=7 && $output=~/MariaDB.*?>\s*$/) {
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
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   #
   #  Set PHP 7 or 8 here
   #
   #  roundcube does not work with php 8 as of 7/8/2021
   my $vn=8;
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
zend_extension=opcache.so
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

   ($stdout,$stderr)=$handle->cwd('/opt/source');
   print $install_wordpress;
   sleep 5;
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "http://wordpress.org/latest.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "tar xzvf latest.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd('wordpress');
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
      "sed -i '/AUTH/,+6d' wp-config.php");
   ($stdout,$stderr)=$handle->cmd($sudo.
      "curl -s https://api.wordpress.org/secret-key/1.1/salt/",
      '__display__');
   my $strs=$stdout;
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
   $strs=~s/[\\]/\\\\x5c/sg;
   $strs=~s/\$/\\\\x24/sg;
   $strs=~s/["]/\\\\x22/sg;
   $strs=~s/[!]/\\x21/sg;
   $strs=~s/[`]/\\\\x60/sg;
   $strs=~s/[%]/\\\\x25/sg;
   $strs=~s/[*]/\\\\x2A/sg;
   ($stdout,$stderr)=$handle->cmd($sudo.
      'cat /opt/source/wordpress/wp-config.php');
   $stdout=~s/[\\]/\\\\x5c/sg;
   $stdout=~s/\$/\\\\x24/sg;
   $stdout=~s/["]/\\\\x22/sg;
   $stdout=~s/[!]/\\\\x21/sg;
   $stdout=~s/[`]/\\\\x60/sg;
   $stdout=~s/[%]/\\\\x25/sg;
   $stdout=~s/[*]/\\\\x2A/sg;
   my $wcn='';my $n=0;
   foreach my $line (split /\n/,$stdout) {
      $line=~s/\r$//;
      if ($line=~/NONCE/) {
         $wcn.=$strs;
      } else {
         $wcn.=$line."\n";
      }
   }
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$wcn\" > /tmp/wp-config.php");
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -fv /tmp/wp-config.php '.
      '/opt/source/wordpress/wp-config.php',
      '__display__');
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
      "rsync -avP /opt/source/wordpress/ ".
      "/var/www/html/wordpress",'__display__');
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

   ($stdout,$stderr)=$handle->cmd($sudo.
      'wget --random-wait --progress=dot '.
      'https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/'.
      'wp-cli.phar','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v +x wp-cli.phar','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'mv -v wp-cli.phar /usr/local/bin/wp','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   $sudo='sudo -u www-data ';
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/wp core install '.
      "--title=$domain_url ".
      "--url=https://www.$domain_url ".
      "--admin_user=$adu ".
      "--admin_email=$email_address ".
      "--admin_password=$service_and_cert_password ".
      '--allow-root --path=/var/www/html/wordpress',
      '__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/wp plugin install really-simple-ssl '.
      '--path=/var/www/html/wordpress','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      '/usr/local/bin/wp plugin activate really-simple-ssl '.
      '--path=/var/www/html/wordpress','__display__');

$do=0;
if ($do==1) {
   # https://www.hugeserver.com/kb/install-secure-elasticsearch-kibana-centos-7/
   # https://www.cloudways.com/blog/elasticsearch-on-wordpress/
   ($stdout,$stderr)=$handle->cmd($sudo.
      'yum -y install java-1.8.0-openjdk.x86_64','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source');
   ($stdout,$stderr)=$handle->cmd($sudo.
      "wget --random-wait --progress=dot ".
      "https://artifacts.elastic.co/downloads/".
      "elasticsearch/elasticsearch-5.0.0.rpm",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'rpm --install elasticsearch-*rpm','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl daemon-reload','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl enable elasticsearch','__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'systemctl start elasticsearch','__display__');
   my $ep='%NL%/** ElasticPress */%NL%'.
          "define( %SQ%EP_HOST%SQ%, %SQ%http://127.0.0.1:9200%SQ% );";
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'/DB_COLLATE/a$ep\' /var/www/html/wordpress/wp-config.php");
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \"s/%SQ%/\'/g\" ".
       '/var/www/html/wordpress/wp-config.php');
   ($stdout,$stderr)=$handle->cmd($sudo.
       "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       '/var/www/html/wordpress/wp-config.php');
}

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

my $standup_wordpress=sub {

   my $catalyst="]T[{select_wordpress_setup}";
   my $password="]I[{'enter_password',1}";
   my $email_address="]I[{'email_address',1}";
   my $stripe_pub="]I[{'stripe_keys',1}";
   my $stripe_sec="]I[{'stripe_keys',2}";
   my $recaptcha_pub="]I[{'recaptcha_keys',1}";
   my $recaptcha_sec="]I[{'recaptcha_keys',2}";
   my $domain_url="]I[{'domain_url',1}";
   my $cnt=0;
   $configure_wordpress->($catalyst,$domain_url,$password,$email_address,$stripe_pub,
                          $stripe_sec,$recaptcha_pub,$recaptcha_sec);
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
      Result => $standup_wordpress,
      #Result =>
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
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
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
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
   Type or Paste the necessary Email Address for WordPress here:

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
      Result => $standup_wordpress,
      #Result => $stripe_keys,
      #Result =>
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
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
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
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
         $Net::FullAuto::ISets::Local::WordPress_is::domain_url->($diff,$domain_url);
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

   Domain URL
                ]I[{1,'fullauto.com',46}

END

   my $domain_url={

      Name => 'domain_url',
      Input => 1,
      #Result => $choose_strong_password,
      Result => $test_letsencrypt,
      #Result =>
   #$Net::FullAuto::ISets::Local::WordPress_is::select_wordpress_setup,
      Banner => $domain_url_banner,

   };
   return $domain_url;

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
         #Result => $choose_strong_password,
         Result => $domain_url,

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
   cleanup;

}

1

