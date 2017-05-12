package Net::Trac;
use Any::Moose;

our $VERSION = '0.16';

use Net::Trac::Connection;
use Net::Trac::Ticket;
use Net::Trac::TicketHistory;
use Net::Trac::TicketAttachment;
use Net::Trac::TicketSearch;

=head1 NAME

Net::Trac - Interact with a remote Trac instance

=head1 SYNOPSIS

    use Net::Trac;

    my $trac = Net::Trac::Connection->new(
        url      => 'http://trac.someproject.org',
        user     => 'hiro',
        password => 'yatta'
    );

    my $ticket = Net::Trac::Ticket->new( connection => $trac );
    my $id = $ticket->create(summary => 'This product has only a moose, not a pony');

    my $other_ticket = Net::Trac::Ticket->new( connection => $trac );
    $other_ticket->load($id);
    print $other_ticket->summary, "\n";

    $ticket->update( summary => 'This project has no pony' );

=head1 DESCRIPTION

Net::Trac is simple client library for a remote Trac instance. 
Because Trac doesn't provide a web services API, this module
currently "fakes" an RPC interface around Trac's webforms and
the feeds it exports. Because of this, it's somewhat more brittle
than a true RPC client would be.

As of now, this module has been tested against Trac 10.4 and Trac 11.0.

The author's needs for this module are somewhat modest and its
current featureset reflects this. Right now, only basic read/write
functionality for Trac's tickets is provided. Patches would be gratefully
appreciated.

=head1 BUGS

This module currently only deals with Trac's bug tracking system.

This module is woefully incomplete.

This module's error handling isn't what it should be.

There are more.

Please send bug reports and patches to bug-net-trac@rt.cpan.org

=head1 AUTHOR

Jesse Vincent <jesse@bestpractical.com>, Thomas Sibley <trs@bestpractical.com>

=head1 LICENSE

Copyright 2008-2009 Best Practical Solutions.

This package is licensed under the same terms as Perl 5.8.8.

=cut

'This is the end of the file';
