package Template::Plugin::GD::Graph::area;

use strict;
use warnings;
use base qw( GD::Graph::area Template::Plugin );

our $VERSION = sprintf("%d.%02d", q$Revision: 1.58 $ =~ /(\d+)\.(\d+)/);

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


sub set_legend {
    my $self = shift;
    $self->SUPER::set_legend(ref $_[0] ? @{$_[0]} : @_);
}

1;

__END__

=head1 NAME

Template::Plugin::GD::Graph::area - Create area graphs with axes and legends

=head1 SYNOPSIS

    [% USE g = GD.Graph.area(x_size, y_size); %]

=head1 EXAMPLES

    [% FILTER null;
        data = [
            ["1st","2nd","3rd","4th","5th","6th","7th", "8th", "9th"],
            [    5,   12,   24,   33,   19,    8,    6,    15,    21],
            [   -1,   -2,   -5,   -6,   -3,  1.5,    1,   1.3,     2]
        ];  
            
        USE my_graph = GD.Graph.area();
        my_graph.set(
                two_axes => 1,  
                zero_axis => 1,
                transparent => 0,
        );  
        my_graph.set_legend('left axis', 'right axis' );
        my_graph.plot(data).png | stdout(1);
       END;
    -%]

=head1 DESCRIPTION

The GD.Graph.area plugin provides an interface to the GD::Graph::area
class defined by the GD::Graph module. It allows one or more (x,y) data
sets to be plotted as lines with the area between the line and x-axis
shaded, in addition to axes and legends.

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

L<Template::Plugin::GD>, L<Template::Plugin::GD::Graph::lines>, L<Template::Plugin::GD::Graph::lines3d>, L<Template::Plugin::GD::Graph::bars>, L<Template::Plugin::GD::Graph::bars3d>, L<Template::Plugin::GD::Graph::points>, L<Template::Plugin::GD::Graph::linespoints>, L<Template::Plugin::GD::Graph::mixed>, L<Template::Plugin::GD::Graph::pie>, L<Template::Plugin::GD::Graph::pie3d>, L<GD>

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# End:
#
# vim: expandtab shiftwidth=4:
