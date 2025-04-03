package Net::FullAuto::ISets::Amazon::KaliLinux_is;

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

our $VERSION='0.02';
our $DISPLAY='Kali Linux™';
our $CONNECT='ssh';
our $defaultInstanceType='t2.micro';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_kali_setup);

use Net::FullAuto::Cloud::fa_amazon;

my $install_dashboard_on_kalilinux=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $server_host_block=$_[2]||'';
   my $handle=$_[3];
   my ($stdout,$stderr,$hash,$error,$output)=('','','','',''); 
   ($stdout,$stderr)=$handle->cmd(
       "sudo apt-get -o Dpkg::Progress=true -y install apache2",3600,
       '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo sed -e 's/index.php //' ".
        "/etc/apache2/mods-enabled/dir.conf");
   ($stdout,$stderr)=$handle->cmd("sudo sed -e 's/Index/Index index.php/' ".
        "/etc/apache2/mods-enabled/dir.conf");
   ($stdout,$stderr)=$handle->cmd("sudo service apache2 restart");
   ($stdout,$stderr)=$handle->cmd(
      "sudo apt-get -o Dpkg::Progress=true -y install git",3600,'__display__');
   if ($stderr) {
      print "Kali Linux Instruction Set aws cmd ERROR!: $stderr at Line",
         __LINE__,"\n";
      Net::FullAuto::FA_Core::cleanup();
   }
   ($stdout,$stderr)=$handle->cwd("/var/www/html");
   ($stdout,$stderr)=$handle->cmd("sudo git clone ".
       "https://github.com/afaqurk/linux-dash.git 2>&1",
       '__display__');
   ($stdout,$stderr)=$handle->cmd(
       "sudo apt-get -o Dpkg::Progress=true -y install php5 ".
       "libapache2-mod-php5 php5-mcrypt",3600,
       '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo /usr/sbin/apache2ctl start",
      '__allow_no_output__');
   my $master=$main::aws->{$server_type}->[$cnt]->[0]->{InstanceId};
   my $c="aws ec2 describe-instances --instance-ids $master 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   my $mdns=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicDnsName};
   print "\n   ACCESS KALI LINUX DASHBOARD AT:\n\n",
         " http://$mdns/linux-dash\n";
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


   Copyright © 2000-2025  Brian M. Kelly  Brian.Kelly@FullAuto.com

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
            "   to start with your new Kali Linux™ installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $configure_kalilinux=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd("sudo apt-get update");
   ($stdout,$stderr)=$handle->cmd("sudo apt-get -o Dpkg::Progress=true ".
      "-y install build-essential",3600,'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo apt-get -o Dpkg::Progress=true ".
      "-y install git",3600,'__display__'); 
   ($stdout,$stderr)=$handle->cmd("sudo gpg --ignore-time-conflict ".
      "--no-options --no-default-keyring --homedir /tmp/tmp.J6INeDB25r ".
      "--no-auto-check-trustdb --trust-model always --keyring ".
      "/etc/apt/trusted.gpg --primary-keyring /etc/apt/trusted.gpg ".
      "--keyserver pgp.mit.edu --recv-keys ED444FF07D8D0BF6",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo apt update",'__display__');
   if ($stderr && $stderr!~/WARNING/) {
      print "Kali Linux Instruction Set cmd ERROR!: $stderr at Line".
         __LINE__."\n";
      Net::FullAuto::FA_Core::cleanup();
   }
   # BUILDING uses Jazmine Figlet Font
   my $install_kali=<<'END';

                oooo.  o    o o o     ooo.   o o    o .oPYo.
                8   `8 8    8 8 8     8  `8. 8 8b   8 8    8
                8YooP' 8    8 8 8     8   `8 8 8`b  8 8
                8   `b 8    8 8 8     8    8 8 8 `b 8 8   oo
                8    8 8    8 8 8     8   .P 8 8  `b8 8    8
                8oooP' `YooP' 8 8oooo 8ooo'  8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


        ##  ##   ##   ##     ##     ##     ## ##   ## ##   ## ##  ## TM
        ##  ##  ####  ##     ##     ##     ## ###  ## ##   ## ##  ##
        ## ##  ##  ## ##     ##     ##     ## #### ## ##   ##  ####
        ####   ##  ## ##     ##     ##     ## ## #### ##   ##   ##
        ## ##  ###### ##     ##     ##     ## ##  ### ##   ##  ####
        ##  ## ##  ## ##     ##     ##     ## ##   ## ##   ## ##  ##
        ##  ## ##  ## ###### ##     ###### ## ##   ##  #####  ##  ##


   http://www.kali.org

   (The Kali Linux™ Project is **NOT** a sponsor of the FullAuto© Project.)
END
   print $install_kali;sleep 10;
   ($stdout,$stderr)=$handle->cmd("sudo git clone ".
      "https://github.com/LionSec/katoolin.git",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo cp katoolin/katoolin.py ".
      "/usr/bin/katoolin",'__display__');
   $install_dashboard_on_kalilinux->($_[0],$_[1],$_[2],$handle);

};

my $standup_kali_linux=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   $main::aws->{kali}->{type}=$type;
   my $os='Ubuntu';
   my $kali="]T[{select_kali_setup}";
   $main::aws->{kali}->{kali}=$kali;
   my $i=$main::aws->{fullauto}->{ImageId}||'';
   if ($os eq 'Ubuntu') {
      my $region = "wget -qO- http://169.254.169.254/latest/".
                   "dynamic/instance-identity/document|grep region";
      $region=`$region`;
      $region=~s/^.*: ["](.*)["],?\s*$/$1/s;
      my ($hash,$output,$error)=('','','');
      ($hash,$output,$error)=run_aws_cmd(
         "aws ec2 describe-images --owners 099720109477 ".
         "--filters \"Name=root-device-type,Values=ebs\"".
         " \"Name=virtualization-type,Values=hvm\" ".
         "\"Name=architecture,Values=x86_64\" --region=$region");
      my %images=();
      foreach my $image (@{$hash->{Images}}) {
         $images{$image->{CreationDate}}=$image
            if $image->{Name}=~/ubuntu-trusty/;
      }

      my $image_hash=$images{(reverse sort keys %{images})[0]};
      $i=$image_hash->{ImageId};
   }
   my $s=$main::aws->{fullauto}->
         {NetworkInterfaces}->[0]->{SubnetId}||'';
   my $g=$main::aws->{fullauto}->
         {SecurityGroups}->[0]->{GroupId}||'';
   my $n=$main::aws->{fullauto}->
         {SecurityGroups}->[0]->{GroupName}||'';
   my $c='aws ec2 describe-security-groups '.
         "--group-names $n";
   my $u=($os eq 'Ubuntu')?'ubuntu':'';
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error;
   my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
            ->[0]->{IpRanges}->[0]->{CidrIp};
   $c='aws ec2 create-security-group --group-name '.
      'KaliLinuxSecurityGroup --description '.
      '"Kali.org Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name KaliLinuxSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name KaliLinuxSecurityGroup --protocol '.
      'tcp --port 0-65535 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name KaliLinuxSecurityGroup --protocol '.
      'icmp --port -1 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'Kali.org'}) {
      my $g=get_aws_security_id('KaliLinuxSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'Kali.org'}}==0) {
         launch_server('Kali.org',$cnt,$kali,$u,$c,$configure_kalilinux);
      } else {
         my $num=$#{$main::aws->{'Kali.org'}}-1;
         my @tags=('Name Node','Secondary Name Node','Slave 1','Slave 2');
         foreach my $num (0..$num) {
            launch_server('Kali.org',$cnt++,$kali,$u,$c,
                          $configure_kalilinux,$tags[$num]);
         }
      }
   }

   return '{choose_demo_setup}<';

};

my $kali_setup_summary=sub {

   package kali_setup_summary;
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
   my $kali="]T[{select_kali_setup}";
   $kali=~s/^"//;
   $kali=~s/"$//;
   print "REGION=$region and TYPE=$type\n";
   print "KALI=$kali\n";
   my $num_of_servers=0;
   my $hp=$kali;
   $hp=~s/^.*(\d+)\sServer.*$/$1/;
   if ($hp==1) {
      $main::aws->{'Kali.org'}->[0]=[];
   } elsif ($hp=~/^\d+$/ && $hp) {
      foreach my $n (0..$hp) {
         $main::aws->{'Kali.org'}=[] unless exists
            $main::aws->{'Kali.org'};
         $main::aws->{'Kali.org'}->[$n]=[];
      }
   }
   $num_of_servers=$hp;
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

         $kali


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_kali_linux,

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

our $select_kalilinux_setup=sub {

   my @options=('Kali Linux™ on 1 Server');
   my $kali_setup_banner=<<'END';


   ##  ##   ##   ##     ##     ##     ## ##   ## ##   ## ##  ## TM
   ##  ##  ####  ##     ##     ##     ## ###  ## ##   ## ##  ##
   ## ##  ##  ## ##     ##     ##     ## #### ## ##   ##  ####
   ####   ##  ## ##     ##     ##     ## ## #### ##   ##   ##
   ## ##  ###### ##     ##     ##     ## ##  ### ##   ##  ####
   ##  ## ##  ## ##     ##     ##     ## ##   ## ##   ## ##  ##
   ##  ## ##  ## ###### ##     ###### ## ##   ##  #####  ##  ##

   http://www.kali.org

   (The Kali Linux™ Project is **NOT** a sponsor of the FullAuto© Project.)

   Choose the Kali Linux™ setup you wish to demo. Note that more servers
   means more expense, and more JVMs means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 JVM on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_kali_setup=(

      Name => 'select_kali_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $kali_setup_summary,

      },
      Scroll => 1,
      Banner => $kali_setup_banner,
   );
   return \%select_kali_setup,

};

1
