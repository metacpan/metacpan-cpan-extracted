package Net::FullAuto::ISets::Amazon::Catalyst_is;

### OPEN SOURCE LICENSE - GNU AFFERO PUBLIC LICENSE Version 3.0 #######
#
#    Net::FullAuto - Distributed Workload Automation Software
#    Copyright © 2000-2017  Brian M. Kelly
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
our $DISPLAY='Catalyst© Web Framework';
our $CONNECT='secure';
our $defaultInstanceType='t2.small';

use 5.005;


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($select_catalyst_setup);

use Net::FullAuto::Cloud::fa_amazon;
use Net::FullAuto::FA_Core qw[cmd_raw];
my $sudo=($^O eq 'cygwin')?'':'sudo ';

my $configure_catalyst=sub {

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
      ' libicu cyrus-sasl-devel libtool-ltdl-devel libxml2-devel'.
      ' freetype-devel libpng-devel',
      '__display__');
   ($stdout,$stderr)=$handle->cmd('sudo yum -y install cpan',
      '__display__');
   $handle->{_cmd_handle}->print('sudo cpan');
   my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
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
   my $show=<<END;
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
      File::Find::Rule
      Catalyst::Runtime
      Regexp::Assemble
      Catalyst::Controller::HTML::FormFu
      Task::Catalyst::Tutorial
      YAML::Syck
      Catalyst::Model::Adaptor

   );
# https://metacpan.org/pod/DBIx::Class::Manual::Cookbook#Predefined-searches
# http://ajct.info/2015/08/16/oauth-and-catalyst.html
# http://stackoverflow.com/questions/23652166/how-to-generate-oauth-2-client-id-and-secret
# https://bshaffer.github.io/oauth2-server-php-docs/grant-types/refresh-token/
   my $install_catalyst=<<'END';


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
         print $install_catalyst;
         sleep 10;
      }
      if ($module eq 'Regexp::Assemble') {
         $handle->{_cmd_handle}->print($sudo.
            'perl -MCPAN -e \'CPAN::Shell->force('.
            "\"install\",\"$module\")\'"
         )
      } else {
         $handle->{_cmd_handle}->print($sudo."cpan $module 2>&1");
      }
      my $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
      my $error=0;my $force=0;my $tries=0;my $allout='';
      while (1) {
         my $done=eval {
            local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
            alarm 120;
            my $output=Net::FullAuto::FA_Core::fetch($handle);
            $allout.=$output;
            if ($output=~/$prompt/) {
               if ($error) {
                  $error=0;$force=1;
                  $handle->{_cmd_handle}->print($sudo.
                     'perl -MCPAN -e \'CPAN::Shell->force('.
                     "\"install\",\"$module\")\'"
                  )
               } else {
                  $output=~s/$prompt$//s;
                  print $output;
                  return 'done';
               }
            } elsif ($output=~/build the XS Stash module/) {
               $handle->{_cmd_handle}->print('y');
            } elsif ($output=~/use the XS Stash by default/) {
               $handle->{_cmd_handle}->print('y');
            }
            if (!$force &&
                  ((-1<index $allout,'[test_dynamic] Error 255') ||
                  (-1<index $allout,'Connection reset by peer'))) {
               $error=1;
               $output=~s/$prompt//gs;
            }
            print $output;
            return 'continue';
         };
         next if $done eq 'continue';
         if ($done=~/^\d$/ && $done==1) {
            my $output=Net::FullAuto::FA_Core::fetch($handle);
            my $attempt='attempts';
            $attempt='attempt' if $tries==0;
            print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                  ":  $module\n\n",
                  "                 --> $output\n",
                  "                 after ",++$tries," $attempt\n\n";
            &Net::FullAuto::FA_Core::cleanup;
         } elsif ($@ && ++$tries<4) {
            alarm(0);$allout='';
            $handle->{_cmd_handle}->print("\003");
            my $done=eval {
               local $SIG{ALRM} = sub { die "alarm\n" }; # \n required
               while (my $ln=$handle->{_cmd_handle}->get) {
                  return 'done' if $ln=~/$prompt/s;
               }
            };
            if ($@) {
               my $attempt='attempts';
               $attempt='attempt' if $tries==0;
               print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                     ":  $module\n\n",
                     "                 --> could not recover handle after \n",
                     "                 ",++$tries," $attempt\n\n";
               &Net::FullAuto::FA_Core::cleanup;
            } elsif ($done) {
               next
            } else {
               print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                     "                 $module\n",
                     "                 - Unknown Error after ",
                     --$tries," attempts\n\n";
               &Net::FullAuto::FA_Core::cleanup;
            }
         } elsif ($tries>3) {
            my $attempt='attempts';
            print "\n\n   FATAL ERROR!: Could not install CPAN Module",
                  ":  $module\n\n",
                  "                 after ",++$tries," $attempt\n\n";
            &Net::FullAuto::FA_Core::cleanup;
         }
         last if $done;
      }
   }
   $show=<<END;

########################################

   INSTALLING Catalyst::Devel

########################################
END
   print $show;
   if ($^O eq 'cygwin') {
      $handle->{_cmd_handle}->print($sudo.
         'perl -MCPAN -e \'CPAN::Shell->notest('.
         '"install","Catalyst::Devel")\'');
   } else {
      $handle->{_cmd_handle}->print($sudo.'cpan Catalyst::Devel');
   }
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

   INSTALLING DBIx::Class::Schema::Loader

########################################
END
   cmd_raw($handle,'sudo cpan DBIx::Class::Schema::Loader',
      '__display__');
   $show=<<END;
########################################

   INSTALLING Catalyst::Controller::REST

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,'sudo cpan Catalyst::Controller::REST','__display__');
   $show=<<END;
########################################

   INSTALLING Catalyst::View::JSON

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,'sudo cpan Catalyst::View::JSON','__display__');
   $show=<<END;
   $show=<<END;
########################################

   INSTALLING Catalyst::View::TT::Alloy

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,'sudo cpan Catalyst::View::TT::Alloy','__display__');
   $show=<<END;
########################################

   INSTALLING Catalyst::Plugin::Unicode

########################################
END
   print $show;
   sleep 1;
   cmd_raw($handle,'sudo cpan Catalyst::Plugin::Unicode','__display__');
   $show=<<END;
########################################

   INSTALLING Finance::Quote

########################################
END
   print $show;
   $handle->{_cmd_handle}->print('sudo cpan Finance::Quote');
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
   ($stdout,$stderr)=$handle->cmd("mkdir db lib/AdventREST/Schema");
   my $db_sql="db.sql";
   my $content=<<'END';
CREATE TABLE user (
 user_id TYPE text NOT NULL PRIMARY KEY,
 fullname TYPE text NOT NULL,
 description TYPE text NOT NULL
); 
END
   ($stdout,$stderr)=$handle->cmd("touch $db_sql");
   ($stdout,$stderr)=$handle->cmd("chmod 777 $db_sql");
   ($stdout,$stderr)=$handle->cmd("echo \"$content\" > $db_sql");
   ($stdout,$stderr)=$handle->cmd("chmod 644 $db_sql");
   ($stdout,$stderr)=$handle->cmd('sqlite3 db/adventrest.db < db.sql');
   ($stdout,$stderr)=$handle->cwd("lib/AdventREST");
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
   ($stdout,$stderr)=$handle->cmd("chmod 777 Schema.pm");
   ($stdout,$stderr)=$handle->cmd("echo \"$content\" > Schema.pm");
   ($stdout,$stderr)=$handle->cmd("chmod 644 Schema.pm");
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
   ($stdout,$stderr)=$handle->cmd("chmod 777 User.pm");
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > User.pm");
   ($stdout,$stderr)=$handle->cmd("chmod 644 User.pm");
   ($stdout,$stderr)=$handle->cwd("../../..");
   ($stdout,$stderr)=$handle->cmd("./script/adventrest_create.pl ".
      "model DB DBIC::Schema AdventREST::Schema");
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
   ($stdout,$stderr)=$handle->cmd("chmod 777 adventrest.yml");
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > adventrest.yml");
   ($stdout,$stderr)=$handle->cmd("chmod 644 adventrest.yml");
   ($stdout,$stderr)=$handle->cmd(
      "./script/adventrest_create.pl controller User");
   ($stdout,$stderr)=$handle->cmd("mv lib/AdventREST/Controller/User.pm ".
      "lib/AdventREST/Controller/User.bak");
   $content=<<'END';
package AdventREST::Controller::User;
 
use strict;
use warnings;
use Moose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::REST' }

sub user_list : Path('/user') :Args(0) : ActionClass('REST') { }

sub user_list_GET {
    my ( \\x24self, \\x24c ) = @_;
 
    my %user_list;
    my \\x24user_rs = \\x24c->model('DB::User')->search;
    while ( my \\x24user_row = \\x24user_rs->next ) {
        \\x24user_list{ \\x24user_row->user_id } =
          \\x24c->uri_for( '/user/' . \\x24user_row->user_id )->as_string;
    }
    \\x24self->status_ok( \\x24c, entity => \\%user_list );
}

sub single_user : Path('/user') : Args(1) : ActionClass('REST') {
    my ( \\x24self, \\x24c, \\x24user_id ) = @_;
 
    \\x24c->stash->{'user'} = \\x24c->model('DB::User')->find(\\x24user_id);
}

sub single_user_POST {
    my ( \\x24self, \\x24c, \\x24user_id ) = @_;
 
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
    my ( \\x24self, \\x24c, \\x24user_id ) = @_;
 
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
    my ( \\x24self, \\x24c, \\x24user_id ) = @_;
 
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
   ($stdout,$stderr)=$handle->cmd("chmod 777 User.pm");
   ($stdout,$stderr)=$handle->cmd("echo -e \"$content\" > User.pm");
   ($stdout,$stderr)=$handle->cmd("chmod 644 User.pm");
   ($stdout,$stderr)=$handle->cwd('../../../..');
   ($stdout,$stderr)=$handle->cmd(
      "wget --random-wait --progress=dot ".
      "https://github.com/pangyre/p5-myapp-10in10/archive/master.zip",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("unzip master.zip",'__display__');
   ($stdout,$stderr)=$handle->cmd("rm -rvf master.zip",'__display__');
   ($stdout,$stderr)=$handle->cwd("p5-myapp-10in10-master");
   ($stdout,$stderr)=$handle->cmd("mkdir -vp root/static/img/title",
      '__display__');
   ($stdout,$stderr)=$handle->cmd("perl Makefile.PL",'__display__');
   ($stdout,$stderr)=$handle->cmd(
      "sed -i 's/static.*=/Plugin::Static::Simple =/' lib/MyApp.pm");
   ($stdout,$stderr)=$handle->cmd(
      "sed -i \"s/Plugin::Static::Simple/'&'/\" lib/MyApp.pm");
   ($stdout,$stderr)=$handle->cmd(
      "sed -i '/Unicode::Encoding/d' lib/MyApp.pm");
   my $ad='encoding: utf8';
   ($stdout,$stderr)=$handle->cmd(
      "sed -i \'/default_view/a $ad\' myapp.yml");
   $handle->{_cmd_handle}->print(
      'script/myapp_server.pl --background');
   $prompt=substr($handle->{_cmd_handle}->prompt(),1,-1);
   while (1) {
      my $output.=Net::FullAuto::FA_Core::fetch($handle);
      last if $output=~/$prompt/;
      print $output;
      if (-1<index $output,'| /end') {
         $output=Net::FullAuto::FA_Core::fetch($handle);
         print $output;
         last;
      }
   }
   my $master=$main::aws->{$server_type}->[0]->[0]->{InstanceId};
   my $c="aws ec2 describe-instances --instance-ids $master 2>&1";
   my ($hash,$output,$error)=('','','');
   ($hash,$output,$error)=run_aws_cmd($c);
   my $mdns=$hash->{Reservations}->[0]->{Instances}->[0]->{PublicDnsName};
   print "\n   ACCESS CATALYST UI AT:\n\n",
         " http://$mdns:3000\n";
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


   Copyright © 2000-2017  Brian M. Kelly  Brian.Kelly@FullAuto.com

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

my $standup_catalyst=sub {

   my $type="]T[{select_type}";
   $type=~s/^"//;
   $type=~s/"$//;
   $type=~s/^(.*?)\s+-[>].*$/$1/;
   my $catalyst="]T[{select_catalyst_setup}";
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
      'CatalystSecurityGroup --description '.
      '"CatalystFramework.org Security Group" 2>&1';
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name CatalystSecurityGroup --protocol '.
      'tcp --port 22 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   $c='aws ec2 authorize-security-group-ingress '.
      '--group-name CatalystSecurityGroup --protocol '.
      'tcp --port 3000 --cidr '.$cidr." 2>&1";
   ($hash,$output,$error)=run_aws_cmd($c);
   Net::FullAuto::FA_Core::handle_error($error) if $error
      && $error!~/already exists/;
   #$c='aws ec2 authorize-security-group-ingress '.
   #   '--group-name CatalystSecurityGroup --protocol '.
   #   'tcp --port 443 --cidr '.$cidr." 2>&1";
   #($hash,$output,$error)=run_aws_cmd($c);
   #Net::FullAuto::FA_Core::handle_error($error) if $error
   #   && $error!~/already exists/;
   my $cnt=0;
   my $pemfile=$pem_file;
   $pemfile=~s/\.pem\s*$//s;
   $pemfile=~s/[ ][(]\d+[)]//;
   if (exists $main::aws->{'CatalystFramework.org'}) {
      my $g=get_aws_security_id('CatalystSecurityGroup');
      my $c="aws ec2 run-instances --image-id $i --count 1 ".
         "--instance-type $type --key-name \'$pemfile\' ".
         "--security-group-ids $g --subnet-id $s";
      if ($#{$main::aws->{'CatalystFramework.org'}}==0) {
#print "WTF is DISPLAY=$DISPLAY\n";
         launch_server('CatalystFramework.org',$cnt,$catalyst,'',$c,
         $configure_catalyst);
      } else {
         my $num=$#{$main::aws->{'CatalystFramework.org'}}-1;
         foreach my $num (0..$num) {
            launch_server('CatalystFramework',$cnt++,$catalyst,'',$c,
            $configure_catalyst);
         }
      }
   }

   return '{choose_demo_setup}<';

};

my $catalyst_setup_summary=sub {

   package catalyst_setup_summary;
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
   my $catalyst="]T[{select_catalyst_setup}";
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
         Result => $standup_catalyst,

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

our $select_catalyst_setup=sub {

   my @options=('Catalyst Web Framework on 1 Server');
   my $catalyst_setup_banner=<<'END';

                     _
                   ((_)
                    /
                   /              _        _           _
               \__/_     ___ __ _| |_ __ _| |_   _ ___| |_
               /    \   / __/ _` | __/ _` | | | | / __| __|  Perl MVC
            _- |    |  | (_| (_| | || (_| | | |_| \__ \ |    framework
       _ _-'   \____/   \___\__,_|\__\__,_|_|\__, |___/\__|©
     ((_)       ---\                         |___/
                    \
                     \\_          Web Framework
                      (_)

   Choose the Catalyst setup you wish to demo. Note that more servers
   means more expense, and more instances means less permformance on a
   small instance type. Consider a medium or large instance type (previous
   screens) if you wish to test more than 1 instance on a server. You can
   navigate backwards and make new selections with the [<] LEFTARROW key.

END
   my %select_catalyst_setup=(

      Name => 'select_catalyst_setup',
      Item_1 => {

         Text => ']C[',
         Convey => \@options,
         Result => $catalyst_setup_summary,

      },
      Scroll => 1,
      Banner => $catalyst_setup_banner,
   );
   return \%select_catalyst_setup

};

1
