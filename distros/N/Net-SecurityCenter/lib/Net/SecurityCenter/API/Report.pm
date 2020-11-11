package Net::SecurityCenter::API::Report;

use warnings;
use strict;

use Carp;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.300';

my $common_template = {

    id => {
        required => 1,
        allow    => qr/^\d+$/,
        messages => {
            required => 'Report ID is required',
            allow    => 'Invalid Report ID',
        },
    },

    filter => {
        allow => [ 'running', 'completed', 'usable', 'manageable' ],
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
        filter => $common_template->{'filter'},
        raw    => {},
    };

    my $params  = sc_check_params( $tmpl, \%args );
    my $raw     = delete( $params->{'raw'} );
    my $reports = $self->client->get( '/report', $params );

    return if ( !$reports );

    if ($raw) {
        return wantarray ? @{$reports} : $reports;
    }

    return wantarray ? @{ sc_merge($reports) } : sc_merge($reports);

}

#-------------------------------------------------------------------------------

sub get {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => $common_template->{'fields'},
        id     => $common_template->{'id'},
        raw    => {},
    };

    my $params = sc_check_params( $tmpl, \%args );

    my $report_id = delete( $params->{'id'} );
    my $raw       = delete( $params->{'raw'} );

    my $report = $self->client->get( "/report/$report_id", $params );

    return         if ( !$report );
    return $report if ($raw);
    return sc_normalize_hash($report);

}

#-------------------------------------------------------------------------------

sub download {

    my ( $self, %args ) = @_;

    my $tmpl = {
        filename => {},
        id       => $common_template->{'id'},
    };

    my $params = sc_check_params( $tmpl, \%args );

    my $report_id = delete( $params->{'id'} );
    my $filename  = delete( $params->{'filename'} );

    my $report_data = $self->client->post("/report/$report_id/download");

    return $report_data if ( !$filename );

    open my $fh, '>', $filename
        or croak("Could not open file '$filename': $!");

    print $fh $report_data;

    close $fh
        or carp("Failed to close file '$filename': $!");

    return 1;

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Report - Perl interface to Tenable.sc (SecurityCenter) Report REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Report;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Report->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Report REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Report->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Report> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 list

Gets the list of reports.

Params:

=over 4

=item * C<fields> : Report fields

=item * C<filter> : Filter

=item * C<raw> : Return RAW result

=back

=head2 get

Gets the report associated with C<id>.

Params:

=over 4

=item * C<id> : Report ID

=back

=head2 download

Download the report associated with C<id>.

    $report->download( id => 1337, filename => '/tmp/report.pdf');

Params:

=over 4

=item * C<id> : Report ID

=item * C<filename> : Name of file

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

This software is copyright (c) 2018-2020 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
