#!/usr/bin/perl -w

use strict;
use lib 'lib';
use lib '../openframe3/lib';
use lib '../Vx/lib';
use Cwd;
use OpenFrame;
use Getopt::Long;
use Sys::Hostname;
use Template;


my $cwd = cwd;
my $port = 7500 + $<; # give every user a different port
my $hostname = hostname;

my $httpd;
my @httpds = (
  "/usr/local/apache2/bin/httpd",
  "$ENV{HOME}/apache2/bin/httpd",
);
foreach (@httpds) {
  next unless -f $_;
  $httpd = $_;
  last;
}

if (not defined $httpd) {
  warn "This script failed to find an Apache2 binary\n";
  warn "Change \@httpds in apache.pl to point to a working Apache2 binary.\n";
  exit;
}

my $mod_perl = $httpd;
$mod_perl =~ s{/bin/httpd}{/modules/mod_perl.so};

my($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid($<);
my $user  = getpwuid($uid);
my $group = getgrgid($gid);


my $default_conf = "$cwd/apache/conf/httpd.conf.default";
my $new_conf     = "$cwd/apache/conf/httpd.conf";
my $default_ctl = "$cwd/apache/bin/apachectl.default";
my $new_ctl     = "$cwd/apache/bin/apachectl";
my $default_startup = "$cwd/apache/bin/startup.pl.default";
my $new_startup     = "$cwd/apache/bin/startup.pl";

my $vars = {
  cwd => $cwd,
  port => $port,
  user => $user,
  group => $group,
  httpd => $httpd,
  mod_perl => $mod_perl,
  conf => $new_conf,
};

my $tt = Template->new({
  ABSOLUTE => 1,
});

$tt->process($default_conf, $vars, $new_conf) || die $tt->error(), "\n";
$tt->process($default_ctl, $vars, $new_ctl) || die $tt->error(), "\n";
$tt->process($default_startup, $vars, $new_startup) || die $tt->error(), "\n";
chmod 0755, $new_ctl;

my $mode = shift() || '';
if ($mode eq 'exit') {
  # don't start the servers if we're being run by the test suite
  exit;
}

$SIG{INT} = \&quit;
system "$new_ctl start";

print "Point your browser at the following URL to see the website:\n";
print "http://$hostname:$port/\n";
sleep 100 while 1; # sleep for a long time

# When the user hits control-C we shut down the httpds we started up
sub quit {
  system "$new_ctl stop";
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

