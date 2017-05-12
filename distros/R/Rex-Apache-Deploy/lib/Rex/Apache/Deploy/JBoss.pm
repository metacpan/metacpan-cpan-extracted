#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::JBoss - Deploy application to JBoss.

=head1 DESCRIPTION

With this module you can deploy EAR/WAR archives to JBoss.

=head1 SYNOPSIS

 use Rex::Apache::Deploy qw/JBoss/;

 context_path "/myapp";

 task "dodeploy", "j01", "j02", sub {
   deploy "myapp.ear",
     deploy_path => "/opt/jboss/server/default/deploy";
 };

=head1 FUNCTIONS

=over 4

=cut

package Rex::Apache::Deploy::JBoss;

use strict;
use warnings;
use File::Basename qw'basename';
use File::Spec;
use Rex::Commands::Upload;
use Rex::Commands::Fs;
use Rex::Commands::Run;
use Rex::Commands;

use vars qw(@EXPORT $context_path);
@EXPORT = qw(deploy context_path);

############ deploy functions ################

=item deploy($file, %option)

This function deploys the given WAR archive. For that it will connect to the Tomcat manager. You have to define username and password for the Tomcat manager in the %option hash. If the Tomcat manager isn't available under its default location /manager you can also define the location with the I<manager_url> option.

 task "dodeploy", "j01", "j02", sub {
   deploy "myapp.war",
     context_path => "/myapp",
     deploy_path => "/opt/jboss/server/default/deploy";
 };


=cut

sub deploy {
  my ( $file, %option ) = @_;

  my $abs_file = File::Spec->rel2abs($file);

  if ( !%option ) {
    if ( Rex::Config->get("package_option") ) {
      %option = %{ Rex::Config->get("package_option") };
    }
  }

  if ( exists $option{context_path} || $context_path ) {
    LOCAL {
      Rex::Logger::debug("Context-Path given, need to extract archive.");
      my $inf_file;

      mkdir "tmp/$$";
      run "cd tmp/$$; unzip $abs_file";
      if ( $? != 0 ) {
        rmdir "tmp/$$";
        Rex::Logger::info( "Error extracting $file.", "error" );
        die("Error extracting $file.");
      }

      if ( $file =~ m/\.ear$/ ) {
        $inf_file = "META-INF/application.xml";
      }
      elsif ( $file =~ m/\.war$/ ) {
        $inf_file = "WEB-INF/jboss-web.xml";
      }
      else {
        Rex::Logger::info(
          "Can't set context path for this file ($file). Only .ear and .war are supported.",
          "error"
        );
        die(
          "Can't set context path for this file ($file). Only .ear and .war are supported."
        );
      }

      if ( !-f "tmp/$$/$inf_file" ) {
        Rex::Logger::info( "Can't find file $inf_file.", "error" );
        rmdir "tmp/$$";
        die("Can't find file $inf_file.");
      }

      open my $file_in, "<", "tmp/$$/$inf_file";
      my @new_content;
      my $context = $option{context_path} || $context_path;
      while ( my $line = <$file_in> ) {
        chomp $line;
        if ( $line =~ m/<context\-root>/ ) {
          $line =~
            s/<context\-root>([^>]+)<\/context\-root>/<context\-root>$context<\/context\-root>/;
        }

        push @new_content, $line;
      }
      close $file_in;

      open my $file_out, ">", "tmp/$$/$inf_file";
      print $file_out join( "\n", @new_content );
      close $file_out;

      mv $abs_file, "tmp/" . basename($file) . ".old";
      run "cd tmp/$$; zip -r $abs_file *";
      if ( $? != 0 ) {
        rmdir "tmp/$$";
        Rex::Logger::info( "Error creating ear archive.", "error" );
        die("Error creating ear archive.");
      }
      rmdir "tmp/$$";
    }
  }

  upload $abs_file, "$option{deploy_path}/" . basename($abs_file);
}

=item context_path($path)

This function sets the context path for the application that gets deployed. This is a global setting. If you want to specify a custom context path for your application you can also do this as an option for the I<deploy> function.

 context_path "/myapp";

=cut

sub context_path {
  $context_path = shift;
}

=back

=cut

####### import function #######

sub import {

  no strict 'refs';
  for my $func (@EXPORT) {
    Rex::Logger::debug("Registering main::$func");
    *{"$_[1]::$func"} = \&$func;
  }

}

1;
