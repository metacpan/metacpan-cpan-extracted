package Template::Plugin::GD::Graph::pie;

use strict;
use warnings;
use base qw( GD::Graph::pie Template::Plugin );

our $VERSION = sprintf("%d.%02d", q$Revision: 1.56 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $class   = shift;
    my $context = shift;
    return $class->SUPER::new(@_);
}

sub set {
    my $self = shift;
    push(@_, %{pop(@_)}) if ( @_ & 1 && ref($_[@_-1]) eq "HASH" );
    $self->SUPER::set(@_);
}

1;

__END__

=head1 NAME

Template::Plugin::GD::Graph::pie - Create pie charts with legends

=head1 SYNOPSIS

    [% USE g = GD.Graph.pie(x_size, y_size); %]

=head1 EXAMPLES

    [% FILTER null;
        data = [
            ["1st","2nd","3rd","4th","5th","6th"],
            [    4,    2,    3,    4,    3,  3.5]
        ];

        USE my_graph = GD.Graph.pie( 250, 200 );

        my_graph.set(
                title => 'A Pie Chart',
                label => 'Label',
                axislabelclr => 'black',
                pie_height => 36,

                transparent => 0,
        );
        my_graph.plot(data).png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Graph.pie plugin provides an interface to the GD::Graph::pie
class defined by the GD::Graph module. It allows an (x,y) data set to
be plotted as a pie chart. The x values are typically strings.

See L<GD::Graph> for more details.

=head1 AUTHOR

Thomas Boutell wrote the GD graphics library.

Lincoln D. Stein wrote the Perl GD modules that interface to it.

Martien Verbruggen wrote the GD::Graph module.

Craig Barratt E<lt>craig@arraycomm.comE<gt> wrote the original GD
plugins for the Template Toolkit (2001).

Andy Wardley E<lt>abw@cpan.orgE<gt> extracted them from the TT core
into a separate distribution for TT version 2.15.

=head1 COPYRIGHT

Copyright (C) 2001 Craig Barratt E<lt>craig@arraycomm.comE<gt>, 
2006 Andy Wardley E<lt>abw@cpan.orgE<gt>.

GD::Graph is copyright 1999 Martien Verbruggen.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Template::Plugin::GD>, L<Template::Plugin::GD::Graph::lines>, L<Template::Plugin::GD::Graph::lines3d>, L<Template::Plugin::GD::Graph::bars>, L<Template::Plugin::GD::Graph::bars3d>, L<Template::Plugin::GD::Graph::points>, L<Template::Plugin::GD::Graph::linespoints>, L<Template::Plugin::GD::Graph::area>, L<Template::Plugin::GD::Graph::mixed>, L<Template::Plugin::GD::Graph::pie3d>, L<GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
