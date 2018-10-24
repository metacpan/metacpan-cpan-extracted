package Net::FullAuto::Cloud::fa_local;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2018  Brian M. Kelly
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
use Net::FullAuto::Cloud::fa_amazon;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(iset);

my $result=sub {

   my $iset_choice=']P[{choose_iset_setup}';
   $iset_choice=~s/^["]//;
   $iset_choice=~s/["]$//;
   my $iset=$Net::FullAuto::ISets->{$iset_choice};
   $Net::FullAuto::ISets->{selected_iset}=$iset_choice;
   my $result=$Net::FullAuto::ISets->{$iset_choice}->[1]."select_".
              lc($Net::FullAuto::ISets->{$iset_choice}->[2]).
              "_setup";
   eval "\$result=$result";
   return $result->();

};

my $get_isets=sub {

   my $test_aws=
         `wget -qO- http://169.254.169.254/latest/dynamic/instance-identity/`;
   if (-1<index $test_aws,'signature') {
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
      if ($need_to_configure_aws) {
         Net::FullAuto::Cloud::fa_amazon::new_user_amazon(
            '','','','','iset_local');
         $Net::FullAuto::Cloud::fa_amazon::configure_aws1->();
      }
   }

   print "\n";
   my ($output,$error)=('','');
   my $choose_iset_banner=<<'END';
     ___ _
    / __| |_  ___  ___ ___ ___    __ _ _ _
   | (__| ' \/ _ \/ _ (_-</ -_)  / _` | ' \
    \___|_||_\___/\___/__/\___|  \__,_|_||_|

    ___         _               _   _             ___      _
   |_ _|_ _  __| |_ _ _ _  _ __| |_(_)___ _ _    / __| ___| |_
    | || ' \(_-<  _| '_| || / _|  _| / _ \ ' \   \__ \/ -_)  _|
   |___|_||_/__/\__|_|  \_,_\__|\__|_\___/_||_|  |___/\___|\__|


   Below is a selection of FullAuto Instruction Sets that
   engage FullAuto's unique ability to automate *any* cloud
   computing operation. Please choose one:

END
   my $dirtree=Net::FullAuto::FA_Core::get_isets('Local');
   my %choose_iset_setup=(

      Name => 'choose_iset_setup',
      Item_1 => {

         Text   => ']C[',
         Convey => [keys %{$dirtree}],
         Result => $result,

      },
      Scroll => 1,
      Banner => $choose_iset_banner,

   );
   return \%choose_iset_setup;
};

sub iset {

   my $iset=$_[0]||'';
   my $cwd=Cwd::cwd();
   my $banner=<<'END';
    ___     _ _   _       _              _                 _ _  _        _
   | __|  _| | | /_\ _  _| |_  |        | |   ___  __ __ _| | || |___ __| |_
   | _| || | | |/ _ \ || |  _/ | \      | |__/ _ \/ _/ _` | | __ / _ (_-<  _| 
   |_| \_,_|_|_/_/ \_\_,_|\__\___/c  ON |____\___/\__\__,_|_|_||_\___/__/\__|

   You are fully authenticated with FullAuto on LocalHost.

   The goal now is to use FullAuto to fully automate the
   setup, processing and maintenance of cloud computing.

END

   my %welcome_fa_amazon=(

      Name   => 'welcome_fa_amazon',
      Banner => $banner,
      Result => $get_isets,

   );
   Net::FullAuto::FA_Core::Menu(\%welcome_fa_amazon);
   Net::FullAuto::FA_Core::cleanup();

}

1
