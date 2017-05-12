# $Id: /mirror/coderepos/lang/perl/Mvalve/trunk/lib/Mvalve/Const.pm 65693 2008-07-15T01:07:26.094046Z daisuke  $

package Mvalve::Const;
use strict;
use Exporter qw(import);

use constant +{
    EMERGENCY_HEADER   => 'X-Mvalve-Emergency',
    DESTINATION_HEADER => 'X-Mvalve-Destination',
    RETRY_HEADER       => 'X-Mvalve-Retry-Time',
    DURATION_HEADER    => 'X-Mvalve-Duration',
    MVALVE_TRACE       => $ENV{MVALVE_TRACE} ? 1 : 0,
};

our @EXPORT_OK = qw(
    EMERGENCY_HEADER
    DESTINATION_HEADER
    RETRY_HEADER
    DURATION_HEADER
    MVALVE_TRACE
);

1;

__END__

=head1 NAME

Mvalve::Const - Mvalve Constants 

=head1 CONSTANTS

=head2 DESTINATION_HEADER

=head2 EMERGENCY_HEADER

=head2 MVALVE_TRACE

=head2 RETRY_HEADER

=head2 DURATION_HEADER

=cut