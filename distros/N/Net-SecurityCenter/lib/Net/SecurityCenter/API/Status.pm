package Net::SecurityCenter::API::Status;

use warnings;
use strict;

use parent 'Net::SecurityCenter::Base';

use Net::SecurityCenter::Utils qw(:all);

our $VERSION = '0.310';

#-------------------------------------------------------------------------------
# METHODS
#-------------------------------------------------------------------------------

sub status {

    my ( $self, %args ) = @_;

    my $tmpl = {
        fields => {
            filter => \&sc_filter_array_to_string
        },
        raw => {},
    };

    my $params = sc_check_params( $tmpl, \%args );
    my $raw    = delete( $params->{'raw'} );
    my $status = $self->client->get( '/status', $params );

    if ($raw) {
        return $status;
    }

    return sc_normalize_hash($status);

}

#-------------------------------------------------------------------------------

1;

__END__
=pod

=encoding UTF-8


=head1 NAME

Net::SecurityCenter::API::Status - Perl interface to Tenable.sc (SecurityCenter) Status REST API


=head1 SYNOPSIS

    use Net::SecurityCenter::REST;
    use Net::SecurityCenter::API::Status;

    my $sc = Net::SecurityCenter::REST->new('sc.example.org');

    $sc->login('secman', 'password');

    my $api = Net::SecurityCenter::API::Status->new($sc);

    $sc->logout();


=head1 DESCRIPTION

This module provides Perl scripts easy way to interface the Status REST API of Tenable.sc
(SecurityCenter).

For more information about the Tenable.sc (SecurityCenter) REST API follow the online documentation:

L<https://docs.tenable.com/sccv/api/index.html>


=head1 CONSTRUCTOR

=head2 Net::SecurityCenter::API::Status->new ( $client )

Create a new instance of B<Net::SecurityCenter::API::Status> using L<Net::SecurityCenter::REST> class.


=head1 METHODS

=head2 status

Gets a collection of status information, including license.


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
