package Net::FullAuto::ISets::Local::Chaining_is;

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
our $DISPLAY='FullAuto Proxy Chaining & RESTful Access';
our $CONNECT='secure';
our $defaultInstanceType='t2.small';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_chaining_setup);

use Net::FullAuto::Cloud::fa_amazon;
use Net::FullAuto::FA_Core qw[cmd_raw $localhost];
use File::HomeDir;
my $home_dir=File::HomeDir->my_home.'/';
my $username=getlogin || getpwuid($<);
my $do;my $ad;my $prompt;

my $configure_chaining=sub {

   my $selection=$_[0]||'';
   my ($stdout,$stderr)=('','');
   my $handle=$localhost;my $connect_error='';
   $localhost->cwd('~');
   my $sudo=($^O eq 'cygwin')?'':'sudo ';
$do=1;
if ($do==1) {
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd("sudo yum clean all");
      ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden");
      ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert");
      ($stdout,$stderr)=$handle->cmd(
         "sudo yum -y groupinstall 'Development tools'",'__display__');
      ($stdout,$stderr)=$handle->cmd(
         'sudo yum -y install openssl-devel icu cyrus-sasl'.
         ' libicu cyrus-sasl-devel libtool-ltdl-devel libxml2-devel'.
         ' freetype-devel libpng-devel java-1.7.0-openjdk-devel'.
         ' unixODBC unixODBC-devel libtool-ltdl libtool-ltdl-devel'.
         ' ncurses-devel xmlto git-all','__display__');
   } else {
      my $cygcheck=`/bin/cygcheck -c` || die $!;
      my $uname=`/bin/uname` || die $!;
      my $uname_all=`/bin/uname -a` || die $!;
      $uname_all.=$uname;
      my %need_packages=();
      if ($uname_all=~/x86_64/) {
         foreach my $package ('libxml2','libxml2-devel','libtool',
               'autoconf','autobuild','automake','pkg-config',
               'libuuid-devel','wget','git') {
            unless (-1<index $cygcheck, "$package ") {
               $need_packages{$package}='';
            }
         }
      } else {
         foreach my $package ('libxml2','libxml2-devel','libtool',
               'autoconf','autobuild','automake','pkg-config',
               'libuuid-devel','wget','git') {
            unless (-1<index $cygcheck, "$package ") {
               $need_packages{$package}='';
            }
         }
      }
      my $packs='';
      foreach my $pack (sort keys %need_packages) {
         $packs.="$pack ";
      }
      if ($packs) {
         print "\n\n   Fatal Error!: The following Cygwin",
               "\n                 packages are missing from",
               "\n                 your installation:",
               "\n\n   $packs",
               "\n\n   Please report any bugs and send any",
               "\n   questions, thoughts or feedback to:",
               "\n\n      Brian.Kelly\@FullAuto.com.",
               "\n\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
   }
   ###############
   ## RABBITMQ
   ###############
   #($stdout,$stderr)=$handle->cmd(
   #   "wget --random-wait --progress=dot ".
   #   "https://github.com/erlang/otp/archive/maint.zip",
   #   '__display__');
   #($stdout,$stderr)=$handle->cmd("unzip maint.zip",'__display__');
   #($stdout,$stderr)=$handle->cmd("rm -rvf maint.zip",'__display__');
   #($stdout,$stderr)=$handle->cwd("otp-maint");
   #($stdout,$stderr)=$handle->cmd("export ERL_TOP=`pwd`",'__display__');
   #($stdout,$stderr)=$handle->cmd("./otp_build autoconf");
   #($stdout,$stderr)=$handle->cmd("./configure",'__display__');
   #($stdout,$stderr)=$handle->cmd("sudo make install",'__display__');
   #($stdout,$stderr)=$handle->cwd("..");
   #($stdout,$stderr)=$handle->cmd("sudo sed -i ".
   #   "'s#secure_path = #secure_path = /usr/local/bin:/usr/local/sbin:#'".
   #   " /etc/sudoers");
   #($stdout,$stderr)=$handle->cmd("wget -qO- ".
   #   "https://www.rabbitmq.com/download.html");
   #my $source_flag=0;
   #my $rmq='';my $rmqtar='';my $rmqdir='';
   #foreach my $line (split "\n", $stdout) {
   #   if ($line=~/Source/) {
   #      $source_flag=1;
   #   } elsif ($source_flag) {
   #      $rmq=$line;
   #      $rmq=~s/^.*href=["](.*?)["].*$/$1/;
   #      $rmq='https://www.rabbitmq.com'.$rmq;
   #      ($rmqtar=$rmq)=~s/^.*\/(.*)$/$1/;
   #      ($rmqdir=$rmqtar)=~s/^(.*).tar.gz/$1/;
   #      last;
   #   }
   #}
   #($stdout,$stderr)=$handle->cmd(
   #   "wget --random-wait --progress=dot ".$rmq,'__display__');
   #($stdout,$stderr)=$handle->cmd("tar zxvf $rmqtar",'__display__');
   #($stdout,$stderr)=$handle->cmd("rm -rvf $rmqtar",'__display__');
   #($stdout,$stderr)=$handle->cwd($rmqdir);
   #$handle->{_cmd_handle}->print('sudo su');
   #$prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->{_cmd_handle}->print('export TARGET_DIR=/usr/local');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->{_cmd_handle}->print('export SBIN_DIR=/usr/local');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->{_cmd_handle}->print('export MAN_DIR=/usr/local');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->{_cmd_handle}->print('make install');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #$handle->{_cmd_handle}->print('exit');
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #}
   #($stdout,$stderr)=$handle->cwd("..");
   #($stdout,$stderr)=$handle->cmd(
   #   "wget --random-wait --progress=dot ".
   #   "https://github.com/rabbitmq/rabbitmq-tutorials/archive/master.zip",
   #   '__display__');
   #($stdout,$stderr)=$handle->cmd("unzip master.zip",'__display__');
   #($stdout,$stderr)=$handle->cmd("rm -rvf master.zip",'__display__');
   #($stdout,$stderr)=$handle->cmd("sudo rabbitmq-server -detached",
   #   '__display__');
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd(
         "wget --random-wait --progress=dot ".
         "http://download.fedoraproject.org".
         "/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm",
         '__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo rpm -ivh epel-release-6-8.noarch.rpm",
         '__display__');
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf epel-release-6-8.noarch.rpm",
         '__display__');
      ($stdout,$stderr)=$handle->cmd('sudo yum -y install uuid-devel '.
         'pkgconfig libtool gcc-c++','__display__');
   }
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "https://github.com/jedisct1/libsodium/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("unzip master.zip",'__display__');
   ($stdout,$stderr)=$handle->cmd("${sudo}rm -rvf master.zip",'__display__');
   ($stdout,$stderr)=$handle->cwd("libsodium-master");
   ($stdout,$stderr)=$handle->cmd("./autogen.sh",'__display__');
   ($stdout,$stderr)=$handle->cmd("./configure",'__display__');
   ($stdout,$stderr)=$handle->cmd("make",'__display__');
   ($stdout,$stderr)=$handle->cmd("${sudo}make install",'__display__');
   ($stdout,$stderr)=$handle->cwd("..");
   unless ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd('echo /usr/local/lib > '.
         'local.conf','__display__');
      ($stdout,$stderr)=$handle->cmd("${sudo}chmod -v 644 local.conf",
         '__display__');
      ($stdout,$stderr)=$handle->cmd(
         "${sudo}mv -v local.conf /etc/ld.so.conf.d",'__display__');
      ($stdout,$stderr)=$handle->cmd("${sudo}ldconfig");
   }
}
$do=1;
if ($do==1) {
   my $zmq='zeromq-4.1.4.tar.gz';
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "http://download.zeromq.org/$zmq",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("wget -qO- ".
      "http://download.zeromq.org/SHA1SUMS");
   my $zmqsha1=$stdout;
   $zmqsha1=~s/^.*gz\s+(.*?)\s+$zmq.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd("sha1sum -c - <<<\"$zmqsha1 $zmq\"",
      '__display__');
   unless ($stderr) {
      print(qq{ + CHECKSUM Test for $zmq *PASSED* \n});
   } else {
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $zmq",'__display__');
      print "FATAL ERROR! : CHECKSUM Test for $zmq *FAILED* ";
      &Net::FullAuto::FA_Core::cleanup;
   }
   ($stdout,$stderr)=$handle->cmd("tar zxvf $zmq",'__display__');
   ($stdout,$stderr)=$handle->cmd("rm -rvf $zmq",'__display__');
   $zmq=~s/\.tar\.gz$//;
   ($stdout,$stderr)=$handle->cwd($zmq);
   cmd_raw($handle,'export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig');
   ($stdout,$stderr)=$handle->cmd('./configure','__display__');
   if ($^O eq 'cygwin') {
      my $ad="        -no-undefined \\%NL%".
             "        -avoid-version \\";
      ($stdout,$stderr)=$handle->cmd(
         "sed -i \'/^libzmq_la_LDFLAGS = \\/a$ad\' ./Makefile");
      ($stdout,$stderr)=$handle->cmd( # bash shell specific
         "sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
         "./Makefile");
   } else {
      my $ad="Defaults    env_keep += \"PKG_CONFIG_PATH\"";
      ($stdout,$stderr)=$handle->cmd(
         "sudo sed -i \'/_XKB_CHARSET/a$ad\' /etc/sudoers")
   }
   ($stdout,$stderr)=$handle->cmd('make','__display__');
   ($stdout,$stderr)=$handle->cmd("${sudo}make install",'__display__');
   ($stdout,$stderr)=$handle->cwd("..");
}
$do=0;
if ($do==1) {
   my $go=$1;my $gosha1=$2;
   ($stdout,$stderr)=$handle->cmd("wget -qO- https://golang.org/dl");
   if ($^O eq 'cygwin') {
      $stdout=~
         /^.*?href=["]([^"]+windows-amd64.zip)["].*?[<]tt[>](.*?)[<].*$/s;
      $go=$1;$gosha1=$2;
   } else {
      $stdout=~
         /^.*?href=["]([^"]+linux-amd64.tar.gz)["].*?[<]tt[>](.*?)[<].*$/s;
      $go=$1;$gosha1=$2;
   }
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".$go,
      '__display__');
   $go=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd("sha1sum -c - <<<\"$gosha1 $go\"",
      '__display__');
   unless ($stderr) {
      print(qq{ + CHECKSUM Test for $go *PASSED* \n});
   } else {
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $go",'__display__');
      print "FATAL ERROR! : CHECKSUM Test for $go *FAILED* ";
      &Net::FullAuto::FA_Core::cleanup;
   }
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cmd("unzip $go",'__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd("tar zxvf $go",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("rm -rvf $go",'__display__');
}
$do=0;
if ($do==1) {
   ($stdout,$stderr)=$handle->cmd('wget -qO- '.
      'https://github.com/membrane/service-proxy/releases/latest');
   $stdout=~s/^.*?href=["]([^"]+zip)["].*$/$1/s;
   my $membrane_zip=$stdout;
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot https://github.com".$membrane_zip,
      '__display__');
   $membrane_zip=~s/^.*\/(.*)$/$1/;
   ($stdout,$stderr)=$handle->cmd("unzip $membrane_zip",'__display__');
   ($stdout,$stderr)=$handle->cmd("rm -rvf $membrane_zip",'__display__');
   #($stdout,$stderr)=$handle->cmd('git clone --depth=1 '.
   #   'https://github.com/membrane/service-proxy.git','__display__');
exit;
}
   if ($^O eq 'cygwin') {
      ($stdout,$stderr)=$handle->cwd("~");
      $handle->{_cmd_handle}->print('cpan');
   } else {
      ($stdout,$stderr)=$handle->cmd('sudo yum -y install cpan',
         '__display__');
      $handle->{_cmd_handle}->print('sudo cpan');
   } 
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'possible automatically') {
         $handle->{_cmd_handle}->print('yes');
         $output='';
         next;
      } elsif (-1<index $output,'by bootstrapping') {
         $handle->{_cmd_handle}->print('sudo');
         $output='';
         next;
      } elsif (-1<index $output,'some CPAN') {
         $handle->{_cmd_handle}->print('no');
         $output='';
         next;
      } elsif (-1<index $output,'pick from') {
         $handle->{_cmd_handle}->print('no');
         $output='';
         next;
      } elsif (-1<index $output,'CPAN site') {
         $handle->{_cmd_handle}->print('http://www.cpan.org');
         $output='';
         next;
      } elsif (-1<index $output,'ENTER to quit') {
         $handle->{_cmd_handle}->print();
         $output='';
         next;
      } elsif ($output=~/cpan[[]\d+[]][>]/) {
         $handle->{_cmd_handle}->print('bye');
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd("export PERL_MM_USE_DEFAULT=1");
   if ($^O eq 'cygwin') {
      my $show=<<END;
########################################

   INSTALLING Starman

########################################
END
      print $show;
      cmd_raw($handle,
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","Starman")\'',
         '__display__');
      $show=<<END;
########################################

   INSTALLING HTTP::Server::Simple

########################################
END
      print $show;
      cmd_raw($handle,
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","HTTP::Server::Simple")\'',
         '__display__');
   }
   my $show=<<END;
########################################

   INSTALLING Perl::Critic

########################################
END
   print $show;
   cmd_raw($handle,
      'perl -MCPAN -e \'CPAN::Shell->notest('.
      '"install","Perl::Critic")\'',
      '__display__');
   $show=<<END;
########################################

   INSTALLING ExtUtils::Embed

########################################
END
   #print $show;
   #cmd_raw($handle,
   #   'sudo perl -MCPAN -e \'CPAN::Shell->force('.
   #   '"install","ExtUtils::Embed")\'',
   #   '__display__');
   my @cpan_modules = qw(

      Test::More
      Module::Build
      AnyEvent
      Proc::Guard
      ZMQ::LibZMQ4
      CPAN::Meta
      ExtUtils::ParseXS
      Package::Generator
      Test::Output
      Compress::Raw::Bzip2
      IO::Compress::Bzip2
      Package::Anon
      Text::Diff
      Archive::Tar
      Archive::Zip
      inc::latest
      PAR::Dist
      Regexp::Common
      Pod::Checker
      Pod::Parser
      Pod::Man
      File::Slurp
      Test::Taint
      Test::Warnings
      Test::Without::Module
      Devel::LexAlias
      BSD::Resource
      IPC::System::Simple
      Sub::Identify
      Fatal
      Sub::Name
      Role::Tiny
      Test::LeakTrace
      Test::CleanNamespaces
      Test::Pod
      Test::Pod::Coverage
      Class::Load
      Class::Load::XS
      Algorithm::C3
      SUPER
      Module::Refresh
      Declare::Constraints::Simple
      Devel::Cycle
      CGI
      Test::Memory::Cycle
      IO::String
      Mouse::Tiny
      DateTime::Format::MySQL
      Moose
      Moo
      MooseX::Role::WithOverloading
      Pod::Coverage::Moose
      MooseX::AttributeHelpers
      MooseX::ConfigFromFile
      MooseX::MarkAsMethods
      MooseX::SimpleConfig
      MooseX::StrictConstructor 
      MooseX::NonMoose
      Net::FullAuto
      Time::HiRes
      Business::ISBN
      App::FatPacker
      JSON
      JSON::XS
      Test::DistManifest
      Term::Size::Any
      Type::Tiny
      File::ReadBackwards
      Imager
      IO::CaptureOutput
      Astro::MoonPhase
      Date::Manip
      XML::LibXML
      SQL::Translator
      Template::Alloy
      URI::Amazon::APA 
      TheSchwartz
      Devel::CheckLib
      Catalyst::Runtime
      Proc::ProcessTable
      Parallel::Forker
      UUID::Tiny
      Regexp::Assemble

   );
   my $install_chaining=<<'END';

          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::
                     _
                   ((_)
                    /
                   /              _        _           _
               \__/_     ___ __ _| |_ __ _| |_   _ ___| |_
               /    \   / __/ _` | __/ _` | | | | / __| __|  Perl MVC
            _- |    |  | (_| (_| | || (_| | | |_| \__ \ |    framework
       _ _-'   \____/   \___\__,_|\__\__,_|_|\__, |___/\__|c
     ((_)       ---\                         |___/
                    \
                     \\_          Web Framework
                      (_)

     (Catalyst Foundation is **NOT** a sponsor of the FullAuto© Project.)
END
   foreach my $module (@cpan_modules) {
      next if $module=~/^\s*#/;
      my $show=<<END;
########################################

   INSTALLING $module

########################################
END
      sleep 1;
      print $show;
      if ($module eq 'Catalyst::Runtime') {
         print $install_chaining;
         sleep 10;
      }
      unless ($^O eq 'cygwin') {
         cmd_raw($handle,
            "${sudo}LD_LIBRARY_PATH=/usr/local/lib ".
            "PKG_CONFIG_PATH=/usr/local/lib/pkgconfig ".
            "LD_PRELOAD=/usr/local/lib/libzmq.so.5 cpan -f -i $module",
            '__display__');
      } else {
         cmd_raw($handle,"cpan -i $module",
            '__display__');
      }
   }
   $show=<<END;
########################################

   INSTALLING Regexp::Assemble

########################################
END
#   print $show;
#   cmd_raw($handle,
#      'sudo perl -MCPAN -e \'CPAN::Shell->force('.
#      '"install","Regexp::Assemble")\'',
#      '__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Devel

########################################
END
   print $show;
   $handle->{_cmd_handle}->print("${sudo}cpan Catalyst::Devel");
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'XS Stash module?') {
         $handle->{_cmd_handle}->print('Y');
         $output='';
         next;
      }
      if (-1<index $output,'XS Stash by default?') {
         $handle->{_cmd_handle}->print('Y');
         $output='';
         next;
      }
   }
   $show=<<END;

########################################

   INSTALLING Catalyst::Controller::HTML::FormFu

########################################
END
   cmd_raw($handle,"${sudo}cpan Catalyst::Controller::HTML::FormFu",
      '__display__');
   print "\n";
   $show=<<END;

########################################

   INSTALLING CatalystX::OAuth2

########################################
END
   cmd_raw($handle,"${sudo}cpan CatalystX::OAuth2",
      '__display__');
   print "\n";
   $show=<<END;

########################################

   INSTALLING Task::Catalyst::Tutorial

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan Task::Catalyst::Tutorial",'__display__');
   $show=<<END;

########################################

   INSTALLING DBIx::Class::Schema::Loader

########################################
END
   cmd_raw($handle,"${sudo}cpan DBIx::Class::Schema::Loader",
      '__display__');
#   $show=<<END;
#
########################################
#
#   INSTALLING Net::RabbitFoot
#
########################################
#END
#   print $show;
#   $handle->{_cmd_handle}->print("${sudo}cpan Net::RabbitFoot");
#   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
#   while (1) {
#      my $output.=Net::FullAuto::FA_Core::fetch($handle);
#      last if $output=~/$prompt/;
#      print $output;
#      if (-1<index $output,'Skip further questions and use') {
#         $handle->{_cmd_handle}->print('y');
#         $output='';
#         next;
#      }
#   }
   $show=<<END;

########################################

   INSTALLING YAML::Syck

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan YAML::Syck",'__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Controller::REST

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan Catalyst::Controller::REST",'__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Model::Adaptor

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan Catalyst::Model::Adaptor",'__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::View::JSON

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan Catalyst::View::JSON",'__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::View::TT::Alloy

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan Catalyst::View::TT::Alloy",'__display__');
   $show=<<END;

########################################

   INSTALLING Catalyst::Plugin::Unicode

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,"${sudo}cpan Catalyst::Plugin::Unicode",'__display__');
   $show=<<END;

########################################

   INSTALLING Finance::Quote

########################################
END
   print $show;
   $handle->{_cmd_handle}->print("${sudo}cpan Finance::Quote");
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'traffic to external sites') {
         $handle->{_cmd_handle}->print('Y');
         $output='';
         next;
      }
      if (-1<index $output,'have network connectivity. [n]') {
         $handle->{_cmd_handle}->print('y');
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd("catalyst.pl Hello",'__display__');
   ($stdout,$stderr)=$handle->cwd("Hello");
   ($stdout,$stderr)=$handle->cmd("perl Makefile.PL",'__display__');
   #$handle->{_cmd_handle}->print(
   #   'script/hello_server.pl --background');
   #$prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   #while (1) {
   #   my $output.=Net::FullAuto::FA_Core::fetch($handle);
   #   last if $output=~/$prompt/;
   #   print $output;
   #   if (-1<index $output,'| /end') {
   #      $output=Net::FullAuto::FA_Core::fetch($handle);
   #      print $output;
   #      last;
   #   }
   #}
   ($stdout,$stderr)=$handle->cwd("..");
   ($stdout,$stderr)=$handle->cmd("catalyst.pl AdventREST",'__display__');
   ($stdout,$stderr)=$handle->cwd("AdventREST");
   ($stdout,$stderr)=$handle->cmd("perl Makefile.PL",'__display__');
   ($stdout,$stderr)=$handle->cmd("mkdir -v db lib/AdventREST/Schema",
      '__display__');
   my $db_sql="db.sql";
   my $content=<<'END';
CREATE TABLE user (
 user_id TYPE text NOT NULL PRIMARY KEY,
 fullname TYPE text NOT NULL,
 description TYPE text NOT NULL
); 
END
   ($stdout,$stderr)=$handle->cmd("touch $db_sql");
   ($stdout,$stderr)=$handle->cmd("chmod -v 777 $db_sql",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo \"$content\" > $db_sql");
   ($stdout,$stderr)=$handle->cmd("chmod -v 644 $db_sql",'__display__');
   #($stdout,$stderr)=$handle->cmd('sqlite3 db/adventrest.db < db.sql');
   ($stdout,$stderr)=$handle->cwd('db');
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
      "examples/RestYUI/db/adventrest.db",
      '__display__');
   ($stdout,$stderr)=$handle->cwd("../lib/AdventREST");
   $content=<<'END';
#
# AdventREST::Schema.pm
#
 
package AdventREST::Schema;
use base qw/DBIx::Class::Schema/;
 
__PACKAGE__->load_classes(qw/User/);
 
1;
END
   ($stdout,$stderr)=$handle->cmd("touch Schema.pm");
   ($stdout,$stderr)=$handle->cmd("chmod -v 777 Schema.pm",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo \"$content\" > Schema.pm");
   ($stdout,$stderr)=$handle->cmd("chmod -v 644 Schema.pm",'__display__');
   $content=<<'END';
package AdventREST::Schema::User;
 
use base qw/DBIx::Class/;
__PACKAGE__->load_components(qw/Core/);
__PACKAGE__->table('user');
__PACKAGE__->add_columns(qw/user_id fullname description/);
__PACKAGE__->set_primary_key('user_id');
 
1;
END
   ($stdout,$stderr)=$handle->cwd("Schema");
   ($stdout,$stderr)=$handle->cmd("touch User.pm");
   ($stdout,$stderr)=$handle->cmd("chmod -v 777 User.pm",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > User.pm");
   ($stdout,$stderr)=$handle->cmd("chmod -v 644 User.pm",'__display__');
   ($stdout,$stderr)=$handle->cwd("../../..");
   ($stdout,$stderr)=$handle->cmd("./script/adventrest_create.pl ".
      "model DB DBIC::Schema AdventREST::Schema",'__display__');
   ($stdout,$stderr)=$handle->cmd("./script/adventrest_create.pl ".
      "controller OAuth2::Provider",'__display__');
   my $pro_path="./lib/AdventREST/Controller/OAuth2/Provider.pm";
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\"s/Catalyst::Controller/Catalyst::Controller::ActionRole/\" ".
      $pro_path);
   $ad="%NL%".
       "with %SQ%CatalystX::OAuth2::Controller::Role::Provider%SQ%;%NL%".
       "%NL%".
       "__PACKAGE__->config(%NL%".
       "  store => {%NL%".
       "    class => %SQ%DBIC%SQ%,%NL%".
       "    client_model => %SQ%DB::Client%SQ%%NL%".
       "  }%NL%".
       ");%NL%".
       "%NL%".
       "sub request : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::RequestAuth%SQ%) {}%NL%".
       "%NL%".
       "sub grant : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::GrantAuth%SQ%) {%NL%".
       "  my ( \$self, \$c ) = \@_;%NL%".
       "%NL%".
       "  my \$oauth2 = \$c->req->oauth2;%NL%".
       "%NL%".
       "  \$c->user_exists and \$oauth2->user_is_valid(1)%NL%".
       "    or \$c->detach(%SQ%/passthrulogin%SQ%);%NL%".
       "}%NL%".
       "%NL%".
       "sub token : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::AuthToken::ViaAuthGrant%SQ%) {}%NL%".
       "%NL%".
       "sub refresh : Chained(%SQ%/%SQ%) Args(0) ".
       "Does(%SQ%OAuth2::AuthToken::ViaRefreshToken%SQ%) {}%NL%";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/ActionRole/a$ad' $pro_path");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" $pro_path");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" $pro_path");
   $content=<<'END';
name: AdventREST
Model::DB:
    schema_class: AdventREST::Schema
    connect_info:
        - DBI:SQLite:dbname=__path_to(db/adventrest.db)__
        - \\x22\\x22
        - \\x22\\x22
END
   ($stdout,$stderr)=$handle->cmd("touch adventrest.yml");
   ($stdout,$stderr)=$handle->cmd("chmod -v 777 adventrest.yml",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > adventrest.yml");
   ($stdout,$stderr)=$handle->cmd("chmod -v 644 adventrest.yml",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "./script/adventrest_create.pl controller User",'__display__');
   ($stdout,$stderr)=$handle->cmd("mv lib/AdventREST/Controller/User.pm ".
      "lib/AdventREST/Controller/User.bak");
   ($stdout,$stderr)=$handle->cmd(
      "./script/adventrest_create.pl view TT TT",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "mkdir -vp root/static/jquery",'__display__');
   ($stdout,$stderr)=$handle->cwd('root/static/jquery');
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "https://code.jquery.com/ui/1.11.3/jquery-ui.js",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "https://code.jquery.com/jquery-1.11.3.js",
      '__display__');
   ($stdout,$stderr)=$handle->cwd('../..');
   # http://www.sitepoint.com/working-jquery-datatables/
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "https://github.com/DataTables/DataTables/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd('unzip master.zip','__display__');
   ($stdout,$stderr)=$handle->cmd("${sudo}rm -rvf master.zip",'__display__');
   ($stdout,$stderr)=$handle->cwd('DataTables-master');
   ($stdout,$stderr)=$handle->cmd('cp -Rv media ..','__display__');
   ($stdout,$stderr)=$handle->cwd('examples');
   ($stdout,$stderr)=$handle->cmd('cp -Rv resources ../..','__display__');
   ($stdout,$stderr)=$handle->cwd('../../..');
   $content=<<END;
package AdventREST::Controller::User;
 
use strict;
use warnings;
use Moose;
use TheSchwartz::Job;
use DBI;
use namespace::autoclean;
use ZMQ::LibZMQ4;
use ZMQ::Constants qw(:all);
use YAML;
use Carp::Assert;

use constant NBR_WORKERS    => 2;
use constant READY          => \\x22\\\\\\\\001\\x22;

use constant FRONTEND_URL   =>
       \\x22ipc://${home_dir}AdventREST/frontend.ipc\\x22;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    'default' => 'application/json',
    'map'       => {
       'text/html'          => [ 'View', 'TT' ],
       'text/xml'           => [ 'View', 'TT' ],
       'text/x-yaml'        => 'YAML',
       'application/json'   => 'JSON',
       'text/x-json'        => 'JSON',
       'text/x-data-dumper' => [ 'Data::Serializer', 'Data::Dumper' ],
       'text/x-data-denter' => [ 'Data::Serializer', 'Data::Denter' ],
       'text/x-data-taxi'   => [ 'Data::Serializer', 'Data::Taxi'   ],
       'application/x-storable'   => [ 'Data::Serializer', 'Storable' ],
       'application/x-freezethaw' => [ 'Data::Serializer', 'FreezeThaw' ],
       'text/x-config-general'    => [ 'Data::Serializer', 'Config::General' ],
       'application/x-www-form-urlencoded' => 'JSON',
    },
);

sub user_list : Path('/user') :Args(0) : ActionClass('REST') { }

sub user_list_GET {
    my ( \\x24self, \\x24c ) = \@_;
    my \\x24draw     = \\x24c->req->params->{draw} || 0;
    my \\x24start    = \\x24c->req->params->{start} || 0;
    my \\x24per_page = \\x24c->req->params->{length} || 10;
    my \\x24page     = 1;
    if (\\x24start<\\x24per_page) {
       \\x24page=1;
    } else {
       \\x24page=int(\\x24start/\\x24per_page)+1;
    }

    my \\x24id = 'Client-'.\\x24\\x24;

    my \\x24ctx     = zmq_init();
    my \\x24socket  = zmq_socket(\\x24ctx,ZMQ_REQ);

    my \\x24rv      = zmq_setsockopt(\\x24socket,ZMQ_IDENTITY,\\x24id);
    assert(\\x24rv == 0, 'setting socket options');

    \\x24rv         = zmq_connect(\\x24socket,FRONTEND_URL());

    assert(\\x24rv == 0,'connecting client ...');

    print \\x22\\x24id sending Hello\\\\\\\\n\\x22;
    \\x24rv         = zmq_msg_send('Hello',\\x24socket);

    my \\x24reply = zmq_recvmsg(\\x24socket);

    assert(\\x24reply);

    print \\x22\\x24id got a reply -> \\x22,zmq_msg_data(\\x24reply),\\x22\\\\\\\\n\\x22;

    # We'll use an array now:
    my \@user_list;
    my \\x24rs = \\x24c->model('DB::User')
        ->search(undef, { rows => \\x24per_page })->page( \\x24page );
    while ( my \\x24user_row = \\x24rs->next ) {
        push \@user_list, {
            \\x24user_row->get_columns,
            uri => \\x24c->uri_for( '/user/' . \\x24user_row->user_id )->as_string
        };
    }

    \\x24self->status_ok( \\x24c, entity => {
        draw => \\x24draw,
        recordsTotal => \\x24rs->pager->total_entries,
        recordsFiltered => \\x24rs->pager->total_entries,
        data => [ \@user_list ]
    });
};

sub single_user : Path('/user') : Args(1) : ActionClass('REST') {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    \\x24c->stash->{'user'} = \\x24c->model('DB::User')->find(\\x24user_id);
}

sub single_user_POST {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    my \\x24new_user_data = \\x24c->req->data;
    if ( \\x21defined(\\x24new_user_data) ) {
       return \\x24self->status_bad_request(\\x24c,
           message => 'You must provide a user to create or modify\\x21' );
    }

    if ( \\x24new_user_data->{'user_id'} ne \\x24user_id ) {
       return \\x24self->status_bad_request( 
              \\x24c,
              message => 
                 'Cannot create or modify user '
                 . \\x24new_user_data->{'user_id'} . ' at '
                 . \\x24c->req->uri->as_string
                 . '; the user_id does not match\\x21' );
    }

    foreach my \\x24required (qw(user_id fullname description)) {
       return \\x24self->status_bad_request( \\x24c,
          message => 'Missing required field: ' . \\x24required )
       if \\x21exists( \\x24new_user_data->{\\x24required} );
    }

    my \\x24user = \\x24c->model('DB::User')->update_or_create(
       user_id     => \\x24new_user_data->{'user_id'},
       fullname    => \\x24new_user_data->{'fullname'},
       description => \\x24new_user_data->{'description'},
    );
    my \\x24return_entity = {
       user_id     => \\x24user->user_id,
       fullname    => \\x24user->fullname,
       description => \\x24user->description,
    };

    if ( \\x24c->stash->{'user'} ) {
        \\x24self->status_ok( \\x24c, entity => \\x24return_entity, );
    } else {
        \\x24self->status_created(
            \\x24c,
            location => \\x24c->req->uri->as_string,
            entity   => \\x24return_entity,
        );
    }
}

*single_user_PUT = *single_user_POST;

sub single_user_GET {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    my \\x24user = \\x24c->stash->{'user'};
    if ( defined(\\x24user) ) {
        \\x24self->status_ok(
            \\x24c,
            entity => {
                user_id     => \\x24user->user_id,
                fullname    => \\x24user->fullname,
                description => \\x24user->description,
            }
        );
    }
    else {
        \\x24self->status_not_found( \\x24c,
            message => 'Could not find User '.\\x24user_id.'\\x21' );
    }
}

sub single_user_DELETE {
    my ( \\x24self, \\x24c, \\x24user_id ) = \@_;
 
    my \\x24user = \\x24c->stash->{'user'};
    if ( defined(\\x24user) ) {
        \\x24user->delete;
        \\x24self->status_ok(
            \\x24c,
            entity => {
                user_id     => \\x24user->user_id,
                fullname    => \\x24user->fullname,
                description => \\x24user->description,
            }
        );
    } else {
        \\x24self->status_not_found( \\x24c,
        message => 'Cannot delete non-existent user '.\\x24user_id.'\\x21' );
    }
}

1;
END
   ($stdout,$stderr)=$handle->cwd('lib/AdventREST/Controller');
   ($stdout,$stderr)=$handle->cmd("touch User.pm");
   ($stdout,$stderr)=$handle->cmd("chmod -v 777 User.pm",'__display__');
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > User.pm");
   $ad='sub index : Private {%NL%   my ( $self, $c ) = @_;%NL%'.
          '   $c->forward( $c->view(%SQ%TT%SQ%) );%NL%}%NL%%NL%';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/sub index :Path/i$ad' ./Root.pm");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ./Root.pm");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ./Root.pm");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i '/index :Path :/,+6d' ./Root.pm");
   ($stdout,$stderr)=$handle->cmd("chmod -v 644 User.pm",'__display__');
   ($stdout,$stderr)=$handle->cwd('../../../root/static');
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
      "examples/RestYUI/root/static/json2.js",
      '__display__');
   ($stdout,$stderr)=$handle->cmd('mkdir -vp yui','__display__');
   ($stdout,$stderr)=$handle->cwd('yui');
   my @yuifiles=('utilities.js','dom.js','connection.js','event.js',
                 'yahoo.js');
   foreach my $file (@yuifiles) {
      ($stdout,$stderr)=$handle->cmd(
         "wget --random-wait --progress=dot ".
         "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
         "examples/RestYUI/root/static/yui/$file",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cwd('../..');
   ($stdout,$stderr)=$handle->cmd('mkdir -vp user','__display__');
   ($stdout,$stderr)=$handle->cwd('user');
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "http://dev.catalyst.perl.org/repos/Catalyst/trunk/".
      "examples/RestYUI/root/user/single_user.tt",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sed -i 's/POSTT/POST/' single_user.tt");
   ($stdout,$stderr)=$handle->cwd('..');
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paster results.):
   #
   #          !  -   \\x21
   #          "  -   \\x22
   #          $  -   \\x24
   #
   $content=<<END;
<\\x21DOCTYPE html>
<html>
<head>
   <meta charset=\\x22utf-8\\x22>
   <meta name=\\x22viewport\\x22 content=\\x22initial-scale=1.0, maximum-scale=2.0\\x22>

   <title>Catalyst REST Example</title>

   <link rel=\\x22stylesheet\\x22 type=\\x22text/css\\x22 href=\\x22https://cdn.datatables.net/1.10.8/css/jquery.dataTables.min.css\\x22>
   <link rel=\\x22stylesheet\\x22 type=\\x22text/css\\x22 href=\\x22resources/demo.css\\x22></script>
   <script type=\\x22text/javascript\\x22 language=\\x22javascript\\x22 src=\\x22//code.jquery.com/jquery-1.11.3.min.js\\x22></script>
   <script type=\\x22text/javascript\\x22 language=\\x22javascript\\x22 src=\\x22https://cdn.datatables.net/1.10.8/js/jquery.dataTables.min.js\\x22></script>
   <script type=\\x22text/javascript\\x22 language=\\x22javascript\\x22 class=\\x22init\\x22>

   \\x24(document).ready(function() {
      \\x24(\\x22#example\\x22).dataTable({
         \\x22processing\\x22: true,
         \\x22serverSide\\x22: true,
         \\x22ajax\\x22: \\x22[%c.uri_for( c.controller('User').action_for('user_list') ) %]?page=1&content-type=application/json\\x22,
         \\x22aoColumns\\x22: [{
            \\x22mData\\x22:\\x22user_id\\x22,
         },{
            \\x22mData\\x22: \\x22fullname\\x22,
         },{
            \\x22mData\\x22: \\x22description\\x22,
         }]
     });
   } );

  </script>
</head>

<body class=\\x22dt-example\\x22>
   <div class=\\x22container\\x22>
      <section>
         <h1>Catalyst REST Example <span>Using JQuery DataTable</span></h1>

         <div class=\\x22info\\x22>
            <p>FullAuto was used to stand up this fully functional Catalyst REST installation.
               The following table is full of demo user data. To add or update a user, manually
               modify the browser URL like so:

            <br><br><code>[%c.uri_for( c.controller('User').action_for('user_list') ) %]/user_id</code>.</p>

            <p>Data can be accessed on the command line:
                <br><br><code>curl -X GET -H 'Content-Type: application/json'
                [%c.uri_for( c.controller('User').action_for('user_list') ) %]</code></p>
         </div>
            <table id=\\x22example\\x22 class=\\x22display\\x22 cellspacing=\\x220\\x22 width=\\x22100%\\x22>
               <thead>
                  <tr>
                     <th>ID</th>
                     <th>Full Name</th>
                     <th>Description</tn>
                  </tr>
               </thead>

               <tfoot>
                  <tr>
                     <th>ID</th>
                     <th>Full Name</th>
                     <th>Description</th>
                  </tr>
               </tfoot>
            </table>
         </div>
      </section>
   </div>
</body>
</html>
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > index.tt");
   my $theswartz_schema=<<END;
CREATE TABLE funcmap (
        funcid INTEGER PRIMARY KEY AUTOINCREMENT,
        funcname VARCHAR(255) NOT NULL,
        UNIQUE(funcname)
);

CREATE TABLE job (
        jobid INTEGER PRIMARY KEY AUTOINCREMENT,
        funcid INTEGER UNSIGNED NOT NULL,
        arg MEDIUMBLOB,
        uniqkey VARCHAR(255) NULL,
        insert_time INTEGER UNSIGNED,
        run_after INTEGER UNSIGNED NOT NULL,
        grabbed_until INTEGER UNSIGNED NOT NULL,
        priority SMALLINT UNSIGNED,
        coalesce VARCHAR(255),
        UNIQUE(funcid,uniqkey)
);

CREATE TABLE error (
        error_time INTEGER UNSIGNED NOT NULL,
        jobid INTEGER NOT NULL,
        message VARCHAR(255) NOT NULL,
        funcid INT UNSIGNED NOT NULL DEFAULT 0
);

CREATE TABLE exitstatus (
        jobid INTEGER PRIMARY KEY NOT NULL,
        funcid INT UNSIGNED NOT NULL DEFAULT 0,
        status SMALLINT UNSIGNED,
        completion_time INTEGER UNSIGNED,
        delete_after INTEGER UNSIGNED
);
END
   ($stdout,$stderr)=$handle->cwd('../db');
   ($stdout,$stderr)=$handle->cmd(
      "echo \"$theswartz_schema\" | sqlite3 theschwartz.sqlt");
   ($stdout,$stderr)=$handle->cwd('..');
   ($stdout,$stderr)=$handle->cmd(
      "./script/adventrest_create.pl model TheSchwartz",'__display__');
   $ad='__PACKAGE__->config( class => "TheSchwartz" );%NL%%NL%'. # %NL% is newline
      'sub mangle_arguments { %{ $_[1]->{args} } }%NL%';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/Catalyst::Model/a$ad\' ".
      "./lib/AdventREST/Model/TheSchwartz.pm");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      "./lib/AdventREST/Model/TheSchwartz.pm");
   $content=<<END;
Model::TheSchwartz:
  args:
    verbose: 1
    databases:
      - dsn: dbi:SQLite:__path_to(db/theschwartz.sqlt)__
END
   ($stdout,$stderr)=$handle->cmd("echo \"$content\" >> adventrest.yml");
   $ad="use Net::FullAuto;%NL%".
       "use ZMQ::LibZMQ4;%NL%".
       "use ZMQ::Constants qw(:all);%NL%".
       "use YAML;%NL%".
       "use Carp::Assert;%NL%%NL%".
       "use constant NBR_WORKERS    => 2;%NL%".
       "use constant READY          => \"\\\\001\";%NL%".
       "%NL%".
       "use constant BACKEND_URL    =>%NL%".
       "       %SQ%ipc://${home_dir}AdventREST/backend.ipc%SQ%;%NL%".
       "use constant FRONTEND_URL    =>%NL%".
       "       %SQ%ipc://${home_dir}AdventREST/frontend.ipc%SQ%;%NL%".
       "%NL%".
       "use Parallel::Forker;%NL%".
       "%NL%".
       "my \$fa_sub=sub {%NL%".
       "%NL%".
       "   my \$server={%NL%".
       "%NL%".
       "      Label => %SQ%server%SQ%,%NL%".
       "      LoginID => %SQ%${username}%SQ%,%NL%".
       "      IdentityFile => %SQ%${home_dir}fullauto.pem%SQ%,%NL%".
       "      HostName => %SQ%localhost%SQ%,%NL%".
       "%NL%".
       "   };%NL%".
       "   # A bit of custom config riding/hacking to use the application".
       "%SQ%s%NL%".
       "   # config for the DB.%NL%".
       "   my \$config_file = %SQ%${home_dir}AdventREST/adventrest.yml".
       "%SQ%;%NL%".
       "   my \$config_data = YAML::LoadFile( \$config_file );%NL%".
       "   #my \$args = \$config_data->{\"Model::ZeroMQ\"}->{args};%NL%".
       "%NL%".
       "   my \$id = %SQ%Worker-%SQ%.\$\$;%NL%%NL%".
       "   my \$ctx     = zmq_init();%NL%".
       "   my \$socket  = zmq_socket(\$ctx,ZMQ_REQ);%NL%%NL%".
       "   my \$rv      = zmq_setsockopt(\$socket,ZMQ_IDENTITY,\$id);%NL%".
       "   assert(\$rv == 0);%NL%%NL%".
       "   \$rv         = zmq_connect(\$socket,BACKEND_URL());%NL%".
       "   assert(\$rv == 0,%SQ%connecting to backend%SQ%);%NL%%NL%".
       "   print \"\$id sending READY\\n\";%NL%".
       "%NL%".
       "   \$rv = zmq_msg_send(READY(),\$socket);%NL%".
       "   assert(\$rv);%NL%".
       "%NL%".
       "   my \$buf = zmq_msg_init();%NL%".
       "%NL%".
       "   my (\$fullauto,\$stdout,\$stderr,\$exitcode,".
       "\$connect_error)=(%SQ%%SQ%,%SQ%%SQ%,%SQ%%SQ%,%SQ%%SQ%,%SQ%%SQ%);%NL%".
       "   (\$fullauto,\$connect_error)=connect_shell(\$server);%NL%".
       "%NL%".
       "   use Time::HiRes;%NL%".
       "   # http://www.unitconversion.org/unit_converter/time-ex.html%NL%".
       "   my \$msg = zmq_msg_init();%NL%".
       "   while (1) {%NL%".
       "%NL%".
       "      my \@msg=();%NL%".
       "      if (zmq_msg_recv(\$buf,\$socket,ZMQ_DONTWAIT)) {%NL%".
       "         push \@msg, zmq_msg_data(\$buf);%NL%".
       "         while (zmq_getsockopt(\$socket,ZMQ_RCVMORE)) {%NL%".
       "            zmq_msg_recv(\$buf,\$socket);%NL%".
       "            push \@msg, zmq_msg_data(\$buf);%NL%".
       "         }%NL%".
       "      }%NL%".
       "      (\$stdout,\$stderr)=\$fullauto->cmd(%SQ%hostname%SQ%);%NL%".
       "      #print \"LOOPING in process \$\$ and ".
       "and HOSTNAME=\$stdout\\n\";%NL%".
       "      if (getppid==1) {%NL%".
       "         `pgrep -P \$\$ | xargs kill -TERM`;%NL%".
       "         exit;%NL%".
       "      }%NL%".
       "      if (\$#msg) {%NL%".
       "         print \"\$id got: \$msg[2] from \$msg[0]\\n\";%NL%".
       "         print \"\$id sending OK to \$msg[0]\\n\";%NL%".
       "         zmq_msg_send(\$msg[0],\$socket,ZMQ_SNDMORE);%NL%".
       "         zmq_msg_send(%SQ%%SQ%,\$socket,ZMQ_SNDMORE);%NL%".
       "         zmq_msg_send(%SQ%OK%SQ%,\$socket);%NL%".
       "      }%NL%".
       "      Time::HiRes::sleep (.000001);%NL%".
       "%NL%".
       "   }%NL%".
       "};%NL%".
       "%NL%".
       "my \$zeromq_broker=sub {%NL%".
       "%NL%".
       "   print \"LOADING BROKER\\n\";%NL%".
       "%NL%".
       "   my \$ctx = zmq_init();%NL%".
       "   my \$frontend = zmq_socket(\$ctx, ZMQ_ROUTER);%NL%".
       "   my \$backend  = zmq_socket(\$ctx, ZMQ_ROUTER);%NL%".
       "%NL%".
       "   my \$rv  = zmq_bind(\$frontend,FRONTEND_URL());%NL%".
       "   assert(\$rv == 0);%NL%".
       "%NL%".
       "   \$rv     = zmq_bind(\$backend,BACKEND_URL());%NL%".
       "   assert(\$rv == 0);%NL%".
       "%NL%".
       "   my \@workers;%NL%".
       "%NL%".
       "   my (\$w_addr,\$delim,\$c_addr,\$data);%NL%".
       "   my \$items = [%NL%".
       "%NL%".
       "         {%NL%".
       "            events      => ZMQ_POLLIN,%NL%".
       "            socket      => \$frontend,%NL%".
       "            callback    => sub {%NL%".
       "%NL%".
       "                if (-1<\$#workers) {%NL%".
       "%NL%".
       "                    print \"frontend…\\n\";%NL%".
       "%NL%".
       "                    my \$buf = zmq_msg_init();%NL%".
       "                    my \@msg=();%NL%".
       "                    if (zmq_msg_recv(\$buf,\$frontend)) {%NL%".
       "                       push \@msg, zmq_msg_data(\$buf);%NL%".
       "                       while (zmq_getsockopt(\$frontend,ZMQ_RCVMORE)) {%NL%".
       "                          zmq_msg_recv(\$buf,\$frontend);%NL%".
       "                          push \@msg, zmq_msg_data(\$buf);%NL%".
       "                       }%NL%".
       "                    }%NL%".
       "%NL%".
       "                    assert(\$#msg);%NL%".
       "%NL%".
       "                    assert(\$#workers < NBR_WORKERS());%NL%".
       "%NL%".
       "                    zmq_msg_send(pop(\@workers),\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(%SQ%%SQ%,\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(\$msg[0],\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(%SQ%%SQ%,\$backend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(\$msg[2],\$backend,);%NL%".
       "%NL%".
       "                }%NL%".
       "            },%NL%".
       "         },%NL%".
       "         {%NL%".
       "            events      => ZMQ_POLLIN,%NL%".
       "            socket      => \$backend,%NL%".
       "            callback    => sub {%NL%".
       "%NL%".
       "                print \"backend…\\n\";%NL%".
       "%NL%".
       "                my \$buf = zmq_msg_init();%NL%".
       "                my \@msg=();%NL%".
       "                if (zmq_msg_recv(\$buf,\$backend)) {%NL%".
       "                   push \@msg, zmq_msg_data(\$buf);%NL%".
       "                   while (zmq_getsockopt(\$backend,ZMQ_RCVMORE)) {%NL%".
       "                      zmq_msg_recv(\$buf,\$backend);%NL%".
       "                      push \@msg, zmq_msg_data(\$buf);%NL%".
       "                   }%NL%".
       "                }%NL%".
       "%NL%".
       "                assert(\$#msg);%NL%".
       "%NL%".
       "                \$w_addr = \$msg[0];%NL%".
       "                push(\@workers,\$w_addr);%NL%".
       "%NL%".
       "                \$delim = \$msg[1];%NL%".
       "                assert(\$delim eq %SQ%%SQ%);%NL%".
       "%NL%".
       "                \$c_addr = \$msg[2];%NL%".
       "%NL%".
       "                if(\$c_addr ne READY()){%NL%".
       "                    \$delim = \$msg[3];%NL%".
       "                    assert (\$delim eq %SQ%%SQ%);%NL%".
       "%NL%".
       "                    \$data = \$msg[4];%NL%".
       "%NL%".
       "                    print %SQ%sending %SQ%.\$data.%SQ% to %SQ%.\$c_addr.\"\\n\";%NL%".
       "%NL%".
       "                    zmq_msg_send(\$c_addr,\$frontend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(%SQ%%SQ%,\$frontend,ZMQ_SNDMORE);%NL%".
       "                    zmq_msg_send(\$data,\$frontend);%NL%".
       "%NL%".
       "                } else {%NL%".
       "                    print %SQ%worker checking in: %SQ%.\$w_addr.\"\\n\";%NL%".
       "                }%NL%".
       "            },%NL%".
       "         },%NL%".
       "   ];%NL%".
       "   while(1){%NL%".
       "      zmq_poll(\$items);%NL%".
       "      select undef,undef,undef,0.025;%NL%".
       "      if (getppid==1) {%NL%".
       "         `pgrep -P \$\$ | xargs kill -TERM`;%NL%".
       "          exit;%NL%".
       "      }%NL%".
       "   }%NL%".
       "%NL%".
       "};%NL%".
       "%NL%".
       "my \$Fork = new Parallel::Forker();%NL%".
       "\$Fork->schedule(run_on_start => \$zeromq_broker)->run()%NL%".
       "   if \$Fork->in_parent;%NL%".
       "setpgrp(0,0) unless \$Fork->in_parent;%NL%".
       "%NL%".
       "for (1..NBR_WORKERS()) {%NL%".
       "%NL%".
       "   my \$Fork = new Parallel::Forker();%NL%".
       "   #\$SIG{TERM} = sub { \$Fork->kill_tree_all(%SQ%TERM%SQ%) ".
       "if \$Fork && \$Fork->in_parent; die \"Quitting...\\n\"; };%NL%".
       "   \$Fork->schedule(run_on_start => \$fa_sub)->run()%NL%".
       "      if \$Fork->in_parent;%NL%".
       "   setpgrp(0,0) unless \$Fork->in_parent;%NL%".
       "%NL%".
       "}%NL%";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/use Catalyst::ScriptRunner/i$ad\' ".
      "./script/adventrest_server.pl");
   ($stdout,$stderr)=$handle->cmd( # bash shell specific
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      "./script/adventrest_server.pl");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      "./script/adventrest_server.pl");
   ($stdout,$stderr)=$handle->cwd("..");
   ($stdout,$stderr)=$handle->put("fullauto.pem");
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "https://github.com/pangyre/p5-myapp-10in10/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("unzip master.zip",'__display__');
   ($stdout,$stderr)=$handle->cmd("rm -rvf master.zip",'__display__');
   ($stdout,$stderr)=$handle->cwd("p5-myapp-10in10-master");
   print "\n\n   p5-myapp-10in10-master CWD ERROR => $stderr\n\n"
      if $stderr;
   ($stdout,$stderr)=$handle->cmd("mkdir -vp root/static/img/title",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("perl Makefile.PL",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sed -i 's/static.*=/Plugin::Static::Simple =/' lib/MyApp.pm");
   ($stdout,$stderr)=$handle->cmd(
      "sed -i \"s/Plugin::Static::Simple/'&'/\" lib/MyApp.pm");
   ($stdout,$stderr)=$handle->cmd(
      "sed -i '/Unicode::Encoding/d' lib/MyApp.pm");
   $ad='encoding: utf8';
   ($stdout,$stderr)=$handle->cmd(
      "sed -i \'/default_view/a $ad\' myapp.yml");
print "GOING TO START MYAPP SERVER\n";
   $handle->{_cmd_handle}->print(
      'script/myapp_server.pl --background');
   ($stdout,$stderr)=$handle->cwd("../AdventREST");
   ($stdout,$stderr)=$handle->cmd("${sudo}ldconfig");
print "GOING TO START WEB SERVER\n";
   $handle->{_cmd_handle}->print(
      "${sudo}script/adventrest_server.pl -p 3001 &");
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      if ($output=~/^(.*?)$prompt.*$/s) {
         print $1 if defined $1;
         last;
      }
      print $output;
      if (-1<index $output,'| /end') {
         $output=Net::FullAuto::FA_Core::fetch($handle);
         print $output;
         last;
      }
   }
   sleep 15;
   print "\n   ACCESS CATALYST REST EXAMPLE AT:\n\n",
         " http://localhost:3001\n";
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


   Copyright © 2000-2024  Brian M. Kelly  Brian.Kelly@FullAuto.com

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
            "   to start with your new Catalyst© installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_chaining=sub {

   my $catalyst="]T[{select_chaining_setup}";
   my $cnt=0;
   $configure_chaining->($catalyst);
   return '{choose_demo_setup}<';

};

my $chaining_setup_summary=sub {

   package chaining_setup_summary;
   use JSON::XS;
   my $region="]T[{awsregions}";
   $region=~s/^"//;
   $region=~s/"$//;
   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   my $money=$type;
   $money=~s/^.*-> \$(.*?) +(?:[(].+[)] )*\s*per hour$/$1/;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $catalyst="]T[{select_chaining_setup}";
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
         Result => $standup_chaining,

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

our $select_chaining_setup=sub {

   my @options=('FullAuto© Proxy Chaining & RESTful Access on 1 Server');
   my $chaining_setup_banner=<<'END';

                     _    ___     _ _   _       _                     
                   ((_)  | __|  _| | | /_\ _  _| |_  |                   
                    /    | _| || | | |/ _ \ || |  _/ | \   Automates     _
                   /     |_| \_,_|_|_/_/ \_\_,_|\__\___/c  Everything  _| |_ 
               \__/_     ___ __ _| |_ __ _| |_   _ ___| |_            |_   _|
               /    \   / __/ _` | __/ _` | | | | / __| __|  Perl MVC   |_|
            _- |    |  | (_| (_| | || (_| | | |_| \__ \ |    framework
       _ _-'   \____/   \___\__,_|\__\__,_|_|\__, |___/\__|c
     ((_)       ---\                         |___/
                    \
                     \\_   Web Framework & SSH Proxy Chaining via RESTful
                      (_)

   Choose the Chaining setup you wish to demo. Note that more servers
   means more expense, and more instances means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 instance on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_chaining_setup=(

      Name => 'select_chaining_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $standup_chaining,

      },
      Scroll => 1,
      Banner => $chaining_setup_banner,
   );
   return \%select_chaining_setup

};

1
