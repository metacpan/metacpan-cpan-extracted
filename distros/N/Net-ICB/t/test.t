# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use Net::ICB qw(:client);
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub ok
{
    my $no = shift ;
    my $result = shift ;
 
    print "not " unless $result ;
    print "ok $no\n" ;
}

# Check the version.
ok 2, $Net::ICB::VERSION eq '1.6';

my $obj;
my ($type, @split);

# Make a bad connection to some host.
eval '$obj = new Net::ICB("host" => "nosuchhost")';
ok 3, !ref($obj);

# Create an unconnected object.
eval '$obj = new Net::ICB()';
ok 4, ref($obj) eq 'Net::ICB';
ok 5, $obj->version eq '1.6';

# Check error for bad hostname.
eval '$obj->connect("host" => "nosuchhost")';
ok 6, $obj->error() =~ /Bad hostname 'nosuchhost'/;

# Check error for bad port.
eval '$obj->connect("host" => "localhost", "port" => 0)';
ok 7, $obj->error() =~ /Connection refused/;

# Check clearerr() method.
eval '$obj->clearerr()';
ok 8, !$obj->error();

# Make a real connection to the server.
eval '$obj->connect("host" => "default.icb.net", "group" => "test", "user" => "U" . substr(rand(), 2, 5))';
ok 9, ref $obj->fd;

# Look for protocol packet.
eval '($type, @split) = $obj->readmsg()';
ok 10, $type eq $M_PROTO;

# Look for login packet.
eval '($type, @split) = $obj->readmsg()';
ok 11, $type eq $M_LOGINOK;

# Send a private message.
eval '$obj->sendpriv($obj->{user}, "TEST")';
ok 12, !$obj->error();

# Read motd, etc until we get the private message.
do {
	($type, @split) = $obj->readmsg();
} until ($type eq $M_PERSONAL);

# Check for size and correct data.
ok 13, @split == 2;
ok 14, $split[1] eq "TEST";

# Send a big string (260 chars) to ourselves.
eval '$obj->sendpriv($obj->{user}, "1234567890" x 26)';
ok 15, $obj->error() =~ /packet > 255 bytes/;
eval '$obj->clearerr()';

# Send the maximum string we can, 251 bytes (cmd|m|DEL|DATA[251]|null).
eval '$obj->sendpriv(substr("$obj->{user} "."1234567890" x 26, 0, 251))';
ok 16, !$obj->error();

# Read a string clipped to 253 chars (type|DATA[251]|null).
($type, @split) = $obj->readmsg();
ok 17, length($split[0]) + length($split[1]) == 250;

# Send a beep.
eval '$obj->sendcmd("beep", $obj->{user})';
ok 18, !$obj->error();

# Read our beep.
($type, @split) = $obj->readmsg();
ok 19, $type eq $M_BEEP;

