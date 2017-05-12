#!/usr/bin/perl
#
# Simple SMTP-tester
# (c) alex pleiner, zeitform Internet Dienste 2001, 2003
# alex@zeitform.de
#
# this tool will connect to a SMTP Server and authenticate using
# either no authentication or SMTP_AUTH (RFC2554)
#
# LICENSE:
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# Get the GPL from: http://www.gnu.org/licenses/gpl.html

###############################################
my $default_host     = 'mail.zeitform.de';
my $default_touser   = 'alex@zf2.de';
my $default_fromuser = 'alex@zf2.de';
my $default_auth     = 'CRAM-MD5';      # try NONE, PLAIN or LOGIN
###############################################

use lib "/home/ciphelp/perl";

use Getopt::Std;
use Net::SMTP_auth;

print "-"x70, 
      "\nsmtp-tester (c) alex pleiner, zeitform Internet Dienste 2001, 2003\n",
      "usage: smtptest [-v] -h host -m method -t recipient -f sender/local -p password\n\n";

getopts('vh:t:f:p:m:');

my $debug    = 1 if $opt_v;
my $host     = $opt_h || get_value("SMTP Server  ", $default_host);
my $touser   = $opt_t || get_value("recipient    ", $default_touser);
my $fromuser = $opt_f || get_value("sender/local ", $default_fromuser);

## show auth methods
my $smtp = Net::SMTP_auth->new($host, Timeout => 60, Hello => "me", Debug => $debug);
print "possible auth-types are: NONE ", scalar($smtp->auth_types()), "\n";

my $auth = $opt_m || get_value("AUTH method", $default_auth);
my $pass = $opt_p || get_value("password   ", "", 1);

### authenticate

print "\n", "-"x70, "\nSMTP (AUTH $auth) on $host ($fromuser -> $touser)...\n";

if (uc($auth) ne "NONE") {
  $ok = $smtp->auth($auth, $fromuser, $pass);
  $message = $smtp->message();  chomp ($message);
} else { $ok = 1; }


if ($ok) {
  $ok = $smtp->mail($fromuser);
  $message = $smtp->message();  chomp ($message);
  if ($ok) {
    $ok = $smtp->to($touser);
    $message = $smtp->message();  chomp ($message);
  }
}

$smtp->quit;

if ($ok) { print "... works fine\n"; }
else     { print "... failed with message:\n$message\n"; }

print "-"x70, "\n";

### sub land

sub get_value
  {
    my ($text, $default, $noecho) = @_;
    print "$text [$default]: ";
    system "stty -echo" if $noecho;
    my $value= <>;
    system "stty echo" if $noecho;
    chomp $value;
    return $value || $default;
  }

###-fin-









