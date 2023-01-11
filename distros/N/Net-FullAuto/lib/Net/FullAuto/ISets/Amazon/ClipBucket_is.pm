package Net::FullAuto::ISets::Amazon::ClipBucket_is;

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
our $DISPLAY='CLIPBUCKET';
our $CONNECT='secure';
our $defaultInstanceType='t2.micro';

my $service_and_cert_password='Full@ut0O1';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_clipbucket_setup);

use File::HomeDir;
use JSON::XS;
use POSIX qw(strftime);
my $home_dir=File::HomeDir->my_home.'/';

use Net::FullAuto::Cloud::fa_amazon;

# https://thechamberlands.net/video-streaming/
# https://github.com/jwplayer/jwplayer

my $configure_clipbucket=sub {

   my $server_type=$_[0];
   my $cnt=$_[1];
   my $selection=$_[2]||'';
   my $region=$_[4]||'';
   my $verified_email=$_[5]||'';
   my $permanent_ip=$_[6]||'';
   my $site_name=$_[7]||'';
   my $site_profile=$_[8]||'';
   my $site_build=$_[9]||'';
   $service_and_cert_password=$_[10]||'';
   my $twitter_api_key=$_[11]||'';
   my $twitter_api_sec=$_[12]||'';
   my $sudo='sudo ';
   if ($site_profile=~/Commmunity/) {
      $site_profile='community';
   } elsif ($site_profile=~/Public/) {
      $site_profile='public';
   } elsif ($site_profile=~/Single/) {
      $site_profile='singleuser';
   } elsif ($site_profile=~/Private/) {
      $site_profile='private';
   }
   $permanent_ip='' if $permanent_ip=~/Stay|Reason/;
   if (exists $main::aws->{permanent_ip}) {
      $permanent_ip=$main::aws->{permanent_ip}; 
   }
   my $handle=$main::aws->{$server_type}->[$cnt]->[1];
   my $local=connect_shell();
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y update",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo yum clean all",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo yum grouplist hidden",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo yum groups mark convert",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      'sudo yum -y install cyrus-sasl-plain sendmail-cf m4 java java-devel',
      '__display__');
   # https://www.unixmen.com/setup-your-own-youtube-clone-website-using-clipbucket/
   # http://opensourceeducation.net/clip-bucket-2-8-on-ubuntu-14-04-with-nginx-php5-fpm-on-digitalocean-vps/
   my $install_clipbucket=<<'END';

           o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
           8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
           8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
           8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
           8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
           8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
           ........................................................
           ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                           http://clipbucket.com


        _____ _      _______  ____  _    _  _____ _   __ ______ _______
       / ____| |    | |  __ \|  _ \| |  | |/ ____| | / /|  ____|__   __|
      / /    | |    | | |__) | |_) | |  | | |    | |/ / | |__     | |
      | |    | |    | |  ___/|  _ <| |  | | |    |    \ |  __|    | |
      | \____| |____| | |    | |_) | |__| | |____| |\  \| |____   | |
       \_____|______|_|_|    |____/ \____/ \_____|_| \__|______|  |_|


         (CLIPBUCKET is **NOT** a sponsor of the FullAuto© Project.)

END
   print $install_clipbucket;sleep 10;
   ($stdout,$stderr)=$handle->cmd(
      'sudo yum -y install php55 php55-curl php55-gd php55-gmp '.
      'php55-intl php55-json php55-opcache php55-mysqlnd '.
      'php55-mbstring php55-devel php55-fpm php55-cli openssl-devel '.
      'ImageMagick ImageMagick-devel ImageMagick-perl',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y groupinstall 'Development tools'",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo pecl install mailparse-2.1.6",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo yum -y install epel-release',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/etc/yum.repos.d');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "wget --random-wait --progress=dot ".
      "http://www.nasm.us/nasm.repo",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'yum -y --disablerepo=amzn-main '.
      'install nasm','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'yum -y install autoconf automake gcc gcc-c++ '.
      'git libtool make pkgconfig wget opencv zlib-devel dbus-devel '.
      'lua-devel zvbi libdvdread-devel libdc1394-devel libxcb-devel '.
      'xcb-util-devel libxml2-devel mesa-libGLU-devel pulseaudio-libs-devel '.
      'alsa-lib-devel libgcrypt-devel qt-devel re2c lshw','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo yum -y --skip-broken --enablerepo=epel '.
      'install yasm libva-devel libass-devel libkate-devel libbluray-devel '.
      'libdvdnav-devel libcddb-devel libmodplug-devel','__display__');
   ($stdout,$stderr)=$handle->cmd('yum install '.
      'a52dec-devel libmpeg2-devel','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'mkdir -pv /opt/source/ffmpeg','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'git clone git://git.videolan.org/x264','__display__');
   ($stdout,$stderr)=$handle->cwd('x264');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo cp -v x264.pc /usr/lib64/pkgconfig',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'git clone --depth 1 git://github.com/mstorsjo/fdk-aac.git',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('fdk-aac');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'autoreconf -fiv','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'cp -v fdk-aac.pc /usr/lib64/pkgconfig','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   my $lame_tar='lame-3.99.5.tar.gz';
   my $lame_md5='84835b313d4a8b68f5349816d33e07ce';
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "http://downloads.sourceforge.net/project/lame/lame/3.99/".
         $lame_tar,'__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo md5sum -c - <<<\"$lame_md5 $lame_tar\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $lame_tar *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $lame_tar *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $lame_tar",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "tar xzvf $lame_tar",'__display__');
   $lame_tar=~s/\.tar\.gz$//;
   ($stdout,$stderr)=$handle->cwd($lame_tar);
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared --enable-nasm');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   my $libogg_tar='libogg-1.3.0.tar.gz';
   my $libogg_md5='0a7eb40b86ac050db3a789ab65fe21c2';
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "http://downloads.xiph.org/releases/ogg/".
         $libogg_tar,'__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo md5sum -c - <<<\"$libogg_md5 $libogg_tar\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $libogg_tar *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $libogg_tar *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $libogg_tar",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "tar xzvf $libogg_tar",'__display__');
   $libogg_tar=~s/\.tar\.gz$//;
   ($stdout,$stderr)=$handle->cwd($libogg_tar);
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo cp -v ogg.pc /usr/lib64/pkgconfig',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   my $libtheora_tar='libtheora-1.1.1.tar.gz';
   my $libtheora_md5='bb4dc37f0dc97db98333e7160bfbb52b';
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "http://downloads.xiph.org/releases/theora/".
         $libtheora_tar,'__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo md5sum -c - <<<\"$libtheora_md5 $libtheora_tar\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $libtheora_tar *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $libtheora_tar *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $libtheora_tar",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "tar xzvf $libtheora_tar",'__display__');
   $libtheora_tar=~s/\.tar\.gz$//;
   ($stdout,$stderr)=$handle->cwd($libtheora_tar);
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   #my $ffmpeg_tar='ffmpeg.static.64bit.2014-07-16.tar.gz';
   #my $ffmpeg_md5='965739cd5cfeb84401857dadea3af93c';
   #foreach my $count (1..3) {
   #   ($stdout,$stderr)=$handle->cmd('sudo '.
   #      "wget --random-wait --progress=dot ".
   #      "http://ffmpeg.gusari.org/static/64bit/$ffmpeg_tar",
   #      '__display__');
   #   ($stdout,$stderr)=$handle->cmd(
   #      "sudo md5sum -c - <<<\"$ffmpeg_md5 $ffmpeg_tar\"",
   #      '__display__');
   #   unless ($stderr) {
   #      print(qq{ + CHECKSUM Test for $ffmpeg_tar *PASSED* \n});
   #      last
   #   } elsif ($count>=3) {
   #      print "FATAL ERROR! : CHECKSUM Test for $ffmpeg_tar *FAILED* ",
   #            "after $count attempts\n";
   #      &Net::FullAuto::FA_Core::cleanup;
   #   }
   #   ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $ffmpeg_tar",'__display__');
   #}
   #($stdout,$stderr)=$handle->cmd('sudo '.
   #   "tar zxvf $ffmpeg_tar",'__display__');
   #($stdout,$stderr)=$handle->cmd('sudo '."rm -rvf $ffmpeg_tar",'__display__');
   #($stdout,$stderr)=$handle->cmd("./ffmpeg -version",'__display__');
   #($stdout,$stderr)=$handle->cmd('sudo '.
   #   "ln -s /usr/local/bin/ffmpeg/ffmpeg /usr/bin/ffmpeg");
   # http://wiki.razuna.com/display/ecp/FFMpeg+Installation+on+CentOS+and+RedHat
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'wget -qO- https://www.libsdl.org/download-2.0.php');
   $stdout=~s/^.*href=["](.*?[.]tar[.]gz[.]sig)["].*$/$1/s;
   my $sdl_tar=$stdout;
   $sdl_tar=~s/^(.*)[.]sig$/$1/;
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "mkdir -pv release",'__display__');
   my $goodsig=0;
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cwd('release');
      ($stdout,$stderr)=$handle->cmd('sudo '.
         'wget --random-wait --progress=dot '.
         "https://www.libsdl.org/$sdl_tar",
         '__display__');
      ($stdout,$stderr)=$handle->cmd('sudo '.
         'wget --random-wait --progress=dot '.
         "https://www.libsdl.org/$sdl_tar.sig",
         '__display__');
      ($stdout,$stderr)=$handle->cwd("-");
      ($stdout,$stderr)=$handle->cmd(
         "gpg --verify-files ./$sdl_tar.sig",
         '__display__');
      if ($stderr=~/No public key/) {
         $stderr=~s/^.*DSA key ID ([A-Z0-9]+)\s+.*$/$1/s;
         ($stdout,$stderr)=$handle->cmd(
            "gpg --keyserver keys.gnupg.net --recv-keys $stderr",
            '__display__');
         ($stdout,$stderr)=$handle->cmd(
            "gpg --verify-files ./$sdl_tar.sig",
            '__display__');
      }
      if (-1<index $stderr, 'Good signature') {
         ($stdout,$stderr)=$handle->cmd(
            "sudo rm -rvf $sdl_tar.sig",'__display__');
         $goodsig=1;
         last;
      }
   }
   exit_on_error($stderr." in package ".__PACKAGE__.
      " line ".__LINE__."\n")
      if !$goodsig;
   ($stdout,$stderr)=$handle->cwd('release');
   ($stdout,$stderr)=$handle->cmd('sudo tar zxvf *','__display__');
   ($stdout,$stderr)=$handle->cwd('SDL2-2.0.5');
   ($stdout,$stderr)=$handle->cmd('sudo ./configure','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo cp -v sdl2.pc /usr/lib64/pkgconfig',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   my $libvorbis_tar='libvorbis-1.3.3.tar.gz';
   my $libvorbis_md5='6b1a36f0d72332fae5130688e65efe1f';
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "http://downloads.xiph.org/releases/vorbis/".
         $libvorbis_tar,'__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo md5sum -c - <<<\"$libvorbis_md5 $libvorbis_tar\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $libvorbis_tar *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $libvorbis_tar *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $libvorbis_tar",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "tar xzvf $libvorbis_tar",'__display__');
   $libvorbis_tar=~s/\.tar\.gz$//;
   ($stdout,$stderr)=$handle->cwd($libvorbis_tar);
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'git clone https://chromium.googlesource.com/webm/libvpx',
      '__display__');
   ($stdout,$stderr)=$handle->cwd('libvpx');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-shared','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   my $libmad_tar='libmad-0.15.1b.tar.gz';
   $goodsig=0;
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "ftp://ftp.mars.org/pub/mpeg/".$libmad_tar,
         '__display__');
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "ftp://ftp.mars.org/pub/mpeg/$libmad_tar.sign",
         '__display__');
      ($stdout,$stderr)=$handle->cwd("-");
      ($stdout,$stderr)=$handle->cmd(
         "gpg --verify-files ./$libmad_tar.sign",
         '__display__');
      if ($stderr=~/No public key/) {
         $stderr=~s/^.*DSA key ID ([A-Z0-9]+)\s+.*$/$1/s;
         ($stdout,$stderr)=$handle->cmd(
            "gpg --keyserver keys.gnupg.net --recv-keys $stderr",
            '__display__');
         ($stdout,$stderr)=$handle->cmd(
            "gpg --verify-files ./$libmad_tar.sign",
            '__display__');
      }
      if (-1<index $stderr, 'Good signature') {
         ($stdout,$stderr)=$handle->cmd(
            "sudo rm -rvf $libmad_tar.sign",'__display__');
         $goodsig=1;
         last;
      }
   }
   exit_on_error($stderr." in package ".__PACKAGE__.
      " line ".__LINE__."\n")
      if !$goodsig;
   ($stdout,$stderr)=$handle->cmd('sudo tar zxvf '.$libmad_tar,'__display__');
   ($stdout,$stderr)=$handle->cwd("libmad-0.15.1b");
   ($stdout,$stderr)=$handle->cmd('sudo ./configure','__display__');
   ($stdout,$stderr)=$handle->cmd("sudo sed -i 's/-fforce-mem //' ".
      "Makefile");
   ($stdout,$stderr)=$handle->cmd('sudo make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install','__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/ffmpeg/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'git clone git://source.ffmpeg.org/ffmpeg','__display__');
   ($stdout,$stderr)=$handle->cwd('ffmpeg');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure --enable-gpl --enable-libfdk_aac --enable-libmp3lame '.
      '--enable-libtheora --enable-libvorbis --enable-libvpx --enable-libx264 '.
      '--enable-nonfree --disable-static --enable-shared','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make',300,'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo make install',300,'__display__');
   ($stdout,$stderr)=$handle->cwd('/opt/source/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "gem install flvtool2",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'yum -y install freetype-devel freeglut-devel',
      '__display__');
   my $mediainfo_tar='MediaInfo_CLI_0.7.92.1_GNU_FromSource.tar.gz';
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "wget --random-wait --progress=dot ".
      "https://mediaarea.net/download/binary/mediainfo/0.7.92.1/".
      $mediainfo_tar,300,
      '__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "tar xvf $mediainfo_tar",'__display__');
   ($stdout,$stderr)=$handle->cwd('MediaInfo_CLI_GNU_FromSource');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './CLI_Compile.sh','__display__');
   ($stdout,$stderr)=$handle->cwd('MediaInfo/Project/GNU/CLI');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'ln -s /usr/local/bin/mediainfo /usr/bin/mediainfo');
   ($stdout,$stderr)=$handle->cwd('/opt/source/');
   my $c='wget -qO- https://api.github.com/users/gpac/repos';
   ($stdout,$stderr)=$local->cmd($c);
   my @repos=();
   @repos=decode_json($stdout);
   my $default_branch=$repos[0]->[1]->{'default_branch'};
   my $updated=$repos[0]->[1]->{'updated_at'};
   my @branches=();
   $c='wget -qO- https://api.github.com/repos/gpac/gpac/branches';
   ($stdout,$stderr)=$local->cmd($c);
   @branches=decode_json($stdout);
   my @builds=();
   $updated=~s/^(.*)T.*$/$1/;
   my $scrollnum=0;my $count=0;
   foreach my $branch (@{$branches[0]}) {
      $count++;
      print "BRANCH NAME=",$branch->{name},"\n";
      push @builds,$branch->{name};
      if ($default_branch eq $branch->{name}) {
         $scrollnum=$count;
      }
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "git clone -v -b $default_branch git://github.com/gpac/gpac",
      '__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "git ls-remote --tags git://github.com/gpac/gpac",
      '__display__');
   my %tags=();
   foreach my $line (split /\n/, $stdout) {
      my ($string,$tag)=('','');
      ($string,$tag)=split /refs\/tags\//, $line;
      $tags{$tag}=$string;
   }
   ($stdout,$stderr)=$handle->cwd('gpac');
   my $tag=(reverse sort keys %tags)[0];
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "git checkout tags/$tag",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'ls -l','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      './configure','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'sed -i \'s#-lgpac$#-lgpac -Wl,-rpath=/usr/local/lib#\' '.
      'applications/mp4box/Makefile');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'make','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'make install','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'cp -v gpac.pc /usr/lib64/pkgconfig','__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'pecl config-set php_ini /etc/php.ini','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'pear config-set php_ini /etc/php.ini','__display__');
   ($stdout,$stderr)=$handle->cmd(
      "yes '' | sudo pecl install imagick",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "yes '' | sudo pear install mail",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "yes '' | sudo pear install Net_SMTP",'__display__');
   ($stdout,$stderr)=$handle->cwd('~');
#   my $im=<<END;
#; Enable imagick extension module
#extension=/usr/lib64/php/5.5/modules/imagick.so
#END
#   ($stdout,$stderr)=$handle->cmd(
#      "echo -e \"$im\" > imagick.ini");
#   ($stdout,$stderr)=$handle->cmd('sudo '.
#      "mv -fv imagick.ini /etc/php.d",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "mkdir -pv /opt/source/sourceguardian",'__display__');
   ($stdout,$stderr)=$handle->cwd(
      '/opt/source/sourceguardian');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "wget --random-wait --progress=dot ".
      "http://www.sourceguardian.com/loaders/download/".
      "loaders.linux-x86_64.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "tar zxvf loaders.linux-x86_64.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "cp -Rv ixed.5.5.lin /usr/lib64/php/5.5/modules",'__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   my $zd=<<END;
[sourceguardian] 
zend_extension=/usr/lib64/php/5.5/modules/ixed.5.5.lin
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$zd\" > sourceguardian.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "mv -fv sourceguardian.ini /etc/php.d",'__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "wget --random-wait --progress=dot ".
      "https://github.com/salimane/sphinx-0.9.9/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("unzip master.zip",'__display__');
   ($stdout,$stderr)=$handle->cwd(
      "sphinx-0.9.9-master/api/libsphinxclient");
   ($stdout,$stderr)=$handle->cmd("./configure",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo make install",'__display__');
   ($stdout,$stderr)=$handle->cwd("-");
   ($stdout,$stderr)=$handle->cmd("sudo rm -rfv master.zip",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo rm -rfv sphinx-0.9.9-master",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "yes '' | sudo pecl install sphinx",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "chmod -v 755 /usr/lib64/php/5.5/modules/*",'__display__');
   my $ad=<<END;
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/5.5/centos6-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$ad\" > maria.repo");
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum-config-manager --add-repo maria.repo",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo rpm --import https://yum.mariadb.org/RPM-GPG-KEY-MariaDB",
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y install MariaDB-server MariaDB-client",'__display__');
print "\n\n\n\n\n\n\nWE SHOULD HAVE INSTALLED MARIADB=$stdout<==\n\n\n\n\n\n\n";
   ($stdout,$stderr)=$handle->cmd("uname -a");
   if ($stdout=~/Ubuntu/i) {
      ($stdout,$stderr)=$handle->cmd(
         "sudo apt-get -y install git-all",'__display__');
   } else {
      ($stdout,$stderr)=$handle->cmd(
         "sudo yum -y -v install git-all",'__display__');
   }
   ($stdout,$stderr)=$handle->cwd('/opt/source/');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'git clone https://github.com/arslancb/clipbucket.git','__display__');
my $z=0;
if ($z==1) {
   my $cb_tar='clipbucket-2.8.v3354-stable.zip';
   my $cb_md5='7dc581a36120592035b18cf8b7111916';
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "wget --random-wait --progress=dot ".
         "https://sourceforge.net/projects/clipbucket/files/ClipBucket%20v2/".
         $cb_tar,'__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo md5sum -c - <<<\"$cb_md5 $cb_tar\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $cb_tar *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $cb_tar *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $cb_tar",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "unzip $cb_tar",'__display__');
   $cb_tar=~s/\.zip$//;
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "chmod -Rv 755 $cb_tar",'__display__');
   ($stdout,$stderr)=$handle->cwd("$cb_tar/upload");
}
   ($stdout,$stderr)=$handle->cwd("clipbucket");
   ($stdout,$stderr)=$handle->cmd(
      'git tag | sort -n | tail -1','__display__');
   chomp($stdout);
   # git ls-remote --tags git://github.com/arslancb/clipbucket
   ($stdout,$stderr)=$handle->cmd(
      "sudo git checkout $stdout",'__display__');
   ($stdout,$stderr)=$handle->cwd("upload");
   ($stdout,$stderr)=$handle->cmd(
      'sudo cp -Rv . /var/www/clipbucket','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'sudo chmod -Rv 777 /var/www/clipbucket/cache','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'sudo chmod -Rv 777 /var/www/clipbucket/files','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'sudo chmod -Rv 777 /var/www/clipbucket/images','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'sudo chmod -Rv 777 /var/www/clipbucket/includes','__display__');
   my $fa_builddir=fullauto_builddir($local,$sudo);
   my $ignore='';
   ($ignore,$stdout)=$local->cmd("${sudo}cp -v $fa_builddir/installer/".
      'fullauto_clickable_image.png ~','__display__');
   ($ignore,$stdout)=$local->cmd($sudo.
      'chmod -v 777 fullauto_clickable_image.png','__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->put('fullauto_clickable_image.png');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'chmod -v 777 fullauto_clickable_image.png','__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   my $sd='/var/www/clipbucket/styles/cb_28/theme/images';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -vf fullauto_clickable_image.png $sd",'__display__');
   ($stdout,$stderr)=$local->cmd($sudo.
      "rm -rvf fullauto_clickable_image.png",'__display__');
   ($stdout,$stderr)=$handle->cmd($sudo.
      'sudo chmod -Rv 777 /var/www/clipbucket/styles','__display__');
   my $fullstyle=
      '                                <div class="fullauto">%NL%'.
      '                                        <a href="http://www.fullauto.com">%NL%'.
      '                                                <img src="{$theme}/images/fullauto_clickable_image.png" class="fullauto-image">%NL%'.
      '                                        </a>%NL%'.
      '                                </div>%NL%';
   $ad=<<END;
sed -i '/Collect/i$fullstyle' /var/www/clipbucket/styles/cb_28/layout/header.html
END
   $handle->cmd_raw("${sudo}$ad");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/var/www/clipbucket/styles/cb_28/layout/header.html");
   $handle->cmd_raw(
       "${sudo}sed -i 's/\\(^[<]div.*\\\)/                                \\1/' ".
       "/var/www/clipbucket/styles/cb_28/layout/header.html");
   $fullstyle=
      '<style>%NL%'.
      '.fullauto{%NL%'.
      '    padding: 10px 10px;%NL%'.
      '    float: none;%NL%'.
      '    display: table-cell;%NL%'.
      '    vertical-align: middle;%NL%'.
      '    width: 40px;%NL%'.
      '}%NL%'.
      '.fullauto-image {%NL%'.
      '        display: block;%NL%'.
      '        position: relative;%NL%'.
      '        width: 83px;%NL%'.
      '        height: 40px;%NL%'.
      '}%NL%'.
      '</style>%NL%';
   $ad=<<END;
sed -i '/^[<]script[>]/i$fullstyle' /var/www/clipbucket/styles/cb_28/layout/header.html
END
   $handle->cmd_raw("${sudo}$ad");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/var/www/clipbucket/styles/cb_28/layout/header.html");
   $handle->cmd_raw(
       "${sudo}sed -i 's/\\(^[<]div.*\\\)/                                \\1/' ".
       "/var/www/clipbucket/styles/cb_28/layout/header.html");
   ($stdout,$stderr)=$handle->cwd('/opt/source/');
   ($stdout,$stderr)=$handle->cmd("sudo wget -qO- https://icanhazip.com");
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
   if ($public_ip && $permanent_ip) {
      my $c="aws ec2 describe-instances";
      my ($hash,$output,$error)=run_aws_cmd($c);
      $hash||={};
      $c="aws ec2 describe-addresses";
      my ($hasha,$outputa,$errora)=run_aws_cmd($c);
      $hasha||={};$hasha->{Addresses}||=[];
      my $a_id='';
      foreach my $address (@{$hasha->{Addresses}}) {
         if ($permanent_ip eq $address->{PublicIp}) {
            $a_id=$address->{AllocationId};
            last;
         }
      }
      my %pubip=();my $instance_id='';
      foreach my $res (@{$hash->{Reservations}}) {
         foreach my $inst (@{$res->{Instances}}) {
            my $pip=$inst->{PublicIpAddress}||'';
            my $iid=$inst->{InstanceId}||'';
            next if exists $inst->{State}->{Name} &&
               $inst->{State}->{Name} eq 'terminated';
            if ($public_ip eq $pip) {
               my $c="aws ec2 associate-address --instance-id ".
                     $inst->{InstanceId}." --allocation-id $a_id ".
                     "--allow-reassociation";
               my ($hasha,$outputa,$errora)=run_aws_cmd($c);
               $public_ip=$permanent_ip;
               last;
            }
         }
      } 
   }
   $public_ip='localhost' unless $public_ip;
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # https://www.sitepoint.com/setting-up-php-behind-nginx-with-fastcgi/
   # http://codingsteps.com/install-php-fpm-nginx-mysql-on-ec2-with-amazon-linux-ami/
   # http://code.tutsplus.com/tutorials/revisiting-open-source-social-networking-installing-gnu-social--cms-22456
   # https://wiki.loadaverage.org/clipbucket/installation_guides/install_like_loadaverage
   # https://karp.id.au/social/index.html
   # http://jeffreifman.com/how-to-install-your-own-private-e-mail-server-in-the-amazon-cloud-aws/
   # http://www.linuxveda.com/2015/06/05/gnu-social-vs-twitter/
   my $nginx='nginx-1.10.0';
   $nginx='nginx-1.9.13' if $^O eq 'cygwin';
   ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
      "http://nginx.org/download/$nginx.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cmd("sudo tar xvf $nginx.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd($nginx);
   ($stdout,$stderr)=$handle->cmd("sudo mkdir -vp objs/lib",'__display__');
   ($stdout,$stderr)=$handle->cwd("objs/lib");
   my $pcre='pcre-8.40';
   my $checksum='';
   foreach my $cnt (1..3) {
      ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
         "ftp://ftp.csx.cam.ac.uk/pub/software/".
         "programming/pcre/$pcre.tar.gz",'__display__');
      ($stdout,$stderr)=$handle->cmd("sudo tar xvf $pcre.tar.gz",'__display__');
      last unless $stderr;
      ($stdout,$stderr)=$handle->cmd("sudo rm -rfv $pcre.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo wget -qO- http://zlib.net/index.html");
   my $zlib_ver=$stdout;
   my $sha__256=$stdout;
   $zlib_ver=~s/^.*? source code, version (\d+\.\d+\.\d+).*$/$1/s;
   $sha__256=~s/^.*?SHA-256 hash [<]tt[>](.*?)[<][\/]tt[>].*$/$1/s;
   foreach my $count (1..3) {
      ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
         "http://zlib.net/zlib-$zlib_ver.tar.gz",'__display__');
      $checksum=$sha__256;
      ($stdout,$stderr)=$handle->cmd(
         "sudo sha256sum -c - <<<\"$checksum zlib-$zlib_ver.tar.gz\"",
         '__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for zlib-$zlib_ver *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for ".
               "zlib-$zlib_ver.tar.gz *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf zlib-$zlib_ver.tar.gz",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo tar xvf zlib-$zlib_ver.tar.gz",
      '__display__');
   my $ossl='openssl-1.0.2h';
   foreach my $count (1..3) {
      $checksum='577585f5f5d299c44dd3c993d3c0ac7a219e4949';
      ($stdout,$stderr)=$handle->cmd("sudo wget --random-wait --progress=dot ".
         "https://www.openssl.org/source/$ossl.tar.gz",
         '__display__');
      ($stdout,$stderr)=$handle->cmd(
         "sudo sha1sum -c - <<<\"$checksum $ossl.tar.gz\"",'__display__');
      unless ($stderr) {
         print(qq{ + CHECKSUM Test for $ossl *PASSED* \n});
         last
      } elsif ($count>=3) {
         print "FATAL ERROR! : CHECKSUM Test for $ossl.tar.gz *FAILED* ",
               "after $count attempts\n";
         &Net::FullAuto::FA_Core::cleanup;
      }
      ($stdout,$stderr)=$handle->cmd("sudo rm -rvf $ossl.tar.gz",'__display__');
   }
   ($stdout,$stderr)=$handle->cmd("sudo tar xvf $ossl.tar.gz",'__display__');
   ($stdout,$stderr)=$handle->cwd("../..");
   my $make_nginx='sudo ./configure --sbin-path=/usr/local/nginx/nginx '.
                  '--conf-path=/usr/local/nginx/nginx.conf '.
                  '--pid-path=/usr/local/nginx/nginx.pid '.
                  "--with-http_ssl_module --with-pcre=objs/lib/$pcre ".
                  "--with-zlib=objs/lib/zlib-$zlib_ver";
   ($stdout,$stderr)=$handle->cmd($make_nginx,'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i 's/-Werror //' ./objs/Makefile");
   ($stdout,$stderr)=$handle->cmd("${sudo}make install",'__display__');
   # https://www.liberiangeek.net/2015/10/
   # how-to-install-self-signed-certificates-on-nginx-webserver/
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}mkdir -vp /etc/nginx/ssl.key");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}mkdir -vp /etc/nginx/ssl.crt");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}mkdir -vp /etc/nginx/ssl.csr");
   $handle->{_cmd_handle}->print(
      "${sudo}openssl genrsa -des3 -out ".
      "/etc/nginx/ssl.key/$public_ip.key 2048");
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   $prompt=~s/\$$//;
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'pass phrase for') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         $output='';
         next;
      } elsif (-1<index $output,'Verifying - Enter') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         $output='';
         next;
      }
   }
   while (1) {
      my $trys=0;
      my $ereturn=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         $handle->{_cmd_handle}->print(
            "${sudo}openssl req -new -key /etc/nginx/ssl.key/$public_ip.key ".
            "-out /etc/nginx/ssl.csr/$public_ip.csr");
         my $test='';my $output='';
         while (1) {
            $output.=Net::FullAuto::FA_Core::fetch($handle);
            $test.=$output;
            $test=~tr/\0-\11\14-\37\177-\377//d;
            return 'DONE' if $output=~/$prompt/;
            print $output;
            $test=~s/\n//gs;
            if ($test=~/Enter pass phrase.*key:/s) {
               $handle->{_cmd_handle}->print($service_and_cert_password);
               $output='';
               $test='';
               next;
            } elsif ((-1<index $test,'[AU]:') ||
                  (-1<index $test,'[XX]:')) {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif ((-1<index $test,'[Some-State]:') ||
                  (-1<index $test,'State or Province')) {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'city') {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif ((-1<index $test,'Pty Ltd]:') ||
                  (-1<index $test,'company')) {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'section) []:') {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif ((-1<index $test,'YOUR name) []:') ||
                  (-1<index $test,'Common Name')) {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'Address []:') {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'challenge password []:') {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            } elsif (-1<index $test,'company name []:') {
               $handle->{_cmd_handle}->print();
               $output='';
               $test='';
               next;
            }
         }
         return 'DONE';
      };
      alarm(0);
      last if $ereturn eq 'DONE' || $trys++>3;
   }
   $handle->{_cmd_handle}->print(
      "${sudo}openssl x509 -req -days 365 -in ".
      "/etc/nginx/ssl.csr/$public_ip.csr -signkey ".
      "/etc/nginx/ssl.key/$public_ip.key -out ".
      "/etc/nginx/ssl.crt/$public_ip.crt");
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'Enter pass phrase') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i 's/1024/64/' ".
       "/usr/local/nginx/nginx.conf");
   $ad='          fastcgi_split_path_info ^(.+\\\\.php)(/.+)\$;%NL%'.
       '          fastcgi_param SCRIPT_FILENAME '.
       '/var/www/clipbucket\$fastcgi_script_name;%NL%'.
       "          include fastcgi_params;%NL%".
       "          fastcgi_pass unix:/var/run/php-fpm/php5-fpm.sock;%NL%".
       "          fastcgi_index index.php;%NL%".
       "          ##Add below line to fix the blank screen error%NL%".
       "          include fastcgi.conf;";
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' /usr/local/nginx/nginx.conf
END
   $handle->cmd_raw("${sudo}$ad");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/default_type/".
       "iclient_max_body_size 1000M;%NL%' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/fastcgi.conf/{n;N;d}' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i 's#^[ ]*location / {#        location ~ \\.php {#' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/ location ~/iroot /var/www/clipbucket;' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/ location ~/".
       "iindex index.php index.html index.htm;%NL%' ".
       '/usr/local/nginx/nginx.conf');
   $handle->cmd_raw("${sudo}sed -i ".
       "'s#\\(^client_max_body_size 1000M;$\\\)#    \\1#' ".
       '/usr/local/nginx/nginx.conf');
   $handle->cmd_raw(
       "${sudo}sed -i 's#\\(^root /var/www/clipbucket;$\\\)#        \\1#' ".
       '/usr/local/nginx/nginx.conf');
   $handle->cmd_raw("${sudo}sed -i ".
       "'s#\\(^index index.php index.html index.htm;$\\\)#        \\1#' ".
       '/usr/local/nginx/nginx.conf');
   $ad='%NL%        location /videos {'.
       '%NL%            rewrite ^/videos/(.*)/(.*)/(.*)/(.*)/(.*) /videos.php?cat=$1&sort=$3&time=$4&page=$5&seo_cat_name=$2;'.
       '%NL%            rewrite ^/videos/([0-9]+) /videos.php?page=$1;'.
       '%NL%            rewrite ^/videos/?$ /videos.php?$query_string;'.
       '%NL%        }%NL%'.
       '%NL%        location /video {'.
       '%NL%            rewrite ^/video/(.*)/(.*) /watch_video.php\?v=$1&$query_string;'.
       '%NL%            rewrite ^/video/([0-9]+)_(.*) /watch_video.php?v=$1&$query_string;'.
       '%NL%        }%NL%'.
       '%NL%        location / {'.
       '%NL%            rewrite ^/(.*)_v([0-9]+) /watch_video.phpi\?v=$2&$query_string;'.
       '%NL%            rewrite ^/([a-zA-Z0-9-]+)/?$ /view_channel.php?uid=$1&seo_diret=yes;'.
       '%NL%        }%NL%'.
       '%NL%        location /channels {'.
       '%NL%            rewrite ^/channels/(.*)/(.*)/(.*)/(.*)/(.*) /channels.php\?cat=$1&sort=$3&time=$4&page=$5&seo_cat_name=$2;'.
       '%NL%            rewrite ^/channels/([0-9]+) /channels.php?page=$1;'.
       '%NL%            rewrite ^/channels/?$ /channels.php?$query_string;'.
       '%NL%        }%NL%'.
       '%NL%        location /members {'.
       '%NL%            rewrite ^/members/?$ /channels.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /users {'.
       '%NL%            rewrite ^/users/?$ /channels.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /user {'.
       '%NL%            rewrite ^/user/?$ /channels.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /channel {'.
       '%NL%            rewrite ^/channel/(.*) /view_channel.php?user=$1;'.
       '%NL%        }%NL%'.
       '%NL%        location /my_account {'.
       '%NL%            rewrite ^/my_account /myaccount.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /page {'.
       '%NL%            rewrite ^/page/([0-9]+)/(.*) /view_page.php?pid=$1;'.
       '%NL%        }%NL%'.
       '%NL%        location /search {'.
       '%NL%            rewrite ^/search/result/?$ /search_result.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /upload {'.
       '%NL%            rewrite ^/upload/?$ /upload.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /contact {'.
       '%NL%            rewrite ^/contact/?$ /contact.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /categories {'.
       '%NL%            rewrite ^/categories/?$ /categories.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /group {'.
       '%NL%            rewrite ^/group/([a-zA-Z0-9].+) /view_group.php?url=$1&$query_string;'.
       '%NL%        }%NL%'.
       '%NL%        location /view_topic {'.
       '%NL%            rewrite ^/view_topic/([a-zA-Z0-9].+)_tid_([0-9]+) /view_topic.php?tid=$2&$query_string;'.
       '%NL%        }%NL%'.
       '%NL%        location /groups {'.
       '%NL%            rewrite ^/groups/(.*)/(.*)/(.*)/(.*)/(.*) /groups.php?cat=$1&sort=$3&time=$4&page=$5&seo_cat_name=$2;'.
       '%NL%            rewrite ^/groups/([0-9]+) /groups.php?page=$1;'.
       '%NL%            rewrite ^/groups/?$ /groups.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /create_group {'.
       '%NL%            rewrite ^/create_group /create_group.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /collections {'.
       '%NL%            rewrite ^/collections/(.*)/(.*)/(.*)/(.*)/(.*) /collections.php?cat=$1&sort=$3&time=$4&page=$5&seo_cat_name=$2;'.
       '%NL%            rewrite ^/collections/([0-9]+) /collections.php?page=$1;'.
       '%NL%            rewrite ^/collections/?$ /collections.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /photos {'.
       '%NL%            rewrite ^/photos/(.*)/(.*)/(.*)/(.*)/(.*) /photos.php?cat=$1&sort=$3&time=$4&page=$5&seo_cat_name=$2;'.
       '%NL%            rewrite ^/photos/([0-9]+) /photos.php?page=$1;'.
       '%NL%            rewrite ^/photos/?$ /photos.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /collection {'.
       '%NL%            rewrite ^/collection/(.*)/(.*)/(.*) /view_collection.php?cid=$1&type=$2&$query_string;'.
       '%NL%        }%NL%'.
       '%NL%        location /item {'.
       '%NL%            rewrite ^/item/(.*)/(.*)/(.*)/(.*) /view_item.php?item=$3&type=$1&collection=$2;'.
       '%NL%        }%NL%'.
       '%NL%        location /photo_upload {'.
       '%NL%            rewrite ^/photo_upload/(.*) /photo_upload.php?collection=$1;'.
       '%NL%            rewrite ^/photo_upload/?$ /photo_upload.php;'.
       '%NL%        }%NL%'.
       '%NL%        location = /sitemap.xml {'.
       '%NL%            rewrite ^(.*)$ /sitemap.php;'.
       '%NL%        }%NL%'.
       '%NL%        location /signup {'.
       '%NL%            rewrite ^/signup/?$ /signup.php;'.
       '%NL%        }%NL%'.
       '%NL%        location = /rss {'.
       '%NL%            rewrite ^/rss/([a-zA-Z0-9].+)$ /rss.php?mode=$1&$query_string;'.
       '%NL%        }';
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'/#error_page/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/usr/local/nginx/nginx.conf");
   # https://www.linode.com/docs/websites/nginx/nginx-and-phpfastcgi-on-centos-5
   $ad='%NL%        location /static {'.
       "%NL%            root /var/www/clipbucket/root;".
       '%NL%        }%NL%'.
       '%NL%        ssl off;'.
       "%NL%        ssl_certificate /etc/nginx/ssl.crt/$public_ip.crt;".
       "%NL%        ssl_certificate_key /etc/nginx/ssl.key/$public_ip.key;".
       '%NL%        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;'.
       '%NL%        ssl_ciphers '.
       '"HIGH:!aNULL:!MD5 or HIGH:!aNULL:!MD5:!3DES";';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/404/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/usr/local/nginx/nginx.conf");
   $ad='%NL%'.
       '    #server {%NL%'.
       '       #listen 80;%NL%'.
       '       #listen [::]:80;%NL%'.
       '%NL%'.
       "       #server_name  $public_ip;%NL%".
       '%NL%'.
       '       # FIXME: change domain name here (and also make sure '.
       'you do the same in the next %SQ%server%SQ% section)%NL%'.
       '%NL%'.
       '       # redirect all traffic to HTTPS%NL%'.
       '       #rewrite ^ https://\$server_name\$request_uri? permanent;%NL%'.
       '    #}';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/#gzip/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
       '/usr/local/nginx/nginx.conf');
   #($stdout,$stderr)=$handle->cmd(
   #    "${sudo}sed -i \'s/^        listen       80/        listen       ".
   #    "\*:443 ssl default_server/\' /usr/local/nginx/nginx.conf");
   my $ngx='/usr/local/nginx/nginx.conf';
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'/split_path/a        try_files \$uri =404;\' $ngx");
   $handle->cmd_raw(
       "${sudo}sed -i 's/\\(^try_files.*\\\)/          \\1/' $ngx");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/localhost/$public_ip/\' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/nobody/ec2-user/\' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/#user/user/\' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/^          fastcgi_index/{n;N;d}' ".
       '/usr/local/nginx/nginx.conf');
   $handle->{_cmd_handle}->print("${sudo}/usr/local/nginx/nginx");
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'PEM pass phrase') {
         $handle->{_cmd_handle}->print($service_and_cert_password);
         $output='';
         next;
      }
   }
   ($stdout,$stderr)=$handle->cmd("sudo /etc/init.d/mysql start",
      '__display__');
   if ($stderr) {
      ($stdout,$stderr)=$handle->cmd(
         "sudo yum -y install MariaDB-server MariaDB-client",'__display__');
      ($stdout,$stderr)=$handle->cmd("sudo /etc/init.d/mysql start",
         '__display__');
   }
   $handle->{_cmd_handle}->print('sudo mysql_secure_installation');
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
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
   $handle->cmd("echo");
   $handle->{_cmd_handle}->print('mysql -u root -p 2>&1');
   my $first_pass=0;
   my $second_pass=0;
   my $third_pass=0;
   my $fourth_pass=0;
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/ && $first_pass;
      print $output;
      if (-1<index $output,'Enter password:') {
         $handle->{_cmd_handle}->print();
         next;
      } elsif (-1<index $output,'none') {
         if (!$first_pass) {
            $handle->{_cmd_handle}->print('CREATE DATABASE clipbucket;');
            $first_pass=1;
         } elsif (!$second_pass) {
            $handle->{_cmd_handle}->print(
               'GRANT USAGE ON clipbucket.* TO clipbucket@localhost'.
               " IDENTIFIED BY \'$service_and_cert_password\';");
            $second_pass=1;
         } elsif (!$third_pass) {
            $handle->{_cmd_handle}->print(
               'GRANT ALL PRIVILEGES ON clipbucket.* TO clipbucket@localhost;');
            $third_pass=1;
         } elsif (!$fourth_pass) {
            $handle->{_cmd_handle}->print('flush privileges;');
            $fourth_pass=1;
         } else {
            $handle->{_cmd_handle}->print('exit;');
         }
      }
   }
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s#127.0.0.1:9000#/var/run/php-fpm/php5-fpm.sock#\' ".
      '/etc/php-fpm-5.5.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/;listen.owner = nobody/listen.owner = ec2-user/\' ".
      '/etc/php-fpm-5.5.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/;listen.group = nobody/listen.group = ec2-user/\' ".
      '/etc/php-fpm-5.5.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/user = apache/user = ec2-user/\' ".
      '/etc/php-fpm-5.5.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/group = apache/group = ec2-user/\' ".
      '/etc/php-fpm-5.5.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/;listen.mode = 0660/listen.mode = 0664/\' ".
      '/etc/php-fpm-5.5.d/www.conf');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chgrp -Rv ec2-user /var/lib/php/5.5/session ".
      '/var/lib/php/5.5/wsdlcache','__display__');
   ($stdout,$stderr)=$handle->cwd("/var/www/clipbucket");
   ($stdout,$stderr)=$handle->cmd("${sudo}chgrp -v ec2-user .");
   ($stdout,$stderr)=$handle->cmd("${sudo}chmod -v g+w .");
   ($stdout,$stderr)=$handle->cwd("~");
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
   my ($hash,$output,$error)=('','','');
   $c="aws iam list-access-keys --user-name clipbucket_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   foreach my $hash (@{$hash->{AccessKeyMetadata}}) {
      my $c="aws iam delete-access-key --access-key-id $hash->{AccessKeyId} ".
            "--user-name clipbucket_email";
      ($hash,$output,$error)=run_aws_cmd($c);
   }
   sleep 1;
   $c="aws iam delete-user --user-name clipbucket_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c="aws iam create-user --user-name clipbucket_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c="aws iam create-access-key --user-name clipbucket_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   my $access_id=$hash->{AccessKey}->{AccessKeyId};
   my $secret_access_key=$hash->{AccessKey}->{SecretAccessKey};
   my $java_smtp_generator=<<END;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import javax.xml.bind.DatatypeConverter;

public class SesSmtpCredentialGenerator {

       // From http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-credentials.html

       private static final String KEY_ENV_VARIABLE = \\x22AWS_SECRET_ACCESS_KEY\\x22; // Put your AWS secret access key in this environment variable.
       private static final String MESSAGE = \\x22SendRawEmail\\x22; // Used to generate the HMAC signature. Do not modify.
       private static final byte VERSION =  0x02; // Version number. Do not modify.

       public static void main(String[] args) {
    	       	   	
              // Get the AWS secret access key from environment variable AWS_SECRET_ACCESS_KEY.
              String key = System.getenv(KEY_ENV_VARIABLE);         	  
              if (key == null)
              {
                 System.out.println(\\x22Error: Cannot find environment variable AWS_SECRET_ACCESS_KEY.\\x22);  
                 System.exit(0);
              }
   	    	       	   
              // Create an HMAC-SHA256 key from the raw bytes of the AWS secret access key.
              SecretKeySpec secretKey = new SecretKeySpec(key.getBytes(), \\x22HmacSHA256\\x22);

              try {         	  
                     // Get an HMAC-SHA256 Mac instance and initialize it with the AWS secret access key.
                     Mac mac = Mac.getInstance(\\x22HmacSHA256\\x22);
                     mac.init(secretKey);

                     // Compute the HMAC signature on the input data bytes.
                     byte[] rawSignature = mac.doFinal(MESSAGE.getBytes());

                     // Prepend the version number to the signature.
                     byte[] rawSignatureWithVersion = new byte[rawSignature.length + 1];               
                     byte[] versionArray = {VERSION};                
                     System.arraycopy(versionArray, 0, rawSignatureWithVersion, 0, 1);
                     System.arraycopy(rawSignature, 0, rawSignatureWithVersion, 1, rawSignature.length);

                     // To get the final SMTP password, convert the HMAC signature to base 64.
                     String smtpPassword = DatatypeConverter.printBase64Binary(rawSignatureWithVersion);       
                     System.out.println(smtpPassword);
              } 
              catch (Exception ex) {
                     System.out.println(\\x22Error generating SMTP password: \\x22 + ex.getMessage());
              }             
       }
}
END
   ($stdout,$stderr)=$handle->cmd(
      "echo -e \"$java_smtp_generator\" > SesSmtpCredentialGenerator.java");
   ($stdout,$stderr)=$handle->cmd('javac SesSmtpCredentialGenerator.java');
   $handle->cmd_raw(
      "export AWS_SECRET_ACCESS_KEY=$secret_access_key");
   my $smtppass='';
   ($smtppass,$stderr)=$handle->cmd('java SesSmtpCredentialGenerator');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "mv -fv SesSmtpCredentialGenerator.* /opt/source",'__display__');
   my $sespolicy=<<END;
{
   \\x22Version\\x22:\\x222012-10-17\\x22,
   \\x22Statement\\x22: [{
        \\x22Effect\\x22:\\x22Allow\\x22,
        \\x22Action\\x22:\\x22ses:SendRawEmail\\x22,
        \\x22Resource\\x22:\\x22*\\x22
}]}
END
   chop $sespolicy;
   ($stdout,$stderr)=$local->cmd(
      "echo -e \"$sespolicy\" > ./sespolicy");
   $c="aws iam list-policies";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   foreach my $policy (@{$hash->{Policies}}) {
      if ($policy->{PolicyName} eq 'sespolicy_clipbucket') {
         $c="aws iam detach-user-policy --user-name clipbucket_email ".
            "--policy-arn $policy->{Arn}";
         ($hash,$output,$error)=run_aws_cmd($c);
         $c="aws iam delete-policy --policy-arn $policy->{Arn}";
         ($hash,$output,$error)=run_aws_cmd($c);
         chomp($output);
         warn($output." in package ".__PACKAGE__.
            " line ".__LINE__."\n")
            if $output=~/error occurred/;
         next if $output=~/error occurred/;
         last;
      }
   }
   $c="aws iam create-policy --policy-name sespolicy_clipbucket ".
      "--policy-document file://sespolicy";
   ($hash,$output,$error)=run_aws_cmd($c);
   chomp $output;
   exit_on_error($output." in package ".__PACKAGE__.
      " line ".__LINE__."\n")
      if $output=~/error occurred/;
   my $policy_arn=$hash->{Policy}->{Arn};
   $c="aws iam attach-user-policy --user-name clipbucket_email ".
      "--policy-arn $policy_arn";
   ($hash,$output,$error)=run_aws_cmd($c);
   ($stdout,$stderr)=$local->cmd("rm -rfv ./sespolicy",'__display__'); 
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/post_max_size = 8M/post_max_size = 500M/\' ".
      "/etc/php.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/post_max_size = 8M/post_max_size = 500M/\' ".
      "/etc/php-5.5.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/upload_max_filesize = 2M/upload_max_filesize = 500M/\' ".
      "/etc/php.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/upload_max_filesize = 2M/upload_max_filesize = 500M/\' ".
      "/etc/php-5.5.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/max_execution_time = 30/max_execution_time = 7500/\' ".
      "/etc/php.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/max_execution_time = 30/max_execution_time = 7500/\' ".
      "/etc/php-5.5.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/memory_limit = 128M/memory_limit = 256M/\' ".
      "/etc/php.ini");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \'s/memory_limit = 128M/memory_limit = 256M/\' ".
      "/etc/php-5.5.ini");
   ($stdout,$stderr)=$handle->cmd("${sudo}/etc/init.d/php-fpm start");
   my $substitute_email_module='%NL%'.
'#####################################################%NL%'.
'# Inserted by FullAuto to handle Amazon SES passwords%NL%'.
'#####################################################%NL%%NL%'.
'require_once %SQ%Mail.php%SQ%;%NL%'.
'%NL%'.
'$headers = array (%NL%'.
'  %SQ%From%SQ% => $from,%NL%'.
'  %SQ%To%SQ% => $to,%NL%'.
'  %SQ%Subject%SQ% => $subject,%NL%'.
'  %SQ%MIME-Version%SQ% => "1.0",%NL%'.
'  %SQ%Content-Type%SQ% => "text/html; charset=iso-8859-1"%NL%'.
');%NL%'.
'%NL%'.
'$smtpParams = array (%NL%'.
'  %SQ%host%SQ% => $mail->Host,%NL%'.
'  %SQ%port%SQ% => $mail->Port,%NL%'.
'  %SQ%auth%SQ% => true,%NL%'.
'  %SQ%username%SQ% => $mail->Username,%NL%'.
'  %SQ%password%SQ% => $mail->Password%NL%'.
');%NL%'.
'%NL%'.
' // Create an SMTP client.%NL%'.
'$mail = Mail::factory(%SQ%smtp%SQ%, $smtpParams);%NL%'.
'%NL%'.
'// Send the email.%NL%'.
'$result = $mail->send($to, $headers, $message);%NL%'.
'%NL%'.
'#if (PEAR::isError($result)) {%NL%'.
'#  echo("Email not sent. " .$result->getMessage() ."\\n");%NL%'.
'#} else {%NL%'.
'#   echo("Email sent!"."\\n");%NL%'.
'#}%NL%%NL%'.
'####################################################%NL%'.
'# Commented Out by FullAuto so above sends all email%NL%'.
'####################################################%NL%';
   ($stdout,$stderr)=$handle->cwd("/var/www/clipbucket/includes");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'/MsgHTML/i$substitute_email_module\' functions.php");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      'functions.php');
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      'functions.php');
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "'/MsgHTML/,+8 s/^/#/' ".
      'functions.php');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i 's/webmaster\@website/".$verified_email."/' ".
      'functions.php');
   ($stdout,$stderr)=$handle->cmd_raw('cat functions.php | sudo '.
      'bash -ic "awk \'{ sub(/\r$/,\"\"); print }\' > temp.php"');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'mv -fv temp.php functions.php','__display__');
   ($stdout,$stderr)=$handle->cwd("/var/www/clipbucket/cb_install/sql");
   my %smtp_host=('us-east-1' => 'email-smtp.us-east-1.amazonaws.com',
                  'us-west-2' => 'email-smtp.us-west-2.amazonaws.com',
                  'eu-west-1' => 'email-smtp.eu-west-1.amazonaws.com');
   my $smtp_host='email-smtp.us-east-1.amazonaws.com';
   $region=~s/^.*['](.*)[']$/$1/;
   if (exists $smtp_host{$region}) {
      $smtp_host=$smtp_host{$region};
   }
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i 's/webmaster\@website/".$verified_email."/' ".
      'add_admin.sql');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/2, '777750fea4d3bd585bf47dc1873619fc'/".
      "2, '38d8e594a1ddbd29fdba0de385d4fefa'/\" ".
      'add_admin.sql');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i 's/webmaster\@localhost/".$verified_email."/' ".
      'configs.sql');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/'mail'/'smtp'/\" ".
      'configs.sql');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/'smtp_host', ''/'smtp_host', '".$smtp_host.
      "'/\" configs.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s#'baseurl', ''#'baseurl', 'https://".$public_ip.
      "'#\" configs.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s#'basedir', ''#'basedir', '/var/www/clipbucket".
      "'#\" configs.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/'smtp_user', ''/'smtp_user', '".$access_id.
      "'/\" configs.sql");
   $smtppass=~s/\//\\\//g;
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/'smtp_pass', ''/'smtp_pass', '".$smtppass.
      "'/\" configs.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/'smtp_auth', 'no'/'smtp_auth', 'yes'/\"".
      " configs.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/'smtp_port', ''/'smtp_port', '25'/\"".
      " configs.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/{tbl_prefix}_video/{tbl_prefix}video/\"".
      " structure.sql");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/{tbl_prefix}_groups/{tbl_prefix}groups/\"".
      " structure.sql");
   my $datestring = strftime "%Y-%d-%e %H:%M:%S", localtime;
   $datestring=sprintf($datestring);
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/now()/'".$datestring."'/\"".
      " categories.sql");
   my @sql=('structure','configs','ads_placements',
            'countries','email_templates','pages','user_levels',
            'categories','add_admin');
   foreach my $file (@sql) {
      print "\nRUNNING $file.sql SQL FILE\n";
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "sed -i \"s/{tbl_prefix}/cb_/\" $file.sql");
      ($stdout,$stderr)=$handle->cmd('sudo '.
         "mysql --verbose --force -u clipbucket -p".
         "'".$service_and_cert_password."' clipbucket < $file.sql",
         '__display__');
   }
   ($stdout,$stderr)=$handle->cwd("/var/www/clipbucket/includes");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "cp -v /var/www/clipbucket/cb_install/clipbucket.php ".
      "/var/www/clipbucket/includes",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "cp -v dbconnect.sample.php dbconnect.php",'__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i 's/clipbucket_svn/clipbucket/' dbconnect.php");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i 's/root/clipbucket/' dbconnect.php");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      "sed -i \"s/''/'".$service_and_cert_password."'/\" dbconnect.php");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'rm -rvf /var/www/clipbucket/cb_install','__display__');
   ($stdout,$stderr)=$handle->cwd('~');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'chmod -Rv 755 /var/www/clipbucket/includes/','__display__');
   $ad=<<'END';
\\x2A \\x2A \\x2A \\x2A \\x2A php -q /var/www/clipbucket/actions/video_convert.php
\\x2A \\x2A \\x2A \\x2A \\x2A php -q /var/www/clipbucket/actions/verify_converted_videos.php
0 0,12,13 \\x2A \\x2A \\x2A php -q /var/www/clipbucket/actions/update_cb_stats.php
END
   ($stdout,$stderr)=$handle->cmd("echo -e \"$ad\" > root");
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'cp root /var/spool/cron/','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'rm -rvf root','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'service crond restart','__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'rm -rvf /var/www/clipbucket/files/temp/install.me','__display__');
   use LWP::UserAgent;
   use HTTP::Request::Common;
   use IO::Socket::SSL qw();
   my $Browser = LWP::UserAgent->new(
      ssl_opts => {
         SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
         verify_hostname => 0,
      }
   );
   my $starting_clipbucket=<<'END';



     .oPYo. ooooo    .oo  .oPYo. ooooo o o    o .oPYo.      o    o  .oPYo.
     8        8     .P 8  8   `8   8   8 8b   8 8    8      8    8  8    8
     `Yooo.   8    .P  8  8YooP'   8   8 8`b  8 8           8    8  8YooP'
         `8   8   oPooo8  8   `b   8   8 8 `b 8 8   oo      8    8  8
          8   8  .P    8  8    8   8   8 8  `b8 8    8      8    8  8
     `YooP'   8 .P     8  8    8   8   8 8   `8 `YooP8      `YooP'  8
     ....................................................................
     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                           http://clipbucket.com/

        _____ _      _______  ____  _    _  _____ _   __ ______ _______
       / ____| |    | |  __ \|  _ \| |  | |/ ____| | / /|  ____|__   __|
      / /    | |    | | |__) | |_) | |  | | |    | |/ / | |__     | |
      | |    | |    | |  ___/|  _ <| |  | | |    |    \ |  __|    | |
      | \____| |____| | |    | |_) | |__| | |____| |\  \| |____   | |
       \_____|______|_|_|    |____/ \____/ \_____|_| \__|______|  |_|


        (CLIPBUCKET is **NOT** a sponsor of the FullAuto© Project.)
END
   print $starting_clipbucket;sleep 10;
   $region=~s/^.*['](.*)[']$/$1/;
   ($stdout,$stderr)=$handle->cmd('sudo wget -qO- '.
      'http://docs.aws.amazon.com/ses/latest/DeveloperGuide/smtp-connect.html'
      );
   my @smtp_servers=();my $smtp_server='us-east-1';
   foreach my $line (split /\n/,$stdout) {
      if (-1<index $line,'email-smtp.') {
         $line=~s/^.*(email-smtp\.[^Hh].*?com).*$/$1/;
         next unless $line=~/^email-smtp/;
         push @smtp_servers,$line;
         if (-1<index $line,$region) {
            $smtp_server=$line;
            last;
         }
      }
   }
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}touch /etc/mail/authinfo");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod 666 /etc/mail/authinfo");
   my $authinfo=<<END;
AuthInfo:$smtp_server \\x22U:root\\x22 \\x22I:$access_id\\x22 \\x22P:$smtppass\\x22 \\x22M:PLAIN\\x22
END
   chop $authinfo;   
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}echo -e \"$authinfo\" > /etc/mail/authinfo");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}makemap -v hash /etc/mail/authinfo.db < /etc/mail/authinfo",
      '__display__');
   my $access="Connect:$smtp_server RELAY";
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod -v 666 /etc/mail/access");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}echo -e \"$access\" >> /etc/mail/access");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod -v 644 /etc/mail/access");
   my $email_domain=$verified_email;
   $email_domain=~s/^.*\@(.*)$/$1/;
   $ad="define(`SMART_HOST%SQ%, `$smtp_server%SQ%)dnl%NL%".
       "define(`RELAY_MAILER_ARGS%SQ%, `TCP \$h 25%SQ%)dnl%NL%".
       "define(`confAUTH_MECHANISMS%SQ%, `LOGIN PLAIN%SQ%)dnl%NL%".
       "FEATURE(`authinfo%SQ%, `hash -o /etc/mail/authinfo.db%SQ%)dnl%NL%".
       "MASQUERADE_AS(`$email_domain%SQ%)dnl%NL%".
       "FEATURE(masquerade_envelope)dnl%NL%".
       "FEATURE(masquerade_entire_domain)dnl";
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'/MAILER(smtp)dnl/i$ad\' /etc/mail/sendmail.mc");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       '/etc/mail/sendmail.mc');
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
       '/etc/mail/sendmail.mc');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod -v 666 /etc/mail/sendmail.cf",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}m4 -d /etc/mail/sendmail.mc > /etc/mail/sendmail.cf");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod -v 644 /etc/mail/sendmail.cf",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}/etc/init.d/sendmail restart",'__display__');
   print "\n   ACCESS CLIPBUCKET UI AT:\n\n",
         " http://$public_ip\n";
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
            "   to start with your new CLIPBUCKET installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_clipbucket=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $region="]T[{awsregions}";
   $region=~s/^"//;
   $region=~s/"$//;
   my $verified_email="]T[{pick_email}";
   if (-1<index $verified_email,'Enter ') {
      $verified_email="]I[{'clipbucket_enter_email_address',1}";
   }
   my $clipbucket="]T[{select_clipbucket_setup}";
   my $permanent_ip="]T[{permanent_ip}";
   my $site_name="]I[{'clipbucket_enter_site_name',1}";
   my $site_profile="]T[{choose_site_profile}";
   my $site_build="]T[{choose_build}";
   my $strong_password="]I[{'clipbucket_enter_password',1}";
   my $twitter_api_key="]I[{'clipbucket_twitter_api',1}";
   my $twitter_api_sec="]I[{'clipbucket_twitter_api',2}";
   #if (-1<index $site_name, ']T[') {
   #   $site_name="]I[{'clipbucket_enter_domain_name',1}"; 
   #}
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
      'ClipBucketSecurityGroup --description '.
      '"CLIPBUCKET.com Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ClipBucketSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ClipBucketSecurityGroup --protocol '.
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name ClipBucketSecurityGroup --protocol '.
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'CLIPBUCKET.com'}) {
      my $g=get_aws_security_id('ClipBucketSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'CLIPBUCKET.com'}}==0) {
         launch_server('CLIPBUCKET.com',$cnt,$clipbucket,'',$c,
         $configure_clipbucket,'',$region,$verified_email,
         $permanent_ip,$site_name,$site_profile,$site_build,
         $strong_password,$twitter_api_key,$twitter_api_sec);
      } else {
         my $num=$#{$main::aws->{'CLIPBUCKET.com'}}-1;
         foreach my $num (0..$num) {
            launch_server('CLIPBUCKET.com',$cnt++,$clipbucket,'',$c,
            $configure_clipbucket,'',$region,$verified_email,
            $permanent_ip,$site_name,$site_profile,$site_build,
            $strong_password,$twitter_api_key,$twitter_api_sec);
         }
      }
   }

   return '{choose_is_setup}<';

};

our $clipbucket_setup_summary=sub {

   package clipbucket_setup_summary;
   #my $site_name="]I[{'clipbucket_enter_site_name',1}";
   #unless ($site_name) {
   #   STDOUT->autoflush(1);
   #   print "\n   ERROR: Site Name cannot be blank!";sleep 5;
   #   STDOUT->autoflush(0);
   #   return '<';
   #}
   my $permanent_ip="]T[{permanent_ip}";
   my $remember="]I[{'clipbucket_enter_site_name',1}";
   $remember='' if -1<index $remember,'clipbucket_enter_site_name';
   if ($permanent_ip=~/^["]Release.* (\d+\.\d+\.\d+\.\d+).*$/s) {
      my $ip_to_release=$1;
      my $c="aws ec2 describe-addresses";
      my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};$hash->{Addresses}||=[];
      foreach my $address (@{$hash->{Addresses}}) {
         if ($address->{PublicIp} eq $ip_to_release) {
            my $c="aws ec2 release-address ".
                  "--allocation-id $address->{AllocationId}";
            my ($hash,$output,$error)=
               &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
            last;
         }
      }
      print "\n   $ip_to_release HAS BEEN RELEASED . . .\n";
      sleep 5;
      return $Net::FullAuto::ISets::Amazon::ClipBucket_is::check_elastic_ip->();
   } elsif ($permanent_ip=~/(\d+\.\d+\.\d+\.\d+)/s) {
      $main::aws->{permanent_ip}=$1;
   } elsif ($permanent_ip=~/Allocate|Elastic \(Permanent\)/) {
      my $c="aws ec2 allocate-address --domain vpc";
      my ($hash,$output,$error)=
            &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};
      $main::aws->{permanent_ip}=$hash->{PublicIp};
   }
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
   my $clipbucket="]T[{select_clipbucket_setup}";
   $clipbucket=~s/^"//;
   $clipbucket=~s/"$//;
   my $num_of_servers=0;
   my $ol=$clipbucket;
   $ol=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ol==1) {
      $main::aws->{'CLIPBUCKET.com'}->[0]=[];
   } elsif ($ol=~/^\d+$/ && $ol) {
      foreach my $n (0..$ol) {
         $main::aws->{'CLIPBUCKET.com'}=[] unless exists
            $main::aws->{'CLIPBUCKET.com'};
         $main::aws->{'CLIPBUCKET.com'}->[$n]=[];
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
         AWS EC2 $type servers for the following application:

         $clipbucket


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_clipbucket,

      },
      Item_2 => {

         Text => "Return to Choose Instruction Set Menu",
         Result => sub { return '{choose_is_setup}<' },

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

our $check_elastic_ip=sub {

   package check_elastic_ip;
   my $password="]I[{'clipbucket_enter_password',1}";
   my $confirm="]I[{'clipbucket_enter_password',2}";
   if ($password ne $confirm &&
         (-1==index $password,'clipbucket_enter_password')) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Password entries do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   my $c="aws ec2 describe-addresses";
   my ($hash,$output,$error)=
      &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   $hash||={};$hash->{Addresses}||=[];
   if (-1==$#{$hash->{Addresses}}) {
      my $permanent_ip_banner=<<'END';
    ___                                 _     ___ ___ ___
   | _ \___ _ _ _ __  __ _ _ _  ___ _ _| |_  |_ _| _ \__ \
   |  _/ -_) '_| '  \/ _` | ' \/ -_) ' \  _|  | ||  _/ /_/
   |_| \___|_| |_|_|_\__,_|_||_\___|_||_\__| |___|_|  (_)
END
      $permanent_ip_banner.=<<END;

   If you plan on using this CLIPBUCKET server for an extended
   period, you will need a non-temporary IP Address. In Amazon
   Web Services, one Elastic IP (Amazon's way of allocating long 
   term IP addresses) is free so long as it is associated to
   a running server. If you stop or terminate the server, you
   need to manually release the address, or you will incur charges.

   Note also, that a Permanent IP Address will substantially
   increase the likelihood of email being sent from the CLIPBUCKET
   server surviving spam filters and actually arriving at the
   intended destination.

END
      my $permanent_ip={

         Name => 'permanent_ip',
         Item_1 => {

            Text => 'Stay with Temporary Public IP Address',
            Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

         },
         Item_2 => {

            Text => 'Use Elastic (Permanent) IP Address',
            Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

         },
         Scroll => 1,
         Banner => $permanent_ip_banner,

      };
      return $permanent_ip;
   } else {
      my $c="aws ec2 describe-instances";
      my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};$hash->{Addresses}||=[];
      my %pubip=();
      foreach my $res (@{$hash->{Reservations}}) {
         foreach my $inst (@{$res->{Instances}}) {
            my $pip=$inst->{PublicIpAddress}||'';
            next unless $pip;
            next if exists $inst->{State}->{Name} &&
               $inst->{State}->{Name} eq 'terminated';
            $pubip{$pip}='';
         }
      }
      $c="aws ec2 describe-addresses";
      ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      my @available=();my @available_remove=();
      foreach my $address (@{$hash->{Addresses}}) {
         unless (exists $pubip{$address->{PublicIp}}) {
            push @available, $address->{PublicIp};
            push @available_remove,"Release IP Address $address->{PublicIp}"; 
         }
      }
      if (-1<$#available) {
         my $use_elastic_banner=<<'END';
    _   _           ___ _         _   _      ___ ___ ___ 
   | | | |___ ___  | __| |__ _ __| |_(_)__  |_ _| _ \__ \ 
   | |_| (_-</ -_) | _|| / _` (_-<  _| / _|  | ||  _/ /_/
    \___//__/\___| |___|_\__,_/__/\__|_\__| |___|_|  (_)
END
         $use_elastic_banner.=<<END;

   An allocated but not associated Elastic IP has been identified.
   Using this IP Address for CLIPBUCKET may avoid charges from
   Amazon that are levied against allocated but not associated
   Elastic IPs. Please make a selection.

END
         my $permanent_ip={

            Name => 'permanent_ip',
            Item_1 => {

               Text => 'Stay with Temporary Public IP Address',
               Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

            },
            Item_2 => {

               Text => "]C[ (to avoid cost)",
               Convey => \@available_remove,
               Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

            },
            Item_3 => {

               Text => "Use Elastic (Permanent) IP Address ]C[",
               Convey => \@available,
               Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

            },
            Scroll => 1,
            Banner => $use_elastic_banner,

         };
         return $permanent_ip;
      } else {
         my $new_elastic_banner=<<'END';
    _  _              ___ _         _   _      ___ ___ ___
   | \| |_____ __ __ | __| |__ _ __| |_(_)__  |_ _| _ \__ \
   | .` / -_) V  V / | _|| / _` (_-<  _| / _|  | ||  _/ /_/
   |_|\_\___|\_/\_/  |___|_\__,_/__/\__|_\__| |___|_|  (_)
END
         $new_elastic_banner.=<<END;

   Allocated Elastic IP Addresses have been identified, but
   all are currently associated with server instances. A new
   one can be allocated and associated with your new CLIPBUCKET
   server, but an additional cost of \$0.005 (half cent)
   per hour will be incurred. Please make a selection.

END
         my $permanent_ip={

            Name => 'permanent_ip',
            Item_1 => {

               Text => 'Stay with Temporary Public IP Address',
               Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

            },
            Item_2 => {

               Text => 'Allocate Additional Elastic (Permanent) IP Address',
               Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,

            },
            Scroll => 1,
            Banner => $new_elastic_banner,

         };
         return $permanent_ip;
      }
   }

};

our $clipbucket_lift_restrictions=sub {

   my $inform_banner=<<'END';

    _    _  __ _     ___        _       _    _   _
   | |  (_)/ _| |_  | _ \___ __| |_ _ _(_)__| |_(_)___ _ _  ___
   | |__| |  _|  _| |   / -_|_-<  _| '_| / _|  _| / _ \ ' \(_-<
   |____|_|_|  \__| |_|_\___/__/\__|_| |_\__|\__|_\___/_||_/__/

END
   $inform_banner.=<<END;
   New Amazon email users are confined to the Amazon SES (Simple Email
   Service) "sandbox". Within the sandbox there is a limit of 200 emails
   every 24 hours. More importantly, *ALL* recipients have to be "Amazon
   verified" - which is burdensome. To lift these restrictions, you have
   to apply for a "limit increase". A limit increase will also remove the
   requirement that recipients be Amazon verified. Note - there is *NO*
   guarantee that Amazon will lift email restrictions for any particular
   user. Use the link below to apply for a limit increase.

   NOTE: If using the FullAuto Windows App, you will have to expand this box
         to fullscreen and hit enter, and then re-enter this screen in order
         to see the entire URL listed below. Link is clickable if underlined.

   http://docs.aws.amazon.com/ses/latest/DeveloperGuide/request-production-access.html
END
   my $lift_restrictions={

      Name => 'lift_restrictions',
      Result => sub { return '{clipbucket_ses_sandbox}<' },
      Banner => $inform_banner,
   };
   return $lift_restrictions;   

};

our $clipbucket_use_limited=sub {

   my $inform_banner=<<'END';

    _   _           _    _       _ _          _   ___            _ _
   | | | |___ ___  | |  (_)_ __ (_) |_ ___ __| | | __|_ __  __ _(_) |
   | |_| (_-</ -_) | |__| | '  \| |  _/ -_) _` | | _|| '  \/ _` | | |
    \___//__/\___| |____|_|_|_|_|_|\__\___\__,_| |___|_|_|_\__,_|_|_|

END
   $inform_banner.=<<END;
   Since there is no guarantee that Amazon will lift email restrictions for
   any particular user, it is helpful to know how to make the most of the
   access there actually is. Users who have not requested, or been granted a
   limit increase, must verify thier recipients with Amazon. Once verified,
   CLIPBUCKET features like notifications will work for that recipient. To
   verify a recipient, use the form in the link below to enter the recipient's
   email address. Amazon will automatically send a verification email that
   they must respond to. You are highly encouraged to communicate with your
   recipient through some other medium (other email, text message, Facebook,
   Twitter, etc.) Be aware that recipients of these verification emails have
   a link to inform Amazon if the email was "unwanted". Once they are verified,
   you can successfully send an invite to them from your CLIPBUCKET server.

http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html
END
   my $use_limited_email={

      Name => 'use_limited_email',
      Result => sub { return '{clipbucket_ses_sandbox}<' },
      Banner => $inform_banner,
   };
   return $use_limited_email;


};

our $clipbucket_ses_sandbox=sub {

   package clipbucket_ses_sandbox;
   my $inform_banner=<<'END';

    ___                     _            _     _____        _ 
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_  |_   _|_ _ __| |__ __
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _|   | |/ _` (_-< / /(_-<
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__|   |_|\__,_/__/_\_\/__/ 
     __      |_|    _                            ___            _ _
    / _|___ _ _    /_\  _ __  __ _ ______ _ _   | __|_ __  __ _(_) |
   |  _/ _ \ '_|  / _ \| '  \/ _` |_ / _ \ ' \  | _|| '  \/ _` | | |
   |_| \___/_|   /_/ \_\_|_|_\__,_/__\___/_||_| |___|_|_|_\__,_|_|_|

END
   $inform_banner.=<<END;
   In order to use email invites and notifications from your CLIPBUCKET
   server, there is an important and necessary task you will have to do
   outside of this FullAuto installation. New Amazon users are allowed very
   limited and precise access to email functionality. Given the ever present
   problem of "spam", and other forms of email abuse, this policy is quite
   reasonable. Unfortunately, email dependent features of CLIPBUCKET are
   limited until these restrictions are lifted. Please make a selection:

END

   my $clipbucket_ses_sandbox={

      Name => 'clipbucket_ses_sandbox',
      Item_1 => {
      
         Text => 'Continue Installation of CLIPBUCKET.',
         Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_choose_strong_password,
      },
      Item_2 => {

         Text => 'Learn how to use limited email with Amazon restrictions.',
         Result =>
      $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_use_limited,

      },
      Item_3 => {

         Text => 'Learn how to apply for removal of Amazon email restrictions.',
         Result =>
      $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_lift_restrictions,

      },
      Scroll => 1,
      Banner => $inform_banner,

   };
   return $clipbucket_ses_sandbox;


};

our $clipbucket_validate_email=sub {

   package clipbucket_validate_email;
   my $email="]I[{'clipbucket_enter_email_address',1}";
   my $confirm="]I[{'clipbucket_enter_email_address',2}";
   unless ($email eq $confirm) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Addresses do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($email=~/^\s*$/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: You failed to enter an Email Address!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($email!~/\@/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Address must contain \'\@\' character!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   my $c="aws ses verify-email-identity --email-address $email";
   my ($hash,$output,$error)=&Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   my $inform_banner=<<'END';

    ___                     _            _   _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_| |
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _|_|
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__(_)
             |_|

END
   $inform_banner.=<<END;
   The email address you just entered: $email

   has been submitted to Amazon Web Services for verification. Amazon
   will be sending an email to this address that you must respond to
   in order for this address to work with your CLIPBUCKET installation.
   You can take a few minutes to do this now, or after you complete this
   installation. Just note, that email in your CLIPBUCKET server will
   not work until you have responded to Amazon's email.

END
   my $email_message={

      Name => 'email_message',
      Result =>
   #$Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_choose_strong_password,
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_ses_sandbox,
      Banner => $inform_banner,

   };
   return $email_message;

};

our $clipbucket_choose_strong_password=sub {

   package choose_strong_password;
   my $clipbucket_password_banner=<<'END';

    ___ _                       ___                              _
   / __| |_ _ _ ___ _ _  __ _  | _ \__ _ _______ __ _____ _ _ __| |
   \__ \  _| '_/ _ \ ' \/ _` | |  _/ _` (_-<_-< V  V / _ \ '_/ _` |
   |___/\__|_| \___/_||_\__, | |_| \__,_/__/__/\_/\_/\___/_| \__,_|
                        |___/
END
   use Crypt::GeneratePassword qw(word);
   my $word='';
   foreach my $count (1..50) {
      print "\n   Generating Password ...\n";
      $word=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         my $word=word(10,15,3,5,6);
         print "\n   Trying Password - $word ...\n";
         die if -1<index $word,'*';
         die if -1<index $word,'$';
         die if -1<index $word,'+';
         die if -1<index $word,'/';
         die if -1<index $word,'&';
         die if -1<index $word,'%';
         die if -1<index $word,'!';
         return $word;
      };
      alarm 0;
      $word||='';
      last if $word;
   }
   $clipbucket_password_banner.=<<END;
   Database (MariaDB), Web Server (NGINX) and SSL Certificate and "admin"
   CLIPBUCKET account all need a strong password. Use the one supplied here,
   or create your own. To create your own, use the [DEL] key to clear the
   highlighted input box first.

   *** BE SURE TO WRITE IT DOWN AND KEEP IT SOMEWHERE SAFE! ***

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.

   Password
                    ]I[{1,\'$word\',50}

   Confirm
                    ]I[{2,\'$word\',50}


END
   my $clipbucket_enter_password={

      Name => 'clipbucket_enter_password',
      Input => 1,
      Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::check_elastic_ip,
      #Result => $clipbucket_setup_summary,
      Banner => $clipbucket_password_banner,

   };
   return $clipbucket_enter_password;

};

our $clipbucket_enter_email_address=sub {

   my $clipbucket_email_banner=<<'END';

    ___     _             ___            _ _     _      _    _
   | __|_ _| |_ ___ _ _  | __|_ __  __ _(_) |   /_\  __| |__| |_ _ ___ ______
   | _|| ' \  _/ -_) '_| | _|| '  \/ _` | | |  / _ \/ _` / _` | '_/ -_|_-<_-<
   |___|_||_\__\___|_|   |___|_|_|_\__,_|_|_| /_/ \_\__,_\__,_|_| \___/__/__/

END
   $clipbucket_email_banner.=<<END;

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.
   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the main contact email for CLIPBUCKET here:


   Email Address
                    ]I[{1,'',50}

   Confirm Address
                    ]I[{2,'',50}


END

   my $clipbucket_enter_email_address={

      Name => 'clipbucket_enter_email_address',
      Input => 1,
      Result => $clipbucket_validate_email,
      #Result => $clipbucket_setup_summary,
      Banner => $clipbucket_email_banner,

   };
   return $clipbucket_enter_email_address;

};

our $clipbucket_pick_email_address=sub {

   package clipbucket_pick_email_address;
   use Net::FullAuto::Cloud::fa_amazon;
   my $c="aws ses list-identities";
   my ($hash,$output,$error)=run_aws_cmd($c);
   my @identities=grep { /\@/ } @{$hash->{Identities}};
   if (-1<$#identities) {

      my $pick_banner=<<'END';

    ___ _    _     ___            _ _     _      _    _
   | _ (_)__| |__ | __|_ __  __ _(_) |   /_\  __| |__| |_ _ ___ ______
   |  _/ / _| / / | _|| '  \/ _` | | |  / _ \/ _` / _` | '_/ -_|_-<_-<
   |_| |_\__|_\_\ |___|_|_|_\__,_|_|_| /_/ \_\__,_\__,_|_| \___/__/__/
END
      $pick_banner.=<<'END';

   In order for email functionality to work with CLIPBUCKET, you need to
   associate an Amazon Web Services verified email address. The following
   email addresses have been identified as verifed Amazon addresses. Please
   select one, or choose to create a new one. Note that if you choose to
   create a new one, it will have to be verified before email functionality
   in CLIPBUCKET will work properly. This setup wizard will notify Amazon,
   and Amazon will send an email to the entered address. You must respond to
   that email in order to complete verification. You can also verify
   addresses manually at this Amazon URL:

http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html

END
      my $pick_email={
      
         Name => 'pick_email',
         Item_1 => {

            Text => "Enter and verify a different address\n\n",
            Result =>
 $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_enter_email_address->(),

         },
         Item_2 => {

            Text => "]C[",
            Convey => \@identities,
            Result =>
         $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_ses_sandbox,

         },
         Scroll => 2,
         Banner => $pick_banner,
      };
      return $pick_email;
   } else {
 $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_enter_email_address->();
   }

};

our $clipbucket_choose_build=sub {

   package clipbucket_choose_build;
   use JSON::XS;
   my $c='wget -qO- https://api.github.com/users/arslancb/repos';
   my $local=Net::FullAuto::FA_Core::connect_shell();
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$local->cmd($c);
   my @repos=();
   @repos=decode_json($stdout);
   my $default_branch=$repos[0]->[1]->{'default_branch'};
   my $updated=$repos[0]->[1]->{'updated_at'};
   my @branches=();
   # git ls-remote --tags git://github.com/arslancb/clipbucket
   $c='wget -qO- https://api.github.com/repos/arslancb/clipbucket/branches';
   ($stdout,$stderr)=$local->cmd($c);
   @branches=decode_json($stdout);
   my @builds=();
   $updated=~s/^(.*)T.*$/$1/;
   my $scrollnum=0;my $count=0;
   foreach my $branch (@{$branches[0]}) {
      $count++;
      print "BRANCH NAME=",$branch->{name},"\n";
      push @builds,$branch->{name};
      if ($default_branch eq $branch->{name}) {
         $scrollnum=$count;
      }
   }
   my $clipbucket_build_banner=<<'END';
     ___ _                       ___      _ _    _  __   __          _
    / __| |_  ___  ___ ___ ___  | _ )_  _(_) |__| | \ \ / /__ _ _ __(_)___ _ _
   | (__| ' \/ _ \/ _ (_-</ -_) | _ \ || | | / _` |  \ V / -_) '_(_-< / _ \ ' \
    \___|_||_\___/\___/__/\___| |___/\_,_|_|_\__,_|   \_/\___|_| /__/_\___/_||_|

END
   $clipbucket_build_banner.=<<END;
   There are different versions of CLIPBUCKET available. If you are *NOT* a
   developer, it is highly recommended that you choose the \"$default_branch\"
   branch. It is set as the default (with the arrow >).

   For more information:  https://github.com/arslanh/clipbucket/branches

   The CLIPBUCKET project was last updated:  $updated

END
   my %choose_build=(

      Name => 'choose_build',
      Item_1 => {

         Text => ']C[',
         Convey => \@builds,
         Result =>
      $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_license_agreement_one,

      },
      Scroll => $scrollnum,
      Banner => $clipbucket_build_banner,
   );
   return \%choose_build

};

our $clipbucket_choose_site_profile=sub {

   package clipbucket_choose_site_profile;
   my $site_name="]I[{'clipbucket_enter_site_name',1}";
   unless ($site_name) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Site Name cannot be blank!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }

   my $clipbucket_profile_banner=<<'END';

     ___ _                       ___ _ _         ___          __ _ _
    / __| |_  ___  ___ ___ ___  / __(_) |_ ___  | _ \_ _ ___ / _(_) |___
   | (__| ' \/ _ \/ _ (_-</ -_) \__ \ |  _/ -_) |  _/ '_/ _ \  _| | / -_)
    \___|_||_\___/\___/__/\___| |___/_|\__\___| |_| |_| \___/_| |_|_\___|

   Please choose the kind of CLIPBUCKET site you'd like to set up.

END
   my %choose_site_profile=(

      Name => 'choose_site_profile',
      Item_1 => {

         Text => ']C[',
         Convey => [
                      'Community',
                      'Public (open registration)',
                      'Single User',
                      'Private (no federation)'
                   ],
         #Result => $clipbucket_setup_summary
         Result =>
      $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_choose_build,

      },
      Scroll => 2,
      Banner => $clipbucket_profile_banner,
   );
   return \%choose_site_profile

};

our $clipbucket_enter_site_name=sub {

   package clipbucket_enter_site_name;
   my $permanent_ip="]T[{permanent_ip}";
   my $remember="]I[{'clipbucket_enter_site_name',1}";
   $remember='' if -1<index $remember,'clipbucket_enter_site_name';
   if ($permanent_ip=~/^["]Release.* (\d+\.\d+\.\d+\.\d+).*$/s) {
      my $ip_to_release=$1;
      my $c="aws ec2 describe-addresses";
      my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};$hash->{Addresses}||=[];
      foreach my $address (@{$hash->{Addresses}}) {
         if ($address->{PublicIp} eq $ip_to_release) {
            my $c="aws ec2 release-address ".
                  "--allocation-id $address->{AllocationId}";
            my ($hash,$output,$error)=
               &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
            last;
         }
      }
      print "\n   $ip_to_release HAS BEEN RELEASED . . .\n";
      sleep 5;
      return $Net::FullAuto::ISets::Amazon::ClipBucket_is::check_elastic_ip->();
   } elsif ($permanent_ip=~/(\d+\.\d+\.\d+\.\d+)/s) {
      $main::aws->{permanent_ip}=$1;
   } elsif ($permanent_ip=~/Allocate|Elastic \(Permanent\)/) { 
      my $c="aws ec2 allocate-address --domain vpc";
      my ($hash,$output,$error)=
            &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};
      $main::aws->{permanent_ip}=$hash->{PublicIp};
   }
   my $clipbucket_site_banner=<<'END';

    ___     _             ___ _ _         _  _
   | __|_ _| |_ ___ _ _  / __(_) |_ ___  | \| |__ _ _ __  ___
   | _|| ' \  _/ -_) '_| \__ \ |  _/ -_) | .` / _` | '  \/ -_)
   |___|_||_\__\___|_|   |___/_|\__\___| |_|\_\__,_|_|_|_\___|

   The Site Name will appear within CLIPBUCKET as the name of your
   CLIPBUCKET site. It may or may not be the same as a Domain Name
   that you might setup or associate with your site. Setting up a
   Domain Name for your site is outside the scope of this installer.
END
   $clipbucket_site_banner.=<<END;

   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the Site Name for CLIPBUCKET here:


   Site Name
                    ]I[{1,\'$remember\',50}

END

   my $clipbucket_enter_site_name={

      Name => 'clipbucket_enter_site_name',
      Input => 1,
      Result =>
         $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_setup_summary,
      Banner => $clipbucket_site_banner,

   };
   return $clipbucket_enter_site_name;

};

our $clipbucket_validate_domain=sub {

   package clipbucket_validate_domain;
   my $domain="]I[{'clipbucket_enter_domain_name',1}";
print "DOMAIN=$domain\n";<STDIN>;
   my $c="aws ec2 allocate-address --domain vpc";
   my ($hash,$output,$error)=
         &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   $hash||={};
   $main::aws->{permanent_ip}=$hash->{PublicIp};

   my $confirm='';
   unless ($domain eq $confirm) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Addresses do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($domain=~/^\s*$/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: You failed to enter an Email Address!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   } elsif ($domain!~/\@/) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Email Address must contain \'\@\' character!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   $c="aws ses verify-email-identity --email-address $domain";
   ($hash,$output,$error)=&Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
   my $inform_banner=<<'END';

    ___                     _            _   _
   |_ _|_ __  _ __  ___ _ _| |_ __ _ _ _| |_| |
    | || '  \| '_ \/ _ \ '_|  _/ _` | ' \  _|_|
   |___|_|_|_| .__/\___/_|  \__\__,_|_||_\__(_)
             |_|

END
   $inform_banner.=<<END;
   The domain name you just entered: $domain

   has been submitted to Amazon Web Services for verification. Amazon
   will be sending an email to this address that you must respond to
   in order for this address to work with your CLIPBUCKET installation.
   You can take a few minutes to do this now, or after you complete this
   installation. Just note, that email in your CLIPBUCKET server will
   not work until you have responded to Amazon's email.

END
   my $email_message={

      Name => 'email_message',
      Result => $clipbucket_setup_summary,
      Banner => $inform_banner,

   };
   return $email_message;

};

our $clipbucket_enter_domain_name=sub {

   my $clipbucket_domain_banner=<<'END';

    ___     _             ___                 _        _  _
   | __|_ _| |_ ___ _ _  |   \ ___ _ __  __ _(_)_ _   | \| |__ _ _ __  ___
   | _|| ' \  _/ -_) '_| | |) / _ \ '  \/ _` | | ' \  | .` / _` | '  \/ -_)
   |___|_||_\__\___|_|   |___/\___/_|_|_\__,_|_|_||_| |_|\_\__,_|_|_|_\___|

   The Domain Name is the friendly address of your site - like fullauto.com
   This setup will test the validity of your domain name, and coach you
   through the steps you need to take to activate it successfully.

END
   $clipbucket_domain_banner.=<<END;

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.
   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the Domain Name for CLIPBUCKET here:


   Domain Name
                    ]I[{1,'',50}

END

   my $clipbucket_enter_domain_name={

      Name => 'clipbucket_enter_domain_name',
      Input => 1,
      Result => $clipbucket_validate_domain,
      #Result => $clipbucket_setup_summary,
      Banner => $clipbucket_domain_banner,

   };
   return $clipbucket_enter_domain_name;

};

our $clipbucket_caution=sub {

   my $inform_banner=<<'END';

     ___   _  _   _ _____ ___ ___  _  _ _
    / __| /_\| | | |_   _|_ _/ _ \| \| | |
   | (__ / _ \ |_| | | |  | | (_) | .` |_|
    \___/_/ \_\___/  |_| |___\___/|_|\_(_)

END
   $inform_banner.=<<END;
   This setup is intended to be a demonstration both of FullAuto‘s automation
   capabilities, as well as CLIPBUCKET’s video streaming capabilities. For
   this purpose, Amazon was chosen because of the fast ZERO to full CLIPBUCKET
   setup in one sitting. With other Cloud and host environments, there can be
   significant delays, and it is not as easy to setup an account, have it
   fully accessible, run the automation to completion, play with CLIPBUCKET
   and destroy it all easily after the evaluation is complete with minimal
   if any charges. With Amazon you can do this very easily. You even get an
   entire Gigabyte of free outbound bandwidth. Beyond uploading and evaluating
   one or two modest videos on CLIPBUCKET, you would **NOT** want to stream a
   lot of video from Amazon – the bandwidth costs are simply too prohibitive
   for anything beyond evaluation and demonstration. **PLEASE DONATE**
   http://FullAuto.com/donate.html and help us to build a full featured
   self-service dashboard that will work just as easily for other more
   affordable hosting environments.
END
   my $clipbucket_caution={

      Name => 'clipbucket_caution',
      Result => 
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_license_agreement_one,
      Banner => $inform_banner,
   };
   return $clipbucket_caution;


};

our $clipbucket_license_agreement_three=sub {

   package clipbucket_license_agreement_three;
   my $clipbucket_license_banner_three=<<'END';

   THIS FREE SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND
   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
   FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
   EVENT SHALL THE AUTHOR OR ANY CONTRIBUTOR BE LIABLE FOR
   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   EFFECTS OF UNAUTHORIZED OR MALICIOUS NETWORK ACCESS;
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
   AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
   LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
   ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

END
   my %clipbucket_license_three=(

      Name => 'clipbucket_license_three',
      Item_1 => {

         Text => "I accept the CLIPBUCKET License Agreement",
         Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_pick_email_address,

      },
      Item_2 => {

         Text => "I DO NOT accept the CLIPBUCKET License Agreement\n".
                 '              - The installation will be cancelled',
         Result => sub { return '{choose_is_setup}<' },

      },
      Scroll => 2,
      Banner => $clipbucket_license_banner_three,

   );
   return \%clipbucket_license_three;

};

our $clipbucket_license_agreement_two=sub {

   package clipbucket_license_agreement_two;
   my $clipbucket_license_banner_two=<<'END';

   1. Redistributions of source code, in whole or part and with or without
   modification (the "Code"), must prominently display this GPG-signed
   text in verifiable form.
   2. Redistributions of the Code in binary form must be accompanied by
   this GPG-signed text in any documentation and, each time the resulting
   executable program or a program dependent thereon is launched, a
   prominent display (e.g., splash screen or banner text) of the Author's
   attribution information, which includes:
   (a) Name ("Arslan Hassan"),
   (b) Professional identification ("ClipBucket"), and
   (c) URL ("http://clip-bucket.com").
   3. Neither the name nor any trademark of the Author may be used to
   endorse or promote products derived from this software without specific
   prior written permission.
   4. Users are entirely responsible, to the exclusion of the Author and
   any other persons, for compliance with (1) regulations set by owners or
   administrators of employed equipment, (2) licensing terms of any other
   software, and (3) local regulations regarding use, including those
   regarding import, export, and use of encryption software.
END
   my %clipbucket_license_two=(

      Name => 'clipbucket_license_one',
      Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_license_agreement_three,
      Banner => $clipbucket_license_banner_two,

   );
   return \%clipbucket_license_two;

};

our $clipbucket_license_agreement_one=sub {

   package clipbucket_license_agreement_one;
   my $clipbucket_license_banner_one=<<'END';

    __   _ _  _     __   ____
   /  |  ||_)|_)| |/  |/|_ |  | o _ _ ._  _ _   /\  _ ._ _  _ ._ _  _ .__|_
   \__|__||  |_)|_|\__|\|_ |  |_|(_(/_| |_>(/_ /--\(_|| (/_(/_| | |(/_| ||_
                                                    _|  
   ON FEBRAURY 14, 2010, CLIPBUCKET LICENSE AGREEMENT TURNED TO OSI
   Attribution Assurance License, OFFICIALLY

   Copyright (c) 2010 by Arslan Hassan
   CLIPBUCKET * http://clip-bucket.com
   "A way to broadcast yourself - free and opensource video sharing website
    script"

   All Rights Reserved
   ATTRIBUTION ASSURANCE LICENSE (adapted from the original BSD license)
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the conditions below are met.
   These conditions require a modest attribution to <AUTHOR> (the
   "Arslan Hassan"), who hopes that its promotional value may help justify the
   thousands of dollars in otherwise billable time invested in writing
   this and other freely available, open-source software.
END
   my %clipbucket_license_one=(

      Name => 'clipbucket_license_one',
      Result =>
   $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_license_agreement_two,
      Banner => $clipbucket_license_banner_one,

   );
   return \%clipbucket_license_one;

};

our $select_clipbucket_setup=sub {

   package select_clipbucket_setup;
   my @options=('CLIPBUCKET & MySQL & NGINX on 1 Server');
   my $clipbucket_setup_banner=<<'END';

                           http://clipbucket.com/

        _____ _      _______  ____  _    _  _____ _   __ ______ _______
       / ____| |    | |  __ \|  _ \| |  | |/ ____| | / /|  ____|__   __|
      / /    | |    | | |__) | |_) | |  | | |    | |/ / | |__     | |
      | |    | |    | |  ___/|  _ <| |  | | |    |    \ |  __|    | |
      | \____| |____| | |    | |_) | |__| | |____| |\  \| |____   | |
       \_____|______|_|_|    |____/ \____/ \_____|_| \__|______|  |_|


   Choose the CLIPBUCKET setup you wish to set up. Note that more or larger
   capactiy servers means more expense. Consider a medium or large instance
   type (previous screens) if you foresee a lot of traffic on the server. You
   can navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_clipbucket_setup=(

      Name => 'select_clipbucket_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result =>
      $Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_caution,
      #$Net::FullAuto::ISets::Amazon::ClipBucket_is::clipbucket_choose_build,

      },
      Scroll => 1,
      Banner => $clipbucket_setup_banner,
   );
   return \%select_clipbucket_setup

};

1
 
