package Net::FullAuto::ISets::Amazon::Chef_is;

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
our $DISPLAY='Chef® High Availability';
our $CONNECT='ssh';
our $defaultInstanceType='t2.small';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_chef_setup);

use Net::FullAuto::Cloud::fa_amazon;

my $configure_mysql=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $lr_inst=$main::aws->{'Chef.io'}->[$cnt]->[0];
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd(
      "sudo apt-get -y -o Dpkg::Progress=true update 2>&1",'__display__');
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
   my $lr_release=$main::aws->{Chef_Release};
   $lr_release=~/liferay.*portal-(.*)-(?:ce-)?(.*)$/;
   my $rnum=$1;my $rtyp=$2;
   print "   Downloading Chef.io SQL files . . .\n";
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
   my $lrhandle=$main::aws->{'Chef.io'}->[$cnt]->[1];
   my $pe=$main::aws->{'Chef.io'}->[$cnt]->[2]->[0].
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
   my $tom_dir=$main::aws->{'Chef.io'}->[$cnt]->[2]->[0];
   my $starting_chef=<<'END';


   .oPYo. ooooo    .oo  .oPYo. ooooo o o    o .oPYo.      o    o  .oPYo.
   8        8     .P 8  8   `8   8   8 8b   8 8    8      8    8  8    8
   `Yooo.   8    .P  8  8YooP'   8   8 8`b  8 8           8    8  8YooP'
       `8   8   oPooo8  8   `b   8   8 8 `b 8 8   oo      8    8  8
        8   8  .P    8  8    8   8   8 8  `b8 8    8      8    8  8
   `YooP'   8 .P     8  8    8   8   8 8   `8 `YooP8      `YooP'  8
   ....................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


                          _____ _    _ ______ ______
                         / ____| |  | |  ____|  ____|
                        | |    | |__| | |__  | |__
                        | |    |  __  |  __| |  __|
                        | |____| |  | | |____| |
                         \_____|_|  |_|______|_|



  (Chef Software, Inc. is **NOT** a sponsor of the FullAuto© Project.)

END
   print $starting_chef;sleep 10;
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
   print "\n   ACCESS APACHE WEB SERVER AT:  http://\n\n";

};

my $configure_chef=sub {

   # http://ghost-parnurzeal.rhcloud.com/experimental-ha-for-opensource-chef-server/
   # http://ghost-parnurzeal.rhcloud.com/
   #    experimental-ha-for-opensource-chef-server-part-iii-loadbalancer-by-nginx/

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $server_host_block=$_[3]||'';
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my ($stdout,$stderr,$url)=(''.''.'');
   ($stdout,$stderr)=$handle->cmd(
      "sudo apt-get -y -o Dpkg::Progress=true update 2>&1",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'apt-get -y -o Dpkg::Progress=true install gnupg2','__display__');
   ($stdout,$stderr)=$handle->cmd(
      'gpg2 --keyserver hkp://keys.gnupg.net --recv-keys '.
      '409B6B1796C275462A1703113804BB82D39DC0E3','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'sudo apt-get -y -o Dpkg::Progress=true install autoconf automake gcc '.
      'g++ libtool libyaml-dev make nasm pkg-config wget flex patch '.
      'libreadline6 libreadline6-dev zlibc zlib1g zlib1g-dev libsqlite3-dev '.
      'libffi-dev libssl-dev bzip2 libtool bison ruby-dev libxml2 git zip '.
      'rebar rabbitmq-server python-dev xsltproc libxml2-dev libxslt1-dev '.
      'build-essential libssh-dev unixodbc-dev libpq-dev',
      '__display__'); # erlang erlang-eunit
   ($stdout,$stderr)=$handle->cmd(
      'curl -sSL https://get.rvm.io | bash -s stable',300,'__display__');
   ($stdout,$stderr)=$handle->cmd_raw('source ~/.rvm/scripts/rvm');
   ($stdout,$stderr)=$handle->cmd(
      'rvm install ruby-2.0.0-p648','__display__');
print "RVM=$stdout<==\n";
   ($stdout,$stderr)=$handle->cmd(
      'rvm use 2.0.0','__display__');
print "RVM NEXT=$stdout<==\n";
   ($stdout,$stderr)=$handle->cmd_raw('source ~/.rvm/scripts/rvm');
   ($stdout,$stderr)=$handle->cmd_raw('export PATH='.
      '/home/ubuntu/.rvm/rubies/ruby-2.0.0-p648/bin:$PATH');
   ($stdout,$stderr)=$handle->cmd(
      'gem install io-console','__display__');
   ($stdout,$stderr)=$handle->cmd(
      'gem install bundler','__display__');
   ($stdout,$stderr)=$handle->cmd('gem install yard','__display__');
   ($stdout,$stderr)=$handle->cmd('yard config --gem-install-yri',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'wget http://www.erlang.org/download/otp_src_17.0.tar.gz');
   ($stdout,$stderr)=$handle->cmd(
      'tar xf otp_src_17.0.tar.gz');
   ($stdout,$stderr)=$handle->cwd('otp_src_17.0');
   ($stdout,$stderr)=$handle->cmd(
      './configure','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   my $download_chef=<<'END';


   ooo.   .oPYo. o      o o    o o     .oPYo.      .oo ooo.   o o    o .oPYo.
   8  `8. 8    8 8      8 8b   8 8     8    8     .P 8 8  `8. 8 8b   8 8    8
   8   `8 8    8 8      8 8`b  8 8     8    8    .P  8 8   `8 8 8`b  8 8
   8    8 8    8 8  db  8 8 `b 8 8     8    8   oPooo8 8    8 8 8 `b 8 8   oo
   8   .P 8    8 `b.PY.d' 8  `b8 8     8    8  .P    8 8   .P 8 8  `b8 8    8
   8ooo'  `YooP'  `8  8'  8   `8 8oooo `YooP' .P     8 8ooo'  8 8   `8 `YooP8
   ..........................................................................
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


                           _____ _    _ ______ ______
                          / ____| |  | |  ____|  ____|
                         | |    | |__| | |__  | |__
                         | |    |  __  |  __| |  __|
                         | |____| |  | | |____| |
                          \_____|_|  |_|______|_|



     (Chef Software, Inc. is **NOT** a sponsor of the FullAuto© Project.)

END
   print $download_chef;sleep 10;
   ($stdout,$stderr)=$handle->cmd(
      'git clone https://github.com/antirez/redis.git','__display__');
   ($stdout,$stderr)=$handle->cwd('redis');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cmd(
      '/usr/local/bin/redis-server --daemonize yes','__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd(
      'git clone https://github.com/chef/chef-server.git','__display__');
   ($stdout,$stderr)=$handle->cwd('chef-server');
   ($stdout,$stderr)=$handle->cmd('make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo chmod -v 777 /var','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo chmod -v 777 /var/cache','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo chmod -v 777 /opt','__display__');
   ($stdout,$stderr)=$handle->cmd('rvm install 2.2.6','__display__');
   ($stdout,$stderr)=$handle->cmd_raw('rvm --default use 2.2.6');
   ($stdout,$stderr)=$handle->cmd('env','__display__');
   ($stdout,$stderr)=$handle->cmd('gem install bundle','__display__');
print "STDOUT=$stdout<== & STDERR=$stderr<==\n";
   ($stdout,$stderr)=$handle->cmd('gem install test-kitchen','__display__');
   ($stdout,$stderr)=$handle->cwd('omnibus');
   ($stdout,$stderr)=$handle->cmd('bundle install --binstubs','__display__');
   ($stdout,$stderr)=$handle->cmd('bin/omnibus build chef-server',10000,
      '__display__');

};

my $standup_chef=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $chef="]T[{select_chef_setup}";
   my $i=$main::aws->{fullauto}->{ImageId}||'';
   my $os='Ubuntu';
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
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error;
   my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
            ->[0]->{IpRanges}->[0]->{CidrIp};
   $c='aws ec2 create-security-group --group-name '.
      'ChefSecurityGroup --description '.
      '"Chef.io Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ChefSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ChefSecurityGroup --protocol '.
      'tcp --port 8080 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ChefSecurityGroup --protocol '.
      'tcp --port 8081 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'Chef.io Server'}) {
      my $g=get_aws_security_id('ChefSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
            "--instance-type $type --key-name \'$pemfile\' ".
            "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'Chef.io Server'}}==0) {
         launch_server('Chef.io Server',$cnt,$chef,'ubuntu',$c,
                       $configure_chef);
      } else {
         my $num=$#{$main::aws->{'Chef.io Server'}}-1;
         $c.=' --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":20,\"DeleteOnTermination\":true}}]"';
         foreach my $num (0..$num) {
            launch_server('Chef.io Server',$cnt++,$chef,'ubuntu',
            $c,$configure_chef);
         }
      }
      $cnt=0;
      if ($#{$main::aws->{'Chef.io Workstation'}}==0) {
         launch_server('Chef.io Workstation',$cnt,$chef,'ubuntu',$c,
                       $configure_chef);
      } else {
         my $num=$#{$main::aws->{'Chef.io Workstation'}}-1;
         foreach my $num (0..$num) {
            launch_server('Chef.io Workstation',$cnt++,$chef,'ubuntu',
            $c,$configure_chef);
         }
      }
      $cnt=0;
      if ($#{$main::aws->{'Chef.io Apache Node'}}==0) {
         launch_server('Chef.io Apache Node',$cnt,$chef,'ubuntu',$c,
                       $configure_chef);
      } else {
         my $num=$#{$main::aws->{'Chef.io Apache Node'}}-1;
         foreach my $num (0..$num) {
            launch_server('Chef.io Apache Node',$cnt++,$chef,'ubuntu',
            $c,$configure_chef);
         }
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
            "   to start with your new Chef installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $chef_setup_summary=sub {

   package chef_setup_summary;
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
   my $chef="]T[{select_chef_setup}";
   $chef=~s/^"//;
   $chef=~s/"$//;
   #print "REGION=$region and TYPE=$type\n";
   #print "LIFERAY=$liferay and DB=$database\n";
   #print "HTTPD=$httpd\n";
   my $num_of_servers=0;
   my $ch=$chef;
   $ch=~s/^.*(\d+)\sChef Server.*$/$1/;
   if ($ch==1) {
      $main::aws->{'Chef.io Server'}->[0]=[];
   } elsif ($ch=~/^\d+$/ && $ch) {
      foreach my $n (0..$ch) {
         $main::aws->{'Chef.io Server'}=[] unless exists
            $main::aws->{'Chef.io Server'};
         $main::aws->{'Chef.io Server'}->[$n]=[];
      }
   }
   my $ws=$chef;
   $ws=~s/^.*(\d+)\sChef Workstation.*$/$1/;
   if ($ws==1) {
      $main::aws->{'Chef.io Workstation'}->[0]=[];
   } elsif ($ws=~/^\d+$/ && $ws) {
      foreach my $n (0..$ws) {
         $main::aws->{'Chef.io Workstation'}=[] unless exists
            $main::aws->{'Chef.io Workstation'};
         $main::aws->{'Chef.io Workstation'}->[$n]=[];
      }
   }
   my $an=$chef;
   $an=~s/^.*(\d+)\sApache Node.*$/$1/;
   if ($an==1) {
      $main::aws->{'Chef.io Apache Node'}->[0]=[];
   } elsif ($an=~/^\d+$/ && $an) {
      foreach my $n (0..$an) {
         $main::aws->{'Chef.io Apache Node'}=[] unless exists
            $main::aws->{'Chef.io Apache Node'};
         $main::aws->{'Chef.io Apache Node'}->[$n]=[];
      }
   }
   $num_of_servers=$ch+$ws+$an;
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
         AWS EC2 $type servers for the FullAuto Setup:

         $chef

END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_chef,

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

my $select_httpd_for_chef=sub {

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
   my %select_httpd_for_chef=(

      Name => 'select_httpd_for_chef',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $chef_setup_summary,

      },
      Scroll => 2,
      Banner => $select_database_banner,

   );
   return \%select_httpd_for_chef;

};

my $select_database_for_chef=sub {

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
   my %select_database_for_chef=(

      Name => 'select_database_for_chef',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $select_httpd_for_chef,

      },
      Scroll => 1,
      Banner => $select_database_banner,

   );
   return \%select_database_for_chef;

};

our $select_chef_setup=sub {

   my @options=('2 Chef Servers 1 Chef Workstation 1 Apache Node');
   my $chef_setup_banner=<<'END';

     ___ _  _ ___ ___     ___      _
    / __| || | __| __|   / __| ___| |_ _  _ _ __
   | (__| __ | _|| _|    \__ \/ -_)  _| || | '_ \
    \___|_||_|___|_|     |___/\___|\__|\_,_| .__/
                                           |_| 

   Choose the Chef setup you wish to demo. Note that more servers
   means more expense, and more JVMs means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 JVM on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_chef_setup=(

      Name => 'select_chef_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         #Result => $select_database_for_chef,
         Result => $chef_setup_summary,

      },
      Scroll => 1,
      Banner => $chef_setup_banner,
   );
   return \%select_chef_setup,

};

1
