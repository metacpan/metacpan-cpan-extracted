#!perl -w
use strict;
use Net::Fritz::Box;
use Net::Fritz::Phonebook;

use Getopt::Long;
GetOptions(
    'h|host:s' => \my $host,
    'u|user:s' => \my $username,
    'p|pass:s' => \my $password,
    'b|phonebook:s' => \my $phonebookname,
);

my $fb = Net::Fritz::Box->new(
    username => $username,
    password => $password,
    upnp_url => $host,
);
my $device = $fb->discover;
if( my $error = $device->error ) {
    die $error
};

`chcp 65001 2>&1`;
binmode *STDOUT, ':encoding(UTF-8)';

my @phonebooks;
if( $phonebookname ) {
    my $book = Net::Fritz::Phonebook->by_name( device => $device, name => $phonebookname )
        or die "Couldn't find phonebook '$phonebookname'";
    @phonebooks = $book;
} else {
    @phonebooks = Net::Fritz::Phonebook->list(device => $device);
};

for my $book (@phonebooks) {
    #print Dumper $book->content;
    print $book->name, "\n";
    for my $e (@{ $book->entries }) {
        delete $e->{phonebook};
        print join "\t", $e->name, $e->category, (map { $_->type, $_->content } @{ $e->numbers }), "\n";
    };
};
