# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..9\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::APP;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num: $msg $@\n");
}

sub input {
  my $prompt = shift;
  print $prompt;
  chomp ( my $input = scalar(<STDIN>) );
  $input;
}

print <<END;
In order to test Net::APP, you need a cleartext APP server available, i.e. a
Safe Passage or tunnel or Stunnel <http://www.stunnel.org>, and an account on
the APP server.

(i.e. stunnel -P none -c -d 8888 -r appsandbox.criticalpath.net:8889)

END

my $hostname = input "Enter the local (cleartext) APP proxy hostname or IP: ";
my $port = input "Enter the local (cleartext) APP proxy port number: ";
my $user = input "Enter your APP username: ";
my $domain = input "Enter your APP domain: ";

system("stty -echo");
my $password = input "Enter your APP password: "; 
print "\n\n"; system("stty echo");

test 2, my $app = new Net::APP ( "$hostname:$port",
                                  Debug => 0,
                                );
test 3, $app->login( User => $user,
                     Domain => $domain,
                     Password => $password,
                   );
test 4, $app->code == 0;
test 5, $app->quit;
test 6, $app->code == 0;
$app->close();
undef $app;
test 6, $app = new Net::APP ( "$hostname:$port",
                              Debug => 0,
                              User => $user,
                              Domain => $domain,
                              Password => $password,
                            );
test 7, $app->code == 0;
test 8, $app->quit;
test 9, $app->code == 0;
$app->close();
undef $app;


