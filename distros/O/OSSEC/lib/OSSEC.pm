package OSSEC 0.1;
# ABSTRACT: OSSEC
use strict;
use warnings;
use Moose;
use XML::LibXML;
use Data::Dumper;
use OSSEC::Log;
use OSSEC::MySQL;



has 'ossecPath'   => (is => 'rw', isa => 'Str' , default => "/var/ossec" );

has 'mysqlAvail'  => (is => 'rw', isa => 'Bool', default => 0);

has 'server' => (is => 'rw', isa => 'Str' , default => "localhost" );

has 'dbuser'      => (is => 'rw', isa => 'Str', default => "ossec");

has 'dbpass'      => (is => 'rw', isa => 'Str');

has 'database'    => (is => 'rw', isa => 'Str', default => "ossec");

has 'config'      => (is => 'rw', isa => 'XML::LibXML::Document');

sub BUILD
{
  my $self = shift;
  my $param = shift;

  if (!$param->{ossecPath})
  {
    $param->{ossecPath} = "/var/ossec";
  }

  die("ossec base path not correctly given") unless -e ($param->{ossecPath});
  die("ossec configuration file not found at " . $param->{ossecPath}."/etc/ossec.conf")  unless -e ($param->{ossecPath}."/etc/ossec.conf");

  # now load ossec configuration file
  open(my $fh, '<', $param->{ossecPath}."/etc/ossec.conf");
  binmode $fh;
  $self->config(XML::LibXML->load_xml(IO => $fh));
  close $fh;

  # parse database specific configuration
  my @databases = $self->config()->getElementsByTagName("database_output");

  if (@databases == 0)
  {
    $param->{mysqlAvail} = 0;
  }
  else
  {
    $self->mysqlAvail(1);
    my @node = $databases[0]->getElementsByTagName("hostname");
    if (@node)
    {
      $self->server($node[0]->textContent);
    }

    @node = $databases[0]->getElementsByTagName("username");
    if (@node)
    {
      $self->dbuser($node[0]->textContent);
    }

    @node = $databases[0]->getElementsByTagName("password");
    if (@node)
    {
      $self->dbpass($node[0]->textContent);
    }

    @node = $databases[0]->getElementsByTagName("database");
    if (@node)
    {
      $self->database($node[0]->textContent);
    }


  }



}



sub arLog
{
  my $self = shift;

  return OSSEC::Log->new(ossecPath => $self->ossecPath(), file => "logs/active-responses.log");
}



sub mysql
{
  my $self = shift;
  my $mysql = OSSEC::MySQL->new(server => $self->server(), dbuser => $self->dbuser(), dbpass => $self->dbpass(),
                           database => $self->database());

  $mysql->connect();

  return $mysql;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OSSEC - OSSEC

=head1 VERSION

version 0.1

=head1 DESCRIPTION

The OSSEC distribution is a collection of perl modules and scripts
simplifying working with OSSEC(https://www.ossec.net/) from Perl.

This is the main module of the OSSEC distribution.
It provides OSSEC configuration file parsing to read database credentials from it.

Using methods of the OSSEC module makes sure that the base path to OSSEC
is always set in the other modules.

=head1 ATTRIBUTES

=head2 ossecPath

Base path to the OSSEC installation. B<default> /var/ossec

Type: String

=head2 mysqlAvail

Have database credentials been found when parsing the OSSEC configuration file

Type: Boolean (0/1)

=head2 server

database server to conect to B<default> localhost

Type: String

=head2 dbuser

database user to use to connect to server B<default> ossec

Type: String

=head2 dbpass

database password to use to connect to server

Type: String

=head2 database

database to use to connect to server B<default> ossec

Type: String

=head2 config

XML::LibXML::Document object of the ossec configuration file

Type: XML::LibXML::Document

=head1 METHODS

=head2 BUILD

Method is called before constructing the object with new.
It checks if a OSSEC configuration file can be found,
loads it and checks if database credentials are available.

=head2 arLog

Method to simplify obtaining an OSSEC::Log instance for logging active response
actions.

no parameters are required

=over

=item B<return>: I<OSSEC::Log>

=back

=head2 mysql

Method to simplify obtaining an OSSEC::MySQL instance. This method makes sure that
all database parameters from the OSSEC configuration file are provided to OSSEC::MySQL
without user support.

no parameters are required

=over

=item B<return>: I<OSSEC::MySQL>

=back

=head1 EXAMPLE

  use strict;
  use warnings;
  use OSSEC;
  use Try::Tiny;
  use Data::Dumper;

  # get an OSSEC instance with the default OSSEC path (/var/ossec)
  my $ossec = OSSEC->new();

  # check if mysql is available
  die("no mysql") unless $ossec->mysqlAvail();

  # get us logging for active response
  my $log  = $ossec->arLog();

  # log something
  $log->info("test-active-response", "we are just testing");

  # search for an alert
  my $mysql = $ossec->mysql();

  my $alert;
  try {
    $alert = $mysql->searchAlert("1576795884.47756102");
  } catch {
    die("Error occured or no alert found: " . $_);
  };

  print Dumper($alert);

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
