package Readonly::Values::Syslog;

use strict;
use warnings;

use Readonly::Enum;
use Readonly;
use Exporter qw(import);

=head1 NAME

Readonly::Values::Syslog - Syslog Constants

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

Readonly::Enum our ($EMERGENCY, $ALERT, $CRITICAL, $ERROR, $WARNING, $NOTICE, $INFORMATIONAL, $DEBUG) => 0;
Readonly::Hash our %syslog_values => (
	'emergency' => $EMERGENCY,
	'alert' => $ALERT,
	'criticial' => $CRITICAL,
	'error' => $ERROR,
	'warning' => $WARNING,
	'warn' => $WARNING,
	'notice' => $NOTICE,
	'informational' => $INFORMATIONAL,
	'info' => $INFORMATIONAL,
	'debug' => $DEBUG
);

our @EXPORT = qw(
	$EMERGENCY $ALERT $CRITICAL $ERROR $WARNING $NOTICE $INFORMATIONAL $DEBUG
	%syslog_values
);

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

=head1 SEE ALSO

=over 4

=item * L<https://last9.io/blog/what-are-syslog-levels/>

=back

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-readonly-values-syslog at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Readonly-Values-Syslog>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Readonly::Values::Syslog

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Readonly-Values-Syslog>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Readonly-Values-Syslog>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Readonly-Values-Syslog>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Readonly::Values::Syslog>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2025 Nigel Horne.

Usage is subject to licence terms.

The licence terms of this software are as follows:

=over 4

=item * Personal single user, single computer use: GPL2

=item * All other users (including Commercial, Charity, Educational, Government)
  must apply in writing for a licence for use from Nigel Horne at the
  above e-mail.

=back

=cut

1;
