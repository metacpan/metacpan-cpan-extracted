# -*- perl -*-
#
#   $Id: test.pl,v 1.2 1999/01/29 20:15:39 joe Exp $
#
#
#   Net::Nessus - a set of Perl modules for working with the
#                 nessus program
#
#
#   The Net::Nessus package is
#
#       Copyright (C) 1998      Jochen Wiedmann
#                               Am Eisteich 9
#                               72555 Metzingen
#                               Germany
#
#                               Phone: +49 7123 14887
#                               Email: joe@ispsoft.de
#
#
#   All rights reserved.
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
############################################################################
#
#   This script is a simple Nessus Client.
#
############################################################################

my $numTests = 6;


use strict;
use Getopt::Long();
use ExtUtils::MakeMaker();


$| = 1;
$^W = 1;


my $cfg = eval { require ".status" } || {};
my $o =
    { 'nessus-host' => $cfg->{'nessus_host'},
      'nessus-port' => $cfg->{'nessus_port'},
      'nessus-user' => $cfg->{'nessus_user'},
      'nessus-password' => $cfg->{'nessus_password'},
      'attack-host' => '127.0.0.1',
      'nessus-proto' => '1.1'
    };

print qq[

This script can launch a Nessus Client for you. You can do the same from
the command line later. Use it by executing the 'nessusc' script, for
example the following would be used to advice the Nessus server on
host 127.0.0.1, port 1241 to attack host 192.168.1.4, you would use

    nessusc --target="192.168.1.4" --host=$o->{'nessus-host'}
       --port=$o->{'nessus-port'} --user=$o->{'nessus-user'}
       --password=$o->{'nessus-password'}

If you want to perform a scan now, enter the host name: ];
my $reply = ExtUtils::MakeMaker::prompt("", "none") ;
exit 0 if $reply eq 'none';
$o->{'attack-host'} = $reply;

exec($^X, "-Iblib/arch", "-Iblib/lib", "nessusc",
     "--target=$o->{'attack-host'}", "--host=$o->{'nessus-host'}",
     "--port=$o->{'nessus-port'}", "--user=$o->{'nessus-user'}",
     "--password=$o->{'nessus-password'}");
