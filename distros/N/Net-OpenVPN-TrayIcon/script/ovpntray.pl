#!/usr/bin/perl

use 5.010;
use warnings;
use Net::OpenVPN::TrayIcon;
use Proc::Daemon;

my $trayicon = Net::OpenVPN::TrayIcon->new;
$trayicon->run;

exit 0;

