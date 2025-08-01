#
# (c) Jan Gehring <jan.gehring@gmail.com>
#

package Rex::Commands::JobControl;

use v5.14.4;
use warnings;

our $VERSION = '1.16.1'; # VERSION

use Rex::Commands;
use YAML;

require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);

@EXPORT = qw(jobcontrol_add_server jobcontrol_next_server);

sub jobcontrol_add_server {
  my (%option) = @_;
  if ( !exists( $ENV{JOBCONTROL_PROJECT_PATH} ) ) {
    Rex::Logger::debug(
      "Can only run on the same host where Rex::JobControl is running.");
    return;
  }

  LOCAL {
    my $ref =
      YAML::LoadFile( $ENV{JOBCONTROL_PROJECT_PATH} . "/project.conf.yml" );
    if ( !exists $ref->{nodes} ) {
      $ref->{nodes} = [];
    }

    push @{ $ref->{nodes} }, {%option};

    YAML::DumpFile( $ENV{JOBCONTROL_PROJECT_PATH} . "/project.conf.yml", $ref );
  };
}

sub jobcontrol_next_server {
  my ($server) = @_;

  if ( !exists( $ENV{JOBCONTROL_PROJECT_PATH} ) ) {
    Rex::Logger::debug(
      "Can only run on the same host where Rex::JobControl is running.");
    return;
  }

  LOCAL {
    open( my $fh, ">", $ENV{JOBCONTROL_PROJECT_PATH} . "/next_server.txt" )
      or die("Can't write nextserver: $!");
    print $fh $server;
    close($fh);
  };
}

1;
