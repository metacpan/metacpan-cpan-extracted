package Net::FullAuto::ISets::Amazon::GNUSocial_is;

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
our $DISPLAY='GNU Social';
our $CONNECT='secure';
our $defaultInstanceType='t2.micro';

my $service_and_cert_password='Full@ut0O1';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_gnusocial_setup);

use File::HomeDir;
my $home_dir=File::HomeDir->my_home.'/';

use Net::FullAuto::Cloud::fa_amazon;

my $configure_gnusocial=sub {

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
   my $install_gnusocial=<<'END';

           o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
           8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
           8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
           8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
           8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
           8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
           ........................................................
           ::::::::::::::::::::::::::::::::::::::::::::::::::::::::


                           https://gnu.io/social/

                        ____ _   _ _   _     ____             _       _
        ,= ,-_-. =.    / ___| \ | | | | |   / ___|  ___   ___(_) __ _| | 
       ((_/)o o(\_))  | |  _|  \| | | | |   \___ \ / _ \ / __| |/ _` | |  
        `-'(. .)`-'   | |_| | |\  | |_| |    ___) | (_) | (__| | (_| | | 
            \_/        \____|_| \_|\___/    |____/ \___/ \___|_|\__,_|_| 


 (The Free Software Foundation is **NOT** a sponsor of the FullAuto© Project.)

END
   print $install_gnusocial;sleep 10;
   ($stdout,$stderr)=$handle->cmd(
      'sudo yum -y install php55 php55-curl php55-gd php55-gmp '.
      'php55-intl php55-json php55-opcache php55-mysqlnd '.
      'php55-mbstring php55-devel php55-fpm openssl-devel re2c',
      '__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo yum -y groupinstall 'Development tools'",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo pecl install mailparse-2.1.6",'__display__');
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
   ($stdout,$stderr)=$handle->cmd(
      "git clone -v -b $site_build https://git.gnu.io/gnu/gnu-social.git",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sudo cp -Rv gnu-social /var/www/gnusocial",'__display__');
   ($stdout,$stderr)=$handle->cwd('/var/www/gnusocial');
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
   my $sudo='sudo ';
   # https://nealpoole.com/blog/2011/04/setting-up-php-fastcgi-and-nginx
   #    -dont-trust-the-tutorials-check-your-configuration/
   # https://www.digitalocean.com/community/tutorials/
   #    understanding-and-implementing-fastcgi-proxying-in-nginx
   # http://dev.soup.io/post/1622791/I-managed-to-get-nginx-running-on
   # https://www.sitepoint.com/setting-up-php-behind-nginx-with-fastcgi/
   # http://codingsteps.com/install-php-fpm-nginx-mysql-on-ec2-with-amazon-linux-ami/
   # http://code.tutsplus.com/tutorials/revisiting-open-source-social-networking-installing-gnu-social--cms-22456
   # https://wiki.loadaverage.org/gnusocial/installation_guides/install_like_loadaverage
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
   $ad="          proxy_http_version 1.1;%NL%".
       "          proxy_set_header Connection \"\";%NL%".
       "          include fastcgi_params;%NL%".
       "          fastcgi_param SCRIPT_FILENAME ".
       '/var/www/gnusocial/$fastcgi_script_name;%NL%'.
       "          fastcgi_pass unix:/var/run/php-fpm/php5-fpm.sock;%NL%".
       "          fastcgi_index index.php;";
   $ad=<<END;
sed -i '1,/location/ {/location/a\\\
$ad
}' /usr/local/nginx/nginx.conf
END
   $handle->cmd_raw("${sudo}$ad");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i 's#^[ ]*location / {#        location ~ \\.php {#' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/ location ~/iroot /var/www/gnusocial;' ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i '/ location ~/".
       "iindex index.php index.html index.htm;%NL%' ".
       '/usr/local/nginx/nginx.conf');
   $handle->cmd_raw(
       "${sudo}sed -i 's#\\(^root /var/www/gnusocial;$\\\)#        \\1#' ".
       '/usr/local/nginx/nginx.conf');
   $handle->cmd_raw("${sudo}sed -i ".
       "'s#\\(^index index.php index.html index.htm;$\\\)#        \\1#' ".
       '/usr/local/nginx/nginx.conf');
   $ad='%NL%        location / {%NL%           try_files $uri $uri/ '.
       '@gnusocial;%NL%        }%NL%%NL%        location @gnusocial {'.
       '%NL%           rewrite ^(.*)$ /index.php?p=$1 last;%NL%'.
       '        }';
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'/#error_page/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/usr/local/nginx/nginx.conf");
   # https://www.linode.com/docs/websites/nginx/nginx-and-phpfastcgi-on-centos-5
   $ad='%NL%        location /static {'.
       "%NL%            root /var/www/gnusocial/root;".
       '%NL%        }%NL%'.
       '%NL%        ssl on;'.
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
       '    server {%NL%'.
       '       listen 80;%NL%'.
       '       #listen [::]:80;%NL%'.
       '%NL%'.
       '       server_name  localhost;%NL%'.
       '%NL%'.
       '       # FIXME: change domain name here (and also make sure '.
       'you do the same in the next %SQ%server%SQ% section)%NL%'.
       '%NL%'.
       '       # redirect all traffic to HTTPS%NL%'.
       '       # rewrite ^ https://\$server_name\$request_uri? permanent;%NL%'.
       "       rewrite ^ https://$public_ip\$request_uri? permanent;%NL%".
       '    }';
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'/#gzip/a$ad\' /usr/local/nginx/nginx.conf");
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
       '/usr/local/nginx/nginx.conf');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/^        listen       80/        listen       ".
       "\*:443 ssl default_server/\' /usr/local/nginx/nginx.conf");
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
print "\n\n\n\n\n\n\nSTDERR=$stderr\n\n\n\n\n\n\n";
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
            $handle->{_cmd_handle}->print('CREATE DATABASE gnusocial;');
            $first_pass=1;
         } elsif (!$second_pass) {
            $handle->{_cmd_handle}->print(
               'GRANT USAGE ON gnusocial.* TO gnusocial@localhost'.
               " IDENTIFIED BY \'$service_and_cert_password\';");
            $second_pass=1;
         } elsif (!$third_pass) {
            $handle->{_cmd_handle}->print(
               'GRANT ALL PRIVILEGES ON gnusocial.* TO gnusocial@localhost;');
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
   ($stdout,$stderr)=$handle->cmd("${sudo}/etc/init.d/php-fpm start");
   ($stdout,$stderr)=$handle->cwd("/var/www/gnusocial");
   ($stdout,$stderr)=$handle->cmd("${sudo}chgrp -v ec2-user .");
   ($stdout,$stderr)=$handle->cmd("${sudo}chmod -v g+w .");
   ($stdout,$stderr)=$handle->cmd("${sudo}mkdir -v avatar background file");
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod -v g+w avatar background file",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chmod -v a+w avatar background file",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}chgrp -v ec2-user avatar background file",'__display__');
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
   my $sd='/var/www/gnusocial/theme/neo-gnu';
   ($stdout,$stderr)=$handle->cmd($sudo.
      "mv -vf fullauto_clickable_image.png $sd",'__display__');
   ($stdout,$stderr)=$local->cmd($sudo.
      "rm -rvf fullauto_clickable_image.png",'__display__');
   $ad="        %SQ%fullauto%SQ% =>%NL%".
      "        array(%SQ%url%SQ% => %SQ%http://www.fullauto.com%SQ%,%NL%".
      "              %SQ%title%SQ% => %SQ%FullAuto - Automates EVERYTHING%SQ%,%NL%".
      "              %SQ%image%SQ% => %NL%".
      "\$_path.%SQ%/theme/neo-gnu/fullauto_clickable_image.png%SQ%),%NL%";
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'/cc_by_3.0_80x15/a$ad\' /var/www/gnusocial/lib/default.php");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
       '/var/www/gnusocial/lib/default.php');
   ($stdout,$stderr)=$handle->cmd(
       "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
       "/var/www/gnusocial/lib/default.php");
   $handle->cmd_raw(
       "${sudo}sed -i 's#\\(^[']fullauto['] =[>]$\\\)#        \\1#' ".
       '/var/www/gnusocial/lib/default.php');
   $ad='    function showFullAuto()%NL%'.
      '    {%NL%'.
      "        \$this->elementStart(%SQ%div%SQ%, array(%SQ%id%SQ% => %SQ%fullauto%SQ%));%NL%".
      "        \$this->element(%SQ%img%SQ%, array(%SQ%id%SQ% => %SQ%fullauto%SQ%,%NL%".
      "                                    %SQ%src%SQ% => Theme::path(%SQ%fullauto_clickable_image.png%SQ%),%NL%".
      "                                    %SQ%alt%SQ% => common_config(%SQ%fullauto%SQ%, %SQ%title%SQ%),%NL%".
      "                                    %SQ%width%SQ% => %SQ%83%SQ%,%NL%".
      "                                    %SQ%height%SQ% => %SQ%40%SQ%));%NL%".
      "        \$this->text(%SQ% %SQ%);%NL%".
      "        \$this->elementStart(%SQ%a%SQ%, array(%SQ%class%SQ% => %SQ%fullauto url%SQ%,%NL%".
      "                                        %SQ%href%SQ% => common_config(%SQ%fullauto%SQ%, %SQ%url%SQ%)));%NL%".
      "        \$link = sprintf(%SQ%<a class=\"fullauto_image\" rel=\"fullauto\" href=\"%1\$s\">%2\$s</a>%SQ%,%NL%".
      "                        htmlspecialchars(common_config(%SQ%fullauto%SQ%, %SQ%url%SQ%)),%NL%".
      "                        htmlspecialchars(common_config(%SQ%fullauto%SQ%, %SQ%title%SQ%)));%NL%".
      "        \$this->raw(\@sprintf(\$link));%NL%".
      "        \$this->elementEnd(%SQ%a%SQ%);".
      "        \$this->elementEnd(%SQ%div%SQ%);%NL%".
      "    }%NL%";
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'/function showFooter/i$ad\' /var/www/gnusocial/lib/action.php");
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i \"s/%SQ%/\'/g\" ".
      '/var/www/gnusocial/lib/action.php');
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}sed -i \'s/%NL%/\'\"`echo \\\\\\n`/g\" ".
      "/var/www/gnusocial/lib/action.php");
   $handle->cmd_raw(
      "${sudo}sed -i 's#\\(^function showFullAuto[(][)]$\\\)#    \\1#' ".
      '/var/www/gnusocial/lib/action.php');
   ($stdout,$stderr)=$handle->cmd("${sudo}sed -i ".
      "\'/-[>]showContentLic/a\$this->showFullAuto();\' /var/www/gnusocial/lib/action.php");
   $handle->cmd_raw(
      "${sudo}sed -i 's#\\(^\$this-[>]showFullAuto[(][)]$\\\)#    \\1#' ".
      '/var/www/gnusocial/lib/action.php');
   #
   # echo-ing/streaming files over ssh can be tricky. Use echo -e
   #          and replace these characters with thier HEX
   #          equivalents (use an external editor for quick
   #          search and replace - and paste back results.
   #          use copy/paste or cat file and copy/paste results.):
   #
   #          !  -   \\x21
   #          "  -   \\x22
   #          $  -   \\x24
   #
   # https://www.lisenet.com/2014/ - bash approach to conversion
   my ($hash,$output,$error)=('','','');
   my $c="aws iam list-access-keys --user-name gnusocial_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};
   foreach my $hash (@{$hash->{AccessKeyMetadata}}) {
      my $c="aws iam delete-access-key --access-key-id $hash->{AccessKeyId} ".
            "--user-name gnusocial_email";
      ($hash,$output,$error)=run_aws_cmd($c);
   }
   sleep 1;
   $c="aws iam delete-user --user-name gnusocial_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c="aws iam create-user --user-name gnusocial_email";
   ($hash,$output,$error)=run_aws_cmd($c);
   $c="aws iam create-access-key --user-name gnusocial_email";
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
   ($stdout,$stderr)=$handle->cmd("javac SesSmtpCredentialGenerator.java");
   $handle->cmd_raw(
      "export AWS_SECRET_ACCESS_KEY=$secret_access_key");
   my $smtppass='';
   ($smtppass,$stderr)=$handle->cmd("java SesSmtpCredentialGenerator");
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
      if ($policy->{PolicyName} eq 'sespolicy') {
         $c="aws iam detach-user-policy --user-name gnusocial_email ".
            "--policy-arn $policy->{Arn}";
         ($hash,$output,$error)=run_aws_cmd($c);
         $c="aws iam delete-policy --policy-arn $policy->{Arn}";
         ($hash,$output,$error)=run_aws_cmd($c);
         last;
      }
   }
   $c="aws iam create-policy --policy-name sespolicy --policy-document ".
      "file://sespolicy";
   ($hash,$output,$error)=run_aws_cmd($c);
   my $policy_arn=$hash->{Policy}->{Arn};
   $c="aws iam attach-user-policy --user-name gnusocial_email ".
      "--policy-arn $policy_arn";
   ($hash,$output,$error)=run_aws_cmd($c);
   ($stdout,$stderr)=$local->cmd("rm -rfv ./sespolicy",'__display__'); 
   use LWP::UserAgent;
   use HTTP::Request::Common;
   use IO::Socket::SSL qw();
   my $Browser = LWP::UserAgent->new(
      ssl_opts => {
         SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
         verify_hostname => 0,
      }
   );
   my $response = $Browser->post(
      "https://$public_ip/install.php",
      [
         'sitename' => $site_name,
         'fancy' => 'enable',
         'ssl' => 'always',
         'host' => 'localhost',
         'dbtype' => 'mysql',
         'database' => 'gnusocial',
         'dbusername' => 'gnusocial',
         'dbpassword' => $service_and_cert_password,
         'admin_nickname' => 'admin',
         'admin_password' => $service_and_cert_password,
         'admin_password2' => $service_and_cert_password,
         'admin_email' => $verified_email,
         'site_profile' => $site_profile,
         'submit' => 'Submit'
      ],
   );
   print $response->content;    
   my $starting_gnusocial=<<'END';



     .oPYo. ooooo    .oo  .oPYo. ooooo o o    o .oPYo.      o    o  .oPYo.
     8        8     .P 8  8   `8   8   8 8b   8 8    8      8    8  8    8
     `Yooo.   8    .P  8  8YooP'   8   8 8`b  8 8           8    8  8YooP'
         `8   8   oPooo8  8   `b   8   8 8 `b 8 8   oo      8    8  8
          8   8  .P    8  8    8   8   8 8  `b8 8    8      8    8  8
     `YooP'   8 .P     8  8    8   8   8 8   `8 `YooP8      `YooP'  8
     ....................................................................
     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
     ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::


                           https://gnu.io/social/

                        ____ _   _ _   _     ____             _       _
        ,= ,-_-. =.    / ___| \ | | | | |   / ___|  ___   ___(_) __ _| |
       ((_/)o o(\_))  | |  _|  \| | | | |   \___ \ / _ \ / __| |/ _` | |
        `-'(. .)`-'   | |_| | |\  | |_| |    ___) | (_) | (__| | (_| | |
            \_/        \____|_| \_|\___/    |____/ \___/ \___|_|\__,_|_|


 (The Free Software Foundation is **NOT** a sponsor of the FullAuto© Project.)
END
   print $starting_gnusocial;sleep 10;
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
   ($stdout,$stderr)=$handle->cmd("${sudo}git clone ".
      'https://github.com/pztrn/statusnet-questioncaptcha-plugin',
      '__display__');
   ($stdout,$stderr)=$handle->cmd("${sudo}cp -Rv ".
      'statusnet-questioncaptcha-plugin/QuestionCaptcha '.
      '/var/www/gnusocial/plugins','__display__');
   ($stdout,$stderr)=$handle->cmd("${sudo}rm -rfv ".
      'statusnet-questioncaptcha-plugin','__display__');
   #($stdout,$stderr)=$handle->cmd("${sudo}php ".
   #   '/var/www/gnusocial/plugins/QuestionCaptcha/scripts/'.
   #   'generate-codes.php -c 10 -l 10','__display__');
   #$stdout=~s/^.*(addPlugin.*)$/$1/s;
   my $config_email=<<END;
\\x24config['mail']['domain'] = \'$email_domain\';
\\x24config['mail']['notifyfrom'] = \'$verified_email\';
\\x24config['mail']['backend'] = 'sendmail';
\\x24config['mail']['params'] = array(
'host' => \'$smtp_server\',
'port' => 25,
'auth' => true,
'username' => \'$access_id\',
'password' => \'$smtppass\'
);
END
#addPlugin('EmailRegistration');
#$stdout
#END
   ($stdout,$stderr)=$handle->cmd(
      "${sudo}echo -e \"$config_email\" >> /var/www/gnusocial/config.php");
   if ($twitter_api_key && $twitter_api_key!~/gnusocial_twitter_api/) {
      $site_name=~s/[']/\\'/g;
      my $config_twitter=<<END;
addPlugin(
   'TwitterBridge',
   array(
      'consumer_key'    => \'$twitter_api_key\',
      'consumer_secret' => \'$twitter_api_sec\'
   )
);
\\x24config['integration']['source'] = \'$site_name\';
END
      ($stdout,$stderr)=$handle->cmd(
         "${sudo}echo -e \"$config_twitter\" >> /var/www/gnusocial/config.php");
   }
   ($stdout,$stderr)=$handle->cmd(
      "php /var/www/gnusocial/scripts/checkschema.php");
   print "\n   ACCESS GNU SOCIAL UI AT:\n\n",
         " https://$public_ip/index.php\n";
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
            "   to start with your new GNU Social installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_gnusocial=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $region="]T[{awsregions}";
   $region=~s/^"//;
   $region=~s/"$//;
   my $verified_email="]T[{pick_email}";
   if (-1<index $verified_email,'Enter ') {
      $verified_email="]I[{'gnusocial_enter_email_address',1}";
   }
   my $gnusocial="]T[{select_gnusocial_setup}";
   my $permanent_ip="]T[{permanent_ip}";
   my $site_name="]I[{'gnusocial_enter_site_name',1}";
   my $site_profile="]T[{choose_site_profile}";
   my $site_build="]T[{choose_build}";
   my $strong_password="]I[{'gnusocial_enter_password',1}";
   my $twitter_api_key="]I[{'gnusocial_twitter_api',1}";
   my $twitter_api_sec="]I[{'gnusocial_twitter_api',2}";
   #if (-1<index $site_name, ']T[') {
   #   $site_name="]I[{'gnusocial_enter_domain_name',1}"; 
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
      'GNUSocialSecurityGroup --description '.
      '"GNU.io/Social Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name GNUSocialSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name GNUSocialSecurityGroup --protocol '.
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name GNUSocialSecurityGroup --protocol '.
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'GNU.io/Social'}) {
      my $g=get_aws_security_id('GNUSocialSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'GNU.io/Social'}}==0) {
         launch_server('GNU.io/Social',$cnt,$gnusocial,'',$c,
         $configure_gnusocial,'',$region,$verified_email,
         $permanent_ip,$site_name,$site_profile,$site_build,
         $strong_password,$twitter_api_key,$twitter_api_sec);
      } else {
         my $num=$#{$main::aws->{'GNU.io/Social'}}-1;
         foreach my $num (0..$num) {
            launch_server('GNU.io/Social',$cnt++,$gnusocial,'',$c,
            $configure_gnusocial,'',$region,$verified_email,
            $permanent_ip,$site_name,$site_profile,$site_build,
            $strong_password,$twitter_api_key,$twitter_api_sec);
         }
      }
   }

   return '{choose_demo_setup}<';

};

my $gnusocial_setup_summary=sub {

   package gnusocial_setup_summary;
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
   my $gnusocial="]T[{select_gnusocial_setup}";
   $gnusocial=~s/^"//;
   $gnusocial=~s/"$//;
   my $permanent_ip="]T[{permanent_ip}";
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
      sleep 4;
   }
   my $num_of_servers=0;
   my $ol=$gnusocial;
   $ol=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ol==1) {
      $main::aws->{'GNU.io/Social'}->[0]=[];
   } elsif ($ol=~/^\d+$/ && $ol) {
      foreach my $n (0..$ol) {
         $main::aws->{'GNU.io/Social'}=[] unless exists
            $main::aws->{'GNU.io/Social'};
         $main::aws->{'GNU.io/Social'}->[$n]=[];
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

         $gnusocial


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_gnusocial,

      },
      Item_2 => {

         Text => "Return to Choose Instruction Set Menu",
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

our $check_elastic_ip=sub {

   my $password="]I[{'gnusocial_enter_password',1}";
   my $confirm="]I[{'gnusocial_enter_password',2}";
   if ($password ne $confirm &&
         (-1==index $password,'gnusocial_enter_password')) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Password entries do not match!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }
   my $c="aws ec2 describe-addresses";
   my ($hash,$output,$error)=run_aws_cmd($c);
   $hash||={};$hash->{Addresses}||=[];
   if (-1==$#{$hash->{Addresses}}) {
      my $permanent_ip_banner=<<'END';
    ___                                 _     ___ ___ ___
   | _ \___ _ _ _ __  __ _ _ _  ___ _ _| |_  |_ _| _ \__ \
   |  _/ -_) '_| '  \/ _` | ' \/ -_) ' \  _|  | ||  _/ /_/
   |_| \___|_| |_|_|_\__,_|_||_\___|_||_\__| |___|_|  (_)
END
      $permanent_ip_banner.=<<END;

   If you plan on using this GNU Social server for an extended
   period, you will need a non-temporary IP Address. In Amazon
   Web Services, one Elastic IP (Amazon's way of allocating long 
   term IP addresses) is free so long as it is associated to
   a running server. If you stop or terminate the server, you
   need to manually release the address, or you will incur charges.

   Note also, that a Permanent IP Address will substantially
   increase the likelihood of email being sent from the GNU Social
   server surviving spam filters and actually arriving at the
   intended destination.

END
      my $permanent_ip={

         Name => 'permanent_ip',
         Item_1 => {

            Text => 'Stay with Temporary Public IP Address',
            Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

         },
         Item_2 => {

            Text => 'Use Elastic (Permanent) IP Address',
            Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

         },
         Scroll => 1,
         Banner => $permanent_ip_banner,

      };
      return $permanent_ip;
   } else {
      my $c="aws ec2 describe-instances";
      my ($hash,$output,$error)=run_aws_cmd($c);
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
      ($hash,$output,$error)=run_aws_cmd($c);
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
   Using this IP Address for GNU Social may avoid charges from
   Amazon that are levied against allocated but not associated
   Elastic IPs. Please make a selection.

END
         my $permanent_ip={

            Name => 'permanent_ip',
            Item_1 => {

               Text => 'Stay with Temporary Public IP Address',
               Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

            },
            Item_2 => {

               Text => "]C[ (to avoid cost)",
               Convey => \@available_remove,
               Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

            },
            Item_3 => {

               Text => "Use Elastic (Permanent) IP Address ]C[",
               Convey => \@available,
               Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

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
   one can be allocated and associated with your new GNU
   Social server, but an additional cost of \$0.005 (half cent)
   per hour will be incurred. Please make a selection.

END
         my $permanent_ip={

            Name => 'permanent_ip',
            Item_1 => {

               Text => 'Stay with Temporary Public IP Address',
               Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

            },
            Item_2 => {

               Text => 'Allocate Additional Elastic (Permanent) IP Address',
               Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_site_name,

            },
            Scroll => 1,
            Banner => $new_elastic_banner,

         };
         return $permanent_ip;
      }
   }

};

our $gnusocial_lift_restrictions=sub {

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
      Result => sub { return '{gnusocial_ses_sandbox}<' },
      Banner => $inform_banner,
   };
   return $lift_restrictions;   

};

our $gnusocial_use_limited=sub {

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
   GNU Social features like notifications will work for that recipient. To
   verify a recipient, use the form in the link below to enter the recipient's
   email address. Amazon will automatically send a verification email that
   they must respond to. You are highly encouraged to communicate with your
   recipient through some other medium (other email, text message, Facebook,
   Twitter, etc.) Be aware that recipients of these verification emails have
   a link to inform Amazon if the email was "unwanted". Once they are verified,
   you can successfully send an invite to them from your GNU Social server.

http://docs.aws.amazon.com/ses/latest/DeveloperGuide/verify-email-addresses.html
END
   my $use_limited_email={

      Name => 'use_limited_email',
      Result => sub { return '{gnusocial_ses_sandbox}<' },
      Banner => $inform_banner,
   };
   return $use_limited_email;


};

our $gnusocial_ses_sandbox=sub {

   package gnusocial_ses_sandbox;
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
   In order to use email invites and notifications from your GNU Social
   server, there is an important and necessary task you will have to do
   outside of this FullAuto installation. New Amazon users are allowed very
   limited and precise access to email functionality. Given the ever present
   problem of "spam", and other forms of email abuse, this policy is quite
   reasonable. Unfortunately, email dependent features of GNU Social are
   limited until these restrictions are lifted. Please make a selection:

END

   my $gnusocial_ses_sandbox={

      Name => 'gnusocial_ses_sandbox',
      Item_1 => {
      
         Text => 'Continue Installation of GNU Social.',
         Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_choose_strong_password,
      },
      Item_2 => {

         Text => 'Learn how to use limited email with Amazon restrictions.',
         Result =>
      $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_use_limited,

      },
      Item_3 => {

         Text => 'Learn how to apply for removal of Amazon email restrictions.',
         Result =>
      $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_lift_restrictions,

      },
      Scroll => 1,
      Banner => $inform_banner,

   };
   return $gnusocial_ses_sandbox;


};

our $gnusocial_validate_email=sub {

   package gnusocial_validate_email;
   my $email="]I[{'gnusocial_enter_email_address',1}";
   my $confirm="]I[{'gnusocial_enter_email_address',2}";
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
   in order for this address to work with your GNU Social installation.
   You can take a few minutes to do this now, or after you complete this
   installation. Just note, that email in your GNU Social server will
   not work until you have responded to Amazon's email.

END
   my $email_message={

      Name => 'email_message',
      Result =>
   #$Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_choose_strong_password,
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_ses_sandbox,
      Banner => $inform_banner,

   };
   return $email_message;

};

our $gnusocial_choose_strong_password=sub {

   package choose_strong_password;
   my $gnusocial_password_banner=<<'END';

    ___ _                       ___                              _
   / __| |_ _ _ ___ _ _  __ _  | _ \__ _ _______ __ _____ _ _ __| |
   \__ \  _| '_/ _ \ ' \/ _` | |  _/ _` (_-<_-< V  V / _ \ '_/ _` |
   |___/\__|_| \___/_||_\__, | |_| \__,_/__/__/\_/\_/\___/_| \__,_|
                        |___/
END
   use Crypt::GeneratePassword qw(word);
   my $word='';
   foreach my $count (1..10) {
      print "\n   Generating Password ...\n";
      $word=eval {
         local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
         alarm 7;
         my $word=word(10,15,3,5,6);
         print "\n   Trying Password - $word ...\n";
         die if -1<index $word,'*';
         die if -1<index $word,'$';
         die if -1<index $word,'+';
         return $word;
      };
      alarm 0;
      last if $word;
   }
   $gnusocial_password_banner.=<<END;
   Database (MariaDB), Web Server (NGINX) and SSL Certificate and "admin"
   GNU Social account all need a strong password. Use the one supplied here,
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
   my $gnusocial_enter_password={

      Name => 'gnusocial_enter_password',
      Input => 1,
      Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::check_elastic_ip,
      #Result => $gnusocial_setup_summary,
      Banner => $gnusocial_password_banner,

   };
   return $gnusocial_enter_password;

};

our $gnusocial_enter_email_address=sub {

   my $gnusocial_email_banner=<<'END';

    ___     _             ___            _ _     _      _    _
   | __|_ _| |_ ___ _ _  | __|_ __  __ _(_) |   /_\  __| |__| |_ _ ___ ______
   | _|| ' \  _/ -_) '_| | _|| '  \/ _` | | |  / _ \/ _` / _` | '_/ -_|_-<_-<
   |___|_||_\__\___|_|   |___|_|_|_\__,_|_|_| /_/ \_\__,_\__,_|_| \___/__/__/

END
   $gnusocial_email_banner.=<<END;

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.
   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the main contact email for GNU Social here:


   Email Address
                    ]I[{1,'',50}

   Confirm Address
                    ]I[{2,'',50}


END

   my $gnusocial_enter_email_address={

      Name => 'gnusocial_enter_email_address',
      Input => 1,
      Result => $gnusocial_validate_email,
      #Result => $gnusocial_setup_summary,
      Banner => $gnusocial_email_banner,

   };
   return $gnusocial_enter_email_address;

};

our $gnusocial_pick_email_address=sub {

   package gnusocial_pick_email_address;
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

   In order for email functionality to work with GNU Social, you need to
   associate an Amazon Web Services verified email address. The following
   email addresses have been identified as verifed Amazon addresses. Please
   select one, or choose to create a new one. Note that if you choose to
   create a new one, it will have to be verified before email functionality
   in GNU Social will work properly. This setup wizard will notify Amazon,
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
 $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_email_address->(),

         },
         Item_2 => {

            Text => "]C[",
            Convey => \@identities,
            Result =>
         $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_ses_sandbox,

         },
         Scroll => 2,
         Banner => $pick_banner,
      };
      return $pick_email;
   } else {
 $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_email_address->();
   }

};

our $gnusocial_create_access_token=sub {

   package gnusocial_create_access_token;
   my $create_access_token_banner=<<'END';

    ___              _           _                     _____    _
   / __|_ _ ___ __ _| |_ ___    /_\  __ __ ___ ______ |_   _|__| |_____ _ _
  | (__| '_/ -_) _` |  _/ -_)  / _ \/ _/ _/ -_|_-<_-<   | |/ _ \ / / -_) ' \
   \___|_| \___\__,_|\__\___| /_/ \_\__\__\___/__/__/   |_|\___/_\_\___|_||_|

END
   $create_access_token_banner.=<<END;
                      ________________________
                     |                        |                
   Details  Settings | Keys and Access Tokens | Permissions  
  ___________________|                        |________________________________

   On the same 'Keys and Access Tokens' Tab/Page, there is a button
   at the bottom of the page named 'Create my access token'.

   Click the 'Create my access token' button at bottom of page.

    ________________________
   | Create my access token |
   |________________________|

END
   my $gnusocial_access_token={

      Name => 'gnusocial_access_token',
      Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_twitter_permissions,
      Banner => $create_access_token_banner,

   };
   return $gnusocial_access_token;

};

our $gnusocial_twitter_permissions=sub {

   my $twitter_permission_banner=<<'END';
     ___ _                         ___               _       _
    / __| |_  __ _ _ _  __ _ ___  | _ \___ _ _ _ __ (_)_____(_)___ _ _  ___
   | (__| ' \/ _` | ' \/ _` / -_) |  _/ -_) '_| '  \| (_-<_-< / _ \ ' \(_-<
    \___|_||_\__,_|_||_\__, \___| |_| \___|_| |_|_|_|_/__/__/_\___/_||_/__/
                       |___/

END
   $twitter_permission_banner.=<<END;
   Back to twitter go to Permissions tab:      _____________
                                              |             |
   Details  Settings   Keys and Access Tokens | Permissions | 
  ____________________________________________|             |______________
 
   Click and change to the following Access setting, and click
   [Update Settings] button at bottom of page.

   (O)  Read, Write and Access direct messages

    _________________
   | Update Settings |
   |_________________| 
END
   my $gnusocial_twitter_perms={

      Name => 'gnusocial_twitter_perms',
      Result => $gnusocial_setup_summary,
      Banner => $twitter_permission_banner,

   };
   return $gnusocial_twitter_perms;

};

our $gnusocial_enter_twitter_api=sub {

   package gnusocial_enter_twitter_api;
   my $twitter_api_banner=<<'END';
    ___     _             _  __             _     ___                 _
   | __|_ _| |_ ___ _ _  | |/ /___ _  _   _| |_  / __| ___ __ _ _ ___| |_
   | _|| ' \  _/ -_) '_| | ' </ -_) || | |_   _| \__ \/ -_) _| '_/ -_)  _|
   |___|_||_\__\___|_|   |_|\_\___|\_, |   |_|   |___/\___\__|_| \___|\__|
                                   |__/
END
   $twitter_api_banner.=<<END;

   On twitter page showing bold "]I[{'gnusocial_enter_site_name',1}", there
   are tabs just underneath. Go to Keys and Access Tokens tab:
                      ________________________
                     |                        |                + Use [TAB] to
   Details  Settings | Keys and Access Tokens | Permissions    + switch boxes
  ___________________|                        |________________________________

   Copy & Paste (or Type) into input boxes the needed API Key & API Secret:

   Consumer Key (API Key)  
                          ]I[{1,'',52}
   Consumer Secret
   (API Secret)
                   ]I[{2,'',59}
END
   my $gnusocial_twitter_api={

      Name => 'gnusocial_twitter_api',
      Input => 1,
      Result =>
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_create_access_token,
      Banner => $twitter_api_banner,

   };
   return $gnusocial_twitter_api;

};

our $gnusocial_enter_values=sub {

   package gnusocial_enter_values;
   my $permanent_ip="]T[{permanent_ip}";
   if ($main::aws->{permanent_ip}) {
      $permanent_ip=$main::aws->{permanent_ip};
   } elsif ($permanent_ip=~s/^.*Elastic.* (\d+\.\d+\.\d+\.\d+).*$/$1/s) {
   } else {
      STDOUT->autoflush(1);
      print "\n   ERROR: You must use an Elastic IP for twitter bridge!";
      sleep 5;
      STDOUT->autoflush(0);
      return '{permanent_ip}<';
   }
   my $enter_values_banner=<<'END';
   ___     _             _____ _                 __   __    _               _
  | __|_ _| |_ ___ _ _  |_   _| |_  ___ ___ ___  \ \ / /_ _| |_  _ ___ ___ (_)
  | _|| ' \  _/ -_) '_|   | | | ' \/ -_|_-</ -_)  \ V / _` | | || / -_|_-<  _
  |___|_||_\__\___|_|     |_| |_||_\___/__/\___|   \_/\__,_|_|\_,_\___/__/ (_)

END
   $enter_values_banner.=<<END;

   Name         -->  ]I[{'gnusocial_enter_site_name',1}

   Description  -->  ]I[{'gnusocial_enter_site_name',1} GNU Social

   WebSite      -->  https://$permanent_ip/main/all

   Callback URL -->  https://$permanent_ip/twitter/authorization

   -----------------------------------------------------------------

   * Read and check the "Twitter Developer Agreement" checkbox.

     Click on "Create your Twitter application".
END
   my $enter_values={

      Name => 'enter_values',
      Result => 
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_twitter_api,
      Banner => $enter_values_banner,

   };
   return $enter_values;

};

our $gnusocial_twitter_app=sub {

   package gnusocial_twitter_app;
   my $twitter_app_banner=<<'END';

    ___              _         _          _ _   _               _
   / __|_ _ ___ __ _| |_ ___  | |___ __ _(_) |_| |_ ___ _ _    /_\  _ __ _ __
  | (__| '_/ -_) _` |  _/ -_) |  _\ V  V / |  _|  _/ -_) '_|  / _ \| '_ \ '_ \
   \___|_| \___\__,_|\__\___|  \__|\_/\_/|_|\__|\__\___|_|   /_/ \_\ .__/ .__/
                                                                    |_|  |_|

END
   $twitter_app_banner.=<<END;
   In your favorite browser, make sure you are first logged in with the
   twitter account you intend to use for the twitter bridge. Then, navigate
   to this URL:

   https://apps.twitter.com/app/new

   You will see a page with a number of input boxes asking for very specific
   information. Press [ENTER] and the next screen of this setup will give 
   you values to cut and paste into those input boxes.
END
   my $twitter_app={

      Name => 'twitter_app',
      Result => 
         $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_enter_values,
      Banner => $twitter_app_banner,

   };
   return $twitter_app;

};

our $gnusocial_no_twitter=sub {

   my $no_twitter_banner=<<'END';
     ___              _         _  _
    / __|_ _ ___ __ _| |_ ___  | \| |_____ __ __
   | (__| '_/ -_) _` |  _/ -_) | .` / -_) V  V /
    \___|_| \___\__,_|\__\___| |_|\_\___|\_/\_/
    _          _ _   _               _                      _
   | |___ __ _(_) |_| |_ ___ _ _    /_\  __ __ ___ _  _ _ _| |_
   |  _\ V  V / |  _|  _/ -_) '_|  / _ \/ _/ _/ _ \ || | ' \  _|
    \__|\_/\_/|_|\__|\__\___|_|   /_/ \_\__\__\___/\_,_|_||_\__|

END
   $no_twitter_banner.=<<END;
   If you don't have a twitter account, or wish to create a separate account
   for use with GNU Social, you will need to create one. You can sign up for
   a twitter account at the link below. Once you have completed that task,
   you can continue setting up the twitter bridge by hitting [ENTER].

   https://twitter.com/signup?lang=en

END
   my $new_twitter_account={

      Name => 'new_twitter_account',
      Result => $gnusocial_twitter_app,
      Banner => $no_twitter_banner,

   };
   return $new_twitter_account;

};

our $gnusocial_setting_up_bridge=sub {

   package gnusocial_setting_up_bridge;
   my $setting_up_bridge_banner=<<'END';
    ___      _   _   _             _   _        ___     _    _
   / __| ___| |_| |_(_)_ _  __ _  | | | |_ __  | _ )_ _(_)__| |__ _ ___
   \__ \/ -_)  _|  _| | ' \/ _` | | |_| | '_ \ | _ \ '_| / _` / _` / -_)
   |___/\___|\__|\__|_|_||_\__, |  \___/| .__/ |___/_| |_\__,_\__, \___|
                           |___/        |_|                   |___/

END
   $setting_up_bridge_banner.=<<END;
   From a purely technical standpoint, FullAuto could completely automate the
   setup of the twitter bridge, like it has every other aspect of GNU Social.
   Unfortunately, most of the setup work needed for this option, has to take
   place on the twitter website. Using external (to twitter's site)
   automation to manipulate the twitter site, is a violation of twitter's
   license agreement that everyone agrees to when they first create a twitter
   account. This FullAuto installer however, will walk you through the process
   of setting up the twitter bridge, and will provide all the items you will
   need to do it successfully.

END
  
   my $setting_up_bridge={

      Name => 'setting_up_bridge',
      Item_1 => {
         Text => 'I have a twitter account',
         Result => 
            $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_twitter_app,
      },
      Item_2 => {
         Text => 'I do NOT have a twitter account',
         Result => 
            $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_no_twitter,
      },
      Scroll => 1,
      Banner => $setting_up_bridge_banner, 

   }; 
   return $setting_up_bridge;

};

our $gnusocial_twitter_bridge=sub {

   package gnusocial_twitter_bridge;
   my $gnusocial_twitter_banner=<<'END';
    _          _ _   _             _        _    _         ___
   | |___ __ _(_) |_| |_ ___ _ _  | |__ _ _(_)__| |__ _ __|__ \
   |  _\ V  V / |  _|  _/ -_) '_| | '_ \ '_| / _` / _` / -_)/_/
    \__|\_/\_/|_|\__|\__\___|_|   |_.__/_| |_\__,_\__, \___(_)
                                                  |___/

END
   $gnusocial_twitter_banner.=<<END;
   The twitter "bridge" plugin allows you to integrate your GNU Social
   instance with twitter.  Installing it will allow your users to:

   - automatically post notices to their twitter accounts
   - automatically subscribe to other twitter users who are also using
     your GNU Social install, if possible 
   - import their twitter friends' tweets
   - allow users to authenticate using twitter ('Sign in with twitter')

   Install twitter bridge?

END
   my $gnusocial_twitter_bridge={ 

      Name => 'gnusocial_twitter_bridge',
      Item_1 => {

         Text => 'Install twitter bridge',
         Result => 
      $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_setting_up_bridge,

      },
      Item_2 => {

         Text => 'DO NOT install twitter bridge',
         Result => $gnusocial_setup_summary,

      },
      Scroll => 2,
      Banner => $gnusocial_twitter_banner,
   };
   return $gnusocial_twitter_bridge; 

};

our $gnusocial_choose_build=sub {

   package gnusocial_choose_build;
   use JSON::XS;
   my $c='wget -qO- https://api.github.com/users/foocorp/repos';
   my $local=Net::FullAuto::FA_Core::connect_shell();
   my ($stdout,$stderr)=('','');
   ($stdout,$stderr)=$local->cmd($c);
   my @repos=();
   @repos=decode_json($stdout);
   my $default_branch=$repos[0]->[1]->{'default_branch'};
   my $updated=$repos[0]->[1]->{'updated_at'};
   my @branches=();
   $c='wget -qO- https://api.github.com/repos/foocorp/gnu-social/branches';
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
   my $gnusocial_build_banner=<<'END';
     ___ _                       ___      _ _    _  __   __          _
    / __| |_  ___  ___ ___ ___  | _ )_  _(_) |__| | \ \ / /__ _ _ __(_)___ _ _
   | (__| ' \/ _ \/ _ (_-</ -_) | _ \ || | | / _` |  \ V / -_) '_(_-< / _ \ ' \
    \___|_||_\___/\___/__/\___| |___/\_,_|_|_\__,_|   \_/\___|_| /__/_\___/_||_|

END
   $gnusocial_build_banner.=<<END;
   There are different versions of GNU Social available. If you are *NOT* a
   developer, it is highly recommended that you choose the \"$default_branch\"
   branch. It is set as the default (with the arrow >).

   For more information:  https://github.com/foocorp/gnu-social/branches

   The GNU Social project was last updated:  $updated

END
   my %choose_build=(

      Name => 'choose_build',
      Item_1 => {

         Text => ']C[',
         Convey => \@builds,
         #Result => $gnusocial_setup_summary
         Result => 
      $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_twitter_bridge,

      },
      Scroll => $scrollnum,
      Banner => $gnusocial_build_banner,
   );
   return \%choose_build

};

our $gnusocial_choose_site_profile=sub {

   package gnusocial_choose_site_profile;
   my $site_name="]I[{'gnusocial_enter_site_name',1}";
   unless ($site_name) {
      STDOUT->autoflush(1);
      print "\n   ERROR: Site Name cannot be blank!";sleep 5;
      STDOUT->autoflush(0);
      return '<';
   }

   my $gnusocial_profile_banner=<<'END';

     ___ _                       ___ _ _         ___          __ _ _
    / __| |_  ___  ___ ___ ___  / __(_) |_ ___  | _ \_ _ ___ / _(_) |___
   | (__| ' \/ _ \/ _ (_-</ -_) \__ \ |  _/ -_) |  _/ '_/ _ \  _| | / -_)
    \___|_||_\___/\___/__/\___| |___/_|\__\___| |_| |_| \___/_| |_|_\___|

   Please choose the kind of GNU Social site you'd like to set up.

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
         #Result => $gnusocial_setup_summary
         Result =>
      $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_choose_build,

      },
      Scroll => 2,
      Banner => $gnusocial_profile_banner,
   );
   return \%choose_site_profile

};

our $gnusocial_enter_site_name=sub {

   package gnusocial_enter_site_name;
   my $permanent_ip="]T[{permanent_ip}";
   my $remember="]I[{'gnusocial_enter_site_name',1}";
   $remember='' if -1<index $remember,'gnusocial_enter_site_name';
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
      return $Net::FullAuto::ISets::Amazon::GNUSocial_is::check_elastic_ip->();
   } elsif ($permanent_ip=~/(\d+\.\d+\.\d+\.\d+)/s) {
      $main::aws->{permanent_ip}=$1;
   } elsif ($permanent_ip=~/Allocate|Elastic \(Permanent\)/) { 
      my $c="aws ec2 allocate-address --domain vpc";
      my ($hash,$output,$error)=
            &Net::FullAuto::Cloud::fa_amazon::run_aws_cmd($c);
      $hash||={};
      $main::aws->{permanent_ip}=$hash->{PublicIp};
   }
   my $gnusocial_site_banner=<<'END';

    ___     _             ___ _ _         _  _
   | __|_ _| |_ ___ _ _  / __(_) |_ ___  | \| |__ _ _ __  ___
   | _|| ' \  _/ -_) '_| \__ \ |  _/ -_) | .` / _` | '  \/ -_)
   |___|_||_\__\___|_|   |___/_|\__\___| |_|\_\__,_|_|_|_\___|

   The Site Name will appear within GNU Social as the name of your
   GNU Social site. It may or may not be the same as a Domain Name
   that you might setup or associate with your site. Setting up a
   Domain Name for your site is outside the scope of this installer.
END
   $gnusocial_site_banner.=<<END;

   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the Site Name for GNU Social here:


   Site Name
                    ]I[{1,\'$remember\',50}

END

   my $gnusocial_enter_site_name={

      Name => 'gnusocial_enter_site_name',
      Input => 1,
      #Result => $gnusocial_validate_domain,
      Result => 
   $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_choose_site_profile,
      Banner => $gnusocial_site_banner,

   };
   return $gnusocial_enter_site_name;

};

our $gnusocial_validate_domain=sub {

   package gnusocial_validate_domain;
   my $domain="]I[{'gnusocial_enter_domain_name',1}";
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
   in order for this address to work with your GNU Social installation.
   You can take a few minutes to do this now, or after you complete this
   installation. Just note, that email in your GNU Social server will
   not work until you have responded to Amazon's email.

END
   my $email_message={

      Name => 'email_message',
      Result => $gnusocial_setup_summary,
      Banner => $inform_banner,

   };
   return $email_message;

};

our $gnusocial_enter_domain_name=sub {

   my $gnusocial_domain_banner=<<'END';

    ___     _             ___                 _        _  _
   | __|_ _| |_ ___ _ _  |   \ ___ _ __  __ _(_)_ _   | \| |__ _ _ __  ___
   | _|| ' \  _/ -_) '_| | |) / _ \ '  \/ _` | | ' \  | .` / _` | '  \/ -_)
   |___|_||_\__\___|_|   |___/\___/_|_|_\__,_|_|_||_| |_|\_\__,_|_|_|_\___|

   The Domain Name is the friendly address of your site - like fullauto.com
   This setup will test the validity of your domain name, and coach you
   through the steps you need to take to activate it successfully.

END
   $gnusocial_domain_banner.=<<END;

   Input box with === border is highlighted (active) input box.
   Use [TAB] key to switch focus between input boxes.
   Use [DEL] key to clear entire entry in highlighted input box.
   Use [Backspace] to backspace in highlighted input box.

   Type or Copy & Paste the Domain Name for GNU Social here:


   Domain Name
                    ]I[{1,'',50}

END

   my $gnusocial_enter_domain_name={

      Name => 'gnusocial_enter_domain_name',
      Input => 1,
      Result => $gnusocial_validate_domain,
      #Result => $gnusocial_setup_summary,
      Banner => $gnusocial_domain_banner,

   };
   return $gnusocial_enter_domain_name;

};

our $select_gnusocial_setup=sub {

   package select_gnusocial_setup;
   my @options=('GNU Social & MySQL & NGINX on 1 Server');
   my $gnusocial_setup_banner=<<'END';

                           https://gnu.io/social/

                        ____ _   _ _   _     ____             _       _
        ,= ,-_-. =.    / ___| \ | | | | |   / ___|  ___   ___(_) __ _| |
       ((_/)o o(\_))  | |  _|  \| | | | |   \___ \ / _ \ / __| |/ _` | |
        `-'(. .)`-'   | |_| | |\  | |_| |    ___) | (_) | (__| | (_| | |
            \_/        \____|_| \_|\___/    |____/ \___/ \___|_|\__,_|_|


   Choose the GNU Social setup you wish to set up. Note that more or larger
   capactiy servers means more expense. Consider a medium or large instance
   type (previous screens) if you foresee a lot of traffic on the server. You
   can navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_gnusocial_setup=(

      Name => 'select_gnusocial_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => 
      $Net::FullAuto::ISets::Amazon::GNUSocial_is::gnusocial_pick_email_address,
         #Result => $gnusocial_enter_domain_name,

      },
      Scroll => 1,
      Banner => $gnusocial_setup_banner,
   );
   return \%select_gnusocial_setup

};

1
 
