package Net::FullAuto::Cloud::fa_amazon;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2024  Brian M. Kelly
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


use 5.005;


use strict;
use warnings;
use Data::Dump::Streamer;
use JSON::XS;
use Module::Load::Conditional qw[can_load];

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(new_user_amazon run_aws_cmd get_aws_security_id
                 launch_server $configure_aws1 $pem_file $credpath
                 $aws_configure $aws connect_shell cmd_raw
		 fullauto_builddir setup_aws_security is_host_aws);
our $pem_file='';
our $credpath='.';
our $aws={};

sub cmd_raw {

   return &Net::FullAuto::FA_Core::cmd_raw(@_);

}

sub connect_shell {

   return &Net::FullAuto::FA_Core::connect_shell(@_);

}

sub run_aws_cmd {

   my $c=$_[0];
   my $json='';
   my $hash='';
   while (1) {
      eval {
         $SIG{CHLD}="DEFAULT";
         open(AWS,"$c 2>&1|");
         while (my $line=<AWS>) {
            $json.=$line;
         }
         close AWS;
         if (-1<index $json,'A client error') {
            die $json;
         } elsif ($json=~/^\s*[{]/) {
            $hash=decode_json($json);
         }
      };
      if (-1<index $json,'--key-name: expected one argument') {
         my $user=&Net::FullAuto::FA_Core::username();
         if (can_load(modules => { "Term::Menus" => 0 })) {
            $json=~s/^\s*/      /mg;
            my $pack=(caller(2))[0];
            my $method=(caller(2))[3];
            my $error_banner=<<END;

      ERROR! Cannot run Amazon EC2 API command because user $user
             lacks the necessary credentials:

$json
      From package: $pack
      From method:  $method

      You can enter the credentials now, and they will be saved permanently
      on this system, or you can exit FullAuto and add the proper credential
      arguments to your API command. Credentials will need administrator
      privleges for some API commands. If no selection is made, this
      invocation will timeout in 5 minutes, and FullAuto will exit gracefully.

      Please make a selection: 

END
            my %error_menu=(

               Name => 'error_menu',
               Item_1 => {

                  Text => 'Add Permanent Credentials Now',
 
               },
               Item_2 => {

                  Text => 'Exit FullAuto',

               },
               Banner => $error_banner,

            );
            alarm 300;
            my $choice='';
            eval {
               local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
               $choice=Term::Menus::Menu(\%error_menu);
            };
            alarm(0);
            unless (-1<index $choice,'Add Permanent') {
               Net::FullAuto::FA_Core::cleanup();
            } else {
              $Net::FullAuto::Cloud::fa_amazon::configure_aws1->();
              next
            }
         }
      } else { last }
   }
   return $hash,$json,$@;

}

sub is_host_aws {

   my $test_aws='wget --timeout=5 --tries=1 -qO- '.
                'http://169.254.169.254/latest/dynamic/instance-identity/';
   $test_aws=`$test_aws`;
   if (-1<index $test_aws,'signature') {
      return 1;
   } return 0;

}

sub setup_aws_security {

   my $security_group=$_[0];
   my $group_description=$_[1]||'';
   if (is_host_aws) {
      my ($hash,$output,$error)=('','','');
      my $fullauto_inst=
            Net::FullAuto::Cloud::fa_amazon::get_fullauto_instance();
      my $i=$fullauto_inst->{InstanceId};
      my $c="aws ec2 describe-instances --instance-ids $i";
      ($hash,$output,$error)=run_aws_cmd($c);
      my $sg=$hash->{Reservations}->[0]->{Instances}->[0]
                  ->{SecurityGroups}->[0]->{GroupName};
      if ($security_group eq $sg) {
         return "$security_group already set for this host",'';
      }
      my $n=$main::aws->{fullauto}->
            {SecurityGroups}->[0]->{GroupName}||'';
      $c='aws ec2 describe-security-groups '.
            "--group-names $n";
      ($hash,$output,$error)=run_aws_cmd($c);
      return '',$error if $error;
      my $cidr=$hash->{SecurityGroups}->[0]->{IpPermissions}
              ->[0]->{IpRanges}->[0]->{CidrIp};
      $c='aws ec2 create-security-group --group-name '.
         "$security_group --description ".
         "\"$group_description\" 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      return '',$error if $error;
      $c='aws ec2 authorize-security-group-ingress '.
         "--group-name $security_group --protocol ".
         'tcp --port 22 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      return '',$error if $error;
      $c='aws ec2 authorize-security-group-ingress '.
         "--group-name $security_group --protocol ".
         'tcp --port 80 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      return '',$error if $error;
      $c='aws ec2 authorize-security-group-ingress '.
         "--group-name $security_group --protocol ".
         'tcp --port 443 --cidr '.$cidr." 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      return '',$error if $error;
      my $g=get_aws_security_id($security_group);
      $c="aws ec2 modify-instance-attribute --instance-id $i ".
         "--groups $g";
      ($hash,$output,$error)=run_aws_cmd($c);
      $c="aws ec2 describe-instances --instance-ids $i";
      ($hash,$output,$error)=run_aws_cmd($c);
      $sg=$hash->{Reservations}->[0]->{Instances}->[0]
                  ->{SecurityGroups}->[0]->{GroupName};
      print "\n   NEW SECURITY GROUP -> $sg\n\n";
      return "$sg assigned to this host",'';
   } else { return '','NOT AN AWS HOST' }
}

sub get_aws_security_id {

   my $g='aws ec2 describe-security-groups --group-names '.
         $_[0];
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($g);
   &exit_on_error($error) if $error;
   return $hash->{SecurityGroups}->[0]->{GroupId};

}

sub get_fullauto_instance {

   my ($hash,$json,$output,$error)=('','','','');
   ($hash,$output,$error)=
       run_aws_cmd("aws ec2 describe-instances");
   $error=~s/^\s*//;
   $error=~s/: /:\n   /;
   &exit_on_error($error) if $error;
   &exit_on_error($output)
     if $output=~/Could not connect to the endpoint URL/s;
   my ($stdout,$stderr)=('','');
   my $handle=connect_shell();
   ($stdout,$stderr)=$handle->cmd(
      'curl -X PUT "http://169.254.169.254/latest/api/token" '.
      '-H "X-aws-ec2-metadata-token-ttl-seconds: 21600"');
   ($stdout,$stderr)=$handle->cmd(
      "curl -H \"X-aws-ec2-metadata-token: $stdout\" ".
      'http://169.254.169.254/latest/meta-data/local-ipv4');
   my $ipaddress=$stdout;
   foreach my $res (@{$hash->{Reservations}}) {
      foreach my $inst (@{$res->{Instances}}) {
         my $pip=$inst->{PrivateIpAddress}||'';
         next if exists $inst->{State}->{Name} &&
            $inst->{State}->{Name} eq 'terminated';
         if ($pip eq $ipaddress) {
            $main::aws->{fullauto}=$inst;
            return $inst;
         }
      }
   }

};

sub wait_for_instance {

   my $instance_id=$_[0];
   my ($hash,$output,$error)=('','','');
   my $flag=0;
   while (1) {
      my $c="aws ec2 describe-instances --instance-ids ".
            "$instance_id 2>&1";
      ($hash,$output,$error)=run_aws_cmd($c);
      if (-1<index $output,'A client error') {
         unless ($flag) {
            $flag=1;sleep 5;next;
         }
         &exit_on_error($output);
      } elsif ($error) {
         &exit_on_error($error);
      }
      last;
   }
   return $hash->{Reservations}->[0]->{Instances}->[0]->{State}->{Name};

}

sub launch_instance {

   my $launch_cmd=$_[0];
   my $server_type=$_[1];
   my $cnt=$_[2];
   my $num=$_[3];
   my $username=$_[4];
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($launch_cmd);
   if ($error) {
      &exit_on_error($error);
   } elsif ($output=~/An error occurred/) {
      &exit_on_error($output);
   }
   my $inst=$hash->{Instances}->[0];
   my $server_launch=<<'END';


   :'######::'########:'########::'##::::'##:'########:'########::
   '##... ##: ##.....:: ##.... ##: ##:::: ##: ##.....:: ##.... ##:
    ##:::..:: ##::::::: ##:::: ##: ##:::: ##: ##::::::: ##:::: ##:
   . ######:: ######::: ########:: ##:::: ##: ######::: ########::
   :..... ##: ##...:::: ##.. ##:::. ##:: ##:: ##...:::: ##.. ##:::
   '##::: ##: ##::::::: ##::. ##:::. ## ##::: ##::::::: ##::. ##::
   . ######:: ########: ##:::. ##:::. ###:::: ########: ##:::. ##:
   :......:::........::..:::::..:::::...:::::........::..:::::..::
   '##::::::::::'###::::'##::::'##:'##::: ##::'######::'##::::'##:
    ##:::::::::'## ##::: ##:::: ##: ###:: ##:'##... ##: ##:::: ##:
    ##::::::::'##:. ##:: ##:::: ##: ####: ##: ##:::..:: ##:::: ##:
    ##:::::::'##:::. ##: ##:::: ##: ## ## ##: ##::::::: #########:
    ##::::::: #########: ##:::: ##: ##. ####: ##::::::: ##.... ##:
    ##::::::: ##.... ##: ##:::: ##: ##:. ###: ##::: ##: ##:::: ##:
    ########: ##:::: ##:. #######:: ##::. ##:. ######:: ##:::: ##:
   ........::..:::::..:::.......:::..::::..:::......:::..:::::..::

END
   print $server_launch;sleep 3;my $icnt=0;
   until (wait_for_instance($inst->{InstanceId})
         eq 'running') {
      print "\n   Waiting for new server ${server_type}-$num to ".
            "come online -> pending\n";
      sleep 3;
      last if $icnt++==30;
   }
   print "\n   Waiting for new server ${server_type}-$num to ".
         "come online -> running\n";
   my $server_host_block={

      Label => $server_type.'-'.$num,
      IP =>  $inst->{PrivateIpAddress},
      LoginID => $username,
      IdentityFile => "$credpath/$pem_file",

   };
   return $server_host_block,$inst;
}

sub add_and_tag_server {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $inst=$_[2];
   my $tag=$_[3]||'';
   $tag=" $tag" if $tag;
   $main::aws->{$server_type}->[$cnt]->[0]=$inst;
   my ($hash,$output,$error)=('','','');
   my $value="$server_type-".++$cnt."$tag";
   my $n='';
   foreach my $tag (0..2) {
      $n="aws ec2 create-tags --resources $inst->{InstanceId}".
            " --tags Key=Name,Value=\"$value\" 2>&1";
      ($hash,$output,$error)=run_aws_cmd($n);
      my $t="aws ec2 describe-tags --filters ".
            "\"Name=value,Values=$value\"";
      ($hash,$output,$error)=run_aws_cmd($t);
      last if -1<index $output,$inst->{InstanceId};
   }
   FT: foreach my $tag (0..2) {
      $n="aws ec2 create-tags --resources $inst->{InstanceId} --tags ".
         "Key=FullAuto,Value=$main::aws->{fullauto}->{InstanceId} 2>&1";
      ($hash,$output,$error)=run_aws_cmd($n);
      my $t="aws ec2 describe-tags --filters \"Name=value,".
            "Values=$main::aws->{fullauto}->{InstanceId}\"";
      ($hash,$output,$error)=run_aws_cmd($t);
      $hash||={};
      foreach my $tag (@{$hash->{Tags}}) {
         if ($tag->{Key} eq 'FullAuto' && $tag->{ResourceId} eq
               $inst->{InstanceId}) {
            last FT;
         }
      }
   }

}

sub fullauto_builddir {

   my $handle=$_[0];
   my $sudo=$_[1]||'';
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd("${sudo}perl -e \'use CPAN;".
      "CPAN::HandleConfig-\>load;print \$CPAN::Config-\>{build_dir}\'");
   my $builddir=$stdout;
   my $fa_ver=$Net::FullAuto::VERSION;
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}ls -1t $builddir | grep Net-FullAuto-$fa_ver");
   my @lstmp=split /\n/,$stdout;
   my @ls_tmp=();
   foreach my $line (@lstmp) {
      unshift @ls_tmp, $line if $line!~/\.yml$/;
   }
   return $builddir.'/'.$ls_tmp[0];

}

sub launch_server {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $username=$_[3]||&Net::FullAuto::FA_Core::username();
   my $launch_cmd=$_[4]||'';
   my $configure_server=$_[5]||
         sub { print "NO configure_server method defined!" };
   my $tag=$_[6]||'';
   my $num=$cnt+1;
   my ($server_host_block,$handle,$hash,$output,$error,$inst)=('','','','','');
   foreach my $count (0..2) {
      ($server_host_block,$inst)=launch_instance(
         $launch_cmd,$server_type,$cnt,$num,$username);
      my $iset=$Net::FullAuto::ISets->{selected_iset};
      my $c=$Net::FullAuto::ISets->{$iset}->[1].'CONNECT'||'';
      eval "\$c=$c" if $c;
      $c='secure' unless $c;
      my $s=$server_host_block;
      if ($c=~/secure/i) {
         ($handle,$error)=Net::FullAuto::FA_Core::connect_secure($s);
      } elsif ($c=~/sftp/) {
         ($handle,$error)=Net::FullAuto::FA_Core::connect_sftp($s);
      } else {
         ($handle,$error)=Net::FullAuto::FA_Core::connect_ssh($s);
      }
      if ($error) {
         my $stderr=$error;
         my $t="aws ec2 terminate-instances --instance-id $inst->{InstanceId}";
         ($hash,$output,$error)=run_aws_cmd($t);
         &exit_on_error($stderr) if $count>1;
         next;
      }
      last;
   }
   if ($error) {
      print "\n\n   Connect_SSH ERROR!: $error\n\n";
      print "Connect_SSH ERROR!: $error\n";
      Net::FullAuto::FA_Core::cleanup();
   }
   add_and_tag_server($server_type,$cnt,$inst,$tag);
   $main::aws->{$server_type}->[$cnt]->[1]=$handle;
   my ($stdout,$stderr,$exitcode)=('','','');
   $configure_server->($server_type,$cnt,$selection,$server_host_block,
                       @_[7..$#_]);
}

our $aws_configure=sub {

   my $username=&Net::FullAuto::FA_Core::username();
   if (-1<$#_) {
      $main::aws->{access_id}=$_[0];
      $main::aws->{secret_key}=$_[1];
   } else {
      $main::aws->{access_id}="]I[{'configure_aws2',1}";
      $main::aws->{secret_key}="]I[{'configure_aws2',2}";
   }
   my $region='wget -qO- http://instance-data/latest/meta-data'.
              '/placement/availability-zone';
   $region=`$region`;
   chop $region;
   my $homedir='.';
   if (can_load(modules => { "File::HomeDir" => 0 })) {
      $homedir=File::HomeDir->my_home;
   } elsif (-r "/home/$username") {
      $homedir="/home/$username";
   }
   if (-e "/home/$username/.aws") {
      eval {
         `rm -rf /home/$username/.aws`;
         `rm -rf /root/.aws`;
      };
   }
   {
      $SIG{CHLD}="DEFAULT";
      my $cmd="aws configure";
      use IO::Pty;
      my $pty = IO::Pty->new;
      my $slave = $pty->slave;
      $pty->slave->set_raw();
      $pty->set_raw();
      my $pid = fork(); die "bad fork: $!\n" unless defined $pid;
      if (!$pid) {
         $pty->close();
         $pty->make_slave_controlling_terminal();
         open( STDIN,  ">&", $slave ) or die "Couldn't dup stdin:  $!";
         open( STDOUT, ">&", $slave ) or die "Couldn't dup stdout: $!";
         open( STDERR, ">&", $slave ) or die "Couldn't dup stderr: $!";
         exec $cmd;
      } else {
         $pty->close_slave();
         my $line='';
         while ( !$pty->eof ) {
            while (defined($_ = $pty->getc)) {
               $line.=$_;
               if ($line=~/Access Key ID \[None\]:\s*$/) {
                  for (1..length $line) {
                     $pty->ungetc(ord);
                  }
                  $line='';
                  $pty->print("$main::aws->{access_id}\n");
               } elsif ($line=~/Secret Access Key \[None\]:\s*$/) {
                  for (1..length $line) {
                     $pty->ungetc(ord);
                  }
                  $line='';
                  $pty->print("$main::aws->{secret_key}\n");
               } elsif ($line=~/Default region name \[None\]:\s*$/) {
                  for (1..length $line) {
                     $pty->ungetc(ord);
                  }
                  $line='';
                  $pty->print("$region\n");
               } elsif ($line=~/Default output format \[None\]:\s*$/) {
                  for (1..length $line) {
                     $pty->ungetc(ord);
                  }
                  $pty->print("\n");
               }
            }
         }
         wait();
      }

      #cleanup pty for next run
      $pty->close();
      my $sudo=($^O eq 'cygwin')?'':'sudo ';
      system("${sudo}cp -R $homedir/.aws /home/$username")
         unless $homedir eq "/home/$username";
      my $group=$username;
      $group='Administrators' if $username eq 'Administrator';
      system("${sudo}chown -R $username:$group /home/$username/.aws");
      system("${sudo}chmod 755 /home/$username/.aws");

   };

};

my $configure_aws2=sub {

   package configure_aws2;
   my $banner=<<'END';

     ___              _            _                      _  __
    / __|_ _ ___ __ _| |_ ___     /_\  __ __ ___ ______  | |/ /___ _  _ ___
   | (__| '_/ -_) _` |  _/ -_)   / _ \/ _/ _/ -_|_-<_-<  | ' </ -_) || (_-<
    \___|_| \___\__,_|\__\___|  /_/ \_\__\__\___/__/__/  |_|\_\___|\_, /__/
                                                                   |__/
                   ___________________ 
   When you click | Create access key | and the Access key ID and Secret
                   -------------------
   access key strings will be displayed. You will not have access to the
   secret access key again after the dialog box closes.

   Copy and Paste or type the Access key ID and Secret access key here:


   Access key ID                    Use [TAB] key to switch
                      ]I[{1,'',30}  focus of input boxes

   Secret access key
                      ]I[{2,'',55}

END

   my %configure_aws2=(

      Name => 'configure_aws2',
      Input  => 1,
      Banner => $banner,
      Result => $Net::FullAuto::Cloud::fa_amazon::aws_configure,

   );
   return \%configure_aws2;

};

our $configure_aws1=sub {

   my $banner=<<'END';

     ___           __ _                        ___      _____
    / __|___ _ _  / _(_)__ _ _  _ _ _ ___     /_\ \    / / __|
   | (__/ _ \ ' \|  _| / _` | || | '_/ -_)   / _ \ \/\/ /\__ \
    \___\___/_||_|_| |_\__, |\_,_|_| \___|  /_/ \_\_/\_/ |___/
                        |___/

   1. Sign in to the AWS Management Console and open the IAM console at:

      https://console.aws.amazon.com/iam/home#/users

   2. Click the username next to the gray checkbox of the name of the
         user you want to create an access key for:
       _
      |_| username     (If you are a new AWS user, you can use 'admin')
                    ______________________
   3. Click on the | Security credentials | tab
                    ----------------------
                    ___________________
   4. Click on the | Create access key | button
                    -------------------
         (Delete old key if button grayed out and limit exceeded.)
END

   my %configure_aws1=(

      Name => 'configure_aws1',
      Result => $configure_aws2,
      Banner => $banner,

   );
   Net::FullAuto::FA_Core::Menu(\%configure_aws1);

};

my $select_an_instance_type=sub {

   my $region="]T[{awsregions}";
   $region=~s/^"//;
   $region=~s/"$//;
   my $region_data='';
   $region_data=$main::regions_data->{$region}
      if (defined $main::regions_data &&
      exists $main::regions_data->{$region});
   my @itypes=@{$region_data->{instanceTypes}};
   my @sizes=();my $scrollnum=1;
   foreach my $type (@itypes) {
      foreach my $sizes (@{$type->{sizes}}) {
         my $size=$sizes->{size};
         my $price=$sizes->{valueColumns}->[0]->{prices}->{USD};
         $price=~s/0$/ /;
         my $cents='';
         if ($price=~/^0\./) {
            $cents=$price;
            $cents=~s/^0\.//;
            if (length $cents>2) {
               $cents=~s/^(..)(.*)$/$1.$2/;
               $cents=~s/^0//;
               $cents=' ('.$cents.' cents)';
            } else {
               $cents=' ('.$cents.' cents)';
            }
            $cents=~s/\.\s+/ /;
         }
         my $pr="-> ".pack('A20',"\$$price$cents")."per hour";
         push @sizes, pack('A12',$size).$pr;
      }
   }
#print "DUMP=",Data::Dump::Streamer::Dump(\@sizes)->Out(),"\n";<STDIN>;
   my $instruction_set_choice=']T[{choose_is_setup}';
   $instruction_set_choice=~s/^["]//;
   $instruction_set_choice=~s/["]$//;
   my $ns=$#sizes+1;
   my $stype='t2.small';
   my $iset=$Net::FullAuto::ISets->{$instruction_set_choice};
   my $defaultInstanceType=$Net::FullAuto::ISets->{$instruction_set_choice}->[1].
                           'defaultInstanceType';
   $Net::FullAuto::ISets->{selected_iset}=$instruction_set_choice;
   eval "\$stype=$defaultInstanceType";
   my $result=$Net::FullAuto::ISets->{$instruction_set_choice}->[1]."select_".
              lc($Net::FullAuto::ISets->{$instruction_set_choice}->[2]).
              "_setup";
   eval "\$result=$result";
   my $is_name=$Net::FullAuto::ISets->{$instruction_set_choice}->[2];
   my @sz=grep { !/t2.micro/ } @sizes;
   unshift @sz, grep { /t2.micro/ } @sizes;
   @sizes=@sz;
   foreach my $s (@sizes) {
      last if $s=~/^$stype/;
      $scrollnum++;
   }
   my $select_type_banner=<<'END';

     ___ _                        _____
    / __| |_  ___  ___ ___ ___   |_   _|  _ _ __  ___
   | (__| ' \/ _ \/ _ (_-</ -_)    | || || | '_ \/ -_)
    \___|_||_\___/\___/__/\___|    |_| \_, | .__/\___|
                                       |__/|_|

END
   $select_type_banner.=<<END;
   Choose the type of server instance to use for your
   $instruction_set_choice build. Note that $stype
   has been pre-selected for you. If you wish use this, just press [ENTER],
   otherwise use the [^] and [v] arrow keys to make a different selection.
   Note: There are $ns choices.

END
   my %select_type=(

      Name => 'select_type',
      Item_1 => {

         Text => ']C[',
         Convey => \@sizes,
         Result => $result,

      },
      Scroll => $scrollnum,
      Display => 6,
      Banner => $select_type_banner,

   );
   return \%select_type;

};

my $choose_an_instance_type=sub {

   my $instruction_set_choice=']T[{choose_is_setup}';
   $instruction_set_choice=~s/^["]//;
   $instruction_set_choice=~s/["]$//;
   my $instance_type_banner=<<'END';
    ___         _                      _____
   |_ _|_ _  __| |_ __ _ _ _  __ ___  |_   _|  _ _ __  ___ ___
    | || ' \(_-<  _/ _` | ' \/ _/ -_)   | || || | '_ \/ -_|_-<
   |___|_||_/__/\__\__,_|_||_\__\___|   |_| \_, | .__/\___/__/
                                            |__/|_|

END
   $instance_type_banner.=
      "   You have selected the Instruction Set: $instruction_set_choice\n";
   if (-1<index $instruction_set_choice,'Liferay') {
      $instance_type_banner.=<<END;

   Unfortunately, Free Tier micro servers do not have enough resources to
   successfully run Liferay, even in a minimalist capacity. Therefore, you
   will have to choose a 'small' instance type at the very minimum. Based
   on the choices you make next, a fee summary will be calculated and
   presented to you for approval before any costs are incurred.

END
   } elsif (-1<index $instruction_set_choice,'Chaining') {
      $instance_type_banner.=<<END;

   Unfortunately, Free Tier micro servers do not have enough resources to
   successfully do Chaining, even in a minimalist capacity. Therefore, you
   will have to choose a 'small' instance type at the very minimum. Based
   on the choices you make next, a fee summary will be calculated and
   presented to you for approval before any costs are incurred.

END
   } elsif (-1<index $instruction_set_choice,'Hadoop') {
      $instance_type_banner.=<<END;

   $instruction_set_choice can be run on a Free Tier micro server, but the performance
   will be poor. Therefore it is recommended you choose at least a 'small'
   instance type. However, Free Tier remains the default choice. Based on the
   choices you make next, a fee summary will be calculated and presented to
   you for approval before any costs are incurred.

END
   } else {
      $instance_type_banner.=<<END;

   $instruction_set_choice can be run on a Free Tier micro server, but the
   performance will be poor. Therefore it is recommended you choose at least
   a 'small' instance type. However, Free Tier remains an option. Based on
   the choices you make next, a fee summary will be calculated and presented
   to you for approval before any costs are incurred.

END
   }

   my %describe_costs=(

      Name => 'describe_costs',
      Banner => $instance_type_banner,
      Result => $select_an_instance_type,

   );
   return \%describe_costs;

};

my $choose_aws_instances=sub {

   my $instruction_set_choice=']S[';
   my $fa_tag=0;
   if (-r "/tmp/fa_aws_home.txt") {
      open(RD,"/tmp/fa_aws_home.txt");
      while (my $line=<RD>) {
         $fa_tag=$line if $line=~/TagFA/;
         $fa_tag=~s/^.*=(\d)\s*$/$1/ if $fa_tag;
      }
      close RD;
   }
   unlink "/tmp/fa_aws_home.txt";
   my $fullauto_inst=get_fullauto_instance();
   my ($hash,$output,$error)=('','','');
   if ($fa_tag) {
      my $i=$fullauto_inst->{InstanceId};
      my $t="aws ec2 describe-tags --filters \"Name=resource-id,Values=$i\"";
      ($hash,$output,$error)=run_aws_cmd($t);
      if ($#{$hash->{Tags}}==-1) {
         my $n="aws ec2 create-tags --resources $i --tags Key=Name,".
               "Value=FullAuto-1";
         ($hash,$output,$error)=run_aws_cmd($n);
      }
   }
   my $prc='wget -qO- https://a0.awsstatic.com/pricing/'.
           '1/ec2/linux-od.min.js';
   ($hash,$output,$error)=run_aws_cmd($prc);
   $output=~s/^.*?callback[(](.*)[)];\s*$/$1/s;
   $output=~s/([{,])([A-Za-z]+):/$1"$2":/g;
   $hash=decode_json($output);
   my $r=$fullauto_inst->{Placement}->{AvailabilityZone};
   chop $r;my $cnt=0;my $scrollnum=1;
   $main::regions_data={};my @regions=();
   foreach my $region (@{$hash->{config}->{regions}}) {
      $cnt++;
      $main::regions_data->{$region->{region}}=$region;
      $scrollnum=$cnt if $r eq $region->{region};
      push @regions,$region->{region};
   }
   my $regions_banner=<<'END';

    ___      _        _       _     ___          _
   / __| ___| |___ __| |_    /_\   | _ \___ __ _(_)___ _ _
   \__ \/ -_) / -_) _|  _|  / _ \  |   / -_) _` | / _ \ ' \
   |___/\___|_\___\__|\__| /_/ \_\ |_|_\___\__, |_\___/_||_|
                                           |___/
END
   $regions_banner.=<<END;
   AWS has infrastructure all over the globe. This server you are now on
   is located in region:  $r

   It is already set as the default, and unless you have a reason to use
   another region, just hit the [ENTER] key and stay in region $r.

END
   my %awsregions=(

      Name => 'awsregions',
      Item_1 => {

         Text => ']C[',
         Convey => \@regions,
         Result => $choose_an_instance_type,

      },
      Display => 7,
      Scroll => $scrollnum,
      Banner => $regions_banner,
   );
   return \%awsregions;

};

my $get_ec2_api=sub {

   package get_ec2_api;
   print "\n";
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=Net::FullAuto::Cloud::fa_amazon::run_aws_cmd(
      "aws iam list-access-keys");
   &exit_on_error($error) if $error;
   $Net::FullAuto::Cloud::fa_amazon::configure_aws1->()
      if (-1<index $output,'configure credentials') ||
      (-1<index $output,'Partial credentials found');
   my $choose_is_banner=<<'END';

   Amazon AWS EC2 API is Active!
     ___ _
    / __| |_  ___  ___ ___ ___    __ _ _ _
   | (__| ' \/ _ \/ _ (_-</ -_)  / _` | ' \
    \___|_||_\___/\___/__/\___|  \__,_|_||_|
    ___         _               _   _             ___      _
   |_ _|_ _  __| |_ _ _ _  _ __| |_(_)___ _ _    / __| ___| |_
    | || ' \(_-<  _| '_| || / _|  _| / _ \ ' \   \__ \/ -_)  _|
   |___|_||_/__/\__|_|  \_,_\__|\__|_\___/_||_|  |___/\___|\__|

   Below is a selection of FullAuto Instruction Sets designed
   to demonstrate FullAuto's unique ability to automate *any*
   cloud computing operation. Please choose one:

END
   my $dirtree='';
   if ($_[0]) {
      $dirtree=Net::FullAuto::FA_Core::get_isets($_[0]);
   } else {
      $dirtree=Net::FullAuto::FA_Core::get_isets('Amazon');
   }
   my %choose_is_setup=(

      Name => 'choose_is_setup',
      Item_1 => {

         Text   => ']C[',
         Convey => [keys %{$dirtree}],
         Result => $choose_aws_instances,

      },
      Scroll => 4,
      Banner => $choose_is_banner,

   );
   return \%choose_is_setup;
};

sub assist_user_to_upload_pemfile {

   my $pem_file=$_[0]||'<filename>.pem';
   my $ppk_file=$pem_file;
   $ppk_file=~s/\.pem$//;
   my $user=$Net::FullAuto::FA_Core::username;
   my $homedir=`pwd`;
   if (can_load(modules => { "File::HomeDir" => 0 })) {
      $homedir=File::HomeDir->my_home;
   } elsif (-r "/home/$user") {
      $homedir="/home/$user";
   }
   my $user_path=($user eq 'root')?'/root':$homedir;
   my $publickey_failed=<<'END';
    ___      _    _ _    _  __
   | _ \_  _| |__| (_)__| |/ /___ _  _
   |  _/ || | '_ \ | / _| ' </ -_) || |
   |_|  \_,_|_.__/_|_\__|_|\_\___|\_, |
                                  |__/
      _       _   _            _   _         _   _
     /_\ _  _| |_| |_  ___ _ _| |_(_)__ __ _| |_(_)___ _ _
    / _ \ || |  _| ' \/ -_) ' \  _| / _/ _` |  _| / _ \ ' \
   /_/ \_\_,_|\__|_||_\___|_||_\__|_\__\__,_|\__|_\___/_||_|

    (                              ____
    )\ )           (        (     |   /
   (()/(    )  (   )\   (   )]\ ) |  /
    /(_))( /(  )\ ((_) ))\ (()/(  | /
   (_))_|)(_))((_) _  /((_) ((_)) |/
   | |_ ((_)_  (_)| |(_))   _| | (
   | __|/ _` | | || |/ -_)/ _` | )\
   |_|  \__,_| |_||_|\___|\__,_|((_)


END
   my $wait_banner=<<'END';

    ___  _  _ _                _ _   _
   |_ _|( )| | |  __ __ ____ _(_) |_| |
    | |  V | | |  \ V  V / _` | |  _|_|
   |___|   |_|_|   \_/\_/\__,_|_|\__(_)  (for 5 minutes)
END
   my $i_will_wait_sub=sub {

      my $keyfilename="]I[{'ask_for_keyfile',1}";
      $keyfilename=~s/^.*\/(.*)(?:[.]pem)*$/$1/;
      $keyfilename=~s/[.]pem$/$1/;
      my $pem_file=$keyfilename.'.pem';
      $pem_file||='<filename>.pem';
      $wait_banner.=<<END;

   If you can, go ahead and upload \"$pem_file\" mentioned on the
   previous page right now. (If you need to review the instructions
   again, just use the LEFTARROW [<] to navigate back to the previous
   page.)

   $pem_file should be uploaded to the /home/$user directory.
   When you press [ENTER] on this screen, FullAuto will begin scanning
   for $pem_file in the /home/$user directory. Once
   $pem_file is detected, Fullauto will authenticate and proceed
   to the next page automatically. Otherwise, FullAuto will timeout and
   gracefully exit in 5 minutes.

   If you would like to quit and continue later, just press the ESC key.

END
      my %i_will_wait=(

         Name => 'i_will_wait',
         Banner => $wait_banner,
         Input => 1,
         Result => sub {
            my $key="]I[{'ask_for_keyfile',1}";
            $key.='.pem';
            my $gotkey=0;
            foreach my $sec (1..300) {
               sleep 1;
               unless (-e $key) {
                  opendir(DH,".");
                  my @pems=();
                  while (my $line=readdir(DH)) {
                     next if $line eq '.';
                     next if $line eq '..';
                     chomp($line);
                     if ($line=~/\.pem$/) {
                        push @pems, $line;
                        last;
                     }
                  }
                  close DH;
                  if (-1<$#pems) {
                     if (0==$#pems) {
                        $pem_file=$pems[0];
                        $gotkey=1;
                        last;
                     } else {
                        $pem_file=$pems[0];
                        $gotkey=1;
                        last;
                     }
                  }
               } elsif (-e $key) {
                  $gotkey=1;
                  last;
               }
            }
            if ($gotkey) {
               `sudo chmod 400 $key`;
               return $key;
            } else {
               Net::FullAuto::FA_Core::cleanup();
            }
         },
      );
      return \%i_will_wait;
   };
   my $amazon=&Net::FullAuto::FA_Core::check_for_amazon_localhost;
   print $Net::FullAuto::FA_Core::blanklines;
   print $publickey_failed;
   sleep 3;
   my $line='';
   my $ll=length $pem_file;
   $ll=$ll+5;
   for (0..$ll) { $line.='-' }
   my $ask_for_key_name=<<'END';

    _   _      _              _                         ___ _ _
   | | | |_ __| |___  __ _ __| |     _ __  ___ _ __    | __(_) |___
   | |_| | '_ \ / _ \/ _` / _` |   _| '_ \/ -_) '  \   | _|| | / -_)
    \___/| .__/_\___/\__,_\__,_|  (_) .__/\___|_|_|_|  |_| |_|_\___|
         |_|                        |_|
END
   $ask_for_key_name.=<<END;

   Copy and Paste or type the Amazon Key File (.pem) name here:


   Amazon Key Name 
                      ]I[{1,'fullauto',40}

END
   my $upload_keyfile=sub {

      my $keyfilename="]I[{'ask_for_keyfile',1}";
      $keyfilename=~s/^.*\/(.*)(?:[.]pem)*$/$1/;
      $keyfilename=~s/[.]pem$/$1/;
      my $pem_file=$keyfilename.'.pem';
      my $ppk_file=$keyfilename.'.ppk';
      my $upload_banner=<<'END';
    _   _      _              _                         ___ _ _
   | | | |_ __| |___  __ _ __| |     _ __  ___ _ __    | __(_) |___
   | |_| | '_ \ / _ \/ _` / _` |   _| '_ \/ -_) '  \   | _|| | / -_)
    \___/| .__/_\___/\__,_\__,_|  (_) .__/\___|_|_|_|  |_| |_|_\___|
         |_|                        |_|
END
      $upload_banner.=<<END;

   Upload the AWS key file from your local computer to this host with
   one of the commands below. You can copy the appropriate command and
   paste it to (and run it in) the command window of your local computer:
 ------------------------------------------------------------------------

 scp -i $pem_file $pem_file $user\@$amazon->[1]:$user_path

     
   -OR- with PuTTY scp (but only if you are using PuTTY):


 pscp -i $ppk_file $pem_file $user\@$amazon->[1]:$user_path

END
      my $upload_keyfile={

         Name => 'upload_keyfile',
         Banner => $upload_banner,
         Result => $i_will_wait_sub,

      };
      return $upload_keyfile;

   };
   my $ask_for_keyfile={

      Name => 'ask_for_keyfile',
      Input => 1,
      Banner => $ask_for_key_name,
      Result => $upload_keyfile,

   };
   my $pbf_banner=<<'END';
                                                        ___     _ _        _ _
  _                                                    | __|_ _(_) |___ __| | |
 |_)   |_ |o _  |/ _     /\   _|_|__|_o _ _._|_o _ ._  | _/ _` | | / -_) _` |_|
 |  |_||_)||(_  |\(/_\/ /--\|_||_| ||_|(_(_| |_|(_)| | |_|\__,_|_|_\___\__,_(_)
                     /

   FullAuto works with Amazon EC2 Servers the same way you do. You
   connected to this server with a private key file similar to this:
END
   $pbf_banner.=<<END;

       ssh -i $pem_file $user\@$amazon->[1]

   In order for FullAuto to connect, the same key must be used:

       fa -i $pem_file   <== Always use THIS on Amazon EC2
       $line

END
   my $assist_menu='';
   opendir(UD,$user_path);
   my @keys=();
   while (my $entry=readdir(UD)) {
      next if $entry eq '.';
      next if $entry eq '..';
      if (-f $entry && $entry=~/[.]pem$/) {
         push @keys, $entry;
      }
   }
   close(UD);
   if (-1<$#keys) {
      my @choice=();
      if ($#keys==0) {
         push @choice,$keys[0];
      } else {
         @choice=@keys;
      }
      $assist_menu={

         Name => 'assist_menu',
         Item_1 => {

            Text => "Use ]C[",
            Convey => \@choice,

         },
         Item_2 => {
            Text => "Upload A Private Key File",
            Result => $ask_for_keyfile,
         },
         Item_3 => {
            Text => "Exit FullAuto",
         },
         Scroll => 1,
         Banner => $pbf_banner,

      };
   } else {
      $assist_menu={

         Name => 'assist_menu',
         Item_1 => {
            Text => "Upload A Private Key File",
            Result => $ask_for_keyfile,
         },
         Item_2 => {
            Text => "Exit FullAuto",
         },
         Scroll => 1,
         Banner => $pbf_banner,

      };
   }
   my $choice=Net::FullAuto::FA_Core::Menu($assist_menu);
   Net::FullAuto::FA_Core::cleanup()
      if $choice eq ']quit[' || $choice=~/Exit/;
   $choice=~s/Use //;
   return $choice;

}

sub new_user_amazon {

   my $identity_file=$_[0]||'';
   my $cleanup=$_[3]||'';
   my $iset_amazon=$_[4]||'';
   unless ($cleanup) {
      print $Net::FullAuto::FA_Core::fa_welcome;
      sleep 3;
   }
   my $out=`which aws 2>&1`;
   if (!(-e "/usr/bin/aws") && (-1<index $out,'no aws in')) {
      system("wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip");
      system("sudo unzip awscli-bundle.zip");
      {
         $SIG{CHLD}="DEFAULT";
         my $cmd="sudo ./awscli-bundle/install -i ".
            "/usr/local/aws -b /usr/local/bin/aws";
         system($cmd);
      };
      system("sudo rm -rf ./awscli-bundle");
      system("wget http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip");
      system("sudo mkdir /usr/local/ec2");
      system("sudo unzip ./ec2-api-tools.zip -d /usr/local/ec2");
      system("sudo rm -rf ./ec2-api-tools.zip");
   }
   my $need_to_configure_aws=0;
   my $cwd=Cwd::cwd();
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=Net::FullAuto::Cloud::fa_amazon::run_aws_cmd(
      "aws iam list-access-keys");
   &exit_on_error($error) if $error;
   $need_to_configure_aws=1 if (-1<index $output,'configure credentials') ||
      (-1<index $output,'Partial credentials found');
   my $credentials_csv_path='.';
   if (-r "/tmp/fa_aws_home.txt") {
      open(RD,"/tmp/fa_aws_home.txt");
      while (my $line=<RD>) {
         $credentials_csv_path=$line if $line=~/home/;
         $pem_file=$line if $line=~/\.pem\s*$/;
         chomp($pem_file);
      }
      close RD;
      $credentials_csv_path=~s/\s*$//;
      $credpath=$credentials_csv_path;
      unless (-r "$credpath/$pem_file") {
         assist_user_to_upload_pemfile($pem_file);
      }
   } elsif ($identity_file && -r "./$identity_file") {
      $pem_file=$identity_file;
      $credpath='.';
   } elsif (-r $identity_file) {
      my $if=$identity_file;
      $if=~/^(.*)\/(.*)/;
      $identity_file=$2;
      $credpath=$1;
      $pem_file=$identity_file;
   } else {
      $identity_file=$pem_file=assist_user_to_upload_pemfile();
   }
   my $homedir='.';
   my $username=&Net::FullAuto::FA_Core::username();
   if (can_load(modules => { "File::HomeDir" => 0 })) {
      $homedir=File::HomeDir->my_home;
   } elsif (-r "/home/$username") {
      $homedir="/home/$username";
   }
   if (exists $ENV{SUDO_USER} &&
         (-e "/home/$ENV{SUDO_USER}/credentials.csv")) {
      $credentials_csv_path="/home/$ENV{SUDO_USER}";
   #} elsif (-e "$homedir/.aws/credentials") {
   } elsif (-e "$homedir/.aws/credentials") {
      open(RD,"$homedir/.aws/credentials");
      while (my $line=<RD>) {
         if ($line=~/^\s*aws_access_key_id\s*=\s*(\S+)/) {
            $main::aws->{access_id}=$1;
         } elsif ($line=~/^\s*aws_secret_access_key\s*=\s*(\S+)/) {
            $main::aws->{secret_key}=$1;
         }
      }
      close RD;
   }
   if ($need_to_configure_aws &&
         (-e "$credentials_csv_path/credentials.csv")) {
      open(FH,"<$credentials_csv_path/credentials.csv");
      my @creds=<FH>;
      close FH;
      my $id='';my $aki='';my $sak='';
      chomp $creds[1];
      ($id,$aki,$sak)=split ',',$creds[1];
      $aws_configure->($aki,$sak);
      unlink "$credentials_csv_path/credentials.csv";
   }
   if ($cleanup) {
      my $fullauto_inst=get_fullauto_instance();
      my $i=$fullauto_inst->{InstanceId};
      my $t="aws ec2 terminate-instances --instance-id $i";
      ($hash,$output,$error)=run_aws_cmd($t);
      Net::FullAuto::FA_Core::cleanup();
   }
   my $banner=<<'END';

    ___     _ _   _       _
   | __|  _| | | /_\ _  _| |_  |      ___ _ _             __|  __|_  )
   | _| || | | |/ _ \ || |  _/ | \   / _ \ ' \            _|  (     /
   |_| \_,_|_|_/_/ \_\_,_|\__\___/©  \___/_||_|  Amazon  ___|\___|___|

   (Amazon is **NOT** a sponsor of the FullAuto© Project.)

   You are fully authenticated with FullAuto on Amazon AWS EC2:
   "Amazon Web Services  -  Elastic Compute Cloud".

   The objective is to demonstrate how FullAuto can fully automate the
   setup, processing and maintenance of cloud computing in AWS EC2.

   FullAuto will now check the current system to determine if the ec2 API
   is installed and available for use.
END
   if ($iset_amazon && $iset_amazon!~/^\d*$/ &&
         $iset_amazon!~/iset_local/) {
      open(FH,"<$iset_amazon") || do {
         print "   FATAL ERROR!: Cannot open Amazon Instruction Set ".
               "\"$iset_amazon\"\n                 $!\n";
         Net::FullAuto::FA_Core::cleanup(); 
      };
      close FH;
      Net::FullAuto::FA_Core::Menu($get_ec2_api->($iset_amazon));
   } elsif ($iset_amazon && $iset_amazon=~/iset_local/) {
   } else {
      my %welcome_fa_amazon=(

         Name   => 'welcome_fa_amazon',
         Banner => $banner,
         Result => $get_ec2_api,

      );
      Net::FullAuto::FA_Core::Menu(\%welcome_fa_amazon);
      Net::FullAuto::FA_Core::cleanup();
   }

}

sub exit_on_error {

   eval {
      local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
      alarm 3600;
      print "\n\n   FATAL ERROR!:\n   ";
      print $_[0];
      print "   \n   Press Any Key to EXIT ... ";
      <STDIN>;
   };alarm(0);
   print "\n";
   &Net::FullAuto::FA_Core::cleanup;

}

1
