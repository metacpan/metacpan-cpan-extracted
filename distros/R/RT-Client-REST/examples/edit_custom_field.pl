#!/usr/bin/perl
#
# edit_custom_field.pl -- set one or more custom fields

use strict;
use warnings;

use Try::Tiny;
use RT::Client::REST;
use RT::Client::REST::Ticket;

unless ( @ARGV >= 3 ) {
    die "Usage: $0 username password ticket_id [key-value pairs]\n";
}

my $rt =
  RT::Client::REST->new( server => ( $ENV{RTSERVER} || 'http://rt.cpan.org' ),
  );
$rt->login(
    username => shift(@ARGV),
    password => shift(@ARGV),
);

my $ticket = RT::Client::REST::Ticket->new(
    rt => $rt,
    id => shift(@ARGV),
);

my %opts = @ARGV;
while ( my ( $cf, $value ) = each(%opts) ) {
    $ticket->cf( $cf, $value );
}

try {
    $ticket->store;
}
catch {
    die $_ unless blessed $_ && $_->can('rethrow');
    if ( $_->isa('Exception::Class::Base') ) {
        die ref($_), ": ", $_->message || $_->description, "\n";
    }
};

use Data::Dumper;
print Dumper($ticket);
