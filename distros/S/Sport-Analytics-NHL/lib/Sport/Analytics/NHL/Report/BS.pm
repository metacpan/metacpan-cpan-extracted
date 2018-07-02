package Sport::Analytics::NHL::Report::BS;

use v5.10.1;
use strict;
use warnings FATAL => 'all';

=head1 NAME

Sport::Analytics::NHL::Report::BS - Class for the Boxscore JSON report

=head1 SYNOPSYS

Class for the Boxscore JSON report.

This is a stub for now. It shall expand as the release grows.

    use Sport::Analytics::NHL::Report::BS;
    my $report = Sport::Analytics::NHL::Report::BS->new($json)
    $report->process();

=head1 METHODS

=over 2

=item C<new>

Create the Boxscore object

=item C<process>

Process the Boxscore into the object

=back

=cut

use JSON::XS;

use Sport::Analytics::NHL::Util;

sub new ($$) {

	my $class = shift;
	my $json  = shift;
	
	my $self = decode_json($json);
	bless $self, $class;
	
	$self;
}

sub process ($) {

	my $self = shift;

	return 1;
}

1;

=head1 AUTHOR

More Hockey Stats, C<< <contact at morehockeystats.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<contact at morehockeystats.com>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Sport::Analytics::NHL::Report::BS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Sport::Analytics::NHL::Report::BS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Sport::Analytics::NHL::Report::BS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Sport::Analytics::NHL::Report::BS>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Sport::Analytics::NHL::Report::BS>

=item * Search CPAN

L<https://metacpan.org/release/Sport::Analytics::NHL::Report::BS>

=back
