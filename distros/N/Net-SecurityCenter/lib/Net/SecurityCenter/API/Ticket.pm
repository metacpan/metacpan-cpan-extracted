package Net::SecurityCenter::API::Ticket;

use warnings;
use strict;

use Carp;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.310';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Ticket ID is required',
            allow    => 'Invalid Ticket ID',
        },
    },

    fields => {
        filter => \&sc_filter_array_to_string,
    },

    assignee => {
        allow  => qr/\d+/,
        errors => { allow => 'Invalid Asignee ID' },
        filter => sub {
            return { 'id' => $_[0] };
        }
    },

    status => {
        allow => [ 'assigned', 'resolved', 'feedback', 'na', 'duplicate', 'closed' ]
    },

    classification => {
        allow => [
            'Information',
            'Configuration',
            'Patch',
            'Disable',
            'Firewall',
            'Schedule',
            'IDS',
            'Other',
            'Accept Risk',
            'Recast Risk',
            'Re-scan Request',
            'False Positive',
            'System Probe',
            'External Probe',
            'Investigation Needed',
            'Compromised System',
            'Virus Incident',
            'Bad Credentials',
            'Unauthorized Software',
            'Unauthorized System',
            'Unauthorized User'
        ]
    },

};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub list {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        raw    => {},
    };

    my $params  = sc_check_params( $tmpl, \%args );
    my $raw     = delete( $params->{'raw'} );
    my $tickets = $self->client->get( '/ticket', $params );

    return if ( !$tickets );

    if ($raw) {
        return wantarray ? @{$tickets} : $tickets;
    }

    return wantarray ? @{ sc_merge($tickets) } : sc_merge($tickets);

}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        id     => $common_template->{'id'},
        raw    => {},
    };

    my $params    = sc_check_params( $tmpl, \%args );
    my $raw       = delete( $params->{'raw'} );
    my $ticket_id = delete( $params->{'id'} );
    my $ticket    = $self->client->get( "/ticket/$ticket_id", $params );

    return         if ( !$ticket );
    return $ticket if ($raw);
    return sc_normalize_hash($ticket);

}

#-------------------------------------------------------------------------------

sub add {

    my ( $self, %args ) = @_;

    my $tmpl = {
        name => {
            required => 1,
            errors   => { required => 'Specify ticket name' }
        },
        assignee       => $common_template->{'asignee'},
        status         => $common_template->{'status'},
        classification => $common_template->{'classification'},
        description    => {},
        notes          => {},
        queries        => {},
        query          => {}
    };

    my $params = sc_check_params( $tmpl, \%args );

    my $result = $self->client->post( '/ticket', $params );

    return $result->{id};

}

#-------------------------------------------------------------------------------

sub edit {

    my ( $self, %args ) = @_;

    my $tmpl = {
        id             => $common_template->{'id'},
        name           => {},
        assignee       => $common_template->{'asignee'},
        status         => $common_template->{'status'},
        classification => $common_template->{'classification'},
        description    => {},
        notes          => {},
        queries        => {},
        query          => {},
        raw            => {}
    };

    my $params    = sc_check_params( $tmpl, \%args );
    my $ticket_id = delete( $params->{'id'} );
    my $raw       = delete( $params->{'raw'} );

    my $ticket = $self->client->patch( "/ticket/$ticket_id", $params );

    return $ticket if ($raw);
    return sc_normalize_hash($ticket);

}

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Ticket - Perl interface to Tenable.sc (SecurityCenter) Ticket REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Ticket;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Ticket->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Ticket REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Ticket->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Ticket> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Get the list of tickets.

Params:

=over 4

=item * C<fields> : List of fields

=back

Allowed Fields:

=over 4

=item * C<id>

=item * C<name>

=item * C<description>

=item * C<creator>

=item * C<owner>

=item * C<assignee>

=item * C<ownerGroup>

=item * C<assigneeGroup>

=item * C<queries>

=item * C<classification>

=item * C<status>

=item * C<notes>

=item * C<assignedTime>

=item * C<resolvedTime>

=item * C<closedTime>

=item * C<createdTime>

=item * C<modifiedTime>

=item * C<canUse>

=item * C<canManage>

=item * C<canRespond>

=back


=head2 get

Get the ticket associated with C<id>.

Params:

=over 4

=item * C<id> : Ticket ID

=item * C<fields> : List of fields (see C<list> method)

=back


=head2 add

Adds a Ticket.

Params:

=over 4

=item * C<name> : Summary (required)

=item * C<assignee> : Tenable.sc user ID (required)

=item * C<status> : Ticket status (default C<assigned>)

=over 4

=item * C<assigned>

=item * C<resolved>

=item * C<feedback>

=item * C<na>

=item * C<duplicate>

=item * C<closed>

=back

=item * C<classification> : Ticket classification (default: C<Information>)

=over 4

=item * C<Information>

=item * C<Configuration>

=item * C<Patch>

=item * C<Disable>

=item * C<Firewall>

=item * C<Schedule>

=item * C<IDS>

=item * C<Other>

=item * C<Accept Risk>

=item * C<Recast Risk>

=item * C<Re-scan Request>

=item * C<False Positive>

=item * C<System Probe>

=item * C<External Probe>

=item * C<Investigation Needed>

=item * C<Compromised System>

=item * C<Virus Incident>

=item * C<Bad Credentials>

=item * C<Unauthorized Software>

=item * C<Unauthorized System>

=item * C<Unauthorized User>

=back

=item * C<description> : Ticket description

=item * C<note> : Ticket note

=item * C<queries> : Array of queries

=item * C<query> : Query

=back

=head2 edit

Edits the Ticket associated with C<id>, changing only the passed in fields.

Params:

=over 4

=item * C<id> : Ticket ID

=item * see C<add> method for all optional params

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code ticket is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
