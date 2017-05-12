use strict;
use Net::SMS::Clickatell;
use Getopt::Std;

# Usage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]
# where [user] is your Clickatell username
#       [password] is your Clickatell password
#       [a] is your Clickatell API id
#       [mobile phone number] is the destinary
#       [message] your message
my %args;
getopts("u:p:a:",\%args);

# Check arguments
# Check credentials
if(!exists $args{u} || !exists $args{p}) {
  print "\nUsage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]\nYou don't specified valid credentials\n";
  exit(0);
}
# Check API id
if(!exists $args{a}) {
  print "\nUsage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]\nYou don't specified valid API id\n";
  exit(0);
} elsif($args{a} =~ /\D/) {
  print "\nUsage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]\nYou don't specified valid API id\n";
  exit(0);
}
# Check mobile phone and message
if(!$ARGV[0]) {
  print "\nUsage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]\nYou don't specified destinatary and message\n";
  exit(0);
} elsif($ARGV[0] =~ /\D/) {
  print "\nUsage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]\nYou don't specified a valid mobile phone number\nFormat: International code + mobile phone number without leading zeros. Don't write the '+'\n";
  exit(0);
} elsif(!$ARGV[1]) {
  print "\nUsage: perl sendsms.pl -u [user] -p [passwd] -a [API id] [mobile phone number] [message]\nYou don't specified message\n";
  exit(0);
}

# Create Clickatell object
my $catell = Net::SMS::Clickatell->new(UseSSL => 1,API_ID => $args{a});

# Log in
if($catell->auth(USER => $args{u}, PASSWD => $args{p})) {
  $catell->sendmsg(TO => $ARGV[0], MSG => $ARGV[1]);
  if($catell->msg_id) {
    print "Message ".$ARGV[1]." sent.\n";
  } else {
    print "Your message couldn't be sent.\n";
  }
} else {
  print "Wrong credentials\n";
}
