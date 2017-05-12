use strict;
use warnings;
use 5.014;

package MyClient {
    sub new {
        say "MyClient created using pid $$";
        return bless { pid => $$ }, shift;
    }
    sub send {
        say 'sending message with object created under pid ', shift->{pid};
    }
}

use Object::ForkAware;
my $client = Object::ForkAware->new(
    create => sub { MyClient->new(server => 'foo.com', port => '1234') },
);

# do things with object as normal...
$client->send('stuff');

# later, we fork for some reason
if (!fork) {
    # child process

    # look, client was recreated!
    $client->send('stuff');
}

