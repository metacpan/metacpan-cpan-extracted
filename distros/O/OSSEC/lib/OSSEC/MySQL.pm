package OSSEC::MySQL 0.1;

# ABSTRACT: Module for getting information from the OSSEC Mysql Database
use strict;
use warnings;
use Moose;
use OSSEC::Log;
use DBI;
use DBD::mysql;
use DateTime;


has 'server' => (is => 'rw', isa => 'Str' , default => "localhost" );

has 'dbuser'      => (is => 'rw', isa => 'Str', default => "ossec");

has 'dbpass'      => (is => 'rw', isa => 'Str');

has 'database'    => (is => 'rw', isa => 'Str', default => "ossec");

has 'dbh'    => (is => 'rw');

sub connect
{
  my $self  = shift;

  die("no server given") unless $self->server();
  die("no user given") unless $self->dbuser();
  die("no password given") unless $self->dbpass();
  die("no database given") unless $self->database();

  my $dsn = "DBI:mysql:database=" . $self->database() . ";host=" . $self->server() . ";port=3306";

  $self->dbh(DBI->connect($dsn, $self->dbuser(), $self->dbpass),{'RaiseError' => 1});
}


sub deleteAllRules
{
  my $self = shift;

  $self->dbh()->do("delete from signature");
}



sub addRule
{
  my $self    = shift;
  my $ruleid  = shift;
  my $level   = shift;
  my $desc    = shift;

  my $sth     = $self->dbh()->prepare("insert into signature(rule_id,level,description) values(?,?,?)");
  $sth->execute($ruleid, $level, $desc);
  $sth->finish;

}

sub deleteAllAgents
{
  my $self = shift;

  $self->dbh()->do("delete from agent");
}

sub addAgent
{
  my $self        = shift;
  my $server_id   = shift;
  my $last_contact= shift;
  my $ip_address  = shift;
  my $version     = shift;
  my $name        = shift;
  my $information = shift;


  my $sth     = $self->dbh()->prepare("insert into agent(server_id, last_contact, ip_address,
                                       version, name, information) values(?,?,?,?,?,?)");
  $sth->execute($server_id, $last_contact, $ip_address, $version, $name, $information);
  $sth->finish;

}

sub searchAlert
{
  my $self    = shift;
  my $alertid = shift;

  my $sth     = $self->dbh()->prepare("select signature.rule_id as rule_id,
                                              signature.level as level,
                                              signature.description as description,
                                              location.name as location,
                                              timestamp, src_ip,
                                              dst_ip, src_port, dst_port, user, full_log
                                       from alert
                                       left join signature on alert.rule_id = signature.rule_id
                                       left join location on alert.location_id = location.id
                                       where alertid=?");

  $sth->execute($alertid);

  if ($sth->rows != 1)
  {
    $sth->finish;
  }

  die("no alert found") unless $sth->rows > 0;
  die("too many alerts found") unless $sth->rows == 1;


  my $row = $sth->fetchrow_hashref;
  $sth->finish;

  my $dt = DateTime->from_epoch( epoch => $row->{timestamp} );
  $row->{timestamp_string} = $dt->ymd() . " " . $dt->hms();

  if ($row->{location}=~/^\((\S+)\)/)
  {
    $row->{agent}=$1;
  }
  else
  {
    $row->{agent}="server";
  }


  return $row;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OSSEC::MySQL - Module for getting information from the OSSEC Mysql Database

=head1 VERSION

version 0.1

=head1 DESCRIPTION

This Module/Class is part of the OSSEC distribution.
It simplifies querying and working with OSSEC and its MySQL database output.
At the moment you are able to search for an alert given by its id.
Update the signature table within the database, which is not done by the current(3.5.0)
version of OSSEC.

=head1 ATTRIBUTES

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

=head2 dbh

database handle, valid after calling connect

=head1 METHODS

=head2 connect

connect to the database server with the provided information

=head2 deleteAllRules

deletes all rules from the signature table of ossec

=head2 addRule

add a rule to the signature table of ossec

=over

=item B<Param1>=I<the ruleid>

=item B<Param2>=I<level of the rule>

=item B<Param3>=I<description of the rule>

=back

=head2 deleteAllAgents

deletes all agents from the agent table of ossec

=head2 addAgent

add an agent to the agent table of ossec

=over

=item B<Param1>=I<the server_id>

=item B<Param2>=I<last_contact information (epoch)>

=item B<Param3>=I<ip address of the agent>

=item B<Param4>=I<version the agent is using>

=item B<Param5>=I<name of the agent>

=item B<Param6>=I<information of the agent. e.g. OS...)>

=back

=head2 searchAlert

search for a given alertid and return the full alert

=over

=item B<Param1>=I<alertid to search for>

=back

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
