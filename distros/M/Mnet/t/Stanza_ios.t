
# purpose: test Mnet::Stanza::ios function

# required modules
use warnings;
use strict;
use Mnet::Stanza;
use Test::More tests => 5;

# init test show running-config output
my $sh_run = "
    Building configuration...

    Current configuration : 1054 bytes
    !
    version 12.2
    !
    hostname router
    no ip domain-lookup
    !
    class-map match-any test
     match access-group name test
    !
    policy-map qos
      class test
       set ip dscp af11
    !
    interface FastEthernet0/0
     description extra  spaces
     ip address 1.2.3.4 255.255.255.0
     service-policy input qos
     no shutdown
    !
    access-list 1 permit ip any any
    access-list 1 deny ip any any
    !
    ip access-list spaces
     remark spa  ces
    !
    ip access-list test
     permit ip any any
     deny ip any any
    !
    line con 0
     password secret
    !
    end
";

# check remove line
#   remove a line, a line starting with 'no', and using the '*!*' wildcard
#   also test removing a line already removed, and a list that was not present
Test::More::is(
    Mnet::Stanza::ios("
        -hostname router
        -no ip domain-lookup
        -access-list 1 *!*
        -access-list 1 deny ip any any
        -ip http server
    ", $sh_run), Mnet::Stanza::trim("
        no hostname router
        ip domain-lookup
        no access-list 1 permit ip any any
        no access-list 1 deny ip any any
    ") . "\n", "remove"
);

# check add line
#   check for line that is already present, and one that is not
#   check that we won't remove already processed lines
Test::More::is(
    Mnet::Stanza::ios("
        +hostname router
        +ip domain test.local
        -ip domain test.local
        -ip domain *!*
        -hostname router
        -hostname *!*
    ", $sh_run), Mnet::Stanza::trim("
        ip domain test.local
    ") . "\n", "add"
);

# check match stanza
#   check that we won't remove already processed lines
Test::More::is(
    Mnet::Stanza::ios("
        =class-map match-any test
         =match access-group 1
        =policy-map qos
          =class test
           =set ip dscp af11
        -class-map match-any test
    ", $sh_run), Mnet::Stanza::trim("
        class-map match-any test
         match access-group 1
    ") . "\n", "match"
);

# check find stanza
#   check stanza lines not needing to change, and needing to add/remove lines
#   check nested stanzas, adding lines to new stanza, finds nothing underneath
#   check that we won't remove already processed lines
Test::More::is(
    Mnet::Stanza::ios("
        >class-map match-any test
         +match access-group name test
         -match access-group 1
        >interface FastEthernet0/0
         -ip address *!*
         +service-policy qos out
        >interface Vlan1
         +shutdown
        >policy-map qos
          >class test
           +set ip dscp af12
        >ip access-list test
        >non-existant
        -class-map match-any test
        -interface FastEthernet0/0
        -interface Vlan1
        -policy-map qos
        -ip access-list test
    ", $sh_run), Mnet::Stanza::trim("
        interface FastEthernet0/0
         no ip address 1.2.3.4 255.255.255.0
         service-policy qos out
        interface Vlan1
         shutdown
        policy-map qos
          class test
           set ip dscp af12
    ") . "\n", "find"
);

# check handling of extra spaces when wildcard-removing description/remark cmds
#   need to be sure that original text is echo'd back, with spaces preserved
Test::More::is(
    Mnet::Stanza::ios("
        >interface FastEthernet0/0
         -description *!*
        >ip access-list spaces
         -remark *!*
    ", $sh_run),
        "interface FastEthernet0/0\n no description extra  spaces\n"
        . "ip access-list spaces\n no remark spa  ces\n",
    "spaces"
);

# finished
exit;

