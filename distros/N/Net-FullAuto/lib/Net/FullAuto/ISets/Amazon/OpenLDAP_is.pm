package Net::FullAuto::ISets::Amazon::OpenLDAP_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2019  Brian M. Kelly
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
our $DISPLAY='OpenLDAP™';
our $CONNECT='ssh';
our $defaultInstanceType='t2.micro';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_openldap_setup);

use Net::FullAuto::Cloud::fa_amazon;

my $configure_openldap=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd("sudo yum clean all");
   ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden");
   ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert");
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y groupinstall 'Development tools'",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      'sudo yum -y install openssl-devel icu cyrus-sasl'.
      ' libicu cyrus-sasl-devel libtool-ltdl-devel',
      '__display__');
   my $url=
      'http://www.oracle.com/technetwork/'.
      'products/berkeleydb/downloads/index.html';
   ($stdout,$stderr)=$handle->cmd("wget -qO- ".$url);
   my $site='download.oracle.com';
   my $source=$stdout;
   $source=~
        s/^.*?(http:\/\/$site\/)(?:otn\/)*(b.*?\d.tar.gz).*$/$1$2/s;
   my $file=$2;
   $file=~s/6\.\d+\.\d+.tar.gz/5.1.29.tar.gz/;
   $source=~s/6\.\d+\.\d+.tar.gz/5.1.29.tar.gz/;
   my $tarfile=$file;
   $tarfile=~s/^.*\/(.*)\s*$/$1/;
   my $dbdir=substr($file,(index $file,'/')+1,-7);
   my $ver=$dbdir;
   $ver=~s/_.*$//;
   $ver=~s/^.*db-(\d+[.]\d+).*$/$1/;
   my $pre="/usr/local/BerkeleyDB.$ver";
   ($stdout,$stderr)=$handle->cmd(
       "wget --random-wait --progress=dot $source",'__display__');
   ($stdout,$stderr)=$handle->cmd("wget ${source}.md5",'__display__');
   ($stdout,$stderr)=$handle->cmd("cat ${tarfile}.md5");
   my $checksum=$stdout;
   $checksum=~s/^\s*(\S+)\s+.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd("md5sum -c - <<<\"$checksum $tarfile\"",
      '__display__');
   unless ($stderr) {
      print(qq{ + CHECKSUM Test for $tarfile *PASSED* \n})
   } else {
      print "FATAL ERROR! : ".
            "CHECKSUM Test for $tarfile *FAILED*\n";
      print "\nPress ANY key to terminate FullAuto ",
            "installation ...\n";
      <STDIN>;
      return '{choose_demo_setup}<';
   }
   ($stdout,$stderr)=$handle->cmd("sudo tar zxvf $tarfile -C /opt",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf ${tarfile}.md5",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $tarfile",'__display__');
   ($stdout,$stderr)=$handle->cmd("wget -qO- ".
      "http://www.openldap.org/software/download/");
   $url=$stdout;
   $url=~s/^.*?[>]OpenLDAP[<].*?HREF="(.*?tgz)".*$/$1/s;
   ($stdout,$stderr)=$handle->cmd(
      "sudo wget --random-wait --progress=dot ".$url,'__display__');
   my $md5=$url;
   $md5=~s/tgz$/md5/;
   $tarfile=$url;
   $tarfile=~s/^.*\/(.*)\s*/$1/;
   my $oldir=$tarfile;
   $oldir=~s/\.tgz$//;
   ($stdout,$stderr)=$handle->cmd("wget $md5",'__display__');
   $md5=~s/^.*\/(.*)\s*/$1/;
   ($stdout,$stderr)=$handle->cmd("cat $md5");
   $checksum=$stdout;
   $checksum=~s/^.*=\s*(\S+)\s*$/$1/s;
   ($stdout,$stderr)=$handle->cmd("md5sum -c - <<<\"$checksum $tarfile\"",
      '__display__');
   unless ($stderr) {
      print(qq{ + CHECKSUM Test for $tarfile *PASSED* \n})
   } else {
      print "FATAL ERROR! : ".
            "CHECKSUM Test for $tarfile *FAILED*\n";
      print "\nPress ANY key to terminate FullAuto ",
            "installation ...\n";
      <STDIN>;
      return '{choose_demo_setup}<';
   }
   my $install_openldap=<<'END';

          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          :::::::::::::''       *    *    *        '':::::::::::::
                           *                   *
                       *                           *
                    *                                 *
                 *        http://www.openldap.org       *
               *                                          *
                ____                 _    ____    _    ____ TM
               / __ \____  ___  ____| |  |  _ \  / \  |  _ \
              / / / / __ \/ _ \/ __ \ |  | | | |/ _ \ | |_) |
             / /_/ / /_/ /  __/ / / / |__| |_| / ___ \| ___/
             \____/ .___/\___/_/ /_/|____|____/_/   \_\_|
                 /_/

         (OpenLDAP® is **NOT** a sponsor of the FullAuto© Project.)

END
   print $install_openldap;sleep 10;
   ($stdout,$stderr)=$handle->cmd("sudo tar zxvf $tarfile -C /opt",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $md5",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $tarfile",'__display__');
   ($stdout,$stderr)=$handle->cwd("/opt/$dbdir/build_unix");
   ($stdout,$stderr)=$handle->cmd("sudo ../dist/configure",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo make install",'__display__');
   my $c='sudo cat /usr/local/BerkeleyDB.5.1/lib >'.
         ' /etc/ld.so.conf.d/bdb.conf;'.
         'sudo chmod 444 /etc/ld.so.conf.d/bdb.conf;'.
         'sudo ldconfig';
   ($stdout,$stderr)=$handle->cmd($c);
   $c='sudo cat /usr/local/lib >'.
         ' /etc/ld.so.conf.d/sasl.conf;'.
         'sudo chmod 444 /etc/ld.so.conf.d/sasl.conf;'.
         'sudo ldconfig';
   ($stdout,$stderr)=$handle->cmd($c);
   $c='sudo cat /usr/lib64 >'.
         ' /etc/ld.so.conf.d/icu.conf;'.
         'sudo chmod 444 /etc/ld.so.conf.d/icu.conf;'.
         'sudo ldconfig';
   ($stdout,$stderr)=$handle->cmd($c);
   ($stdout,$stderr)=$handle->cwd("/opt/$oldir");
   # http://www.openldap.org/faq/data/cache/1113.html
   my $lf="export LDFLAGS=\'-L/usr/local/BerkeleyDB.5.1/lib ".
                         "-L/usr/lib64 -L/usr/local/lib ".
                         "-Wl,-rpath,/usr/local/BerkeleyDB.5.1/lib ".
                         "-Wl,-rpath,/usr/lib64 ".
                         "-Wl,-rpath,/usr/local/lib\'";
   my $cp="export CPPFLAGS=\'-I/usr/local/BerkeleyDB.5.1/include ".
                          "-I/usr/include/sasl\'";
   #my $lp='export LD_LIBRARY_PATH=/usr/local/BerkeleyDB.5.1/lib:'
   #      .'/usr/lib64:/usr/local/lib';
   ($stdout,$stderr)=$handle->cmd(
      "sudo bash -lc \"$lf;$cp;./configure --with-cyrus-sasl\"",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo make depend",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo make",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo make install",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo /usr/local/libexec/slapd",
      '__allow_no_output__');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y update",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y install httpd24 php54",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo /usr/sbin/apachectl start",
      '__allow_no_output__');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y install php54-ldap",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo /usr/sbin/apachectl restart",
      '__allow_no_output__');
   ($stdout,$stderr)=$handle->cwd("/var/www/html");
   my $master=$main::aws->{$server_type}->[$cnt]->[0]->{InstanceId};
   $c="aws ec2 describe-instances --instance-ids $master 2>&1";
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   my $mdns=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicDnsName};
   my $pbip=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicIpAddress};
   my $dcnt=0;
   my $extn='';
   while (1) {
      ($stdout,$stderr)=$handle->cmd("wget --random-wait -qO- ".
         "http://sourceforge.net/projects/phpldapadmin/files");
      $stdout=~s/^.*latest\/download.*?title="(.*?):.*$/$1/s;
      $extn=$stdout;
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "http://sourceforge.net/projects/phpldapadmin/files$extn",
         '__display__');
      next if (-1<index $stderr,'ERROR 404') && $dcnt++<3;
      last
   }
   if ($extn=~/zip/) {
      ($stdout,$stderr)=$handle->cmd("sudo unzip *zip",'__display__');
      ($stdout,$stderr)=$handle->cmd("sudo rm -vf *zip",'__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd("sudo tar zxvf *tgz",'__display__');
      ($stdout,$stderr)=$handle->cmd("sudo rm -vf *tgz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo mv -T phpldapadmin* phpldapadmin",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo cp -v phpldapadmin/config/con* phpldapadmin/config/config.php",
      '__display__');
   print "\n   ACCESS OPENLDAP UI AT:\n\n",
         " http://$mdns/phpldapadmin\n";
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


   Copyright © 2000-2019  Brian M. Kelly  Brian.Kelly@FullAuto.com

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
            "   to start with your new OpenLDAP™ installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_openldap=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $openldap="]T[{select_openldap_setup}";
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
      'OpenLDAPSecurityGroup --description '.
      '"OpenLDAP.org Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name OpenLDAPSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name OpenLDAPSecurityGroup --protocol '.
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name OpenLDAPSecurityGroup --protocol '.
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'OpenLDAP.org'}) {
      my $g=get_aws_security_id('OpenLDAPSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'OpenLDAP.org'}}==0) {
         launch_server('OpenLDAP.org',$cnt,$openldap,'',$c,
         $configure_openldap);
      } else {
         my $num=$#{$main::aws->{'OpenLDAP.org'}}-1;
         foreach my $num (0..$num) {
            launch_server('OpenLDAP.org',$cnt++,$openldap,'',$c,
            $configure_openldap);
         }
      }
   }

   return '{choose_demo_setup}<';

};

my $openldap_setup_summary=sub {

   package openldap_setup_summary;
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
   my $openldap="]T[{select_openldap_setup}";
   $openldap=~s/^"//;
   $openldap=~s/"$//;
   print "REGION=$region and TYPE=$type\n";
   print "OPENLDAP=$openldap\n";
   my $num_of_servers=0;
   my $ol=$openldap;
   $ol=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ol==1) {
      $main::aws->{'OpenLDAP.org'}->[0]=[];
   } elsif ($ol=~/^\d+$/ && $ol) {
      foreach my $n (0..$ol) {
         $main::aws->{'OpenLDAP.org'}=[] unless exists
            $main::aws->{'OpenLDAP.org'};
         $main::aws->{'OpenLDAP.org'}->[$n]=[];
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

         $openldap


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_openldap,

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

our $select_openldap_setup=sub {

   my @options=('OpenLDAP & Berkeley DB on 1 Server');
   my $openldap_setup_banner=<<'END';


                     *    *    *
                *                   *
            *                            *
         *                                  *
       *                                      *
     *                                          *
      ____                 _    ____    _    ____ TM
     / __ \____  ___  ____| |  |  _ \  / \  |  _ \
    / / / / __ \/ _ \/ __ \ |  | | | |/ _ \ | |_) |
   / /_/ / /_/ /  __/ / / / |__| |_| / ___ \| ___/
   \____/ .___/\___/_/ /_/|____|____/_/   \_\_|
       /_/

   Choose the OpenLDAP setup you wish to demo. Note that more servers
   means more expense, and more JVMs means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 JVM on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_openldap_setup=(

      Name => 'select_openldap_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $openldap_setup_summary,

      },
      Scroll => 1,
      Banner => $openldap_setup_banner,
   );
   return \%select_openldap_setup

};

1
