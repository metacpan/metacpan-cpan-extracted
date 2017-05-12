package SVGraph;

use warnings;
use strict;

=head1 NAME

SVGraph - Library that generates cool SVG graphs

=cut

our $VERSION = '0.02';

use SVGraph::Core;

=head1 SYNOPSIS

    use SVGraph::2D::lines;

    my $graph=SVGraph::2D::lines->new(
     title => "My graph",
     type => "normal/percentage",
     x => 500,
     y => 300,
     show_lines => 1,
     show_points => 1,
     grid_y_main_lines => 0,
     show_label_textsize => 20,
     show_legend => 1,
     show_data => 1,
     show_data_background => 1,
     show_grid_x => 0
    );

    # two columns -> two lines in the graph
    my %columns;
    $columns{first}=$graph->addColumn(title=>"first", show_line=>1);
    $columns{second}=$graph->addColumn(title=>"second", show_line=>1);

    $graph->addRowLabel('1');
    $graph->addRowLabel('2');
    $graph->addRowLabel('3');

    $graph->addValueMark(20,front => 1, color => 'blue', right => 1, 
                         show_label_text => 'something', show_label => 1);
    
    # data for graph
    $columns{first}->addData('1',30);
    $columns{first}->addData('2',60);
    $columns{first}->addData('3',50);
    $columns{second}->addData('1',20);
    $columns{second}->addData('2',0);
    $columns{second}->addData('3',70);

    # creates svg file
    print $graph->prepare;

=head1 AUTHOR

Roman Fordinal, C<< <comsultia at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-svgraph at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SVGraph>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SVGraph


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SVGraph>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SVGraph>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SVGraph>

=item * Search CPAN

L<http://search.cpan.org/dist/SVGraph>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Roman Fordinal, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under LGPLv2.

=cut

1;
