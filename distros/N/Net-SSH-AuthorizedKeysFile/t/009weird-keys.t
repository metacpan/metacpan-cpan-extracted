#
# Test cases for ssh2 keys
#
use Net::SSH::AuthorizedKey;
use Net::SSH::AuthorizedKey::SSH2;
use Test::More;
use Log::Log4perl qw(:easy);
use strict;
use warnings;

# Log::Log4perl->easy_init($DEBUG);

my $offset = tell DATA;
my @data = <DATA>;
plan tests => scalar @data;

seek DATA, $offset, 0;

while(<DATA>) {
    my($key, $comment) = split / ## /, $_;

    chomp $comment;

    my $ssh = Net::SSH::AuthorizedKey->parse($key);

    ok !defined $ssh, "$comment";
}

__DATA__
from="*.onk.com" from="*.onk.com" 1024 37 133009991 abc@foo.com ## spaces between options
AAAAB3NzaC1yc2EU= worp@corp.com ## ssh-2 key without enc algo
AAAAB3NzaC1yc2EU= ## ssh-2 key without enc algo
from="*.onk.com",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,1024 35 1409076329 worp@corp.com ## no space but comma before ssh1 key len
from ="*.onk.com" 1024 35 1743547142167 abc@foo.bar.baz.com ## space before options's "="
63548219 abc@bar.baz.com ## Missing ssh1 keylen
sh-rsa AAAAB3Nz ## Misspelled (sh-rsa) ssh2 algo
ssh-dsa AAAAB3Nz ## Misspelled (ssh-dsa) ssh2 algo
from="abc.com" no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding,command="ls" 1024 35 12923 abc@def.com ## space in options
