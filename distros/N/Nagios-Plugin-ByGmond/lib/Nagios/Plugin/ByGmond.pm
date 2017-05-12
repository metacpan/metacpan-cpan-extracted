package Nagios::Plugin::ByGmond;

use strict;
use warnings;
use XML::Simple;
use IO::Socket::INET;
use base 'Nagios::Plugin';

our $VERSION = '0.04';

=head1 NAME

Nagios::Plugin::ByGmond - Nagios plugin for checking metrics from ganglia monitor daemon TCP output.

=head1 SYNOPSIS

    use Nagios::Plugin::ByGmond;

    my $npbg = Nagios::Plugin::ByGmond->new();
    $npbg->run;

=head1 DESCRIPTION
 
Please setup your nagios config.
 
  define command {
    command_name    check_memory_by_gmond
    command_line    /usr/local/bin/check_by_gmond -H $HOSTADDRESS$ -w 3 -c 5 -m 'mem_total'
  }
 
This plugin use metric named by ganglia. Please saw documention of ganglia before using.

=cut

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(
        usage => <<END_USAGE,
Usage: %s [ -v|--verbose ] [-H|--host=<host>] [-p|--port=<port>] [-m|--metric=<metric>]
[ -c|--critical=<critical threshold> ]
[ -w|--warning=<warning threshold> ]
END_USAGE
        version => $Nagios::Plugin::POP3VERSION,
        blurb   => q{Nagios plugin for receive metric data from gmond},
    );
    $self->add_arg(
        spec => 'warning|w=s',
        help => <<END_HELP,
-w, --warning=INTEGER:INTEGER
Minimum and maximum number of allowable result, outside of which a
warning will be generated.  If omitted, no warning is generated.
END_HELP
    );
    $self->add_arg(
        spec => 'critical|c=s',
        help => <<END_HELP,
-c, --critical=INTEGER:INTEGER
Minimum and maximum number of the generated result, outside of
which a critical will be generated.
END_HELP
    );
    $self->add_arg(
        spec    => 'host|H=s',
        default => 'localhost.localdomain',
        help    => <<END_HELP,
-H, --host
Gmond Host (defaults to localhost.localdomain)
END_HELP
    );
    $self->add_arg(
        spec    => 'port|p=s',
        default => '8649',
        help    => <<END_HELP,
-p, --port
Gmond Port (defaults to 8649)
END_HELP
    );
    $self->add_arg(
        spec => 'metric|m=s',
        help => <<END_HELP,
-m, --metric
Gmetric name
END_HELP
    );
    return $self;
}

sub run {
    my $self = shift;

    # Parse arguments and process standard ones (e.g. usage, help, version)
    $self->getopts;
    if (   !defined $self->opts->warning
        && !defined $self->opts->critical
        && !defined $self->opts->metric )
    {
        $self->nagios_die("You need to specify a threshold argument");
    }

    #Connect and got data
    my $sock = IO::Socket::INET->new(
        PeerAddr => $self->opts->host,
        PeerPort => $self->opts->port,
        Proto    => 'tcp'
      )
      or
      $self->nagios_die( 'Connect to ' . $self->opts->host . ' error: ' . $! );
    my $data;
    while (<$sock>) { $data .= $_ }
    my $gmond_ref = XMLin($data)->{CLUSTER}->{HOST};
    my $host_ref;
    if ( ref($gmond_ref) eq 'ARRAY' ) {
        for my $host ( @{$gmond_ref} ) {
            if ( $host->{IP} eq $self->opts->host
              or $host->{NAME} eq $self->opts->host ) {
                $host_ref = $host;
                last;
            }
        }
    } else {
        $host_ref = $gmond_ref;
    }
    my $metric_arrayref = $host_ref->{METRIC};
    for my $metric (@$metric_arrayref) {
        next unless $self->opts->metric eq $metric->{NAME};
        $self->add_perfdata(
            label     => $metric->{NAME},
            value     => $metric->{VAL},
            uom       => $metric->{UNITS},
            threshold => $self->threshold,
        );
        $self->nagios_exit(
            return_code => $self->check_threshold( $metric->{VAL} ),
            message     => sprintf "%s: %f %s\n",
            $metric->{EXTRA_DATA}->{EXTRA_ELEMENT}->[1]->{VAL}, $metric->{VAL},
            $metric->{UNITS},
        );
    }

}

1;

=head1 AUTHOR

chenryn, C<< <rao.chenlin at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-nagios-plugin-bygmond at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Nagios-Plugin-ByGmond>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Nagios::Plugin::ByGmond


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Nagios-Plugin-ByGmond>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Nagios-Plugin-ByGmond>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Nagios-Plugin-ByGmond>

=item * Search CPAN

L<http://search.cpan.org/dist/Nagios-Plugin-ByGmond/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 chenryn.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
