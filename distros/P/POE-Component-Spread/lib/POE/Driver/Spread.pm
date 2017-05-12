package POE::Driver::Spread;

use strict;
use vars qw($VERSION);

$VERSION = "0.01";

use Spread;
use Data::Dumper;

sub new {
    my $type = shift;
    my $self = bless {@_}, $type;
    return $self;
}

sub get {
    my $self = shift;
    my $fh   = shift;

    # this returns all undef if we're disconnected
    my ($type, $sender, $groups, $mess, $endian, $message) = Spread::receive($self->{mbox});

    if (!defined($type)) {
        # raise an error somewhere
        print "error: $sperrno\n";
    }

    return [ [$type, $sender, $groups, $mess, $endian, $message] ];
}

$VERSION;
