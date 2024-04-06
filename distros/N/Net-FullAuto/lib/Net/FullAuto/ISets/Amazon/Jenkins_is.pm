package Net::FullAuto::ISets::Amazon::Jenkins_is;

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
our $DISPLAY='Jenkins';
our $CONNECT='ssh';
our $defaultInstanceType='t2.micro';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_jenkins_setup);

use Net::FullAuto::Cloud::fa_amazon;

my $configure_jenkins=sub {

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
   ($stdout,$stderr)=$handle->cmd("sudo yum -y -v install java-1.8.0",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("sudo yum -y -v remove java-1.7.0-openjdk",
      '__display__');
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'yum -y -v install tomcat8 tomcat8-webapps tomcat8-admin-webapps '.
      'tomcat8-docs-webapp tomcat8-javadoc',
      '__display__');
   my $source='http://mirrors.jenkins.io/war-stable/latest/jenkins.war';
   ($stdout,$stderr)=$handle->cmd(
       "wget --random-wait --progress=dot $source",'__display__');
   my $install_jenkins=<<'END';




          o o    o .oPYo. ooooo    .oo o     o     o o    o .oPYo.
          8 8b   8 8        8     .P 8 8     8     8 8b   8 8    8
          8 8`b  8 `Yooo.   8    .P  8 8     8     8 8`b  8 8
          8 8 `b 8     `8   8   oPooo8 8     8     8 8 `b 8 8   oo
          8 8  `b8      8   8  .P    8 8     8     8 8  `b8 8    8
          8 8   `8 `YooP'   8 .P     8 8oooo 8oooo 8 8   `8 `YooP8
          ........................................................
          ::::::::::::::::::::::::::::::::::::::::::::::::::::::::

                          http://www.jenkins.io    

                       _            _    _
                      | | ___ _ __ | | _(_)_ __  ___
                   _  | |/ _ \ '_ \| |/ / | '_ \/ __|
                  | |_| |  __/ | | |   <| | | | \__ \
                   \___/ \___|_| |_|_|\_\_|_| |_|___/


         (Jenkins® is **NOT** a sponsor of the FullAuto© Project.)

END
   print $install_jenkins;sleep 10;
   ($stdout,$stderr)=$handle->cmd("sudo yum -y update",'__display__');
   my $master=$main::aws->{$server_type}->[$cnt]->[0]->{InstanceId};
   my $c="aws ec2 describe-instances --instance-ids $master 2>&1";
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   my $mdns=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicDnsName};
   my $pbip=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicIpAddress};
   my $dcnt=0;
   my $extn='';
   ($stdout,$stderr)=$handle->cmd('sudo '.
      'mv ~/jenkins.war /var/lib/tomcat8/webapps');
   ($stdout,$stderr)=$handle->cwd('/usr/share/tomcat8');
   ($stdout,$stderr)=$handle->cmd('sudo mkdir .jenkins');
   ($stdout,$stderr)=$handle->cmd('sudo chown -Rv tomcat:tomcat .jenkins',
      '__display__');
   ($stdout,$stderr)=$handle->cmd('sudo chown -Rv tomcat:tomcat *',
      '__display__');
   ($stdout,$stderr)=$handle->cmd('sudo service tomcat8 start','__display__');
   $handle->{_cmd_handle}->print('sudo '.
      'tail -f /usr/share/tomcat8/logs/catalina.out');
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   my $adminpass='';my $allout='';
   while (1) {
      my $output=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      $allout.=$output;
      if ($allout=~
            /^.*password to proceed to installation:\s+(.*?)\s+This.*$/s) {
         $adminpass=$1;
      }
      if ($allout=~/Finished/s) {
         sleep 5;
         $handle->{_cmd_handle}->print("\003");
         last;
      }
   }
   $handle->clean_filehandle();
   ($stdout,$stderr)=$handle->cmd('hostname');
   my $cmd='wget -d -qO- '.
      '-e robots=off '.
      '--cookies=on --keep-session-cookies '.
      '--save-cookies cookies.txt '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="DNT: 1" http://'.$pbip.':8080/jenkins';
print "BEGIN_CMD=$cmd\n";
   ($stdout,$stderr)=$handle->cmd($cmd);
print "BEGIN_STDOUT=$stdout<== and BEGIN_STDERR=$stderr<==\n\n\n\n\n";
   my $session=$stdout;
   $stdout=~s/^.*(JSESSIONID=.*?);.*/$1/s;
   my $cookies=$stdout;
   $session=~s/^.*X-Jenkins-Session: (.*?)\n.*$/$1/s;
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="Accept: text/html,application/xhtml+xml,application/xml;'.
      'q=0.9,*/*;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 '.
      '(Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0" '.
      '--header="DNT: 1" '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      'http://'.$pbip.':8080/jenkins/login?from=%2Fjenkins%2F';
print "SESSION=$session\n";
print "LOGIN_CMD=$cmd\n";
   ($stdout,$stderr)=$handle->cmd($cmd);
print "LOGIN_STDOUT=$stdout<========= and LOGIN_STDERR=$stderr<=========\n\n\n\n\n";
   $cookies=$stderr;
   $cookies=~s/^.*(JSESSIONID=.*?);.*$/$1/s;
print "COOKIE=$cookies<==\n";
   $stdout=~s/^.*Jenkins-Crumb", "(.*?)"[)].*$/$1/s;
   my $jenkins_crumb=$stdout;
print "CRUMB=$jenkins_crumb<==\n";
   my @files=(

      '/css/style.css',
      '/css/color.css',
      '/css/responsive-grid.css',
      '/scripts/yui/container/assets/container.css',
      '/scripts/yui/assets/skins/sam/skin.css',
      '/scripts/yui/container/assets/skins/sam/container.css',
      '/scripts/yui/button/assets/skins/sam/button.css',
      '/scripts/yui/menu/assets/skins/sam/menu.css',
      '/jsbundles/pluginSetupWizard.css',
      '/scripts/prototype.js',
      '/scripts/behavior.js',
      '/org/kohsuke/stapler/bind.js',
      '/scripts/yui/yahoo/yahoo-min.js',
      '/scripts/yui/dom/dom-min.js',
      '/scripts/yui/event/event-min.js',
      '/scripts/yui/animation/animation-min.js',
      '/scripts/yui/dragdrop/dragdrop.js',
      '/scripts/yui/container/container-min.js',
      '/scripts/yui/connection/connection-min.js',
      '/scripts/yui/datasource/datasource-min.js',
      '/scripts/yui/autocomplete/autocomplete-min.js',
      '/scripts/yui/menu/menu-min.js',
      '/scripts/yui/element/element-min.js',
      '/scripts/yui/button/button-min.js',
      '/scripts/yui/storage/storage-min.js',
      '/scripts/hudson-behavior.js',
      '/scripts/sortable.js',
      '/jsbundles/pluginSetupWizard.js',
      '/assets/bootstrap/jsmodules/bootstrap3/style.css',
      '/css/font-awesome/css/font-awesome.min.css',
      '/css/icomoon/css/icomoon.css',
      '/assets/jquery-detached/jsmodules/jquery2.js',
      '/assets/bootstrap/jsmodules/bootstrap3.js',
      '/assets/handlebars/jsmodules/handlebars3.js',
      '/css/google-fonts/roboto/fonts/roboto-v15-greek_latin-ext_latin_vietnamese_cyrillic_greek-ext_cyrillic-ext-regular.woff2',
      '/css/google-fonts/roboto/fonts/roboto-v15-greek_latin-ext_latin_vietnamese_cyrillic_greek-ext_cyrillic-ext-700.woff2',
      '/css/icomoon/fonts/icomoon.ttf?-itxuas',
      '/css/google-fonts/roboto/fonts/roboto-v15-greek_latin-ext_latin_vietnamese_cyrillic_greek-ext_cyrillic-ext-300.woff2',
      '/css/google-fonts/roboto/fonts/roboto-v15-greek_latin-ext_latin_vietnamese_cyrillic_greek-ext_cyrillic-ext-500.woff2',
      '/favicon.ico',

   );
my $r=1;
if ($r==0) {
   foreach my $ppath (@files) {
      $cmd='wget -qO- --content-on-error '.
         '--random-wait --wait=3 '.
         '--cookies=on --keep-session-cookies '.
         '--load-cookies cookies.txt '.
         '--save-cookies cookies.txt '.
         '--level=1 '.
         '--header "Accept: text/html,application/xhtml+xml,application/xml;'.
         'q=0.9,*/*;q=0.8" '.
         '--header="User-Agent: Mozilla/5.0 '.
         '(Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0" '.
         '--header="DNT: 1" '.
         '--header="Upgrade-Insecure-Requests: 1" '.
         '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
         'http://'.$pbip.':8080/jenkins/static/'.$session.$ppath;
      ($stdout,$stderr)=$handle->cmd($cmd);
print "STDOUT=$stdout<== AND STDERR=$stderr<== XXXXXXXXXXXXXX\n";
   }
}
print "PASS=$adminpass\n";
   # https://www.urldecoder.org/
   my $data_crumb='from=%2Fjenkins%2F&j_username=admin&j_password='.
      $adminpass.'&Jenkins-Crumb='.$jenkins_crumb.'&json=%7B%22'.
      'from%22%3A+%22%2Fjenkins%2F%22%2C+%22j_username%22%3A+%22admin%22'.
      '%2C+%22j_password%22%3A+%22'.$adminpass.'%22%2C+%22Jenkins-Crumb%22%'.
      '3A+%22'.$jenkins_crumb.'%22%7D';
   $cmd='sudo wget -qO- --no-proxy --content-on-error --auth-no-challenge '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="Accept: text/html,application/xhtml+xml,'.
      'application/xml;q=0.9,*/*;q=0.8" '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.5" '.
      '--header="Origin: http://'.$pbip.':8080" '.
      '--header="User-Agent: Mozilla/5.0 '.
      '(Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0" '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="Content-Length: 333" '.
      '--header="Content-Type: application/x-www-form-urlencoded" '.
      '--referer="http://'.$pbip.':8080/jenkins/login?from=%2Fjenkins%2F" '.
      '--post-data="'.$data_crumb.'" '.
      'http://'.$pbip.':8080/jenkins/j_acegi_security_check';
print "ACEGI_CMD=$cmd<==\n";
   $cookies=$stderr;
   $cookies=~s/^.*(JSESSIONID=.*?);.*$/$1/s;
   ($stdout,$stderr)=$handle->cmd($cmd);
print "ACEGI_STDOUT=$stdout and ACEGI_STDERR=$stderr<==\n\n\n\n\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header "Accept: text/html,application/xhtml+xml,application/xml;'.
      'q=0.9,*/*;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 '.
      '(Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="DNT: 1" '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="Referer: http://'.$pbip.
      ':8080/jenkins/login?from=%2Fjenkins%2F" '.
      '--header="Cache-Control: max-age=0" '.
      'http://'.$pbip.':8080/jenkins/';
print "FINAL_CMD=$cmd<==\n";
   ($stdout,$stderr)=$handle->cmd($cmd);
print "FINAL_STDOUT=$stdout<== and FINAL_STDERR=$stderr<==FINALSTDERR\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 (Linux; Android 6.0; '.
      'Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, '.
      'like Gecko) Chrome/58.0.3029.110 Mobile Safari/537.36" '.
      '--header="Accept: application/json, text/javascript, */*; q=0.01" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="X-Requested-With: XMLHttpRequest" '.
      'http://'.$pbip.':8080/jenkins/i18n/resourceBundle?baseName=jenkins.install.pluginSetupWizard&_=1497382801063';
print "WIZ_CMD=$cmd<==\n";
      ($stdout,$stderr)=$handle->cmd($cmd);
print "WIZ_STDOUT=$stdout<== and WIZ_STDERR=$stderr<==\n\n\n\n\n";
   $cmd='sudo wget -qO- --cookies=on --keep-session-cookies --load-cookies cookies.txt '.
        '\'http://'.$pbip.':8080/jenkins/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)\'';
   ($stdout,$stderr)=$handle->cmd($cmd);
print "CRUMB_STDOUT=$stdout<== and CRUMB_STDERR=$stderr<==CRUMB_STDERR\n";
   $jenkins_crumb=$stdout;
   $jenkins_crumb=~s/^.*:(.*)$/$1/;
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="Origin: http://'.$pbip.':8080" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="User-Agent: Mozilla/5.0 '.
      '(Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="Content-Type: application/json" '.
      '--header="Accept: application/json, text/javascript, */*; q=0.01" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="X-Requested-With: XMLHttpRequest" '.
      '--header="Connection: keep-alive" '.
      '--header="DNT: 1" '.
      '--header="Jenkins-Crumb: '.$jenkins_crumb.'" '.
      '--post-data=\'{"dynamicLoad":true,"plugins":["cloudbees-folder","antisamy-markup-formatter","build-timeout","credentials-binding","timestamper","ws-cleanup","ant","gradle","workflow-aggregator","github-organization-folder","pipeline-stage-view","git","subversion","ssh-slaves","matrix-auth","pam-auth","ldap","email-ext","mailer"],"Jenkins-Crumb":"'.$jenkins_crumb.'"}\' '.
      'http://'.$pbip.':8080/jenkins/pluginManager/installPlugins';
print "PLUGIN_CMD=$cmd<==\n";
   ($stdout,$stderr)=$handle->cmd($cmd);
print "PLUGIN_STDOUT=$stdout<== and PLUGIN_STDERR=$stderr<==PLUGINSTDERR\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 (Linux; Android 6.0; '.
      'Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, '.
      'like Gecko) Chrome/58.0.3029.110 Mobile Safari/537.36" '.
      '--header="Accept: text/html,application/xhtml+xml,'.
      'application/xml;q=0.9,*/*;q=0.8" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="Proxy-Connection: keep-alive" '.
      'http://'.$pbip.':8080/jenkins/setupWizard/setupWizardFirstUser';
print "FIRSTUSER_CMD=$cmd<==\n";
      ($stdout,$stderr)=$handle->cmd($cmd);
print "FIRSTUSER_STDOUT=$stdout<== and FIRSTUSER_STDERR=$stderr<==\n\n\n\n\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 (Linux; Android 6.0; '.
      'Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, '.
      'like Gecko) Chrome/58.0.3029.110 Mobile Safari/537.36" '.
      '--header="Accept: application/json, text/javascript, */*; q=0.01" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="X-Requested-With: XMLHttpRequest" '.
      '--header="Proxy-Connection: keep-alive" '.
      'http://'.$pbip.':8080/jenkins/setupWizard/'.
      'restartStatus?_=1497374550478';
print "RESTART_CMD=$cmd<==\n";
      ($stdout,$stderr)=$handle->cmd($cmd);
print "RESTART_STDOUT=$stdout<== and RESTART_STDERR=$stderr<==\n\n\n\n\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 (Linux; Android 6.0; '.
      'Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, '.
      'like Gecko) Chrome/58.0.3029.110 Mobile Safari/537.36" '.
      '--header="Accept: application/json, text/javascript, */*; q=0.01" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="X-Requested-With: XMLHttpRequest" '.
      '--header="Origin: http://'.$pbip.':8080" '.
      '--header="Jenkins-Crumb: '.$jenkins_crumb.'" '.
      '--post-data=\'{"Jenkins-Crumb":"'.$jenkins_crumb.'"}\' '.
      'http://'.$pbip.':8080/jenkins/setupWizard/completeInstall';
print "COMPLETE_CMD=$cmd<==\n";
      ($stdout,$stderr)=$handle->cmd($cmd);
print "COMPLETE_STDOUT=$stdout<== and COMPLETE_STDERR=$stderr<==\n\n\n\n\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 (Linux; Android 6.0; '.
      'Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, '.
      'like Gecko) Chrome/58.0.3029.110 Mobile Safari/537.36" '.
      '--header="Accept: text/html,application/xhtml+xml,'.
      'application/xml;q=0.9,*/*;q=0.8" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="Proxy-Connection: keep-alive" '.
      'http://'.$pbip.':8080/jenkins/';
print "JENKINS_CMD=$cmd<==\n";
      ($stdout,$stderr)=$handle->cmd($cmd);
print "JENKINS_STDOUT=$stdout<== and JENKINS_STDERR=$stderr<==\n\n\n\n\n";
   $cmd='sudo wget -d -qO- --content-on-error '.
      '--random-wait --wait=3 '.
      '--cookies=on --keep-session-cookies '.
      '--load-cookies cookies.txt '.
      '--save-cookies cookies.txt '.
      '--header="DNT: 1" '.
      '--header="Accept-Encoding: deflate, sdch" '.
      '--header="Accept-Language: en-US,en;q=0.8" '.
      '--header="User-Agent: Mozilla/5.0 (Linux; Android 6.0; '.
      'Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, '.
      'like Gecko) Chrome/58.0.3029.110 Mobile Safari/537.36" '.
      '--header="Accept: text/html,application/xhtml+xml,'.
      'application/xml;q=0.9,*/*;q=0.8" '.
      '--header="Referer: http://'.$pbip.':8080/jenkins/" '.
      '--header="Upgrade-Insecure-Requests: 1" '.
      '--header="Proxy-Connection: keep-alive" '.
      'http://'.$pbip.':8080/jenkins/user/admin/configure';
print "CONFIG_CMD=$cmd<==\n";
      ($stdout,$stderr)=$handle->cmd($cmd);
print "CONFIG_STDOUT=$stdout<== and CONFIG_STDERR=$stderr<==\n\n\n\n\n";
   my $api_token=$stdout;
   $api_token=~s/^.*?apiToken.*?value=["](.*?)["].*$/$1/s;

   print "\n   ACCESS JENKINS UI AT:\n\n",
         " http://$pbip:8080/jenkins\n\n Password: $adminpass".
         "\n\n API Token: $api_token\n\n";
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
            "   to start with your new Jenkins™ installation!\n\n\n";
   } else {
      print $thanks;
   }
   &Net::FullAuto::FA_Core::cleanup;

};

my $standup_jenkins=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $jenkins="]T[{select_jenkins_setup}";
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
      'JenkinsSecurityGroup --description '.
      '"Jenkins.io Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name JenkinsSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name JenkinsSecurityGroup --protocol '.
      'tcp --port 80 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name JenkinsSecurityGroup --protocol '.
      'tcp --port 443 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name JenkinsSecurityGroup --protocol '.
      'tcp --port 8080 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'Jenkins.io'}) {
      my $g=get_aws_security_id('JenkinsSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'Jenkins.io'}}==0) {
         launch_server('Jenkins.io',$cnt,$jenkins,'',$c,
         $configure_jenkins);
      } else {
         my $num=$#{$main::aws->{'Jenkins.io'}}-1;
         foreach my $num (0..$num) {
            launch_server('Jenkins.io',$cnt++,$jenkins,'',$c,
            $configure_jenkins);
         }
      }
   }

   return '{choose_demo_setup}<';

};

my $jenkins_setup_summary=sub {

   package jenkins_setup_summary;
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
   my $jenkins="]T[{select_jenkins_setup}";
   $jenkins=~s/^"//;
   $jenkins=~s/"$//;
   my $num_of_servers=0;
   my $ol=$jenkins;
   $ol=~s/^.*(\d+)\sServer.*$/$1/;
   if ($ol==1) {
      $main::aws->{'Jenkins.io'}->[0]=[];
   } elsif ($ol=~/^\d+$/ && $ol) {
      foreach my $n (0..$ol) {
         $main::aws->{'Jenkins.io'}=[] unless exists
            $main::aws->{'Jenkins.io'};
         $main::aws->{'Jenkins.io'}->[$n]=[];
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

         $jenkins


END
   my %show_cost=(

      Name => 'show_cost',
      Item_1 => {

         Text => "I accept the \$$cost$cents per hour cost",
         Result => $standup_jenkins,

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

our $select_jenkins_setup=sub {

   my @options=('Jenkins on 1 Server');
   my $jenkins_setup_banner=<<'END';


        _            _    _
       | | ___ _ __ | | _(_)_ __  ___
    _  | |/ _ \ '_ \| |/ / | '_ \/ __|
   | |_| |  __/ | | |   <| | | | \__ \
    \___/ \___|_| |_|_|\_\_|_| |_|___/


   Choose the Jenkins setup you wish to demo. Note that more servers
   means more expense, and more JVMs means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 JVM on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_jenkins_setup=(

      Name => 'select_jenkins_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $jenkins_setup_summary,

      },
      Scroll => 1,
      Banner => $jenkins_setup_banner,
   );
   return \%select_jenkins_setup

};

1
