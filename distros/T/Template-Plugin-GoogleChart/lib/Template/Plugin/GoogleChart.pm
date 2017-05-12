package Template::Plugin::GoogleChart;
use 5.006;
use strict;
use warnings;
use Google::Chart;
our $VERSION = '0.02';
use base qw(Template::Plugin);
sub new_chart {
    my ($self, $args) = @_;
    Google::Chart->new($args) }
1;
__END__

=for test_synopsis
1;
__END__

=head1 NAME

Template::Plugin::GoogleChart - Using Google::Chart as a template plugin

=head1 SYNOPSIS

    [% USE c = GoogleChart %]
    [% chart = c.new_chart %]
    [% ... set up chart ... %]
    [% chart.img_tag %]

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item C<new_chart>

Returns a new L<Google::Chart> object. See its documentation for how to use
the chart object. You will probably want to write out the URL with the chart
object's C<get_url()> method or write out the C<IMG> tag with C<img_tag()> as
shown in the synopsis.

=back

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Template-Plugin-GoogleChart/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by the authors.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

