#!/usr/bin/perl -w

use strict;
use lib 'lib';
use lib '../openframe3/lib';
use lib '../Vx/lib';
use Cwd;
use OpenFrame;
use Getopt::Long;
use Sys::Hostname;

$SIG{INT} = \&quit;

my $CWD = cwd;
my $port = 7500 + $<; # give every user a different port
my $hostname = hostname;

my $HTTPD;
my @HTTPDS = (
  "/usr/local/apache_perl/bin/httpd",
  "../../../apache_perl/bin/httpd",
  "../../apache_perl/bin/httpd",
  "/usr/local/apache/bin/httpd",
  "../../apache/bin/httpd",
  "../apache/bin/httpd",
  $ENV{'TEST_APACHE'},
);
foreach (@HTTPDS) {
  next unless -f $_;
  $HTTPD = $_;
  last;
}

if (not defined $HTTPD) {
  warn "This script failed to find an Apache binary\n";
  warn "Change \@HTTPDS in apache.pl to point to a working Apache binary.\n";
  warn "Or define \$ENV{'TEST_APACHE'}.\n";
  exit;
}


my $DEFAULTCONF = "$CWD/apache/conf/httpd.conf.default";
my $NEWCONF = "$CWD/apache/conf/httpd.conf";

open(IN, $DEFAULTCONF) || die $!;
open(OUT, "> $NEWCONF") || die $!;
while (<IN>) {
  s/\@\@CWD\@\@/$CWD/g;
  s/\@\@PORT\@\@/$port/g;
  print OUT;
}
close IN;
close OUT;

system "$HTTPD -f $NEWCONF";

print "Point your browser at the following URL to see the website:\n";
print "http://$hostname:$port/\n";
sleep 100 while 1; # sleep for a long time

# When the user hits control-C we shut down the httpds we started up
sub quit {
  print "Killing apache...\n";
  open(IN, "$CWD/apache/logs/httpd.pid") || die $!;
  my $pid = <IN>;
  kill -2, $pid;
  close IN;
  exit;
};




__END__

=head1 NAME

website.pl - Run a small website through Apache

=head1 DESCRIPTION

Run the script and point your favourite web browser at the URL that it
reports.

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright (C) 2002, Fotango Ltd.

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

