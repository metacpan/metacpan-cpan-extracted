package Net::SecurityCenter::API::Scanner;

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
            required => 'Scanner ID is required',
            allow    => 'Invalid Scanner ID',
        },
    },

    fields => {
        filter => \&sc_filter_array_to_string,
    }

};

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub list {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        raw    => {}
    };

    my $params   = sc_check_params( $tmpl, \%args );
    my $raw      = delete( $params->{'raw'} );
    my $scanners = $self->client->get( '/scanner', $params );

    return if ( !$scanners );

    if ($raw) {
        return wantarray ? @{$scanners} : $scanners;
    }

    return wantarray ? @{ sc_normalize_array($scanners) } : sc_normalize_array($scanners);

}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        id     => $common_template->{'id'},
        raw    => {},
    };

    my $params     = sc_check_params( $tmpl, \%args );
    my $scanner_id = delete( $params->{'id'} );
    my $raw        = delete( $params->{'raw'} );
    my $scanner    = $self->client->get( "/scanner/$scanner_id", $params );

    return          if ( !$scanner );
    return $scanner if ($raw);
    return sc_normalize_hash($scanner);

}

#-------------------------------------------------------------------------------

sub status {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, };

    my $params     = sc_check_params( $tmpl, \%args );
    my $scanner_id = delete( $params->{'id'} );

    my $scanner = $self->get( id => $scanner_id, fields => [ 'id', 'status' ] );

    return if ( !$scanner );
    return sc_decode_scanner_status( $scanner->{'status'} );

}

#-------------------------------------------------------------------------------

sub health {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, count => {} };

    my $params     = sc_check_params( $tmpl, \%args );
    my $scanner_id = delete( $params->{'id'} );

    my $scanner = $self->client->get("/scanner/$scanner_id/health");

    return if ( !$scanner );
    return $scanner;

}

#-------------------------------------------------------------------------------

sub bug_report {

    my ( $self, %args ) = @_;

    my $tmpl = { id => $common_template->{'id'}, scrub_mode => {}, full_mode => {} };

    my $params     = sc_check_params( $tmpl, \%args );
    my $scanner_id = delete( $params->{'id'} );

    my $scanner = $self->client->get( "/scanner/$scanner_id/bug_report", $params );

    return if ( !$scanner );
    return $scanner;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Scanner - Perl interface to Tenable.sc (SecurityCenter) Scanner REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Scanner;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Scanner->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Scanner REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 FUNCTIONS

=head2 sc_decode_scanner_status ( $status_int )

Decode Nessus scanner status.

    print decode_scanner_status(16384); #  Scanner disabled by user


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Scanner->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Scanner> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Get the scanner list.

=head2 get

Get the scanner associated with C<id>.

=head2 status

Get the decoded scanner status associated with C<scanner_id>.

=head2 health

Retrieve scanner health statistics by querying the Nessus API endpoint for the Scanner associated with C<scanner_id>.


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

This software is copyright (c) 2018-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
