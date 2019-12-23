#!/usr/bin/env perl

#ABSTRACT: script to update the rules within the mysql database
#PODNAME: ossec-update-rules-database.pl
use strict;
use warnings;
use File::Basename;
use OSSEC;
use XML::LibXML;
use Try::Tiny;

my $ossec = OSSEC->new();
my $mysql = $ossec->mysql();

# clear rules from database
$mysql->deleteAllRules();

my @includes = $ossec->config()->getElementsByTagName("include");

for my $i (@includes)
{
  if (! -e $ossec->ossecPath() . "/rules/" . $i->textContent)
  {
    warn($i . " not found\n");
  }
  else
  {

    readpipe("echo \"<root>\" > /tmp/".$i->textContent);
    readpipe("cat " . $ossec->ossecPath() . "/rules/" . $i->textContent . ">> /tmp/".$i->textContent);
    readpipe("echo \"</root>\" >> /tmp/".$i->textContent);
    readpipe("sed -i '/pcre2/d' /tmp/".$i->textContent );

    open(my $fh, '<', "/tmp/" . $i->textContent);
    binmode $fh;
    my $ruleFile;

    my $parser = XML::LibXML->new;
    $parser->set_option("pedantic_parser",0);
    $parser->set_option("validation", 0);
    $parser->set_option("recover",1);

    try {
      $ruleFile = $parser->load_xml(IO => $fh);
    } catch {
      warn("Error parsing " . $i->textContent . ": $_\n");
    };
    close $fh;

    my @rules = $ruleFile->getElementsByTagName("rule");

    for my $r (@rules)
    {
      my $rule = {};
      my $description;
      if ($r->getElementsByTagName("description"))
      {
        $description = $r->getElementsByTagName("description")->[0]->textContent;
      }
      else
      {
        $description  = "unknown";
      }

      $mysql->addRule($r->getAttribute("id"), $r->getAttribute("level"), $description);
    }

  }

}

__END__

=pod

=encoding UTF-8

=head1 NAME

ossec-update-rules-database.pl - script to update the rules within the mysql database

=head1 VERSION

version 0.1

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
