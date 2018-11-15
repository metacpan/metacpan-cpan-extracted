=head1 NAME

Nagios::NRPE::Utils - Common helper functions for Nagios::NRPE

=head1 DESCRIPTION

This file contains common helper functions for the submodules 
Nagios::NRPE::Client,  Nagios::NRPE::Packet and Nagios::NRPE::Daemon.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the authors (see AUTHORS file).
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 METHODS

=over  

=item return_error

Create a hash with the specified error message using this format

{
    error => 1,
    reason => "some reason"
}

=back

=cut

package Nagios::NRPE::Utils;

our $VERSION = '2.0.2';
use strict;
use warnings;
require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(return_error);

sub return_error {
    my ($reason) = @_;
    my %return;
    $return{'error'}  = 1;
    $return{'reason'} = $reason;
    return ( \%return );

}

1;
