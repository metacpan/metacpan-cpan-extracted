#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::Symlink - Deploy application and symlink to live

=head1 DESCRIPTION

With this module you can deploy an application to a special folder and after that you can symlink it to the document root.

=head1 SYNOPSIS

 generate_deploy_directory {
   my ($file) = @_;
   $file =~ m/(\d+\.\d+)/;
   return $1;
 };

 deploy_to "/data/myapp";
 document_root "/var/www/html";

 task "dodeploy", "server1", sub {
   deploy "myapp-1.2.tar.gz";
 };

 task "dodeploy", "server1", sub {
   deploy "myapp",
     version => "1.2";
 };

=head1 FUNCTIONS

=over 4

=cut

package Rex::Apache::Deploy::Symlink;

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;
use File::Basename qw(dirname basename);

use Rex::Apache::Build;

use File::Basename qw(basename);
use Cwd qw(getcwd);

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $deploy_to $document_root $generate_deploy_directory);
@EXPORT = qw(deploy get_live_version get_deploy_directory_for
  deploy_to generate_deploy_directory document_root
  list_versions switch_to_version);

############ deploy functions ################

=item deploy($file, %option)

This function will do the deployment. It uploads the file to the target server and extract it to the directory given by I<deploy_to> concatenated with the return value of I<generate_deploy_directory>.

 task "dodeploy", "server1", sub {
   deploy "myapp-1.2.tar.gz";
 };

 task "dodeploy", "server1", sub {
   deploy "myapp",
     version => "1.2";
 };


=cut

sub deploy {
  my ( $file, %option ) = @_;

  if ( !%option ) {
    if ( Rex::Config->get("package_option") ) {
      %option = %{ Rex::Config->get("package_option") };
    }
  }

  my $options = \%option;

  unless ($file) {

    # if no file is given, use directory name
    $file = basename( getcwd() );
  }

  unless ( -f $file ) {
    my $version = get_version();

    if ( exists $options->{version} ) {
      $version = $options->{version};
    }

    # if file doesn't exists, try to find it
    if ( -f "$file.tar.gz" ) {
      $file = "$file.tar.gz";
    }
    elsif ( -f "$file-$version.tar.gz" ) {
      $file = "$file-$version.tar.gz";
    }
    else {
      Rex::Logger::debug("No file found to deploy ($file)");
      die("File $file not found.");
    }
  }

  no strict;
  no warnings;
  my $rnd_file = get_random( 8, a .. z, 0 .. 9 );
  use strict;
  use warnings;

  unless ( is_dir($deploy_to) ) {
    mkdir $deploy_to;
  }

  unless ( is_writeable($deploy_to) ) {
    Rex::Logger::info("No write permission to $deploy_to");
    exit 1;
  }

  unless ( is_writeable( dirname($document_root) ) ) {
    Rex::Logger::info("No write permission to $document_root");
    exit 1;
  }

  my $deploy_dir = get_deploy_directory_for($file);
  Rex::Logger::debug("deploy_dir: $deploy_dir");

  if ( get_live_version() && get_live_version() eq basename($deploy_dir) ) {
    Rex::Logger::info(
      "Sorry, you try to deploy to a version that is currently live.");
    exit 1;
  }

  Rex::Logger::debug( "Uploadling $file to /tmp/$rnd_file" . _get_ext($file) );
  upload( $file, "/tmp/$rnd_file" . _get_ext($file) );

  mkdir $deploy_dir;

  run "cd $deploy_dir; "
    . sprintf( _get_extract_command($file),
    "/tmp/$rnd_file" . _get_ext($file) );

  Rex::Logger::debug( "Unlinking /tmp/$rnd_file" . _get_ext($file) );
  unlink "/tmp/$rnd_file" . _get_ext($file);
}

=item list_versions

This function returns all available versions from the directory defined by I<deploy_to> as an array.

=cut

sub list_versions {
  return grep { !/^\./ } list_files($deploy_to);
}

=item switch_to_version($new_version)

This function switches to the given version.

 task "switch", "server1", sub {
   my $param = shift;

   switch_to_version $param->{version};
 };

=cut

sub switch_to_version {
  my ($new_version) = @_;

  my @versions = list_versions;
  if ( !grep { /$new_version/ } @versions ) {
    Rex::Logger::info("no version found!");
    return;
  }

  run "ln -snf $deploy_to/$new_version $document_root";
}

=item get_live_version

This function returns the current live version.

=cut

sub get_live_version {
  my $link = eval { return readlink $document_root; };

  return basename($link) if ($link);
}

############ configuration functions #############

sub get_deploy_directory_for {
  my ($file) = @_;

  unless ($generate_deploy_directory) {
    $generate_deploy_directory = sub {
      my ($file) = @_;
      if ( $file =~ m/-([0-9\._~\-]+)\.(zip|tar\.gz|war|tar\.bz2|jar)$/ ) {
        return $1;
      }
      else {
        return "" . time;
      }
    };
  }
  my $gen_dir_name = &$generate_deploy_directory($file);
  my $deploy_dir   = "$deploy_to/$gen_dir_name";

  return $deploy_dir;
}

=item deploy_to($directory)

This function sets the directory where the uploaded archives should be extracted. This is not the document root of your webserver.

 deploy_to "/data/myapp";

=cut

sub deploy_to {
  $deploy_to = shift;
}

=item document_root($doc_root)

This function sets the document root of your webserver. This will be a symlink to the deployed application.

=cut

sub document_root {
  $document_root = shift;
}

=item generate_deploy_directory(sub{})

If you need a special directory naming of your uploaded version you can define it with this function.

The default function is:

 sub {
   my ($file) = @_;
   if($file =~ m/-([0-9\._~\-]+)\.(zip|tar\.gz|war|tar\.bz2|jar)$/) {
     return $1;
   }
   else {
     return "" . time;
   }
 };


=cut

sub generate_deploy_directory(&) {
  $generate_deploy_directory = shift;
}

############ helper functions #############

sub _get_extract_command {
  my ($file) = @_;

  if ( $file =~ m/\.tar\.gz$/ ) {
    return "tar xzf %s";
  }
  elsif ( $file =~ m/\.zip$/ ) {
    return "unzip -o %s";
  }
  elsif ( $file =~ m/\.tar\.bz2$/ ) {
    return "tar xjf %s";
  }

  die("Unknown Archive Format.");
}

sub _get_pack_command {
  my ($file) = @_;

  if ( $file =~ m/\.tar\.gz$/ ) {
    return "tar czf %s %s";
  }
  elsif ( $file =~ m/\.zip$/ ) {
    return "zip -r %s %s";
  }
  elsif ( $file =~ m/\.tar\.bz2$/ ) {
    return "tar cjf %s %s";
  }

  die("Unknown Archive Format.");
}

sub _get_ext {
  my ($file) = @_;

  if ( $file =~ m/\.tar\.gz$/ ) {
    return ".tar.gz";
  }
  elsif ( $file =~ m/\.zip$/ ) {
    return ".zip";
  }
  elsif ( $file =~ m/\.tar\.bz2$/ ) {
    return ".tar.bz2";
  }

  die("Unknown Archive Format.");

}

####### import function #######

sub import {

  no strict 'refs';
  for my $func (@EXPORT) {
    Rex::Logger::debug("Registering main::$func");
    *{"$_[1]::$func"} = \&$func;
  }

}

=back

=cut

1;
