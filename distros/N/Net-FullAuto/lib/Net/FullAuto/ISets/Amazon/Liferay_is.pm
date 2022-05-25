package Net::FullAuto::ISets::Amazon::Liferay_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2022  Brian M. Kelly
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
our $DISPLAY='Liferay® Portal (ce) with MySQL® and Apache™';
our $CONNECT='ssh';
our $defaultInstanceType='t2.small';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_liferay_setup);

use Net::FullAuto::Cloud::fa_amazon;

my $configure_mysql=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $lr_inst=$main::aws->{'Liferay.com'}->[$cnt]->[0];
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd("sudo yum clean all");
   ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden");
   ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert");
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
   ($stdout,$stderr)=$handle->cmd("sudo yum -y install ".
      "mysql56 mysql56-server mysql56-common mysql56-client",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo service mysqld start",
      '__display__');
   $handle->{_cmd_handle}->print('sudo mysql_secure_installation');
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'root (enter for none):') {
         $handle->{_cmd_handle}->print();
         next;
      } elsif (-1<index $output,'Set root password? [Y/n]') {
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
   my $lr_release=$main::aws->{Liferay_Release};
   $lr_release=~/liferay.*portal-(.*)-(?:ce-)?(.*)$/;
   my $rnum=$1;my $rtyp=$2;
   print "   Downloading Liferay.com SQL files . . .\n";
   ($stdout,$stderr)=$handle->cmd("wget -qO- ".
      "http://sourceforge.net/projects/lportal/files/Liferay%20Portal/");
   my $flag=0;my $lr_url='';
   foreach my $line (split "\n",$stdout) {
      if ($flag && $line=~/^.*[Hh][Rr][Ee][Ff]=["](.*?)["].*$/) {
         $lr_url=$1;last;
      } elsif ($line=~/^.*title=["](.*?) (.*?)["]\s*class=["]folder/) {
         next if $line=~/One level up/;
         my $num=$1;my $typ=$2;
         if ($num=~/^$rnum/ && $rtyp=~/$typ/i) {
            $flag=1;next;
         }
      }
   }
   ($stdout,$stderr)=$handle->cmd("wget -qO- ".
      "http://sourceforge.net".$lr_url);
   my $regx="liferay.*sql-.*$rnum.*".lc($rtyp).".*zip";
   $flag=0;
   foreach my $line (split "\n",$stdout) {
      if ($flag && $line=~/^.*[Hh][Rr][Ee][Ff]=["](.*?)["].*$/) {
         $lr_url=$1;last;
      } elsif ($line=~/^.*title=["]$regx["]\s*class=["]file/) {
         $flag=1;next;
      }
   }
   $lr_url=~s/^(.*)\/download\s*$/$1/;
   ($stdout,$stderr)=$handle->cmd(
      "sudo wget --progress=dot --random-wait $lr_url 2>&1",'__display__');
   $lr_url=~s/^.*\/(.*)\s*$/$1/;
   ($stdout,$stderr)=$handle->cmd("sudo unzip -d /opt $lr_url",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $lr_url",
      '__display__');
   $lr_url=~s/^(.*)-.*$/$1/;
   my $cmd='sudo mysql -vvv -u root < '.
           "/opt/$lr_url/create/create-mysql.sql";
   ($stdout,$stderr)=$handle->cmd($cmd,'__display__');
   my $lr_pip=$lr_inst->{NetworkInterfaces}->[0]->{PrivateIpAddress};
   $handle->{_cmd_handle}->print('mysql -u root lportal');
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   my $cmd_sent=0;
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      my $out=$output;
      $out=~s/$prompt//sg;
      print $out if $output!~/^mysql>\s*$/;
      last if $output=~/$prompt|Bye/;
      if (!$cmd_sent && $output=~/mysql>\s*$/) {
         my $cmd='grant all privileges on *.* to '.
                 "'lportal'\@'".$lr_pip."' identified by 'liferay'".
                 " with grant option;";
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent==1 && $output=~/mysql>\s*$/) {
         my $cmd="FLUSH PRIVILEGES;";
         print "$cmd\n";
         $handle->{_cmd_handle}->print($cmd);
         $cmd_sent++;
         sleep 1;
         next;
      } elsif ($cmd_sent>=2 && $output=~/mysql>\s*$/) {
         print "quit\n";
         $handle->{_cmd_handle}->print('quit');
         sleep 1;
         next;
      } sleep 1;
      $handle->{_cmd_handle}->print();
   }
   my $db_inst=$main::aws->{$server_type}->[$cnt]->[0];
   my $db_pip=$db_inst->{NetworkInterfaces}->[0]->{PrivateIpAddress};
   my $lrhandle=$main::aws->{'Liferay.com'}->[$cnt]->[1];
   my $pe=$main::aws->{'Liferay.com'}->[$cnt]->[2]->[0].
          '/webapps/ROOT/WEB-INF/classes/portal-ext.properties';
   my $ad="jdbc.default.driverClassName=com.mysql.jdbc.Driver";
   ($stdout,$stderr)=$lrhandle->cmd(
      "sudo sed -i \'/S3Store/a $ad\' $pe");
   ($stdout,$stderr)=$lrhandle->cmd(
      "sudo sed -i \'/S3Store/G\' $pe");
   $ad="jdbc.default.url=jdbc:mysql://$db_pip:3306/lportal?".
       'useUnicode=true&'.
       'characterEncoding=UTF-8&'.
       'useFastDateParsing=false';
   ($stdout,$stderr)=$lrhandle->cmd(
      "sudo sed -i \'/Driver/a $ad\' $pe");
   my $id="jdbc.default.username=lportal";
   ($stdout,$stderr)=$lrhandle->cmd(
      "sudo sed -i \'/Unicode/a $id\' $pe");
   my $pw="jdbc.default.password=liferay";
   ($stdout,$stderr)=$lrhandle->cmd(
      "sudo sed -i \'/username/a $pw\' $pe");
   my $tom_dir=$main::aws->{'Liferay.com'}->[$cnt]->[2]->[0];
   my $starting_liferay=<<'END';

   .oPYo. ooooo    .oo  .oPYo. ooooo o o    o .oPYo.      o    o  .oPYo.
   8        8     .P 8  8   `8   8   8 8b   8 8    8      8    8  8    8
   `Yooo.   8    .P  8  8YooP'   8   8 8`b  8 8           8    8  8YooP'
       `8   8   oPooo8  8   `b   8   8 8 `b 8 8   oo      8    8  8
        8   8  .P    8  8    8   8   8 8  `b8 8    8      8    8  8
   `YooP'   8 .P     8  8    8   8   8 8   `8 `YooP8      `YooP'  8
   ....................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
          __________
         |          |  _     _  ____  ____  ____        __   __
         | [][][]   | | |   | ||  __||  __||  _ `\   /\ \ \ / /
         | [][]     | | |   | || |_  | |__ | |_) |  /  \ \ V /
         | []    [] | | |   | ||  _| |  __||    ./ / /\ \ \ /
         |     [][] | | |__ | || |   | |__ | |\ \ / ____ \| |
         |   [][][] | |____||_||_|   |____||_| \_\_/    \_|_| ®
         |__________|                        _  _  _ ___ _
                                            |_)/ \|_) | |_||
   http://www.liferay.com/community         |  \_/| \ | | ||__  CE

   (Liferay Inc. and Community are **NOT** sponsors of the FullAuto© Project.)

END
   print $starting_liferay;sleep 10;
   ($stdout,$stderr)=$lrhandle->cmd("sudo $tom_dir".
      "/bin/startup.sh",'__display__');
   $lrhandle->{_cmd_handle}->print("tail -f $tom_dir/logs/catalina.out");
   $prompt=substr($lrhandle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($lrhandle);
      my $out=$output;
      $out=~s/$prompt//sg;
      print $out;
      if ($out=~/Server startup in/) {
         $lrhandle->{_cmd_handle}->print("\003");
         last;
      }
      sleep 1;
   }
   my ($hash,$json,$output,$error)=('','','','');
   my $in_id=$lr_inst->{InstanceId};
   ($hash,$output,$error)=
       run_aws_cmd("aws ec2 describe-instances ".
       "--filters Name=instance-id,Values=$in_id");
   if ($error) {
      print $error;
      cleanup();
   }
   my $lr_ip=
         $hash->{Reservations}->[0]->{Instances}->[0]->{PublicIpAddress};
   print "\n   ACCESS LIFERAY PORTAL AT:  http://$lr_ip:8080\n";

};

my $configure_apache=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd("sudo yum clean all");
   ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden");
   ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert");
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y groupinstall 'Development tools'",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y install pcre-devel",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y install openssl-devel",'__display__');
   my $url='https://apr.apache.org/download.cgi';
   ($stdout,$stderr)=$handle->cmd("wget -qO- $url");
   my $flag=0;my $apache_lib='';my $apr_util='';my $apr='';
   foreach my $line (split "\n",$stdout) {
      if (-1<index $line,'Unix Source') {
         $flag=1 unless $flag;
      } elsif ($flag) {
         next if 1<$flag && $line!~/apr-util/;
         $apache_lib=$line;
         $apache_lib=~s/^.*[Hh][Rr][Ee][Ff]=["](.*)["].*$/$1/;
         $apache_lib=~s/([^:])\/\//$1\//g;
         ($stdout,$stderr)=$handle->cmd(
            "sudo wget --progress=dot --random-wait $apache_lib 2>&1",
            '__display__');
         $apache_lib=~s/^.*\/(.*)$/$1/;
         ($stdout,$stderr)=$handle->cmd(
            "sudo tar zxvf $apache_lib -C /opt",'__display__');
         ($stdout,$stderr)=$handle->cmd(
            "sudo rm -rfv $apache_lib",'__display__');
         $apache_lib=~s/\.tar\.gz\s*$//;
         if ($line=~/apr-util/) {
            $apr_util=$apache_lib;
         } else {
            $apr=$apache_lib;
         }
         ($stdout,$stderr)=$handle->cwd("/opt/$apache_lib");
         $apache_lib=~s/\.tar\.gz\s*$//;
         if ($line=~/apr-util/) {
            $apr_util=$apache_lib;
         } else {
            $apr=$apache_lib;
         }
         ($stdout,$stderr)=$handle->cwd("/opt/$apache_lib");
         if ($line=~/apr-util/) {
            ($stdout,$stderr)=$handle->cmd(
               "sudo ./configure --with-apr=/opt/$apr".
               " --with-openssl".
               " --with-crypto 2>/dev/null",
               '__display__');
            ($stdout,$stderr)=$handle->cwd("xml/expat");
            ($stdout,$stderr)=$handle->cmd("sudo ./configure 2>/dev/null",
               '__display__');
            ($stdout,$stderr)=$handle->cmd("sudo make install",
               '__display__');
            ($stdout,$stderr)=$handle->cwd("/opt/$apr_util");
         } else {
            ($stdout,$stderr)=$handle->cmd("sudo ./configure 2>/dev/null",
               '__display__');
         }
         ($stdout,$stderr)=$handle->cmd(
            "sudo make install",'__display__');
         ($stdout,$stderr)=$handle->cwd("~");
         last if $flag++==2;
      }
   }
   $url='http://httpd.apache.org/download.cgi';
   ($stdout,$stderr)=$handle->cmd("wget -qO- $url");
   $flag=0;my $apache='';
   foreach my $line (split "\n",$stdout) {
      if ($line=~/Stable Release/) {
         $flag=1;
      } elsif ($flag && $line=~/^.*[#]apache.*?[>](.*gz?)[<].*$/) {
         $apache=$1;$flag=0;
      } elsif ($line=~/Source:.*$apache.*gz/) {
         $apache=$line;
         $apache=~s/^.*[Hh][Rr][Ee][Ff]="(.*?)"[>].*$/$1/;
      }
   }
   my $download_apache=<<'END';


   ooo.   .oPYo. o      o o    o o     .oPYo.      .oo ooo.   o o    o .oPYo.
   8  `8. 8    8 8      8 8b   8 8     8    8     .P 8 8  `8. 8 8b   8 8    8
   8   `8 8    8 8      8 8`b  8 8     8    8    .P  8 8   `8 8 8`b  8 8
   8    8 8    8 8  db  8 8 `b 8 8     8    8   oPooo8 8    8 8 8 `b 8 8   oo
   8   .P 8    8 `b.PY.d' 8  `b8 8     8    8  .P    8 8   .P 8 8  `b8 8    8
   8ooo'  `YooP'  `8  8'  8   `8 8oooo `YooP' .P     8 8ooo'  8 8   `8 `YooP8
   ..........................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                             _                 _
         __,,--;;;v\\_V_=-" /_\  _ __  __ _ __| |_  ___      ______ _
    _--;;\\V^V^\\\//7 ^    / _ \| '_ \/ _` / _| ' \/ -_)  |_| |  | |_)
   <_,,,==//^~*'''        /_/ \_\ .__/\__,_\__|_||_\___|  | | |  | |   SERVER
                                |_|                   ™

   http://www.apache.org

   (The Apache™ Foundation is **NOT** a sponsor of the FullAuto© Project.)

END
   print $download_apache;sleep 10;
   ($stdout,$stderr)=$handle->cmd(
      "sudo wget --progress=dot --random-wait $apache 2>&1",'__display__');
   $apache=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd(
      "sudo tar zxvf $apache -C /opt",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rfv $apache",'__display__');
   $apache=~s/\.tar\.gz\s*$//;
   ($stdout,$stderr)=$handle->cwd("/opt/$apache");
   ($stdout,$stderr)=$handle->cmd("sudo ./configure ".
      "--with-apr=/opt/$apr ".
      "--with-apr-util=/opt/$apr_util ".
      "--with-ssl 2>/dev/null",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo make install",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo /usr/local/apache2/bin/apachectl start");
   ($stdout,$stderr)=$handle->cmd(
      "sudo cat /usr/local/apache2/logs/error_log",'__display__');
   my ($hash,$json,$output,$error)=('','','','');
   my $in_id=$main::aws->{$server_type}->[$cnt]->[0]->{InstanceId};
   ($hash,$output,$error)=
       run_aws_cmd("aws ec2 describe-instances ".
       "--filters Name=instance-id,Values=$in_id");
   if ($error) {
      print $error;
      cleanup();
   }
   my $ap_ip=
         $hash->{Reservations}->[0]->{Instances}->[0]->{PublicIpAddress};
   print "\n   ACCESS APACHE WEB SERVER AT:  http://$ap_ip\n\n";

};

my $configure_liferay=sub {

   # https://www.liferay.com/web/raymond.auge/blog/-/blogs \
   #       /liferay-osgi-and-shell-access-via-gogo-shell

   # https://www.liferay.com/web/jignesh/blog/-/ \
   #       blogs/power-of-beanshell-in-liferay

   # http://www.insinuator.net/2011/12/liferay-portlet-shell/

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr,$url)=(''.''.'');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y -v install java-1.8.0",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y -v remove java-1.7.0-openjdk",
      '__display__');
   foreach my $k (1..5) {
      ($stdout,$stderr)=$handle->cmd("wget -qO- ".
         "http://sourceforge.net/projects/lportal/files/");
      $url=$stdout;
      $url=~s/^.*title=["](.*?zip).*$/$1/s;
      $url=~s/ /%20/g;
      last if $url=~/zip$/;
   }
   die "Cannot get Liferay file location\n" unless $url=~/zip$/;
   $url='http://downloads.sourceforge.net/project/lportal'.$url;
   my $zip=$url;
   $zip=~s/^.*\/(.*)$/$1/;
   my $download_liferay=<<'END';

   ooo.   .oPYo. o      o o    o o     .oPYo.      .oo ooo.   o o    o .oPYo.
   8  `8. 8    8 8      8 8b   8 8     8    8     .P 8 8  `8. 8 8b   8 8    8
   8   `8 8    8 8      8 8`b  8 8     8    8    .P  8 8   `8 8 8`b  8 8
   8    8 8    8 8  db  8 8 `b 8 8     8    8   oPooo8 8    8 8 8 `b 8 8   oo
   8   .P 8    8 `b.PY.d' 8  `b8 8     8    8  .P    8 8   .P 8 8  `b8 8    8
   8ooo'  `YooP'  `8  8'  8   `8 8oooo `YooP' .P     8 8ooo'  8 8   `8 `YooP8
   ..........................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
            __________
           |          |  _     _  ____  ____  ____        __   __
           | [][][]   | | |   | ||  __||  __||  _ `\   /\ \ \ / /
           | [][]     | | |   | || |_  | |__ | |_) |  /  \ \ V /
           | []    [] | | |   | ||  _| |  __||    ./ / /\ \ \ /
           |     [][] | | |__ | || |   | |__ | |\ \ / ____ \| |
           |   [][][] | |____||_||_|   |____||_| \_\_/    \_|_| ®
           |__________|                       _  _  _ ___ _
                                             |_)/ \|_) | |_||    COMMUNITY
   http://www.liferay.com/community          |  \_/| \ | | ||__  EDITION

   (Liferay Inc. and Community are **NOT** sponsors of the FullAuto© Project.)

END
   print $download_liferay;sleep 10;
   ($stdout,$stderr)=$handle->cmd(
      "sudo wget --progress=dot --random-wait ".
      "$url 2>&1",'__display__');
   print "WGET LIFERAY ERROR=$stderr\n" if $stderr;
   ($stdout,$stderr)=$handle->cmd("sudo mkdir -p /var/opt/lr_jvm1");
   ($stdout,$stderr)=$handle->cmd("sudo unzip -d /var/opt/lr_jvm1 $zip",
      '__display__');
   print "\n   ";
   if ($selection=~/1 Server & 2/ || $selection=~/2 Servers & 4/) {
      ($stdout,$stderr)=$handle->cmd("sudo mkdir -p /var/opt/lr_jvm2");
      ($stdout,$stderr)=$handle->cmd("sudo unzip -d /var/opt/lr_jvm2 $zip",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $zip",'__display__');
   my $rand = localtime;
   $rand=~s/\s|://g;
   $rand=~s/\.//g;
   my $lr_cnt=0;
   my $lrbn='liferay-repository-'.$main::aws->{fullauto}->{InstanceId}.
            "-$lr_cnt";
   my $output='';
   while (1) {
      my $s="aws s3 mb s3://$lrbn 2>&1";
      my ($hash,$output,$error)=('','','');
      ($hash,$output,$error)=run_aws_cmd($s);
      print "   ".$output;
      if ((-1<index $output,'bucket name is not avail') ||
            ((-1<index $output,'you already own it') &&
            (-1==index $output,'make_bucket:'))) {
         $lr_cnt++;
         $lrbn='liferay-repository-'.
            $main::aws->{fullauto}->{InstanceId}."-$lr_cnt";
         $output='';
      } elsif (-1<index $output,'make_bucket:') {
         last
      } elsif ($error) {
         Net::FullAuto::FA_Core::handle_error($error);
      }
   }
   ($stdout,$stderr)=$handle->cmd("sudo ls -1 /var/opt/lr_jvm1");
   my $lr_release=$stdout;
   $lr_release=~s/^.*(liferay.*)\n.*/$1/s;
   $main::aws->{Liferay_Release}=$lr_release;
   ($stdout,$stderr)=$handle->cmd(
      "sudo ls -1 /var/opt/lr_jvm1/$lr_release");
   my %tom=();
   foreach my $item (split "\n", $stdout) {
      chomp $item;
      if ($item=~/tomcat-(.*)$/) {
         $tom{$1}=$item;
      }
   }
   my @tom=sort keys %tom;
   my $num=$cnt+1;
   $main::aws->{$server_type}->[$cnt]->[2]=
      [ "/var/opt/lr_jvm$num/$lr_release/$tom{$tom[$#tom]}" ];
   if ($selection=~/1 Server & 2/ || $selection=~/2 Servers & 4/) {
      $num++;
      push @{$main::aws->{$server_type}->[$cnt]->[2]},
         "/var/opt/lr_jvm$num/$lr_release/$tom{$tom[$#tom]}";
   }
   foreach my $jvm (@{$main::aws->{$server_type}->[$cnt]->[2]}) {
      my $dlak='dl.store.s3.access.key';
      my $dlsk='dl.store.s3.secret.key';
      my $dlbn='dl.store.s3.bucket.name';
      my $ak='';my $sk='';
      unless (exists $main::aws->{access_id}) {
         open(CF,"$ENV{HOME}/.aws/credentials");
         while (my $line=<CF>) {
            if ($line=~/^aws_access_key_id *= *(.*)\s*/) {
               $ak=$1;
            } elsif ($line=~/^aws_secret_access_key *= *(.*)\s*/) {
               $sk=$1;
            }
         }
         close CF;
      } else {
         $ak=$main::aws->{access_id};
         $sk=$main::aws->{secret_key};
      }
      my $pe="$jvm/webapps/ROOT/WEB-INF/classes/portal-ext.properties";
      my $impl='dl.store.impl';
      my $s3='com.liferay.portlet.documentlibrary.store.S3Store';
      my $content="\n$dlak=$ak".
                  "\n$dlsk=$sk".
                  "\n$dlbn=$lrbn".
                  "\n$impl=$s3\n";
      ($stdout,$stderr)=$handle->cmd("sudo touch $pe");
      ($stdout,$stderr)=$handle->cmd("sudo chmod 777 $pe");
      ($stdout,$stderr)=$handle->cmd("sudo echo \"$content\" > $pe");
      ($stdout,$stderr)=$handle->cmd("sudo chmod 644 $pe");
   }

};

my $standup_liferay=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $database="]T[{select_database_for_liferay}";
   my $liferay="]T[{select_liferay_setup}";
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
   my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
            ->[0]->{IpRanges}->[0]->{CidrIp};
   $c='aws ec2 create-security-group --group-name '.
      'LiferaySecurityGroup --description '.
      '"Liferay.com Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name LiferaySecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name LiferaySecurityGroup --protocol '.
      'tcp --port 8080 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name LiferaySecurityGroup --protocol '.
      'tcp --port 8081 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 create-security-group --group-name '.
      'ApacheSecurityGroup --description '.
      '"Apache.org Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ApacheSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ApacheSecurityGroup --protocol '.
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ApacheSecurityGroup --protocol '.
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 create-security-group --group-name '.
      'MySQLSecurityGroup --description '.
      '"MySQL Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name MySQLSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name MySQLSecurityGroup --protocol '.
      'tcp --port 3306 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'Liferay.com'}) {
      my $g=get_aws_security_id('LiferaySecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
            "--instance-type $type --key-name \'$pemfile\' ".
            "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'Liferay.com'}}==0) {
         launch_server('Liferay.com',$cnt,$liferay,'',$c,
                       $configure_liferay);
      } else {
         my $num=$#{$main::aws->{'Liferay.com'}}-1;
         foreach my $num (0..$num) {
            launch_server('Liferay.com',$cnt++,$liferay,'',
            $c,$configure_liferay);
         }
      }
   }
   $cnt=0;
   if (exists $main::aws->{'Apache.org'}) {
      my $g=get_aws_security_id('ApacheSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'Apache.org'}}==0) {
         launch_server('Apache.org',$cnt,'','',$c,
                       $configure_apache);
      } else {
         my $num=$#{$main::aws->{'Apache.org'}}-1;
         foreach my $num (0..$num) {
            launch_server('Apache.org',$cnt++,'','',$c,
                          $configure_apache);
         }
      }
   }
   $cnt=0;
   if (exists $main::aws->{'MySQL.com'}) {
      my $g=get_aws_security_id('MySQLSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'MySQL.com'}}==0) {
         launch_server('MySQL.com',$cnt,$database,'',$c,
                       $configure_mysql);
      }
   }
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


   Copyright © 2000-2022  Brian M. Kelly  Brian.Kelly@FullAuto.com

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
            "   to start with your new Liferay® installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $liferay_setup_summary=sub {

   package liferay_setup_summary;
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
   my $liferay="]T[{select_liferay_setup}";
   $liferay=~s/^"//;
   $liferay=~s/"$//;
   my $database="]T[{select_database_for_liferay}";
   $database=~s/^"//;
   $database=~s/"$//;
   my $httpd="]T[{select_httpd_for_liferay}";
   $httpd="]T[{select_httpd_for_liferay}";
   $httpd=~s/^"//;
   $httpd=~s/"$//;
   #print "REGION=$region and TYPE=$type\n";
   #print "LIFERAY=$liferay and DB=$database\n";
   #print "HTTPD=$httpd\n";
   my $num_of_servers=0;
   my $ln=$liferay;
   $ln=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ln==1) {
      $main::aws->{'Liferay.com'}->[0]=[];
   } elsif ($ln=~/^\d+$/ && $ln) {
      foreach my $n (0..$ln) {
         $main::aws->{'Liferay.com'}=[] unless exists
            $main::aws->{'Liferay.com'};
         $main::aws->{'Liferay.com'}->[$n]=[];
      }
   }
   my $hd=$httpd;
   $hd=~s/^.*(\d+)\sadditional.*$/$1/;
   if ($hd==1) {
      $main::aws->{'Apache.org'}->[0]=[];
   } elsif ($hd=~/^\d+$/ && $hd) {
      foreach my $n (0..$hd) {
         $main::aws->{'Apache.org'}=[] unless exists
            $main::aws->{'Apache.org'};
         $main::aws->{'Apache.org'}->[$n]=[];
      }
   }
   $main::aws->{'MySQL.com'}->[0]=[];
   $num_of_servers=$ln+$hd+1;
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

         $liferay
         $database Database on 1 Server
         $httpd


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_liferay,

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

my $select_httpd_for_liferay=sub {

   my @options=('Do NOT use a separate httpd (web) server',
                'Use 1 Apache.org httpd server on 1 additional Server',
                'Use 2 Apache.org httpd servers on 2 additional Servers');

   my $select_database_banner=<<'END';

    _   _          __      __   _      ___                         ___
   | | | |___ ___  \ \    / /__| |__  / __| ___ _ ___ _____ _ _ __|__ \
   | |_| (_-</ -_)  \ \/\/ / -_) '_ \ \__ \/ -_) '_\ V / -_) '_(_-< /_/
    \___//__/\___|   \_/\_/\___|_.__/ |___/\___|_|  \_/\___|_| /__/(_)


   If you choose to use Apache.org httpd (web) servers in front of Liferay,
   additional servers will be launched. Depending on all your choices,
   FullAuto will launch and install supporting software on up to 5
   separate AWS EC2 servers.

END
   my %select_httpd_for_liferay=(

      Name => 'select_httpd_for_liferay',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $liferay_setup_summary,

      },
      Scroll => 2,
      Banner => $select_database_banner,

   );
   return \%select_httpd_for_liferay;

};

my $select_database_for_liferay=sub {

   #my @options=('MySQL','PostgresSQL');
   my @options=('MySQL');
   #my @options=('MySQL','Microsoft SQL Server','Oracle Database',
   #             'IBM DB2','PostgresSQL','Sybase','Apache Derby',
   #             'Firebird','Informix','Ingres','SAP DB');
   #http://imperialwicket.com/aws-install-postgresql-on-amazon-linux-quick-and-dirty/
   # https://chendamok.wordpress.com/2014/01/18/yum-install-oracle-validated-for-oracle-enterprise-linux-5/
   # cd /etc/yum.repos.d/
   # wget http://public-yum.oracle.com/public-yum-el5.repo
   # vi public-yum-el5.repo
   # yum install oracle-validated
   # http://download.oracle.com/otn/linux/oracle11g/xe/oracle-ex-11.2.0-1.0.x86_64.rmp.zip

   my $select_database_banner=<<'END';

    ___      _        _     ___       _        _
   / __| ___| |___ __| |_  |   \ __ _| |_ __ _| |__  __ _ ___ ___
   \__ \/ -_) / -_) _|  _| | |) / _` |  _/ _` | '_ \/ _` (_-</ -_)
   |___/\___|_\___\__|\__| |___/\__,_|\__\__,_|_.__/\__,_/__/\___|


   An additional server will be launched, and a supporting database for
   use by Liferay Portal (ce) will be installed. Please choose a database:

END
   my %select_database_for_liferay=(

      Name => 'select_database_for_liferay',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $select_httpd_for_liferay,

      },
      Scroll => 1,
      Banner => $select_database_banner,

   );
   return \%select_database_for_liferay;

};

our $select_liferay_setup=sub {

   my @options=('Liferay & Tomcat on 1 Server & 1 JVM',
                'Liferay & Tomcat on 1 Server & 2 Clustered JVMs',
                'Liferay & Tomcat on 2 Servers & 2 Clustered JVMs',
                'Liferay & Tomcat on 2 Servers & 4 Clustered JVMs');
   my $liferay_setup_banner=<<'END';

    _    _  __                      ___      _
   | |  (_)/ _|___ _ _ __ _ _  _   / __| ___| |_ _  _ _ __
   | |__| |  _/ -_) '_/ _` | || |  \__ \/ -_)  _| || | '_ \
   |____|_|_| \___|_| \__,_|\_, |  |___/\___|\__|\_,_| .__/
                            |__/                     |_|

   Choose the Liferay setup you wish to demo. Note that more servers
   means more expense, and more JVMs means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 JVM on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_liferay_setup=(

      Name => 'select_liferay_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $select_database_for_liferay,

      },
      Scroll => 1,
      Banner => $liferay_setup_banner,
   );
   return \%select_liferay_setup,

};

1
