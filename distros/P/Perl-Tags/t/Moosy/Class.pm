package Moosy::Class;
use Moose;

extends 'Moosy::Parent';
with 'Moosy::Role1';
with qw(Moosy::Role2 Moosy::Role3);

has foo => (
    is => 'ro',
);

around bar => sub {
    print "Ha ha ha\n";
};

1;
