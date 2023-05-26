package Net::SecurityCenter::API::Notification;

use warnings;
use strict;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.311';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Notification ID is required',
            allow    => 'Invalid Notification ID',
        },
    },

    fields => {
        filter => \&sc_filter_array_to_string,
    },

};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub list {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields    => $common_template->{'fields'},
        timeframe => {
            allow   => [ '24h', '7d', '30d' ],
            default => '24h'
        },
        raw => {},
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );

    my $notifications = $self->client->get( '/notification', $params );

    return if ( !$notifications );

    if ($raw) {
        return wantarray ? @{$notifications} : $notifications;
    }

    return wantarray ? @{ sc_normalize_array($notifications) } : sc_normalize_array($notifications);

}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        id     => $common_template->{'id'},
        raw    => {},
    };

    my $params          = sc_check_params( $tmpl, \%args );
    my $raw             = delete( $params->{'raw'} );
    my $notification_id = delete( $params->{'id'} );
    my $notification    = $self->client->get( "/notification/$notification_id", $params );

    return               if ( !$notification );
    return $notification if ($raw);
    return sc_normalize_hash($notification);

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Notification - Perl interface to Tenable.sc (SecurityCenter) Status REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Notification;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Notification->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Notification REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Notification->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Notification> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Gets the list of notifications.

Params:

=over 4

=item * C<fields> : List of fields (see C<list>)

=item * C<raw> : Return the original message without optimizations

=back

Allowed Fields:

=over 4

=item * C<id> *

=item * C<initiator>

=item * C<action>

=item * C<type>

=item * C<time>

=item * C<target>

=item * C<changes>

=item * C<effects>

=item * C<status>

=item * C<text>

=back

(*) always comes back


=head2 get

Gets the notification associated with C<id>.

Params:

=over 4

=item * C<id> : Notification ID

=item * C<fields> : List of fields (see C<list>)

=item * C<raw> : Return the original message without optimizations

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Net-SecurityCenter/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Net-SecurityCenter>

    git clone https://github.com/giterlizzi/perl-Net-SecurityCenter.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2018-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
