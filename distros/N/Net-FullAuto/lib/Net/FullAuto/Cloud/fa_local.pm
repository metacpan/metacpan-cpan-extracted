package Net::FullAuto::Cloud::fa_local;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2016  Brian M. Kelly
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
our @EXPORT = qw(iset);

sub cmd_raw {

   return Net::FullAuto::FA_Core::cmd_raw(@_);

}

my $configure_aws2=sub {

   my $banner=<<'END';

     ___              _            _                      _  __
    / __|_ _ ___ __ _| |_ ___     /_\  __ __ ___ ______  | |/ /___ _  _ ___
   | (__| '_/ -_) _` |  _/ -_)   / _ \/ _/ _/ -_|_-<_-<  | ' </ -_) || (_-<
    \___|_| \___\__,_|\__\___|  /_/ \_\__\__\___/__/__/  |_|\_\___|\_, /__/
                                                                   |__/

   Click 'Create Access Key' button in the lower part of the popup page.

   Click 'Show User Security Credentials' and the Access key ID and Secret
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
      Result => sub {},

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

      https://console.aws.amazon.com/iam/#users

   2. Click the blue checkbox of the name of the user you want to create
      an access key for:
       _
      |_| username     (If you are a new AWS user, use 'admin')

   3. Look for the big gray box just above the section you clicked that
      is labeled 'User Actions':
       ________________
      | User Actions v |  Click on it and select 'Manage Access Keys'
       ----------------
END

   my %configure_aws1=(

      Name => 'configure_aws1',
      Result => $configure_aws2,
      Banner => $banner,

   );
   Net::FullAuto::FA_Core::Menu(\%configure_aws1);

};

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
