#!/usr/bin/perl

# -----------------------------------------------------------------------------
#
#  Nes by Skriptke
#  Copyright 2009 - 2010 Enrique F. Castañón Barbero
#  Licensed under the GNU GPL.
#
#  CPAN:
#  http://search.cpan.org/dist/Nes/
#
#  Sample:
#  http://nes.sourceforge.net/
#
#  Repository:
#  http://github.com/Skriptke/nes
# 
#  Version 1.03
#
#  date_time.pl
#
# -----------------------------------------------------------------------------

use Nes;
use strict;
use POSIX qw(strftime);

my $nes = Nes::Singleton->new('./date_time.html');
my $q   = $nes->{'query'}->{'q'};
my $local_gmt = $q->{'local_gmt'} || $q->{'date_time_param_1'} || shift @ARGV || 'local';
my $format    = $q->{'format'}    || $q->{'date_time_param_2'} || "@ARGV"     || '%a %e %b %Y %H:%M:%S';

my $tags = {};
$tags->{'date_time'} = POSIX::strftime( "$format", localtime ); # default
$tags->{'date_time'} = POSIX::strftime( "$format", gmtime )     if $local_gmt =~ /gmt/i;

# determine CGI Environment
if ( $ENV{'REMOTE_ADDR'} || $ENV{'REMOTE_HOST'} || $ENV{'SCRIPT_NAME'} ) {
  # CGI
  $nes->out(%$tags);
} else {
  # command line
  print $tags->{'date_time'},"\n";
}


# don't forget to return a true value from the file
1;

