*** Formatted for Perlmonks, read on https://perlmonks.org/?node_id=1223514 ***


Interprocess messaging with Net::Clacks

<p>So, your project is going fine, your codebase is groing fast. But now your have the problem
that some of your processes have to communicate with each other. Maybe, some temperature
sensor needs to report its sensor value every few seconds to the central heating system.
Maybe the central heating system needs to know if the windows are open and close them
before heating the house. Another process wants to count how many times the door has been
opened and log the sum once a minute...</p>

<p>Net::Clacks to the rescue!</p>

<p>The Net::Clacks modules implement a client/server based interprocess messaging. Without going
too much into the internals of the protocol, a client can either send notifications ("event
xy has just happened") or values ("the reading for sensor xy is now 42"). Other clients may (or may not)
choose to listen to those broadcasts.</p>

<p>Net::Clacks also implements Memcached-like value storage and retrieval. So instead of broadcasting,
a value can be stored, read out, incremented, decremented and deleted.</p>

<p><b>A note on security:</b> Currently, the system only implements a shared-secret type thing (all clients in a clacks network use the same
username/password). This will get changed in the future. I'm planning to make it so that you can override the authentication checks with
your own function and return which permissions the client has. But that is not yet implemented.</p>

<p>Let's do a simple example project: Server, chatclient, chatbot and a clock process to trigger some actions at the start of every minute.</p>

<readmore title="Click to see the rest of the rather long post">

<p>First of all, we need a server. For this, we need an XML config file and a bit of Perl code.</p>

<code>
#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 4.1;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

my $isDebugging = 0;
if(defined($ARGV[1]) && $ARGV[1] eq "--debug") {
    $isDebugging = 1;
}

use Net::Clacks::Server;

my $configfile = shift @ARGV;
croak("No Config file parameter") if(!defined($configfile) || $configfile eq '');

my $worker = Net::Clacks::Server->new($isDebugging, $configfile);
$worker->init;
$worker->run;
</code>

<p>And the config (saved as clacks_master.xml, we'll add a slaveserver later on):</p>

<code>
<clacks>
    <appname>Clacks Master</appname>
    <ip>127.0.0.1</ip>
    <port>18888</port>
    <pingtimeout>600</pingtimeout>
    <interclackspingtimeout>60</interclackspingtimeout>
    <ssl>
        <cert>exampleserver.crt</cert>
        <key>exampleserver.key</key>
    </ssl>
    <username>exampleuser</username>
    <password>unsafepassword</password>
    <throttle>
        <maxsleep>5000</maxsleep>
        <step>1</step>
    </throttle>
    <hosts>
        <developmentbox>
            <ip>128.0.0.1</ip>
            <ip>::1</ip>
        </developmentbox>
    </hosts>
</clacks>
</code>

<p>Oh, and yes, we need an OpenSSL certificate as well. For this demo we will make a self signed one. Not very secure,
but sufficient for a proof of concept:</p>

<code>
openssl req -new -newkey rsa:4096 -x509 -sha256 -days 36500 -nodes -out exampleserver.crt -keyout exampleserver.key
</code>

<p>Now let's start the server:</p>

<code>
perl server.pl clacks_master.xml
</code>

<p>First client will be the "clock.pl" process, this is basically a "write only" thing, it only sends a notify() to all
clients listening to it at the start of every minute.</p>

<code>
#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 4.1;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use Term::ReadKey;
use Time::HiRes qw(sleep);
use Data::Dumper;

my $username = 'exampleuser';
my $password = 'unsafepassword';
my $applicationname = 'clock';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 18888, $username, $password, $applicationname, $is_caching);

my $clockname = 'example::notify';

my $last = '';

while(1) {
    my $now = getCurrentMinute();
    if($now ne $last) {
        $chat->notify($clockname);
        $chat->ping();
        $last = $now;
    }

    $chat->doNetwork();
    while((my $msg = $chat->getNext())) {
        if($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            last;
        }
    }
    sleep(0.2);
}

sub getCurrentMinute {
    my ($sec,$min, $hour, $mday,$mon, $year, $wday,$yday, $isdst) = localtime time;
    $year += 1900;
    $mon += 1;

    $mon = doFPad($mon, 2);
    $mday = doFPad($mday, 2);
    $hour = doFPad($hour, 2);
    $min = doFPad($min, 2);
    return "$year-$mon-$mday $hour:$min";
}

sub doFPad {
    my ($val, $len) = @_;

    while(length($val) < $len) {
        $val = '0' . $val;
    }

    return $val;
}
</code>

<p>Notice, we also have to send the occasional ping(). This tells the server we are still alive, so it doesn't close the connection. You usually do this
in your main loop. I personally had a bug in which the client kept sending some data while it was stuck in a subroutine, so this is some sort of insurance
that the clients higher brain functions still get called...</p>

<p>Another thing to note is the doNetwork() call. Message sending and receiving over the network doesn't happen automatically, messages get buffered in the client library. This
reduces network traffic when handling lots of small messages by bundling them into bigger packets.</p>

<p>Now, let's do the actual chat client. This is quite similar, except we listen() to some messages at the beginning and also handle the
extra message types. Oh, and of course, take line-by-line user input and send those chat messages to the server.</p>

<code>
#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 4.1;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use Term::ReadKey;
use Time::HiRes qw(sleep);
use Data::Dumper;

my $username = 'exampleuser';
my $password = 'unsafepassword';
my $applicationname = 'chatclient';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 18888, $username, $password, $applicationname, $is_caching);
#print 'Connected to server. Info given: ', $chat->getServerinfo(), "\n";

my $chatname = 'example::chat';
my $clockname = 'example::notify';

$chat->listen($chatname);
$chat->listen($clockname);
$chat->ping();
$chat->doNetwork();

my $nextping = time + 60;

while(1) {
    my $line = ReadLine -1;

    if(defined($line)) {
        chomp $line;
        if(length($line)) {
            last if(uc $line eq 'QUIT' || uc $line eq 'EXIT');
            $chat->set($chatname, $line);
        }
    }
    if($nextping < time) {
        $chat->ping();
        $nextping = time + 60;
    }
    $chat->doNetwork();
    while((my $msg = $chat->getNext())) {
        if($msg->{type} eq 'set' && $msg->{name} eq $chatname) {
            print '>>> ', $msg->{data}, "\n";
        } elsif($msg->{type} eq 'notify' && $msg->{name} eq $clockname) {
            print "*** Another minute has passed ***\n";
        } elsif($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            last;
        }
    }
    sleep(0.2);
}
</code>

<p>At the beginning, we listen() to the two message names. On user input, we send it as a chat message to everyone else
listening to the chat. Roughly every 60 seconds we ping() the server (keepalive again). Then we send and receive with doNetwork()
and check to see if we got any interesting messages.</p>

<p>We could simplify the checks quite a bit since there are only two well defined messages (one 'notify', one 'set'), but i implemented the full
checking here to illustrate the principle.</p>

<p>Last but not least, let's implement the most brain-dead chatbot we can think of. It repeats messages containing "simon" with "Simon says". It also
implements a counter in Clacks for counting chat messages. Every time it gets a clock notification, it sends the number of chat messages seen since the
last notification as a chat message and decreases the counter accordingly. (I could just set it to zero, but using decrement with the previously read
out value is the correct thing to do, especially in cases where the counter is increased by some other program).</p>

<code>
#!/usr/bin/env perl
#---AUTOPRAGMASTART---
use 5.020;
use strict;
use warnings;
use diagnostics;
use mro 'c3';
use English;
use Carp;
our $VERSION = 4.1;
use Fatal qw( close );
use Array::Contains;
#---AUTOPRAGMAEND---

use Net::Clacks::Client;
use Term::ReadKey;
use Time::HiRes qw(sleep);
use Data::Dumper;

my $username = 'exampleuser';
my $password = 'unsafepassword';
my $applicationname = 'chatbot';
my $is_caching = 0;

my $chat = Net::Clacks::Client->new('127.0.0.1', 18888, $username, $password, $applicationname, $is_caching);
#print 'Connected to server. Info given: ', $chat->getServerinfo(), "\n";

my $chatname = 'example::chat';
my $clockname = 'example::notify';
my $countname = 'chatbot::linecount';

$chat->listen($chatname);
$chat->listen($clockname);
$chat->ping();
$chat->doNetwork();

my $nextping = time + 60;

while(1) {
    my $line = ReadLine -1;

    if(defined($line)) {
        chomp $line;
        if(length($line)) {
            last if(uc $line eq 'QUIT' || uc $line eq 'EXIT');
            $chat->set($chatname, $line);
        }
    }
    if($nextping < time) {
        $chat->ping();
        $nextping = time + 60;
    }
    $chat->doNetwork();
    while((my $msg = $chat->getNext())) {
        if($msg->{type} eq 'set' && $msg->{name} eq $chatname) {
            # Increment count for every chat message
            $chat->increment($countname);

            # very non-AI answer implementation of "simon says"
            if($msg->{data} =~ /simon/i) {
                $chat->set($chatname, 'RoboSimon says: ' . $msg->{data});
                $chat->increment($countname);
            }
        } elsif($msg->{type} eq 'notify' && $msg->{name} eq $clockname) {
            # Every minute, retrieve our current count, send a chat message and decrease line count accordingly
            my $linecount = $chat->retrieve($countname);
            if(!defined($linecount)) {
                $linecount = 0;
                $chat->store($countname, 0);
            }
            $chat->set($chatname, $linecount . ' new chat messages during the last minute');
            $chat->decrement($countname, $linecount);
        } elsif($msg->{type} eq 'disconnect') {
            print '+++ Disconnected by server, reason given: ', $msg->{data}, "\n";
            last;
        }
    }
    $chat->doNetwork();
    sleep(1);
}
</code>

<p>Ok, sure, this chat system will never get much users, because it just doesn't have good features. It's just
a demo of some of the Net::Clacks capabilities.</p>

<p>But "what if" you actually get more users or processes that a single service or server can handle? No problem here, either.
Net::Clacks::Server has what is called an "Interclacks" mode, which can be used to run in master/slave mode. When a slave starts up
and connects (or reconnects after a network error) to the master, it drops it's locally stored variables and resyncs from the master.</p>

<p>After that, every message or stored variable you set/send/notify gets automatically synced to the master. A slave can also work as a master
node at the same time, so you are able to chain nodes in a tree like pattern if you really so desire.</p>

<p>So, lets make a slave node. In our case, it will run on the same host with a different port (but you can trivially change it to run on a different
server). All we need is an additional XML config file:</p>

<code>
<clacks>
    <appname>Clacks Master</appname>
    <ip>127.0.0.1</ip>
    <port>18889</port>
    <pingtimeout>600</pingtimeout>
    <interclackspingtimeout>60</interclackspingtimeout>
    <ssl>
        <cert>exampleserver.crt</cert>
        <key>exampleserver.key</key>
    </ssl>
    <username>exampleuser</username>
    <password>unsafepassword</password>
    <throttle>
        <maxsleep>5000</maxsleep>
        <step>1</step>
    </throttle>
    <master>
        <ip>127.0.0.1</ip>
        <port>18888</port>
    </master>
</clacks>
</code>

<p>And then start it:</p>

<code>
perl server.pl clacks_slaveserver.xml
</code>

<p>So far, i have had Net::Clacks in use on a couple of live systems for over 2 years, most of them running 1000+ clacks 
connections at the same time. At least one of them having a constant 24/7 message rate of roughly 5000 messages per minute. 
Pretty much no crashes in the last few months. Obviously, you need to test, test, test before you decide to use it for
your own systems.</p>

</readmore>
