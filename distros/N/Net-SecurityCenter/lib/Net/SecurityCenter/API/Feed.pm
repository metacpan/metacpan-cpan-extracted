package Net::SecurityCenter::API::Feed;

use warnings;
use strict;

use Carp;

use parent 'Net::SecurityCenter::API';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.203';

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub status {

    my ( $self, %args ) = @_;

    my $tmpl = {
        type => {
            default => 'all',
            allow   => [ 'all', 'active', 'passive', 'lce', 'sc' ]
        },
        raw => {}
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $type   = delete( $params->{'type'} );
    my $raw    = delete( $params->{'raw'} );

    my $feed_path = '/feed';

    if ( $type ne 'all' ) {
        $feed_path .= "/$type";
    }

    my $feed = $self->client->get($feed_path);

    return if ( !$feed );
    return $feed if ($raw);
    return sc_normalize_hash($feed);

}

#-------------------------------------------------------------------------------

sub update {

    my ( $self, %args ) = @_;

    my $tmpl = {
        type => {
            default => 'all',
            allow   => [ 'all', 'active', 'passive', 'lce', 'sc' ]
        }
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $type   = delete( $params->{'type'} );

    $self->client->post("/feed/$type/update");

    return 1;    # TODO

}

#-------------------------------------------------------------------------------

sub process {

    my ( $self, %args ) = @_;

    my $tmpl = {
        type => {
            required => 1,
            allow    => [ 'all', 'active', 'passive', 'lce', 'sc' ]
        },
        filename => {
            required => 1,
        }
    };

    my $params   = sc_check_params( $tmpl, \%args );
    my $type     = delete( $params->{'type'} );
    my $filename = delete( $params->{'filename'} );

    my $sc_filename = $self->client->upload($filename)->{'filename'};

    $self->client->post( "/feed/$type/process", { 'filename' => $sc_filename } );

    return 1;    # TODO

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Feed - Perl interface to Tenable.sc (SecurityCenter) Feed REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Feed;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Feed->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Feed REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Feed->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Feed> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 status

Gets the status of feed the upload associated with C<type>.

Params:

=over 4

=item * C<type>: Feed type

=over 4

=item * C<all>: Return all feeds update status (default)

=item * C<sc>: Return SecurityCenter feed update status

=item * C<acttve>: Return Active plugins feed update status

=item * C<passive>: Return Passive plugins feed update status

=item * C<lce>: Return LCE feed update status

=back

=back

=head2 update

Sends a job to update the Feed type associated with C<type>.

Params:

=over 4

=item * C<type>: Feed type

=over 4

=item * C<all>: All feeds (default)

=item * C<sc>: SecurityCenter feed

=item * C<acttve>: Active plugins feed

=item * C<passive>: Passive plugins

=item * C<lce>: LCE feed

=back

=back

=head2 process

Processes an uploaded feed update file and sends a job to update the Feed type associated with C<type>.

Params:

=over 4

=item * C<type>: Feed type

=over 4

=item * C<sc>: SecurityCenter feed update

=item * C<acttve>: Active plugins feed update

=item * C<passive>: Passive plugins feed update

=item * C<lce>: LCE feed update

=back

=item * C<filename>: Feed file path (eg. C</tmp/all-2.0.tar.gz>)

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

This software is copyright (c) 2018-2019 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
