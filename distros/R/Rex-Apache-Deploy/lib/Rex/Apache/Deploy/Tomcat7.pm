#
# (c) Jan Gehring <jan.gehring@gmail.com>
#
# vim: set ts=2 sw=2 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Deploy::Tomcat7 - Deploy application to Tomcat 7.

=head1 DESCRIPTION

With this module you can deploy WAR archives to Tomcat7.
This module needs the manager application and I<manager-script> permissions.

=head1 SYNOPSIS

 use Rex::Apache::Deploy qw/Tomcat7/;

 context_path "/myapp";

 task "dodeploy", "tc01", "tc02", sub {
   deploy "myapp.war",
     username => "manager",
     password => "manager",
     port    => 8080;
 };

=head1 FUNCTIONS

=over 4

=cut

package Rex::Apache::Deploy::Tomcat7;

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;
use File::Basename qw(dirname basename);
use LWP::UserAgent;

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $context_path);
@EXPORT = qw(deploy context_path jk);

############ deploy functions ################

=item deploy($file, %option)

This function deploys the given WAR archive. For that it will connect to the Tomcat manager. You have to define username and password for the Tomcat manager in the %option hash. If the Tomcat manager isn't available under its default location /manager you can also define the location with the I<manager_url> option.

 task "dodeploy", "tc01", "tc02", sub {
   deploy "myapp.war",
     username    => "manager",
     password    => "manager",
     manager_url  => "_manager",
     port      => 8080,
     context_path => "/foo";
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

  no strict;
  no warnings;
  my $rnd_file = get_random( 8, a .. z, 0 .. 9 );
  use strict;
  use warnings;

  if ( !exists $options->{"context_path"} ) {
    $options->{"context_path"} = $context_path;
  }

  if ( exists $options->{"manager_url"} ) {
    my $mgr_url = $options->{"manager_url"};
    $mgr_url =~ s{^/}{};
    $options->{"manager_url"} = $mgr_url;
  }
  else {
    $options->{"manager_url"} = "manager";
  }

  upload( $file, "/tmp/$rnd_file.war" );
  chmod 644, "/tmp/$rnd_file.war";

  $options->{"file"} = "/tmp/$rnd_file.war";

  _deploy($options);

  unlink "/tmp/$rnd_file.war";
}

sub jk {
  my ( $action, $iname, @opts ) = @_;
  my $option = {@opts};
  my $path   = $option->{"path"} || "/jkmanager";
  my $worker = $option->{"worker"} || "";

  my $url    = "http://%s%s/?cmd=update&w=$worker&att=vwa&sw=%s&vwa=%i";
  my $server = Rex->get_current_connection()->{"server"};

  if ( $action eq "disable" ) {
    $url = sprintf( $url, $server, $path, $iname, 1 );
  }
  else {
    $url = sprintf( $url, $server, $path, $iname, 0 );
  }

  my $ua       = LWP::UserAgent->new;
  my $response = $ua->get($url);

  if ( !$response->is_success ) {
    die("Failed $action instance");
  }
}

############ helper function ##############

sub _deploy {

  my $p = shift;

  my $server = connection->server;
  if ( $server eq "<local>" ) {
    $server = "localhost";
  }

  my $ua = LWP::UserAgent->new();
  my $url =
    _get_url( "$server:$p->{port}",
    "deploy?path=$p->{context_path}&war=file:$p->{file}&update=true",
    $p->{"username"}, $p->{"password"}, $p->{"manager_url"} );

  Rex::Logger::debug("Connection to: $url");
  my $resp = $ua->get($url);
  if ( $resp->is_success ) {
    my $c = $resp->decoded_content;
    if ( $c =~ m/FAIL/gmi ) {
      Rex::Logger::info( $resp->decoded_content );
      die( $resp->decoded_content );
    }
    else {
      Rex::Logger::info( $resp->decoded_content );
    }
  }
  else {
    Rex::Logger::info( "FAILURE: $url: " . $resp->status_line );
    die( "FAILURE: $url: " . $resp->status_line );
  }

}

sub _undeploy {

  my $p = shift;

  my $server = connection->server;
  if ( $server eq "<local>" ) {
    $server = "localhost";
  }

  my $ua  = LWP::UserAgent->new();
  my $url = _get_url( "$server:$p->{port}", "undeploy?path=$p->{context_path}",
    $p->{username}, $p->{password}, $p->{manager_url} );

  Rex::Logger::debug("Connection to: $url");
  my $resp = $ua->get($url);
  if ( $resp->is_success ) {
    Rex::Logger::info( $resp->decoded_content );
  }
  else {
    Rex::Logger::info( "FAILURE: $url: " . $resp->status_line );
  }

}

sub _get_url {
  my $server   = shift;
  my $command  = shift;
  my $user     = shift;
  my $pw       = shift;
  my $mgr_path = shift;

  $mgr_path ||= "manager";

  return "http://$user:$pw\@" . "$server/$mgr_path/text/$command";
}

sub _do_action {

  my $action   = shift;
  my $path     = shift;
  my $port     = shift;
  my $user     = shift;
  my $pw       = shift;
  my $mgr_path = shift;

  $mgr_path ||= "manager";

  my $ua                 = LWP::UserAgent->new();
  my $current_connection = Rex::get_current_connection();

  my $server = connection->server;
  if ( $server eq "<local>" ) {
    $server = "localhost";
  }

  my $_url =
    _get_url( "$server:$port", "$action?path=$path", $user, $pw, $mgr_path );
  Rex::Logger::debug("Connecting to: $_url");

  my $resp = $ua->get($_url);
  if ( $resp->is_success ) {
    Rex::Logger::info( $resp->decoded_content );
  }
  else {
    Rex::Logger::info( "FAILURE: $_url: " . $resp->status_line );
  }

}

############ configuration functions #############

=item context_path($path)

This function sets the context path for the application that gets deployed. This is a global setting. If you want to specify a custom context path for your application you can also do this as an option for the I<deploy> function.

 context_path "/myapp";

=cut

sub context_path {
  $context_path = shift;
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
