#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Std qw{getopts};
use DateTime;
use SMS::Send::VoIP::MS;

my $opt      = {};
getopts('u:p:f:d', $opt); #debug
my $syntax   = qq{$0 [-u username] [-p password] [-f from_phone] [-d] to_phone "text"\n};
my $username = $opt->{'u'}; #default undef from INI file
my $password = $opt->{'p'}; #default undef from INI file
my $from     = $opt->{'f'}; #default undef from INI file
my $debug    = $opt->{'d'} ? 1 : 0;
my $to       = shift or die($syntax);
my $text     = shift or die($syntax);
my $service  = SMS::Send::VoIP::MS->new(username=>$username, password=>$password, did=>$from);
my $status   = $service->send_sms(
                                  to   => $to,
                                  text => $text,
                                 );
if ($debug) {
  require Data::Dumper;
  print Data::Dumper::Dumper($service->{'__data'});
  print '+' x 80, "\n", $service->{'__content'}, "\n", '-' x 80, "\n";
}

printf "%s: Phone: %s, Text: %s, Status: %s\n", DateTime->now, $to, $text, $status;

exit 1 unless $status;

__END__

=head1 NAME

perl-SMS-Send-VoIP-MS-send_sms.pl - SMS::Send::VoIP::MS Example script


=head1 SYNOPSIS

Settings from /etc/SMS-Send.ini

  perl-SMS-Send-VoIP-MS-send_sms.pl to_phone "text"

Settings from command line

  perl-SMS-Send-VoIP-MS-send_sms.pl [-u username] [-p password] [-f from_phone] to_phone "text"

Debug

  perl-SMS-Send-VoIP-MS-send_sms.pl [-d] to_phone "text"

=head1 OPTIONS

=over 4

=item B<-u> Username

Username of the account

=item B<-p> Password

Password of the account

=item B<-f> From_Phone

The phone number to send the SMS from.  Passed as "did" on the URL.

=item B<-d>

Debug Flag to print service return

=back

=cut
