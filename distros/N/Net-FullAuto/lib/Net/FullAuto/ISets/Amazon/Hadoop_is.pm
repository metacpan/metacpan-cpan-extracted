package Net::FullAuto::ISets::Amazon::Hadoop_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2023  Brian M. Kelly
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
our $DISPLAY='Apache™ Hadoop®';
our $CONNECT='ssh';
our $defaultInstanceType='t2.micro';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_hadoop_setup);

use Net::FullAuto::Cloud::fa_amazon;

my $configure_hadoop=sub {

   # https://letsdobigdata.wordpress.com/2014/01/13 \
   # /setting-up-hadoop-multi-node-cluster-on-amazon-ec2-part-1/

   # https://letsdobigdata.wordpress.com/2014/01/13 \
   # /setting-up-hadoop-1-2-1-multi-node-cluster-on-amazon-ec2-part-2/

   # http://hortonworks.com/hadoop-tutorial
   # /how-to-process-data-with-apache-hive/

   # http://www.reddit.com/r/hadoop/comments/xkf4e/ \
   # is_apache_pig_slower_than_streaming_perl/

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr,$exitcode,$error)=('','','','');
   ($stdout,$stderr)=$handle->cmd(
      "sudo apt-get -o Dpkg::Progress=true update 2>&1",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo add-apt-repository -y ppa:webupd8team/java",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo apt-get -o Dpkg::Progress=true update 2>&1",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "echo debconf shared/accepted-oracle-license-v1-1 select true | ".
      "sudo debconf-set-selections");
   ($stdout,$stderr)=$handle->cmd(
      "echo debconf shared/accepted-oracle-license-v1-1 seen true | ".
      "sudo debconf-set-selections");
   ($stdout,$stderr)=$handle->cmd(
      "sudo apt-get -o Dpkg::Progress=true -y --force-yes install ".
      "oracle-java8-installer 2>&1",'__display__');
   my $gcnt=2;my $md5='';my $targz='';my $hadoop_mirror='';
   while (--$gcnt) {
      my $url='http://www.apache.org/dyn/closer.cgi/hadoop/common/';
      my $wcnt=4;
      while (--$wcnt) {
         ($stdout,$stderr)=$handle->cmd("wget -qO- $url");
         my $flag=0;
         foreach my $line (split "\n",$stdout) {
            if ($line=~/We\s+suggest/) {
               $flag=1;
            } elsif ($flag && $line=~/^.*[Hh][Rr][Ee][Ff]=["](.*?)["].*$/) {
               $hadoop_mirror=$1;last;
            }
         } last if $hadoop_mirror=~/^http/;
         sleep 1;
      }
      unless ($hadoop_mirror=~/^http/) {
         print "Can't get Apache™ Hadoop® mirror -> $hadoop_mirror\n\n",
               "after 5 attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("wget -qO- ".
         "${hadoop_mirror}stable");
      my $flag=0;
      foreach my $line (split "\n",$stdout) {
         chomp($line);
         if ($line=~/(?<!src)[.]tar[.]gz["]/) {
            $targz=$line;
            $targz=~s/^.*[Hh][Rr][Ee][Ff]=["](.*?)["].*$/$1/;
            ($stdout,$stderr)=$handle->cmd(
               "sudo wget --random-wait --progress=dot $targz 2>&1");
         } elsif ($line=~/(?<!src)[.]tar[.]gz[.]mds/) {
            $md5=$line;
            $md5=~s/^.*[Hh][Rr][Ee][Ff]=["](.*?)["].*$/$1/;
            ($stdout,$stderr)=$handle->cmd(
               "sudo wget --random-wait --progress=dot $md5 2>&1");
            last unless $stderr;
         }
      } last unless $stderr;
   }
   my $download_hadoop=<<'END';

   ooo.   .oPYo. o      o o    o o     .oPYo.      .oo ooo.   o o    o .oPYo.
   8  `8. 8    8 8      8 8b   8 8     8    8     .P 8 8  `8. 8 8b   8 8    8
   8   `8 8    8 8      8 8`b  8 8     8    8    .P  8 8   `8 8 8`b  8 8
   8    8 8    8 8  db  8 8 `b 8 8     8    8   oPooo8 8    8 8 8 `b 8 8   oo
   8   .P 8    8 `b.PY.d' 8  `b8 8     8    8  .P    8 8   .P 8 8  `b8 8    8
   8ooo'  `YooP'  `8  8'  8   `8 8oooo `YooP' .P     8 8ooo'  8 8   `8 `YooP8
   ..........................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                         ,--,
                     ,--/ ,  `.~,
                  (_/  /   ^ ^l i __              __
                    |  V |   __/ / /_  ____ _____/ /___  ____  ____
                   /    \/ \|U  / __ \/ __ `/ __  / __ \/ __ \/ __ \
         Apache™   \/|_|< /_|  / / / / /_/ / /_/ / /_/ / /_/ / /_/ /
                              /_/ /_/\__,_/\__,_/\____/\____/ .___/
                                                           /_/     ®
   http://hadoop.apache.org

   (The Apache™ Foundation is **NOT** a sponsor of the FullAuto© Project.)

END

   print $download_hadoop;sleep 10;
   foreach my $dc (0..2) {
      ($stdout,$stderr,$exitcode)=$handle->cmd(
         "sudo wget --random-wait --progress=dot ".
         "${hadoop_mirror}stable/$targz 2>&1",
         '__display__');
      print "wget ERROR: $stderr\n" if $stderr;
      #($stdout,$stderr)=$handle->cmd(
      #   "sudo wget --random-wait --progress=dot ".
      #   "${hadoop_mirror}stable/$md5 2>&1",
      #   '__display__');
      #($stdout,$stderr)=$handle->cmd("cat $md5");
      #my $checksum=$stdout;
      #$checksum=~s/^.*MD5\s*[=]\s*(.*?)\n$targz.*$/$1/s;
      #$checksum=~s/\s//g;
      #($stdout,$stderr)=$handle->cmd("md5sum -c - <<<\"$checksum $targz\"",
      #   '__display__');
      #unless ($stderr) {
      #   print(qq{ + CHECKSUM Test for $targz *PASSED* \n});
      #} else {
      #   if ($dc<3) {
      #      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $md5",'__display__');
      #      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $targz",'__display__');
      #      next; 
      #   }
      #   print "FATAL ERROR! : CHECKSUM Test for $targz *FAILED* ",
      #         "after $dc attempts\n";
      #   &Net::FullAuto::FA_Core::cleanup;
      #}
      ($stdout,$stderr)=$handle->cmd("sudo tar zxvf $targz -C /opt",
         '__display__');
      $stderr.=$stdout;
      if (-1==index $stderr,'tar: Unexpected EOF in archive') {
         last;
      } else {
         if ($dc<3) {
      #      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $md5",'__display__');
            ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $targz",'__display__');
            next;
         }
         print "FATAL ERROR! : tar: Unexpected EOF in archive ",
               "after $dc attempts\n";
      }
   }
   #($stdout,$stderr)=$handle->cmd("sudo rm -rvf $md5",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $targz",'__display__');
   $targz=~s/[.]tar[.]gz//;
   my $id=$main::aws->{$server_type}->[$cnt]->[0]->{InstanceId};
   my ($hash,$output)=('','');
   my $c="aws ec2 describe-instances --instance-ids $id 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   my $pdns=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicDnsName};
   my $pip=$hash->{Reservations}->[0]->{Instances}->[0]->{PrivateIpAddress};
   ($stdout,$stderr)=$handle->cmd("sudo hostname $pdns");
   ($stdout,$stderr)=$handle->cmd(
      "sudo sed -i \'/127.0.0.1 localhost/c\\$pip $pdns\' /etc/hosts");
   my $sftp_handle='';
   ($sftp_handle,$error)=
      Net::FullAuto::FA_Core::connect_sftp($server_host_block);
   if ($error) {
      print "\n\n   Connect_SSH ERROR!: $error\n\n";
      die;
   }
   use Cwd;
   ($stdout,$stderr)=$sftp_handle->cmd(
      "put '".cwd()."/$pem_file"."'",'__display__');
   $handle->{_cmd_handle}->print('eval `ssh-agent -s`');
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
   }
   ($stdout,$stderr)=$handle->cmd('pwd');
   $handle->{_cmd_handle}->print(
      "ssh-add \'$stdout/$pem_file\'");
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
   }
   if ($cnt==0) {
      $handle->{_cmd_handle}->print('ssh-keygen -t rsa');
      my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
      while (1) {
         my $output=Net::FullAuto::FA_Core::fetch($handle);
         last if $output=~/$prompt/;
         print $output;
         if ($output=~/Enter file/) {
            $handle->{_cmd_handle}->print();
            next;
         } elsif ($output=~/Enter pass/) {
            $handle->{_cmd_handle}->print();
            next;
         } elsif ($output=~/Enter same/) {
            $handle->{_cmd_handle}->print();
            next;
         }
      }
      ($stdout,$stderr)=$handle->cmd(
         "sudo cat /home/ubuntu/.ssh/id_rsa.pub >> ".
         "/home/ubuntu/.ssh/authorized_keys");
      ($stdout,$stderr)=$handle->cmd(
         "sudo chmod -R 600 /home/ubuntu/.ssh/*",
         '__display__');
      ($stdout,$stderr)=$sftp_handle->get(
         '/home/ubuntu/.ssh/id_rsa.pub');
   } else {
      ($stdout,$stderr)=$sftp_handle->put('id_rsa.pub');
      ($stdout,$stderr)=$handle->cmd(
         'cat ~/id_rsa.pub >> ~/.ssh/authorized_keys','__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo chmod -R 600 /home/ubuntu/.ssh/*",
         '__display__');
      unlink "id_rsa.pub" if $cnt==3;
   }
   # http://sed.sourceforge.net/sed1line.txt - useful one line sed scripts
   ($stdout,$stderr)=$handle->cmd('sudo sed -i \'s#[$][{]JAVA_HOME[}]#'.
      '/usr/lib/jvm/java-8-oracle#\' /opt/'.$targz.
      '/etc/hadoop/hadoop-env.sh',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo mkdir -p /opt/$targz/hdfstmp",'__display__');
   my $master=$main::aws->{$server_type}->[0]->[0]->{InstanceId};
   $c="aws ec2 describe-instances --instance-ids $master 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   my $mdns=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicDnsName};
   my $ad='NL<property>NL<name>fs.default.name</name>NL'. # NL is newline
       '<value>hdfs://'.$mdns.':8020</value>NL'.
       '</property>NLNL'.
       '<property>NL'.
       '<name>hadoop.tmp.dir</name>NL'.
       '<value>/opt/'.$targz.'/hdfstmp</value>NL'.
       '</property>NL';
   ($stdout,$stderr)=$handle->cmd(
      "sudo sed -i \'/[<]configuration[>]/a$ad\' ".
      "/opt/$targz/etc/hadoop/core-site.xml");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "sudo sed -i \'s/NL/\'\"`echo \\\\\\n`/g\" ".
      "/opt/$targz/etc/hadoop/core-site.xml");
   $ad='NL<property>NL<name>dfs.replication</name>NL'. # NL is newline
       '<value>2</value>NL'.
       '</property>NLNL'.
       '<property>NL'.
       '<name>dfs.permissions</name>NL'.
       '<value>false</value>NL'.
       '</property>';
   ($stdout,$stderr)=$handle->cmd(
      "sudo sed -i \'/[<]configuration[>]/a$ad\' ".
      "/opt/$targz/etc/hadoop/hdfs-site.xml");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "sudo sed -i \'s/NL/\'\"`echo \\\\\\n`/g\" ".
      "/opt/$targz/etc/hadoop/hdfs-site.xml");
   ($stdout,$stderr)=$handle->cmd(
      "sudo cp /opt/$targz/etc/hadoop/mapred-site.xml.template ".
      "/opt/$targz/etc/hadoop/mapred-site.xml");
   $ad='NL<property>NL<name>mapred.job.tracker</name>NL'. # NL is newline
       '<value>hdfs://'.$mdns.':8021</value>NL'.
       '</property>';
   ($stdout,$stderr)=$handle->cmd(
      "sudo sed -i \'/[<]configuration[>]/a$ad\' ".
      "/opt/$targz/etc/hadoop/mapred-site.xml");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "sudo sed -i \'s/NL/\'\"`echo \\\\\\n`/g\" ".
      "/opt/$targz/etc/hadoop/mapred-site.xml");
   ($stdout,$stderr)=$handle->cmd(
      "sudo rm -rvf /opt/$targz/etc/hadoop/slaves",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo touch /opt/$targz/etc/hadoop/slaves",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo touch /opt/$targz/etc/hadoop/masters",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo chmod -v 777 /opt/$targz/etc/hadoop/slaves",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo chmod -v 777 /opt/$targz/etc/hadoop/masters",'__display__');
   if ($cnt==3) {
      my @dns=();
      foreach my $inum (0..3) {
         my $inid=$main::aws->{$server_type}->[$inum]->[0]->{InstanceId};
         $c="aws ec2 describe-instances --instance-ids $inid 2>&1";
         ($hash,$output,$error)=run_aws_cmd($c);
         my $dns=$hash->{Reservations}->[0]->{Instances}->[0]
                 ->{PublicDnsName};
         push @dns,$dns;
      }
      foreach my $srv (0..3) {
         my $inst=$main::aws->{$server_type}->[$srv]->[1];
         foreach my $in (0..3) {
            my $type=($in<2)?'masters':'slaves';
            print "UPDATING $type with $dns[$in]\n";
            ($stdout,$stderr)=$inst->cmd(
               "sudo echo $dns[$in] >> /opt/$targz/etc/hadoop/$type",
               '__display__');
            ($stdout,$stderr)=$inst->cmd(
               "sudo chown -Rv ubuntu:ubuntu /opt/$targz",
               '__display__');
         }
         ($stdout,$stderr)=$inst->cmd(
            "sudo chmod -v 644 /opt/$targz/etc/hadoop/masters",
            '__display__');
         ($stdout,$stderr)=$inst->cmd(
            "sudo chmod -v 644 /opt/$targz/etc/hadoop/slaves",
            '__display__');
      }
      my $starting_hadoop=<<'END';


   .oPYo. ooooo    .oo  .oPYo. ooooo o o    o .oPYo.      o    o  .oPYo.
   8        8     .P 8  8   `8   8   8 8b   8 8    8      8    8  8    8
   `Yooo.   8    .P  8  8YooP'   8   8 8`b  8 8           8    8  8YooP'
       `8   8   oPooo8  8   `b   8   8 8 `b 8 8   oo      8    8  8
        8   8  .P    8  8    8   8   8 8  `b8 8    8      8    8  8
   `YooP'   8 .P     8  8    8   8   8 8   `8 `YooP8      `YooP'  8
   ....................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                         ,--,
                     ,--/ ,  `.~,
                  (_/  /   ^ ^l i __              __
                    |  V |   __/ / /_  ____ _____/ /___  ____  ____
                   /    \/ \|U  / __ \/ __ `/ __  / __ \/ __ \/ __ \
         Apache™   \/|_|< /_|  / / / / /_/ / /_/ / /_/ / /_/ / /_/ /
                              /_/ /_/\__,_/\__,_/\____/\____/ .___/
                                                           /_/     ®
   http://hadoop.apache.org

   (The Apache™ Foundation is **NOT** a sponsor of the FullAuto© Project.)

END
      print $starting_hadoop;sleep 10;
      $master=$main::aws->{$server_type}->[0]->[1];
      ($stdout,$stderr)=$master->cmd(
         "/opt/$targz/bin/hdfs namenode -format",'__display__');
      ($stdout,$stderr)=$master->cwd("/opt/$targz/sbin");
      $master->{_cmd_handle}->print('./start-all.sh');
      my $prompt=substr($master->{_cmd_handle}->prompt(),1,-1);
      my $cnt=0;my $test_output='';
      foreach (1..100) {
         my $output=Net::FullAuto::FA_Core::fetch($master);
         $test_output.=$output;
         last if $test_output=~/$prompt/;
         print $output;
         if ($test_output=~/[(]yes\/no[)][?]/) {
            $master->{_cmd_handle}->print("yes");
            $test_output='';
         }
      }
      print "\n   ACCESS HADOOP UI AT:\n\n",
            " http://$mdns:50070/dfshealth.html\n";
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


   Copyright © 2000-2023  Brian M. Kelly  Brian.Kelly@FullAuto.com

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
               "   to start with your new Hadoop® installation!\n\n\n";
      } else {
         print $thanks;
      }
      &Net::FullAuto::FA_Core::cleanup;

   }

};

my $standup_hadoop=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $os="]T[{choose_os}";
   $os=~s/^"//;
   $os=~s/"$//;
   my $hadoop="]T[{select_hadoop_setup}";
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
      'HadoopSecurityGroup --description '.
      '"Hadoop.Apache.org Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name HadoopSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name HadoopSecurityGroup --protocol '.
      'tcp --port 0-65535 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name HadoopSecurityGroup --protocol '.
      'icmp --port -1 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'Hadoop.Apache.org'}) {
      my $g=get_aws_security_id('HadoopSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'Hadoop.Apache.org'}}==0) {
         launch_server('Hadoop.Apache.org',$cnt,$hadoop,$u,$c,
                          $configure_hadoop);
      } else {
         my $num=$#{$main::aws->{'Hadoop.Apache.org'}}-1;
         my @tags=('Name Node','Secondary Name Node','Slave 1','Slave 2');
         foreach my $num (0..$num) {
            launch_server('Hadoop.Apache.org',$cnt++,$hadoop,$u,$c,
                          $configure_hadoop,$tags[$num]);
         }
      }
   }

   return '{choose_demo_setup}<';

};

my $hadoop_setup_summary=sub {

   package hadoop_setup_summary;
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
   my $hadoop="]T[{select_hadoop_setup}";
   $hadoop=~s/^"//;
   $hadoop=~s/"$//;
   print "REGION=$region and TYPE=$type\n";
   print "HADOOP=$hadoop\n";
   my $num_of_servers=0;
   my $hp=$hadoop;
   $hp=~s/^.*(\d+)\sServer.*$/$1/;
   if ($hp==1) {
      $main::aws->{'Hadoop.Apache.org'}->[0]=[];
   } elsif ($hp=~/^\d+$/ && $hp) {
      foreach my $n (0..$hp) {
         $main::aws->{'Hadoop.Apache.org'}=[] unless exists
            $main::aws->{'Hadoop.Apache.org'};
         $main::aws->{'Hadoop.Apache.org'}->[$n]=[];
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

         $hadoop


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_hadoop,

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

my $hadoop_oracle_license=sub {

   package hadoop_oracle_license;
   my $oracle_banner=<<'END';

         #######   #######       #        ######## #          ########
        #       #  #      #     # #      #         #         #
       #         # #       #   #   #    #          #        #
       #         # #  ####    #     #   #          #        ########
       #         # #    #    #####   #  #          #        #
        #       #  #     #  #         #  #         #         #
         #######   #      # #         #   ########  ########  ######## ®

        Oracle® Binary Code License Agreement for the Java SE Platform
        Products and JavaFX. You MUST agree to the license available in

                           http://java.com/license

              if you want to use Oracle® JDK with Apache™ Hadoop®.

            (Oracle® is **NOT** a sponsor of the FullAuto© Project.)

END
   my %oracle_license=(

      Name => 'oracle_license',
      Item_1 => {

         Text => 'Yes - I accept the Oracle® Binary Code license terms',
         Result => $hadoop_setup_summary,

      },
      Item_2 => {

         Text => 'No  - The installation will be cancelled',
         Result => sub { return '{choose_demo_setup}<' },

      },
      Scroll => 2,
      Banner => $oracle_banner,

   );
   return \%oracle_license;

};

my $hadoop_choose_os=sub {

   package hadoop_choose_os;
   my @options=(

         'Ubuntu',
         #'Amazon Linux'

   );

   my $show_os_banner=<<'END';

     ___ _                        ___  ___
    / __| |_  ___  ___ ___ ___   / _ \/ __|
   | (__| ' \/ _ \/ _ (_-</ -_) | (_) \__ \
    \___|_||_\___/\___/__/\___|  \___/|___/


END
   my %choose_os=(

      Name => 'choose_os',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $hadoop_oracle_license,

      },
      Scroll => 1,
      Banner => $show_os_banner,

   );
   return \%choose_os;

};

our $select_hadoop_setup=sub {

   my @options=('Apache™ Hadoop® on 4 Servers');
   my $hadoop_setup_banner=<<'END';

                  ,--,
              ,--/ ,  `.~,           http://hadoop.apache.org
           (_/  /   ^ ^l i __              __
             |  V |   __/ / /_  ____ _____/ /___  ____  ____
            /    \/ \|U  / __ \/ __ `/ __  / __ \/ __ \/ __ \
   Apache™  \/|_|< /_|  / / / / /_/ / /_/ / /_/ / /_/ / /_/ /
              `        /_/ /_/\__,_/\__,_/\____/\____/ .___/
                                                    /_/     ®

   (The Apache™ Foundation is **NOT** a sponsor of the FullAuto© Project.)

   Choose the Apache™ Hadoop® setup you wish to demo. Note that more servers
   means more expense, and more JVMs means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 JVM on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_hadoop_setup=(

      Name => 'select_hadoop_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $hadoop_choose_os,

      },
      Scroll => 1,
      Banner => $hadoop_setup_banner,
   );
   return \%select_hadoop_setup,

};

1
