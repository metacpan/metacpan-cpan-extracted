#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std qw{getopts};
use DateTime;
use SMS::Send::Kannel::SMSbox;

my $opt       = {};
getopts("h:u:p:", $opt); #debug
my $host      = $opt->{"h"}; #default undef from INI file
my $username  = $opt->{"u"}; #default undef from INI file
my $password  = $opt->{"p"}; #default undef from INI file
my $syntax    = qq{$0 [-h host] [-u username] [-p password] phone "text"\n};
my $to        = shift or die($syntax);
my $text      = shift or die($syntax);

my $service   = SMS::Send::Kannel::SMSbox->new(host=>$host, username=>$username, password=>$password);

my $status    = $service->send_sms(
                                   to   => $to,
                                   text => $text,
                                  );
printf "%s: Phone: %s, Text: %s, Status: %s\n", DateTime->now, $to, $text, $status;

__END__

=head1 NAME

perl-SMS-Send-Kannel-SMSbox-send_sms.pl - SMS::Send::Kannel::SMSbox Example script

=cut
