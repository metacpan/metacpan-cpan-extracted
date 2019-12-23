#!/usr/bin/env perl

#ABSTRACT: script to update the agents within the mysql database
#PODNAME: ossec-update-agents-database.pl
use strict;
use warnings;
use File::Basename;
use OSSEC;
use XML::LibXML;
use Try::Tiny;

my $ossec = OSSEC->new();
my $mysql = $ossec->mysql();

# clear rules from database
$mysql->deleteAllAgents();

my $help = readpipe($ossec->ossecPath()."/bin/agent_control -l");
my @lines = split /\n/, $help;


for my $l (@lines)
{
  if ($l =~ /^\s*ID:\s(\d+)/)
  {
    my $help = readpipe($ossec->ossecPath()."/bin/agent_control -i $1");
    my @lines = split /\n/, $help;
    my $name;
    my $ip;
    my $version;
    my $information;

    for my $l2 (@lines)
    {
      if ($l2 =~ /Name:\s+(\S+)/)
      {
        $name = $1;
      }

      if ($l2 =~ /IP.*:\s+(\S+)/)
      {
        $ip   = $1;
      }

      if ($l2 =~ /version:\s+OSSEC\sHIDS\sv(\S+)/)
      {
        $version = $1;
      }

      if ($l2 =~ /system:\s+(.*)$/)
      {
        $information=$1;
      }
    }

    $mysql->addAgent("1", 0, $ip, $version,$name, $information );

  }
}

__END__

=pod

=encoding UTF-8

=head1 NAME

ossec-update-agents-database.pl - script to update the agents within the mysql database

=head1 VERSION

version 0.1

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
