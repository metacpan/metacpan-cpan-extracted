#!/usr/bin/perl
use strict;
use warnings;
use Mail::Sender;
use File::Basename 'dirname';

# A bit of configuration: the recipient of the notification
my $recipient
   = '"Traduttori pod2it" <pod2it-translators@lists.sourceforge.net>';
#    = '"Flavio Poletti" <flavio@polettix.it>';

# Make sure we're in the correct directory
chdir dirname($0);

# Issue a cvs update command and grab output, ignore STDERR
my $cvs_output = qx{ /usr/bin/cvs update -I update.pl 2>/dev/null };

# Exit immediately if there's nothing interesting
exit 0 unless length $cvs_output;

# Grab logs for last day and filter out unneeded stuff
my $cvs_log;
open my $logfh, ">", \$cvs_log
   or die "open() on string: $!";
open my $cvsfh, "cvs log -S -d '>1 day ago' 2>/dev/null |"
   or die "open(): $!";
my $in_description = undef;
INPUT:
while (<$cvsfh>) {
   if ($in_description) {
      $in_description = ! /\A =+ \Z/x;
      print {$logfh} $_;
   }
   else {
      $in_description = /\A description /x;
      next INPUT unless /\A (?: RCS\ file | head | \s*\z) /xms;
      print {$logfh} $_;
   }
}
close $cvsfh;
close $logfh;

# Send e-mail with notification of changes
my $mailer = Mail::Sender->new({ smtp => 'localhost' });
$mailer->MailMsg({
   from     => '"Flavio Poletti" <flavio@polettix.it>',
   to       => $recipient,
   subject  => "Progetto pod2it: cambiamenti in CVS",
   msg      => "Ciao a tutti,\n\n"
          . "\tl'ultimo 'update' ha evidenziato i seguenti cambiamenti:\n\n"
          . $cvs_output
          . "\n\n"
          . $cvs_log
          . "\nCiao,\n\tFlavio.",
});
