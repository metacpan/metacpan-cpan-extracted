#!/usr/bin/perl
#
# Simple POP3-tester
# (c) alex pleiner, zeitform Internet Dienste 2001, 2003
# alex@zeitform.de
#
# this tool will connect to a POP3 Server and authenticate using
# PLAIN user/pass authentication, APOP or any supported SASL
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
my $default_host = 'mail.zeitform.de';
my $default_user = 'alex@zf2.de';
my $default_auth = 'CRAM-MD5';   # try NONE, PLAIN or LOGIN
###############################################

use Getopt::Std;
use Net::POP3_auth;

print "-"x70,
      "\npop3-tester (c) alex pleiner, zeitform Internet Dienste 2001, 2003\n",
      "usage: pop3test [-v] -h host -m method -u user -p password\n\n";

getopts('vh:u:p:m:');

### get user data and connect

my $debug = 1 if $opt_v;
my $host  = $opt_h || get_value("POP3 Server", $default_host);
my $user  = $opt_u || get_value("username   ", $default_user);

my $pop   = Net::POP3_auth->new($host, Timeout => 60, Debug => $debug);
print "possible auth-types are: ", scalar($pop->auth_types()), "\n";

my $auth  = $opt_m || get_value("AUTH method", $default_auth);
my $pass  = $opt_p || get_value("password   ", "", 1);

### authenticate

print "\n", "-"x70, "\nPOP3 (AUTH $auth) on $host ($user) ...\n";

my $ok = $pop->auth($auth, $user, $pass) or print "failed\n";
my $message = $pop->message();  chomp ($message);

$pop->quit();

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



